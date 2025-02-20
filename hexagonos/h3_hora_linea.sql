DROP TABLE IF EXISTS BASE.DBO.ETAPAS_HEX;
WITH EtapasH3 AS (
	SELECT 
		v.h3_o, v.h3_d,
		CAST (v.factor_expansion_linea AS FLOAT) AS factor_expansion_linea
	FROM base.dbo.etapas v
),
EtapaOrigen AS (
	SELECT 
		v.h3_o AS h3,
		SUM(v.factor_expansion_linea) AS v_totales
	FROM EtapasH3 v
	GROUP BY v.h3_o
),
EtapaDestino AS (
	SELECT 
		v.h3_d AS h3,
		SUM(v.factor_expansion_linea) AS v_totales
	FROM EtapasH3 v
	GROUP BY v.h3_d
)
SELECT 
	d.h3,
	SUM(COALESCE(o.v_totales, 0)) AS H3o,
	SUM(COALESCE(d.v_totales, 0)) AS H3d,
	SUM(COALESCE(o.v_totales, 0)+COALESCE(d.v_totales, 0))/2 AS H3_totales
INTO BASE.DBO.ETAPAS_HEX
FROM EtapaOrigen d
FULL OUTER JOIN EtapaDestino o ON o.h3 = d.h3
GROUP BY d.h3
ORDER BY d.h3;

SELECT
	SUM (h3o) AS Origen,
	SUM (H3d) AS Destino,
	SUM (H3_TOTALES) AS Totales
FROM BASE.DBO.ETAPAS_HEX