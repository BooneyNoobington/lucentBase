/* Insert initial user as well as other data directly after database creation. */


/* The initial "lucent" user / admin. */

INSERT INTO person (given_name, surname, linux_user)
VALUES ('System', 'User', 'grindel');


/* Your company—adapt accordingly. */

INSERT INTO organization (name, shorthand)
VALUES ('Redhsoft.org', 'redhsoft');


/* Link lucent to your company. */

UPDATE person
SET    id_organization = (
           SELECT id_organization
           FROM   organization
           WHERE  name = 'Redhsoft.org'
       )
WHERE  linux_user = 'grindel';


/* The roles front ends and APIs know. */

INSERT INTO role (name, description)
VALUES ('sampler',  'Registers collections.'),
       ('analyst',  'Records raw values.'),
       ('reviewer', 'Accepts and withdraws raw values, except their own.'),
       ('admin',    'May do everything, including managing people, roles and devices.');


/* The initial user administers everything else. */

INSERT INTO j_person_role (id_person, id_role)
SELECT p.id_person, r.id_role
FROM   person p, role r
WHERE  p.linux_user = 'grindel'
AND    r.name = 'admin';
