/* A very basic method to assign a task / to do regarding an arbitray record. */
-- TODO: Very similar with event in function and build up. Merge?
CREATE OR REPLACE TABLE task
(
    id_task INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT,
    -- Explains what is to be done.
    request VARCHAR(50) NOT NULL,
    -- Provide additional infomration that might be needed to complete the task.
    description VARCHAR(250),
    -- Who gave the order to which person? The relation is 1 to 1 and not 1 to n.
    -- It should be clear who is responsible and who is in charge.
    id_assigner INTEGER NOT NULL REFERENCES person (id_person),
    id_assignee INTEGER NOT NULL REFERENCES person (id_person),
    -- When is the task due?
    deadline DATETIME,
    -- Recycle bin.
    vis BOOLEAN NOT NULL DEFAULT TRUE
);



/* Basically a little Mail client inside lucent.
In this configuration only actual users can send messages.
This is okay because how would you transfer a message to someone who couldn't
even log into to the system. */
CREATE OR REPLACE TABLE message
(
    id_message INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT,
    sender VARCHAR(20) NOT NULL REFERENCES person (linux_user),
    reciever VARCHAR(20) NOT NULL REFERENCES person (linux_user),
    subject VARCHAR(250) NOT NULL,
    message VARCHAR(500) NOT NULL,
    new BOOLEAN NOT NULL DEFAULT TRUE,
    -- Recycle bin.
    vis BOOLEAN NOT NULL DEFAULT TRUE  
);