SELECT 
	v.id_linea,
	v.dia,
	SUM(CAST (v.[factor_expansion_original] AS FLOAT)) AS SumaEtapas
  FROM [Base].[dbo].[etapas] v
  WHERE id_linea IN (428,430,1146,431)
GROUP BY v.id_linea,v.dia;

---------------------------------------------------------------------------------

SELECT
	v.id_linea,
	v.nombre_linea,
	v.nombre_linea_agg,
	v.empresa
FROM dbo.lineas v
WHERE id_linea IN ('428','430','1146','431')

---------------------------------------------------------------------------------

SELECT 
    v.id_linea,
    SUM(CAST(v.[factor_expansion_original] AS FLOAT)) AS SumaEtapas
FROM 
    [Base].[dbo].[etapas] v
LEFT JOIN  
    [Base].[dbo].[lineas] l ON l.id_linea = v.id_linea
WHERE 
    l.nombre_linea LIKE '%MITRE%'
GROUP BY 
    v.id_linea;
