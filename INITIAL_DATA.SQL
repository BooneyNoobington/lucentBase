/* Insert initial user as well as other data directly after
database creation. */

-- The initial "lucent" user / admin
INSERT INTO `person` (`given_name`, `surname`, `unix_account`)
VALUES('Testi', 'Testo', 'lucent');

-- Your company, adapt accordingly
INSERT INTO `organization` (`name`, `shorthand`)
VALUES('Redhsoft.org', 'redhsoft');

-- Link lucent to your company
UPDATE `person`SET `id_organization` = (
  SELECT `id_organization` FROM `organization` WHERE `name` = 'Redhsoft.org'
)
WHERE `unix_account` = 'lucent';