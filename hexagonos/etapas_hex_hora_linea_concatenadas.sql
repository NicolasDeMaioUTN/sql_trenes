DROP TABLE IF EXISTS base.dbo.h3_linea_proporcional_concatenado;

WITH EtapasH3 AS (
    SELECT 
        v.hora,
        v.h3_o AS h3,
        v.id_linea,
        CAST(v.factor_expansion_linea AS FLOAT) AS factor_expansion_linea
    FROM base.dbo.etapas v
),
TotalesPorHexagono AS (
    -- Calculamos los totales por h3 y hora desde base.dbo.h3_hora_linea
    SELECT 
        b.h3,
        b.H3o,
        b.H3d,
        b.H3_totales
    FROM base.dbo.h3_hora_linea b
),
Proporcional AS (
    -- Calculamos el proporcional de cada factor_expansion_linea
    SELECT 
        e.h3,
        e.id_linea,
        e.factor_expansion_linea,
        -- Calculamos el proporcional para cada componente (H3o, H3d, H3_totales) con NULLIF para evitar la división por cero
        (e.factor_expansion_linea / NULLIF(tot.H3o, 0)) * NULLIF(tot.H3o, 0) AS proporcional_h3o,
        (e.factor_expansion_linea / NULLIF(tot.H3d, 0)) * NULLIF(tot.H3d, 0) AS proporcional_h3d,
        (e.factor_expansion_linea / NULLIF(tot.H3_totales, 0)) * NULLIF(tot.H3_totales, 0) AS proporcional_h3_totales
    FROM EtapasH3 e
    JOIN TotalesPorHexagono tot
        ON e.h3 = tot.h3
),
LineasUnicas AS (
    -- Seleccionamos las líneas únicas por h3 y hora
    SELECT DISTINCT 
        p.h3, 
        l.nombre_linea
    FROM Proporcional p
    LEFT JOIN base.dbo.lineas l ON p.id_linea = l.id_linea
)
-- Finalmente, insertamos los resultados en una nueva tabla
SELECT 
    p.h3,
    -- Usamos STRING_AGG para concatenar las líneas únicas y garantizamos que se use VARCHAR(MAX)
    CAST(STRING_AGG(lu.nombre_linea, '-') AS VARCHAR(MAX)) AS lineas_hex,
    SUM(p.proporcional_h3o) AS proporcional_h3o,
    SUM(p.proporcional_h3d) AS proporcional_h3d,
    SUM(p.proporcional_h3_totales) AS proporcional_h3_totales
INTO base.dbo.h3_linea_proporcional_concatenado
FROM Proporcional p
-- Realizamos un JOIN con la tabla de líneas únicas
LEFT JOIN LineasUnicas lu ON p.h3 = lu.h3
GROUP BY p.h3
ORDER BY p.h3;

-- Verificamos los resultados agregados
SELECT 
    SUM(v.proporcional_h3o) AS origen,
    SUM(v.proporcional_h3d) AS destino,
    SUM(v.proporcional_h3_totales) AS TOTAL
FROM base.dbo.h3_hora_linea_proporcional v;
