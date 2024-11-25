/* Generate database, user and tables for lucentLIMS
This script needs to be run as root.
Warning! This script is designed for the initial creation.
It will overwrite all existing databases with the name "lucent". */



/* Drop any old lucent database before creating a new one
WARNING: This script is for (re)installation of a lucent instance
All data will be lost with or without dropping the old datbase first! */
DROP DATABASE IF EXISTS lucent;



/* Initial database generation. */
-- COLLATE is what the Arch Wiki suggests for Databases on Linux systems
CREATE OR REPLACE DATABASE lucent CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
/* Inital user generation. */
-- TODO: Check wether this is safe to do. Usually the socket is read-writable for everyone
CREATE OR REPLACE USER $linux_user@'localhost' IDENTIFIED VIA unix_socket;
-- Only neccessary if SQL_MODE does not have NO_AUTO_CREATE_USER set
-- The table "lucent" can be used by the user of the same name
GRANT USAGE ON lucent.* TO $linux_user@'localhost' IDENTIFIED VIA unix_socket;
-- Allow all actions on this databnase to user "lucent".
GRANT ALL PRIVILEGES ON lucent.* TO $linux_user@'localhost' IDENTIFIED VIA unix_socket;
-- Update the RDBMS to the recent access permissions
FLUSH PRIVILEGES;

/* Databases */
USE lucent;  -- Only database to be used


-- Scientific information like units and constants
SOURCE SCIENTIFIC.SQL

-- Spatial Information: Cities, sampling sites, addresses
SOURCE SPATIAL.SQL;

-- Clients, employees, manufacturers, …
SOURCE PEOPLE_AND_ORGANIZATIONS.SQL;

-- Miscellaneous information.
SOURCE MISCELLANEOUS.SQL;

-- Sample types, matrizes, etc..
SOURCE CLASSES.SQL

-- Information about measurement instruments, flasks, and so on
-- Everything one needs to complete a specific action
SOURCE DEVICES.SQL

-- Getting to the jist of it now. One of two hearts of lucent. The actions
SOURCE ACTIONS.SQL;

-- Second heart of lucent. Collections.
SOURCE COLLECTIONS.SQL

-- actions and belonging in their respective colletions
SOURCE PARAMETERS_VALUES_RESULTS.SQL

-- Views
SOURCE VIEWS.SQL

-- Inital records
SOURCE INITIAL_DATA.SQL

-- Procedure for creating logtables as well as update and insert triggers
SOURCE LOGTABLES_AND_TRIGGERS.SQL
CALL create_all_log_tables();
