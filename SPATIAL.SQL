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


/* Some information is geographical and has coordinates. So a coordinate reference
system is needed. */
CREATE OR REPLACE TABLE `crs`
(
    `id_crs` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `epsg` INTEGER NOT NULL
  , `identifier` VARCHAR(25) UNIQUE NOT NULL
  , `description` VARCHAR(150)
);


/* This is the general place an investigation takes places. It could be anything
from a part of a beach to a crime scene. */
CREATE OR REPLACE TABLE `site`
(
    `id_site` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `identifier` VARCHAR(20) UNIQUE NOT NULL
  , `class` VARCHAR(30) NOT NULL
    -- An address is one possibility to make clear, where the site is located.
  , `id_address` INTEGER REFERENCES `address` (`id_address`)
    -- A site can be represented by a polygon.
  , `borders` POLYGON
  , `id_crs` INTEGER REFERENCES `crs` (`id_crs`)
    -- But a description is fine too.
  , `description` VARCHAR(50)
    -- A site needs either an address, a polygon of coordinates surrounding it or just a description
  , CHECK(`id_address` IS NOT NULL OR `borders` IS NOT NULL OR `description` IS NOT NULL)
    -- TODO: When a polygon of coordinates is given, we also need a coordinate reference system.
);


/* The exact place where a investigation takes place is called a spot.
A site can have multiple spots.*/
CREATE OR REPLACE TABLE `spot`
(
    `id_spot` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `identifier` VARCHAR(50) UNIQUE NOT NULL
    -- A spot can be equipped with coordinates.
  , `x` DOUBLE
  , `y` DOUBLE
  , `id_crs` INTEGER REFERENCES `crs` (`id_crs`)
    -- Or just a description like "Hudson River Pier".
  , `description` VARCHAR(50)
    -- Link this spot to a specific site.
  , `id_site` INTEGER REFERENCES `site` (`id_site`)
    -- Make sure that at least a description or coordinates are provided.
  , CHECK (`description` IS NOT NULL OR (`x` IS NOT NULL AND `y` IS NOT NULL))
);

/* Combine spots and the crs information into a view. */
CREATE OR REPLACE VIEW `v_spot_crs` AS
SELECT          s.`identifier` AS "Spot"
              , s.`description` AS "Description"
              , s.`x` AS "x Coordinate"
              , s.`y` AS "y Coordinate"
              , c.`identifier` AS "CRS"
              , c.`epsg` AS "EPSG"
FROM            `spot` s
        JOIN    `crs` c
        ON      c.`id_crs` = s.`id_crs`
;
