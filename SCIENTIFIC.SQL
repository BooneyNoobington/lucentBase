/* Units of measurements base on dimensions. Like mass, length or time. */
CREATE OR REPLACE TABLE `dimension`
(
    `id_dimension` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `name` VARCHAR(40) NOT NULL UNIQUE
  , `description` VARCHAR(50)
    -- Recycle bin.
  , `vis` BOOLEAN NOT NULL DEFAULT TRUE
);



/* Pretty self explainatory. A measured result consists of its result,
a unit as well as an uncertainty. */
CREATE OR REPLACE TABLE `unit`
(
    `id_unit` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `name` VARCHAR(40) NOT NULL UNIQUE
  , `description` VARCHAR(100)
    -- Foreign key: dimension.
  , `id_dimension` INTEGER REFERENCES `dimension` (`id_dimension`)
    -- Recycle bin.
  , `vis` BOOLEAN NOT NULL DEFAULT TRUE  
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