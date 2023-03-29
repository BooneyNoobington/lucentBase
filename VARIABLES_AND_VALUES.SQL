/*
"variables" and "values"
Part of the lucentLIMS project.
Copyright: GPLv3

LucentLIMS is supposed to store not only measurement results but also other information that was
obtained during the procedures that lead to their quantification. Like the visual impression of a
sample or a confirmation that a sample ideed was filtrated.

The database entity that contains this infomration is the table `value`. Such a value is
ascocciated with a `variable` which in turn is a ascocciated with an `action`(described in its
own SQL file).
*/



/* Instances of `variable` will fill up the activity data. It can be many things
and is mostly a property of an action. Like a measurement result but also some other
meta data like "was sample x filtrated"? */
-- TODO: Connect to comound?
CREATE OR REPLACE TABLE `variable`
(
    `id_variable` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `identifier` VARCHAR(20) UNIQUE NOT NULL
  -- Later, when a variable is equipped with a value, the respective entry has
  -- to be put in a fitting column. Everything in a VARACHAR would violate NF1.
  , `value_class` VARCHAR(20) NOT NULL CHECK(
        `value_class` IN ('decimal', 'text', 'boolean', 'datetime')
    )
  , `description` VARCHAR(50)
);



/* Join up an action and a variable that should be asosciated with it. */
CREATE OR REPLACE TABLE `j_action_variable`
(
    `id_j_action_variable` INTEGER PRIMARY KEY UNIQUE NOT NULL
  -- Which action contains which variables?
  , `id_action` INTEGER NOT NULL REFERENCES `action` (`id_action`)
  , `id_variable` INTEGER NOT NULL REFERENCES `variable` (`id_variable`)
  -- Which unit is usually used? Can be overwritten in `result`.
  -- TODO: Mark this as default somehow.
  , `id_unit` INTEGER REFERENCES `unit` (`id_unit`)
  -- TODO: This seems fishy. Nothing of this can be seriously predicted. No convenience functions…
  -- What uncertainty is to be expected?
  , `uncertainty` DOUBLE
  -- Is this a relative or absolute value? (Percentage or actual value?)
  , `uncertainty_class` VARCHAR(9)
  -- In which unit is the uncertainty provided?
  , `uncertainty_unit` INTEGER REFERENCES `unit` (`id_unit`)
  -- How is the corresponding end result calculated? Points to a (usually r) file.
  , `calculation` VARCHAR(40)
);



/* Assign actions and (some or all of) their respective variables to a procedure. */
CREATE OR REPLACE TABLE `j_procedure_action_variable`
(
    `id_j_procedure_action_variable` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  -- To which procedure should the variables be added to?
  , `id_procedure` INTEGER REFERENCES `procedure` (`id_procedure`)
  -- Now this is where it gets tricky. You can't just add individual ids of actions and variables
  -- to a procedure. This is against normal form 4 (or 5?). Because you could add a variable x that
  -- isn't really asosciated with action y.
  -- To avoid that, add a record from another junction table.
  , `id_j_action_variable` INTEGER REFERENCES `j_action_variable` (`id_j_action_variable`)
  -- Make sure such a connection cannot be added redundantly.
  , CONSTRAINT `pav_unique` UNIQUE(`id_procedure`, `id_j_action_variable`)
);



/* Raw values are inserted in an somewhat unplanned manner. Every time an action
produces a result, it can be inserted into the database in a non nomralized manner.
Hence the prefix "nn".
This information does not have to be normalized since it is part of an interface. Nor
does it have to be equivalent to the names in the datbase.
For instance a results file can hold information about a 'pH-value' but the corresponding
`variable` can be called just 'pH'. */
CREATE OR REPLACE TABLE `nn_raw_value`
(
    `id_nn_raw_value` INTEGER NOT NULL PRIMARY KEY UNIQUE AUTO_INCREMENT
  -- Whatever idefication for a sample or something similar was provided to the interface.
  -- E.g. by a results file.
  -- The prefiy "map" means, that in the tables of `lucent` these columns have different names.
  -- But normally a distinct mapping between something like a sample if from a results file
  -- and `id_collection` should be possible.
  , `map_collection` VARCHAR(40) NOT NULL
  -- What was done, logged, measured … ?
  , `map_variable` VARCHAR(40) NOT NULL
  -- This varaible got its value by what action?
  , `map_action` VARCHAR(40) NOT NULL
  -- From wich device comes the reading?
  , `map_device` VARCHAR(40) NOT NULL  -- Can't be null in QM sensitive applications.
  -- Who did create this value?
  , `map_person` VARCHAR(40)  NOT NULL  -- In QM relevant applications definitively NOT NULL.
  -- When was the value aquired?
  , `moment` VARCHAR(40) NOT NULL
  -- What was the actual result and which unit has it?
  , `decimal_value` DECIMAL(30,20)
  , `text_value` VARCHAR(250)
  , `boolean_value` BOOLEAN
  , `datetime_value` DATETIME
  , `map_unit` VARCHAR(40)  -- A textual result like the description of a sample has no unit.
  , `map_uncertainty` VARCHAR(40)  -- Same here.
  -- Raw results need to be either accepted or declined.
  -- Otherwise it wouldn't be clear how to deal with them in a calculation.
  , `accepted` BOOLEAN NOT NULL DEFAULT 0  -- By default no value is accepted.
  -- Many measurements are performed in diluted samples.
  , `dilution` DECIMAL
  -- Make sure exactly one result type (decimal, text, boolean, date) is given.
  , CONSTRAINT `one_result_type_only` CHECK(
        (
          `decimal_value` IS NOT NULL
          AND `text_value` IS NULL
          AND `boolean_value` IS NULL
          AND `datetime_value` IS NULL
        )
        OR
        (
          `decimal_value` IS NULL
          AND `text_value` IS NOT NULL
          AND `boolean_value` IS NULL
          AND `datetime_value` IS NULL
        )
        OR
        (
          `decimal_value` IS NULL
          AND `text_value` IS NULL
          AND `boolean_value` IS NOT NULL
          AND `datetime_value` IS NULL
        )
        OR
        (
          `decimal_value` IS NULL
          AND `text_value` IS NULL
          AND `boolean_value` IS NULL
          AND `datetime_value` IS NOT NULL
        )
    )
  -- Make sure the same result (line) is only entered once.
  , CONSTRAINT `unique_results_only` UNIQUE(
        `map_collection`
      , `map_variable`
      , `map_action`
      , `moment`
    )
);



/* All things can have different names. A sample can have a different id from lab
to lab. Maybe one lab counts every collected flask as an individual sample
and another does not.
These different names can be mapped here.*/
CREATE OR REPLACE TABLE `mapping`
(
    `id_mapping` INTEGER NOT NULL UNIQUE PRIMARY KEY AUTO_INCREMENT
  -- Alternative name for a characterizing element like a sample id or
  -- a CAS number.
  , `alternative_identifier` VARCHAR(50) NOT NULL
  -- Which table is alternative name referring to?
  , `referenced_table` VARCHAR(40) NOT NULL
  -- The foreign key for the referenced table.
  -- Can be NULL at first. The app is responsible to let the user make the connection.
  , `id_referenced_table` INTEGER
);

/* This trigger ensures that the reference between `alternative_identifier` and the respective
table given by `referenced_table` is valid. */
DELIMITER $$  -- Temporarily change the delimiter to allow for an "outer" definition (BEGIN to END).
CREATE TRIGGER `t_mapping_validation`
-- Whenever a new record is inserted or an existing one changed fire this trigger.
BEFORE INSERT ON `mapping`
FOR EACH ROW  -- For every added or changed record.
BEGIN
    -- Declare a new variable holding the name of the referenced table.
    DECLARE v_referenced_table VARCHAR(50);
    SET v_referenced_table = NEW.`referenced_table`;

    -- Check wether the referenced table eveny exists.
    IF (
            SELECT              COUNT(*)
            FROM                `information_schema`.tables
            WHERE               `table_schema` = DATABASE()
                          AND   `table_name` = v_referenced_table
    ) = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Foreign key violation: referenced
        table does not exist.';
    END IF;

    -- If an id for referenced table was provided, check wether such a  value actually exists
    -- within the referenced table.
    IF NEW.`id_referenced_table` IS NOT NULL THEN
        IF (
            SELECT              COUNT(*)
            FROM                `information_schema`.columns
            WHERE               `table_schema` = DATABASE()
                          AND   `table_name` = v_referenced_table
                          AND   `column_name` = 'id_' || v_referenced_table
                          AND   `column_type` LIKE 'int%' -- Assumes that the ID column is an int.
                          AND   EXISTS (
                                    SELECT   1
                                    FROM     v_referenced_table
                                    WHERE    `id_` || v_referenced_table = NEW.`id_referenced_table`
                                )
        ) = 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Foreign key violation:
            referenced row does not exist.';
        END IF;
    END IF;
END $$
DELIMITER ;



/* The second heart of lucent are values that are attributed to specific variables.
Most prominently measurement results. But it can be a lot of things, like a confirmation
that a sample has been disposed of.
Also many different data types for the value itself are possbible. Decimal for measurement
results, booleans for a status, text for a description, an rgb value, and so on.
This is why there is no field for the actual value in `value`. */
-- TODO: Think about wether it might be better to have records in `value` entered
-- only if a result is available. Not before.
-- The junction between `collection` and `procedure` should already tell what variables
-- are to be exptected.
-- This would make the the first constraint a little easier since EXACTLY one
-- value columns has to be filled.
CREATE OR REPLACE TABLE `value`
(
    `id_value` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  -- To which collection do these values belong to?
  -- This asosciation is created automatically when a procedure is attached to a collection
  -- the corresponding variables (of which values can be seen as an instance) are stored here.
  , `id_collection` INTEGER NOT NULL REFERENCES `collection` (`id_collection`)
  -- What variables are to be provided with values?
  -- From this refrence we can derive the `procedure`, `action` and `variable`.
  , `id_j_procedure_action_variable` INTEGER NOT NULL
        REFERENCES `j_procedure_action_variable` (`id_j_procedure_action_variable`)
  -- Someone has to accept all entered values.
  -- TODO: This should trigger an entry in `event`.
  -- The actual value.
  , `decimal` DECIMAL
  , `text` VARCHAR(50)
  , `boolean` BOOLEAN
  , `datetime` DATETIME
  --
  , `accepted` BOOLEAN NOT NULL DEFAULT FALSE
  -- Make sure that at most one of the value columns is filled.
  , CONSTRAINT `one_entry_for_value_only` CHECK(  -- YUCK YUCK YUCK
      -- No entry in any of the value columns is allowed.
      (`decimal` IS NULL AND `text` IS NULL AND `boolean` IS NULL AND `datetime` IS NULL)
      OR
      (`decimal` IS NOT NULL AND `text` IS NULL AND `boolean` IS NULL AND `datetime` IS NULL)
      OR
      (`decimal` IS NULL AND `text` IS NOT NULL AND `boolean` IS NULL AND `datetime` IS NULL)
      OR
      (`decimal` IS NULL AND `text` IS NULL AND `boolean` IS NOT NULL AND `datetime` IS NULL)
      OR
      (`decimal` IS NULL AND `text` IS NULL AND `boolean` IS NULL AND `datetime` IS NOT NULL)
    )
  -- Make sure that a collection can hold each value only one time.
  , CONSTRAINT `id_collection_id_j_procedure_action_variable_unqiue` UNIQUE(
      `id_collection`, `id_j_procedure_action_variable`
    )
);
