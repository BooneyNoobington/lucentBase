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


/* Information about a particular person such as an employee or contractor.
   linux_user is the account a person signs in with. Someone who has left is no longer
   active: they can't sign in, but stay in the history. vis = FALSE would hide them as if
   they had never been entered. */

CREATE OR REPLACE TABLE person
(
    id_person           INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    id_organization     INTEGER,
    given_name          VARCHAR(50)     NOT NULL,
    surname             VARCHAR(50)     NOT NULL,
    linux_user          VARCHAR(50)     UNIQUE,
    active              BOOLEAN         NOT NULL DEFAULT TRUE,
    vis                 BOOLEAN         NOT NULL DEFAULT TRUE,

    FOREIGN KEY (id_organization) REFERENCES organization (id_organization)
);


/* What people may do, such as registering collections or accepting raw values. Front ends
   and APIs check roles; signing in (passwords, two factors) stays with whatever checks
   linux_user. Not to be confused with the role of a person in an action (j_action_person),
   which says who is responsible, not who is allowed. */

CREATE OR REPLACE TABLE role
(
    id_role             INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    name                VARCHAR(20)     NOT NULL UNIQUE,
    description         VARCHAR(250),
    vis                 BOOLEAN         NOT NULL DEFAULT TRUE
);


/* Grant roles to people. Revoking a role sets vis to FALSE and granting it again back to
   TRUE, so l_j_person_role shows who granted and revoked what, and when. */

CREATE OR REPLACE TABLE j_person_role
(
    id_j_person_role    INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    id_person           INTEGER         NOT NULL,
    id_role             INTEGER         NOT NULL,
    vis                 BOOLEAN         NOT NULL DEFAULT TRUE,

    CONSTRAINT id_person_id_role_unique UNIQUE(id_person, id_role),

    FOREIGN KEY (id_person) REFERENCES person (id_person),
    FOREIGN KEY (id_role)   REFERENCES role (id_role)
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
