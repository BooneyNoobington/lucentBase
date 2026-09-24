/* Assertion procedures for the SQL tests. bin/test loads them into every test
   database; they are not part of the lucentBase schema.

   A failing assertion raises an error, which makes the test fail. */

DELIMITER $$


/* Fails unless p_condition is true. NULL counts as false. */

CREATE PROCEDURE assert_true(p_condition BOOLEAN, p_label VARCHAR(200))
BEGIN
    DECLARE v_message VARCHAR(500);

    IF p_condition IS NULL OR NOT p_condition THEN
        SET v_message = CONCAT('assertion failed: ', p_label);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_message;
    END IF;
END$$


/* Fails unless both values are equal. Two NULLs count as equal. */

CREATE PROCEDURE assert_equal(p_actual VARCHAR(1000), p_expected VARCHAR(1000), p_label VARCHAR(200))
BEGIN
    DECLARE v_message VARCHAR(1000);

    IF NOT (p_actual <=> p_expected) THEN
        SET v_message = CONCAT('assertion failed: ', p_label,
                               ' (expected ', COALESCE(p_expected, 'NULL'),
                               ', got ', COALESCE(p_actual, 'NULL'), ')');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_message;
    END IF;
END$$


/* Fails unless both numbers are equal, however many decimals they are
   written with: 1500 equals 1500.000. */

CREATE PROCEDURE assert_number(p_actual DECIMAL(38,12), p_expected DECIMAL(38,12), p_label VARCHAR(200))
BEGIN
    DECLARE v_message VARCHAR(1000);

    IF NOT (p_actual <=> p_expected) THEN
        SET v_message = CONCAT('assertion failed: ', p_label,
                               ' (expected ', COALESCE(p_expected, 'NULL'),
                               ', got ', COALESCE(p_actual, 'NULL'), ')');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_message;
    END IF;
END$$


/* Runs p_statement and fails unless it raises an error whose message
   contains p_expected_message. Use it to prove that a rule is enforced. */

CREATE PROCEDURE assert_fails(p_statement TEXT, p_expected_message VARCHAR(200), p_label VARCHAR(200))
BEGIN
    DECLARE v_failed BOOLEAN DEFAULT FALSE;
    DECLARE v_error VARCHAR(1000) DEFAULT '';
    DECLARE v_message VARCHAR(1500);

    BEGIN
        DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            GET DIAGNOSTICS CONDITION 1 v_error = MESSAGE_TEXT;
            SET v_failed = TRUE;
        END;

        SET @assert_statement = p_statement;
        PREPARE assert_statement FROM @assert_statement;
        EXECUTE assert_statement;
        DEALLOCATE PREPARE assert_statement;
    END;

    IF NOT v_failed THEN
        SET v_message = CONCAT('assertion failed: ', p_label, ' (statement succeeded, but should have failed)');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_message;
    END IF;

    IF v_error NOT LIKE CONCAT('%', p_expected_message, '%') THEN
        SET v_message = CONCAT('assertion failed: ', p_label, ' (failed with an unexpected error: ', v_error, ')');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_message;
    END IF;
END$$

DELIMITER ;
