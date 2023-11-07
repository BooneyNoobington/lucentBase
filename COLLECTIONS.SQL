/* The second heart of lucent. A collection holds variables (or values) that are
obtained by performing a specific action. It is a specific instance of an object.
Like an actual soil sample from the `object` soil in my backyard, left of my porch.
Or something immaterial like radation close to a nuclear power plant. */
CREATE OR REPLACE TABLE `collection`
(
    `id_collection` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  	-- The "name" of a collection should not be chosen by the user but rather follow
  	-- a specific counting mechanism.
  , `name` VARCHAR(40) UNIQUE NOT NULL
  	-- Of which object is this collection an instance of? Or, of what was this sample taken?
  , `id_matrix` INTEGER NOT NULL REFERENCES `matrix` (`id_matrix`)
  	-- If you take a water sample from your tab, the collection would be a sample and
  	-- the object "water from a tab". This can be taken as a spot sample or collected over time.
  , `id_collection_class` INTEGER NOT NULL REFERENCES `collection_class` (`id_collection_class`)
  	-- Where did this collection originate from.
  , `id_spot` INTEGER REFERENCES `spot` (`id_spot`)
  , `id_site` INTEGER REFERENCES `site` (`id_site`)
    -- Make sure a spot OR a site is related, never both.
  , CONSTRAINT `spot_or_site` CHECK (
        `id_spot` IS NULL AND `id_site` IS NOT NULL  -- Site was specified.
        OR
        `id_spot` IS NOT NULL AND `id_site` IS NULL  -- Spot was specidied.
    )
  	-- Recycle bin.
  , `vis` BOOLEAN NOT NULL DEFAULT TRUE    
);



/* A sattelite table logging information about changes to
the records in `collection`. */
CREATE OR REPLACE TABLE `l_collection`
(
    `id_l_collection` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
    -- Relate an entry to a record in the main table.
  , `id_collection` INTEGER REFERENCES `collection` (`id_collection`)
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