/* An organization can be a group, a company or any other collection
of individuals. Mostly for categorization.*/
CREATE OR REPLACE TABLE organization
(
    id_organization INTEGER PRIMARY KEY NOT NULL AUTO_INCREMENT,
    name VARCHAR(50) UNIQUE,
    shorthand VARCHAR(15),
    relation VARCHAR(25),  -- E.g. partner, client, …
	-- Recycle bin
    vis BOOLEAN NOT NULL DEFAULT TRUE
);



/* Information about a particular person like an employee or contractor, etc.. */
CREATE OR REPLACE TABLE person
(
    id_person INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT,
    id_organization INTEGER REFERENCES organization (id_organization),
    given_name VARCHAR(50) NOT NULL,
    surname VARCHAR(50) NOT NULL,
    linux_user VARCHAR(50) UNIQUE,
    -- Recycle bin
    vis BOOLEAN NOT NULL DEFAULT TRUE
);



/* Connect people and organizations to addresses (a specific house). */
CREATE OR REPLACE TABLE j_person_house
(
    id_j_person_house INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT,
    id_person INTEGER REFERENCES person (id_person),
    id_house INTEGER REFERENCES house (id_house),
    address_class VARCHAR(20),  -- Different addresses are possible. Home, work, etc.
	-- Recycle bin
    vis BOOLEAN NOT NULL DEFAULT TRUE
);



/* Connect organizations and organizations to addresses. */
CREATE OR REPLACE TABLE j_organization_house
(
    id_j_organization_house INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT,
    id_organization INTEGER REFERENCES organization (id_organization),
    id_house INTEGER REFERENCES house (id_house),
    address_class VARCHAR(20),  -- Different addresses are possible. Main, production site, etc.
    -- Recycle bin
    vis BOOLEAN NOT NULL DEFAULT TRUE
);



/* Connect people to organizations. */
CREATE OR REPLACE TABLE j_person_organization
(
    id_j_person_organization INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT,
    id_person INTEGER REFERENCES person (id_person),
    id_organization INTEGER REFERENCES organization (id_organization),
    position VARCHAR(20),  -- What is a person doing for a specific organization?
	-- Recycle bin
    vis BOOLEAN NOT NULL DEFAULT TRUE
);