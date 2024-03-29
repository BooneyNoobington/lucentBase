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



/* A sattelite table logging information about changes to
the records in `link`. */
CREATE OR REPLACE TABLE `l_link`
(
    `id_l_link` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
    -- Relate an entry to a record in the main table.
  , `id_link` INTEGER REFERENCES `link` (`id_link`)
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



/* Standard operating procedures (sop) are special documents that describe
the way actions and procedures are performed in an analytical environment.
Depending on how a lab organizes these instructions. They can be a link to
a website or a file.*/
CREATE OR REPLACE TABLE `sop`
(
    `id_sop` INTEGER PRIMARY KEY NOT NULL AUTO_INCREMENT
  , `name` VARCHAR(40) UNIQUE NOT NULL
  , `active` BOOLEAN NOT NULL DEFAULT FALSE
    -- Recycle bin.
  , `vis` BOOLEAN NOT NULL DEFAULT TRUE  
);



/* A sattelite table logging information about changes to
the records in `sop`. */
CREATE OR REPLACE TABLE `l_sop`
(
    `id_l_sop` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
    -- Relate an entry to a record in the main table.
  , `id_sop` INTEGER REFERENCES `sop` (`id_sop`)
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



/* Create a join between `link` `sop`. */
CREATE OR REPLACE TABLE `j_sop_link`
(
    `id_j_sop_link` INTEGER PRIMARY KEY NOT NULL AUTO_INCREMENT
  , `id_sop` INTEGER NOT NULL REFERENCES `sop` (`id_sop`)
  , `id_link` INTEGER NOT NULL REFERENCES `link` (`id_link`)
    -- Recycle bin.
  , `vis` BOOLEAN NOT NULL DEFAULT TRUE  
);



/* A sattelite table logging information about changes to
the records in `j_sop_link`. */
CREATE OR REPLACE TABLE `l_j_sop_link`
(
    `id_l_j_sop_link` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
    -- Relate an entry to a record in the main table.
  , `id_j_sop_link` INTEGER REFERENCES `j_sop_link` (`id_j_sop_link`)
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



/* A sattelite table logging information about changes to
the records in `j_sop_person`. */
CREATE OR REPLACE TABLE `l_j_sop_person`
(
    `id_l_j_sop_person` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
    -- Relate an entry to a record in the main table.
  , `id_j_sop_person` INTEGER REFERENCES `j_sop_person` (`id_j_sop_person`)
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



/* A sattelite table logging information about changes to
the records in `action`. */
CREATE OR REPLACE TABLE `l_action`
(
    `id_l_action` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
    -- Relate an entry to a record in the main table.
  , `id_action` INTEGER REFERENCES `action` (`id_action`)
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



/* Actions depend on one another. This table organizes this dependecies. */
CREATE OR REPLACE TABLE `j_action_dependency`
(
    -- primary key.
    `id_action_action` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
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



/* A sattelite table logging information about changes to
the records in `j_action_dependency`. */
CREATE OR REPLACE TABLE `l_j_action_dependency`
(
    `id_l_j_action_dependency` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
    -- Relate an entry to a record in the main table.
  , `id_j_action_dependency` INTEGER REFERENCES `j_action_dependency` (`id_j_action_dependency`)
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



/* A sattelite table logging information about changes to
the records in `j_action_implication`. */
CREATE OR REPLACE TABLE `l_j_action_implication`
(
    `id_l_j_action_implication` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
    -- Relate an entry to a record in the main table.
  , `id_j_action_implication` INTEGER REFERENCES `j_action_implication` (`id_j_action_implication`)
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



/* A sattelite table logging information about changes to
the records in `j_action_person`. */
CREATE OR REPLACE TABLE `l_j_action_person`
(
    `id_l_j_action_person` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
    -- Relate an entry to a record in the main table.
  , `id_j_action_person` INTEGER REFERENCES `j_action_person` (`id_j_action_person`)
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



/* Same goes for a specific collectionclass. */
CREATE OR REPLACE TABLE `j_action_collection_class`
(
    `id_action_collection_class` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `id_action` INTEGER NOT NULL REFERENCES `action` (`id_action`)
  , `id_collection_class` INTEGER NOT NULL REFERENCES `collection_class` (`id_collection_class`)
  -- Avoind redundant connections.
  , CONSTRAINT `id_action_id_collection_class_unqiue` UNIQUE(`id_action`, `id_collection_class`)
  	-- Recycle bin.
  , `vis` BOOLEAN NOT NULL DEFAULT TRUE    
);



/* A sattelite table logging information about changes to
the records in `j_action_collection_class`. */
CREATE OR REPLACE TABLE `l_j_action_collection_class`
(
    `id_l_j_action_collection_class` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
    -- Relate an entry to a record in the main table.
  , `id_j_action_collection_class` INTEGER REFERENCES `j_action_collection_class` (`id_j_action_collection_class`)
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



/* Connect actions and devices used to perform them. */
CREATE OR REPLACE TABLE `j_action_device`
(
    `id_action_device` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `id_action` INTEGER NOT NULL REFERENCES `action` (`id_action`)
  , `id_device` INTEGER NOT NULL REFERENCES `device` (`id_device`)
  	-- Recycle bin.
  , `vis` BOOLEAN NOT NULL DEFAULT TRUE    
);



/* A sattelite table logging information about changes to
the records in `j_action_device`. */
CREATE OR REPLACE TABLE `l_j_action_device`
(
    `id_l_j_action_device` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
    -- Relate an entry to a record in the main table.
  , `id_j_action_device` INTEGER REFERENCES `j_action_device` (`id_j_action_device`)
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