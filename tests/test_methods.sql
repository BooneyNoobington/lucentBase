/* Methods: what their properties may look like, versions, and dependencies. */

INSERT INTO dimension (name) VALUES ('mass concentration'), ('temperature');
INSERT INTO unit (name, symbol, id_dimension, conversion_factor) VALUES
    ('milligram per litre', 'mg/L', 1, 0.001),
    ('kelvin', 'K', 2, 1);
INSERT INTO observed_property (name, result_type, id_dimension) VALUES
    ('nitrate', 'numeric', 1),
    ('nitrate reading', 'numeric', 1);
INSERT INTO observed_property (name, result_type) VALUES ('colour', 'text');

INSERT INTO method (name, kind) VALUES
    ('sampling', 'sampling'),       -- 1
    ('filtration', 'preparation'),  -- 2
    ('nitrate by IC', 'observation'), -- 3
    ('disposal', 'handling');       -- 4

CALL assert_fails("INSERT INTO method (name, kind, is_final) VALUES ('final measurement', 'observation', TRUE)",
                  'only_handling_methods_are_final', 'only handling methods close a sample');

/* Versions: the latest one that is already valid is the current one. */
INSERT INTO method_version (id_method, valid_from) VALUES
    (3, '2025-01-01'), (3, '2026-01-01'), (3, '2099-01-01'),
    (1, '2026-01-01'), (2, '2026-01-01'), (4, '2026-01-01');
CALL assert_equal(current_method_version(3), 2, 'the current version is the latest valid one, not a future one');

UPDATE method SET retired_at = CURRENT_TIMESTAMP WHERE id_method = 4;
CALL assert_true(current_method_version(4) IS NULL, 'retired methods have no current version');
UPDATE method SET retired_at = NULL WHERE id_method = 4;


/* What a method property may look like */

CALL assert_fails("INSERT INTO method_property (id_method_version, id_observed_property) VALUES (2, 1)",
                  'needs a unit', 'numeric properties need a unit');
CALL assert_fails("INSERT INTO method_property (id_method_version, id_observed_property, id_unit) VALUES (2, 1, 2)",
                  'does not fit the dimension', 'kelvin is no unit for a concentration');
CALL assert_fails("INSERT INTO method_property (id_method_version, id_observed_property, id_unit) VALUES (2, 3, 1)",
                  'only for numeric properties', 'text properties have no unit');
CALL assert_fails("INSERT INTO method_property (id_method_version, id_observed_property, formula) VALUES (2, 3, 'x')",
                  'only for numeric properties', 'text properties have no formula');
CALL assert_fails("INSERT INTO method_property (id_method_version, id_observed_property, id_unit, lod, loq) VALUES (2, 1, 1, 0.5, 0.1)",
                  'lod_not_above_loq', 'the LOD is not above the LOQ');

INSERT INTO method_property (id_method_version, id_observed_property, id_unit) VALUES (2, 2, 1);
INSERT INTO method_property (id_method_version, id_observed_property, id_unit, formula) VALUES (2, 1, 1, 'reading * 2');
INSERT INTO method_property (id_method_version, id_observed_property) VALUES (2, 3);


/* Formula inputs */

CALL assert_fails("INSERT INTO formula_input (id_method_property, variable_name, id_observed_property, id_unit) VALUES (1, 'x', 2, 1)",
                  'only be added to a property with a formula', 'only calculated properties have inputs');
CALL assert_fails("INSERT INTO formula_input (id_method_property, variable_name, id_observed_property, id_unit) VALUES (2, 'reading', 2, 2)",
                  'must be numeric properties, with a unit of their dimension', 'the input unit must fit');
CALL assert_fails("INSERT INTO formula_input (id_method_property, variable_name, id_observed_property, id_unit) VALUES (2, 'Reading', 2, 1)",
                  'formula_input_variable_name_format', 'variable names are lower case');
CALL assert_fails("INSERT INTO formula_input (id_method_property, variable_name, id_observed_property, id_unit) VALUES (2, 'x; DROP', 2, 1)",
                  'formula_input_variable_name_format', 'variable names cannot smuggle in SQL');
INSERT INTO formula_input (id_method_property, variable_name, id_observed_property, id_unit) VALUES (2, 'reading', 2, 1);


/* Prerequisites must not form a circle; implications may not imply themselves. */

INSERT INTO method_prerequisite (id_method, id_prerequisite_method) VALUES (3, 2), (2, 1);
CALL assert_fails("INSERT INTO method_prerequisite (id_method, id_prerequisite_method) VALUES (1, 3)",
                  'wait for each other forever', 'a circle of prerequisites is refused');
CALL assert_fails("INSERT INTO method_prerequisite (id_method, id_prerequisite_method) VALUES (1, 1)",
                  'wait for each other forever', 'a method is not its own prerequisite');
CALL assert_fails("INSERT INTO method_implication (id_method, id_implied_method) VALUES (1, 1)",
                  'method_does_not_imply_itself', 'a method does not imply itself');


/* Once an action has used a version, the version is frozen. */

INSERT INTO sample (code, sample_kind) VALUES ('S1', 'material');
INSERT INTO action (id_sample, id_method_version) VALUES (1, 2);

CALL assert_fails("UPDATE method_property SET decimal_places = 3 WHERE id_method_property = 1",
                  'has been used by actions', 'properties of a used version cannot change');
CALL assert_fails("INSERT INTO method_property (id_method_version, id_observed_property) VALUES (2, 3)",
                  'has been used by actions', 'a used version gets no new properties');
CALL assert_fails("DELETE FROM method_property WHERE id_method_property = 3",
                  'has been used by actions', 'a used version loses no properties');
CALL assert_fails("UPDATE formula_input SET variable_name = 'r' WHERE id_formula_input = 1",
                  'has been used by actions', 'formulas of a used version cannot change');
CALL assert_fails("UPDATE method_version SET valid_from = '2026-02-01' WHERE id_method_version = 2",
                  'has been used by actions', 'a used version keeps its validity');

/* An unused version can still be edited. */
INSERT INTO method_property (id_method_version, id_observed_property, id_unit) VALUES (3, 1, 1);
UPDATE method_property SET decimal_places = 2 WHERE id_method_version = 3;
CALL assert_equal((SELECT decimal_places FROM method_property WHERE id_method_version = 3), 2,
                  'unused versions are editable');
