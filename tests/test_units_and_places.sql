/* Units convert within their dimension; addresses stay unique without
   forbidding what real addresses do. */

INSERT INTO dimension (name) VALUES ('mass concentration'), ('temperature'), ('acidity');

INSERT INTO unit (name, symbol, ucum_code, id_dimension, conversion_factor, conversion_offset) VALUES
    ('milligram per litre', 'mg/L', 'mg/L', 1, 0.001, 0),
    ('microgram per litre', 'µg/L', 'ug/L', 1, 0.000001, 0),
    ('degree Celsius', '°C', 'Cel', 2, 1, 273.15),
    ('kelvin', 'K', 'K', 2, 1, 0),
    ('pH unit', 'pH', '[pH]', 3, NULL, 0);

CALL assert_number(convert_unit(1.5, 1, 2), 1500, 'mg/L to µg/L');
CALL assert_number(convert_unit(20, 3, 4), 293.15, '°C to K uses the offset');
CALL assert_number(convert_unit(293.15, 4, 3), 20, 'K to °C');
CALL assert_number(convert_unit(7, 5, 5), 7, 'a unit converts to itself, even without a factor');
CALL assert_true(convert_unit(1, 1, 3) IS NULL, 'units of different dimensions do not convert');

CALL assert_fails("INSERT INTO unit (name, symbol, id_dimension, conversion_offset) VALUES ('x', 'x', 1, 5)",
                  'unit_offset_needs_factor', 'an offset without a factor is refused');

/* Notations are case sensitive: mg/l and mg/L are two notations. */
INSERT INTO unit_notation (id_unit, notation) VALUES (1, 'mg/l'), (1, 'mg/L');
CALL assert_equal((SELECT COUNT(*) FROM unit_notation), 2, 'notations differing in case');

CALL assert_fails("INSERT INTO observed_property (name, result_type) VALUES ('nitrate', 'numeric')",
                  'numeric_property_has_dimension', 'numeric properties need a dimension');
CALL assert_fails("INSERT INTO observed_property (name, result_type, id_dimension) VALUES ('colour', 'text', 1)",
                  'numeric_property_has_dimension', 'text properties have no dimension');


/* Addresses */

INSERT INTO country (iso_code, name) VALUES ('DE', 'Germany');
INSERT INTO city (name, id_country) VALUES ('Berlin', 1), ('Neustadt', 1), ('Neustadt', 1);
CALL assert_equal((SELECT COUNT(*) FROM city WHERE name = 'Neustadt'), 2, 'two cities may share a name');

/* The same street name twice in one city, told apart by the postal code. */
INSERT INTO street (name, postal_code, id_city) VALUES ('Hauptstraße', '10827', 1), ('Hauptstraße', '13055', 1);
CALL assert_fails("INSERT INTO street (name, postal_code, id_city) VALUES ('Hauptstraße', '10827', 1)",
                  'Duplicate entry', 'the same street segment twice is refused');

INSERT INTO address (id_street, house_number) VALUES (1, '12'), (1, '12a');
CALL assert_fails("INSERT INTO address (id_street, house_number) VALUES (1, '12')",
                  'Duplicate entry', 'the same house twice is refused');

CALL assert_equal((SELECT CONCAT(street, ' ', house_number, ', ', postal_code, ' ', city)
                   FROM v_address WHERE id_address = 2),
                  'Hauptstraße 12a, 10827 Berlin', 'v_address writes an address like an envelope');


/* People and organizations */

INSERT INTO organization (name) VALUES ('Institute A'), ('Institute B');
INSERT INTO person (given_name, surname, db_account) VALUES ('Ada', 'Example', SUBSTRING_INDEX(USER(), '@', 1));
INSERT INTO organization_member (id_organization, id_person) VALUES (1, 1), (2, 1);
CALL assert_equal((SELECT COUNT(*) FROM organization_member WHERE id_person = 1), 2,
                  'a person can belong to several organizations');
CALL assert_fails("INSERT INTO organization_member (id_organization, id_person) VALUES (1, 1)",
                  'Duplicate entry', 'membership is recorded once');

CALL assert_equal(current_person(), 1, 'current_person() finds the person of the database account');
