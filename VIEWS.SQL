/* Generic views */

/* Display raw values in conjucntion with their respective collections */
CREATE OR REPLACE VIEW v_raw_value AS
SELECT          c.name AS "collection", c.id_collection AS "collection id",
                a.name AS "action", a.iteration AS "version",
                v.name AS "parameter",
                p.given_name AS "operator_given_name", p.surname AS "operator_surname",
                y.decimal_raw_value AS "y", y.t AS "effect_time", u.name AS "unit"
FROM            collection c
        JOIN    value x ON c.id_collection = x.id_collection
        JOIN    effect j1 on j1.id_effect = x.id_effect
        JOIN    action a ON a.id_action = j1.id_action
        JOIN    parameter v ON v.id_parameter = j1.id_parameter
        JOIN    raw_value y ON y.id_value = x.id_value
        JOIN    person p ON p.id_person = y.id_person
        JOIN    unit u on u.id_unit = y.id_unit
;



/* The address related tables can be cumbersome. The follwing view provides
a flatter table. */
CREATE OR REPLACE VIEW v_address AS
SELECT			  house.id_house AS "__house__id_house",
			  house.number AS "__house__number",
                          house.number_addition AS "__house__number_addition",
			  street.id_street AS "__street__id_street",
			  street.name AS "__street__name",
			  district.id_district AS "__district__id_district",
                          district.name AS "__district__name",
                          district.zip AS "__district__zip",
                          city.id_city AS "__city__id_city",
                          city.name AS "__city__name"
FROM			  house
            JOIN	  street
            ON		  street.id_street = house.id_street
            JOIN	  district
            ON		  district.id_district = street.id_district
            JOIN	  city
            ON		  city.id_city = district.id_city
;
