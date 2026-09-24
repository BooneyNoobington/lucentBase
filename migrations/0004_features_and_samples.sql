/* Features and samples: what the lab investigates, and what it actually
   takes into its hands to do so.

   This follows ISO 19156 (OMS) closely:

   - A feature is the real-world thing that is ultimately of interest: a lake,
     a field, a well, a building. OMS calls it the ultimate feature-of-interest.
   - A sample is representative of a feature. A spatial sample is a place
     (a sampling point, a transect, a plot); a material sample is a physical
     thing (a bottle of water, a bag of soil). All observations are made on
     samples; see docs/oms-alignment.md for why. */


/* The real-world thing an investigation is about. Where it is can be given as
   a geometry (with its EPSG code as SRID), as a postal address, or both. */

CREATE TABLE feature
(
    id_feature      INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    name            VARCHAR(150)    NOT NULL,
    description     VARCHAR(500),
    shape           GEOMETRY        NULL,
    id_address      INTEGER,

    CONSTRAINT feature_shape_has_srid CHECK(
        shape IS NULL OR ST_SRID(shape) > 0
    ),

    FOREIGN KEY (id_address) REFERENCES address (id_address)
);


/* A sample (OMS: Sample).

   code is the sample number the lab writes on the label.

   sample_kind is 'spatial' for places and 'material' for physical things.

   id_sampled_feature is the feature the sample represents. It is left empty
   for samples obtained from other samples (see sample_source), which inherit
   it. It may also be empty when the sampled feature is unknown, which OMS
   explicitly allows.

   location is the shape of a spatial sample, or where a material sample was
   taken if that is not already given by a source sample. location_description
   is for places without coordinates: "left of the porch".

   size (with its unit), matrix and storage location only apply to material
   samples. Where a sample currently is lives in id_storage_location. */

CREATE TABLE sample
(
    id_sample               INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    code                    VARCHAR(40)     NOT NULL UNIQUE,
    sample_kind             VARCHAR(10)     NOT NULL,
    id_sampled_feature      INTEGER,
    id_matrix               INTEGER,
    location                GEOMETRY        NULL,
    location_description    VARCHAR(250),
    size                    DECIMAL(20,6),
    id_size_unit            INTEGER,
    id_storage_location     INTEGER,
    description             VARCHAR(500),

    CONSTRAINT sample_kind_choices CHECK(
        sample_kind IN ('spatial', 'material')
    ),
    CONSTRAINT sample_location_has_srid CHECK(
        location IS NULL OR ST_SRID(location) > 0
    ),
    CONSTRAINT sample_size_has_unit CHECK(
        (size IS NULL AND id_size_unit IS NULL)
        OR
        (size IS NOT NULL AND id_size_unit IS NOT NULL)
    ),
    CONSTRAINT only_material_samples_have_size_and_storage CHECK(
        sample_kind = 'material'
        OR
        (size IS NULL AND id_storage_location IS NULL)
    ),

    FOREIGN KEY (id_sampled_feature)    REFERENCES feature (id_feature),
    FOREIGN KEY (id_matrix)             REFERENCES matrix (id_matrix),
    FOREIGN KEY (id_size_unit)          REFERENCES unit (id_unit),
    FOREIGN KEY (id_storage_location)   REFERENCES storage_location (id_storage_location)
);


/* Where a sample was obtained from (OMS: relatedSample).

   - A bottle filled at a sampling point has the sampling point as source.
   - An aliquot poured off a bottle has the bottle as source.
   - A composite mixed from five spot samples has all five as sources.

   Sources can have sources themselves. Together they form the lineage of a
   sample, which v_sample_lineage lists. */

CREATE TABLE sample_source
(
    id_sample_source    INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    id_sample           INTEGER         NOT NULL,
    id_source_sample    INTEGER         NOT NULL,

    CONSTRAINT sample_source_unique UNIQUE(id_sample, id_source_sample),
    CONSTRAINT sample_is_not_its_own_source CHECK(
        id_sample <> id_source_sample
    ),

    FOREIGN KEY (id_sample)         REFERENCES sample (id_sample),
    FOREIGN KEY (id_source_sample)  REFERENCES sample (id_sample)
);


/* Every sample together with all its ancestors: its sources, their sources,
   and so on. generations is 0 for the sample itself, 1 for its direct
   sources, 2 for their sources. */

CREATE VIEW v_sample_lineage AS
WITH RECURSIVE lineage (id_sample, id_ancestor_sample, generations) AS
(
    SELECT      id_sample, id_sample, 0
    FROM        sample

    UNION ALL

    SELECT      lineage.id_sample, sample_source.id_source_sample, lineage.generations + 1
    FROM        lineage
    JOIN        sample_source   ON sample_source.id_sample = lineage.id_ancestor_sample
)
SELECT      id_sample, id_ancestor_sample, generations
FROM        lineage;


DELIMITER $$


/* A sample must not end up among its own ancestors, and a place (spatial
   sample) cannot be obtained from a physical thing (material sample). */

CREATE TRIGGER sample_source_before_insert
BEFORE INSERT ON sample_source
FOR EACH ROW
BEGIN
    DECLARE v_message VARCHAR(500);

    IF NEW.id_sample = NEW.id_source_sample THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A sample cannot be its own source.';
    END IF;

    IF EXISTS (
        WITH RECURSIVE ancestor (id_sample) AS
        (
            SELECT  NEW.id_source_sample
            UNION
            SELECT  sample_source.id_source_sample
            FROM    sample_source
            JOIN    ancestor    ON sample_source.id_sample = ancestor.id_sample
        )
        SELECT  1
        FROM    ancestor
        WHERE   ancestor.id_sample = NEW.id_sample
    ) THEN
        SET v_message = CONCAT('Sample ', NEW.id_sample, ' cannot be obtained from sample ',
                               NEW.id_source_sample, ', because that one was obtained from it.');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_message;
    END IF;

    IF (SELECT sample_kind FROM sample WHERE id_sample = NEW.id_sample) = 'spatial'
       AND (SELECT sample_kind FROM sample WHERE id_sample = NEW.id_source_sample) = 'material'
    THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A spatial sample cannot be obtained from a material sample.';
    END IF;
END$$


/* Where a sample came from is history; it is not edited afterwards. */

CREATE TRIGGER sample_source_before_update
BEFORE UPDATE ON sample_source
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Sample sources cannot be changed. Remove the wrong one and add the right one.';
END$$


/* The feature a sample represents: its own, or else the one of its nearest
   ancestor that has one. NULL if nobody in the lineage knows it. */

CREATE FUNCTION sampled_feature_of(p_id_sample INTEGER)
RETURNS INTEGER
READS SQL DATA
BEGIN
    RETURN (
        WITH RECURSIVE lineage (id_sample, generations) AS
        (
            SELECT  p_id_sample, 0
            UNION ALL
            SELECT  sample_source.id_source_sample, lineage.generations + 1
            FROM    lineage
            JOIN    sample_source   ON sample_source.id_sample = lineage.id_sample
        )
        SELECT      sample.id_sampled_feature
        FROM        lineage
        JOIN        sample  ON sample.id_sample = lineage.id_sample
        WHERE       sample.id_sampled_feature IS NOT NULL
        ORDER BY    lineage.generations, sample.id_sample
        LIMIT       1
    );
END$$

DELIMITER ;
