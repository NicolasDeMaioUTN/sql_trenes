WITH BaseServicios AS (
    SELECT 
        dia,
        l.l_atm AS l_codif,
        hora,    
		CAST(ROUND(CAST(veh AS FLOAT), 0) AS INT) AS Veh,
		TRY_CAST(pax AS DECIMAL(20,2)) AS PAX,
		TRY_CAST(dmt AS DECIMAL(20,2)) AS DMT,
		TRY_CAST([of] AS DECIMAL(20,2)) AS FO,
		TRY_CAST([speed_kmh] AS DECIMAL(20,2)) AS speed_kmh
    FROM serviciosNocturnos.dbo.basic_kpi_by_line_hr_2024_11_13 k
    JOIN serviciosNocturnos.dbo.tx_latm_2024_11_13 l
        ON l.bo_idlinea = k.id_linea
),
DatosAgrupados AS (
    SELECT
        hora, 
        l_codif,
        SUM(Veh) AS Servicios,
        SUM(PAX) AS TotalPax,
        AVG(FO) AS FO,
        AVG(DMT) AS DMT,
        AVG(speed_kmh) AS Km_h
    FROM BaseServicios
    GROUP BY 
        hora,
        l_codif
)
-- Servicios (integer values)
SELECT 
    l_codif,
    'Servicios' AS Metricas,
    SUM(CASE WHEN hora = '0' THEN Servicios ELSE 0 END) AS [0],
    SUM(CASE WHEN hora = '1' THEN Servicios ELSE 0 END) AS [1],
    SUM(CASE WHEN hora = '2' THEN Servicios ELSE 0 END) AS [2],
    SUM(CASE WHEN hora = '3' THEN Servicios ELSE 0 END) AS [3],
    SUM(CASE WHEN hora = '4' THEN Servicios ELSE 0 END) AS [4],
    SUM(CASE WHEN hora = '5' THEN Servicios ELSE 0 END) AS [5],
    SUM(CASE WHEN hora = '6' THEN Servicios ELSE 0 END) AS [6],
    1 AS SortOrder  -- Added for ordering
FROM DatosAgrupados
GROUP BY l_codif

UNION ALL

-- TotalPax (formatted as decimal)
SELECT 
    l_codif,
    'TotalPax' AS Metricas,
    SUM(CASE WHEN hora = '0' THEN CAST(TotalPax AS DECIMAL(18,2)) ELSE 0 END) AS [0],
    SUM(CASE WHEN hora = '1' THEN CAST(TotalPax AS DECIMAL(18,2)) ELSE 0 END) AS [1],
    SUM(CASE WHEN hora = '2' THEN CAST(TotalPax AS DECIMAL(18,2)) ELSE 0 END) AS [2],
    SUM(CASE WHEN hora = '3' THEN CAST(TotalPax AS DECIMAL(18,2)) ELSE 0 END) AS [3],
    SUM(CASE WHEN hora = '4' THEN CAST(TotalPax AS DECIMAL(18,2)) ELSE 0 END) AS [4],
    SUM(CASE WHEN hora = '5' THEN CAST(TotalPax AS DECIMAL(18,2)) ELSE 0 END) AS [5],
    SUM(CASE WHEN hora = '6' THEN CAST(TotalPax AS DECIMAL(18,2)) ELSE 0 END) AS [6],
    2 AS SortOrder  -- Added for ordering
FROM DatosAgrupados
GROUP BY l_codif

UNION ALL

-- FO (Factor de Ocupación - formatted as decimal)
SELECT 
    l_codif,
    'FO' AS Metricas,
    CAST(AVG(CASE WHEN hora = '0' THEN FO ELSE NULL END) AS DECIMAL(18,2)) AS [0],
    CAST(AVG(CASE WHEN hora = '1' THEN FO ELSE NULL END) AS DECIMAL(18,2)) AS [1],
    CAST(AVG(CASE WHEN hora = '2' THEN FO ELSE NULL END) AS DECIMAL(18,2)) AS [2],
    CAST(AVG(CASE WHEN hora = '3' THEN FO ELSE NULL END) AS DECIMAL(18,2)) AS [3],
    CAST(AVG(CASE WHEN hora = '4' THEN FO ELSE NULL END) AS DECIMAL(18,2)) AS [4],
    CAST(AVG(CASE WHEN hora = '5' THEN FO ELSE NULL END) AS DECIMAL(18,2)) AS [5],
    CAST(AVG(CASE WHEN hora = '6' THEN FO ELSE NULL END) AS DECIMAL(18,2)) AS [6],
    3 AS SortOrder  -- Added for ordering
FROM DatosAgrupados
GROUP BY l_codif

UNION ALL

-- DMT (Distancia Media de Viaje - formatted as decimal)
SELECT 
    l_codif,
    'DMT' AS Metricas,
    CAST(AVG(CASE WHEN hora = '0' THEN DMT ELSE NULL END) AS DECIMAL(18,2)) AS [0],
    CAST(AVG(CASE WHEN hora = '1' THEN DMT ELSE NULL END) AS DECIMAL(18,2)) AS [1],
    CAST(AVG(CASE WHEN hora = '2' THEN DMT ELSE NULL END) AS DECIMAL(18,2)) AS [2],
    CAST(AVG(CASE WHEN hora = '3' THEN DMT ELSE NULL END) AS DECIMAL(18,2)) AS [3],
    CAST(AVG(CASE WHEN hora = '4' THEN DMT ELSE NULL END) AS DECIMAL(18,2)) AS [4],
    CAST(AVG(CASE WHEN hora = '5' THEN DMT ELSE NULL END) AS DECIMAL(18,2)) AS [5],
    CAST(AVG(CASE WHEN hora = '6' THEN DMT ELSE NULL END) AS DECIMAL(18,2)) AS [6],
    4 AS SortOrder  -- Added for ordering
FROM DatosAgrupados
GROUP BY l_codif

UNION ALL

-- Km_h (Velocidad - formatted as decimal)
SELECT 
    l_codif,
    'Km_h' AS Metricas,
    CAST(AVG(CASE WHEN hora = '0' THEN Km_h ELSE NULL END) AS DECIMAL(18,2)) AS [0],
    CAST(AVG(CASE WHEN hora = '1' THEN Km_h ELSE NULL END) AS DECIMAL(18,2)) AS [1],
    CAST(AVG(CASE WHEN hora = '2' THEN Km_h ELSE NULL END) AS DECIMAL(18,2)) AS [2],
    CAST(AVG(CASE WHEN hora = '3' THEN Km_h ELSE NULL END) AS DECIMAL(18,2)) AS [3],
    CAST(AVG(CASE WHEN hora = '4' THEN Km_h ELSE NULL END) AS DECIMAL(18,2)) AS [4],
    CAST(AVG(CASE WHEN hora = '5' THEN Km_h ELSE NULL END) AS DECIMAL(18,2)) AS [5],
    CAST(AVG(CASE WHEN hora = '6' THEN Km_h ELSE NULL END) AS DECIMAL(18,2)) AS [6],
    5 AS SortOrder  -- Added for ordering
FROM DatosAgrupados
GROUP BY l_codif

ORDER BY l_codif, SortOrder;