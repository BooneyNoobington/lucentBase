/* The second heart of lucent. A collection holds parameters (or values) that are
   obtained by performing a specific action. It is a specific instance of an object,
   like an actual soil sample from your backyard, left of the porch.
   Or something immaterial like radiation measured near a nuclear power plant. */

CREATE OR REPLACE TABLE collection
(
    id_collection       INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    name                VARCHAR(40)     UNIQUE,
    id_matrix           INTEGER         NOT NULL,
    collection_class    VARCHAR(50)     NOT NULL,
    id_spot             INTEGER,
    id_site             INTEGER,
    vis                 BOOLEAN         NOT NULL DEFAULT TRUE,

    CONSTRAINT spot_or_site CHECK(
        (id_spot IS NULL AND id_site IS NOT NULL)
        OR
        (id_spot IS NOT NULL AND id_site IS NULL)
    ),
    CONSTRAINT collection_class_choices CHECK(
        collection_class IN (
            'spot sample',
            'mixed sample',
            'collective sample',
            'time series',
            'free measurement'
        )
    ),

    FOREIGN KEY (id_matrix) REFERENCES matrix (id_matrix),
    FOREIGN KEY (id_spot)   REFERENCES spot (id_spot),
    FOREIGN KEY (id_site)   REFERENCES site (id_site)
);
