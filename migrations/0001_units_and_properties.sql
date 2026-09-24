/* Units, observed properties and sample matrices.

   These are the reference data every observation depends on. In ISO 19156
   (OMS) terms, observed_property is the ObservableProperty and matrix is a
   community-specific sample type (see docs/oms-alignment.md). */


/* A physical dimension such as mass concentration, temperature or length.
   Units of the same dimension can be converted into each other. */

CREATE TABLE dimension
(
    id_dimension    INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    name            VARCHAR(60)     NOT NULL UNIQUE,
    description     VARCHAR(250)
);


/* A unit of measurement.

   Conversion: every unit knows how to express a value in the coherent SI unit
   of its dimension:

       value_in_si_unit = value * conversion_factor + conversion_offset

   So 1 mg/L (0.001 kg/m³) has the factor 0.001, and °C has the factor 1 and
   the offset 273.15 (to kelvin). Units without a factor, like pH, cannot be
   converted. ucum_code is the code of the Unified Code for Units of Measure,
   the notation most other systems understand. Symbols and codes are case
   sensitive: "Mm" is a megametre, "mm" a millimetre. */

CREATE TABLE unit
(
    id_unit             INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    name                VARCHAR(60)     NOT NULL UNIQUE,
    symbol              VARCHAR(20)     NOT NULL COLLATE utf8mb4_bin,
    ucum_code           VARCHAR(40)     UNIQUE COLLATE utf8mb4_bin,
    id_dimension        INTEGER         NOT NULL,
    conversion_factor   DECIMAL(40,20),
    conversion_offset   DECIMAL(40,20)  NOT NULL DEFAULT 0,

    CONSTRAINT unit_offset_needs_factor CHECK(
        conversion_factor IS NOT NULL OR conversion_offset = 0
    ),
    CONSTRAINT unit_factor_is_positive CHECK(
        conversion_factor > 0
    ),

    FOREIGN KEY (id_dimension) REFERENCES dimension (id_dimension)
);


/* Instruments and people write the same unit in different ways ("mg/l",
   "mg/L", "mg l-1"). Every known way of writing a unit is listed here, so
   imported values can be matched to their unit. */

CREATE TABLE unit_notation
(
    id_unit_notation    INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    id_unit             INTEGER         NOT NULL,
    notation            VARCHAR(40)     NOT NULL UNIQUE COLLATE utf8mb4_bin,

    FOREIGN KEY (id_unit) REFERENCES unit (id_unit)
);


/* A property that can be observed, such as "nitrate concentration", "water
   temperature" or "colour". Chemists call it the analyte or determinand; OMS
   calls it ObservableProperty.

   result_type says what kind of result an observation of this property has.
   Numeric properties need a dimension, so their units can be checked.
   definition_uri can point to a term in a public vocabulary. */

CREATE TABLE observed_property
(
    id_observed_property    INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    name                    VARCHAR(100)    NOT NULL UNIQUE,
    description             VARCHAR(250),
    result_type             VARCHAR(10)     NOT NULL,
    id_dimension            INTEGER,
    definition_uri          VARCHAR(500),

    CONSTRAINT observed_property_result_type_choices CHECK(
        result_type IN ('numeric', 'text', 'boolean', 'timestamp')
    ),
    CONSTRAINT numeric_property_has_dimension CHECK(
        (result_type = 'numeric' AND id_dimension IS NOT NULL)
        OR
        (result_type <> 'numeric' AND id_dimension IS NULL)
    ),

    FOREIGN KEY (id_dimension) REFERENCES dimension (id_dimension)
);


/* The material a sample consists of, such as surface water, groundwater, soil
   or ambient air. */

CREATE TABLE matrix
(
    id_matrix       INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    name            VARCHAR(60)     NOT NULL UNIQUE,
    description     VARCHAR(250)
);


DELIMITER $$


/* Converts a value from one unit into another unit of the same dimension.
   Returns NULL if the units cannot be converted into each other. */

CREATE FUNCTION convert_unit(p_value DECIMAL(38,12), p_from_unit INTEGER, p_to_unit INTEGER)
RETURNS DECIMAL(38,12)
READS SQL DATA
BEGIN
    DECLARE v_result DECIMAL(38,12);

    IF p_from_unit = p_to_unit THEN
        RETURN p_value;
    END IF;

    SELECT ((p_value * from_unit.conversion_factor + from_unit.conversion_offset)
            - to_unit.conversion_offset) / to_unit.conversion_factor
    INTO   v_result
    FROM   unit AS from_unit
    JOIN   unit AS to_unit  ON to_unit.id_dimension = from_unit.id_dimension
    WHERE  from_unit.id_unit = p_from_unit
      AND  to_unit.id_unit = p_to_unit;

    RETURN v_result;
END$$

DELIMITER ;
