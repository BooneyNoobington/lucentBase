/*
These tables describe classes which are used for cathegorization.
Like matrizes for samples or sample types (container classes).
*/



/* Objects of interest often have a matrix. Like air
, surface water or moon regolithe. */
CREATE OR REPLACE TABLE `matrix`
(
    `id_matrix` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `name` VARCHAR(40) NOT NULL UNIQUE
  , `description` VARCHAR(250)
    -- Recycle bin.
  , `vis` BOOLEAN NOT NULL DEFAULT TRUE
);



/* A sattelite table logging information about changes to
the records in `matrix`. */
CREATE OR REPLACE TABLE `l_matrix`
(
    `id_l_matrix` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
    -- Relate an entry to a record in the main table.
  , `id_matrix` INTEGER REFERENCES `matrix` (`id_matrix`)
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



/* This is essential to categorize a container / sample. It mostly describes how
a cointainer of values, no matter if it is a sample or some measurement series was
conducted in general. E.g. was surface water collected over time or as a spot sample? */
CREATE OR REPLACE TABLE `collection_class`
(
    `id_collection_class` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `name` VARCHAR(20) NOT NULL UNIQUE
  , `description` VARCHAR(250)
    -- Recycle bin.
  , `vis` BOOLEAN NOT NULL DEFAULT TRUE  
);



/* A sattelite table logging information about changes to
the records in `collection_class`. */
CREATE OR REPLACE TABLE `l_collection_class`
(
    `id_l_collection_class` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
    -- Relate an entry to a record in the main table.
  , `id_collection_class` INTEGER REFERENCES `collection_class` (`id_collection_class`)
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