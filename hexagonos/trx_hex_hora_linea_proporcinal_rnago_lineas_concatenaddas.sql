DROP TABLE IF EXISTS base.dbo.h3_hora_linea_proporcional_rango_concatenado;

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
        b.hora,
        b.H3o,
        b.H3d,
        b.H3_totales
    FROM base.dbo.h3_hora_linea b
),
Proporcional AS (
    -- Calculamos el proporcional de cada factor_expansion_linea
    SELECT 
        e.h3,
        e.hora,
        e.id_linea,
        e.factor_expansion_linea,
        -- Calculamos el proporcional para cada componente (H3o, H3d, H3_totales) con NULLIF para evitar la división por cero
        (e.factor_expansion_linea / NULLIF(tot.H3o, 0)) * NULLIF(tot.H3o, 0) AS proporcional_h3o,
        (e.factor_expansion_linea / NULLIF(tot.H3d, 0)) * NULLIF(tot.H3d, 0) AS proporcional_h3d,
        (e.factor_expansion_linea / NULLIF(tot.H3_totales, 0)) * NULLIF(tot.H3_totales, 0) AS proporcional_h3_totales
    FROM EtapasH3 e
    JOIN TotalesPorHexagono tot
        ON e.h3 = tot.h3 AND e.hora = tot.hora
)
-- Ahora, generamos el concatenado de `id_linea` por cada `h3` y `hora`, asegurándonos de que no se repitan
SELECT 
    p.h3,
    -- Agrupamos por un rango horario de 4 horas
    (FLOOR(p.hora / 4) * 4) AS hora_inicio_rango,
    (FLOOR(p.hora / 4) * 4 + 3) AS hora_fin_rango,
    -- Concatenamos todos los `id_linea` únicos que corresponden a un hexágono y hora, utilizando una subconsulta para eliminar duplicados
    STRING_AGG(CAST(p.id_linea AS VARCHAR), ' --- ') AS id_lineas_concatenados,
    SUM(p.proporcional_h3o) AS total_proporcional_h3o,
    SUM(p.proporcional_h3d) AS total_proporcional_h3d,
    SUM(p.proporcional_h3_totales) AS total_proporcional_h3_totales
INTO base.dbo.h3_hora_linea_proporcional_rango_concatenado
FROM (
    SELECT DISTINCT 
        e.h3,
        e.hora,
        e.id_linea,
        e.factor_expansion_linea,
        (e.factor_expansion_linea / NULLIF(tot.H3o, 0)) * NULLIF(tot.H3o, 0) AS proporcional_h3o,
        (e.factor_expansion_linea / NULLIF(tot.H3d, 0)) * NULLIF(tot.H3d, 0) AS proporcional_h3d,
        (e.factor_expansion_linea / NULLIF(tot.H3_totales, 0)) * NULLIF(tot.H3_totales, 0) AS proporcional_h3_totales
    FROM EtapasH3 e
    JOIN TotalesPorHexagono tot
        ON e.h3 = tot.h3 AND e.hora = tot.hora
) p
GROUP BY 
    p.h3,
    (FLOOR(p.hora / 4) * 4),  -- Hora de inicio del rango de 4 horas
    (FLOOR(p.hora / 4) * 4 + 3) -- Hora de fin del rango de 4 horas
ORDER BY p.h3, hora_inicio_rango;
