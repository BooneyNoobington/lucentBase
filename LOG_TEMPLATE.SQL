/* A sattelite table logging information about changes to
the records in `{table.chr}`. */
CREATE OR REPLACE TABLE `l_{table.chr}`
(
    `id_l_{table.chr}` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `id_{table.chr}` INTEGER REFERENCES `{table.chr}` (`id_{table.chr}`)
  , `change` VARCHAR(50) NOT NULL
  , `t` DATETIME NOT NULL
  , `id_editor` INTEGER REFERENCES `person` (`id_person`)
  , `note` VARCHAR(500)
  , `checksum` VARCHAR(100) NOT NULL
);