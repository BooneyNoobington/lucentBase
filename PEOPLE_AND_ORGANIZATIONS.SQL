/* An organization can be a group, a company, or any other collection of individuals.
   Mostly for categorization. */

CREATE OR REPLACE TABLE organization
(
    id_organization     INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    name                VARCHAR(50)     UNIQUE,
    shorthand           VARCHAR(15),
    relation            VARCHAR(25),
    vis                 BOOLEAN         NOT NULL DEFAULT TRUE
);


/* Information about a particular person such as an employee or contractor. */

CREATE OR REPLACE TABLE person
(
    id_person           INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    id_organization     INTEGER,
    given_name          VARCHAR(50)     NOT NULL,
    surname             VARCHAR(50)     NOT NULL,
    linux_user          VARCHAR(50)     UNIQUE,
    vis                 BOOLEAN         NOT NULL DEFAULT TRUE,

    FOREIGN KEY (id_organization) REFERENCES organization (id_organization)
);


/* Connect people to addresses (a specific house). */

CREATE OR REPLACE TABLE j_person_house
(
    id_j_person_house   INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    id_person           INTEGER,
    id_house            INTEGER,
    address_class       VARCHAR(20),
    vis                 BOOLEAN         NOT NULL DEFAULT TRUE,

    FOREIGN KEY (id_person) REFERENCES person (id_person),
    FOREIGN KEY (id_house)  REFERENCES house (id_house)
);


/* Connect organizations to addresses. */

CREATE OR REPLACE TABLE j_organization_house
(
    id_j_organization_house     INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    id_organization             INTEGER,
    id_house                    INTEGER,
    address_class               VARCHAR(20),
    vis                         BOOLEAN         NOT NULL DEFAULT TRUE,

    FOREIGN KEY (id_organization)   REFERENCES organization (id_organization),
    FOREIGN KEY (id_house)          REFERENCES house (id_house)
);


/* Connect people to organizations. */

CREATE OR REPLACE TABLE j_person_organization
(
    id_j_person_organization    INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    id_person                   INTEGER,
    id_organization             INTEGER,
    position                    VARCHAR(20),
    vis                         BOOLEAN         NOT NULL DEFAULT TRUE,

    FOREIGN KEY (id_person)         REFERENCES person (id_person),
    FOREIGN KEY (id_organization)   REFERENCES organization (id_organization)
);
