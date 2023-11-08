/*
Global connections between smaller clusters of tables. These tables bring
together the three hearts of lucent.
- Collections
- Actions
- and Variables.
*/



/* The table itself is relatively straight forward. */
CREATE OR REPLACE TABLE `j_collection_lifecycle`
(
    `id_j_collection_lifecycle` INTEGER PRIMARY KEY NOT NULL UNIQUE AUTO_INCREMENT
  , `id_collection` INTEGER NOT NULL REFERENCES `collection` (`id_collection`)
  , `id_lifecycle` INTEGER NOT NULL REFERENCES `lifecycle` (`id_lifecycle`)
  -- Make sure that a collection cannot have the same lifecycle attached multiple times.
  , CONSTRAINT `id_collection_id_lifecycle_unique` UNIQUE (`id_collection`, `id_lifecycle`)
);



/* A sattelite table logging information about changes to
the records in `j_collection_lifecycle`. */
CREATE OR REPLACE TABLE `l_j_collection_lifecycle`
(
    `id_l_j_collection_lifecycle` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
    -- Relate an entry to a record in the main table.
  , `id_j_collection_lifecycle` INTEGER REFERENCES `j_collection_lifecycle` (`id_j_collection_lifecycle`)
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



/* Every time a lifecycle is attached to a sample, insert all of the variables
in the actions ascocciated to the lifecycle to the values table. */
DELIMITER $$  -- Temporarily define a new delimieter so that ";" can be used to terminate stmts.
CREATE TRIGGER `t_fill_values`
AFTER INSERT ON `j_collection_lifecycle`  -- When a new lifecycle was attached to a collection.
FOR EACH ROW   -- Repeat the following for all new records in the junction table.
BEGIN

    -- Declare and set helper variables.
    DECLARE v_id_collection INT;
    DECLARE v_id_lifecycle INT;
    SET v_id_collection = NEW.`id_collection`;
    SET v_id_lifecycle = NEW.`id_lifecycle`;

    -- Insert a combination of a collection id and a fitting variable id into `value`.
    INSERT INTO     `value`
                    (`id_collection`, `id_j_lifecycle_action_variable`)
    SELECT          v_id_collection
                  , `j_lifecycle_action_variable`.`id_j_lifecycle_action_variable`
                  , v_id_lifecycle
    FROM            `j_lifecycle_action_variable`
    WHERE           `j_lifecycle_action_variable`.`id_lifecycle` = v_id_lifecycle;


END $$
DELIMITER ;  -- Reset to standard.
