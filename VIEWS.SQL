/* Generic views */


/* Display raw values in conjunction with their respective collections. */

CREATE OR REPLACE VIEW v_raw_value AS
SELECT      c.name              AS "collection",
            c.id_collection     AS "collection_id",
            a.name              AS "action",
            a.iteration         AS "version",
            v.name              AS "parameter",
            p.given_name        AS "operator_given_name",
            p.surname           AS "operator_surname",
            y.decimal_raw_value AS "y",
            y.t                 AS "effect_time",
            u.name              AS "unit"
FROM        collection c
JOIN        value v         ON c.id_collection = v.id_collection
JOIN        effect e        ON e.id_effect = v.id_effect
JOIN        action a        ON a.id_action = e.id_action
JOIN        parameter pm    ON pm.id_parameter = e.id_parameter
JOIN        raw_value y     ON y.id_value = v.id_value
JOIN        person p        ON p.id_person = y.id_person
JOIN        unit u          ON u.id_unit = y.id_unit
;


/* The address-related tables can be cumbersome.
   The following view provides a flatter table. */

CREATE OR REPLACE VIEW v_address AS
SELECT      house.id_house          AS "house_id",
            house.number            AS "house_number",
            house.number_addition   AS "house_number_addition",
            street.id_street        AS "street_id",
            street.name             AS "street_name",
            district.id_district    AS "district_id",
            district.name           AS "district_name",
            district.zip            AS "district_zip",
            city.id_city            AS "city_id",
            city.name               AS "city_name"
FROM        house
JOIN        street      ON street.id_street = house.id_street
JOIN        district    ON district.id_district = street.id_district
JOIN        city        ON city.id_city = district.id_city
;
