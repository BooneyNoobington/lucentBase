/* A basic method to assign a task / to-do regarding an arbitrary record. */

CREATE OR REPLACE TABLE task
(
    id_task         INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    request         VARCHAR(50)     NOT NULL,
    description     VARCHAR(250),
    id_assigner     INTEGER         NOT NULL,
    id_assignee     INTEGER         NOT NULL,
    deadline        DATETIME,
    vis             BOOLEAN         NOT NULL DEFAULT TRUE,

    FOREIGN KEY (id_assigner) REFERENCES person (id_person),
    FOREIGN KEY (id_assignee) REFERENCES person (id_person)
);


/* A simple internal messaging system.
   Only actual users can send messages since recipients need to log in to read them. */

CREATE OR REPLACE TABLE message
(
    id_message      INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    id_sender       INTEGER         NOT NULL,
    id_receiver     INTEGER         NOT NULL,
    subject         VARCHAR(250)    NOT NULL,
    message         VARCHAR(500)    NOT NULL,
    new             BOOLEAN         NOT NULL DEFAULT TRUE,
    vis             BOOLEAN         NOT NULL DEFAULT TRUE,

    FOREIGN KEY (id_sender)   REFERENCES person (id_person),
    FOREIGN KEY (id_receiver) REFERENCES person (id_person)
);
