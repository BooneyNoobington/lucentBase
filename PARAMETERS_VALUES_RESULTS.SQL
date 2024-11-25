/*
"parameters" and "values"
Part of the lucentLIMS project.
Copyright: GPLv3

LucentLIMS is supposed to store not only measurement effects but also other information that was
obtained during the lifecycle that lead to their quantification. Like the visual impression of a
sample or a confirmation that a sample ideed was filtrated.

The database entity that contains this infomration is the table value. Such a value is
ascocciated with a parameter which in turn is a ascocciated with an action(described in its
own SQL file).
*/



/* Instances of parameter will fill up the activity data. It can be many things
and is always a property of an action. Like a measurement effect but also some other
meta data like "was sample x filtrated"? */

CREATE OR REPLACE TABLE parameter
(
    id_parameter INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT,
    name VARCHAR(30) UNIQUE NOT NULL,
    -- A short description of this var. Mostly for the end user.
    description VARCHAR(80),
    id_unit INTEGER REFERENCES unit (id_unit),
  	-- Recycle bin.
    vis BOOLEAN NOT NULL DEFAULT TRUE    
);



/* Sometimes parameters can be corresponding with other parameters.
Like the liquids temperature with a pH-value. */
CREATE OR REPLACE TABLE j_parameter_parameter
(
	  id_j_parameter_parameter INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT,
    id_parameter1 INTEGER REFERENCES parameter (id_parameter),
    id_parameter2 INTEGER REFERENCES parameter (id_parameter),
    -- A short explaination why the two parameters are connected together
    description VARCHAR(50),
  	-- Recycle bin
    vis BOOLEAN NOT NULL DEFAULT TRUE  
);



/* Relate an action and a parameter. */
CREATE OR REPLACE TABLE effect
(
    id_effect INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT,
	  -- Which action contains which parameters?
    id_action INTEGER NOT NULL REFERENCES action (id_action),
    id_parameter INTEGER NOT NULL REFERENCES parameter (id_parameter),
    -- Make sure that the same action cannot hold the same parameter twice
    CONSTRAINT id_collection_id_parameter_unqiue UNIQUE(
      id_action, id_parameter
    ),
	  -- What uncertainty is to be expected?
    uncertainty DOUBLE,
	  -- Is this a relative or absolute value? (Percentage or actual value?)
    uncertainty_class VARCHAR(9),
	  -- In which unit is the uncertainty provided?
    uncertainty_id_unit INTEGER REFERENCES unit (id_unit),
	  -- How is the corresponding end effect calculated? Points to a (usually r) file
    calculation VARCHAR(40),
	  -- Recycle bin
    vis BOOLEAN NOT NULL DEFAULT TRUE  
);


/* Relate two effects. E.g. relative humidity makes sense in conjunction with
air temperature */
CREATE OR REPLACE TABLE j_effect_effect 



/* The second heart of lucent are values that are attributed to specific parameters.
Most prominently measurement effects. But it can be a lot of things, like a confirmation
that a sample has been disposed of.
Also many different data types for the value itself are possbible. Decimal for measurement
effects, booleans for a status, text for a description, an rgb value, and so on.

Most importantly, values are the link between a collection
and actions performed on them. */
CREATE OR REPLACE TABLE value
(
    id_value INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT,
    name VARCHAR(30),
    -- To which collection do these values belong to?
    -- This asosciation is created automatically when a group of actions is attached to a collection
    -- The corresponding parameters are stored here
    id_collection INTEGER NOT NULL REFERENCES collection (id_collection),
    -- What parameters are to be provided with values?
    -- From this reference we can derive the lifecycle, action and parameter
    id_effect INTEGER NOT NULL REFERENCES effect (id_effect),
    -- A value can be measured multiple times. Not to be confused with raw values
    -- that are repeatadly measured to increase precision
    -- More like repeated measurements for time series

    -- Make sure that a collection can hold each value only one time
    CONSTRAINT id_collection_id_j_parameter_unqiue UNIQUE(
      id_collection, id_effect
    ),
    -- For measurement effects, define calculation
    calculation VARCHAR(30) DEFAULT 'getMeanGeneric',
  	-- Recycle bin
    vis BOOLEAN NOT NULL DEFAULT TRUE      
);

/* As seen above, the link between collections and values don't hold any actual
measurement effects. These are provided by the respective raw values
as well as the effect table which describes how end effects are computed. */
CREATE OR REPLACE TABLE raw_value
(
    id_raw_value INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT,
    -- A value can always be traced back to one or more raw values.
    id_value INTEGER REFERENCES value (id_value),
    -- When was this raw value generated?
    -- TODO: Can be null when the value itself datetime_value is already
    -- a date time
    t DATETIME,
    -- Who generated the value?
    id_person INTEGER REFERENCES person (id_person),
    -- On which device was the value generated on?
    id_device INTEGER REFERENCES device (id_device),
    id_unit INTEGER REFERENCES unit (id_unit)  ,

    -- Actual value.
    decimal_raw_value DOUBLE,
    text_raw_value VARCHAR(50),
    boolean_raw_value BOOLEAN,
    datetime_raw_value DATETIME,

    -- As soon as all the raw values assigned to a final value are set to true OR false
    -- the front end should trigger a calculation
    accepted BOOLEAN DEFAULT FALSE,

    -- Make sure that at most one of the value columns is filled
    CONSTRAINT one_entry_for_value_only CHECK(  -- YUCK YUCK YUCK
        -- No entry in any of the value columns is allowed
        (decimal_raw_value IS NULL AND text_raw_value IS NULL AND boolean_raw_value IS NULL AND datetime_raw_value IS NULL)
        OR
        (decimal_raw_value IS NOT NULL AND text_raw_value IS NULL AND boolean_raw_value IS NULL AND datetime_raw_value IS NULL)
        OR
        (decimal_raw_value IS NULL AND text_raw_value IS NOT NULL AND boolean_raw_value IS NULL AND datetime_raw_value IS NULL)
        OR
        (decimal_raw_value IS NULL AND text_raw_value IS NULL AND boolean_raw_value IS NOT NULL AND datetime_raw_value IS NULL)
        OR
        (decimal_raw_value IS NULL AND text_raw_value IS NULL AND boolean_raw_value IS NULL AND datetime_raw_value IS NOT NULL)
    ),
    -- Make sure that a value cannot be connected to the same measurement time "t" multiple times
    CONSTRAINT one_value_per_t UNIQUE(id_value, t),
  	-- Recycle bin
    vis BOOLEAN NOT NULL DEFAULT TRUE
);
