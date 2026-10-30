/* Self-explanatory. */

CREATE OR REPLACE TABLE city
(
    id_city     INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    name        VARCHAR(60)     NOT NULL UNIQUE,
    vis         BOOLEAN         NOT NULL DEFAULT TRUE
);


/* Many cities consist of various districts. */

CREATE OR REPLACE TABLE district
(
    id_district     INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    name            VARCHAR(60)     NOT NULL,
    id_city         INTEGER         NOT NULL,
    zip             VARCHAR(10)     NOT NULL,
    vis             BOOLEAN         NOT NULL DEFAULT TRUE,

    CONSTRAINT one_district_per_city UNIQUE(name, id_city),

    FOREIGN KEY (id_city) REFERENCES city (id_city)
);


/* Self-explanatory. */

CREATE OR REPLACE TABLE street
(
    id_street       INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    name            VARCHAR(100)    NOT NULL,
    id_district     INTEGER         NOT NULL,
    vis             BOOLEAN         NOT NULL DEFAULT TRUE,

    CONSTRAINT one_street_per_district UNIQUE(name, id_district),

    FOREIGN KEY (id_district) REFERENCES district (id_district)
);


/* A house (identified by its number) is situated in a specific street,
   which in turn is connected to a specific district and so on. */

CREATE OR REPLACE TABLE house
(
    id_house            INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    name                VARCHAR(50),
    number              INTEGER         NOT NULL,
    number_addition     VARCHAR(5),
    id_street           INTEGER         NOT NULL,
    vis                 BOOLEAN         NOT NULL DEFAULT TRUE,

    CONSTRAINT house_number_addition_street UNIQUE(number, number_addition, id_street),

    FOREIGN KEY (id_street) REFERENCES street (id_street)
);


/* Some information is geographical and has coordinates,
   so a coordinate reference system is needed. */

CREATE OR REPLACE TABLE crs
(
    id_crs          INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    epsg            INTEGER         NOT NULL,
    name            VARCHAR(25)     NOT NULL UNIQUE,
    description     VARCHAR(150),
    vis             BOOLEAN         NOT NULL DEFAULT TRUE
);


/* This is the general place an investigation takes place.
   It could be anything from a part of a beach to a crime scene. */

CREATE OR REPLACE TABLE site
(
    id_site         INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    name            VARCHAR(20)     NOT NULL UNIQUE,
    id_house        INTEGER,
    borders         POLYGON,
    id_crs          INTEGER,
    description     VARCHAR(50),
    vis             BOOLEAN         NOT NULL DEFAULT TRUE,

    CONSTRAINT site_needs_location CHECK(
        id_house IS NOT NULL OR borders IS NOT NULL OR description IS NOT NULL
    ),

    FOREIGN KEY (id_house) REFERENCES house (id_house),
    FOREIGN KEY (id_crs)   REFERENCES crs (id_crs)
);


/* The exact place where an investigation takes place is called a spot.
   A site can have multiple spots. */

CREATE OR REPLACE TABLE spot
(
    id_spot     INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    name        VARCHAR(50)     NOT NULL UNIQUE,
    x           DOUBLE,
    y           DOUBLE,
    z           DOUBLE,
    z_class     VARCHAR(20),
    z_id_unit   INTEGER,
    id_crs      INTEGER,
    description VARCHAR(50),
    id_site     INTEGER,
    vis         BOOLEAN         NOT NULL DEFAULT TRUE,

    CONSTRAINT spot_needs_location CHECK(
        description IS NOT NULL OR (x IS NOT NULL AND y IS NOT NULL)
    ),

    FOREIGN KEY (z_id_unit) REFERENCES unit (id_unit),
    FOREIGN KEY (id_crs)    REFERENCES crs (id_crs),
    FOREIGN KEY (id_site)   REFERENCES site (id_site)
);
