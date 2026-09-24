-- uses: seed
/* Reports freeze what was reported. A later correction flags the report for
   amendment, and an amending report replaces it. */

SET @order        = (SELECT id_lab_order FROM lab_order WHERE order_number = '2026-0917');
SET @report       = (SELECT id_report FROM report WHERE report_number = 'R-2026-0917-1');
SET @m_icp        = (SELECT id_method FROM method WHERE name = 'metals by ICP-OES');
SET @m_hardness   = (SELECT id_method FROM method WHERE name = 'total hardness from Ca and Mg');
SET @mira         = (SELECT id_person FROM person WHERE given_name = 'Mira');
SET @erika        = (SELECT id_person FROM person WHERE given_name = 'Erika');
SET @p_calcium    = (SELECT id_observed_property FROM observed_property WHERE name = 'calcium');
SET @p_magnesium  = (SELECT id_observed_property FROM observed_property WHERE name = 'magnesium');
SET @p_lead       = (SELECT id_observed_property FROM observed_property WHERE name = 'lead');
SET @metals1      = (SELECT id_sample FROM sample WHERE code = '2026-0917-01-M');
SET @hardness1    = (SELECT action.id_action FROM action
                     JOIN method_version ON method_version.id_method_version = action.id_method_version
                     WHERE action.id_sample = @metals1 AND method_version.id_method = @m_hardness);
SET @calcium1     = (SELECT observation.id_observation FROM observation
                     JOIN action ON action.id_action = observation.id_action
                     WHERE action.id_sample = @metals1 AND observation.id_observed_property = @p_calcium);


/* What the issued demo report contains */

CALL assert_equal((SELECT COUNT(*) FROM reported_result WHERE id_report = @report), 14,
                  'fourteen results were reported; raw readings and dilution factors were not');
CALL assert_equal((SELECT reported_text FROM reported_result WHERE id_observation = @calcium1), '48.2',
                  'calcium as printed');


/* An issued report does not change */

CALL assert_fails("UPDATE report SET report_number = 'R-X' WHERE id_report = @report", 'cannot be changed',
                  'issued reports are not edited');
CALL assert_fails("UPDATE report SET id_link = NULL WHERE id_report = @report", 'cannot be changed',
                  'the document link, once set, stays');
CALL assert_fails("DELETE FROM report WHERE id_report = @report", 'never deleted', 'issued reports are not deleted');
CALL assert_fails("UPDATE reported_result SET reported_text = '48' WHERE id_observation = @calcium1",
                  'issued report cannot be changed', 'what was reported stays as it was printed');
CALL assert_fails("DELETE FROM reported_result WHERE id_observation = @calcium1",
                  'issued report cannot be changed', 'nothing is removed from an issued report');
CALL assert_fails(CONCAT("INSERT INTO report (id_lab_order, report_number, issued_at, id_issuer) VALUES (",
                         @order, ", 'R-Y', CURRENT_TIMESTAMP, ", @erika, ")"),
                  'drafts', 'reports are issued through issue_report()');


/* A correction after the report went out */

CALL invalidate_observation(@calcium1, 'Calibration standard was found to be expired.');

CALL assert_equal((SELECT GROUP_CONCAT(reason ORDER BY reason SEPARATOR ' | ')
                   FROM v_report_needing_amendment WHERE id_report = @report),
                  'A reported result has been invalidated. | A reported result is stale.',
                  'the report is flagged: calcium is invalid and the hardness built on it is stale');

INSERT INTO report (id_lab_order, report_number, id_replaced_report) VALUES (@order, 'R-2026-0917-2', @report);
SET @amendment = LAST_INSERT_ID();
CALL assert_fails("CALL issue_report(@amendment, @erika)", 'stale', 'stale results are not reported');

/* Without calcium, the hardness has no inputs left and is withdrawn. */
CALL calculate_action(@hardness1);
CALL assert_equal((SELECT invalidation_reason FROM observation WHERE id_action = @hardness1 ORDER BY id_observation DESC LIMIT 1),
                  'Its inputs are no longer available.', 'a result without inputs is withdrawn');

/* The metals are measured again with a fresh standard. */
CALL plan_action(@metals1, @m_icp, @order, @mira, NULL, @icp_again);
CALL start_action(@icp_again, @mira, NULL);
INSERT INTO observation (id_action, id_observed_property, result_numeric) VALUES
    (@icp_again, @p_calcium, 48.4),
    (@icp_again, @p_magnesium, 9.75),
    (@icp_again, @p_lead, 0.0031);
CALL finish_action(@icp_again, NULL);
CALL calculate_action(@hardness1);

CALL assert_fails("CALL issue_report(@amendment, @erika)", 'not been reviewed', 'unreviewed results are not reported');

CALL review_action(@icp_again, @erika);
CALL review_action(@hardness1, @erika);
CALL issue_report(@amendment, @erika);

/* 0.1399 * 48.4 + 0.2307 * mean(9.75, 9.75) = 9.020485 */
CALL assert_equal((SELECT reported_result.reported_text FROM reported_result
                   JOIN observation ON observation.id_observation = reported_result.id_observation
                   WHERE reported_result.id_report = @amendment AND observation.id_action = @hardness1),
                  '9.0', 'the amended hardness');
CALL assert_equal((SELECT COUNT(*) FROM v_report_needing_amendment), 0,
                  'the amendment replaces the flagged report');
CALL assert_equal((SELECT reported_text FROM reported_result WHERE id_report = @report AND id_observation = @calcium1),
                  '48.2', 'the old report still says what it said');


/* Replacing only works for issued reports of the same order */

INSERT INTO lab_order (order_number, id_customer_organization, received_on)
SELECT '2026-0999', id_organization, '2026-09-20' FROM organization WHERE short_name = 'SWM';
CALL assert_fails(CONCAT("INSERT INTO report (id_lab_order, report_number, id_replaced_report) VALUES (",
                         LAST_INSERT_ID(), ", 'R-Z', ", @amendment, ")"),
                  'same order', 'a report of another order cannot be replaced');
CALL assert_fails(CONCAT("CALL issue_report(", @amendment, ", NULL)"),
                  'Who issues the report', 'issuing needs an issuer');
