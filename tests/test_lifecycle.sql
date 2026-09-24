-- uses: seed
/* The lifecycle of a sample: planning with implications, prerequisites,
   closing a sample, cancelling, and what cannot change afterwards. */

SET @m_grab       = (SELECT id_method FROM method WHERE name = 'grab sampling, surface water');
SET @m_receipt    = (SELECT id_method FROM method WHERE name = 'sample receipt');
SET @m_disposal   = (SELECT id_method FROM method WHERE name = 'disposal');
SET @m_aliquoting = (SELECT id_method FROM method WHERE name = 'aliquoting');
SET @m_filtration = (SELECT id_method FROM method WHERE name = 'membrane filtration 0.45 µm');
SET @m_ic         = (SELECT id_method FROM method WHERE name = 'anions by ion chromatography');
SET @m_icp        = (SELECT id_method FROM method WHERE name = 'metals by ICP-OES');
SET @m_hardness   = (SELECT id_method FROM method WHERE name = 'total hardness from Ca and Mg');
SET @mira         = (SELECT id_person FROM person WHERE given_name = 'Mira');
SET @p_arrival    = (SELECT id_observed_property FROM observed_property WHERE name = 'temperature on arrival');

INSERT INTO sample (code, sample_kind) VALUES ('T-1', 'material');
SET @t1 = LAST_INSERT_ID();
INSERT INTO sample_source (id_sample, id_source_sample)
SELECT @t1, id_sample FROM sample WHERE code = 'MW-P1';

/* Returns the action of a method on a sample (the latest, if several). */
CREATE FUNCTION action_of(p_id_sample INTEGER, p_id_method INTEGER) RETURNS INTEGER READS SQL DATA
    RETURN (SELECT MAX(action.id_action) FROM action
            JOIN method_version ON method_version.id_method_version = action.id_method_version
            WHERE action.id_sample = p_id_sample AND method_version.id_method = p_id_method);


/* Planning brings along what is implied, transitively: grab sampling implies
   receipt, and receipt implies disposal. */

CALL plan_action(@t1, @m_grab, NULL, @mira, NULL, @sampling);
CALL assert_equal((SELECT COUNT(*) FROM action WHERE id_sample = @t1), 3, 'sampling, receipt and disposal are planned');
CALL assert_equal((SELECT COUNT(*) FROM action WHERE id_implied_by_action = @sampling), 2,
                  'implied actions point back to the action that caused them');
CALL assert_true(action_of(@t1, @m_disposal) IS NOT NULL, 'disposal is implied through receipt');

CALL plan_action(@t1, @m_grab, NULL, NULL, NULL, @sampling_again);
CALL assert_equal((SELECT COUNT(*) FROM action WHERE id_sample = @t1), 4,
                  'planning again adds the action itself, but no second receipt or disposal');
CALL cancel_action(@sampling_again, 'planned twice by mistake');


/* Prerequisites */

SET @receipt = action_of(@t1, @m_receipt);
CALL assert_fails("CALL start_action(@receipt, @mira, NULL)",
                  'grab sampling, surface water', 'receipt waits for the sampling');
CALL assert_equal((SELECT waiting_for FROM v_action WHERE id_action = @receipt),
                  'grab sampling, surface water', 'v_action says what the receipt waits for');

CALL start_action(@sampling, @mira, NULL);
CALL finish_action(@sampling, NULL);
CALL assert_fails("DELETE FROM sample_source WHERE id_sample = @t1", 'cannot be removed any more',
                  'once work has started, the lineage of a sample is fixed');
CALL start_action(@receipt, @mira, NULL);
CALL assert_equal((SELECT status FROM action WHERE id_action = @receipt), 'started', 'receipt started after sampling');

/* A prerequisite met on an ancestor counts: the aliquot was not received
   itself, but the bottle it came from was. */
INSERT INTO sample (code, sample_kind) VALUES ('T-1-A', 'material');
SET @t1a = LAST_INSERT_ID();
INSERT INTO sample_source (id_sample, id_source_sample) VALUES (@t1a, @t1);

CALL plan_action(@t1a, @m_ic, NULL, NULL, NULL, @ic);
SET @filtration = action_of(@t1a, @m_filtration);
CALL assert_true(@filtration IS NOT NULL, 'planning IC brings filtration along');
CALL assert_fails("CALL start_action(@ic, @mira, NULL)", 'membrane filtration', 'IC waits for filtration');
CALL assert_fails("CALL start_action(@filtration, @mira, NULL)", 'sample receipt',
                  'filtration waits for the receipt, which is still running');

INSERT INTO observation (id_action, id_observed_property, result_numeric) VALUES (@receipt, @p_arrival, 5.0);
CALL finish_action(@receipt, NULL);
CALL start_action(@filtration, @mira, NULL);
CALL assert_equal((SELECT status FROM action WHERE id_action = @filtration), 'started',
                  'the receipt of the bottle satisfies the prerequisite of its aliquot');


/* Closing a sample */

SET @disposal = action_of(@t1, @m_disposal);
CALL plan_action(@t1, @m_aliquoting, NULL, NULL, NULL, @open_on_t1);
CALL assert_fails("CALL start_action(@disposal, @mira, NULL)", 'still open on it',
                  'disposal waits until nothing else is open on the sample');
CALL assert_equal((SELECT waiting_for FROM v_action WHERE id_action = @disposal),
                  'all other actions on the sample', 'v_action says what the disposal waits for');

CALL cancel_action(@open_on_t1, 'not needed');
CALL start_action(@disposal, @mira, NULL);
CALL finish_action(@disposal, NULL);

CALL assert_equal(closing_action_of(@t1), @disposal, 'the disposal closes the sample');
CALL assert_fails("CALL plan_action(@t1, @m_receipt, NULL, NULL, NULL, @x)", 'is closed',
                  'nothing can be planned for a closed sample');
CALL assert_equal((SELECT is_closed FROM v_sample_overview WHERE id_sample = @t1), 1, 'v_sample_overview shows it');


/* Cancelling */

INSERT INTO sample (code, sample_kind) VALUES ('T-2', 'material');
SET @t2 = LAST_INSERT_ID();
CALL plan_action(@t2, @m_grab, NULL, NULL, NULL, @sampling2);

CALL assert_fails("CALL cancel_action(@sampling2, '  ')", 'give a reason', 'cancelling needs a reason');
CALL cancel_action(@sampling2, 'customer called it off');
CALL assert_equal((SELECT COUNT(*) FROM action WHERE id_sample = @t2 AND status = 'cancelled'), 3,
                  'what the sampling implied is cancelled with it');
CALL assert_fails("CALL cancel_action(@sampling, 'too late')", 'Only planned or started',
                  'finished actions cannot be cancelled');

/* A cancelled implied action is planned again when needed. */
CALL plan_action(@t2, @m_grab, NULL, NULL, NULL, @sampling3);
CALL assert_equal((SELECT COUNT(*) FROM action WHERE id_sample = @t2 AND status = 'planned'), 3,
                  'replanning brings receipt and disposal back');


/* What cannot change */

CALL assert_fails("UPDATE action SET id_performer = NULL WHERE id_action = @sampling",
                  'except for their note', 'finished actions are history');
UPDATE action SET note = 'bottle label was smudged' WHERE id_action = @sampling;
CALL assert_equal((SELECT note FROM action WHERE id_action = @sampling), 'bottle label was smudged',
                  'the note of a finished action can still be amended');

CALL assert_fails("DELETE FROM action WHERE id_action = @sampling3", 'never deleted', 'actions are never deleted');
CALL assert_fails("UPDATE action SET id_sample = @t1 WHERE id_action = @sampling3", 'cannot be changed',
                  'an action stays with its sample');
CALL assert_fails("UPDATE action SET started_at = '2026-01-01' WHERE id_action = @filtration",
                  'cannot be changed once it is recorded', 'the start time is not rewritten');
CALL assert_fails("UPDATE action SET id_method_version = current_method_version(@m_icp) WHERE id_action = @sampling3",
                  'another version of the same method', 'an action does not change its method');
CALL assert_fails(CONCAT("INSERT INTO action (id_sample, id_method_version, started_at) VALUES (",
                         @t2, ", current_method_version(", @m_grab, "), CURRENT_TIMESTAMP)"),
                  'New actions are planned actions', 'actions cannot be inserted as started');

UPDATE method SET retired_at = CURRENT_TIMESTAMP WHERE id_method = @m_hardness;
CALL assert_fails("CALL plan_action(@t2, @m_hardness, NULL, NULL, NULL, @x)", 'no version that is valid now',
                  'retired methods cannot be planned');


/* The worklist */

CALL assert_true((SELECT COUNT(*) FROM v_worklist WHERE sample_code = 'T-2') = 3, 'open actions are on the worklist');
CALL assert_equal((SELECT status FROM v_worklist LIMIT 1), 'started', 'actions in progress come first');
