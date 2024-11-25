-- Procedure to fetch all existing, non log tables and crate logtables
-- as well as insert and update triggers for them
DELIMITER $$

CREATE PROCEDURE create_all_log_tables()
BEGIN
    -- Variable declarations
    DECLARE done INT DEFAULT FALSE;
    DECLARE tbl_name VARCHAR(64);
    DECLARE log_table VARCHAR(128);
    DECLARE create_table_sql TEXT;
    DECLARE trigger_insert_sql TEXT;
    DECLARE trigger_update_sql TEXT;
    DECLARE column_list TEXT;
    DECLARE checksum_expr TEXT;
    
    -- Cursor to iterate over main tables
    DECLARE cur CURSOR FOR
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = DATABASE()
          AND table_type = 'BASE TABLE'
          AND table_name NOT LIKE 'l\_%' ESCAPE '\\'  -- Exclude log tables
          AND table_name != 'person';                 -- Exclude 'person' table if not to be audited
    
    -- Handler for cursor completion
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    -- Open the cursor
    OPEN cur;
    
    -- Loop through each table
    read_loop: LOOP
        FETCH cur INTO tbl_name;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        -- Define the log table name
        SET log_table = CONCAT('l_', tbl_name);
        
        -- Generate the column list for checksum using GROUP_CONCAT
        SELECT GROUP_CONCAT(CONCAT('COALESCE(NEW.', COLUMN_NAME, ', \'NULL\')') SEPARATOR ', \'|\', ')
        INTO column_list
        FROM information_schema.columns
        WHERE table_schema = DATABASE()
          AND table_name = tbl_name
        ORDER BY ordinal_position;
        
        -- Construct the SHA256 checksum expression
        SET checksum_expr = CONCAT('SHA2(CONCAT_WS(\'|\', ', column_list, '), 256)');
        
        -- Create the log table
        SET create_table_sql = CONCAT('
            CREATE TABLE IF NOT EXISTS ', log_table, ' (
                id_l_', tbl_name, ' INT AUTO_INCREMENT PRIMARY KEY,
                id_', tbl_name, ' INT NOT NULL,
                change VARCHAR(50) NOT NULL,
                t TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                id_editor INT,
                note VARCHAR(500),
                checksum VARCHAR(100) NOT NULL,
                FOREIGN KEY (id_', tbl_name, ') REFERENCES ', tbl_name, '(id_', tbl_name, '),
                FOREIGN KEY (id_editor) REFERENCES person(id_person)
            ) ENGINE=InnoDB;
        ');
        
        -- Execute the CREATE TABLE statement
        PREPARE stmt FROM create_table_sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
        
        -- Define trigger names
        SET @trigger_name_insert = CONCAT('trg_', tbl_name, '_insert');
        SET @trigger_name_update = CONCAT('trg_', tbl_name, '_update');
        
        -- Drop existing triggers if they exist to avoid duplication errors
        SET @drop_insert = CONCAT('DROP TRIGGER IF EXISTS ', @trigger_name_insert, ';');
        SET @drop_update = CONCAT('DROP TRIGGER IF EXISTS ', @trigger_name_update, ';');
        
        PREPARE stmt FROM @drop_insert;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
        
        PREPARE stmt FROM @drop_update;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
        
        -- Create AFTER INSERT trigger
        SET trigger_insert_sql = CONCAT('
            CREATE TRIGGER ', @trigger_name_insert, ' AFTER INSERT ON ', tbl_name, '
            FOR EACH ROW
            BEGIN
                INSERT INTO ', log_table, ' (
                    id_', tbl_name, ',
                    change,
                    id_editor,
                    note,
                    checksum
                ) VALUES (
                    NEW.id_', tbl_name, ',
                    \'I\',
                    @current_user_id,
                    \'Inserted\',
                    ', checksum_expr, '
                );
            END;
        ');
        
        PREPARE stmt FROM trigger_insert_sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
        
        -- Create AFTER UPDATE trigger
        SET trigger_update_sql = CONCAT('
            CREATE TRIGGER ', @trigger_name_update, ' AFTER UPDATE ON ', tbl_name, '
            FOR EACH ROW
            BEGIN
                INSERT INTO ', log_table, ' (
                    id_', tbl_name, ',
                    change,
                    id_editor,
                    note,
                    checksum
                ) VALUES (
                    NEW.id_', tbl_name, ',
                    \'U\',
                    @current_user_id,
                    \'Updated\',
                    ', checksum_expr, '
                );
            END;
        ');
        
        PREPARE stmt FROM trigger_update_sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
        
    END LOOP;
    
    -- Close the cursor
    CLOSE cur;
END$$

DELIMITER ;

