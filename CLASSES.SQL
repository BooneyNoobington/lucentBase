/*
These tables describe classes which are used for cathegorization.
Like matrizes for samples or sample types (container classes).
*/



/* Objects of interest often have a matrix. Like air
, surface water or moon regolithe. */
CREATE OR REPLACE TABLE matrix
(
    id_matrix INTEGER PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT,
    name VARCHAR(40) NOT NULL UNIQUE,
    description VARCHAR(250),
    -- Recycle bin
    vis BOOLEAN NOT NULL DEFAULT TRUE
);
