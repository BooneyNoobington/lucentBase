/* Methods: the documented ways of taking, preparing and examining samples.

   OMS calls a method a Procedure ("a specified way to carry out an activity").
   The table is called method because PROCEDURE is a reserved word in MariaDB,
   and because "method" is what ISO/IEC 17025 and lab staff call it.

   A method changes over time, so what it does is described per version.
   Which methods depend on each other is described per method, because that
   rarely changes when a method is revised. */


/* A method. kind tells which OMS act it describes:

   - sampling      creates samples (OMS: SamplingProcedure)
   - preparation   treats a sample, e.g. filtration (OMS: PreparationProcedure)
   - observation   determines property values (OMS: ObservingProcedure);
                   this includes calculations
   - handling      everything else that happens to a sample: receipt,
                   storage, disposal. OMS has no counterpart for these.

   A final method, such as disposal, closes a sample: it may only start when
   nothing else is open on the sample, and nothing can be planned after it. */

CREATE TABLE method
(
    id_method       INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    name            VARCHAR(150)    NOT NULL UNIQUE,
    kind            VARCHAR(12)     NOT NULL,
    description     VARCHAR(500),
    is_final        BOOLEAN         NOT NULL DEFAULT FALSE,
    retired_at      TIMESTAMP       NULL,

    CONSTRAINT method_kind_choices CHECK(
        kind IN ('sampling', 'preparation', 'observation', 'handling')
    ),
    CONSTRAINT only_handling_methods_are_final CHECK(
        is_final = FALSE OR kind = 'handling'
    )
);


/* A version of a method, valid from a point in time until the next version
   of the same method becomes valid. Actions record the version they used. */

CREATE TABLE method_version
(
    id_method_version   INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    id_method           INTEGER         NOT NULL,
    valid_from          TIMESTAMP       NOT NULL,
    change_note         VARCHAR(500),

    CONSTRAINT method_version_unique UNIQUE(id_method, valid_from),

    FOREIGN KEY (id_method) REFERENCES method (id_method)
);


/* Documents describing a method version, typically the SOP. */

CREATE TABLE method_version_link
(
    id_method_version_link  INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    id_method_version       INTEGER         NOT NULL,
    id_link                 INTEGER         NOT NULL,

    CONSTRAINT method_version_link_unique UNIQUE(id_method_version, id_link),

    FOREIGN KEY (id_method_version)     REFERENCES method_version (id_method_version),
    FOREIGN KEY (id_link)               REFERENCES link (id_link)
);


/* A property a method version determines, and how well it does so.

   - id_unit         unit the results are reported in
   - decimal_places  how many decimals a reported result gets
   - lod, loq        limit of detection and limit of quantification, in id_unit;
                     results below the LOQ are reported as "< LOQ"
   - uncertainty     measurement uncertainty, absolute (in id_unit) or relative
                     (as a fraction: 0.1 means 10 %)
   - is_required     the method's actions cannot finish without this result
   - is_reported     the result goes into reports (raw readings and dilution
                     factors usually do not)
   - formula         set for calculated properties; see formula_input

   Units, limits, uncertainty and formulas only make sense for numeric
   properties; triggers below make sure of that. */

CREATE TABLE method_property
(
    id_method_property      INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    id_method_version       INTEGER         NOT NULL,
    id_observed_property    INTEGER         NOT NULL,
    id_unit                 INTEGER,
    decimal_places          TINYINT,
    lod                     DECIMAL(38,12),
    loq                     DECIMAL(38,12),
    uncertainty             DECIMAL(38,12),
    uncertainty_kind        VARCHAR(8),
    is_required             BOOLEAN         NOT NULL DEFAULT TRUE,
    is_reported             BOOLEAN         NOT NULL DEFAULT TRUE,
    formula                 VARCHAR(1000),

    CONSTRAINT method_property_unique UNIQUE(id_method_version, id_observed_property),
    CONSTRAINT decimal_places_range CHECK(
        decimal_places BETWEEN 0 AND 12
    ),
    CONSTRAINT lod_not_above_loq CHECK(
        lod <= loq
    ),
    CONSTRAINT uncertainty_has_kind CHECK(
        (uncertainty IS NULL AND uncertainty_kind IS NULL)
        OR
        (uncertainty IS NOT NULL AND uncertainty_kind IN ('absolute', 'relative'))
    ),

    FOREIGN KEY (id_method_version)     REFERENCES method_version (id_method_version),
    FOREIGN KEY (id_observed_property)  REFERENCES observed_property (id_observed_property),
    FOREIGN KEY (id_unit)               REFERENCES unit (id_unit)
);


/* An input of a formula.

   The formula of a method_property is a MariaDB expression, for example
   "reading * dilution". Every name used in it is declared here:

   - variable_name         the name used in the formula
   - id_observed_property  the property whose observations provide the value
   - id_unit               the unit the formula expects; values are converted
   - scope                 'same action': observations made in the same action,
                           'sample': observations on the same sample or, if it
                           has none, on its nearest ancestor that has some
   - aggregation           how several observations become one value
   - below_loq             what to use for a value below its LOQ */

CREATE TABLE formula_input
(
    id_formula_input        INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    id_method_property      INTEGER         NOT NULL,
    variable_name           VARCHAR(40)     NOT NULL,
    id_observed_property    INTEGER         NOT NULL,
    id_unit                 INTEGER         NOT NULL,
    scope                   VARCHAR(12)     NOT NULL DEFAULT 'same action',
    aggregation             VARCHAR(8)      NOT NULL DEFAULT 'mean',
    below_loq               VARCHAR(12)     NOT NULL DEFAULT 'as measured',

    CONSTRAINT formula_input_variable_unique UNIQUE(id_method_property, variable_name),
    CONSTRAINT formula_input_variable_name_format CHECK(
        variable_name REGEXP BINARY '^[a-z][a-z0-9_]*$'
    ),
    CONSTRAINT formula_input_scope_choices CHECK(
        scope IN ('same action', 'sample')
    ),
    CONSTRAINT formula_input_aggregation_choices CHECK(
        aggregation IN ('mean', 'min', 'max', 'sum', 'latest', 'count')
    ),
    CONSTRAINT formula_input_below_loq_choices CHECK(
        below_loq IN ('as measured', 'zero', 'half loq', 'loq')
    ),

    FOREIGN KEY (id_method_property)    REFERENCES method_property (id_method_property),
    FOREIGN KEY (id_observed_property)  REFERENCES observed_property (id_observed_property),
    FOREIGN KEY (id_unit)               REFERENCES unit (id_unit)
);


/* "An action of this method may only start once an action of the prerequisite
   method has finished on the same sample or on one of its ancestors."

   Example: nitrate by ion chromatography requires filtration. */

CREATE TABLE method_prerequisite
(
    id_method_prerequisite  INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    id_method               INTEGER         NOT NULL,
    id_prerequisite_method  INTEGER         NOT NULL,

    CONSTRAINT method_prerequisite_unique UNIQUE(id_method, id_prerequisite_method),
    CONSTRAINT method_is_not_its_own_prerequisite CHECK(
        id_method <> id_prerequisite_method
    ),

    FOREIGN KEY (id_method)                 REFERENCES method (id_method),
    FOREIGN KEY (id_prerequisite_method)    REFERENCES method (id_method)
);


/* "Planning an action of this method on a sample also plans an action of the
   implied method on that sample, unless one is already planned or done."
   Implications are followed transitively.

   Example: receiving a sample implies that it will be disposed of one day. */

CREATE TABLE method_implication
(
    id_method_implication   INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    id_method               INTEGER         NOT NULL,
    id_implied_method       INTEGER         NOT NULL,

    CONSTRAINT method_implication_unique UNIQUE(id_method, id_implied_method),
    CONSTRAINT method_does_not_imply_itself CHECK(
        id_method <> id_implied_method
    ),

    FOREIGN KEY (id_method)             REFERENCES method (id_method),
    FOREIGN KEY (id_implied_method)     REFERENCES method (id_method)
);


DELIMITER $$


/* The version of a method that is valid now. NULL if the method is retired or
   has no valid version yet. */

CREATE FUNCTION current_method_version(p_id_method INTEGER)
RETURNS INTEGER
READS SQL DATA
BEGIN
    RETURN (
        SELECT      method_version.id_method_version
        FROM        method_version
        JOIN        method  ON method.id_method = method_version.id_method
        WHERE       method_version.id_method = p_id_method
          AND       method_version.valid_from <= CURRENT_TIMESTAMP
          AND       method.retired_at IS NULL
        ORDER BY    method_version.valid_from DESC
        LIMIT       1
    );
END$$


/* Numeric properties need a unit of their own dimension. Units, limits,
   uncertainty, decimal places and formulas are for numeric properties only. */

CREATE PROCEDURE check_method_property(
    p_id_observed_property  INTEGER,
    p_id_unit               INTEGER,
    p_decimal_places        TINYINT,
    p_lod                   DECIMAL(38,12),
    p_loq                   DECIMAL(38,12),
    p_uncertainty           DECIMAL(38,12),
    p_formula               VARCHAR(1000)
)
BEGIN
    DECLARE v_result_type   VARCHAR(10);
    DECLARE v_id_dimension  INTEGER;

    SELECT  result_type, id_dimension
    INTO    v_result_type, v_id_dimension
    FROM    observed_property
    WHERE   id_observed_property = p_id_observed_property;

    IF v_result_type = 'numeric' THEN
        IF p_id_unit IS NULL THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'A numeric property needs a unit.';
        END IF;
        IF (SELECT id_dimension FROM unit WHERE id_unit = p_id_unit) <> v_id_dimension THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'The unit does not fit the dimension of the property.';
        END IF;
    ELSEIF COALESCE(p_id_unit, p_decimal_places, p_lod, p_loq, p_uncertainty, p_formula) IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Units, limits, uncertainty, decimal places and formulas are only for numeric properties.';
    END IF;
END$$


CREATE TRIGGER method_property_before_insert
BEFORE INSERT ON method_property
FOR EACH ROW
BEGIN
    CALL check_method_property(NEW.id_observed_property, NEW.id_unit, NEW.decimal_places,
                               NEW.lod, NEW.loq, NEW.uncertainty, NEW.formula);
END$$


CREATE TRIGGER method_property_before_update
BEFORE UPDATE ON method_property
FOR EACH ROW
BEGIN
    CALL check_method_property(NEW.id_observed_property, NEW.id_unit, NEW.decimal_places,
                               NEW.lod, NEW.loq, NEW.uncertainty, NEW.formula);
END$$


/* Formula inputs belong to calculated properties, and their unit must fit the
   input property. */

CREATE PROCEDURE check_formula_input(
    p_id_method_property    INTEGER,
    p_id_observed_property  INTEGER,
    p_id_unit               INTEGER
)
BEGIN
    IF (SELECT formula FROM method_property WHERE id_method_property = p_id_method_property) IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Formula inputs can only be added to a property with a formula.';
    END IF;

    IF NOT EXISTS (
        SELECT  1
        FROM    observed_property
        JOIN    unit    ON unit.id_dimension = observed_property.id_dimension
        WHERE   observed_property.id_observed_property = p_id_observed_property
          AND   unit.id_unit = p_id_unit
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Formula inputs must be numeric properties, with a unit of their dimension.';
    END IF;
END$$


CREATE TRIGGER formula_input_before_insert
BEFORE INSERT ON formula_input
FOR EACH ROW
BEGIN
    CALL check_formula_input(NEW.id_method_property, NEW.id_observed_property, NEW.id_unit);
END$$


CREATE TRIGGER formula_input_before_update
BEFORE UPDATE ON formula_input
FOR EACH ROW
BEGIN
    CALL check_formula_input(NEW.id_method_property, NEW.id_observed_property, NEW.id_unit);
END$$


/* Prerequisites must not go round in a circle, or no action could ever start. */

CREATE TRIGGER method_prerequisite_before_insert
BEFORE INSERT ON method_prerequisite
FOR EACH ROW
BEGIN
    IF EXISTS (
        WITH RECURSIVE required (id_method) AS
        (
            SELECT  NEW.id_prerequisite_method
            UNION
            SELECT  method_prerequisite.id_prerequisite_method
            FROM    method_prerequisite
            JOIN    required    ON method_prerequisite.id_method = required.id_method
        )
        SELECT  1
        FROM    required
        WHERE   required.id_method = NEW.id_method
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'This prerequisite would make the methods wait for each other forever.';
    END IF;
END$$


CREATE TRIGGER method_prerequisite_before_update
BEFORE UPDATE ON method_prerequisite
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Prerequisites cannot be changed. Remove the wrong one and add the right one.';
END$$

DELIMITER ;
