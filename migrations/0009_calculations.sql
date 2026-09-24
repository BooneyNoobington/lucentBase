/* Calculated results.

   A calculated property has a formula (method_property.formula): a MariaDB
   expression over named inputs, such as

       reading * dilution
       0.1399 * calcium + 0.2307 * magnesium

   formula_input says where each input comes from. calculate_action() gathers
   the input observations, converts them into the units the formula expects,
   evaluates the formula and stores the result as a new observation. It also
   records which observations went in (observation_input), so every
   calculated result can be traced back to its raw data.

   Why store calculated results at all, instead of computing them whenever
   they are shown? Because MariaDB cannot evaluate a formula that is stored as
   data inside a view; that needs dynamic SQL, which only procedures may use.
   And because a result that silently changes after it was reported is worse
   than a stale one. So results are stored with their inputs, and
   v_stale_calculation shows every calculated result whose inputs have
   changed since. Recalculating is one call to calculate_action().

   Formulas are executed as SQL with the rights of whoever runs the
   calculation. Whoever may edit formulas must be trusted like someone who may
   write SQL. */


DELIMITER $$


/* Calculates all formula properties of an action, in the order they were
   defined, so a formula may use the result of an earlier one.

   A formula whose inputs are not all available is skipped. A formula whose
   result has not changed (same value, same inputs) is left alone. Otherwise
   the previous result is invalidated and the new one recorded. */

CREATE PROCEDURE calculate_action(p_id_action INTEGER)
MODIFIES SQL DATA
SQL SECURITY INVOKER
BEGIN
    DECLARE v_done                  BOOLEAN DEFAULT FALSE;
    DECLARE v_status                VARCHAR(10);
    DECLARE v_id_sample             INTEGER;
    DECLARE v_id_method_property    INTEGER;
    DECLARE v_id_observed_property  INTEGER;
    DECLARE v_formula               VARCHAR(1000);
    DECLARE v_id_unit               INTEGER;
    DECLARE v_input_count           INTEGER;
    DECLARE v_available_count       INTEGER;
    DECLARE v_columns               TEXT;
    DECLARE v_result                DECIMAL(38,12);
    DECLARE v_id_previous           INTEGER;
    DECLARE v_previous_result       DECIMAL(38,12);
    DECLARE v_inputs_dropped        INTEGER;
    DECLARE v_inputs_added          INTEGER;
    DECLARE v_id_new                INTEGER;
    DECLARE v_message               VARCHAR(1500);

    DECLARE formula_cursor CURSOR FOR
        SELECT      method_property.id_method_property,
                    method_property.id_observed_property,
                    method_property.formula,
                    method_property.id_unit
        FROM        action
        JOIN        method_property     ON method_property.id_method_version = action.id_method_version
        WHERE       action.id_action = p_id_action
          AND       method_property.formula IS NOT NULL
        ORDER BY    method_property.id_method_property;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;

    SET v_status = (SELECT status FROM action WHERE id_action = p_id_action);
    SET v_id_sample = (SELECT id_sample FROM action WHERE id_action = p_id_action);

    IF v_status IS NULL OR v_status NOT IN ('started', 'finished') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Only started or finished actions can be calculated.';
    END IF;

    /* Work tables for one formula at a time: the input observations with
       their converted values, and one value per variable. */
    CREATE OR REPLACE TEMPORARY TABLE calculation_input
    (
        variable_name   VARCHAR(40)     NOT NULL,
        id_observation  INTEGER         NOT NULL,
        value           DECIMAL(38,12)
    );
    CREATE OR REPLACE TEMPORARY TABLE calculation_value
    (
        variable_name   VARCHAR(40)     NOT NULL,
        value           DECIMAL(38,12)
    );

    OPEN formula_cursor;

    formula_loop: LOOP
        FETCH formula_cursor INTO v_id_method_property, v_id_observed_property, v_formula, v_id_unit;
        IF v_done THEN
            LEAVE formula_loop;
        END IF;

        DELETE FROM calculation_input;
        DELETE FROM calculation_value;

        /* 1. Find the input observations. For scope 'sample', take those of
              the nearest sample in the lineage that has any. */
        INSERT INTO calculation_input (variable_name, id_observation, value)
        WITH RECURSIVE lineage_paths (id_sample, generations) AS
        (
            SELECT  v_id_sample, 0
            UNION
            SELECT  sample_source.id_source_sample, lineage_paths.generations + 1
            FROM    lineage_paths
            JOIN    sample_source   ON sample_source.id_sample = lineage_paths.id_sample
        ),
        lineage AS
        (
            SELECT      id_sample, MIN(generations) AS generations
            FROM        lineage_paths
            GROUP BY    id_sample
        ),
        candidate AS
        (
            SELECT  formula_input.variable_name,
                    formula_input.aggregation,
                    observation.id_observation,
                    observation.result_time,
                    lineage.generations,
                    CASE
                        WHEN formula_input.below_loq <> 'as measured'
                             AND (observation.censoring = '<'
                                  OR convert_unit(observation.result_numeric, observation.id_unit,
                                                  input_property.id_unit) < input_property.loq)
                        THEN
                            CASE formula_input.below_loq
                                WHEN 'zero' THEN 0
                                WHEN 'half loq' THEN
                                    COALESCE(convert_unit(input_property.loq, input_property.id_unit, formula_input.id_unit),
                                             convert_unit(observation.result_numeric, observation.id_unit, formula_input.id_unit)) / 2
                                WHEN 'loq' THEN
                                    COALESCE(convert_unit(input_property.loq, input_property.id_unit, formula_input.id_unit),
                                             convert_unit(observation.result_numeric, observation.id_unit, formula_input.id_unit))
                            END
                        ELSE
                            convert_unit(observation.result_numeric, observation.id_unit, formula_input.id_unit)
                    END AS value
            FROM    formula_input
            JOIN    observation
                        ON observation.id_observed_property = formula_input.id_observed_property
                       AND observation.invalidated_at IS NULL
            JOIN    action AS input_action
                        ON input_action.id_action = observation.id_action
                       AND input_action.cancelled_at IS NULL
            JOIN    method_property AS input_property
                        ON input_property.id_method_version = input_action.id_method_version
                       AND input_property.id_observed_property = observation.id_observed_property
            JOIN    lineage
                        ON lineage.id_sample = input_action.id_sample
            WHERE   formula_input.id_method_property = v_id_method_property
              AND   (formula_input.scope = 'sample' OR observation.id_action = p_id_action)
        ),
        nearest AS
        (
            SELECT      variable_name, MIN(generations) AS generations
            FROM        candidate
            GROUP BY    variable_name
        ),
        ranked AS
        (
            SELECT  candidate.variable_name,
                    candidate.aggregation,
                    candidate.id_observation,
                    candidate.value,
                    ROW_NUMBER() OVER (PARTITION BY candidate.variable_name
                                       ORDER BY candidate.result_time DESC, candidate.id_observation DESC)
                        AS recency
            FROM    candidate
            JOIN    nearest     ON nearest.variable_name = candidate.variable_name
                               AND nearest.generations = candidate.generations
        )
        SELECT  variable_name, id_observation, value
        FROM    ranked
        WHERE   aggregation <> 'latest' OR recency = 1;

        /* 2. Without a value for every input there is no result. A result
              calculated earlier from inputs that are gone is withdrawn. */
        SET v_input_count = (SELECT COUNT(*) FROM formula_input
                             WHERE id_method_property = v_id_method_property);
        SET v_available_count = (SELECT COUNT(DISTINCT variable_name) FROM calculation_input);

        IF v_input_count = 0 THEN
            SET v_message = CONCAT('The formula "', v_formula, '" has no inputs.');
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_message;
        END IF;

        IF v_available_count < v_input_count THEN
            UPDATE  observation
            SET     invalidated_at = CURRENT_TIMESTAMP,
                    invalidation_reason = 'Its inputs are no longer available.'
            WHERE   id_action = p_id_action
              AND   id_observed_property = v_id_observed_property
              AND   invalidated_at IS NULL;
            ITERATE formula_loop;
        END IF;

        /* 3. One value per variable. */
        INSERT INTO calculation_value (variable_name, value)
        SELECT      calculation_input.variable_name,
                    CASE formula_input.aggregation
                        WHEN 'mean'   THEN AVG(calculation_input.value)
                        WHEN 'min'    THEN MIN(calculation_input.value)
                        WHEN 'max'    THEN MAX(calculation_input.value)
                        WHEN 'sum'    THEN SUM(calculation_input.value)
                        WHEN 'count'  THEN COUNT(*)
                        WHEN 'latest' THEN MAX(calculation_input.value)
                    END
        FROM        calculation_input
        JOIN        formula_input   ON formula_input.id_method_property = v_id_method_property
                                   AND formula_input.variable_name = calculation_input.variable_name
        GROUP BY    calculation_input.variable_name, formula_input.aggregation;

        /* 4. Evaluate the formula, with one column per variable:
              SELECT <formula> FROM (SELECT <value of x> AS x, ...) AS input */
        SET v_columns = (
            SELECT  GROUP_CONCAT(CONCAT('MAX(CASE WHEN variable_name = ', QUOTE(variable_name),
                                        ' THEN value END) AS `', variable_name, '`')
                                 SEPARATOR ', ')
            FROM    formula_input
            WHERE   id_method_property = v_id_method_property
        );

        SET @lucent_calculation_result = NULL;
        SET @lucent_calculation = CONCAT('SELECT ROUND((', v_formula, '), 12) ',
                                         'INTO @lucent_calculation_result ',
                                         'FROM (SELECT ', v_columns, ' FROM calculation_value) AS input');
        PREPARE calculation FROM @lucent_calculation;
        EXECUTE calculation;
        DEALLOCATE PREPARE calculation;
        SET v_result = @lucent_calculation_result;

        IF v_result IS NULL THEN
            SET v_message = CONCAT('The formula "', v_formula, '" gave no result (a division by zero?).');
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_message;
        END IF;

        /* 5. Keep the previous result if nothing changed, else replace it. */
        SET v_id_previous = (
            SELECT      id_observation
            FROM        observation
            WHERE       id_action = p_id_action
              AND       id_observed_property = v_id_observed_property
              AND       invalidated_at IS NULL
            ORDER BY    id_observation DESC
            LIMIT       1
        );
        SET v_previous_result = (SELECT result_numeric FROM observation WHERE id_observation = v_id_previous);
        SET v_inputs_dropped = (
            SELECT  COUNT(*)
            FROM    observation_input
            WHERE   id_observation = v_id_previous
              AND   id_input_observation NOT IN (SELECT id_observation FROM calculation_input)
        );
        SET v_inputs_added = (
            SELECT  COUNT(*)
            FROM    calculation_input
            WHERE   id_observation NOT IN (SELECT id_input_observation FROM observation_input
                                           WHERE id_observation = v_id_previous)
        );

        IF v_id_previous IS NULL
           OR v_previous_result <> v_result
           OR v_inputs_dropped > 0
           OR v_inputs_added > 0
        THEN
            UPDATE  observation
            SET     invalidated_at = CURRENT_TIMESTAMP,
                    invalidation_reason = 'Recalculated.'
            WHERE   id_observation = v_id_previous;

            INSERT INTO observation (id_action, id_observed_property, result_numeric, id_unit)
            VALUES (p_id_action, v_id_observed_property, v_result, v_id_unit);
            SET v_id_new = LAST_INSERT_ID();

            INSERT INTO observation_input (id_observation, id_input_observation)
            SELECT DISTINCT v_id_new, id_observation
            FROM   calculation_input;
        END IF;
    END LOOP;

    CLOSE formula_cursor;

    DROP TEMPORARY TABLE calculation_input;
    DROP TEMPORARY TABLE calculation_value;
END$$

DELIMITER ;


/* Calculated results that may no longer be right, with the reason:

   - one of their inputs has been invalidated (or its action cancelled);
   - an observation that would be an input has been recorded after the
     calculation. This errs on the side of caution: it may flag a result
     whose recalculation turns out to give the same value;
   - no inputs are recorded at all, so the value was typed in rather than
     calculated.

   Recalculate with CALL calculate_action(<action>). */

CREATE VIEW v_stale_calculation AS
SELECT      calculated.id_observation,
            calculated.id_action,
            'An input has been invalidated.' AS reason
FROM        observation AS calculated
JOIN        observation_input   ON observation_input.id_observation = calculated.id_observation
JOIN        observation AS input
                ON input.id_observation = observation_input.id_input_observation
JOIN        action AS input_action
                ON input_action.id_action = input.id_action
WHERE       calculated.invalidated_at IS NULL
  AND       (input.invalidated_at IS NOT NULL OR input_action.cancelled_at IS NOT NULL)

UNION

SELECT      calculated.id_observation,
            calculated.id_action,
            'A newer input has been recorded since.'
FROM        observation AS calculated
JOIN        action AS calculating_action
                ON calculating_action.id_action = calculated.id_action
JOIN        method_property
                ON method_property.id_method_version = calculating_action.id_method_version
               AND method_property.id_observed_property = calculated.id_observed_property
JOIN        formula_input
                ON formula_input.id_method_property = method_property.id_method_property
JOIN        v_sample_lineage AS lineage
                ON lineage.id_sample = calculating_action.id_sample
JOIN        action AS input_action
                ON input_action.id_sample = lineage.id_ancestor_sample
               AND input_action.cancelled_at IS NULL
JOIN        observation AS newer
                ON newer.id_action = input_action.id_action
               AND newer.id_observed_property = formula_input.id_observed_property
               AND newer.invalidated_at IS NULL
               AND newer.id_observation > calculated.id_observation
WHERE       calculated.invalidated_at IS NULL
  AND       method_property.formula IS NOT NULL
  AND       (formula_input.scope = 'sample' OR newer.id_action = calculated.id_action)
  AND       NOT EXISTS (
                SELECT  1
                FROM    observation_input
                WHERE   observation_input.id_observation = calculated.id_observation
                  AND   observation_input.id_input_observation = newer.id_observation
            )

UNION

SELECT      calculated.id_observation,
            calculated.id_action,
            'No inputs are recorded; the value was typed in, not calculated.'
FROM        observation AS calculated
JOIN        action AS calculating_action
                ON calculating_action.id_action = calculated.id_action
JOIN        method_property
                ON method_property.id_method_version = calculating_action.id_method_version
               AND method_property.id_observed_property = calculated.id_observed_property
WHERE       calculated.invalidated_at IS NULL
  AND       method_property.formula IS NOT NULL
  AND       NOT EXISTS (
                SELECT  1
                FROM    observation_input
                WHERE   observation_input.id_observation = calculated.id_observation
            );
