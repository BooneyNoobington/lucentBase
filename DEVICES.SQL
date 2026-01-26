/* These tables describe all kinds of devices. These can be measurement instruments
   like a pH probe, or something mundane like a sample flask. */


/* An action often requires devices to be executed, such as measurement gear. */

CREATE OR REPLACE TABLE device
(
    id_device           INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    name                VARCHAR(50)     NOT NULL,
    number              INTEGER         NOT NULL,
    id_manufacturer     INTEGER,
    id_operator         INTEGER,
    active              BOOLEAN         NOT NULL DEFAULT TRUE,
    vis                 BOOLEAN         NOT NULL DEFAULT TRUE,

    CONSTRAINT name_and_number_unique UNIQUE(name, number),

    FOREIGN KEY (id_manufacturer)   REFERENCES organization (id_organization),
    FOREIGN KEY (id_operator)       REFERENCES organization (id_organization)
);
