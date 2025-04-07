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
        SUM(pax) AS TotalPax,
        AVG([FO]) AS FO,
        AVG([dmt]) AS DMT,
        AVG([speed_kmh]) AS Km_h
    FROM BaseServicios
    GROUP BY 
        hora,
        l_codif
)
SELECT 
    l_codif,
    Metricas,
    [0], [1], [2], [3], [4], [5], [6]
FROM (
    SELECT 
        l_codif,
        hora,
        Metricas,
        CASE 
            WHEN Metricas = 'Servicios' THEN COALESCE(CAST(Servicios AS FLOAT), 0)
            WHEN Metricas = 'TotalPax' THEN COALESCE(CAST(TotalPax AS FLOAT), 0)
            WHEN Metricas = 'FO' THEN COALESCE(CAST(FO AS FLOAT), 0)
            WHEN Metricas = 'DMT' THEN COALESCE(CAST(DMT AS FLOAT), 0)
            WHEN Metricas = 'Km_h' THEN COALESCE(CAST(Km_h AS FLOAT), 0)
        END AS Valor
    FROM DatosAgrupados
    CROSS APPLY (
        VALUES 
            ('Servicios', CAST(Servicios AS FLOAT)),
            ('TotalPax', CAST(TotalPax AS FLOAT)),
            ('FO', CAST(FO AS FLOAT)),
            ('DMT', CAST(DMT AS FLOAT)),
            ('Km_h', CAST(Km_h AS FLOAT))
    ) AS Unpivoted(Metricas, Valor)
) AS SourceData
PIVOT (
    SUM(Valor)
    FOR hora IN ([0], [1], [2], [3], [4], [5], [6])
) AS PivotTable
ORDER BY l_codif, Metricas;