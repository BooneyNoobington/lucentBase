/* Self explainatory. */
CREATE OR REPLACE TABLE `city`
(
    `id_city` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `identifier` VARCHAR(60) NOT NULL UNIQUE
);

/* Many cities consist of various districts. */
CREATE OR REPLACE TABLE `district`
(
    `id_district` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `identifier` VARCHAR(60) NOT NULL UNIQUE
  , `id_city` INTEGER NOT NULL REFERENCES `city` (`id_city`)
  -- Why don't use id_district as field for zips? Actually there can be multiple disctricts
  -- with the same zip in some cities.
  , `zip` INTEGER NOT NULL
);

/* Seld explainatory. */
CREATE OR REPLACE TABLE `street`
(
    `id_street` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `identifier` VARCHAR(100) NOT NULL
  , `id_district` INTEGER NOT NULL REFERENCES `district` (`id_district`)
  -- Make sure the same street name (identifier) can only appear once
  -- per district.
  , CONSTRAINT `one_street_per_district` UNIQUE(`identifier`, `id_district`)
);

/* An address is a house (identified by its number) in a specific street which
in turn is connected to a specific district and so on.*/
CREATE OR REPLACE TABLE `address`
(
    `id_address` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `house_number` INTEGER NOT NULL
  , `house_number_addition` VARCHAR(5)
  , `id_street` INTEGER NOT NULL REFERENCES `street` (`id_street`)
    -- Make sure that the same house number cannot appear multiple times in the same street.
  , CONSTRAINT `house_number_addition_street` UNIQUE(
        `house_number`
      , `house_number_addition`
      , `id_street`
    )
);

/* This is the general place an investigation takes places. It could be anything
from a part of a beach to a crime scene. */
CREATE OR REPLACE TABLE `site`
(
    `id_site` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `identifier` VARCHAR(20) UNIQUE NOT NULL
  , `class` VARCHAR(30) NOT NULL
  -- TODO: This is a problem. You can enter an address that has nothing to do with
  -- the district you entered. Solution: Just allow an address.
  -- Other solution: Only the district or the address are to be given. Not both.
  , `id_district` INTEGER REFERENCES `district` (`id_district`)
  , `id_address` INTEGER REFERENCES `address` (`id_address`)
  , CHECK (
      (`id_district` IS NOT NULL AND `id_address` IS NULL)
      OR
      (`id_address` IS NOT NULL AND `id_district` IS NULL)
    )
);
