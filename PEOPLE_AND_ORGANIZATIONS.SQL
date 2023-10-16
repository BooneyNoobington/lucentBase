/* An organisation can be a group, a company or any other collection
of individuals. Mostly for categorization.*/
CREATE OR REPLACE TABLE `organisation`
(
    `id_organisation` INTEGER PRIMARY KEY NOT NULL AUTO_INCREMENT
  , `identifier` VARCHAR(50) UNIQUE
  , `short_identifier` VARCHAR(15)
  , `connection` VARCHAR(25)  -- E.g. partner, client, …
);



/* Information aboit a particular person like an employee or contractor, etc.. */
CREATE OR REPLACE TABLE `person`
(
    `id_person` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `id_organisation` INTEGER REFERENCES `organisation` (`id_organisation`)
  , `given_name` VARCHAR(50) NOT NULL
  , `surname` VARCHAR(50) NOT NULL
  , `unix_account` VARCHAR(50) UNIQUE
);

/* Connect people and organisations to addresses. */
CREATE OR REPLACE TABLE `j_person_address`
(
    `id_j_person_address` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `id_person` INTEGER REFERENCES `person` (`id_person`)
  , `id_address` INTEGER REFERENCES `address` (`id_address`)
  , `address_class` VARCHAR(20)  -- Different addresses are possible. Home, work, etc.
);

/* Connect organisations and organisations to addresses. */
CREATE OR REPLACE TABLE `j_organisation_address`
(
    `id_j_organisation_address` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `id_organisation` INTEGER REFERENCES `organisation` (`id_organisation`)
  , `id_address` INTEGER REFERENCES `address` (`id_address`)
  , `address_class` VARCHAR(20)  -- Different addresses are possible. Main, production site, etc.
);

/* Connect people to organisations. */
CREATE OR REPLACE TABLE `j_person_organisation`
(
    `id_j_person_organisation` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `id_person` INTEGER REFERENCES `person` (`id_person`)
  , `id_address` INTEGER REFERENCES `organisation` (`id_organisation`)
  , `position` VARCHAR(20)  -- What is a person doing for a specific organisation.
);
