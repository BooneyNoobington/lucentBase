/*
Global connections between smaller clusters of tables. These tables bring
together the three hearts of lucent.
- Collections
- Actions
- and Variables.
*/



/* The table itself is relatively straight forward. */
CREATE OR REPLACE TABLE `j_collection_procedure`
(
    `id_j_collection_procedure` INTEGER PRIMARY KEY NOT NULL UNIQUE AUTO_INCREMENT
  , `id_collection` INTEGER NOT NULL REFERENCES `collection` (`id_collection`)
  , `id_procedure` INTEGER NOT NULL REFERENCES `procedure` (`id_procedure`)
  -- Make sure that a collection cannot have the same procedure attached multiple times.
  , CONSTRAINT `id_collection_id_procedure_unique` UNIQUE (`id_collection`, `id_procedure`)
);

/* Every time a procedure is attached to a sample, insert all of the variables
in the actions ascocciated to the procedure to the values table. */
DELIMITER $$  -- Temporarily define a new delimieter so that
CREATE TRIGGER `t_fill_values`
AFTER INSERT ON `j_collection_procedure`  -- When a new procedure was attached to a collection.
FOR EACH ROW   -- Repeat the following for all new records in the junction table.
BEGIN

    -- Declare and set helper variables.
    DECLARE v_id_collection INT;
    DECLARE v_id_procedure INT;
    SET v_id_collection = NEW.`id_collection`;
    SET v_id_procedure = NEW.`id_procedure`;

    INSERT INTO     `value`
                    (`id_collection`, `id_j_procedure_action_variable`, `accepted`)
    SELECT          v_id_collection
                  , `j_procedure_action_variable`.`id_j_procedure_action_variable`
                  , v_id_procedure
    FROM            `j_procedure_action_variable`
    WHERE           `j_procedure_action_variable`.`id_procedure` = v_id_procedure;

END $$
DELIMITER ;  -- Reset to standard.
