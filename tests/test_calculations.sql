-- uses: seed
/* Calculated results: formulas, their inputs, recalculation, below-LOQ
   rules and stale results. */

SET @m_grab       = (SELECT id_method FROM method WHERE name = 'grab sampling, surface water');
SET @m_ic         = (SELECT id_method FROM method WHERE name = 'anions by ion chromatography');
SET @m_icp        = (SELECT id_method FROM method WHERE name = 'metals by ICP-OES');
SET @m_hardness   = (SELECT id_method FROM method WHERE name = 'total hardness from Ca and Mg');
SET @mira         = (SELECT id_person FROM person WHERE given_name = 'Mira');
SET @p_reading    = (SELECT id_observed_property FROM observed_property WHERE name = 'nitrate in measuring solution');
SET @p_dilution   = (SELECT id_observed_property FROM observed_property WHERE name = 'dilution factor');
SET @p_nitrate    = (SELECT id_observed_property FROM observed_property WHERE name = 'nitrate');
SET @p_calcium    = (SELECT id_observed_property FROM observed_property WHERE name = 'calcium');
SET @p_magnesium  = (SELECT id_observed_property FROM observed_property WHERE name = 'magnesium');
SET @p_lead       = (SELECT id_observed_property FROM observed_property WHERE name = 'lead');
SET @p_hardness   = (SELECT id_observed_property FROM observed_property WHERE name = 'total hardness');
SET @mg_l         = (SELECT id_unit FROM unit WHERE symbol = 'mg/L');

/* The current valid result of a property in an action. */
CREATE FUNCTION result_of(p_id_action INTEGER, p_id_property INTEGER) RETURNS DECIMAL(38,12) READS SQL DATA
    RETURN (SELECT result_numeric FROM observation
            WHERE id_action = p_id_action AND id_observed_property = p_id_property AND invalidated_at IS NULL);

/* The anion aliquot of bottle 01 from the demo, measured once more. */
SET @anions = (SELECT id_sample FROM sample WHERE code = '2026-0917-01-A');
CALL plan_action(@anions, @m_ic, NULL, NULL, NULL, @ic);
CALL start_action(@ic, @mira, NULL);


/* Same-action formula over replicates: nitrate = mean(reading) * latest(dilution) */

INSERT INTO observation (id_action, id_observed_property, result_numeric) VALUES
    (@ic, @p_reading, 10.0),
    (@ic, @p_reading, 10.4),
    (@ic, @p_dilution, 2);
SET @reading_high = (SELECT id_observation FROM observation WHERE id_action = @ic AND result_numeric = 10.4);
CALL finish_action(@ic, NULL);

CALL assert_number(result_of(@ic, @p_nitrate), 20.4, 'nitrate = mean(10.0, 10.4) * 2');
SET @nitrate_first = (SELECT id_observation FROM observation
                      WHERE id_action = @ic AND id_observed_property = @p_nitrate AND invalidated_at IS NULL);
CALL assert_equal((SELECT COUNT(*) FROM observation_input WHERE id_observation = @nitrate_first), 3,
                  'the calculated result knows its three inputs');

CALL calculate_action(@ic);
CALL assert_equal((SELECT COUNT(*) FROM observation WHERE id_action = @ic AND id_observed_property = @p_nitrate), 1,
                  'calculating again without changes records nothing new');


/* An input is withdrawn: the result goes stale until it is recalculated. */

CALL invalidate_observation(@reading_high, 'air bubble in the sample loop');
CALL assert_equal((SELECT reason FROM v_stale_calculation WHERE id_observation = @nitrate_first),
                  'An input has been invalidated.', 'the result is flagged as stale');
CALL assert_fails("CALL review_action(@ic, @mira)", 'stale', 'stale results cannot be reviewed');

CALL calculate_action(@ic);
CALL assert_number(result_of(@ic, @p_nitrate), 20.0, 'recalculated from the remaining reading');
CALL assert_equal((SELECT invalidation_reason FROM observation WHERE id_observation = @nitrate_first),
                  'Recalculated.', 'the old result is invalidated, not overwritten');
CALL assert_equal((SELECT COUNT(*) FROM v_stale_calculation WHERE id_action = @ic), 0, 'nothing is stale any more');


/* Inputs from another action on the sample: total hardness uses calcium and
   magnesium from ICP-OES. A second ICP-OES run makes the result stale. */

SET @metals = (SELECT id_sample FROM sample WHERE code = '2026-0917-01-M');
SET @hardness = (SELECT action.id_action FROM action
                 JOIN method_version ON method_version.id_method_version = action.id_method_version
                 WHERE action.id_sample = @metals AND method_version.id_method = @m_hardness);
SET @hardness_first = (SELECT id_observation FROM observation
                       WHERE id_action = @hardness AND invalidated_at IS NULL);

CALL plan_action(@metals, @m_icp, NULL, NULL, NULL, @icp_again);
CALL start_action(@icp_again, @mira, NULL);
INSERT INTO observation (id_action, id_observed_property, result_numeric) VALUES
    (@icp_again, @p_calcium, 49.8),
    (@icp_again, @p_magnesium, 9.85),
    (@icp_again, @p_lead, 0.0029);
CALL finish_action(@icp_again, NULL);

CALL assert_equal((SELECT reason FROM v_stale_calculation WHERE id_observation = @hardness_first LIMIT 1),
                  'A newer input has been recorded since.', 'a new calcium value makes the hardness stale');

CALL calculate_action(@hardness);
/* mean calcium (48.2 + 49.8) / 2 = 49.0, mean magnesium (9.75 + 9.85) / 2 = 9.8:
   0.1399 * 49.0 + 0.2307 * 9.8 = 6.8551 + 2.26086 = 9.11596 */
CALL assert_number(result_of(@hardness, @p_hardness), 9.11596, 'hardness from the mean of both ICP-OES runs');
CALL assert_equal((SELECT COUNT(*) FROM observation_input
                   JOIN observation ON observation.id_observation = observation_input.id_observation
                   WHERE observation.id_action = @hardness AND observation.invalidated_at IS NULL), 4,
                  'two calcium and two magnesium values went in');


/* Below-LOQ rules and unit conversion of inputs.
   Lead in bottle 01: 0.0031 and 0.0029 mg/L, both below the LOQ of 0.005. */

INSERT INTO observed_property (name, result_type, id_dimension)
SELECT names.name, 'numeric', dimension.id_dimension
FROM   dimension,
       (SELECT 'lead, as measured' AS name UNION ALL SELECT 'lead, below LOQ as zero'
        UNION ALL SELECT 'lead, below LOQ as half LOQ' UNION ALL SELECT 'lead in µg/L') AS names
WHERE  dimension.name = 'mass concentration';

INSERT INTO method (name, kind) VALUES ('lead evaluation (test)', 'observation');
SET @m_lead = LAST_INSERT_ID();
INSERT INTO method_version (id_method, valid_from) VALUES (@m_lead, '2026-01-01');
SET @v_lead = LAST_INSERT_ID();

INSERT INTO method_property (id_method_version, id_observed_property, id_unit, formula)
SELECT @v_lead, id_observed_property, @mg_l, 'lead' FROM observed_property WHERE name LIKE 'lead, %' UNION ALL
SELECT @v_lead, id_observed_property, (SELECT id_unit FROM unit WHERE symbol = 'µg/L'), 'lead'
FROM   observed_property WHERE name = 'lead in µg/L';

INSERT INTO formula_input (id_method_property, variable_name, id_observed_property, id_unit, scope, aggregation, below_loq)
SELECT method_property.id_method_property, 'lead', @p_lead,
       IF(observed_property.name = 'lead in µg/L', (SELECT id_unit FROM unit WHERE symbol = 'µg/L'), @mg_l),
       'sample', 'mean',
       CASE observed_property.name
           WHEN 'lead, below LOQ as zero' THEN 'zero'
           WHEN 'lead, below LOQ as half LOQ' THEN 'half loq'
           ELSE 'as measured'
       END
FROM   method_property
JOIN   observed_property ON observed_property.id_observed_property = method_property.id_observed_property
WHERE  method_property.id_method_version = @v_lead;

CALL plan_action(@metals, @m_lead, NULL, NULL, NULL, @lead_evaluation);
CALL start_action(@lead_evaluation, @mira, NULL);
CALL finish_action(@lead_evaluation, NULL);

SET @as_measured = (SELECT id_observed_property FROM observed_property WHERE name = 'lead, as measured');
SET @as_zero     = (SELECT id_observed_property FROM observed_property WHERE name = 'lead, below LOQ as zero');
SET @as_half     = (SELECT id_observed_property FROM observed_property WHERE name = 'lead, below LOQ as half LOQ');
SET @in_ug       = (SELECT id_observed_property FROM observed_property WHERE name = 'lead in µg/L');

CALL assert_number(result_of(@lead_evaluation, @as_measured), 0.003, 'as measured: the mean of 0.0031 and 0.0029');
CALL assert_number(result_of(@lead_evaluation, @as_zero), 0, 'below LOQ as zero');
CALL assert_number(result_of(@lead_evaluation, @as_half), 0.0025, 'below LOQ as half the LOQ');
CALL assert_number(result_of(@lead_evaluation, @in_ug), 3, 'inputs are converted into the unit the formula expects');


/* Missing inputs: no result, and the action cannot finish without it. */

INSERT INTO sample (code, sample_kind) VALUES ('C-EMPTY', 'material');
SET @empty = LAST_INSERT_ID();
INSERT INTO action (id_sample, id_method_version) VALUES (@empty, current_method_version(@m_lead));
SET @lead_without_data = LAST_INSERT_ID();
CALL start_action(@lead_without_data, @mira, NULL);
CALL assert_fails("CALL finish_action(@lead_without_data, NULL)", 'these results are missing',
                  'without lead values there is nothing to calculate');


/* Values typed into a calculated property are flagged. */

INSERT INTO observation (id_action, id_observed_property, result_numeric) VALUES (@lead_without_data, @as_zero, 1);
CALL assert_equal((SELECT reason FROM v_stale_calculation WHERE id_observation = LAST_INSERT_ID()),
                  'No inputs are recorded; the value was typed in, not calculated.', 'a typed-in value is flagged');


/* A formula that fails loudly */

INSERT INTO observed_property (name, result_type, id_dimension)
SELECT 'broken', 'numeric', id_dimension FROM dimension WHERE name = 'mass concentration';
INSERT INTO method (name, kind) VALUES ('broken evaluation (test)', 'observation');
INSERT INTO method_version (id_method, valid_from) VALUES (LAST_INSERT_ID(), '2026-01-01');
SET @v_broken = LAST_INSERT_ID();
INSERT INTO method_property (id_method_version, id_observed_property, id_unit, formula)
SELECT @v_broken, id_observed_property, @mg_l, 'lead / 0' FROM observed_property WHERE name = 'broken';
INSERT INTO formula_input (id_method_property, variable_name, id_observed_property, id_unit, scope)
SELECT LAST_INSERT_ID(), 'lead', @p_lead, @mg_l, 'sample';
INSERT INTO action (id_sample, id_method_version) VALUES (@metals, @v_broken);
SET @broken = LAST_INSERT_ID();
CALL start_action(@broken, @mira, NULL);
CALL assert_fails("CALL finish_action(@broken, NULL)", 'gave no result', 'a division by zero is an error, not a silent NULL');
