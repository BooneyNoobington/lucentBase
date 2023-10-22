/* The second heart of lucent. A collection holds variables (or values) that are
obtained by performing a specific action. It is a specific instance of an object.
Like an actual soil sample from the `object` soil in my backyard, left of my porch.
Or something immaterial like radation close to a nuclear power plant. */
CREATE OR REPLACE TABLE `collection`
(
    `id_collection` INTEGER PRIMARY KEY UNIQUE NOT NULL
  -- The "name" of a collection should not be chosen by the user but rather follow
  -- a specific counting mechanism.
  , `name` VARCHAR(40) UNIQUE NOT NULL
  -- Of which object is this collection an instance of? Or, of what was this sample taken?
  , `id_object` INTEGER NOT NULL REFERENCES `object` (`id_object`)
  -- If you take a water sample from your tab, the collection would be a sample and
  -- the object "water from a tab". This can be taken as a spot sample or collected over time.
  , `id_collectionclass` INTEGER NOT NULL REFERENCES `collectionclass` (`id_collectionclass`)
  	-- Recycle bin.
  , `vis` BOOLEAN NOT NULL DEFAULT TRUE    
);
