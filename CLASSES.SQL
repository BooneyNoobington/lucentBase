/*
These tables describe classes which are used for cathegorization.
Like matrizes for samples or sample types (container classes).
*/



/* Objects of interest often have a matrix. Like air, surface water, moon regolithe
or even an entire airplane. */
CREATE OR REPLACE TABLE `matrix`
(
    `id_matrix` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `identifier` VARCHAR(40) NOT NULL UNIQUE
  , `description` VARCHAR(250)  -- TODO: Shouldn't really be neccessary.
);



/* Different things can be the focus of an anlysis. An environmental sample like
water taken from a river or something immaterial background noise in a schoolyard.
These can be connected to a specific site but don't have to be.*/
-- TODO: For a table that central it doesn't have many columns.
CREATE OR REPLACE TABLE `object`
(
    `id_object` INTEGER PRIMARY KEY NOT NULL AUTO_INCREMENT
  , `identifier` VARCHAR(40) UNIQUE NOT NULL
  -- Connect to a specific site that has the focus of the analysis.
  , `id_site` INTEGER REFERENCES `site` (`id_site`)
  -- Important for physical samples. Can be null if not applicable.
  , `id_matrix` INTEGER REFERENCES `matrix` (`id_matrix`)
);
-- TODO: Maybe link to another table called objectclass? Realize control samples
-- and stored chemicals in that way.



/* This is essential to categorize a container / sample. It mostly describes how
a cointainer of values, no matter if it is a sample or some measurement series was
conducted in general. E.g. was surface water collected over time or as a spot sample? */
CREATE OR REPLACE TABLE `collectionclass`
(
    `id_collectionclass` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `identifier` VARCHAR(20) NOT NULL UNIQUE
  , `description` VARCHAR(250)
);
