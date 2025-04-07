 @Database NVARCHAR(15), -- Base de datos = Linea de analisis
 @BasePares NVARCHAR(20), -- Base_Database
 @Hexagonos NVARCHAR(MAX), -- Tabla de Hexagonos de Elección
 @Dia NVARCHAR(10) -- DIA yyyy_mm_dd
 
EXEC BASE.DBO._009_Zonas_h3 'Hex_Procrear','Base_Hex_Procrear','Hexagonos','2024_11_16';