-- Insert the link first.
INSERT INTO `link` (`name`, `url`) VALUES('Generic Sampling Wikipedia Description', 'https://de.wikipedia.org/wiki/Probenahme');

-- Then the sop.
INSERT INTO `sop` (`name`) VALUES('Generic Sampling');

-- Relate the sop to the link.
INSERT INTO `j_sop_link` (`id_sop`, `id_link`) VALUES(
	(SELECT `id_sop` FROM `sop` WHERE `name` = 'Generic Sampling')
  , (SELECT `id_link` FROM `link` WHERE `name` = 'Generic Sampling Wikipedia Description')
);
  
-- Create an action.
INSERT INTO `action` (`name`, `iteration`, `active`, `description`, `id_sop`)
VALUES(
	'Generic Sampling'
  , STR_TO_DATE('22.10.2023', '%d.%m.%Y')
  , TRUE
  , 'Generic Aquisition of Sample'
  , (SELECT id_sop FROM sop WHERE name = 'Generic Sampling')
);

-- Create two variables for this action.
INSERT INTO `dimension` (`name`, `description`) VALUES('temperature', 'movement of particles');

INSERT INTO `variable` (`name`, `value_class`, `description`, `id_dimension`)
VALUES(
	'water temperature'
  , 'decimal'
  , 'temperature of a body of water measured on site'
  , (SELECT `id_dimension` FROM `dimension` WHERE `name` = 'temperature')
);

INSERT INTO `dimension` (`name`, `description`) VALUES('time', 'the flow of entropy');

INSERT INTO `variable` (`name`, `value_class`, `description`, `id_dimension`)
VALUES(
	'sampling date'
  , 'datetime'
  , 'the moment a sample was taken.'
  , (SELECT `id_dimension` FROM `dimension` WHERE `name` = 'time')
);


-- Relate the variables to actions.

-- Create units for temperature and time.
INSERT INTO `unit` (`name`, `description`, `id_dimension`) VALUES('°C', 'degrees celsius', 1);
INSERT INTO `unit` (`name`, `description`, `id_dimension`) VALUES('date and time', 'statement of a date and a time of day', 2);
INSERT INTO `unit` (`name`, `description`, `id_dimension`) VALUES('s', 'second', 2);

INSERT INTO `j_action_variable`
(
	`id_action`
  , `id_variable`
  , `uncertainty`
  , `uncertainty_class`
  , `uncertainty_unit`
  , `calculation`
)

VALUES
(
	1  -- Generic Sampling
  , 1  -- degrees celsius
  , 0.1  -- Standard for a PT100
  , 'absolute'
  , 1
  , 'generic raw to value'
);



INSERT INTO `j_action_variable`
(
	`id_action`
  , `id_variable`
  , `uncertainty`
  , `uncertainty_class`
  , `uncertainty_unit`
  , `calculation`
)

VALUES
(
	1  -- Generic Sampling
  , 2  -- date and time
  , 120  -- two minues = 120 seconds.
  , 'absolute'
  , 3
  , 'generic raw to value'
);







-- Create another action.

-- Insert the link first.
INSERT INTO `link` (`name`, `file_path`, `SHA256`) VALUES('recieve sample', 'K:\\SOPs\\Sample Reception.docx', '68808301a89ae4c64bfabc40f20ff45157c2cb87b9d03fdf2d77554e4');

-- Then the sop.
INSERT INTO `sop` (`name`) VALUES('sample reception');

-- Relate the sop to the link.
INSERT INTO `j_sop_link` (`id_sop`, `id_link`) VALUES(
	(SELECT `id_sop` FROM `sop` WHERE `name` = 'sample reception')
  , (SELECT `id_link` FROM `link` WHERE `name` = 'recieve sample')
);
  
-- Create an action.
INSERT INTO `action` (`name`, `iteration`, `active`, `description`, `id_sop`)
VALUES(
	'recieve sample'
  , STR_TO_DATE('20.10.2023', '%d.%m.%Y')
  , TRUE
  , 'handling of sample when arriving in lab'
  , (SELECT id_sop FROM sop WHERE name = 'sample reception')
);


INSERT INTO `variable` (`name`, `value_class`, `description`, `id_dimension`)
VALUES(
	'reception time'
  , 'datetime'
  , 'the moment a sample was recieved in the lab'
  , (SELECT `id_dimension` FROM `dimension` WHERE `name` = 'time')
);


INSERT INTO `variable` (`name`, `value_class`, `description`)
VALUES(
	'filtration completed'
  , 'boolean'
  , 'Was a filtration performed?'
);

INSERT INTO `variable` (`name`, `value_class`, `description`)
VALUES(
	'sub sample created'
  , 'integer'
  , 'id of the created sub sample after filtration.'
);