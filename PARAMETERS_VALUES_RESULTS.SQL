/* "Parameters" and "Values"
   Part of the lucentLIMS project.
   Copyright: GPLv3

   LucentLIMS stores not only measurement results but also other information obtained
   during the lifecycle that led to their quantification—such as the visual impression
   of a sample or confirmation that a sample was filtrated.

   The database entity containing this information is the table "value". Such a value
   is associated with a parameter, which in turn is associated with an action. */


/* Instances of parameter will fill up the activity data. It can be many things
   and is always a property of an action—like a measurement result but also metadata
   such as "was sample X filtrated?" */

CREATE OR REPLACE TABLE parameter
(
    id_parameter    INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    name            VARCHAR(30)     NOT NULL UNIQUE,
    description     VARCHAR(80),
    id_unit         INTEGER,
    vis             BOOLEAN         NOT NULL DEFAULT TRUE,

    FOREIGN KEY (id_unit) REFERENCES unit (id_unit)
);


/* Relate an action and a parameter. */

CREATE OR REPLACE TABLE effect
(
    id_effect               INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    id_action               INTEGER         NOT NULL,
    id_parameter            INTEGER         NOT NULL,
    uncertainty             DOUBLE,
    uncertainty_class       VARCHAR(9),
    uncertainty_id_unit     INTEGER,
    calculation             VARCHAR(40),
    vis                     BOOLEAN         NOT NULL DEFAULT TRUE,

    CONSTRAINT id_action_id_parameter_unique UNIQUE(id_action, id_parameter),

    FOREIGN KEY (id_action)             REFERENCES action (id_action),
    FOREIGN KEY (id_parameter)          REFERENCES parameter (id_parameter),
    FOREIGN KEY (uncertainty_id_unit)   REFERENCES unit (id_unit)
);


/* Relate two effects. E.g., relative humidity makes sense in conjunction
   with air temperature. */

CREATE OR REPLACE TABLE coefficient
(
    id_coefficient  INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    id_effect1      INTEGER,
    id_effect2      INTEGER,
    description     VARCHAR(250),
    vis             BOOLEAN         NOT NULL DEFAULT TRUE,

    FOREIGN KEY (id_effect1) REFERENCES effect (id_effect),
    FOREIGN KEY (id_effect2) REFERENCES effect (id_effect)
);


/* The second heart of lucent: values attributed to specific parameters.
   Most prominently measurement results, but it can be many things—like confirmation
   that a sample has been disposed of.

   Various data types for the value itself are possible: decimal for measurement
   results, booleans for status, text for descriptions, etc.

   Most importantly, values are the link between a collection and actions performed on them. */

CREATE OR REPLACE TABLE value
(
    id_value        INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    name            VARCHAR(30),
    id_collection   INTEGER         NOT NULL,
    id_effect       INTEGER         NOT NULL,
    vis             BOOLEAN         NOT NULL DEFAULT TRUE,

    CONSTRAINT collection_effect_unique UNIQUE(id_collection, id_effect),

    FOREIGN KEY (id_collection) REFERENCES collection (id_collection),
    FOREIGN KEY (id_effect)     REFERENCES effect (id_effect)
);


/* The link between collections and values doesn't hold actual measurement results.
   These are provided by raw values, while the effect table describes how
   end results are computed. */

CREATE OR REPLACE TABLE raw_value
(
    id_raw_value            INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    id_value                INTEGER,
    t                       DATETIME,
    id_person               INTEGER,
    id_device               INTEGER,
    id_unit                 INTEGER,
    decimal_raw_value       DOUBLE,
    text_raw_value          VARCHAR(50),
    boolean_raw_value       BOOLEAN,
    datetime_raw_value      DATETIME,
    accepted                BOOLEAN         DEFAULT FALSE,
    vis                     BOOLEAN         NOT NULL DEFAULT TRUE,

    CONSTRAINT one_entry_for_value_only CHECK(
        (decimal_raw_value IS NULL AND text_raw_value IS NULL AND boolean_raw_value IS NULL AND datetime_raw_value IS NULL)
        OR
        (decimal_raw_value IS NOT NULL AND text_raw_value IS NULL AND boolean_raw_value IS NULL AND datetime_raw_value IS NULL)
        OR
        (decimal_raw_value IS NULL AND text_raw_value IS NOT NULL AND boolean_raw_value IS NULL AND datetime_raw_value IS NULL)
        OR
        (decimal_raw_value IS NULL AND text_raw_value IS NULL AND boolean_raw_value IS NOT NULL AND datetime_raw_value IS NULL)
        OR
        (decimal_raw_value IS NULL AND text_raw_value IS NULL AND boolean_raw_value IS NULL AND datetime_raw_value IS NOT NULL)
    ),
    CONSTRAINT one_value_per_t UNIQUE(id_value, t),

    FOREIGN KEY (id_value)  REFERENCES value (id_value),
    FOREIGN KEY (id_person) REFERENCES person (id_person),
    FOREIGN KEY (id_device) REFERENCES device (id_device),
    FOREIGN KEY (id_unit)   REFERENCES unit (id_unit)
);
