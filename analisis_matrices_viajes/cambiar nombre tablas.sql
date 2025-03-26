USE Linea101;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON; -- Automatically rollback on errors

DECLARE @oldPattern NVARCHAR(255) = '_2_2_';
DECLARE @newPattern NVARCHAR(255) = '_2_1_';
DECLARE @schemaName NVARCHAR(128) = 'dbo';
DECLARE @dryRun BIT = 0; -- Set to 0 to actually perform the renames

-- Create a log table to track changes (if it doesn't exist)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TableRenameLog' AND schema_id = SCHEMA_ID(@schemaName))
BEGIN
    CREATE TABLE dbo.TableRenameLog (
        LogID INT IDENTITY(1,1) PRIMARY KEY,
        OldTableName NVARCHAR(255) NOT NULL,
        NewTableName NVARCHAR(255) NOT NULL,
        RenameDate DATETIME NULL,
        Status NVARCHAR(50) NOT NULL,
        ErrorMessage NVARCHAR(MAX) NULL
    );
END

PRINT 'Starting table rename operation...';
PRINT 'Dry run mode: ' + CASE WHEN @dryRun = 1 THEN 'ON (no changes will be made)' ELSE 'OFF (changes will be executed)' END;
PRINT '';

-- Temporary table to hold tables to be renamed
CREATE TABLE #TablesToRename (
    ID INT IDENTITY(1,1),
    OldName NVARCHAR(255) NOT NULL,
    NewName NVARCHAR(255) NOT NULL,
    PRIMARY KEY (ID)
);

-- Find all matching tables and prepare new names
INSERT INTO #TablesToRename (OldName, NewName)
SELECT 
    t.name AS OldName,
    REPLACE(t.name, @oldPattern, @newPattern) AS NewName
FROM 
    sys.tables t
WHERE 
    t.name LIKE '%_tc_1%'
    AND t.name LIKE '%' + @oldPattern + '%'
    AND SCHEMA_NAME(t.schema_id) = @schemaName
    AND NOT EXISTS (
        SELECT 1 FROM sys.tables 
        WHERE name = REPLACE(t.name, @oldPattern, @newPattern)
    );

DECLARE @totalTables INT = (SELECT COUNT(*) FROM #TablesToRename);
DECLARE @processedTables INT = 0;
DECLARE @successCount INT = 0;
DECLARE @errorCount INT = 0;

PRINT 'Found ' + CAST(@totalTables AS VARCHAR(10)) + ' tables to process';
PRINT '';

-- Process each table
DECLARE @currentID INT = 0;
DECLARE @currentOldName NVARCHAR(255);
DECLARE @currentNewName NVARCHAR(255);
DECLARE @sqlCommand NVARCHAR(MAX);
DECLARE @errorMessage NVARCHAR(MAX);

WHILE EXISTS (SELECT 1 FROM #TablesToRename WHERE ID > @currentID)
BEGIN
    SELECT TOP 1 
        @currentID = ID,
        @currentOldName = OldName,
        @currentNewName = NewName
    FROM #TablesToRename
    WHERE ID > @currentID
    ORDER BY ID;
    
    SET @processedTables = @processedTables + 1;
    
    BEGIN TRY
        PRINT 'Processing table ' + CAST(@processedTables AS VARCHAR(10)) + ' of ' + CAST(@totalTables AS VARCHAR(10)) + ':';
        PRINT '  Old name: ' + @currentOldName;
        PRINT '  New name: ' + @currentNewName;
        
        IF @dryRun = 0
        BEGIN
            BEGIN TRANSACTION;
            
            SET @sqlCommand = 'EXEC sp_rename ''' + QUOTENAME(@schemaName) + '.' + QUOTENAME(@currentOldName) + ''', ''' + QUOTENAME(@currentNewName) + '''';
            EXEC sp_executesql @sqlCommand;
            
            INSERT INTO dbo.TableRenameLog (OldTableName, NewTableName, RenameDate, Status)
            VALUES (@currentOldName, @currentNewName, GETDATE(), 'Success');
            
            COMMIT TRANSACTION;
            SET @successCount = @successCount + 1;
            PRINT '  SUCCESS: Table renamed';
        END
        ELSE
        BEGIN
            INSERT INTO dbo.TableRenameLog (OldTableName, NewTableName, RenameDate, Status)
            VALUES (@currentOldName, @currentNewName, NULL, 'Dry Run');
            PRINT '  DRY RUN: No changes made';
        END
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        SET @errorMessage = ERROR_MESSAGE();
        SET @errorCount = @errorCount + 1;
        
        INSERT INTO dbo.TableRenameLog (OldTableName, NewTableName, RenameDate, Status, ErrorMessage)
        VALUES (@currentOldName, @currentNewName, GETDATE(), 'Failed', @errorMessage);
        
        PRINT '  ERROR: ' + @errorMessage;
    END CATCH
    
    PRINT '';
END

-- Cleanup
DROP TABLE #TablesToRename;

-- Summary report
PRINT 'Operation completed:';
PRINT '  Total tables found:    ' + CAST(@totalTables AS VARCHAR(10));
PRINT '  Tables processed:      ' + CAST(@processedTables AS VARCHAR(10));
PRINT '  Successful renames:    ' + CAST(@successCount AS VARCHAR(10));
PRINT '  Failed attempts:       ' + CAST(@errorCount AS VARCHAR(10));

IF @dryRun = 1
BEGIN
    PRINT '';
    PRINT 'NOTE: Script was run in dry run mode. No tables were actually renamed.';
    PRINT '      Set @dryRun = 0 to execute the renames.';
END