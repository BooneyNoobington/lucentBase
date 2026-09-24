/* Devices, links to documents, and storage locations. */


/* Anything with an inventory number that is used to take, prepare or measure
   samples: a pH meter, an ion chromatograph, an autosampler, a soil auger.
   In OMS terms a device can act as Sampler or as Observer. */

CREATE TABLE device
(
    id_device           INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    name                VARCHAR(100)    NOT NULL,
    inventory_number    VARCHAR(40)     NOT NULL UNIQUE,
    serial_number       VARCHAR(80),
    id_manufacturer     INTEGER,
    retired_at          TIMESTAMP       NULL,

    FOREIGN KEY (id_manufacturer) REFERENCES organization (id_organization)
);


/* A link to a document that lives elsewhere: a standard operating procedure
   in paperless-ngx, a raw data file on a share, a PDF report in Nextcloud.
   lucentLIMS keeps no documents itself. The optional SHA-256 checksum proves
   later that the file is still the one that was linked. */

CREATE TABLE link
(
    id_link         INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    name            VARCHAR(150)    NOT NULL,
    uri             VARCHAR(2000),
    file_path       VARCHAR(1000),
    sha256          CHAR(64),

    CONSTRAINT link_has_target CHECK(
        uri IS NOT NULL OR file_path IS NOT NULL
    ),
    CONSTRAINT link_sha256_format CHECK(
        sha256 REGEXP '^[0-9a-f]{64}$'
    )
);


/* A place where material samples are kept: "fridge 2, shelf B". */

CREATE TABLE storage_location
(
    id_storage_location     INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    name                    VARCHAR(80)     NOT NULL UNIQUE,
    description             VARCHAR(250)
);
