USE [Base]
GO

SELECT [h3],
	  CONCAT([hora_inicio_rango],'---',[hora_fin_rango])
      ,l.nombre_linea
      ,[total_proporcional_h3o] AS Etapas_origen
      ,[total_proporcional_h3d] AS Etapas_Destino
      ,[total_proporcional_h3_totales] AS Etapas_Total
  FROM [dbo].[h3_hora_linea_proporcional_rango] b
  JOIN base.dbo.lineas l ON l.id_linea = b.id_linea

GO


SELECT 
    h3,
    hora_inicio_rango,
    hora_fin_rango,
    id_lineas_concatenados,
    total_proporcional_h3o,
    total_proporcional_h3d,
    total_proporcional_h3_totales
FROM base.dbo.h3_hora_linea_proporcional_rango_concatenado
ORDER BY h3, hora_inicio_rango;

SELECT 
    SUM(total_proporcional_h3o),
    SUM(total_proporcional_h3d),
    SUM(total_proporcional_h3_totales)
FROM base.dbo.h3_hora_linea_proporcional_rango_concatenado