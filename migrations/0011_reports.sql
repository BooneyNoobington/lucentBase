/* Reports: what the lab told its customer.

   Results are displayed on the fly (format_result), but a report is a
   document that has been sent out; what it said must never change afterwards.
   So when a report is issued, each reported result is frozen in
   reported_result, exactly as it was printed. That is not a duplicate of the
   observation: "on 3 March we reported < 0.05 mg/L" is a fact of its own.

   When a reported result is later invalidated or goes stale, the report is
   listed in v_report_needing_amendment. The amended report is a new report
   that replaces the old one. The PDF itself lives in a document system and
   is referenced through link. */


/* A report for an order. It is a draft until issued_at is set. */

CREATE TABLE report
(
    id_report               INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    id_lab_order            INTEGER         NOT NULL,
    report_number           VARCHAR(40)     NOT NULL UNIQUE,
    id_replaced_report      INTEGER         UNIQUE,
    created_at              TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    issued_at               TIMESTAMP       NULL,
    id_issuer               INTEGER,
    id_link                 INTEGER,

    CONSTRAINT report_issue_is_complete CHECK(
        (issued_at IS NULL AND id_issuer IS NULL)
        OR
        (issued_at IS NOT NULL AND id_issuer IS NOT NULL)
    ),

    FOREIGN KEY (id_lab_order)          REFERENCES lab_order (id_lab_order),
    FOREIGN KEY (id_replaced_report)    REFERENCES report (id_report),
    FOREIGN KEY (id_issuer)             REFERENCES person (id_person),
    FOREIGN KEY (id_link)               REFERENCES link (id_link)
);


/* A result as it was printed in an issued report. */

CREATE TABLE reported_result
(
    id_reported_result  INTEGER         PRIMARY KEY NOT NULL AUTO_INCREMENT,
    id_report           INTEGER         NOT NULL,
    id_observation      INTEGER         NOT NULL,
    reported_text       VARCHAR(1000)   NOT NULL,
    id_unit             INTEGER,

    CONSTRAINT reported_result_unique UNIQUE(id_report, id_observation),

    FOREIGN KEY (id_report)         REFERENCES report (id_report),
    FOREIGN KEY (id_observation)    REFERENCES observation (id_observation),
    FOREIGN KEY (id_unit)           REFERENCES unit (id_unit)
);


DELIMITER $$


/* A report can only replace an issued report of the same order. */

CREATE TRIGGER report_before_insert
BEFORE INSERT ON report
FOR EACH ROW
BEGIN
    IF NEW.issued_at IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'New reports are drafts. Issue them with issue_report().';
    END IF;

    IF NEW.id_replaced_report IS NOT NULL
       AND NOT EXISTS (
           SELECT  1
           FROM    report
           WHERE   id_report = NEW.id_replaced_report
             AND   id_lab_order = NEW.id_lab_order
             AND   issued_at IS NOT NULL
       )
    THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A report can only replace an issued report of the same order.';
    END IF;
END$$


/* An issued report does not change. Only the link to its document may still
   be filled in, once. */

CREATE TRIGGER report_before_update
BEFORE UPDATE ON report
FOR EACH ROW
BEGIN
    IF OLD.issued_at IS NOT NULL
       AND NOT (    NEW.id_lab_order <=> OLD.id_lab_order
                AND NEW.report_number <=> OLD.report_number
                AND NEW.id_replaced_report <=> OLD.id_replaced_report
                AND NEW.created_at <=> OLD.created_at
                AND NEW.issued_at <=> OLD.issued_at
                AND NEW.id_issuer <=> OLD.id_issuer
                AND (NEW.id_link <=> OLD.id_link OR OLD.id_link IS NULL))
    THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'An issued report cannot be changed. Issue a new report that replaces it.';
    END IF;
END$$


CREATE TRIGGER report_before_delete
BEFORE DELETE ON report
FOR EACH ROW
BEGIN
    IF OLD.issued_at IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Issued reports are never deleted.';
    END IF;
END$$


CREATE PROCEDURE check_report_is_draft(p_id_report INTEGER)
BEGIN
    IF (SELECT issued_at FROM report WHERE id_report = p_id_report) IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'The results of an issued report cannot be changed.';
    END IF;
END$$


CREATE TRIGGER reported_result_before_insert
BEFORE INSERT ON reported_result
FOR EACH ROW
BEGIN
    CALL check_report_is_draft(NEW.id_report);
END$$


CREATE TRIGGER reported_result_before_update
BEFORE UPDATE ON reported_result
FOR EACH ROW
BEGIN
    CALL check_report_is_draft(OLD.id_report);
    CALL check_report_is_draft(NEW.id_report);
END$$


CREATE TRIGGER reported_result_before_delete
BEFORE DELETE ON reported_result
FOR EACH ROW
BEGIN
    CALL check_report_is_draft(OLD.id_report);
END$$


/* Issues a draft report: freezes every valid, reviewed result of a reported
   property from the finished actions of the order, as format_result() writes
   it, and marks the report as issued.

   Refuses while results of the order still wait for review, or while any of
   its calculated results is stale. */

CREATE PROCEDURE issue_report(
    p_id_report     INTEGER,
    p_id_issuer     INTEGER
)
MODIFIES SQL DATA
BEGIN
    DECLARE v_id_lab_order  INTEGER;
    DECLARE v_id_issuer     INTEGER;
    DECLARE v_unreviewed    INTEGER;

    SET v_id_lab_order = (SELECT id_lab_order FROM report WHERE id_report = p_id_report);
    SET v_id_issuer = COALESCE(p_id_issuer, current_person());

    IF v_id_lab_order IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'There is no report with this id.';
    END IF;

    IF v_id_issuer IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Who issues the report? Pass a person, or link your database account to a person.';
    END IF;

    CALL check_report_is_draft(p_id_report);

    IF EXISTS (
        SELECT  1
        FROM    v_stale_calculation
        JOIN    action  ON action.id_action = v_stale_calculation.id_action
        WHERE   action.id_lab_order = v_id_lab_order
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Some calculated results of this order are stale. Recalculate them first.';
    END IF;

    SET v_unreviewed = (
        SELECT  COUNT(*)
        FROM    observation
        JOIN    action              ON action.id_action = observation.id_action
        JOIN    method_property     ON method_property.id_method_version = action.id_method_version
                                   AND method_property.id_observed_property = observation.id_observed_property
        WHERE   action.id_lab_order = v_id_lab_order
          AND   action.finished_at IS NOT NULL
          AND   method_property.is_reported
          AND   observation.invalidated_at IS NULL
          AND   observation.reviewed_at IS NULL
    );
    IF v_unreviewed > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Some results of this order have not been reviewed yet.';
    END IF;

    DELETE FROM reported_result WHERE id_report = p_id_report;

    INSERT INTO reported_result (id_report, id_observation, reported_text, id_unit)
    SELECT      p_id_report,
                observation.id_observation,
                format_result(observation.id_observation),
                IF(observed_property.result_type = 'numeric', method_property.id_unit, NULL)
    FROM        observation
    JOIN        action              ON action.id_action = observation.id_action
    JOIN        method_property     ON method_property.id_method_version = action.id_method_version
                                   AND method_property.id_observed_property = observation.id_observed_property
    JOIN        observed_property   ON observed_property.id_observed_property = observation.id_observed_property
    WHERE       action.id_lab_order = v_id_lab_order
      AND       action.finished_at IS NOT NULL
      AND       method_property.is_reported
      AND       observation.invalidated_at IS NULL
      AND       observation.reviewed_at IS NOT NULL
    ORDER BY    observation.id_observation;

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'There are no reviewed results to report for this order yet.';
    END IF;

    UPDATE  report
    SET     issued_at = CURRENT_TIMESTAMP,
            id_issuer = v_id_issuer
    WHERE   id_report = p_id_report;
END$$

DELIMITER ;


/* Issued reports that are still in force (no issued report replaces them)
   but contain a result that has since been invalidated or gone stale. */

CREATE VIEW v_report_needing_amendment AS
SELECT      report.id_report,
            report.report_number,
            reported_result.id_observation,
            'A reported result has been invalidated.' AS reason
FROM        report
JOIN        reported_result     ON reported_result.id_report = report.id_report
JOIN        observation         ON observation.id_observation = reported_result.id_observation
WHERE       report.issued_at IS NOT NULL
  AND       observation.invalidated_at IS NOT NULL
  AND       NOT EXISTS (
                SELECT  1
                FROM    report AS amendment
                WHERE   amendment.id_replaced_report = report.id_report
                  AND   amendment.issued_at IS NOT NULL
            )

UNION

SELECT      report.id_report,
            report.report_number,
            reported_result.id_observation,
            'A reported result is stale.'
FROM        report
JOIN        reported_result     ON reported_result.id_report = report.id_report
JOIN        v_stale_calculation ON v_stale_calculation.id_observation = reported_result.id_observation
WHERE       report.issued_at IS NOT NULL
  AND       NOT EXISTS (
                SELECT  1
                FROM    report AS amendment
                WHERE   amendment.id_replaced_report = report.id_report
                  AND   amendment.issued_at IS NOT NULL
            );
