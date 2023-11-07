/*
"variables" and "values"
Part of the lucentLIMS project.
Copyright: GPLv3

LucentLIMS is supposed to store not only measurement results but also other information that was
obtained during the lifecycle that lead to their quantification. Like the visual impression of a
sample or a confirmation that a sample ideed was filtrated.

The database entity that contains this infomration is the table `value`. Such a value is
ascocciated with a `variable` which in turn is a ascocciated with an `action`(described in its
own SQL file).
*/



/* Instances of `variable` will fill up the activity data. It can be many things
and is always a property of an action. Like a measurement result but also some other
meta data like "was sample x filtrated"? */

CREATE OR REPLACE TABLE `variable`
(
    `id_variable` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `name` VARCHAR(20) UNIQUE NOT NULL
    -- Later, when a variable is equipped with a value, the respective entry has
    -- to be put in a fitting column. Everything in a VARACHAR would violate NF1.
  , `value_class` VARCHAR(20) NOT NULL CHECK(
        `value_class` IN ('decimal', 'text', 'boolean', 'datetime')
        -- ADAPT: Maybe others if an action produces a geometry type for instance.
    )
    -- A short description of this var. Mostly for the end user.
  , `description` VARCHAR(50)
    -- While it isn't clear what unit the value of var will have, the dimension
    -- should always be clear. A date cannot have dimension "mass" but "time".
  , `id_dimension` INTEGER REFERENCES `dimension` (`id_dimension`)
  	-- Recycle bin.
  , `vis` BOOLEAN NOT NULL DEFAULT TRUE    
);



/* Sometimes variables can be corresponding with other variables.
Like the liquids temperature with a pH-value. */
CREATE OR REPLACE TABLE `j_variable_variable`
(
	`id_j_variable_variable` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `id_variable1` INTEGER REFERENCES `variable` (`id_variable`)
  , `id_variable2` INTEGER REFERENCES `variable` (`id_variable`)
    -- A short explaination why the two variables are connected together.
  , `description` VARCHAR(50)
  	-- Recycle bin.
  , `vis` BOOLEAN NOT NULL DEFAULT TRUE  
);


/* Relate an action and a variable. */
CREATE OR REPLACE TABLE `j_action_variable`
(
    `id_j_action_variable` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
	-- Which action contains which variables?
  , `id_action` INTEGER NOT NULL REFERENCES `action` (`id_action`)
  , `id_variable` INTEGER NOT NULL REFERENCES `variable` (`id_variable`)
	-- What uncertainty is to be expected?
  , `uncertainty` DOUBLE
	-- Is this a relative or absolute value? (Percentage or actual value?)
  , `uncertainty_class` VARCHAR(9)
	-- In which unit is the uncertainty provided?
  , `uncertainty_id_unit` INTEGER REFERENCES `unit` (`id_unit`)
	-- How is the corresponding end result calculated? Points to a (usually r) file.
  , `calculation` VARCHAR(40)
	-- Recycle bin.
  , `vis` BOOLEAN NOT NULL DEFAULT TRUE  
);



/* Assign actions and some or all of their respective variables to a lifecycle. */
-- CREATE OR REPLACE TABLE `j_lifecycle_action_variable`
-- (
--     `id_j_lifecycle_action_variable` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
--     -- To which lifecycle should the variables be added to?
--   , `id_lifecycle` INTEGER REFERENCES `lifecycle` (`id_lifecycle`)
--     -- Now this is where it gets tricky. You can't just add individual ids of actions and variables
--     -- to a lifecycle. This is against normal form 4 (or 5?). Because you could add a variable
--     -- x that isn't really asosciated with action y.
--     -- To avoid that, add a record from another junction table.
--   , `id_j_action_variable` INTEGER REFERENCES `j_action_variable` (`id_j_action_variable`)
--     -- Make sure such a connection cannot be added redundantly.
--   , CONSTRAINT `pav_unique` UNIQUE(`id_lifecycle`, `id_j_action_variable`)
--   	-- Recycle bin.
--   , `vis` BOOLEAN NOT NULL DEFAULT TRUE
-- );



/* The second heart of lucent are values that are attributed to specific variables.
Most prominently measurement results. But it can be a lot of things, like a confirmation
that a sample has been disposed of.
Also many different data types for the value itself are possbible. Decimal for measurement
results, booleans for a status, text for a description, an rgb value, and so on. */
CREATE OR REPLACE TABLE `value`
(
    `id_value` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
    -- To which collection do these values belong to?
    -- This asosciation is created automatically when a lifecycle is attached to a collection.
    -- The corresponding variables are stored here.
  , `id_collection` INTEGER NOT NULL REFERENCES `collection` (`id_collection`)
    -- What variables are to be provided with values?
    -- From this reference we can derive the `lifecycle`, `action` and `variable`.
  , `id_j_action_variable` INTEGER NOT NULL REFERENCES `j_action_variable` (`id_j_action_variable`)
    -- A value can be measured multiple times. Not to be confused with raw values
    -- that are repeatadly measured to increase precision.
    -- More like repeated measurements for time series.
  , `repetition` INTEGER DEFAULT 0
	-- A repetition can be done for a number of reasons.
    -- For instance if the first result of a measurement was produced
    -- without an obvious error but still is unplausibel.
    -- Or because remeasuring is to be exptected. E.g. in a time series.
    -- The actual value.
  , `repetition_class` VARCHAR(20) CHECK (`repetition_class` IN ('time series', 'remeasuring'))

    -- The actual value.
  , `decimal_value` DECIMAL
  , `text_value` VARCHAR(50)
  , `boolean_value` BOOLEAN
  , `datetime_value` DATETIME

  -- Someone has to accept all entered values.
  , `accepted` BOOLEAN NOT NULL DEFAULT FALSE
  -- Make sure that at most one of the value columns is filled.
  , CONSTRAINT `one_entry_for_value_only` CHECK(  -- YUCK YUCK YUCK
      -- No entry in any of the value columns is allowed.
      (`decimal_value` IS NULL AND `text_value` IS NULL AND `boolean_value` IS NULL AND `datetime_value` IS NULL)
      OR
      (`decimal_value` IS NOT NULL AND `text_value` IS NULL AND `boolean_value` IS NULL AND `datetime_value` IS NULL)
      OR
      (`decimal_value` IS NULL AND `text_value` IS NOT NULL AND `boolean_value` IS NULL AND `datetime_value` IS NULL)
      OR
      (`decimal_value` IS NULL AND `text_value` IS NULL AND `boolean_value` IS NOT NULL AND `datetime_value` IS NULL)
      OR
      (`decimal_value` IS NULL AND `text_value` IS NULL AND `boolean_value` IS NULL AND `datetime_value` IS NOT NULL)
    )
  -- Make sure that a collection can hold each value only one time.
  , CONSTRAINT `id_collection_id_j_variable_unqiue` UNIQUE(
      `id_collection`, `id_j_action_variable`, `repetition`
    )
  	-- Recycle bin.
  , `vis` BOOLEAN NOT NULL DEFAULT TRUE      
);



/* Just as two variables can belong together, their values can do so too. */
CREATE OR REPLACE TABLE `j_value_value`
(
    `id_j_value_value` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `id_value1` INTEGER NOT NULL REFERENCES `value` (`id_value`)
  , `id_value2` INTEGER NOT NULL REFERENCES `value` (`id_value`)
);




/* Raw values come directly from entry or an entry or an import file. */
/* The second heart of lucent are values that are attributed to specific variables.
Most prominently measurement results. But it can be a lot of things, like a confirmation
that a sample has been disposed of.
Also many different data types for the value itself are possbible. Decimal for measurement
results, booleans for a status, text for a description, an rgb value, and so on. */
CREATE OR REPLACE TABLE `raw_value`
(
    `id_raw_value` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
    -- A value can always be traced back to one or more raw values.
  , `id_value` INTEGER REFERENCES `value` (`id_value`)
    -- When was this raw value generated?
  , `t` DATETIME NOT NULL
    -- Who generated the value?
  , `id_person` INTEGER REFERENCES `person` (`id_person`)
    -- On which device was the value generated on?
  , `id_device` INTEGER REFERENCES `device` (`id_device`)

    -- Actual value.
  , `decimal_raw_value` DECIMAL
  , `text_raw_value` VARCHAR(50)
  , `boolean_raw_value` BOOLEAN
  , `datetime_raw_value` DATETIME

    -- As soon as all the raw values assigned to a final value are set to true OR false
    -- the front end should trigger a calculation.
  , `accepted` BOOLEAN

    -- Make sure that at most one of the value columns is filled.
  , CONSTRAINT `one_entry_for_value_only` CHECK(  -- YUCK YUCK YUCK
      -- No entry in any of the value columns is allowed.
      (`decimal_raw_value` IS NULL AND `text_raw_value` IS NULL AND `boolean_raw_value` IS NULL AND `datetime_raw_value` IS NULL)
      OR
      (`decimal_raw_value` IS NOT NULL AND `text_raw_value` IS NULL AND `boolean_raw_value` IS NULL AND `datetime_raw_value` IS NULL)
      OR
      (`decimal_raw_value` IS NULL AND `text_raw_value` IS NOT NULL AND `boolean_raw_value` IS NULL AND `datetime_raw_value` IS NULL)
      OR
      (`decimal_raw_value` IS NULL AND `text_raw_value` IS NULL AND `boolean_raw_value` IS NOT NULL AND `datetime_raw_value` IS NULL)
      OR
      (`decimal_raw_value` IS NULL AND `text_raw_value` IS NULL AND `boolean_raw_value` IS NULL AND `datetime_raw_value` IS NOT NULL)
    )
  	-- Recycle bin.
  , `vis` BOOLEAN NOT NULL DEFAULT TRUE
);
