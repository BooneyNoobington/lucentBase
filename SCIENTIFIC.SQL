/* Units of measurements base on dimensions. Like mass, length or time. */
CREATE OR REPLACE TABLE `dimension`
(
    `id_dimension` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `name` VARCHAR(40) NOT NULL UNIQUE
  , `description` VARCHAR(50)
    -- Recycle bin.
  , `vis` BOOLEAN NOT NULL DEFAULT TRUE
);



/* A sattelite table logging information about changes to
the records in `dimension`. */
CREATE OR REPLACE TABLE `l_dimension`
(
    `id_l_dimension` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
    -- Relate an entry to a record in the main table.
  , `id_dimension` INTEGER REFERENCES `dimension` (`id_dimension`)
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



/* Pretty self explainatory. A measured result consists of its result,
a unit as well as an uncertainty. */
CREATE OR REPLACE TABLE `unit`
(
    `id_unit` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `name` VARCHAR(40) NOT NULL UNIQUE
  , `description` VARCHAR(50)
    -- Foreign key: dimension.
  , `id_dimension` INTEGER REFERENCES `dimension` (`id_dimension`)
    -- Recycle bin.
  , `vis` BOOLEAN NOT NULL DEFAULT TRUE  
);



/* A sattelite table logging information about changes to
the records in `unit`. */
CREATE OR REPLACE TABLE `l_unit`
(
    `id_l_unit` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
    -- Relate an entry to a record in the main table.
  , `id_unit` INTEGER REFERENCES `unit` (`id_unit`)
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



/* Some write "milligram per liter" as "mg/l" others as "mg/L" others with whitespaces.
This table contains all possible notations. */
CREATE OR REPLACE TABLE `unit_notation`
(
    `id_unit_notation` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  -- Reference a specific unit.
  , `id_unit` INTEGER NOT NULL REFERENCES `unit` (`id_unit`)
  -- Actual notation. Like "mg/L", "mg / L", "mg/l" and so on.
  , `notation` VARCHAR(40) UNIQUE
    -- Recycle bin.
  , `vis` BOOLEAN NOT NULL DEFAULT TRUE  
);



/* A sattelite table logging information about changes to
the records in `unit_notation`. */
CREATE OR REPLACE TABLE `l_unit_notation`
(
    `id_l_unit_notation` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
    -- Relate an entry to a record in the main table.
  , `id_unit_notation` INTEGER REFERENCES `unit_notation` (`id_unit_notation`)
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



/* Pi, the Avogadro number, molecular masses … */
CREATE OR REPLACE TABLE `constant`
(
    `id_constant` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `name` VARCHAR(40) UNIQUE NOT NULL
  , `value` DECIMAL NOT NULL  -- 6.02214086 × 10^23 1/mol for the Avogadro number.
  , `id_unit` INTEGER NOT NULL REFERENCES `unit` (`id_unit`)
    -- Recycle bin.
  , `vis` BOOLEAN NOT NULL DEFAULT TRUE  
);



/* A sattelite table logging information about changes to
the records in `constant`. */
CREATE OR REPLACE TABLE `l_constant`
(
    `id_l_constant` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
    -- Relate an entry to a record in the main table.
  , `id_constant` INTEGER REFERENCES `constant` (`id_constant`)
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