-- uses: seed
/* The demo data tells the story it promises. If this fails, the seed or the
   schema has drifted. */

CALL assert_equal((SELECT COUNT(*) FROM sample), 8, 'two sampling points, two bottles, four aliquots');

CALL assert_equal((SELECT result FROM v_observation WHERE sample_code = '2026-0917-01-A' AND property = 'nitrate' AND is_valid),
                  '24.6', 'nitrate in bottle 01: 12.30 mg/L * dilution 2');
CALL assert_equal((SELECT result FROM v_observation WHERE sample_code = '2026-0917-02-A' AND property = 'nitrate'),
                  '< 0.5', 'nitrate in bottle 02 is below the LOQ');
CALL assert_equal((SELECT result FROM v_observation WHERE sample_code = '2026-0917-01-M' AND property = 'total hardness'),
                  '9.0', 'total hardness of bottle 01 in °dH');
CALL assert_equal((SELECT result FROM v_observation WHERE sample_code = '2026-0917-02-M' AND property = 'total hardness'),
                  '9.5', 'total hardness of bottle 02 in °dH');
CALL assert_equal((SELECT result FROM v_observation WHERE sample_code = '2026-0917-01-M' AND property = 'lead'),
                  '< 0.005', 'lead in bottle 01 is below the LOQ');

CALL assert_equal((SELECT invalidation_reason FROM v_observation WHERE raw_value = 123),
                  'Typing error; the instrument shows 12.30.', 'the typo is invalidated with its reason');

CALL assert_equal((SELECT phenomenon_time FROM v_observation WHERE sample_code = '2026-0917-01-A' AND property = 'nitrate' AND is_valid),
                  '2026-09-15 09:10:00', 'the aliquot reports the sampling time of its bottle');

CALL assert_equal((SELECT GROUP_CONCAT(CONCAT(sample_code, ': ', method) ORDER BY sample_code SEPARATOR '; ') FROM v_worklist),
                  '2026-0917-01: disposal; 2026-0917-02: disposal', 'only the disposals are still to do');

CALL assert_equal((SELECT COUNT(*) FROM v_stale_calculation), 0, 'nothing is stale');
CALL assert_equal((SELECT COUNT(*) FROM v_report_needing_amendment), 0, 'the report is in force');
CALL assert_equal((SELECT COUNT(*) FROM v_missing_implied_action), 0, 'every implication is planned');
CALL assert_equal((SELECT COUNT(*) FROM observation WHERE reviewed_at IS NULL AND invalidated_at IS NULL), 0,
                  'every valid result is reviewed');
