

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
        CAST (FecIni AS DATETIME) AS Fecha
    FROM servicios_2024_11_13
    WHERE
        xd = '13'
        AND MRK <> 'N'
        AND CAST(FecIni AS DATETIME) BETWEEN '2024-11-13 00:00:00' AND '2024-11-13 07:00:00'
),
DatosAgrupados AS (
    SELECT
        DATEPART(HOUR, CONVERT(TIME, Fecha)) AS hora, 
        l_codif,
        COUNT(id_servicio) AS Servicios,
        SUM(TRY_CAST(CantPax AS INT)) AS TotalPax
    FROM BaseServicios
    GROUP BY 
        CONVERT(TIME, Fecha),
        l_codif
)
SELECT 
    l_codif AS Codigo,
    Metricas,
    [00], [01], [02], [03], [04], [05], [06]
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
            ('TotalPax', TotalPax)
    ) AS Unpivoted(Metricas, Valor)
) AS SourceData
PIVOT (
    SUM(Valor)
    FOR hora IN ([00], [01], [02], [03], [04], [05], [06])
) AS PivotTable
ORDER BY Codigo,Metricas;