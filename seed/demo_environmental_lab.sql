/* Demo data: a small environmental lab monitors a lake for its customer.

   Everything here is fictional. The script replays two weeks of lab work in
   September 2026 through the same procedures a frontend would call, so it
   doubles as a walkthrough of how lucentBase is used. "SET timestamp" moves
   the session clock forward, so every "now" in the database (planning times,
   result times, reviews) happens when it would have happened.

   Load it into a freshly migrated database:

       bin/migrate lucent_demo
       mariadb lucent_demo < seed/demo_environmental_lab.sql

   The story:

   - Stadtwerke Musterstadt orders the September monitoring of the lake
     Musterweiher: temperature and pH in the field at two sampling points,
     nitrate and total hardness in the lab.
   - On 15 September, Jonas takes a bottle at each point and measures in the
     field. In the lab, each bottle is split into an aliquot for anions
     (filtered) and one for metals (acidified).
   - Mira measures nitrate by ion chromatography (with a typo she corrects)
     and calcium, magnesium and lead by ICP-OES. Total hardness is calculated
     from calcium and magnesium.
   - Erika reviews everything, and the report goes out on 18 September.
   - The bottles wait in the fridge for disposal after the retention time. */


SET timestamp = UNIX_TIMESTAMP('2026-09-01 08:00:00');


/* ---------------------------------------------------------------------------
   Reference data: dimensions, units, properties, matrices
   --------------------------------------------------------------------------- */

INSERT INTO dimension (name, description) VALUES
    ('mass concentration',   'mass per volume, SI unit kg/m³'),
    ('amount concentration', 'amount of substance per volume, SI unit mol/m³'),
    ('temperature',          'SI unit K'),
    ('volume',               'SI unit m³'),
    ('dimensionless',        'ratios, factors and counts'),
    ('acidity',              'pH value; logarithmic, not convertible');

INSERT INTO unit (name, symbol, ucum_code, id_dimension, conversion_factor, conversion_offset)
SELECT 'milligram per litre', 'mg/L', 'mg/L', id_dimension, 0.001, 0 FROM dimension WHERE name = 'mass concentration' UNION ALL
SELECT 'microgram per litre', 'µg/L', 'ug/L', id_dimension, 0.000001, 0 FROM dimension WHERE name = 'mass concentration' UNION ALL
SELECT 'millimole per litre', 'mmol/L', 'mmol/L', id_dimension, 1, 0 FROM dimension WHERE name = 'amount concentration' UNION ALL
SELECT 'German degree of hardness', '°dH', NULL, id_dimension, 0.17832, 0 FROM dimension WHERE name = 'amount concentration' UNION ALL
SELECT 'degree Celsius', '°C', 'Cel', id_dimension, 1, 273.15 FROM dimension WHERE name = 'temperature' UNION ALL
SELECT 'kelvin', 'K', 'K', id_dimension, 1, 0 FROM dimension WHERE name = 'temperature' UNION ALL
SELECT 'litre', 'L', 'L', id_dimension, 0.001, 0 FROM dimension WHERE name = 'volume' UNION ALL
SELECT 'millilitre', 'mL', 'mL', id_dimension, 0.000001, 0 FROM dimension WHERE name = 'volume' UNION ALL
SELECT 'one', '1', '1', id_dimension, 1, 0 FROM dimension WHERE name = 'dimensionless' UNION ALL
SELECT 'pH unit', 'pH', '[pH]', id_dimension, NULL, 0 FROM dimension WHERE name = 'acidity';

INSERT INTO unit_notation (id_unit, notation)
SELECT id_unit, 'mg/l' FROM unit WHERE symbol = 'mg/L' UNION ALL
SELECT id_unit, 'mg/L' FROM unit WHERE symbol = 'mg/L' UNION ALL
SELECT id_unit, 'ug/l' FROM unit WHERE symbol = 'µg/L' UNION ALL
SELECT id_unit, 'µg/l' FROM unit WHERE symbol = 'µg/L' UNION ALL
SELECT id_unit, 'deg C' FROM unit WHERE symbol = '°C';

INSERT INTO observed_property (name, result_type, id_dimension, description)
SELECT 'water temperature', 'numeric', id_dimension, NULL FROM dimension WHERE name = 'temperature' UNION ALL
SELECT 'temperature on arrival', 'numeric', id_dimension, 'checks the cooling chain' FROM dimension WHERE name = 'temperature' UNION ALL
SELECT 'pH value', 'numeric', id_dimension, NULL FROM dimension WHERE name = 'acidity' UNION ALL
SELECT 'nitrate in measuring solution', 'numeric', id_dimension, 'instrument reading before dilution is accounted for' FROM dimension WHERE name = 'mass concentration' UNION ALL
SELECT 'dilution factor', 'numeric', id_dimension, NULL FROM dimension WHERE name = 'dimensionless' UNION ALL
SELECT 'nitrate', 'numeric', id_dimension, 'mass concentration of nitrate (NO3-)' FROM dimension WHERE name = 'mass concentration' UNION ALL
SELECT 'calcium', 'numeric', id_dimension, 'mass concentration of calcium' FROM dimension WHERE name = 'mass concentration' UNION ALL
SELECT 'magnesium', 'numeric', id_dimension, 'mass concentration of magnesium' FROM dimension WHERE name = 'mass concentration' UNION ALL
SELECT 'lead', 'numeric', id_dimension, 'mass concentration of lead' FROM dimension WHERE name = 'mass concentration' UNION ALL
SELECT 'total hardness', 'numeric', id_dimension, 'sum of calcium and magnesium ions' FROM dimension WHERE name = 'amount concentration';

INSERT INTO observed_property (name, result_type, description) VALUES
    ('appearance', 'text', 'colour and turbidity as seen on arrival');

INSERT INTO matrix (name, description) VALUES
    ('surface water', 'water from lakes, rivers and ponds');


/* ---------------------------------------------------------------------------
   The lab, its customer and their people
   --------------------------------------------------------------------------- */

INSERT INTO country (iso_code, name) VALUES ('DE', 'Germany');
INSERT INTO city (name, id_country) SELECT 'Musterstadt', id_country FROM country WHERE iso_code = 'DE';
SET @musterstadt = LAST_INSERT_ID();

INSERT INTO street (name, postal_code, id_city) VALUES ('Laborweg', '12345', @musterstadt);
INSERT INTO address (id_street, house_number) VALUES (LAST_INSERT_ID(), '5');
SET @lab_address = LAST_INSERT_ID();

INSERT INTO street (name, postal_code, id_city) VALUES ('Hauptstraße', '12345', @musterstadt);
INSERT INTO address (id_street, house_number) VALUES (LAST_INSERT_ID(), '1');
SET @customer_address = LAST_INSERT_ID();

INSERT INTO organization (name, short_name) VALUES ('Demolabor Musterstadt', 'Demolabor');
SET @lab = LAST_INSERT_ID();
INSERT INTO organization (name, short_name) VALUES ('Stadtwerke Musterstadt', 'SWM');
SET @customer = LAST_INSERT_ID();
INSERT INTO organization (name) VALUES ('Beispiel Instruments GmbH');
SET @manufacturer = LAST_INSERT_ID();

INSERT INTO organization_address (id_organization, id_address, purpose) VALUES
    (@lab, @lab_address, 'postal'),
    (@customer, @customer_address, 'postal'),
    (@customer, @customer_address, 'billing');

INSERT INTO person (given_name, surname, email) VALUES ('Erika', 'Mustermann', 'erika@demolabor.example');
SET @erika = LAST_INSERT_ID();
INSERT INTO person (given_name, surname, email) VALUES ('Jonas', 'Beispiel', 'jonas@demolabor.example');
SET @jonas = LAST_INSERT_ID();
INSERT INTO person (given_name, surname, email) VALUES ('Mira', 'Probe', 'mira@demolabor.example');
SET @mira = LAST_INSERT_ID();
INSERT INTO person (given_name, surname, email) VALUES ('Paul', 'Kunde', 'paul.kunde@stadtwerke.example');
SET @paul = LAST_INSERT_ID();

INSERT INTO organization_member (id_organization, id_person, position) VALUES
    (@lab, @erika, 'head of laboratory'),
    (@lab, @jonas, 'sampling technician'),
    (@lab, @mira, 'laboratory technician'),
    (@customer, @paul, 'water quality');


/* ---------------------------------------------------------------------------
   Devices, documents and storage
   --------------------------------------------------------------------------- */

INSERT INTO device (name, inventory_number, serial_number, id_manufacturer) VALUES
    ('field multimeter (temperature, pH)', 'D-001', 'FM1-20931', @manufacturer),
    ('ion chromatograph',                  'D-002', 'IC5-11872', @manufacturer),
    ('ICP-OES',                            'D-003', 'OES2-4410', @manufacturer);

INSERT INTO storage_location (name, description) VALUES
    ('fridge 1', 'sample fridge, 2-6 °C');

INSERT INTO link (name, uri) VALUES
    ('SOP anions by ion chromatography', 'https://paperless.demolabor.example/documents/101/');
SET @sop_ic = LAST_INSERT_ID();


/* ---------------------------------------------------------------------------
   Methods, what they determine, and how they depend on each other
   --------------------------------------------------------------------------- */

INSERT INTO method (name, kind, description, is_final) VALUES
    ('grab sampling, surface water',      'sampling',    'fill a 1 L bottle from 30 cm below the surface', FALSE),
    ('aliquoting',                        'sampling',    'pour off part of a sample into a new container', FALSE),
    ('field measurement',                 'observation', 'temperature and pH at the sampling point',      FALSE),
    ('sample receipt',                    'handling',    'check and register an arriving sample',          FALSE),
    ('membrane filtration 0.45 µm',       'preparation', NULL,                                              FALSE),
    ('acidification with nitric acid',    'preparation', 'to pH < 2 for metal analysis',                    FALSE),
    ('anions by ion chromatography',      'observation', 'DIN EN ISO 10304-1',                              FALSE),
    ('metals by ICP-OES',                 'observation', 'DIN EN ISO 11885',                                FALSE),
    ('total hardness from Ca and Mg',     'observation', 'calculated',                                      FALSE),
    ('disposal',                          'handling',    'after the retention time of four weeks',          TRUE);

INSERT INTO method_version (id_method, valid_from, change_note)
SELECT id_method, '2026-01-01 00:00:00', 'first version' FROM method;

/* Shortcuts to the current version of each method, for the inserts below. */
SET @v_grab       = (SELECT current_method_version(id_method) FROM method WHERE name = 'grab sampling, surface water');
SET @v_field      = (SELECT current_method_version(id_method) FROM method WHERE name = 'field measurement');
SET @v_receipt    = (SELECT current_method_version(id_method) FROM method WHERE name = 'sample receipt');
SET @v_ic         = (SELECT current_method_version(id_method) FROM method WHERE name = 'anions by ion chromatography');
SET @v_icp        = (SELECT current_method_version(id_method) FROM method WHERE name = 'metals by ICP-OES');
SET @v_hardness   = (SELECT current_method_version(id_method) FROM method WHERE name = 'total hardness from Ca and Mg');

INSERT INTO method_version_link (id_method_version, id_link) VALUES (@v_ic, @sop_ic);

SET @mg_l     = (SELECT id_unit FROM unit WHERE symbol = 'mg/L');
SET @celsius  = (SELECT id_unit FROM unit WHERE symbol = '°C');
SET @ph_unit  = (SELECT id_unit FROM unit WHERE symbol = 'pH');
SET @one      = (SELECT id_unit FROM unit WHERE symbol = '1');
SET @dh       = (SELECT id_unit FROM unit WHERE symbol = '°dH');

/* property ids by name */
SET @p_water_temperature = (SELECT id_observed_property FROM observed_property WHERE name = 'water temperature');
SET @p_arrival_temperature = (SELECT id_observed_property FROM observed_property WHERE name = 'temperature on arrival');
SET @p_ph         = (SELECT id_observed_property FROM observed_property WHERE name = 'pH value');
SET @p_appearance = (SELECT id_observed_property FROM observed_property WHERE name = 'appearance');
SET @p_reading    = (SELECT id_observed_property FROM observed_property WHERE name = 'nitrate in measuring solution');
SET @p_dilution   = (SELECT id_observed_property FROM observed_property WHERE name = 'dilution factor');
SET @p_nitrate    = (SELECT id_observed_property FROM observed_property WHERE name = 'nitrate');
SET @p_calcium    = (SELECT id_observed_property FROM observed_property WHERE name = 'calcium');
SET @p_magnesium  = (SELECT id_observed_property FROM observed_property WHERE name = 'magnesium');
SET @p_lead       = (SELECT id_observed_property FROM observed_property WHERE name = 'lead');
SET @p_hardness   = (SELECT id_observed_property FROM observed_property WHERE name = 'total hardness');

INSERT INTO method_property
    (id_method_version, id_observed_property, id_unit, decimal_places, lod, loq,
     uncertainty, uncertainty_kind, is_required, is_reported, formula)
VALUES
    (@v_field,    @p_water_temperature,   @celsius, 1, NULL,  NULL,  0.2,  'absolute', TRUE,  TRUE,  NULL),
    (@v_field,    @p_ph,                  @ph_unit, 2, NULL,  NULL,  0.05, 'absolute', TRUE,  TRUE,  NULL),
    (@v_receipt,  @p_arrival_temperature, @celsius, 1, NULL,  NULL,  NULL, NULL,       TRUE,  FALSE, NULL),
    (@v_receipt,  @p_appearance,          NULL,     NULL, NULL, NULL, NULL, NULL,      FALSE, FALSE, NULL),
    (@v_ic,       @p_reading,             @mg_l,    2, NULL,  NULL,  NULL, NULL,       TRUE,  FALSE, NULL),
    (@v_ic,       @p_dilution,            @one,     0, NULL,  NULL,  NULL, NULL,       TRUE,  FALSE, NULL),
    (@v_ic,       @p_nitrate,             @mg_l,    1, 0.15,  0.5,   0.08, 'relative', TRUE,  TRUE,  'reading * dilution'),
    (@v_icp,      @p_calcium,             @mg_l,    1, 0.1,   0.5,   0.05, 'relative', TRUE,  TRUE,  NULL),
    (@v_icp,      @p_magnesium,           @mg_l,    2, 0.03,  0.1,   0.05, 'relative', TRUE,  TRUE,  NULL),
    (@v_icp,      @p_lead,                @mg_l,    3, 0.002, 0.005, 0.15, 'relative', TRUE,  TRUE,  NULL),
    (@v_hardness, @p_hardness,            @dh,      1, NULL,  NULL,  NULL, NULL,       TRUE,  TRUE,
        '0.1399 * calcium + 0.2307 * magnesium');

INSERT INTO formula_input (id_method_property, variable_name, id_observed_property, id_unit, scope, aggregation)
SELECT id_method_property, 'reading', @p_reading, @mg_l, 'same action', 'mean'
FROM   method_property WHERE id_method_version = @v_ic AND id_observed_property = @p_nitrate
UNION ALL
SELECT id_method_property, 'dilution', @p_dilution, @one, 'same action', 'latest'
FROM   method_property WHERE id_method_version = @v_ic AND id_observed_property = @p_nitrate
UNION ALL
SELECT id_method_property, 'calcium', @p_calcium, @mg_l, 'sample', 'mean'
FROM   method_property WHERE id_method_version = @v_hardness AND id_observed_property = @p_hardness
UNION ALL
SELECT id_method_property, 'magnesium', @p_magnesium, @mg_l, 'sample', 'mean'
FROM   method_property WHERE id_method_version = @v_hardness AND id_observed_property = @p_hardness;

/* Which method must have finished before another may start ... */
INSERT INTO method_prerequisite (id_method, id_prerequisite_method)
SELECT m.id_method, p.id_method FROM method m, method p WHERE m.name = 'sample receipt'                 AND p.name = 'grab sampling, surface water' UNION ALL
SELECT m.id_method, p.id_method FROM method m, method p WHERE m.name = 'aliquoting'                     AND p.name = 'sample receipt' UNION ALL
SELECT m.id_method, p.id_method FROM method m, method p WHERE m.name = 'membrane filtration 0.45 µm'    AND p.name = 'sample receipt' UNION ALL
SELECT m.id_method, p.id_method FROM method m, method p WHERE m.name = 'acidification with nitric acid' AND p.name = 'sample receipt' UNION ALL
SELECT m.id_method, p.id_method FROM method m, method p WHERE m.name = 'anions by ion chromatography'   AND p.name = 'membrane filtration 0.45 µm' UNION ALL
SELECT m.id_method, p.id_method FROM method m, method p WHERE m.name = 'metals by ICP-OES'              AND p.name = 'acidification with nitric acid' UNION ALL
SELECT m.id_method, p.id_method FROM method m, method p WHERE m.name = 'total hardness from Ca and Mg'  AND p.name = 'metals by ICP-OES';

/* ... and which method brings which other one along when it is planned. */
INSERT INTO method_implication (id_method, id_implied_method)
SELECT m.id_method, i.id_method FROM method m, method i WHERE m.name = 'grab sampling, surface water'  AND i.name = 'sample receipt' UNION ALL
SELECT m.id_method, i.id_method FROM method m, method i WHERE m.name = 'sample receipt'                AND i.name = 'disposal' UNION ALL
SELECT m.id_method, i.id_method FROM method m, method i WHERE m.name = 'anions by ion chromatography'  AND i.name = 'membrane filtration 0.45 µm' UNION ALL
SELECT m.id_method, i.id_method FROM method m, method i WHERE m.name = 'metals by ICP-OES'             AND i.name = 'acidification with nitric acid' UNION ALL
SELECT m.id_method, i.id_method FROM method m, method i WHERE m.name = 'total hardness from Ca and Mg' AND i.name = 'metals by ICP-OES';

/* method ids by name, for planning */
SET @m_grab       = (SELECT id_method FROM method WHERE name = 'grab sampling, surface water');
SET @m_aliquoting = (SELECT id_method FROM method WHERE name = 'aliquoting');
SET @m_field      = (SELECT id_method FROM method WHERE name = 'field measurement');
SET @m_ic         = (SELECT id_method FROM method WHERE name = 'anions by ion chromatography');
SET @m_hardness   = (SELECT id_method FROM method WHERE name = 'total hardness from Ca and Mg');


/* ---------------------------------------------------------------------------
   10 September: the order comes in and the sampling is planned
   --------------------------------------------------------------------------- */

SET timestamp = UNIX_TIMESTAMP('2026-09-10 10:00:00');

INSERT INTO feature (name, description, shape) VALUES (
    'Musterweiher',
    'lake north of Musterstadt, about 4 ha',
    ST_GeomFromText('POLYGON((10.0010 51.0020, 10.0045 51.0021, 10.0047 51.0003, 10.0012 51.0001, 10.0010 51.0020))', 4326)
);
SET @lake = LAST_INSERT_ID();

SET @surface_water = (SELECT id_matrix FROM matrix WHERE name = 'surface water');

INSERT INTO sample (code, sample_kind, id_sampled_feature, id_matrix, location, location_description) VALUES
    ('MW-P1', 'spatial', @lake, @surface_water, ST_GeomFromText('POINT(10.0021 51.0019)', 4326), 'north inlet, from the jetty'),
    ('MW-P2', 'spatial', @lake, @surface_water, ST_GeomFromText('POINT(10.0040 51.0006)', 4326), 'bathing area, 5 m from the shore');
SET @p1 = (SELECT id_sample FROM sample WHERE code = 'MW-P1');
SET @p2 = (SELECT id_sample FROM sample WHERE code = 'MW-P2');

INSERT INTO lab_order (order_number, id_customer_organization, id_contact_person, received_on, due_on, description)
VALUES ('2026-0917', @customer, @paul, '2026-09-10', '2026-09-25', 'Musterweiher monitoring, September');
SET @order = LAST_INSERT_ID();

/* The bottles are registered in advance, so their labels can be printed. */
INSERT INTO sample (code, sample_kind, id_matrix, size, id_size_unit, description)
SELECT '2026-0917-01', 'material', @surface_water, 1, id_unit, 'bottle from MW-P1' FROM unit WHERE symbol = 'L' UNION ALL
SELECT '2026-0917-02', 'material', @surface_water, 1, id_unit, 'bottle from MW-P2' FROM unit WHERE symbol = 'L';
SET @bottle1 = (SELECT id_sample FROM sample WHERE code = '2026-0917-01');
SET @bottle2 = (SELECT id_sample FROM sample WHERE code = '2026-0917-02');

INSERT INTO sample_source (id_sample, id_source_sample) VALUES (@bottle1, @p1), (@bottle2, @p2);

/* Planning the grab sampling also plans receipt and, through it, disposal. */
CALL plan_action(@bottle1, @m_grab,  @order, @jonas, '2026-09-15 09:00:00', @sampling1);
CALL plan_action(@bottle2, @m_grab,  @order, @jonas, '2026-09-15 09:00:00', @sampling2);
CALL plan_action(@p1,      @m_field, @order, @jonas, '2026-09-15 09:00:00', @field1);
CALL plan_action(@p2,      @m_field, @order, @jonas, '2026-09-15 09:00:00', @field2);


/* ---------------------------------------------------------------------------
   15 September: sampling and field measurements, receipt in the lab
   --------------------------------------------------------------------------- */

SET timestamp = UNIX_TIMESTAMP('2026-09-15 09:05:00');
CALL start_action(@field1, @jonas, NULL);
INSERT INTO action_device (id_action, id_device) SELECT @field1, id_device FROM device WHERE inventory_number = 'D-001';
INSERT INTO observation (id_action, id_observed_property, result_numeric) VALUES
    (@field1, @p_water_temperature, 14.2),
    (@field1, @p_ph, 7.61);
CALL finish_action(@field1, NULL);

SET timestamp = UNIX_TIMESTAMP('2026-09-15 09:10:00');
CALL start_action(@sampling1, @jonas, NULL);
CALL finish_action(@sampling1, '2026-09-15 09:12:00');

SET timestamp = UNIX_TIMESTAMP('2026-09-15 09:35:00');
CALL start_action(@field2, @jonas, NULL);
INSERT INTO action_device (id_action, id_device) SELECT @field2, id_device FROM device WHERE inventory_number = 'D-001';
INSERT INTO observation (id_action, id_observed_property, result_numeric) VALUES
    (@field2, @p_water_temperature, 15.0),
    (@field2, @p_ph, 7.84);
CALL finish_action(@field2, NULL);

SET timestamp = UNIX_TIMESTAMP('2026-09-15 09:40:00');
CALL start_action(@sampling2, @jonas, NULL);
CALL finish_action(@sampling2, '2026-09-15 09:42:00');

SET timestamp = UNIX_TIMESTAMP('2026-09-15 13:00:00');
SET @receipt1 = (SELECT id_action FROM action WHERE id_sample = @bottle1 AND id_method_version = @v_receipt);
SET @receipt2 = (SELECT id_action FROM action WHERE id_sample = @bottle2 AND id_method_version = @v_receipt);

CALL start_action(@receipt1, @mira, NULL);
INSERT INTO observation (id_action, id_observed_property, result_numeric) VALUES (@receipt1, @p_arrival_temperature, 6.1);
INSERT INTO observation (id_action, id_observed_property, result_text) VALUES (@receipt1, @p_appearance, 'clear, colourless');
CALL finish_action(@receipt1, NULL);

CALL start_action(@receipt2, @mira, NULL);
INSERT INTO observation (id_action, id_observed_property, result_numeric) VALUES (@receipt2, @p_arrival_temperature, 6.4);
INSERT INTO observation (id_action, id_observed_property, result_text) VALUES (@receipt2, @p_appearance, 'slightly turbid');
CALL finish_action(@receipt2, NULL);

UPDATE sample
SET    id_storage_location = (SELECT id_storage_location FROM storage_location WHERE name = 'fridge 1')
WHERE  id_sample IN (@bottle1, @bottle2);

/* The bottles are kept for four weeks before they are disposed of. */
UPDATE action
SET    due_at = '2026-10-13 12:00:00'
WHERE  id_sample IN (@bottle1, @bottle2)
  AND  id_method_version = (SELECT current_method_version(id_method) FROM method WHERE name = 'disposal');


/* Each bottle is split into an aliquot for anions (A) and one for metals (M).
   Planning nitrate brings filtration along; planning total hardness brings
   ICP-OES and, through it, acidification. */

SET timestamp = UNIX_TIMESTAMP('2026-09-15 13:30:00');

INSERT INTO sample (code, sample_kind, id_matrix, size, id_size_unit, description)
SELECT '2026-0917-01-A', 'material', @surface_water, 100, id_unit, 'anions' FROM unit WHERE symbol = 'mL' UNION ALL
SELECT '2026-0917-01-M', 'material', @surface_water, 100, id_unit, 'metals' FROM unit WHERE symbol = 'mL' UNION ALL
SELECT '2026-0917-02-A', 'material', @surface_water, 100, id_unit, 'anions' FROM unit WHERE symbol = 'mL' UNION ALL
SELECT '2026-0917-02-M', 'material', @surface_water, 100, id_unit, 'metals' FROM unit WHERE symbol = 'mL';
SET @anions1 = (SELECT id_sample FROM sample WHERE code = '2026-0917-01-A');
SET @metals1 = (SELECT id_sample FROM sample WHERE code = '2026-0917-01-M');
SET @anions2 = (SELECT id_sample FROM sample WHERE code = '2026-0917-02-A');
SET @metals2 = (SELECT id_sample FROM sample WHERE code = '2026-0917-02-M');

INSERT INTO sample_source (id_sample, id_source_sample) VALUES
    (@anions1, @bottle1), (@metals1, @bottle1),
    (@anions2, @bottle2), (@metals2, @bottle2);

CALL plan_action(@anions1, @m_aliquoting, @order, @mira, NULL, @aliquoting_a1);
CALL plan_action(@metals1, @m_aliquoting, @order, @mira, NULL, @aliquoting_m1);
CALL plan_action(@anions2, @m_aliquoting, @order, @mira, NULL, @aliquoting_a2);
CALL plan_action(@metals2, @m_aliquoting, @order, @mira, NULL, @aliquoting_m2);

CALL plan_action(@anions1, @m_ic,       @order, @mira, '2026-09-16 12:00:00', @ic1);
CALL plan_action(@anions2, @m_ic,       @order, @mira, '2026-09-16 12:00:00', @ic2);
CALL plan_action(@metals1, @m_hardness, @order, @mira, '2026-09-17 12:00:00', @hardness1);
CALL plan_action(@metals2, @m_hardness, @order, @mira, '2026-09-17 12:00:00', @hardness2);

/* Aliquoting counts as sampling in OMS terms: it creates new samples. Its
   prerequisite, the receipt, happened on the bottle, an ancestor. */
CALL start_action(@aliquoting_a1, @mira, NULL);  CALL finish_action(@aliquoting_a1, NULL);
CALL start_action(@aliquoting_m1, @mira, NULL);  CALL finish_action(@aliquoting_m1, NULL);
CALL start_action(@aliquoting_a2, @mira, NULL);  CALL finish_action(@aliquoting_a2, NULL);
CALL start_action(@aliquoting_m2, @mira, NULL);  CALL finish_action(@aliquoting_m2, NULL);

/* Filtration and acidification were planned implicitly; do them now. */
SET timestamp = UNIX_TIMESTAMP('2026-09-15 14:00:00');

DELIMITER $$
BEGIN NOT ATOMIC
    DECLARE v_done BOOLEAN DEFAULT FALSE;
    DECLARE v_id_action INTEGER;
    DECLARE preparation CURSOR FOR
        SELECT      action.id_action
        FROM        action
        JOIN        method_version  ON method_version.id_method_version = action.id_method_version
        JOIN        method          ON method.id_method = method_version.id_method
        WHERE       method.kind = 'preparation'
          AND       action.status = 'planned'
        ORDER BY    action.id_action;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;

    OPEN preparation;
    preparation_loop: LOOP
        FETCH preparation INTO v_id_action;
        IF v_done THEN
            LEAVE preparation_loop;
        END IF;
        CALL start_action(v_id_action, @mira, NULL);
        CALL finish_action(v_id_action, NULL);
    END LOOP;
    CLOSE preparation;
END$$
DELIMITER ;


/* ---------------------------------------------------------------------------
   16 September: nitrate by ion chromatography
   --------------------------------------------------------------------------- */

SET timestamp = UNIX_TIMESTAMP('2026-09-16 10:15:00');
CALL start_action(@ic1, @mira, NULL);
INSERT INTO action_device (id_action, id_device) SELECT @ic1, id_device FROM device WHERE inventory_number = 'D-002';
INSERT INTO link (name, file_path) VALUES ('IC sequence 2026-09-16', '/srv/rawdata/ic/2026-09-16/sequence.csv');
INSERT INTO action_link (id_action, id_link) VALUES (@ic1, LAST_INSERT_ID());

/* Mira types 123.0 instead of 12.30, notices, and corrects it: the wrong
   value is invalidated with a reason, never overwritten. */
INSERT INTO observation (id_action, id_observed_property, result_numeric) VALUES (@ic1, @p_reading, 123.0);
CALL invalidate_observation(LAST_INSERT_ID(), 'Typing error; the instrument shows 12.30.');
INSERT INTO observation (id_action, id_observed_property, result_numeric) VALUES
    (@ic1, @p_reading, 12.30),
    (@ic1, @p_dilution, 2);
CALL finish_action(@ic1, NULL);

/* Sample 02 has hardly any nitrate: 0.21 mg/L is below the LOQ of 0.5 mg/L.
   The exact value is kept; it is displayed and reported as "< 0.5". */
SET timestamp = UNIX_TIMESTAMP('2026-09-16 10:40:00');
CALL start_action(@ic2, @mira, NULL);
INSERT INTO action_device (id_action, id_device) SELECT @ic2, id_device FROM device WHERE inventory_number = 'D-002';
INSERT INTO observation (id_action, id_observed_property, result_numeric) VALUES
    (@ic2, @p_reading, 0.21),
    (@ic2, @p_dilution, 1);
CALL finish_action(@ic2, NULL);


/* ---------------------------------------------------------------------------
   17 September: metals by ICP-OES, then total hardness is calculated
   --------------------------------------------------------------------------- */

SET timestamp = UNIX_TIMESTAMP('2026-09-17 09:30:00');
SET @icp1 = (SELECT id_action FROM action WHERE id_sample = @metals1 AND id_method_version = @v_icp);
SET @icp2 = (SELECT id_action FROM action WHERE id_sample = @metals2 AND id_method_version = @v_icp);

CALL start_action(@icp1, @mira, NULL);
INSERT INTO action_device (id_action, id_device) SELECT @icp1, id_device FROM device WHERE inventory_number = 'D-003';
INSERT INTO observation (id_action, id_observed_property, result_numeric) VALUES
    (@icp1, @p_calcium, 48.2),
    (@icp1, @p_magnesium, 9.75),
    (@icp1, @p_lead, 0.0031);
CALL finish_action(@icp1, NULL);

/* This lead value came from the instrument as a limit only. */
CALL start_action(@icp2, @mira, NULL);
INSERT INTO action_device (id_action, id_device) SELECT @icp2, id_device FROM device WHERE inventory_number = 'D-003';
INSERT INTO observation (id_action, id_observed_property, result_numeric) VALUES
    (@icp2, @p_calcium, 51.0),
    (@icp2, @p_magnesium, 10.4);
INSERT INTO observation (id_action, id_observed_property, result_numeric, censoring) VALUES
    (@icp2, @p_lead, 0.002, '<');
CALL finish_action(@icp2, NULL);

SET timestamp = UNIX_TIMESTAMP('2026-09-17 11:00:00');
CALL start_action(@hardness1, @mira, NULL);
CALL finish_action(@hardness1, NULL);
CALL start_action(@hardness2, @mira, NULL);
CALL finish_action(@hardness2, NULL);


/* ---------------------------------------------------------------------------
   18 September: review and report
   --------------------------------------------------------------------------- */

SET timestamp = UNIX_TIMESTAMP('2026-09-18 08:30:00');

DELIMITER $$
BEGIN NOT ATOMIC
    DECLARE v_done BOOLEAN DEFAULT FALSE;
    DECLARE v_id_action INTEGER;
    DECLARE finished_with_results CURSOR FOR
        SELECT DISTINCT action.id_action
        FROM            action
        JOIN            observation     ON observation.id_action = action.id_action
        WHERE           action.id_lab_order = @order
          AND           action.status = 'finished'
        ORDER BY        action.id_action;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;

    OPEN finished_with_results;
    review_loop: LOOP
        FETCH finished_with_results INTO v_id_action;
        IF v_done THEN
            LEAVE review_loop;
        END IF;
        CALL review_action(v_id_action, @erika);
    END LOOP;
    CLOSE finished_with_results;
END$$
DELIMITER ;

SET timestamp = UNIX_TIMESTAMP('2026-09-18 10:00:00');
INSERT INTO report (id_lab_order, report_number) VALUES (@order, 'R-2026-0917-1');
SET @report = LAST_INSERT_ID();
CALL issue_report(@report, @erika);

INSERT INTO link (name, uri, sha256) VALUES (
    'Report R-2026-0917-1',
    'https://paperless.demolabor.example/documents/2177/',
    '3f1c0e3a9b7d4e2f8a6c5b4d3e2f1a0b9c8d7e6f5a4b3c2d1e0f9a8b7c6d5e4f'
);
UPDATE report SET id_link = LAST_INSERT_ID() WHERE id_report = @report;


SET timestamp = DEFAULT;
