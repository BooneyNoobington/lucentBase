/* A very basic method to assign a task / to do regarding an arbitray record. */
-- TODO: Very similar with `event` in function and build up. Merge?
CREATE OR REPLACE TABLE `task`
(
    `id_task` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  -- Explains what is to be done.
  , `request` VARCHAR(50) NOT NULL
  -- Provide additional infomration that might be needed to complete the task.
  , `description` VARCHAR(250)
  -- Who gave the order to which person? The relation is 1 to 1 and not 1 to n.
  -- It should be clear who is responsible and who is in charge.
  , `id_assigner` INTEGER NOT NULL REFERENCES `person` (`id_person`)
  , `id_assignee` INTEGER NOT NULL REFERENCES `person` (`id_person`)
  -- When is the task due?
  , `deadline` DATETIME
    -- Recycle bin.
  , `vis` BOOLEAN NOT NULL DEFAULT TRUE
);



/* A sattelite table logging information about changes to
the records in `task`. */
CREATE OR REPLACE TABLE `l_task`
(
    `id_l_task` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
    -- Relate an entry to a record in the main table.
  , `id_task` INTEGER REFERENCES `task` (`id_task`)
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



/* Basically a little Mail client inside lucent.
In this configuration only actual users can send messages.
This is okay because how would you transfer a message to someone who couldn't
even log into to the system. */
CREATE OR REPLACE TABLE `message`
(
    `id_message` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `sender` VARCHAR(20) NOT NULL REFERENCES `person` (`unix_account`)
  , `reciever` VARCHAR(20) NOT NULL REFERENCES `person` (`unix_account`)
  , `subject` VARCHAR(250) NOT NULL
  , `message` VARCHAR(500) NOT NULL
  , `read` BOOLEAN NOT NULL DEFAULT 0
    -- Recycle bin.
  , `vis` BOOLEAN NOT NULL DEFAULT TRUE  
);



/* A sattelite table logging information about changes to
the records in `message`. */
CREATE OR REPLACE TABLE `l_message`
(
    `id_l_message` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
    -- Relate an entry to a record in the main table.
  , `id_message` INTEGER REFERENCES `message` (`id_message`)
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