/* Configuration settings that are better kept in
the database itself rather than in a config file */

-- Config for encoding numbers
-- Set up at install time then never change!
CREATE OR REPLACE TABLE `encoding_segment`
(
    `id_encoding_segment` INTEGER PRIMARY KEY UNIQUE NOT NULL,
    -- Segment position (digit) in a decimal number
    `segment_position` INTEGER UNIQUE NOT NULL,
    -- A descriptive name
    `name` VARCHAR(30) NOT NULL
);

CREATE OR REPLACE TABLE `segment_digit`
(
    `id_segment_digit` INTEGER PRIMARY KEY UNIQUE NOT NULL,
    `id_encoding_segment` INTEGER NOT NULL REFERENCING `encoding_segment` (`id_encoding_segment),
    -- The substitution (encoding) for a digit. Like "red" for 1.
    `digit` VARCHAR(15) NOT NULL,
);


-- Revoke all privileges for the user on the table
REVOKE ALL PRIVILEGES ON `lucent`.`encoding_segment` FROM 'lucent'@'localhost';
REVOKE ALL PRIVILEGES ON `lucent`.`segment_digit` FROM 'lucent'@'localhost';


-- Grant only SELECT privilege
GRANT SELECT ON `lucent`.`encoding_segment` TO 'lucent'@'localhost';
GRANT SELECT ON `lucent`.`segment_digit` TO 'lucent'@'localhost';


-- Hard code data into the the two tables
INSERT INTO `encoding_segment` (`segment_position`, `name`)
VALUES(0,  'zero through nine'),       -- 10^0
VALUES(1,  'colors'),                  -- 10^1
VALUES(2,  'houndreds'),               -- 10^2
VALUES(3,  'greek selection one'),     -- 10^3
VALUES(4,  'tens of thousands'),       -- 10^4
VALUES(5,  'greek selection two'),     -- 10^5
VALUES(6,  'millions'),                -- 10^6
VALUES(7,  'latin selection 1'),       -- 10^7
VALUES(8,  'hounreds of millions'),    -- 10^8
VALUES(9,  'latin selection 2'),       -- 10^9
VALUES(10, 'tens of trillions'),       -- 10^10
VALUES(11, 'shapes')                   -- 10^11
;

INSERT INTO `segment_digit` (`id_encoding_segment`, `digit`)
-- Digit 1 = d * 10^0
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 0), '0'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 0), '1'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 0), '2'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 0), '3'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 0), '4'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 0), '5'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 0), '6'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 0), '7'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 0), '8'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 0), '9'),
-- Digit 2 = d * 10^1
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 1), '0'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 1), 'Red'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 1), 'Orange'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 1), 'Yellow'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 1), 'Green'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 1), 'Cyan'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 1), 'Blue'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 1), 'Violet'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 1), 'White'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 1), 'Black'),
-- Digit 3 = d * 10^2
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 2), '0'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 2), '1'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 2), '2'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 2), '3'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 2), '4'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 2), '5'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 2), '6'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 2), '7'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 2), '8'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 2), '9'),
-- Digit 4 = d * 10^3
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 3), '0'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 3), 'Alpha'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 3), 'Beta'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 3), 'Gamma'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 3), 'Delta'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 3), 'Epsilon'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 3), 'Zeta'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 3), 'Iota'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 3), 'Kappa'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 3), 'Lambda'),
-- Digit 5 = d * 10^4
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 4), '0'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 4), '1'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 4), '2'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 4), '3'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 4), '4'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 4), '5'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 4), '6'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 4), '7'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 4), '8'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 4), '9'),
-- Digit 6 = d * 10^5
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 5), '0'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 5), 'Mu'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 5), 'Xi'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 5), 'Omicron'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 5), 'Pi'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 5), 'Rho'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 5), 'Sigma'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 5), 'Tau'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 5), 'Upsilon'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 5), 'Omega'),
-- Digit 7 = d * 10^6
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 6), '0'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 6), '1'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 6), '2'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 6), '3'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 6), '4'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 6), '5'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 6), '6'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 6), '7'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 6), '8'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 6), '9'),
-- Digit 8 = d * 10^7
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 7), '0'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 7), 'A'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 7), 'B'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 7), 'C'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 7), 'D'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 7), 'E'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 7), 'G'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 7), 'H'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 7), 'I'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 7), 'K'),
-- Digit 9 = d * 10^8
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 8), '0'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 8), '1'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 8), '2'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 8), '3'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 8), '4'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 8), '5'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 8), '6'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 8), '7'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 8), '8'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 8), '9'),
-- Digit 10 = d * 10^9
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 9), '0'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 9), 'L'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 9), 'M'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 9), 'P'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 9), 'Q'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 9), 'R'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 9), 'S'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 9), 'T'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 9), 'V'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 9), 'X'),
-- Digit 11 = d * 10^10
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 10), '0'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 10), '1'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 10), '2'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 10), '3'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 10), '4'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 10), '5'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 10), '6'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 10), '7'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 10), '8'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 10), '9'),
-- Digit 12 = d * 10^11
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 11), '0'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 11), 'Dot'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 11), 'Line'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 11), 'Square'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 11), 'Cube'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 11), 'Circle'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 11), 'Sphere'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 11), 'Star'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 11), 'Torus'),
VALUES((SELECT `id_encoding_segment` FROM `encoding_segment` WHERE `segment_position` = 11), 'Tessaract')
;
