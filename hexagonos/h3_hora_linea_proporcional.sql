DROP TABLE IF EXISTS base.dbo.h3_hora_linea_proporcional;
WITH EtapasH3 AS (
    SELECT 
        v.hora,
        v.h3_o AS h3,
        v.id_linea,
        CAST(v.factor_expansion_linea AS FLOAT) AS factor_expansion_linea
    FROM base.dbo.etapas v
	GROUP BY 
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
-- Finalmente, insertamos los resultados en una nueva tabla
SELECT 
    p.h3,
    p.hora,
    p.id_linea,
    p.proporcional_h3o,
    p.proporcional_h3d,
    p.proporcional_h3_totales
INTO base.dbo.h3_hora_linea_proporcional
FROM Proporcional p
ORDER BY p.h3, p.hora;

SELECT 
	SUM(v.proporcional_h3o) AS origen,
	SUM(v.proporcional_h3d) AS destino,
	SUM (v.proporcional_h3_totales) AS TOTAL
FROM base.dbo.h3_hora_linea_proporcional v