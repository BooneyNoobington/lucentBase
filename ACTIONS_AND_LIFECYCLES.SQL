/* Many records may have actual files attached to them on a file
system level. Or in content management systems a web page can
hold relevant information. A "link" to these files and pages is found here. */
CREATE OR REPLACE TABLE `link`
(
    `id_link` INTEGER PRIMARY KEY NOT NULL AUTO_INCREMENT
  , `name` VARCHAR(40) UNIQUE NOT NULL
  , `url` VARCHAR(500)
  , `file_path` VARCHAR(500)
  -- Every time "accepted" changes to TRUE, the app has to calculate the sha256 sum.
  , `accepted` BOOLEAN NOT NULL DEFAULT 0
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



/* Standard operating procedures (sop) are special documents that describe
the way actions and procedures are performed in an analytical environment.
Depending on how a lab organizes these instructions. They can be a link to
a website or a file.*/
CREATE OR REPLACE TABLE `sop`
(
    `id_sop` INTEGER PRIMARY KEY NOT NULL AUTO_INCREMENT
  , `name` VARCHAR(40) UNIQUE NOT NULL
  , `active` BOOLEAN NOT NULL
    -- Recycle bin.
  , `vis` BOOLEAN NOT NULL DEFAULT TRUE  
);



/* Create a join between `link` `sop`. */
CREATE OR REPLACE TABLE `j_sop_link`
(
    `id_j_sop_link` INTEGER PRIMARY KEY NOT NULL AUTO_INCREMENT
  , `id_sop` INTEGER NOT NULL REFERENCES `sop` (`id_sop`)
  , `id_link` INTEGER NOT NULL REFERENCES `link` (`id_link`)
    -- Recycle bin.
  , `vis` BOOLEAN NOT NULL DEFAULT TRUE  
);



/* Connect people with a standard operation procedure and
explain what their role in regards of the sop are. */
CREATE OR REPLACE TABLE `j_sop_person`
(
    `id_j_sop_person` INTEGER PRIMARY KEY NOT NULL AUTO_INCREMENT
  , `id_sop` INTEGER REFERENCES `sop` (`id_sop`)
  , `id_person` INTEGER REFERENCES `person` (`id_person`)
	-- A person has a specific job regarding an sop.
  , `role` VARCHAR(40) NOT NULL CHECK (`role` IN ('author', 'responsible', 'releaser'))
	-- Make sure that the combination of an sop, a person and a specified role are unique.
  , CONSTRAINT `id_sop_id_person_role_unique` UNIQUE(`id_sop`, `id_person`, `role`)
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
  , `id_sop` INTEGER REFERENCES `sop` (`id_sop`)  -- How to do it is explained in sop.
    -- Name (or version) alone don't have to be unique but in combination they are.
  , CONSTRAINT `action_name_iterartion_unique` UNIQUE(`name`, `iteration`)
	-- Recycle bin.
  , `vis` BOOLEAN NOT NULL DEFAULT TRUE
);


/* Often times many actions are needed to be performed to do whatever is desired to
happen with a collection such as a sample. These are combined in a "lifecycle".
A lifecycle is selective concerning variables. Not all variables of an action are
required.
In lucentLIMS it is mandatory to provide "lifecycles", not just optional. */
CREATE OR REPLACE TABLE `lifecycle`
(
    `id_lifecycle` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `name` VARCHAR(50) UNIQUE NOT NULL
  , `iteration` DATETIME NOT NULL  -- Versioning.
    -- Name (and version) alone don't have to be unique. But in combination
    -- they should be.
  , CONSTRAINT `name_iteration_unique` UNIQUE(`name`, `iteration`)
	-- Recycle bin.
  , `vis` BOOLEAN NOT NULL DEFAULT TRUE  
);


/* A lifecycle also organizes the dependencies of actions upon one another.
A samples' lifecycle can start by an action "sampling", then some measurement,
result validation and end with some action describing disposal. */
CREATE OR REPLACE TABLE `j_lifecycle_dependency`
(
    -- primary key.
    `id_action_action` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
    -- Dependencies are vallid for a specific lifecycle. Sometimes actions like "report_completion"
    -- depend on only one measurement, sometimes dozens.
  , `id_lifecycle` INTEGER REFERENCES `lifecycle` (`id_lifecycle`)
    -- Which action depends on which other action.
  , `id_dependant` INTEGER NOT NULL REFERENCES `action` (`id_action`)
  , `id_dependency` INTEGER NOT NULL REFERENCES `action` (`id_action`)
    -- Some dependencies are only recommended or completely optional.
  , `dependency_class` VARCHAR(12) NOT NULL CHECK (
        `dependency_class` IN ('mandatory', 'recommended', 'optional')
    )
    -- An optional description of what a dependency means.
  , `description` VARCHAR(100)
    -- Make sure there are no doubled paring of two actions.
  , CONSTRAINT `id_action_id_action_unique` UNIQUE(`id_dependant`, `id_dependency`, `id_lifecycle`)
	-- Recycle bin.
  , `vis` BOOLEAN NOT NULL DEFAULT TRUE  
);
-- REMARK: The way this is structured, a lifecycle cannot consist of one singular action.


/* Just like an sop has a connection to people, actions have these too. */
CREATE OR REPLACE TABLE `j_action_person`
(
    `id_action_person` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
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



/* An action can have a narrowed application. E.g. a HPLC measurement might
work with groundwater but not blood. */
CREATE OR REPLACE TABLE `j_action_object`
(
    `id_action_object` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `id_object` INTEGER NOT NULL REFERENCES `object` (`id_object`)
  , `id_action` INTEGER NOT NULL REFERENCES `action` (`id_action`)
    -- Avoind redundant connections.
  , CONSTRAINT `id_action_id_object_unique` UNIQUE(`id_action`, `id_object`)
  	-- Recycle bin.
  , `vis` BOOLEAN NOT NULL DEFAULT TRUE  
);



/* Same goes for a specific collectionclass. */
CREATE OR REPLACE TABLE `j_action_collectionclass`
(
    `id_action_collectionclass` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `id_action` INTEGER NOT NULL REFERENCES `action` (`id_action`)
  , `id_collectionclass` INTEGER NOT NULL REFERENCES `collectionclass` (`id_collectionclass`)
  -- Avoind redundant connections.
  , CONSTRAINT `id_action_id_collectionclass_unqiue` UNIQUE(`id_action`, `id_collectionclass`)
  	-- Recycle bin.
  , `vis` BOOLEAN NOT NULL DEFAULT TRUE    
);



/* Connect actions and devices used to perform them. */
CREATE OR REPLACE TABLE `j_action_device`
(
    `id_action_device` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `id_action` INTEGER NOT NULL REFERENCES `action` (`id_action`)
  , `id_device` INTEGER NOT NULL REFERENCES `device` (`id_device`)
  	-- Recycle bin.
  , `vis` BOOLEAN NOT NULL DEFAULT TRUE    
);
