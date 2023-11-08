/*
These tables describe all kinds of devices. These can be measurement instruments
like a pH probe or something mundane like a sample flask.
*/

/* An action often reqiures devices to be executed. Such as measurement gear. */
CREATE OR REPLACE TABLE `device`
(
    `id_device` INTEGER PRIMARY KEY UNIQUE NOT NULL
  , `name` VARCHAR(50) NOT NULL
  -- A lab may have an array of pH probes, etc.. They might be called the same but have a
  -- different number.
  , `number` INTEGER NOT NULL
  , `id_manufacturer` INTEGER REFERENCES `organization` (`id_organization`)  -- Manufacturer.
  , `id_operator` INTEGER REFERENCES `organization` (`id_organization`)  -- Who uses it?
  -- Workers can lock a device if it should not be used for some reason.
  -- Toggling the active state should create a log entry.
  , `active` BOOLEAN NOT NULL DEFAULT TRUE
  , CONSTRAINT `name_and_number_unqiue` UNIQUE(`name`, `number`)
    -- Recycle bin.
  , `vis` BOOLEAN NOT NULL DEFAULT TRUE
);



/* A sattelite table logging information about changes to
the records in `device`. */
CREATE OR REPLACE TABLE `l_device`
(
    `id_l_device` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
    -- Relate an entry to a record in the main table.
  , `id_device` INTEGER REFERENCES `device` (`id_device`)
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