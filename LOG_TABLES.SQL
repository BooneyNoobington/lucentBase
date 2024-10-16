/* A sattelite table logging information about changes to
the records in `link`. */
CREATE OR REPLACE TABLE `l_link`
(
    `id_l_link` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `id_link` INTEGER REFERENCES `link` (`id_link`)
  , `change` VARCHAR(50) NOT NULL
  , `t` DATETIME NOT NULL
  , `id_editor` INTEGER REFERENCES `person` (`id_person`)
  , `note` VARCHAR(500)
  , `checksum` VARCHAR(100) NOT NULL
);


/* A sattelite table logging information about changes to
the records in `j_sop_link`. */
CREATE OR REPLACE TABLE `l_j_action_link`
(
    `id_l_j_action_link` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `id_j_acion_link` INTEGER REFERENCES `j_action_link` (`id_j_action_link`)
  , `change` VARCHAR(50) NOT NULL
  , `t` DATETIME NOT NULL
  , `id_editor` INTEGER REFERENCES `person` (`id_person`)
  , `note` VARCHAR(500)
  , `checksum` VARCHAR(100) NOT NULL
);

/* A sattelite table logging information about changes to
the records in `action`. */
CREATE OR REPLACE TABLE `l_action`
(
    `id_l_action` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `id_action` INTEGER REFERENCES `action` (`id_action`)
  , `change` VARCHAR(50) NOT NULL
  , `t` DATETIME NOT NULL
  , `id_editor` INTEGER REFERENCES `person` (`id_person`)
  , `note` VARCHAR(500)
  , `checksum` VARCHAR(100) NOT NULL
);

/* A sattelite table logging information about changes to
the records in `j_action_dependency`. */
CREATE OR REPLACE TABLE `l_j_action_dependency`
(
    `id_l_j_action_dependency` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `id_j_action_dependency` INTEGER REFERENCES `j_action_dependency` (`id_j_action_dependency`)
  , `change` VARCHAR(50) NOT NULL
  , `t` DATETIME NOT NULL
  , `id_editor` INTEGER REFERENCES `person` (`id_person`)
  , `note` VARCHAR(500)
  , `checksum` VARCHAR(100) NOT NULL
);

/* A sattelite table logging information about changes to
the records in `j_action_implication`. */
CREATE OR REPLACE TABLE `l_j_action_implication`
(
    `id_l_j_action_implication` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `id_j_action_implication` INTEGER REFERENCES `j_action_implication` (`id_j_action_implication`)
  , `change` VARCHAR(50) NOT NULL
  , `t` DATETIME NOT NULL
  , `id_editor` INTEGER REFERENCES `person` (`id_person`)
  , `note` VARCHAR(500)
  , `checksum` VARCHAR(100) NOT NULL
);

/* A sattelite table logging information about changes to
the records in `j_action_person`. */
CREATE OR REPLACE TABLE `l_j_action_person`
(
    `id_l_j_action_person` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `id_j_action_person` INTEGER REFERENCES `j_action_person` (`id_j_action_person`)
  , `change` VARCHAR(50) NOT NULL
  , `t` DATETIME NOT NULL
  , `id_editor` INTEGER REFERENCES `person` (`id_person`)
  , `note` VARCHAR(500)
  , `checksum` VARCHAR(100) NOT NULL
);

/* A sattelite table logging information about changes to
the records in `j_action_device`. */
CREATE OR REPLACE TABLE `l_j_action_device`
(
    `id_l_j_action_device` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `id_j_action_device` INTEGER REFERENCES `j_action_device` (`id_j_action_device`)
  , `change` VARCHAR(50) NOT NULL
  , `t` DATETIME NOT NULL
  , `id_editor` INTEGER REFERENCES `person` (`id_person`)
  , `note` VARCHAR(500)
  , `checksum` VARCHAR(100) NOT NULL
);

/* A sattelite table logging information about changes to
the records in `matrix`. */
CREATE OR REPLACE TABLE `l_matrix`
(
    `id_l_matrix` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `id_matrix` INTEGER REFERENCES `matrix` (`id_matrix`)
  , `change` VARCHAR(50) NOT NULL
  , `t` DATETIME NOT NULL
  , `id_editor` INTEGER REFERENCES `person` (`id_person`)
  , `note` VARCHAR(500)
  , `checksum` VARCHAR(100) NOT NULL
);


/* A sattelite table logging information about changes to
the records in `collection`. */
CREATE OR REPLACE TABLE `l_collection`
(
    `id_l_collection` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `id_collection` INTEGER REFERENCES `collection` (`id_collection`)
  , `change` VARCHAR(50) NOT NULL
  , `t` DATETIME NOT NULL
  , `id_editor` INTEGER REFERENCES `person` (`id_person`)
  , `note` VARCHAR(500)
  , `checksum` VARCHAR(100) NOT NULL
);

/* A sattelite table logging information about changes to
the records in `device`. */
CREATE OR REPLACE TABLE `l_device`
(
    `id_l_device` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `id_device` INTEGER REFERENCES `device` (`id_device`)
  , `change` VARCHAR(50) NOT NULL
  , `t` DATETIME NOT NULL
  , `id_editor` INTEGER REFERENCES `person` (`id_person`)
  , `note` VARCHAR(500)
  , `checksum` VARCHAR(100) NOT NULL
);

/* A sattelite table logging information about changes to
the records in `task`. */
CREATE OR REPLACE TABLE `l_task`
(
    `id_l_task` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `id_task` INTEGER REFERENCES `task` (`id_task`)
  , `change` VARCHAR(50) NOT NULL
  , `t` DATETIME NOT NULL
  , `id_editor` INTEGER REFERENCES `person` (`id_person`)
  , `note` VARCHAR(500)
  , `checksum` VARCHAR(100) NOT NULL
);

/* A sattelite table logging information about changes to
the records in `message`. */
CREATE OR REPLACE TABLE `l_message`
(
    `id_l_message` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `id_message` INTEGER REFERENCES `message` (`id_message`)
  , `change` VARCHAR(50) NOT NULL
  , `t` DATETIME NOT NULL
  , `id_editor` INTEGER REFERENCES `person` (`id_person`)
  , `note` VARCHAR(500)
  , `checksum` VARCHAR(100) NOT NULL
);

/* A sattelite table logging information about changes to
the records in `organization`. */
CREATE OR REPLACE TABLE `l_organization`
(
    `id_l_organization` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `id_organization` INTEGER REFERENCES `organization` (`id_organization`)
  , `change` VARCHAR(50) NOT NULL
  , `t` DATETIME NOT NULL
  , `id_editor` INTEGER REFERENCES `person` (`id_person`)
  , `note` VARCHAR(500)
  , `checksum` VARCHAR(100) NOT NULL
);

/* A sattelite table logging information about changes to
the records in `person`. */
CREATE OR REPLACE TABLE `l_person`
(
    `id_l_person` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `id_person` INTEGER REFERENCES `person` (`id_person`)
  , `change` VARCHAR(50) NOT NULL
  , `t` DATETIME NOT NULL
  , `id_editor` INTEGER REFERENCES `person` (`id_person`)
  , `note` VARCHAR(500)
  , `checksum` VARCHAR(100) NOT NULL
);

/* A sattelite table logging information about changes to
the records in `j_person_house`. */
CREATE OR REPLACE TABLE `l_j_person_house`
(
    `id_l_j_person_house` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `id_j_person_house` INTEGER REFERENCES `j_person_house` (`id_j_person_house`)
  , `change` VARCHAR(50) NOT NULL
  , `t` DATETIME NOT NULL
  , `id_editor` INTEGER REFERENCES `person` (`id_person`)
  , `note` VARCHAR(500)
  , `checksum` VARCHAR(100) NOT NULL
);

/* A sattelite table logging information about changes to
the records in `j_organization_house`. */
CREATE OR REPLACE TABLE `l_j_organization_house`
(
    `id_l_j_organization_house` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `id_j_organization_house` INTEGER REFERENCES `j_organization_house` (`id_j_organization_house`)
  , `change` VARCHAR(50) NOT NULL
  , `t` DATETIME NOT NULL
  , `id_editor` INTEGER REFERENCES `person` (`id_person`)
  , `note` VARCHAR(500)
  , `checksum` VARCHAR(100) NOT NULL
);

/* A sattelite table logging information about changes to
the records in `j_person_organization`. */
CREATE OR REPLACE TABLE `l_j_person_organization`
(
    `id_l_j_person_organization` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `id_j_person_organization` INTEGER REFERENCES `j_person_organization` (`id_j_person_organization`)
  , `change` VARCHAR(50) NOT NULL
  , `t` DATETIME NOT NULL
  , `id_editor` INTEGER REFERENCES `person` (`id_person`)
  , `note` VARCHAR(500)
  , `checksum` VARCHAR(100) NOT NULL
);

/* A sattelite table logging information about changes to
the records in `dimension`. */
CREATE OR REPLACE TABLE `l_dimension`
(
    `id_l_dimension` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `id_dimension` INTEGER REFERENCES `dimension` (`id_dimension`)
  , `change` VARCHAR(50) NOT NULL
  , `t` DATETIME NOT NULL
  , `id_editor` INTEGER REFERENCES `person` (`id_person`)
  , `note` VARCHAR(500)
  , `checksum` VARCHAR(100) NOT NULL
);

/* A sattelite table logging information about changes to
the records in `unit`. */
CREATE OR REPLACE TABLE `l_unit`
(
    `id_l_unit` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `id_unit` INTEGER REFERENCES `unit` (`id_unit`)
  , `change` VARCHAR(50) NOT NULL
  , `t` DATETIME NOT NULL
  , `id_editor` INTEGER REFERENCES `person` (`id_person`)
  , `note` VARCHAR(500)
  , `checksum` VARCHAR(100) NOT NULL
);

/* A sattelite table logging information about changes to
the records in `unit_notation`. */
CREATE OR REPLACE TABLE `l_unit_notation`
(
    `id_l_unit_notation` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `id_unit_notation` INTEGER REFERENCES `unit_notation` (`id_unit_notation`)
  , `change` VARCHAR(50) NOT NULL
  , `t` DATETIME NOT NULL
  , `id_editor` INTEGER REFERENCES `person` (`id_person`)
  , `note` VARCHAR(500)
  , `checksum` VARCHAR(100) NOT NULL
);

/* A sattelite table logging information about changes to
the records in `constant`. */
CREATE OR REPLACE TABLE `l_constant`
(
    `id_l_constant` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `id_constant` INTEGER REFERENCES `constant` (`id_constant`)
  , `change` VARCHAR(50) NOT NULL
  , `t` DATETIME NOT NULL
  , `id_editor` INTEGER REFERENCES `person` (`id_person`)
  , `note` VARCHAR(500)
  , `checksum` VARCHAR(100) NOT NULL
);

/* A sattelite table logging information about changes to
the records in `city`. */
CREATE OR REPLACE TABLE `l_city`
(
    `id_l_city` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `id_city` INTEGER REFERENCES `city` (`id_city`)
  , `change` VARCHAR(50) NOT NULL
  , `t` DATETIME NOT NULL
  , `id_editor` INTEGER REFERENCES `person` (`id_person`)
  , `note` VARCHAR(500)
  , `checksum` VARCHAR(100) NOT NULL
);

/* A sattelite table logging information about changes to
the records in `district`. */
CREATE OR REPLACE TABLE `l_district`
(
    `id_l_district` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `id_district` INTEGER REFERENCES `district` (`id_district`)
  , `change` VARCHAR(50) NOT NULL
  , `t` DATETIME NOT NULL
  , `id_editor` INTEGER REFERENCES `person` (`id_person`)
  , `note` VARCHAR(500)
  , `checksum` VARCHAR(100) NOT NULL
);

/* A sattelite table logging information about changes to
the records in `street`. */
CREATE OR REPLACE TABLE `l_street`
(
    `id_l_street` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `id_street` INTEGER REFERENCES `street` (`id_street`)
  , `change` VARCHAR(50) NOT NULL
  , `t` DATETIME NOT NULL
  , `id_editor` INTEGER REFERENCES `person` (`id_person`)
  , `note` VARCHAR(500)
  , `checksum` VARCHAR(100) NOT NULL
);

/* A sattelite table logging information about changes to
the records in `house`. */
CREATE OR REPLACE TABLE `l_house`
(
    `id_l_house` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `id_house` INTEGER REFERENCES `house` (`id_house`)
  , `change` VARCHAR(50) NOT NULL
  , `t` DATETIME NOT NULL
  , `id_editor` INTEGER REFERENCES `person` (`id_person`)
  , `note` VARCHAR(500)
  , `checksum` VARCHAR(100) NOT NULL
);

/* A sattelite table logging information about changes to
the records in `crs`. */
CREATE OR REPLACE TABLE `l_crs`
(
    `id_l_crs` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `id_crs` INTEGER REFERENCES `crs` (`id_crs`)
  , `change` VARCHAR(50) NOT NULL
  , `t` DATETIME NOT NULL
  , `id_editor` INTEGER REFERENCES `person` (`id_person`)
  , `note` VARCHAR(500)
  , `checksum` VARCHAR(100) NOT NULL
);

/* A sattelite table logging information about changes to
the records in `site`. */
CREATE OR REPLACE TABLE `l_site`
(
    `id_l_site` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `id_site` INTEGER REFERENCES `site` (`id_site`)
  , `change` VARCHAR(50) NOT NULL
  , `t` DATETIME NOT NULL
  , `id_editor` INTEGER REFERENCES `person` (`id_person`)
  , `note` VARCHAR(500)
  , `checksum` VARCHAR(100) NOT NULL
);

/* A sattelite table logging information about changes to
the records in `spot`. */
CREATE OR REPLACE TABLE `l_spot`
(
    `id_l_spot` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `id_spot` INTEGER REFERENCES `spot` (`id_spot`)
  , `change` VARCHAR(50) NOT NULL
  , `t` DATETIME NOT NULL
  , `id_editor` INTEGER REFERENCES `person` (`id_person`)
  , `note` VARCHAR(500)
  , `checksum` VARCHAR(100) NOT NULL
);

/* A sattelite table logging information about changes to
the records in `variable`. */
CREATE OR REPLACE TABLE `l_variable`
(
    `id_l_variable` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `id_variable` INTEGER REFERENCES `variable` (`id_variable`)
  , `change` VARCHAR(50) NOT NULL
  , `t` DATETIME NOT NULL
  , `id_editor` INTEGER REFERENCES `person` (`id_person`)
  , `note` VARCHAR(500)
  , `checksum` VARCHAR(100) NOT NULL
);

/* A sattelite table logging information about changes to
the records in `j_variable_variable`. */
CREATE OR REPLACE TABLE `l_j_variable_variable`
(
    `id_l_j_variable_variable` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `id_j_variable_variable` INTEGER REFERENCES `j_variable_variable` (`id_j_variable_variable`)
  , `change` VARCHAR(50) NOT NULL
  , `t` DATETIME NOT NULL
  , `id_editor` INTEGER REFERENCES `person` (`id_person`)
  , `note` VARCHAR(500)
  , `checksum` VARCHAR(100) NOT NULL
);

/* A sattelite table logging information about changes to
the records in `j_action_variable`. */
CREATE OR REPLACE TABLE `l_j_action_variable`
(
    `id_l_j_action_variable` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `id_j_action_variable` INTEGER REFERENCES `j_action_variable` (`id_j_action_variable`)
  , `change` VARCHAR(50) NOT NULL
  , `t` DATETIME NOT NULL
  , `id_editor` INTEGER REFERENCES `person` (`id_person`)
  , `note` VARCHAR(500)
  , `checksum` VARCHAR(100) NOT NULL
);

/* A sattelite table logging information about changes to
the records in `value`. */
CREATE OR REPLACE TABLE `l_j_collection_value`
(
    `id_l_j_collection_value` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `id_j_collection_value` INTEGER REFERENCES `j_collection_value` (`id_j_collection_value`)
  , `change` VARCHAR(50) NOT NULL
  , `t` DATETIME NOT NULL
  , `id_editor` INTEGER REFERENCES `person` (`id_person`)
  , `note` VARCHAR(500)
  , `checksum` VARCHAR(100) NOT NULL
);

/* A sattelite table logging information about changes to
the records in `j_value_value`. */
CREATE OR REPLACE TABLE `l_j_value_value`
(
    `id_l_j_value_value` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `id_j_value_value` INTEGER REFERENCES `j_value_value` (`id_j_value_value`)
  , `change` VARCHAR(50) NOT NULL
  , `t` DATETIME NOT NULL
  , `id_editor` INTEGER REFERENCES `person` (`id_person`)
  , `note` VARCHAR(500)
  , `checksum` VARCHAR(100) NOT NULL
);

/* A sattelite table logging information about changes to
the records in `raw_value`. */
CREATE OR REPLACE TABLE `l_raw_value`
(
    `id_l_raw_value` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `id_raw_value` INTEGER REFERENCES `raw_value` (`id_raw_value`)
  , `change` VARCHAR(50) NOT NULL
  , `t` DATETIME NOT NULL
  , `id_editor` INTEGER REFERENCES `person` (`id_person`)
  , `note` VARCHAR(500)
  , `checksum` VARCHAR(100) NOT NULL
);
