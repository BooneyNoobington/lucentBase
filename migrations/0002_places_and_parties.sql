/* Postal addresses, organizations and people.

   Addresses are normalized down to the street. Where to put the postal code
   is the tricky part: it is not a property of the city (big cities have many)
   and not of the whole street (long streets cross postal code borders). It is
   a property of a street segment, which is how postal services see streets
   anyway. So a street here is "a street name within one postal code of one
   city", and a long street with two postal codes appears twice. This also
   tells apart the several "Hauptstraße"s a big city can have.

   City districts are left out on purpose: they are not part of a postal
   address in most countries, and streets cross district borders. */


CREATE TABLE country
(
    id_country      INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    iso_code        CHAR(2)         NOT NULL UNIQUE,
    name            VARCHAR(100)    NOT NULL UNIQUE
);


/* City names are not unique, not even within one country. */

CREATE TABLE city
(
    id_city         INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    name            VARCHAR(100)    NOT NULL,
    id_country      INTEGER         NOT NULL,

    FOREIGN KEY (id_country) REFERENCES country (id_country)
);


/* A street within one postal code of one city (see the top of this file).
   Countries without postal codes use an empty postal code. */

CREATE TABLE street
(
    id_street       INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    name            VARCHAR(150)    NOT NULL,
    postal_code     VARCHAR(12)     NOT NULL,
    id_city         INTEGER         NOT NULL,

    CONSTRAINT street_name_postal_code_city_unique UNIQUE(name, postal_code, id_city),

    FOREIGN KEY (id_city) REFERENCES city (id_city)
);


/* One building entrance: a house number in a street. House numbers stay text
   because "12a" and "12-14" are house numbers too. */

CREATE TABLE address
(
    id_address      INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    id_street       INTEGER         NOT NULL,
    house_number    VARCHAR(20)     NOT NULL,

    CONSTRAINT address_street_house_number_unique UNIQUE(id_street, house_number),

    FOREIGN KEY (id_street) REFERENCES street (id_street)
);


/* A company, authority, university institute or any other group of people:
   customers, manufacturers, suppliers and the lab itself. What role an
   organization plays follows from where it is referenced (a customer has
   orders, a manufacturer has devices), so there is no role column. */

CREATE TABLE organization
(
    id_organization     INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    name                VARCHAR(150)    NOT NULL UNIQUE,
    short_name          VARCHAR(30)
);


/* A person: lab staff, customer contacts and private customers.

   db_account is the MariaDB account this person logs in with. It lets the
   database know who is at work without the frontend having to tell it. */

CREATE TABLE person
(
    id_person       INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    given_name      VARCHAR(80)     NOT NULL,
    surname         VARCHAR(80)     NOT NULL,
    email           VARCHAR(254)    UNIQUE,
    db_account      VARCHAR(80)     UNIQUE
);


/* A person works for or belongs to an organization. People can belong to
   several organizations, which is common in academia. */

CREATE TABLE organization_member
(
    id_organization_member  INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    id_organization         INTEGER         NOT NULL,
    id_person               INTEGER         NOT NULL,
    position                VARCHAR(80),

    CONSTRAINT organization_member_unique UNIQUE(id_organization, id_person),

    FOREIGN KEY (id_organization)   REFERENCES organization (id_organization),
    FOREIGN KEY (id_person)         REFERENCES person (id_person)
);


/* The addresses of an organization and what each is used for. */

CREATE TABLE organization_address
(
    id_organization_address     INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    id_organization             INTEGER         NOT NULL,
    id_address                  INTEGER         NOT NULL,
    purpose                     VARCHAR(20)     NOT NULL,

    CONSTRAINT organization_address_purpose_choices CHECK(
        purpose IN ('postal', 'billing', 'delivery', 'visiting')
    ),
    CONSTRAINT organization_address_unique UNIQUE(id_organization, id_address, purpose),

    FOREIGN KEY (id_organization)   REFERENCES organization (id_organization),
    FOREIGN KEY (id_address)        REFERENCES address (id_address)
);


/* The addresses of a person. Mostly needed for private customers; staff and
   customer contacts are reached through their organization. */

CREATE TABLE person_address
(
    id_person_address   INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    id_person           INTEGER         NOT NULL,
    id_address          INTEGER         NOT NULL,
    purpose             VARCHAR(20)     NOT NULL,

    CONSTRAINT person_address_purpose_choices CHECK(
        purpose IN ('postal', 'billing', 'delivery', 'visiting')
    ),
    CONSTRAINT person_address_unique UNIQUE(id_person, id_address, purpose),

    FOREIGN KEY (id_person)     REFERENCES person (id_person),
    FOREIGN KEY (id_address)    REFERENCES address (id_address)
);


/* Addresses as one flat row each, the way they are written on an envelope. */

CREATE VIEW v_address AS
SELECT      address.id_address,
            street.name             AS street,
            address.house_number,
            street.postal_code,
            city.name               AS city,
            country.name            AS country,
            country.iso_code        AS country_code
FROM        address
JOIN        street      ON street.id_street = address.id_street
JOIN        city        ON city.id_city = street.id_city
JOIN        country     ON country.id_country = city.id_country;


DELIMITER $$


/* The person who is logged in, found through person.db_account.
   Returns NULL if the current MariaDB account belongs to nobody. */

CREATE FUNCTION current_person()
RETURNS INTEGER
READS SQL DATA
BEGIN
    RETURN (
        SELECT  id_person
        FROM    person
        WHERE   db_account = SUBSTRING_INDEX(USER(), '@', 1)
    );
END$$

DELIMITER ;
