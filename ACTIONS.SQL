/* Many records may have actual files attached to them on a filesystem level,
   or a web page can hold relevant information. A "link" to these files and pages is found here. */

CREATE OR REPLACE TABLE link
(
    id_link     INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    name        VARCHAR(50)     NOT NULL UNIQUE,
    uri         VARCHAR(500),
    file_path   VARCHAR(500),
    accepted    BOOLEAN         NOT NULL DEFAULT FALSE,
    sha256      VARCHAR(64),
    vis         BOOLEAN         NOT NULL DEFAULT TRUE
);


/* One of two hearts of lucentLIMS. There are objects of interest (often called "samples")
   and something that happens with them: Actions. */

CREATE OR REPLACE TABLE action
(
    id_action       INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    name            VARCHAR(50)     NOT NULL,
    iteration       DATETIME        NOT NULL,
    active          BOOLEAN         NOT NULL,
    description     VARCHAR(250),
    vis             BOOLEAN         NOT NULL DEFAULT TRUE,

    CONSTRAINT action_name_iteration_unique UNIQUE(name, iteration)
);


/* Join between action and link. */

CREATE OR REPLACE TABLE j_action_link
(
    id_j_action_link    INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    id_action           INTEGER         NOT NULL,
    id_link             INTEGER         NOT NULL,
    vis                 BOOLEAN         NOT NULL DEFAULT TRUE,

    FOREIGN KEY (id_action) REFERENCES action (id_action),
    FOREIGN KEY (id_link)   REFERENCES link (id_link)
);


/* Actions depend on one another. This table organizes these dependencies. */

CREATE OR REPLACE TABLE j_action_action
(
    id_j_action_action  INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    id_action1          INTEGER         NOT NULL,
    id_action2          INTEGER         NOT NULL,
    dependency_class    VARCHAR(12)     NOT NULL DEFAULT 'strict',
    description         VARCHAR(100),
    vis                 BOOLEAN         NOT NULL DEFAULT TRUE,

    CONSTRAINT dependency_class_choices CHECK(
        dependency_class IN ('strict', 'possibility')
    ),
    CONSTRAINT id_action1_id_action2_unique UNIQUE(id_action1, id_action2),

    FOREIGN KEY (id_action1) REFERENCES action (id_action),
    FOREIGN KEY (id_action2) REFERENCES action (id_action)
);


/* Just like an SOP has a connection to people, actions have these too. */

CREATE OR REPLACE TABLE j_action_person
(
    id_j_action_person  INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    id_action           INTEGER         NOT NULL,
    id_person           INTEGER         NOT NULL,
    role                VARCHAR(40)     NOT NULL,
    vis                 BOOLEAN         NOT NULL DEFAULT TRUE,

    CONSTRAINT role_choices CHECK(
        role IN ('auditor', 'manager', 'worker')
    ),
    CONSTRAINT id_action_id_person_role_unique UNIQUE(id_action, id_person, role),

    FOREIGN KEY (id_action) REFERENCES action (id_action),
    FOREIGN KEY (id_person) REFERENCES person (id_person)
);


/* Connect actions and devices used to perform them. */

CREATE OR REPLACE TABLE j_action_device
(
    id_j_action_device  INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    id_action           INTEGER         NOT NULL,
    id_device           INTEGER         NOT NULL,
    vis                 BOOLEAN         NOT NULL DEFAULT TRUE,

    FOREIGN KEY (id_action) REFERENCES action (id_action),
    FOREIGN KEY (id_device) REFERENCES device (id_device)
);
