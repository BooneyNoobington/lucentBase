/* Actions: the lifecycle of a sample.

   An action is one method applied to one sample: taking it, receiving it,
   filtering it, measuring it, disposing of it. Everything that happens to a
   sample is an action, so the list of its actions is its life story, and the
   list of open actions is the work still to be done.

   An action is planned first, then started, then finished or cancelled.
   The database enforces the rules between them:

   - an action only starts when the prerequisite methods of its method have
     finished actions on the sample or on one of its ancestors;
   - a final action (disposal) only starts when nothing else is open on the
     sample, and after it has finished, nothing new can be planned for it;
   - finished and cancelled actions do not change any more.

   Planning an action also plans the actions its method implies; that happens
   in the procedure plan_action (0010_workflow_procedures.sql), because a
   trigger cannot insert into its own table.

   In OMS terms, a sampling action is a Sampling, a preparation action a
   PreparationStep, and an observation action is the shared context (feature
   of interest, procedure, observer, time) of the Observations it produces. */


CREATE TABLE action
(
    id_action               INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    id_sample               INTEGER         NOT NULL,
    id_method_version       INTEGER         NOT NULL,
    id_lab_order            INTEGER,
    id_implied_by_action    INTEGER,
    id_assignee             INTEGER,
    id_performer            INTEGER,
    due_at                  TIMESTAMP       NULL,
    planned_at              TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    started_at              TIMESTAMP       NULL,
    finished_at             TIMESTAMP       NULL,
    cancelled_at            TIMESTAMP       NULL,
    note                    VARCHAR(1000),
    status                  VARCHAR(10)     AS (
                                CASE
                                    WHEN cancelled_at IS NOT NULL THEN 'cancelled'
                                    WHEN finished_at IS NOT NULL THEN 'finished'
                                    WHEN started_at IS NOT NULL THEN 'started'
                                    ELSE 'planned'
                                END
                            ) VIRTUAL,

    CONSTRAINT action_finish_needs_start CHECK(
        finished_at IS NULL OR started_at IS NOT NULL
    ),
    CONSTRAINT action_finishes_after_start CHECK(
        finished_at >= started_at
    ),
    CONSTRAINT action_is_not_finished_and_cancelled CHECK(
        finished_at IS NULL OR cancelled_at IS NULL
    ),
    CONSTRAINT cancelled_action_has_note CHECK(
        cancelled_at IS NULL OR note IS NOT NULL
    ),

    FOREIGN KEY (id_sample)             REFERENCES sample (id_sample),
    FOREIGN KEY (id_method_version)     REFERENCES method_version (id_method_version),
    FOREIGN KEY (id_lab_order)          REFERENCES lab_order (id_lab_order),
    FOREIGN KEY (id_implied_by_action)  REFERENCES action (id_action),
    FOREIGN KEY (id_assignee)           REFERENCES person (id_person),
    FOREIGN KEY (id_performer)          REFERENCES person (id_person)
);


/* Devices used in an action (OMS: Sampler or Observer). */

CREATE TABLE action_device
(
    id_action_device    INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    id_action           INTEGER         NOT NULL,
    id_device           INTEGER         NOT NULL,

    CONSTRAINT action_device_unique UNIQUE(id_action, id_device),

    FOREIGN KEY (id_action) REFERENCES action (id_action),
    FOREIGN KEY (id_device) REFERENCES device (id_device)
);


/* Documents produced in an action: raw data files, photos, field protocols. */

CREATE TABLE action_link
(
    id_action_link      INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    id_action           INTEGER         NOT NULL,
    id_link             INTEGER         NOT NULL,

    CONSTRAINT action_link_unique UNIQUE(id_action, id_link),

    FOREIGN KEY (id_action) REFERENCES action (id_action),
    FOREIGN KEY (id_link)   REFERENCES link (id_link)
);


DELIMITER $$


/* The names of the prerequisite methods that have no finished action yet on
   the sample or its ancestors, separated by commas. NULL if nothing is
   missing, so the action may start. */

CREATE FUNCTION missing_prerequisites(p_id_sample INTEGER, p_id_method INTEGER)
RETURNS VARCHAR(2000)
READS SQL DATA
BEGIN
    RETURN (
        WITH RECURSIVE lineage (id_sample) AS
        (
            SELECT  p_id_sample
            UNION
            SELECT  sample_source.id_source_sample
            FROM    sample_source
            JOIN    lineage     ON sample_source.id_sample = lineage.id_sample
        )
        SELECT      GROUP_CONCAT(prerequisite.name ORDER BY prerequisite.name SEPARATOR ', ')
        FROM        method_prerequisite
        JOIN        method AS prerequisite
                        ON prerequisite.id_method = method_prerequisite.id_prerequisite_method
        WHERE       method_prerequisite.id_method = p_id_method
          AND       NOT EXISTS (
                        SELECT  1
                        FROM    action
                        JOIN    method_version
                                    ON method_version.id_method_version = action.id_method_version
                        WHERE   method_version.id_method = method_prerequisite.id_prerequisite_method
                          AND   action.finished_at IS NOT NULL
                          AND   action.id_sample IN (SELECT id_sample FROM lineage)
                    )
    );
END$$


/* The finished final action (e.g. disposal) of a sample, or NULL if the
   sample is still open. */

CREATE FUNCTION closing_action_of(p_id_sample INTEGER)
RETURNS INTEGER
READS SQL DATA
BEGIN
    RETURN (
        SELECT      action.id_action
        FROM        action
        JOIN        method_version  ON method_version.id_method_version = action.id_method_version
        JOIN        method          ON method.id_method = method_version.id_method
        WHERE       action.id_sample = p_id_sample
          AND       action.finished_at IS NOT NULL
          AND       method.is_final
        LIMIT       1
    );
END$$


/* Is a method version already used by an action? Then it must not change any
   more, or old results would suddenly have been made by a different method. */

CREATE FUNCTION method_version_in_use(p_id_method_version INTEGER)
RETURNS BOOLEAN
READS SQL DATA
BEGIN
    RETURN EXISTS (
        SELECT  1
        FROM    action
        WHERE   id_method_version = p_id_method_version
    );
END$$


/* New actions start out planned, on a sample that is still open, with a
   method that is not retired. */

CREATE TRIGGER action_before_insert
BEFORE INSERT ON action
FOR EACH ROW
BEGIN
    DECLARE v_message VARCHAR(500);

    IF NEW.started_at IS NOT NULL OR NEW.finished_at IS NOT NULL OR NEW.cancelled_at IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'New actions are planned actions. Start, finish or cancel them afterwards.';
    END IF;

    IF closing_action_of(NEW.id_sample) IS NOT NULL THEN
        SET v_message = CONCAT('Sample ', (SELECT code FROM sample WHERE id_sample = NEW.id_sample),
                               ' is closed by action ', closing_action_of(NEW.id_sample),
                               '; nothing more can be planned for it.');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_message;
    END IF;

    IF (SELECT method.retired_at
        FROM   method_version
        JOIN   method   ON method.id_method = method_version.id_method
        WHERE  method_version.id_method_version = NEW.id_method_version) IS NOT NULL
    THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'This method is retired and cannot be planned any more.';
    END IF;
END$$


CREATE TRIGGER action_before_update
BEFORE UPDATE ON action
FOR EACH ROW
BEGIN
    DECLARE v_id_method     INTEGER;
    DECLARE v_missing       VARCHAR(2000);
    DECLARE v_open_actions  VARCHAR(2000);
    DECLARE v_message       VARCHAR(2500);

    SELECT  id_method
    INTO    v_id_method
    FROM    method_version
    WHERE   id_method_version = NEW.id_method_version;

    /* Finished and cancelled actions are history. Only the note may still be
       amended. */

    IF OLD.finished_at IS NOT NULL OR OLD.cancelled_at IS NOT NULL THEN
        IF NOT (    NEW.id_sample <=> OLD.id_sample
                AND NEW.id_method_version <=> OLD.id_method_version
                AND NEW.id_lab_order <=> OLD.id_lab_order
                AND NEW.id_implied_by_action <=> OLD.id_implied_by_action
                AND NEW.id_assignee <=> OLD.id_assignee
                AND NEW.id_performer <=> OLD.id_performer
                AND NEW.due_at <=> OLD.due_at
                AND NEW.planned_at <=> OLD.planned_at
                AND NEW.started_at <=> OLD.started_at
                AND NEW.finished_at <=> OLD.finished_at
                AND NEW.cancelled_at <=> OLD.cancelled_at)
        THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Finished and cancelled actions cannot be changed, except for their note.';
        END IF;
    END IF;

    IF NOT (NEW.id_sample <=> OLD.id_sample) OR NOT (NEW.planned_at <=> OLD.planned_at) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'The sample and planning time of an action cannot be changed. Cancel it and plan a new one.';
    END IF;

    IF OLD.started_at IS NOT NULL AND NOT (NEW.started_at <=> OLD.started_at) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'The start of an action cannot be changed once it is recorded.';
    END IF;

    IF NOT (NEW.id_method_version <=> OLD.id_method_version) THEN
        IF OLD.started_at IS NOT NULL THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'The method version of a started action cannot be changed.';
        END IF;
        IF v_id_method <> (SELECT id_method FROM method_version WHERE id_method_version = OLD.id_method_version) THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'An action can only switch to another version of the same method.';
        END IF;
    END IF;

    /* The moment an action starts, its prerequisites must be met. */

    IF OLD.started_at IS NULL AND NEW.started_at IS NOT NULL THEN

        IF closing_action_of(NEW.id_sample) IS NOT NULL THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'The sample is closed; no action can start on it any more.';
        END IF;

        SET v_missing = missing_prerequisites(NEW.id_sample, v_id_method);
        IF v_missing IS NOT NULL THEN
            SET v_message = CONCAT('This action cannot start before these methods are finished on the sample: ',
                                   v_missing, '.');
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_message;
        END IF;

        IF (SELECT is_final FROM method WHERE id_method = v_id_method) THEN
            SELECT  GROUP_CONCAT(other.id_action ORDER BY other.id_action SEPARATOR ', ')
            INTO    v_open_actions
            FROM    action AS other
            WHERE   other.id_sample = NEW.id_sample
              AND   other.id_action <> NEW.id_action
              AND   other.finished_at IS NULL
              AND   other.cancelled_at IS NULL;

            IF v_open_actions IS NOT NULL THEN
                SET v_message = CONCAT('This action closes the sample, but these actions are still open on it: ',
                                       v_open_actions, '. Finish or cancel them first.');
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_message;
            END IF;
        END IF;
    END IF;
END$$


CREATE TRIGGER action_before_delete
BEFORE DELETE ON action
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Actions are never deleted. Cancel the action instead.';
END$$


/* A wrong sample source may be removed until work on the sample starts.
   After that, the lineage is part of the record of that work (prerequisites
   were checked against it). */

CREATE TRIGGER sample_source_before_delete
BEFORE DELETE ON sample_source
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM action WHERE id_sample = OLD.id_sample AND started_at IS NOT NULL) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Work on this sample has started; its sources cannot be removed any more.';
    END IF;
END$$


/* Method versions that actions have used are frozen: their properties and
   formulas cannot change. Create a new version instead. */

CREATE PROCEDURE check_method_version_unused(p_id_method_version INTEGER)
BEGIN
    DECLARE v_message VARCHAR(500);

    IF method_version_in_use(p_id_method_version) THEN
        SET v_message = CONCAT('Method version ', p_id_method_version,
                               ' has been used by actions and cannot change. Create a new version instead.');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_message;
    END IF;
END$$


CREATE TRIGGER method_version_frozen_before_update
BEFORE UPDATE ON method_version
FOR EACH ROW
BEGIN
    IF NOT (NEW.id_method <=> OLD.id_method) OR NOT (NEW.valid_from <=> OLD.valid_from) THEN
        CALL check_method_version_unused(OLD.id_method_version);
    END IF;
END$$


CREATE TRIGGER method_property_frozen_before_insert
BEFORE INSERT ON method_property
FOR EACH ROW
BEGIN
    CALL check_method_version_unused(NEW.id_method_version);
END$$


CREATE TRIGGER method_property_frozen_before_update
BEFORE UPDATE ON method_property
FOR EACH ROW
BEGIN
    CALL check_method_version_unused(OLD.id_method_version);
    CALL check_method_version_unused(NEW.id_method_version);
END$$


CREATE TRIGGER method_property_frozen_before_delete
BEFORE DELETE ON method_property
FOR EACH ROW
BEGIN
    CALL check_method_version_unused(OLD.id_method_version);
END$$


CREATE PROCEDURE check_formula_unused(p_id_method_property INTEGER)
BEGIN
    DECLARE v_id_method_version INTEGER;

    SELECT  id_method_version
    INTO    v_id_method_version
    FROM    method_property
    WHERE   id_method_property = p_id_method_property;

    CALL check_method_version_unused(v_id_method_version);
END$$


CREATE TRIGGER formula_input_frozen_before_insert
BEFORE INSERT ON formula_input
FOR EACH ROW
BEGIN
    CALL check_formula_unused(NEW.id_method_property);
END$$


CREATE TRIGGER formula_input_frozen_before_update
BEFORE UPDATE ON formula_input
FOR EACH ROW
BEGIN
    CALL check_formula_unused(OLD.id_method_property);
    CALL check_formula_unused(NEW.id_method_property);
END$$


CREATE TRIGGER formula_input_frozen_before_delete
BEFORE DELETE ON formula_input
FOR EACH ROW
BEGIN
    CALL check_formula_unused(OLD.id_method_property);
END$$

DELIMITER ;
