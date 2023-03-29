/*

*/

/* An organisation can be a group, a company or any other collection
of individuals. Mostly for categorization.*/
CREATE OR REPLACE TABLE `organisation`
(
    `id_organisation` INTEGER PRIMARY KEY NOT NULL
  , `identifier` VARCHAR(50) UNIQUE
  , `short_identifier` VARCHAR(15)
  , `connection` VARCHAR(25)  -- E.g. partner, client, …
);

/* Information aboit a particular person like an employee or contractor, etc.. */
CREATE OR REPLACE TABLE `person`
(
    `id_person` INTEGER PRIMARY KEY UNIQUE NOT NULL
  , `id_address` INTEGER REFERENCES `address` (`id_address`)
  , `id_organisation` INTEGER REFERENCES `organisation` (`id_organisation`)
  , `given_name` VARCHAR(50) NOT NULL
  , `surname` VARCHAR(50) NOT NULL
  , `unix_account` VARCHAR(50) UNIQUE
);
