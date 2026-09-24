-- uses: seed
/* Results: what may be recorded, how they are shown, and that they are never
   edited or deleted. */

SET @m_grab       = (SELECT id_method FROM method WHERE name = 'grab sampling, surface water');
SET @m_receipt    = (SELECT id_method FROM method WHERE name = 'sample receipt');
SET @m_filtration = (SELECT id_method FROM method WHERE name = 'membrane filtration 0.45 µm');
SET @m_ic         = (SELECT id_method FROM method WHERE name = 'anions by ion chromatography');
SET @mira         = (SELECT id_person FROM person WHERE given_name = 'Mira');
SET @erika        = (SELECT id_person FROM person WHERE given_name = 'Erika');
SET @p_arrival    = (SELECT id_observed_property FROM observed_property WHERE name = 'temperature on arrival');
SET @p_appearance = (SELECT id_observed_property FROM observed_property WHERE name = 'appearance');
SET @p_reading    = (SELECT id_observed_property FROM observed_property WHERE name = 'nitrate in measuring solution');
SET @p_dilution   = (SELECT id_observed_property FROM observed_property WHERE name = 'dilution factor');
SET @p_calcium    = (SELECT id_observed_property FROM observed_property WHERE name = 'calcium');
SET @ug_l         = (SELECT id_unit FROM unit WHERE symbol = 'µg/L');
SET @celsius      = (SELECT id_unit FROM unit WHERE symbol = '°C');

/* A bottle that has been sampled, and whose receipt is under way. */
INSERT INTO sample (code, sample_kind) VALUES ('O-1', 'material');
SET @o1 = LAST_INSERT_ID();
CALL plan_action(@o1, @m_grab, NULL, NULL, NULL, @sampling);
CALL start_action(@sampling, @mira, NULL);
CALL finish_action(@sampling, NULL);
SET @receipt = (SELECT id_action FROM action WHERE id_implied_by_action = @sampling
                AND id_method_version = current_method_version(@m_receipt));


/* What may be recorded */

CALL assert_fails("INSERT INTO observation (id_action, id_observed_property, result_numeric) VALUES (@receipt, @p_arrival, 5)",
                  'started and not yet finished', 'no results for an action that has not started');

CALL start_action(@receipt, @mira, NULL);

CALL assert_fails("INSERT INTO observation (id_action, id_observed_property, result_numeric) VALUES (@receipt, @p_calcium, 5)",
                  'does not determine this property', 'only properties of the method (OMS: suitable property)');
CALL assert_fails("INSERT INTO observation (id_action, id_observed_property, result_text) VALUES (@receipt, @p_arrival, 'cold')",
                  'does not have the type', 'the result must have the type of the property');
CALL assert_fails("INSERT INTO observation (id_action, id_observed_property, result_numeric, result_text) VALUES (@receipt, @p_arrival, 5, 'cold')",
                  'observation_has_exactly_one_result', 'one result per observation');
CALL assert_fails("INSERT INTO observation (id_action, id_observed_property, result_numeric, id_unit) VALUES (@receipt, @p_arrival, 5, @ug_l)",
                  'does not fit the observed property', 'the unit must fit the property');
CALL assert_fails("INSERT INTO observation (id_action, id_observed_property, result_text, censoring) VALUES (@receipt, @p_appearance, 'clear', '<')",
                  'only_numeric_results_have_censoring_and_unit', 'only numbers can be censored');

INSERT INTO observation (id_action, id_observed_property, result_numeric) VALUES (@receipt, @p_arrival, 5.04);
SET @arrival = LAST_INSERT_ID();
CALL assert_equal((SELECT id_unit FROM observation WHERE id_observation = @arrival), @celsius,
                  'the unit of the method is filled in (OMS: unit of measure)');
CALL assert_equal(format_result(@arrival), '5.0', 'shown with the decimals of the method');

INSERT INTO observation (id_action, id_observed_property, result_text) VALUES (@receipt, @p_appearance, 'clear');
CALL assert_equal(format_result(LAST_INSERT_ID()), 'clear', 'text results are shown as they are');

CALL finish_action(@receipt, NULL);
CALL assert_fails("INSERT INTO observation (id_action, id_observed_property, result_numeric) VALUES (@receipt, @p_arrival, 5.1)",
                  'started and not yet finished', 'no new measurements once the action has finished');


/* Required results */

INSERT INTO sample (code, sample_kind) VALUES ('O-1-A', 'material');
SET @o1a = LAST_INSERT_ID();
INSERT INTO sample_source (id_sample, id_source_sample) VALUES (@o1a, @o1);
CALL plan_action(@o1a, @m_ic, NULL, NULL, NULL, @ic);
SET @filtration = (SELECT id_action FROM action WHERE id_implied_by_action = @ic);
CALL start_action(@filtration, @mira, NULL);
CALL finish_action(@filtration, NULL);
CALL start_action(@ic, @mira, NULL);

INSERT INTO observation (id_action, id_observed_property, result_numeric) VALUES (@ic, @p_reading, 4.2);
CALL assert_fails("CALL finish_action(@ic, NULL)", 'dilution factor, nitrate',
                  'an action cannot finish while required results are missing');


/* Display: units, LOQ and censoring */

/* 3100 µg/L entered in µg/L is 3.1 mg/L, shown in the method's unit. */
INSERT INTO observation (id_action, id_observed_property, result_numeric, id_unit) VALUES (@ic, @p_reading, 3100, @ug_l);
SET @in_ug = LAST_INSERT_ID();
CALL assert_equal(format_result(@in_ug), '3.10', 'converted into the unit of the method');
CALL assert_number((SELECT raw_value FROM v_observation WHERE id_observation = @in_ug), 3100,
                   'the raw value stays as it was entered');
CALL assert_equal((SELECT raw_unit FROM v_observation WHERE id_observation = @in_ug), 'µg/L',
                  'and so does its unit');

INSERT INTO observation (id_action, id_observed_property, result_numeric, censoring) VALUES (@ic, @p_reading, 50, '>');
CALL assert_equal(format_result(LAST_INSERT_ID()), '> 50.00', 'a value above the working range stays a limit');

INSERT INTO observation (id_action, id_observed_property, result_numeric) VALUES (@ic, @p_dilution, 1);
CALL finish_action(@ic, NULL);

/* nitrate = mean reading * dilution = (4.2 + 3.1 + 50) / 3; the method's LOQ
   is 0.5 mg/L, so tiny values show up as "< 0.5". */
CALL assert_equal((SELECT result FROM v_observation WHERE id_action = @ic AND property = 'nitrate' AND is_valid),
                  '19.1', 'the calculated result is displayed like any other');

CALL assert_equal((SELECT result FROM v_observation WHERE sample_code = '2026-0917-02-A' AND property = 'nitrate'),
                  '< 0.5', 'a value below the LOQ is shown as "< LOQ"');
CALL assert_number((SELECT raw_value FROM v_observation WHERE sample_code = '2026-0917-02-A' AND property = 'nitrate'),
                   0.21, 'but the exact value is kept');
CALL assert_equal((SELECT result FROM v_observation WHERE sample_code = '2026-0917-02-M' AND property = 'lead'),
                  '< 0.002', 'a value reported as a limit by the device is shown as that limit');


/* Phenomenon time: for lab measurements, the time the water was sampled */

CALL assert_equal((SELECT phenomenon_time FROM v_observation WHERE id_observation = @in_ug),
                  (SELECT started_at FROM action WHERE id_action = @sampling),
                  'an aliquot measured in the lab reports the sampling time of its bottle');
CALL assert_equal((SELECT phenomenon_time FROM v_observation WHERE sample_code = 'MW-P1' AND property = 'pH value'),
                  '2026-09-15 09:05:00', 'an in-situ value reports the time it was measured');


/* Results are never edited or deleted */

CALL assert_fails("UPDATE observation SET result_numeric = 4.3 WHERE id_observation = @arrival",
                  'Results cannot be edited', 'a result stays as it was recorded');
CALL assert_fails("DELETE FROM observation WHERE id_observation = @arrival",
                  'never deleted', 'results are never deleted');

CALL assert_fails("CALL invalidate_observation(@arrival, '')", 'give a reason', 'invalidating needs a reason');
CALL invalidate_observation(@arrival, 'thermometer was not calibrated');
CALL assert_fails("CALL invalidate_observation(@arrival, 'again')", 'no valid result', 'invalid results stay invalid');
CALL assert_fails("UPDATE observation SET invalidated_at = NULL, invalidation_reason = NULL WHERE id_observation = @arrival",
                  'cannot be changed or undone', 'an invalidation cannot be undone');


/* Review */

CALL assert_fails("CALL review_action(@filtration, NULL)", 'Who is reviewing', 'a review needs a reviewer');
CALL review_action(@receipt, @erika);
CALL assert_true((SELECT reviewed_at IS NULL FROM observation WHERE id_observation = @arrival),
                 'invalidated results are not reviewed');
CALL assert_equal((SELECT COUNT(*) FROM observation WHERE id_action = @receipt AND id_reviewer = @erika), 1,
                  'the valid result of the receipt is reviewed');
CALL assert_fails(CONCAT("UPDATE observation SET id_reviewer = ", @mira, " WHERE id_action = ", @receipt, " AND reviewed_at IS NOT NULL"),
                  'review cannot be changed', 'a review is not rewritten');
