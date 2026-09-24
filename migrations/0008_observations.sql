/* Observations: the results.

   An observation is one value of one property, determined in one action
   (OMS: Observation). Its feature of interest is the sample of the action;
   its procedure is the action's method version; its observer is the person
   and the devices of the action.

   Results are never edited or deleted. A wrong result is invalidated, with a
   reason, and a new one is recorded. Calculated results are observations too
   (OMS allows algorithms as procedures); observation_input records which
   observations they were calculated from.

   How a result is displayed ("< 0.05" for a value below the LOQ, rounding to
   the method's decimal places) is computed on the fly by format_result(), so
   it can never get out of step with the raw value. */


/* One result.

   - phenomenon_time   when the observed state existed. For a measurement on a
                       material sample in the lab this is the sampling time,
                       which the sample's sampling action already knows, so it
                       stays empty and is looked up (OMS 8.2.4, example 2). It
                       is filled for in-situ values and time series.
   - result_time       when the result became available.
   - result_*          exactly one of them holds the result, matching the
                       result_type of the observed property.
   - censoring         '<' or '>' when the device reported only a limit, e.g.
                       "< 0.05" or "> 300 colonies"; the limit goes into
                       result_numeric. Values the device did report exactly
                       stay exact even when they are below the LOQ; the "< LOQ"
                       is added when the result is displayed.
   - id_unit           unit of result_numeric, if the value was recorded in a
                       different unit than the method reports in.
   - reviewed_*        who checked and released the result.
   - invalidated_*     when and why the result was withdrawn. */

CREATE TABLE observation
(
    id_observation          INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    id_action               INTEGER         NOT NULL,
    id_observed_property    INTEGER         NOT NULL,
    phenomenon_time         TIMESTAMP       NULL,
    result_time             TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    result_numeric          DECIMAL(38,12),
    result_text             VARCHAR(1000),
    result_boolean          BOOLEAN,
    result_timestamp        TIMESTAMP       NULL,
    censoring               CHAR(1),
    id_unit                 INTEGER,
    reviewed_at             TIMESTAMP       NULL,
    id_reviewer             INTEGER,
    invalidated_at          TIMESTAMP       NULL,
    invalidation_reason     VARCHAR(500),

    /* Each IS NOT NULL counts as 1, so the sum is the number of results. */
    CONSTRAINT observation_has_exactly_one_result CHECK(
        (result_numeric IS NOT NULL) + (result_text IS NOT NULL)
        + (result_boolean IS NOT NULL) + (result_timestamp IS NOT NULL) = 1
    ),
    CONSTRAINT observation_censoring_choices CHECK(
        censoring IN ('<', '>')
    ),
    CONSTRAINT only_numeric_results_have_censoring_and_unit CHECK(
        result_numeric IS NOT NULL OR (censoring IS NULL AND id_unit IS NULL)
    ),
    CONSTRAINT observation_review_is_complete CHECK(
        (reviewed_at IS NULL AND id_reviewer IS NULL)
        OR
        (reviewed_at IS NOT NULL AND id_reviewer IS NOT NULL)
    ),
    CONSTRAINT observation_invalidation_has_reason CHECK(
        (invalidated_at IS NULL AND invalidation_reason IS NULL)
        OR
        (invalidated_at IS NOT NULL AND invalidation_reason IS NOT NULL)
    ),

    FOREIGN KEY (id_action)             REFERENCES action (id_action),
    FOREIGN KEY (id_observed_property)  REFERENCES observed_property (id_observed_property),
    FOREIGN KEY (id_unit)               REFERENCES unit (id_unit),
    FOREIGN KEY (id_reviewer)           REFERENCES person (id_person)
);


/* The observations a calculated observation was calculated from
   (OMS: relatedObservation). Written by calculate_action(). */

CREATE TABLE observation_input
(
    id_observation_input    INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    id_observation          INTEGER         NOT NULL,
    id_input_observation    INTEGER         NOT NULL,

    CONSTRAINT observation_input_unique UNIQUE(id_observation, id_input_observation),
    CONSTRAINT observation_is_not_its_own_input CHECK(
        id_observation <> id_input_observation
    ),

    FOREIGN KEY (id_observation)        REFERENCES observation (id_observation),
    FOREIGN KEY (id_input_observation)  REFERENCES observation (id_observation)
);


DELIMITER $$


/* Checks a new observation against its action and method:

   - the action has started (calculated values may also be added after it
     finished, because a calculation can be repeated), and is not cancelled;
   - the method version determines this property (OMS: suitable property);
   - the result has the property's type (OMS: suitable result type);
   - a numeric result has a unit of the right dimension; if none is given,
     the method's unit is filled in (OMS: unit of measure). */

CREATE TRIGGER observation_before_insert
BEFORE INSERT ON observation
FOR EACH ROW
BEGIN
    DECLARE v_status            VARCHAR(10);
    DECLARE v_id_method_version INTEGER;
    DECLARE v_result_type       VARCHAR(10);
    DECLARE v_id_dimension      INTEGER;
    DECLARE v_method_unit       INTEGER;
    DECLARE v_formula           VARCHAR(1000);
    DECLARE v_property_found    BOOLEAN DEFAULT FALSE;

    SELECT  status, id_method_version
    INTO    v_status, v_id_method_version
    FROM    action
    WHERE   id_action = NEW.id_action;

    SELECT  TRUE, observed_property.result_type, observed_property.id_dimension,
            method_property.id_unit, method_property.formula
    INTO    v_property_found, v_result_type, v_id_dimension, v_method_unit, v_formula
    FROM    method_property
    JOIN    observed_property
                ON observed_property.id_observed_property = method_property.id_observed_property
    WHERE   method_property.id_method_version = v_id_method_version
      AND   method_property.id_observed_property = NEW.id_observed_property;

    IF NOT v_property_found THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'The method of this action does not determine this property.';
    END IF;

    IF v_status = 'planned' OR v_status = 'cancelled'
       OR (v_status = 'finished' AND v_formula IS NULL)
    THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Results can only be recorded for actions that have started and not yet finished.';
    END IF;

    IF NEW.reviewed_at IS NOT NULL OR NEW.invalidated_at IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'New results are neither reviewed nor invalidated yet.';
    END IF;

    IF    (v_result_type = 'numeric' AND NEW.result_numeric IS NULL)
       OR (v_result_type = 'text' AND NEW.result_text IS NULL)
       OR (v_result_type = 'boolean' AND NEW.result_boolean IS NULL)
       OR (v_result_type = 'timestamp' AND NEW.result_timestamp IS NULL)
    THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'The result does not have the type of the observed property.';
    END IF;

    IF v_result_type = 'numeric' THEN
        IF NEW.id_unit IS NULL THEN
            SET NEW.id_unit = v_method_unit;
        ELSEIF (SELECT id_dimension FROM unit WHERE id_unit = NEW.id_unit) <> v_id_dimension THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'The unit of the result does not fit the observed property.';
        END IF;
    END IF;
END$$


/* A result stays as it was recorded. It can only be reviewed once and
   invalidated once. */

CREATE TRIGGER observation_before_update
BEFORE UPDATE ON observation
FOR EACH ROW
BEGIN
    IF NOT (    NEW.id_action <=> OLD.id_action
            AND NEW.id_observed_property <=> OLD.id_observed_property
            AND NEW.phenomenon_time <=> OLD.phenomenon_time
            AND NEW.result_time <=> OLD.result_time
            AND NEW.result_numeric <=> OLD.result_numeric
            AND NEW.result_text <=> OLD.result_text
            AND NEW.result_boolean <=> OLD.result_boolean
            AND NEW.result_timestamp <=> OLD.result_timestamp
            AND NEW.censoring <=> OLD.censoring
            AND NEW.id_unit <=> OLD.id_unit)
    THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Results cannot be edited. Invalidate the wrong result and record a new one.';
    END IF;

    IF OLD.reviewed_at IS NOT NULL
       AND NOT (NEW.reviewed_at <=> OLD.reviewed_at AND NEW.id_reviewer <=> OLD.id_reviewer)
    THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A review cannot be changed once it is recorded.';
    END IF;

    IF OLD.invalidated_at IS NOT NULL
       AND NOT (NEW.invalidated_at <=> OLD.invalidated_at AND NEW.invalidation_reason <=> OLD.invalidation_reason)
    THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'An invalidation cannot be changed or undone.';
    END IF;

    IF OLD.reviewed_at IS NULL AND NEW.reviewed_at IS NOT NULL AND NEW.invalidated_at IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'An invalidated result cannot be reviewed.';
    END IF;
END$$


CREATE TRIGGER observation_before_delete
BEFORE DELETE ON observation
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Results are never deleted. Invalidate the result instead.';
END$$


CREATE TRIGGER observation_input_before_update
BEFORE UPDATE ON observation_input
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'The inputs of a calculated result cannot be changed.';
END$$


CREATE TRIGGER observation_input_before_delete
BEFORE DELETE ON observation_input
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'The inputs of a calculated result cannot be deleted.';
END$$


/* An action can only finish once every required property of its method has
   a valid result. */

CREATE TRIGGER action_finish_needs_results
BEFORE UPDATE ON action
FOR EACH ROW
FOLLOWS action_before_update
BEGIN
    DECLARE v_missing   VARCHAR(2000);
    DECLARE v_message   VARCHAR(2500);

    IF OLD.finished_at IS NULL AND NEW.finished_at IS NOT NULL THEN
        SELECT      GROUP_CONCAT(observed_property.name ORDER BY observed_property.name SEPARATOR ', ')
        INTO        v_missing
        FROM        method_property
        JOIN        observed_property
                        ON observed_property.id_observed_property = method_property.id_observed_property
        WHERE       method_property.id_method_version = NEW.id_method_version
          AND       method_property.is_required
          AND       NOT EXISTS (
                        SELECT  1
                        FROM    observation
                        WHERE   observation.id_action = NEW.id_action
                          AND   observation.id_observed_property = method_property.id_observed_property
                          AND   observation.invalidated_at IS NULL
                    );

        IF v_missing IS NOT NULL THEN
            SET v_message = CONCAT('The action cannot finish; these results are missing: ', v_missing, '.');
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_message;
        END IF;
    END IF;
END$$


/* A number as text with the given number of decimals, rounded half up.
   Without a number of decimals, trailing zeros are removed. */

CREATE FUNCTION format_decimal(p_value DECIMAL(38,12), p_decimal_places TINYINT)
RETURNS VARCHAR(60)
DETERMINISTIC
BEGIN
    IF p_value IS NULL THEN
        RETURN NULL;
    ELSEIF p_decimal_places IS NULL THEN
        RETURN TRIM(TRAILING '.' FROM TRIM(TRAILING '0' FROM CAST(p_value AS CHAR)));
    ELSE
        RETURN REPLACE(FORMAT(p_value, p_decimal_places, 'en_US'), ',', '');
    END IF;
END$$


/* A result the way it is shown and reported: converted into the unit of the
   method, rounded to the method's decimal places, and written as "< LOQ" if
   it is below the limit of quantification. */

CREATE FUNCTION format_result(p_id_observation INTEGER)
RETURNS VARCHAR(1000)
READS SQL DATA
BEGIN
    DECLARE v_result_type       VARCHAR(10);
    DECLARE v_numeric           DECIMAL(38,12);
    DECLARE v_text              VARCHAR(1000);
    DECLARE v_boolean           BOOLEAN;
    DECLARE v_timestamp         TIMESTAMP;
    DECLARE v_censoring         CHAR(1);
    DECLARE v_decimal_places    TINYINT;
    DECLARE v_loq               DECIMAL(38,12);

    SELECT  observed_property.result_type,
            convert_unit(observation.result_numeric, observation.id_unit, method_property.id_unit),
            observation.result_text,
            observation.result_boolean,
            observation.result_timestamp,
            observation.censoring,
            method_property.decimal_places,
            method_property.loq
    INTO    v_result_type, v_numeric, v_text, v_boolean, v_timestamp,
            v_censoring, v_decimal_places, v_loq
    FROM    observation
    JOIN    action              ON action.id_action = observation.id_action
    JOIN    method_property     ON method_property.id_method_version = action.id_method_version
                               AND method_property.id_observed_property = observation.id_observed_property
    JOIN    observed_property   ON observed_property.id_observed_property = observation.id_observed_property
    WHERE   observation.id_observation = p_id_observation;

    RETURN CASE v_result_type
        WHEN 'text'      THEN v_text
        WHEN 'boolean'   THEN IF(v_boolean, 'yes', 'no')
        WHEN 'timestamp' THEN DATE_FORMAT(v_timestamp, '%Y-%m-%d %H:%i')
        WHEN 'numeric'   THEN
            CASE
                WHEN v_censoring IS NOT NULL THEN CONCAT(v_censoring, ' ', format_decimal(v_numeric, v_decimal_places))
                WHEN v_numeric < v_loq       THEN CONCAT('< ', format_decimal(v_loq, v_decimal_places))
                ELSE format_decimal(v_numeric, v_decimal_places)
            END
    END;
END$$

DELIMITER ;
