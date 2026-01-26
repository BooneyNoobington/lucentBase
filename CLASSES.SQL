/* These tables describe classes used for categorization,
   such as matrices for samples or sample types (container classes). */


/* Objects of interest often have a matrix,
   such as air, surface water, or moon regolith. */

CREATE OR REPLACE TABLE matrix
(
    id_matrix       INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    name            VARCHAR(40)     NOT NULL UNIQUE,
    description     VARCHAR(250),
    vis             BOOLEAN         NOT NULL DEFAULT TRUE
);
