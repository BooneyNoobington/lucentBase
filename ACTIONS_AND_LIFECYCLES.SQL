/* Many records may have actual files attached to them on a file
system level. Or  a web page can
hold relevant information. A "link" to these files and pages is found here. */
CREATE OR REPLACE TABLE `link`
(
    `id_link` INTEGER PRIMARY KEY NOT NULL AUTO_INCREMENT
  , `name` VARCHAR(50) UNIQUE NOT NULL
  , `url` VARCHAR(500)
  , `file_path` VARCHAR(500)
  -- Every time "accepted" changes to TRUE, the app has to calculate the sha256 sum.
  , `accepted` BOOLEAN NOT NULL DEFAULT FALSE
  , `SHA256` VARCHAR(64)  -- Make sure the file wasn't tampered with.
  -- Make sure at least a file or an url is given.
  ,  CONSTRAINT file_or_url CHECK (
        -- Either a file path is given …
        (file_path IS NOT NULL AND url IS NULL)
        OR
        -- … or a url, but never both.
        (file_path IS NULL AND url IS NOT NULL)
    ) 
    -- Recycle bin.
  , `vis` BOOLEAN NOT NULL DEFAULT TRUE
);


/* One of two hearts of lucentLIMS. There are objects of interets (often called "samples")
and something that happens with them. Actions. */
CREATE OR REPLACE TABLE `action`
(
    `id_action` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `name` VARCHAR(50) NOT NULL
  , `iteration` DATETIME NOT NULL  -- Versioning.
  , `active` BOOLEAN NOT NULL  -- Is this action ready / permitted to be performed?
  , `description` VARCHAR(250)  -- A short description of what this action does.
    -- Name (or version) alone don't have to be unique but in combination they are.
  , CONSTRAINT `action_name_iterartion_unique` UNIQUE(`name`, `iteration`)
	-- Recycle bin.
  , `vis` BOOLEAN NOT NULL DEFAULT TRUE
);


/* Create a join between `action` and `link`. */
CREATE OR REPLACE TABLE `j_action_link`
(
    `id_j_action_link` INTEGER PRIMARY KEY NOT NULL AUTO_INCREMENT
  , `id_action` INTEGER NOT NULL REFERENCES `action` (`id_action`)
  , `id_link` INTEGER NOT NULL REFERENCES `link` (`id_link`)
    -- Recycle bin.
  , `vis` BOOLEAN NOT NULL DEFAULT TRUE  
);


/* Actions depend on one another. This table organizes this dependecies. */
CREATE OR REPLACE TABLE `j_action_dependency`
(
    -- primary key.
    `id_j_action_dependency` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
    -- Which action depends on which other action.
  , `id_dependant` INTEGER NOT NULL REFERENCES `action` (`id_action`)
  , `id_dependency` INTEGER NOT NULL REFERENCES `action` (`id_action`)
    -- Some dependencies are only recommended or completely optional.
  , `dependency_class` VARCHAR(12) NOT NULL CHECK (
        `dependency_class` IN ('strict', 'possibility')
    )
    -- An optional description of what a dependency means.
  , `description` VARCHAR(100)
    -- Make sure there are no doubled paring of two actions.
  , CONSTRAINT `id_action_id_action_unique` UNIQUE(`id_dependant`, `id_dependency`)
	-- Recycle bin.
  , `vis` BOOLEAN NOT NULL DEFAULT TRUE  
);



/* The dependency table solves the chicken and egg problem in the "egg" direction.
But to solve it in the "chicken" direction we need a second table. */
CREATE OR REPLACE TABLE `j_action_implication`
(
    `id_j_action_implication` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
    -- If this action is performed …
  , `id_implier` INTEGER NOT NULL REFERENCES `action` (`id_action`)
    -- this one automatically has to be performed too.
  , `id_implication` INTEGER NOT NULL REFERENCES `action` (`id_action`)
    -- Make sure there are no doubled paring of two actions.
  , CONSTRAINT `id_action_id_action_unique` UNIQUE(`id_implier`, `id_implication`)
    -- Recycle bin.
  , `vis` BOOLEAN NOT NULL DEFAULT TRUE
);



/* Just like an sop has a connection to people, actions have these too. */
CREATE OR REPLACE TABLE `j_action_person`
(
    `id_j_action_person` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
    -- What action is performed by which individual?
  , `id_action` INTEGER NOT NULL REFERENCES `action` (`id_action`)
  , `id_person` INTEGER NOT NULL REFERENCES `person` (`id_person`)
    -- What job does this person have regarding the action.
    -- Lab worker, supervisor, auditor …
  , `role` VARCHAR(40) NOT NULL CHECK (`role` IN ('auditor', 'manager', 'worker'))
    -- All of these attributes combined are unique.
  , CONSTRAINT `id_action_id_person_role` UNIQUE(`id_action`, `id_person`, `role`)
	-- Recycle bin.
  , `vis` BOOLEAN NOT NULL DEFAULT TRUE  
);


/* Connect actions and devices used to perform them. */
CREATE OR REPLACE TABLE `j_action_device`
(
    `id_j_action_device` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `id_action` INTEGER NOT NULL REFERENCES `action` (`id_action`)
  , `id_device` INTEGER NOT NULL REFERENCES `device` (`id_device`)
  	-- Recycle bin.
  , `vis` BOOLEAN NOT NULL DEFAULT TRUE    
);