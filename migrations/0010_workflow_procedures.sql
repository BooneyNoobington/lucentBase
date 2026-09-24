/* The everyday workflow as procedures: plan, start, finish, cancel, review.

   The rules themselves live in triggers (0007, 0008), so they also hold for
   anyone who writes to the tables directly. These procedures add what a
   trigger cannot do: planning implied actions, cascading cancellations and
   running calculations. Anyone working with the database alone, without a
   frontend, should use them the same way a frontend would:

       CALL plan_action(<sample>, <method>, <order>, <assignee>, <due>, @id);
       CALL start_action(@id, <performer>, NULL);
       INSERT INTO observation (id_action, id_observed_property, result_numeric)
           VALUES (@id, <property>, 7.2);
       CALL finish_action(@id, NULL);
       CALL review_action(@id, <reviewer>);

   Persons may be left NULL; then the person linked to the current database
   account (person.db_account) is used. Times may be left NULL for "now". */


DELIMITER $$


/* Plans an action of the current version of a method on a sample, plus every
   action its method implies, directly or indirectly, unless the sample
   already has an action of that method that is not cancelled. Implied
   actions belong to the same order and point back to the action that caused
   them. The id of the new action is returned in p_id_action. */

CREATE PROCEDURE plan_action(
    IN  p_id_sample     INTEGER,
    IN  p_id_method     INTEGER,
    IN  p_id_lab_order  INTEGER,
    IN  p_id_assignee   INTEGER,
    IN  p_due_at        TIMESTAMP,
    OUT p_id_action     INTEGER
)
MODIFIES SQL DATA
BEGIN
    DECLARE v_id_method_version INTEGER;
    DECLARE v_without_version   VARCHAR(2000);
    DECLARE v_message           VARCHAR(2500);

    SET v_id_method_version = current_method_version(p_id_method);
    IF v_id_method_version IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'This method has no version that is valid now, or it is retired.';
    END IF;

    CREATE OR REPLACE TEMPORARY TABLE planning_implied_method
    (
        id_method   INTEGER     PRIMARY KEY
    );

    INSERT INTO planning_implied_method (id_method)
    WITH RECURSIVE implied (id_method) AS
    (
        SELECT  id_implied_method
        FROM    method_implication
        WHERE   id_method = p_id_method
        UNION
        SELECT  method_implication.id_implied_method
        FROM    method_implication
        JOIN    implied     ON method_implication.id_method = implied.id_method
    )
    SELECT  id_method
    FROM    implied
    WHERE   id_method <> p_id_method;

    DELETE FROM planning_implied_method
    WHERE  id_method IN (
               SELECT  method_version.id_method
               FROM    action
               JOIN    method_version  ON method_version.id_method_version = action.id_method_version
               WHERE   action.id_sample = p_id_sample
                 AND   action.cancelled_at IS NULL
           );

    SET v_without_version = (
        SELECT  GROUP_CONCAT(method.name ORDER BY method.name SEPARATOR ', ')
        FROM    planning_implied_method
        JOIN    method  ON method.id_method = planning_implied_method.id_method
        WHERE   current_method_version(planning_implied_method.id_method) IS NULL
    );
    IF v_without_version IS NOT NULL THEN
        SET v_message = CONCAT('These implied methods have no valid version or are retired: ',
                               v_without_version, '.');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_message;
    END IF;

    INSERT INTO action (id_sample, id_method_version, id_lab_order, id_assignee, due_at)
    VALUES (p_id_sample, v_id_method_version, p_id_lab_order, p_id_assignee, p_due_at);
    SET p_id_action = LAST_INSERT_ID();

    INSERT INTO action (id_sample, id_method_version, id_lab_order, id_implied_by_action)
    SELECT      p_id_sample, current_method_version(id_method), p_id_lab_order, p_id_action
    FROM        planning_implied_method
    ORDER BY    id_method;

    DROP TEMPORARY TABLE planning_implied_method;
END$$


/* Starts a planned action. The trigger on action checks the prerequisites. */

CREATE PROCEDURE start_action(
    p_id_action     INTEGER,
    p_id_performer  INTEGER,
    p_started_at    TIMESTAMP
)
MODIFIES SQL DATA
BEGIN
    IF NOT ((SELECT status FROM action WHERE id_action = p_id_action) <=> 'planned') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Only planned actions can start.';
    END IF;

    UPDATE  action
    SET     started_at = COALESCE(p_started_at, CURRENT_TIMESTAMP),
            id_performer = COALESCE(p_id_performer, id_performer, current_person())
    WHERE   id_action = p_id_action;
END$$


/* Finishes a started action: runs its calculations first, then marks it
   finished. The trigger on action refuses if required results are missing. */

CREATE PROCEDURE finish_action(
    p_id_action     INTEGER,
    p_finished_at   TIMESTAMP
)
MODIFIES SQL DATA
BEGIN
    IF NOT ((SELECT status FROM action WHERE id_action = p_id_action) <=> 'started') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Only started actions can finish.';
    END IF;

    CALL calculate_action(p_id_action);

    UPDATE  action
    SET     finished_at = COALESCE(p_finished_at, CURRENT_TIMESTAMP)
    WHERE   id_action = p_id_action;
END$$


/* Cancels an open action, with a reason. Actions it implied that have not
   started yet are cancelled with it. */

CREATE PROCEDURE cancel_action(
    p_id_action     INTEGER,
    p_reason        VARCHAR(500)
)
MODIFIES SQL DATA
BEGIN
    IF TRIM(COALESCE(p_reason, '')) = '' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Please give a reason for the cancellation.';
    END IF;

    IF (SELECT status FROM action WHERE id_action = p_id_action) NOT IN ('planned', 'started') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Only planned or started actions can be cancelled.';
    END IF;

    UPDATE  action
    SET     cancelled_at = CURRENT_TIMESTAMP,
            note = CONCAT_WS(' ', note, CONCAT('Cancelled: ', p_reason))
    WHERE   id_action = p_id_action;

    UPDATE  action
    SET     cancelled_at = CURRENT_TIMESTAMP,
            note = CONCAT_WS(' ', note, CONCAT('Cancelled together with action ', p_id_action, '.'))
    WHERE   id_implied_by_action = p_id_action
      AND   started_at IS NULL
      AND   cancelled_at IS NULL;
END$$


/* Releases all valid results of a finished action. Refuses if one of its
   calculated results is stale. */

CREATE PROCEDURE review_action(
    p_id_action     INTEGER,
    p_id_reviewer   INTEGER
)
MODIFIES SQL DATA
BEGIN
    DECLARE v_id_reviewer INTEGER;

    SET v_id_reviewer = COALESCE(p_id_reviewer, current_person());

    IF v_id_reviewer IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Who is reviewing? Pass a person, or link your database account to a person.';
    END IF;

    IF NOT ((SELECT status FROM action WHERE id_action = p_id_action) <=> 'finished') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Only finished actions can be reviewed.';
    END IF;

    IF EXISTS (SELECT 1 FROM v_stale_calculation WHERE id_action = p_id_action) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Some calculated results of this action are stale. Recalculate them first.';
    END IF;

    UPDATE  observation
    SET     reviewed_at = CURRENT_TIMESTAMP,
            id_reviewer = v_id_reviewer
    WHERE   id_action = p_id_action
      AND   invalidated_at IS NULL
      AND   reviewed_at IS NULL;
END$$


/* Withdraws a result, with a reason. */

CREATE PROCEDURE invalidate_observation(
    p_id_observation    INTEGER,
    p_reason            VARCHAR(500)
)
MODIFIES SQL DATA
BEGIN
    IF TRIM(COALESCE(p_reason, '')) = '' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Please give a reason for the invalidation.';
    END IF;

    UPDATE  observation
    SET     invalidated_at = CURRENT_TIMESTAMP,
            invalidation_reason = p_reason
    WHERE   id_observation = p_id_observation
      AND   invalidated_at IS NULL;

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'There is no valid result with this id.';
    END IF;
END$$

DELIMITER ;


/* Actions whose method implies another method that has no action on the
   same sample. plan_action() never leaves such gaps, but actions inserted
   directly into the table can. */

CREATE VIEW v_missing_implied_action AS
SELECT DISTINCT
            action.id_sample,
            action.id_action            AS id_implying_action,
            method_implication.id_implied_method
FROM        action
JOIN        method_version      ON method_version.id_method_version = action.id_method_version
JOIN        method_implication  ON method_implication.id_method = method_version.id_method
WHERE       action.cancelled_at IS NULL
  AND       NOT EXISTS (
                SELECT  1
                FROM    action AS implied_action
                JOIN    method_version AS implied_version
                            ON implied_version.id_method_version = implied_action.id_method_version
                WHERE   implied_action.id_sample = action.id_sample
                  AND   implied_version.id_method = method_implication.id_implied_method
                  AND   implied_action.cancelled_at IS NULL
            );
