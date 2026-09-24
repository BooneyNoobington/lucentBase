/* Samples, their sources and lineage. */

INSERT INTO feature (name, shape) VALUES
    ('Lake', ST_GeomFromText('POINT(10.0 51.0)', 4326)),
    ('Field', NULL);

CALL assert_fails("INSERT INTO feature (name, shape) VALUES ('x', ST_GeomFromText('POINT(1 1)'))",
                  'feature_shape_has_srid', 'a shape needs a coordinate reference system');

INSERT INTO sample (code, sample_kind, id_sampled_feature) VALUES
    ('P1', 'spatial', 1),       -- 1 sampling point on the lake
    ('B1', 'material', NULL),   -- 2 bottle filled at P1
    ('A1', 'material', NULL),   -- 3 aliquot of B1
    ('S1', 'material', 2),      -- 4 soil core from the field
    ('S2', 'material', 2),      -- 5 another soil core
    ('C1', 'material', NULL);   -- 6 composite of S1 and S2

INSERT INTO sample_source (id_sample, id_source_sample) VALUES
    (2, 1), (3, 2), (6, 4), (6, 5);

CALL assert_equal((SELECT GROUP_CONCAT(id_ancestor_sample ORDER BY generations) FROM v_sample_lineage WHERE id_sample = 3),
                  '3,2,1', 'lineage of the aliquot: itself, the bottle, the sampling point');
CALL assert_equal((SELECT COUNT(*) FROM v_sample_lineage WHERE id_sample = 6 AND generations = 1), 2,
                  'a composite has all its parts as sources');

CALL assert_equal(sampled_feature_of(3), 1, 'the aliquot inherits the lake from the sampling point');
CALL assert_equal(sampled_feature_of(6), 2, 'the composite inherits the field');
INSERT INTO sample (code, sample_kind) VALUES ('X1', 'material');
CALL assert_true(sampled_feature_of(7) IS NULL, 'an unknown sampled feature stays unknown');

CALL assert_fails("INSERT INTO sample_source (id_sample, id_source_sample) VALUES (1, 3)",
                  'cannot be obtained from sample', 'a sample cannot descend from its own descendant');
CALL assert_fails("INSERT INTO sample_source (id_sample, id_source_sample) VALUES (2, 2)",
                  'cannot be its own source', 'a sample is not its own source');

INSERT INTO sample (code, sample_kind) VALUES ('P9', 'spatial');
CALL assert_fails("INSERT INTO sample_source (id_sample, id_source_sample) VALUES (8, 2)",
                  'spatial sample cannot be obtained from a material sample', 'places do not come out of bottles');

CALL assert_fails("UPDATE sample_source SET id_source_sample = 5 WHERE id_sample = 3",
                  'cannot be changed', 'sources are history');

CALL assert_fails("INSERT INTO sample (code, sample_kind, size) VALUES ('Z', 'spatial', 3)",
                  'CONSTRAINT', 'places have no size');
CALL assert_fails("INSERT INTO sample (code, sample_kind) VALUES ('P1', 'spatial')",
                  'Duplicate entry', 'sample codes are unique');
