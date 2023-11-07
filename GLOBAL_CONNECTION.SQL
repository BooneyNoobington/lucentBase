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
