/*
These tables describe all kinds of devices. These can be measurement instruments
like a pH probe or something mundane like a sample flask.
*/

/* An action often reqiures devices to be executed. Such as measurement gear. */
CREATE OR REPLACE TABLE `device`
(
    `id_device` INTEGER PRIMARY KEY UNIQUE NOT NULL
  , `identifier` VARCHAR(50) NOT NULL
  -- A lab may have an array of pH probes, etc.. They might be called the same but have a
  -- different number.
  , `number` INTEGER NOT NULL
  , `id_organisation` INTEGER REFERENCES `organisation` (`id_organisation`)  -- Manufacturer.
  -- Workers can lock a device if it should not be used for some reason.
  -- Toggling the active state should create an `event` every time
  , `active` BOOLEAN NOT NULL DEFAULT TRUE
  , CONSTRAINT name_and_number_unqiue UNIQUE(identifier, number)
);
