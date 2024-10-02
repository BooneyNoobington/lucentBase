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