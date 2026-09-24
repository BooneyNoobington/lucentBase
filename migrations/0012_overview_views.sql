/* Views for reading: the worklist, results and samples at a glance.

   They are what a frontend shows, and what anyone querying the database
   directly will want to start from. All of them are computed from the
   tables on every read, so they cannot go stale. */


DELIMITER $$


/* When a material sample was taken: the earliest finished sampling action on
   a material sample in its lineage. For an aliquot this is the sampling of
   the bottle it was poured from, not the pouring. NULL if unknown. */

CREATE FUNCTION sampling_time_of(p_id_sample INTEGER)
RETURNS TIMESTAMP
READS SQL DATA
BEGIN
    RETURN (
        WITH RECURSIVE lineage (id_sample) AS
        (
            SELECT  p_id_sample
            UNION
            SELECT  sample_source.id_source_sample
            FROM    sample_source
            JOIN    lineage     ON sample_source.id_sample = lineage.id_sample
        )
        SELECT      MIN(action.started_at)
        FROM        lineage
        JOIN        sample          ON sample.id_sample = lineage.id_sample
        JOIN        action          ON action.id_sample = lineage.id_sample
        JOIN        method_version  ON method_version.id_method_version = action.id_method_version
        JOIN        method          ON method.id_method = method_version.id_method
        WHERE       sample.sample_kind = 'material'
          AND       method.kind = 'sampling'
          AND       action.finished_at IS NOT NULL
    );
END$$


/* The time an observed value applies to (OMS: phenomenonTime). If it was not
   recorded with the observation, it is the sampling time for material samples
   and the time of the action for spatial samples (in-situ measurements). */

CREATE FUNCTION phenomenon_time_of(p_id_observation INTEGER)
RETURNS TIMESTAMP
READS SQL DATA
BEGIN
    RETURN (
        SELECT  COALESCE(observation.phenomenon_time,
                         IF(sample.sample_kind = 'material',
                            sampling_time_of(sample.id_sample),
                            action.started_at))
        FROM    observation
        JOIN    action  ON action.id_action = observation.id_action
        JOIN    sample  ON sample.id_sample = action.id_sample
        WHERE   observation.id_observation = p_id_observation
    );
END$$


/* Why a planned action cannot start yet, in words. NULL if it can. */

CREATE FUNCTION waiting_for(p_id_action INTEGER)
RETURNS VARCHAR(2500)
READS SQL DATA
BEGIN
    DECLARE v_id_sample     INTEGER;
    DECLARE v_id_method     INTEGER;
    DECLARE v_is_final      BOOLEAN;
    DECLARE v_missing       VARCHAR(2000);
    DECLARE v_others_open   BOOLEAN;

    SELECT  action.id_sample, method.id_method, method.is_final
    INTO    v_id_sample, v_id_method, v_is_final
    FROM    action
    JOIN    method_version  ON method_version.id_method_version = action.id_method_version
    JOIN    method          ON method.id_method = method_version.id_method
    WHERE   action.id_action = p_id_action;

    SET v_missing = missing_prerequisites(v_id_sample, v_id_method);

    SET v_others_open = v_is_final AND EXISTS (
        SELECT  1
        FROM    action
        WHERE   id_sample = v_id_sample
          AND   id_action <> p_id_action
          AND   finished_at IS NULL
          AND   cancelled_at IS NULL
    );

    RETURN CASE
        WHEN v_missing IS NOT NULL AND v_others_open THEN CONCAT(v_missing, '; all other actions on the sample')
        WHEN v_missing IS NOT NULL THEN v_missing
        WHEN v_others_open THEN 'all other actions on the sample'
    END;
END$$

DELIMITER ;


/* Every action with names instead of ids. waiting_for says what a planned
   action is still waiting for. */

CREATE VIEW v_action AS
SELECT      action.id_action,
            action.status,
            sample.id_sample,
            sample.code                                         AS sample_code,
            method.name                                         AS method,
            method.kind                                         AS method_kind,
            method_version.valid_from                           AS method_version,
            lab_order.order_number,
            CONCAT_WS(' ', assignee.given_name, assignee.surname)   AS assignee,
            CONCAT_WS(' ', performer.given_name, performer.surname) AS performer,
            action.due_at,
            action.planned_at,
            action.started_at,
            action.finished_at,
            action.cancelled_at,
            IF(action.status = 'planned', waiting_for(action.id_action), NULL) AS waiting_for,
            action.note
FROM        action
JOIN        sample              ON sample.id_sample = action.id_sample
JOIN        method_version      ON method_version.id_method_version = action.id_method_version
JOIN        method              ON method.id_method = method_version.id_method
LEFT JOIN   lab_order           ON lab_order.id_lab_order = action.id_lab_order
LEFT JOIN   person AS assignee  ON assignee.id_person = action.id_assignee
LEFT JOIN   person AS performer ON performer.id_person = action.id_performer;


/* What there is to do: open actions, those in progress first, then those
   that can start now, then those still waiting; each group by due date. */

CREATE VIEW v_worklist AS
SELECT      *
FROM        v_action
WHERE       status IN ('planned', 'started')
ORDER BY    status = 'started' DESC,
            waiting_for IS NOT NULL,
            due_at IS NULL,
            due_at,
            planned_at,
            id_action;


/* Every result, displayed as it would be reported, next to the raw value. */

CREATE VIEW v_observation AS
SELECT      observation.id_observation,
            sample.code                                 AS sample_code,
            method.name                                 AS method,
            observed_property.name                      AS property,
            format_result(observation.id_observation)   AS result,
            method_unit.symbol                          AS unit,
            observation.result_numeric                  AS raw_value,
            raw_unit.symbol                             AS raw_unit,
            observation.censoring,
            convert_unit(observation.result_numeric, observation.id_unit, method_property.id_unit)
                < method_property.loq                   AS is_below_loq,
            method_property.formula IS NOT NULL         AS is_calculated,
            phenomenon_time_of(observation.id_observation) AS phenomenon_time,
            observation.result_time,
            observation.reviewed_at,
            observation.invalidated_at IS NULL
                AND action.cancelled_at IS NULL         AS is_valid,
            EXISTS (
                SELECT  1
                FROM    v_stale_calculation
                WHERE   v_stale_calculation.id_observation = observation.id_observation
            )                                           AS is_stale,
            observation.invalidation_reason,
            action.id_action,
            sample.id_sample,
            lab_order.order_number
FROM        observation
JOIN        action              ON action.id_action = observation.id_action
JOIN        sample              ON sample.id_sample = action.id_sample
JOIN        method_version      ON method_version.id_method_version = action.id_method_version
JOIN        method              ON method.id_method = method_version.id_method
JOIN        method_property     ON method_property.id_method_version = action.id_method_version
                               AND method_property.id_observed_property = observation.id_observed_property
JOIN        observed_property   ON observed_property.id_observed_property = observation.id_observed_property
LEFT JOIN   unit AS method_unit ON method_unit.id_unit = method_property.id_unit
LEFT JOIN   unit AS raw_unit    ON raw_unit.id_unit = observation.id_unit
LEFT JOIN   lab_order           ON lab_order.id_lab_order = action.id_lab_order;


/* Every sample with what it represents, when it was taken, where it is and
   how much work is still open on it. */

CREATE VIEW v_sample_overview AS
SELECT      sample.id_sample,
            sample.code,
            sample.sample_kind,
            matrix.name                                 AS matrix,
            feature.name                                AS sampled_feature,
            sampling_time_of(sample.id_sample)          AS sampled_at,
            sample.location_description,
            ST_AsText(sample.location)                  AS location,
            storage_location.name                       AS stored_at,
            (SELECT COUNT(*) FROM action
             WHERE  action.id_sample = sample.id_sample
               AND  action.status IN ('planned', 'started'))    AS open_actions,
            (SELECT COUNT(*) FROM action
             WHERE  action.id_sample = sample.id_sample
               AND  action.status = 'finished')                 AS finished_actions,
            closing_action_of(sample.id_sample) IS NOT NULL     AS is_closed
FROM        sample
LEFT JOIN   matrix              ON matrix.id_matrix = sample.id_matrix
LEFT JOIN   feature             ON feature.id_feature = sampled_feature_of(sample.id_sample)
LEFT JOIN   storage_location    ON storage_location.id_storage_location = sample.id_storage_location;
