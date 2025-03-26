USE [Linea101];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @schemaName NVARCHAR(128) = 'dbo';
DECLARE @dryRun BIT = 0; -- Cambiar a 0 para ejecutar los cambios reales

-- Crear tabla de registro si no existe
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

-- Tabla temporal para almacenar tablas a renombrar (solo las que tienen corchetes)
CREATE TABLE #TablesToRename (
    ID INT IDENTITY(1,1),
    OldName NVARCHAR(255) NOT NULL,
    CleanName NVARCHAR(255) NOT NULL,
    PRIMARY KEY (ID)
);

-- Encontrar tablas que contengan corchetes
INSERT INTO #TablesToRename (OldName, CleanName)
SELECT 
    t.name AS OldName,
    REPLACE(REPLACE(t.name, '[', ''), ']', '') AS CleanName
FROM 
    sys.tables t
WHERE 
    (t.name LIKE '%[%' OR t.name LIKE '%]%')
    AND SCHEMA_NAME(t.schema_id) = @schemaName
    AND REPLACE(REPLACE(t.name, '[', ''), ']', '') NOT IN (
        SELECT name FROM sys.tables WHERE schema_id = SCHEMA_ID(@schemaName)
    );

DECLARE @totalTables INT = (SELECT COUNT(*) FROM #TablesToRename);
DECLARE @processedTables INT = 0;
DECLARE @successCount INT = 0;
DECLARE @errorCount INT = 0;

PRINT 'Se encontraron ' + CAST(@totalTables AS VARCHAR(10)) + ' tablas con corchetes para procesar';
PRINT 'Modo prueba: ' + CASE WHEN @dryRun = 1 THEN 'ACTIVADO (no se harán cambios)' ELSE 'DESACTIVADO (se ejecutarán los cambios)' END;
PRINT '';

-- Procesar cada tabla
DECLARE @currentID INT = 0;
DECLARE @currentOldName NVARCHAR(255);
DECLARE @currentCleanName NVARCHAR(255);
DECLARE @sqlCommand NVARCHAR(MAX);
DECLARE @errorMessage NVARCHAR(MAX);

WHILE EXISTS (SELECT 1 FROM #TablesToRename WHERE ID > @currentID)
BEGIN
    SELECT TOP 1 
        @currentID = ID,
        @currentOldName = OldName,
        @currentCleanName = CleanName
    FROM #TablesToRename
    WHERE ID > @currentID
    ORDER BY ID;
    
    SET @processedTables = @processedTables + 1;
    
    BEGIN TRY
        PRINT 'Procesando tabla ' + CAST(@processedTables AS VARCHAR(10)) + ' de ' + CAST(@totalTables AS VARCHAR(10)) + ':';
        PRINT '  Nombre actual: ' + @currentOldName;
        PRINT '  Nuevo nombre: ' + @currentCleanName;
        
        IF @dryRun = 0
        BEGIN
            BEGIN TRANSACTION;
            
            SET @sqlCommand = 'EXEC sp_rename ''' + QUOTENAME(@schemaName) + '.' + QUOTENAME(@currentOldName) + ''', ''' + @currentCleanName + ''', ''OBJECT''';
            EXEC sp_executesql @sqlCommand;
            
            INSERT INTO dbo.TableRenameLog (OldTableName, NewTableName, RenameDate, Status)
            VALUES (@currentOldName, @currentCleanName, GETDATE(), 'Success');
            
            COMMIT TRANSACTION;
            SET @successCount = @successCount + 1;
            PRINT '  ÉXITO: Tabla renombrada';
        END
        ELSE
        BEGIN
            INSERT INTO dbo.TableRenameLog (OldTableName, NewTableName, RenameDate, Status)
            VALUES (@currentOldName, @currentCleanName, NULL, 'Dry Run');
            PRINT '  MODO PRUEBA: No se realizaron cambios';
        END
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        SET @errorMessage = ERROR_MESSAGE();
        SET @errorCount = @errorCount + 1;
        
        INSERT INTO dbo.TableRenameLog (OldTableName, NewTableName, RenameDate, Status, ErrorMessage)
        VALUES (@currentOldName, @currentCleanName, GETDATE(), 'Failed', @errorMessage);
        
        PRINT '  ERROR: ' + @errorMessage;
    END CATCH
    
    PRINT '';
END

-- Limpieza
DROP TABLE #TablesToRename;

-- Resumen
PRINT 'Proceso completado:';
PRINT '  Tablas encontradas:    ' + CAST(@totalTables AS VARCHAR(10));
PRINT '  Tablas procesadas:    ' + CAST(@processedTables AS VARCHAR(10));
PRINT '  Renombres exitosos:   ' + CAST(@successCount AS VARCHAR(10));
PRINT '  Errores:              ' + CAST(@errorCount AS VARCHAR(10));

IF @dryRun = 1 AND @totalTables > 0
BEGIN
    PRINT '';
    PRINT 'NOTA: El script se ejecutó en modo prueba. No se renombraron tablas.';
    PRINT '      Configure @dryRun = 0 para ejecutar los cambios reales.';
END