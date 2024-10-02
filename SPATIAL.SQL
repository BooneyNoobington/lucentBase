/* Self explainatory. */
CREATE OR REPLACE TABLE `city`
(
    `id_city` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `name` VARCHAR(60) NOT NULL UNIQUE
    -- Recycle bin.
  , `vis` BOOLEAN NOT NULL DEFAULT TRUE
);

/* Many cities consist of various districts. */
CREATE OR REPLACE TABLE `district`
(
    `id_district` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `name` VARCHAR(60) NOT NULL UNIQUE
  , `id_city` INTEGER NOT NULL REFERENCES `city` (`id_city`)
    -- Why don't use id_district as field for zips? Actually there can be multiple disctricts
    -- with the same zip in some cities.
  , `zip` INTEGER NOT NULL
    -- Recycle bin.
  , `vis` BOOLEAN NOT NULL DEFAULT TRUE
);

/* Seld explainatory. */
CREATE OR REPLACE TABLE `street`
(
    `id_street` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `name` VARCHAR(100) NOT NULL
  , `id_district` INTEGER NOT NULL REFERENCES `district` (`id_district`)
	-- Make sure the same street name can only appear once
	-- per district.
  , CONSTRAINT `one_street_per_district` UNIQUE(`name`, `id_district`)
	-- Recycle bin.
  , `vis` BOOLEAN NOT NULL DEFAULT TRUE
);



/* A house (identified by its number) is situated in a specific street which
in turn is connected to a specific district and so on.*/
CREATE OR REPLACE TABLE `house`
(
    `id_house` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `name` VARCHAR(50)
  , `number` INTEGER NOT NULL
  , `number_addition` VARCHAR(5)
  , `id_street` INTEGER NOT NULL REFERENCES `street` (`id_street`)
    -- Make sure that the same house number cannot appear multiple times in the same street.
  , CONSTRAINT `house_number_addition_street` UNIQUE(
        `number`
      , `number_addition`
      , `id_street`
    )
    -- Recycle bin.
  , `vis` BOOLEAN NOT NULL DEFAULT TRUE
);



/* The address related tables can be cumbersome. The follwing view provides
a flatter table. */
CREATE OR REPLACE VIEW `v_address` AS
SELECT				      `house`.`id_house` AS "__house__id_house"
				          , `house`.`number` AS "__house__number"
                  , `house`.`number_addition` AS "__house__number_addition"
				          , `street`.`id_street` AS "__street__id_street"
				          , `street`.`name` AS "__street__name"
				          , `district`.`id_district` AS "__district__id_district"
                  , `district`.`name` AS "__district__name"
                  , `district`.`zip` AS "__district__zip"
                  , `city`.`id_city` AS "__city__id_city"
                  , `city`.`name` AS "__city__name"
FROM				        `house`
			      JOIN	  `street`
            ON		  `street`.`id_street` = `house`.`id_street`
            JOIN	  `district`
            ON		  `district`.`id_district` = `street`.`id_district`
            JOIN	  `city`
            ON		  `city`.`id_city` = `district`.`id_city`
;


/* Some information is geographical and has coordinates. So a coordinate reference
system is needed. */
CREATE OR REPLACE TABLE `crs`
(
    `id_crs` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `epsg` INTEGER NOT NULL
  , `name` VARCHAR(25) UNIQUE NOT NULL
  , `description` VARCHAR(150)
	-- Recycle bin.
  , `vis` BOOLEAN NOT NULL DEFAULT TRUE
);



/* This is the general place an investigation takes places. It could be anything
from a part of a beach to a crime scene. */
CREATE OR REPLACE TABLE `site`
(
    `id_site` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `name` VARCHAR(20) UNIQUE NOT NULL
    -- An address (house number) is one possibility to make clear, where the site is located.
  , `id_house` INTEGER REFERENCES `house` (`id_house`)
    -- A site can also be represented by a polygon.
  , `borders` POLYGON
  , `id_crs` INTEGER REFERENCES `crs` (`id_crs`)  -- Then a crs is needed for the coordinates.
    -- But just a description is fine too.
  , `description` VARCHAR(50)
    -- A site needs either an address, a polygon of coordinates surrounding it or just a description
  , CHECK(`id_house` IS NOT NULL OR `borders` IS NOT NULL OR `description` IS NOT NULL)
    -- TODO: When a polygon of coordinates is given, we also need a coordinate reference system.
  , `vis` BOOLEAN NOT NULL DEFAULT TRUE
);



/* The exact place where a investigation takes place is called a spot.
A site can have multiple spots.*/
CREATE OR REPLACE TABLE `spot`
(
    `id_spot` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `name` VARCHAR(50) UNIQUE NOT NULL
    -- A spot can be equipped with coordinates.
  , `x` DOUBLE
  , `y` DOUBLE
  , `z` DOUBLE
  , `z_class` VARCHAR(20)  -- TODO: Implement specific values, CHECK(`z` IN (''))
  , `z_id_unit` INTEGER REFERENCES `unit` (`id_unit`)
  , `id_crs` INTEGER REFERENCES `crs` (`id_crs`)
    -- Or just a description like "Hudson River Pier".
  , `description` VARCHAR(50)
    -- Link this spot to a specific site.
  , `id_site` INTEGER REFERENCES `site` (`id_site`)
    -- Make sure that at least a description or coordinates are provided.
  , CHECK (`description` IS NOT NULL OR (`x` IS NOT NULL AND `y` IS NOT NULL))
    -- Recycle bin,
  , `vis` BOOLEAN NOT NULL DEFAULT TRUE
);