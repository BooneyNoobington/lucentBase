/* An organization can be a group, a company or any other collection
of individuals. Mostly for categorization.*/
CREATE OR REPLACE TABLE `organization`
(
    `id_organization` INTEGER PRIMARY KEY NOT NULL AUTO_INCREMENT
  , `name` VARCHAR(50) UNIQUE
  , `shorthand` VARCHAR(15)
  , `connection` VARCHAR(25)  -- E.g. partner, client, …
	-- Recycle bin.
  , `vis` BOOLEAN NOT NULL DEFAULT TRUE
);



/* A sattelite table logging information about changes to
the records in `organization`. */
CREATE OR REPLACE TABLE `l_organization`
(
    `id_l_organization` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
    -- Relate an entry to a record in the main table.
  , `id_organization` INTEGER REFERENCES `organization` (`id_organization`)
    -- What kind of change happened to the record? Update, Insert, deletion, ...?
  , `change` VARCHAR(50) NOT NULL
    -- When did the change occur?
  , `t` DATETIME NOT NULL
    -- Who performed the change?
  , `id_person` INTEGER REFERENCES `person` (`id_person`)
    -- Any additional information?
  , `note` VARCHAR(500)
    -- How did the record look before?
    -- Every time a record is changed, this sum should be computable
    -- of all the columns of the specific record. in the main table.
  , `checksum` VARCHAR(100) NOT NULL
);



/* Information about a particular person like an employee or contractor, etc.. */
CREATE OR REPLACE TABLE `person`
(
    `id_person` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `id_organization` INTEGER REFERENCES `organization` (`id_organization`)
  , `given_name` VARCHAR(50) NOT NULL
  , `surname` VARCHAR(50) NOT NULL
  , `unix_account` VARCHAR(50) UNIQUE
	-- Recycle bin.
  , `vis` BOOLEAN NOT NULL DEFAULT TRUE
);



/* A sattelite table logging information about changes to
the records in `person`. */
CREATE OR REPLACE TABLE `l_person`
(
    `id_l_person` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
    -- Relate an entry to a record in the main table.
  , `id_person` INTEGER REFERENCES `person` (`id_person`)
    -- What kind of change happened to the record? Update, Insert, deletion, ...?
  , `change` VARCHAR(50) NOT NULL
    -- When did the change occur?
  , `t` DATETIME NOT NULL
    -- Who performed the change?
  , `id_person` INTEGER REFERENCES `person` (`id_person`)
    -- Any additional information?
  , `note` VARCHAR(500)
    -- How did the record look before?
    -- Every time a record is changed, this sum should be computable
    -- of all the columns of the specific record. in the main table.
  , `checksum` VARCHAR(100) NOT NULL
);



/* Connect people and organizations to addresses (a specific house). */
CREATE OR REPLACE TABLE `j_person_house`
(
    `id_j_person_house` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `id_person` INTEGER REFERENCES `person` (`id_person`)
  , `id_house` INTEGER REFERENCES `house` (`id_house`)
  , `address_class` VARCHAR(20)  -- Different addresses are possible. Home, work, etc.
	-- Recycle bin.
  , `vis` BOOLEAN NOT NULL DEFAULT TRUE
);



/* A sattelite table logging information about changes to
the records in `j_person_house`. */
CREATE OR REPLACE TABLE `l_j_person_house`
(
    `id_l_j_person_house` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
    -- Relate an entry to a record in the main table.
  , `id_j_person_house` INTEGER REFERENCES `j_person_house` (`id_j_person_house`)
    -- What kind of change happened to the record? Update, Insert, deletion, ...?
  , `change` VARCHAR(50) NOT NULL
    -- When did the change occur?
  , `t` DATETIME NOT NULL
    -- Who performed the change?
  , `id_person` INTEGER REFERENCES `person` (`id_person`)
    -- Any additional information?
  , `note` VARCHAR(500)
    -- How did the record look before?
    -- Every time a record is changed, this sum should be computable
    -- of all the columns of the specific record. in the main table.
  , `checksum` VARCHAR(100) NOT NULL
);



/* Connect organizations and organizations to addresses. */
CREATE OR REPLACE TABLE `j_organization_house`
(
    `id_j_organization_house` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `id_organization` INTEGER REFERENCES `organization` (`id_organization`)
  , `id_house` INTEGER REFERENCES `house` (`id_house`)
  , `address_class` VARCHAR(20)  -- Different addresses are possible. Main, production site, etc.
	-- Recycle bin.
  , `vis` BOOLEAN NOT NULL DEFAULT TRUE
);



/* A sattelite table logging information about changes to
the records in `j_organization_house`. */
CREATE OR REPLACE TABLE `l_j_organization_house`
(
    `id_l_j_organization_house` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
    -- Relate an entry to a record in the main table.
  , `id_j_organization_house` INTEGER REFERENCES `j_organization_house` (`id_j_organization_house`)
    -- What kind of change happened to the record? Update, Insert, deletion, ...?
  , `change` VARCHAR(50) NOT NULL
    -- When did the change occur?
  , `t` DATETIME NOT NULL
    -- Who performed the change?
  , `id_person` INTEGER REFERENCES `person` (`id_person`)
    -- Any additional information?
  , `note` VARCHAR(500)
    -- How did the record look before?
    -- Every time a record is changed, this sum should be computable
    -- of all the columns of the specific record. in the main table.
  , `checksum` VARCHAR(100) NOT NULL
);



/* Connect people to organizations. */
CREATE OR REPLACE TABLE `j_person_organization`
(
    `id_j_person_organization` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `id_person` INTEGER REFERENCES `person` (`id_person`)
  , `id_organization` INTEGER REFERENCES `organization` (`id_organization`)
  , `position` VARCHAR(20)  -- What is a person doing for a specific organization?
	-- Recycle bin.
  , `vis` BOOLEAN NOT NULL DEFAULT TRUE
);



/* A sattelite table logging information about changes to
the records in `j_person_organization`. */
CREATE OR REPLACE TABLE `l_j_person_organization`
(
    `id_l_j_person_organization` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
    -- Relate an entry to a record in the main table.
  , `id_j_person_organization` INTEGER REFERENCES `j_person_organization` (`id_j_person_organization`)
    -- What kind of change happened to the record? Update, Insert, deletion, ...?
  , `change` VARCHAR(50) NOT NULL
    -- When did the change occur?
  , `t` DATETIME NOT NULL
    -- Who performed the change?
  , `id_person` INTEGER REFERENCES `person` (`id_person`)
    -- Any additional information?
  , `note` VARCHAR(500)
    -- How did the record look before?
    -- Every time a record is changed, this sum should be computable
    -- of all the columns of the specific record. in the main table.
  , `checksum` VARCHAR(100) NOT NULL
);