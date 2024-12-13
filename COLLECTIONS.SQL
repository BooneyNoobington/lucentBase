/* The second heart of lucent. A collection holds parameters (or values) that are
obtained by performing a specific action. It is a specific instance of an object.
Like an actual soil sample from the object soil in my backyard, left of my porch.
Or something immaterial like radation close to a nuclear power plant. */
CREATE OR REPLACE TABLE collection
(
    id_collection INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT,
  	-- The "name" of a collection should not be chosen by the user but rather follow
  	-- a specific counting mechanism
   name VARCHAR(40) UNIQUE,
   	-- Of which object is this collection an instance of? Or, of what was this sample taken?
    id_matrix INTEGER NOT NULL REFERENCES matrix (id_matrix),
  	-- If you take a water sample from your tab, the collection would be a sample and
  	-- the object "water from a tab". This can be taken as a spot sample or collected over time
    collection_class VARCHAR(50) NOT NULL,
  	-- Where did this collection originate from
    id_spot INTEGER REFERENCES spot (id_spot),
    id_site INTEGER REFERENCES site (id_site),
    -- Make sure a spot OR a site is related, never both
    CONSTRAINT spot_or_site CHECK (
        id_spot IS NULL AND id_site IS NOT NULL  -- Site was specified
        OR
        id_spot IS NOT NULL AND id_site IS NULL  -- Spot was specidied
    ),
    -- Make sure collection classes are taken from a robust set of choices
    CONSTRAINT collection_class_choices CHECK(
        collection_class IN (
            'spot sample',
            'mixed sample',
            'collective sample',
            'time series',
            'free measurement'
            -- append as needed
        )
    ),
  	-- Recycle bin
    vis BOOLEAN NOT NULL DEFAULT TRUE    
);