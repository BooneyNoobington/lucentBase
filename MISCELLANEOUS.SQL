/* Holds information about something that happend to a specific record. */
CREATE OR REPLACE TABLE `event`
(
    `id_event` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  , `identifier` VARCHAR(50) NOT NULL
  , `moment` DATETIME NOT NULL
  , `description` VARCHAR(250)  -- Not mandatory.
  -- Make sure that the same event doesn't happen twice at the same time.
  , CONSTRAINT `event_identifier_and_concerning_table_unique` UNIQUE (`identifier`, `moment`)
);



/* A very basic method to assign a task / to do regarding an arbitray record. */
-- TODO: Very similar with `event` in function and build up. Merge?
CREATE OR REPLACE TABLE `task`
(
    `id_task` INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
  -- Explains what is to be done.
  , `identifier` VARCHAR(50) NOT NULL
  -- Provide additional infomration that might be needed to complete the task.
  , `additional_info` VARCHAR(250)
  -- Who gave the order to what person? The relation is 1 to 1 and not 1 to n.
  -- It should be clear who is responsible and who is in charged.
  , `id_assigner` INTEGER NOT NULL REFERENCES `person` (`id_person`)
  , `id_assignee` INTEGER NOT NULL REFERENCES `person` (`id_person`)
  -- When is the task due?
  , `deadline` DATETIME
);



/* Basically a little Mail client inside lucent.
In this configuration only actual users can send messages.
This is okay because how would you transfer a message to someone who couldn't
even login to the system. */
CREATE OR REPLACE TABLE `message`
(
    `id_message` INTEGER PRIMARY KEY UNIQUE NOT NULL
  , `sender` VARCHAR(20) NOT NULL REFERENCES `person` (`unix_account`)
  , `reciever` VARCHAR(20) NOT NULL REFERENCES `person` (`unix_account`)
  , `subject` VARCHAR(250) NOT NULL
  , `message` VARCHAR(500) NOT NULL
  , `read_status` BOOLEAN NOT NULL DEFAULT 0
);
