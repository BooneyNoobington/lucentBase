/* If the `person` table changes, transfer the changes on the
field `vis` to all the junction tables that connect `person` to
other tables. */
DELIMITER $$
CREATE TRIGGER `follow_person_vis`
AFTER UPDATE ON `person`
FOR EACH ROW
BEGIN
    -- Check if the vis column in `person` is updated.
    IF NEW.vis <> OLD.vis THEN
        -- Update vis in all ju"nction tables 
        -- connected to `person` based on the change in person.
        UPDATE `j_person_house` SET `vis` = NEW.`vis` WHERE `id_person` = NEW.`id_person`;
        UPDATE `j_person_organisation` SET `vis` = NEW.`vis` WHERE `id_person` = NEW.`id_person`;
        UPDATE `j_sop_person` SET `vis` = NEW.`vis` WHERE `id_person` = NEW.`id_person`;
        UPDATE `j_action_person` SET `vis` = NEW.`vis` WHERE `id_person` = NEW.`id_person`;
        -- ...
    END IF;
END;
$$



/* Same as in `person` but with `house` */
DELIMITER $$

CREATE TRIGGER `follow_house_vis`
AFTER UPDATE ON `house`
FOR EACH ROW
BEGIN
    -- Check if the vis column in house is updated
    IF NEW.`vis` <> OLD.`vis` THEN
        -- Update all junction tables.
        UPDATE `j_person_house` SET `vis` = NEW.`vis` WHERE `id_house` = NEW.`id_house`;
        -- ...
    END IF;
END;
$$

DELIMITER ;



/* When an sop is "recycled", do the same with the links it is
connected to. */
DELIMITER $$

CREATE TRIGGER `follow_sop_vis`
AFTER UPDATE ON `sop`
FOR EACH ROW
BEGIN
    -- Check if the vis column in house is updated
    IF NEW.`vis` <> OLD.`vis` THEN
        -- Update all junction tables.
        UPDATE `j_sop_link` SET `vis` = NEW.`vis` WHERE `id_sop` = NEW.`id_sop`;
        -- ...
    END IF;
END;
$$

DELIMITER ;



/* The same the other way around. */
DELIMITER $$

CREATE TRIGGER `follow_link_vis`
AFTER UPDATE ON `link`
FOR EACH ROW
BEGIN
    -- Check if the vis column in house is updated
    IF NEW.`vis` <> OLD.`vis` THEN
        -- Update all junction tables.
        UPDATE `j_sop_link` SET `vis` = NEW.`vis` WHERE `id_link` = NEW.`id_link`;
        -- ...
    END IF;
END;
$$

DELIMITER ;



/* When an action is "recycled", do the same with all the
junctions it is connected to. */
DELIMITER $$

CREATE TRIGGER `follow_action_vis`
AFTER UPDATE ON `action`
FOR EACH ROW
BEGIN
    -- Check if the vis column in house is updated
    IF NEW.`vis` <> OLD.`vis` THEN
        -- Update all junction tables.
        UPDATE `j_action_person` SET `vis` = NEW.`vis` WHERE `id_sop` = NEW.`id_sop`;
        UPDATE `j_action_object` SET `vis` = NEW.`vis` WHERE `id_sop` = NEW.`id_sop`;        
		UPDATE `j_action_collectionclass` SET `vis` = NEW.`vis` WHERE `id_sop` = NEW.`id_sop`;    
        -- ...
    END IF;
END;
$$

DELIMITER ;