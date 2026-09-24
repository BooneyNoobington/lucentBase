/* Orders: work the lab does for a customer.

   The name is lab_order because ORDER is a reserved word in SQL. What an order
   asks for is not listed here but in the actions planned for it: every action
   can belong to an order (see action.id_lab_order). */


/* An order from a customer, which is either an organization or a private
   person. For organizations, a contact person can be named. */

CREATE TABLE lab_order
(
    id_lab_order                INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    order_number                VARCHAR(40)     NOT NULL UNIQUE,
    id_customer_organization    INTEGER,
    id_customer_person          INTEGER,
    id_contact_person           INTEGER,
    received_on                 DATE            NOT NULL,
    due_on                      DATE,
    description                 VARCHAR(500),

    CONSTRAINT lab_order_has_one_customer CHECK(
        (id_customer_organization IS NOT NULL AND id_customer_person IS NULL)
        OR
        (id_customer_organization IS NULL AND id_customer_person IS NOT NULL)
    ),
    CONSTRAINT lab_order_contact_needs_organization CHECK(
        id_contact_person IS NULL OR id_customer_organization IS NOT NULL
    ),

    FOREIGN KEY (id_customer_organization)  REFERENCES organization (id_organization),
    FOREIGN KEY (id_customer_person)        REFERENCES person (id_person),
    FOREIGN KEY (id_contact_person)         REFERENCES person (id_person)
);


/* Documents belonging to an order: the customer's request, the quotation. */

CREATE TABLE lab_order_link
(
    id_lab_order_link   INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    id_lab_order        INTEGER         NOT NULL,
    id_link             INTEGER         NOT NULL,

    CONSTRAINT lab_order_link_unique UNIQUE(id_lab_order, id_link),

    FOREIGN KEY (id_lab_order)  REFERENCES lab_order (id_lab_order),
    FOREIGN KEY (id_link)       REFERENCES link (id_link)
);
