/* Generate database, user, and tables for lucentLIMS.
   This script needs to be run as root.
   Warning! This script is designed for the initial creation.
   It will overwrite all existing databases with the name "lucent". */


/* Drop any old lucent database before creating a new one.
   WARNING: This script is for (re)installation of a lucent instance.
   All data will be lost with or without dropping the old database first! */

DROP DATABASE IF EXISTS lucent;


/* Initial database generation. */

CREATE OR REPLACE DATABASE lucent
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_general_ci;


/* Initial user generation. */

CREATE OR REPLACE USER {linux_user}@'localhost' IDENTIFIED VIA unix_socket;

GRANT USAGE ON lucent.*
    TO {linux_user}@'localhost'
    IDENTIFIED VIA unix_socket;

GRANT ALL PRIVILEGES ON lucent.*
    TO {linux_user}@'localhost'
    IDENTIFIED VIA unix_socket;

FLUSH PRIVILEGES;


/* Use the lucent database for all subsequent operations. */

USE lucent;


/* Source all component files in dependency order. */

SOURCE SCIENTIFIC.SQL;

SOURCE SPATIAL.SQL;

SOURCE PEOPLE_AND_ORGANIZATIONS.SQL;

SOURCE MISCELLANEOUS.SQL;

SOURCE CLASSES.SQL;

SOURCE DEVICES.SQL;

SOURCE ACTIONS.SQL;

SOURCE COLLECTIONS.SQL;

SOURCE PARAMETERS_VALUES_RESULTS.SQL;

SOURCE VIEWS.SQL;

SOURCE INITIAL_DATA.SQL;

SOURCE LOGTABLES_AND_TRIGGERS.SQL;

CALL create_all_log_tables();
