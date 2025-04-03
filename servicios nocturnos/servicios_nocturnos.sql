

WITH BaseServicios AS (
    SELECT *
    FROM servicios_2024_11_13
    WHERE
        xd = '13'
        AND MRK <> 'N'
        AND CAST(FecIni AS DATETIME) BETWEEN '2024-11-13 00:00:00' AND '2024-11-13 06:00:00'
)
SELECT
    SUBSTRING(FecIni, 12, 2) AS hora, 
    l_codif,
    COUNT(id_servicio) AS Servicios,
    SUM(TRY_CAST(CantPax AS INT)) AS TotalPax
FROM BaseServicios
GROUP BY 
    SUBSTRING(FecIni, 12, 2),
    l_codif
ORDER BY hora;
 
------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------

WITH BaseServicios AS (
    SELECT 
        *,
        CONVERT(DATETIME, FecIni, 103) AS FechaHoraConvertida
    FROM servicios_2024_11_13
    WHERE
        xd = '13'
        AND MRK <> 'N'
        AND CAST(FecIni AS DATETIME) BETWEEN '2024-11-13 00:00:00' AND '2024-11-13 06:00:00'
),
DatosAgrupados AS (
    SELECT
        CONVERT(TIME, FechaHoraConvertida) AS hora, 
        l_codif,
        COUNT(id_servicio) AS Servicios,
        COUNT(dominio) AS CantVehiculos,
        SUM(TRY_CAST(CantPax AS INT)) AS TotalPax
    FROM BaseServicios
    GROUP BY 
        CONVERT(TIME, FechaHoraConvertida),
        l_codif
)
SELECT 
    Metricas,
    l_codif AS Codigo,
    [00:00:00], [01:00:00], [02:00:00], [03:00:00], [04:00:00], [05:00:00], [06:00:00]
FROM (
    SELECT 
        l_codif,
        hora,
        Metricas,
        Valor
    FROM DatosAgrupados
    CROSS APPLY (
        VALUES 
            ('Servicios', Servicios),
            ('CantVehiculos', CantVehiculos),
            ('TotalPax', TotalPax)
    ) AS Unpivoted(Metricas, Valor)
) AS SourceData
PIVOT (
    SUM(Valor)
    FOR hora IN ([00:00:00], [01:00:00], [02:00:00], [03:00:00], [04:00:00], [05:00:00], [06:00:00])
) AS PivotTable
ORDER BY Metricas, Codigo;