/* Units of measurement are based on dimensions, such as mass, length, or time. */

CREATE OR REPLACE TABLE dimension
(
    id_dimension    INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    name            VARCHAR(40)     NOT NULL UNIQUE,
    description     VARCHAR(50),
    vis             BOOLEAN         NOT NULL DEFAULT TRUE
);


/* A measured effect consists of its value, a unit, and an uncertainty. */

CREATE OR REPLACE TABLE unit
(
    id_unit         INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    name            VARCHAR(40)     NOT NULL UNIQUE,
    description     VARCHAR(100),
    id_dimension    INTEGER,
    vis             BOOLEAN         NOT NULL DEFAULT TRUE,

    FOREIGN KEY (id_dimension) REFERENCES dimension (id_dimension)
);


/* Some write "milligram per liter" as "mg/l", others as "mg/L", others with whitespaces.
   This table contains all possible notations. */

CREATE OR REPLACE TABLE unit_notation
(
    id_unit_notation    INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    id_unit             INTEGER         NOT NULL,
    notation            VARCHAR(40)     UNIQUE,
    vis                 BOOLEAN         NOT NULL DEFAULT TRUE,

    FOREIGN KEY (id_unit) REFERENCES unit (id_unit)
);
