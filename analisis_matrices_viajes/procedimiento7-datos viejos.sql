USE [Base]
GO
/****** Object:  StoredProcedure [dbo].[_007_2_Datos_Basicos_Grupo_Lineas]    Script Date: 26/3/2025 12:47:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[_007_2_Datos_Basicos_Grupo_Lineas]
 @Database NVARCHAR(15), -- Base de datos = Linea de analisis
 @IdLinea NVARCHAR(50), -- Se debe utilizar id_linea "123.0"
 @BasePares NVARCHAR(20) -- Nombre de la base de pares a crear
AS
BEGIN
 BEGIN TRY
	BEGIN TRANSACTION;
	DECLARE @sql NVARCHAR(MAX);

	-- Crear tabla temporal para almacenar los Ids de Linea
	CREATE TABLE #LineaIds (id_linea NVARCHAR(50));       
	-- Insertar los valores de IdLinea en la tabla temporal
	INSERT INTO #LineaIds (id_linea)
	SELECT value FROM STRING_SPLIT(@IdLinea, ',');

	-- 1. Base de Viajes del Corredor
	SET @sql =
			'DROP TABLE IF EXISTS '+QUOTENAME(@database)+'.dbo._2_tabla01;
			SELECT DISTINCT
				CONCAT(v.IdO,''---'',v.IdD) AS ParOD,
				v.IdO, v.IdD,
				o.zonas AS z_origen, d.zonas AS z_destino,
				v.hora, v.id_tarjeta, v.id_viaje,
				STRING_AGG(CAST(e.id_linea AS NVARCHAR(MAX)), ''-'') WITHIN GROUP (ORDER BY e.id_etapa) AS CombinacionesViaje,
				STRING_AGG(CAST(l.nombre_linea AS NVARCHAR(MAX)), ''-'') WITHIN GROUP (ORDER BY e.id_etapa) AS NombreCombinacion,
				STRING_AGG(CAST(l.modo AS NVARCHAR(MAX)), ''-'') WITHIN GROUP (ORDER BY e.id_etapa) AS ModoCombinacion,
				CASE 
					WHEN EXISTS (
						SELECT 1
						FROM [Base].[dbo].[etapas] e2
						JOIN #LineaIds li ON e2.id_linea = li.id_linea
						WHERE e2.id_tarjeta = v.id_tarjeta 
						 AND e2.id_viaje = v.id_viaje 
					) THEN 1 -- tiene combinacion
					ELSE 0 -- no tiene combinacion
				END AS TieneCombinacion, 
				CAST(v.factor_expansion_linea AS FLOAT) AS ViajesExpandidos,
				CAST(v.tren AS INT) AS tren,
				CAST(v.autobus AS INT) AS autobus,
				CAST(v.metro AS INT) AS metro,
				CAST(v.cant_etapas AS INT) AS cant_etapas,
				CAST(v.distance_h3 AS FLOAT) AS distance_h3,
				CAST(v.distance_osm_drive AS FLOAT) AS distance_osm_drive
			INTO '+QUOTENAME(@Database)+'.dbo._2_tabla01
			FROM [Base].[dbo].[viajes] v
				LEFT JOIN [Base].[dbo].[etapas] e ON v.id_tarjeta = e.id_tarjeta AND v.id_viaje = e.id_viaje
				LEFT JOIN [Base].[dbo].[microzonas] o ON v.IdO = o.id
				LEFT JOIN [Base].[dbo].[microzonas] d ON v.IdD = d.id
				LEFT JOIN [Base].[dbo].[lineas] l ON e.id_linea = l.id_linea
			WHERE CONCAT(v.IdO,''---'',v.IdD) IN (SELECT ParOD FROM [Base].[dbo].'+QUOTENAME(@BasePares)+') -- Zonas de OD seleccionadas. Base de zonas de linea
			GROUP BY
				v.IdO, v.IdD, o.zonas, d.zonas, v.hora, v.id_tarjeta, v.id_viaje, v.factor_expansion_linea, v.tren, v.autobus, 
				v.metro, v.cant_etapas, v.distance_h3, v.distance_osm_drive;';
	print @sql ;EXEC sp_executesql @sql;

	-- 2. Base de Viajes 
	SET @sql = 
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_base_viajes;
		SELECT DISTINCT 
			v.ParOD, v.IdO, v.IdD,
			CASE
				WHEN AVG(CAST(v.distance_osm_drive AS FLOAT)) >= 90 THEN ''100''
				WHEN AVG(CAST(v.distance_osm_drive AS FLOAT)) >= 80 THEN ''80---90''
				WHEN AVG(CAST(v.distance_osm_drive AS FLOAT)) >= 70 THEN ''70---80''
				WHEN AVG(CAST(v.distance_osm_drive AS FLOAT)) >= 60 THEN ''60---70''
				WHEN AVG(CAST(v.distance_osm_drive AS FLOAT)) >= 50 THEN ''50---60''
				WHEN AVG(CAST(v.distance_osm_drive AS FLOAT)) >= 40 THEN ''40---50''
				WHEN AVG(CAST(v.distance_osm_drive AS FLOAT)) >= 30 THEN ''30---40''
				WHEN AVG(CAST(v.distance_osm_drive AS FLOAT)) >= 20 THEN ''20---30''
				WHEN AVG(CAST(v.distance_osm_drive AS FLOAT)) >= 10 THEN ''10---20''
				WHEN AVG(CAST(v.distance_osm_drive AS FLOAT)) >= 5 THEN ''05---10''
				WHEN AVG(CAST(v.distance_osm_drive AS FLOAT)) >= 2 THEN ''02---05''
				ELSE ''00---02''
			END AS distancia,
			v.z_origen, v.z_destino, v.TieneCombinacion,';
	SET @SQL = @SQL +
		'CASE
				WHEN v.tren = 0 AND v.autobus = 1 AND v.metro = 0 THEN ''A-COLECTIVO''
				WHEN v.tren = 0 AND v.autobus = 2 AND v.metro = 0 THEN ''A-COLECTIVOx2''
				WHEN v.tren = 0 AND v.autobus = 3 AND v.metro = 0 THEN ''A-COLECTIVOx3''
				WHEN v.tren = 0 AND v.autobus >= 4 AND v.metro = 0 THEN ''A-COLECTIVO+4''
				WHEN v.tren = 0 AND v.autobus = 0 AND v.metro = 1 THEN ''B-SUBTE''
				WHEN v.tren = 0 AND v.autobus = 0 AND v.metro = 2 THEN ''B-SUBTEX2''
				WHEN v.tren = 0 AND v.autobus = 0 AND v.metro = 3 THEN ''B-SUBTEx3''
				WHEN v.tren = 0 AND v.autobus = 0 AND v.metro >= 4 THEN ''B-SUBTE+4''
				WHEN v.tren = 1 AND v.autobus = 0 AND v.metro = 0 THEN ''C-TREN''
				WHEN v.tren = 2 AND v.autobus = 0 AND v.metro = 0 THEN ''C-TRENx2''
				WHEN v.tren >= 3 AND v.autobus = 0 AND v.metro = 0 THEN ''C-TREN+3''
				WHEN v.tren = 0 AND v.autobus = 1 AND v.metro = 1 THEN ''D-COLECTIVO-SUBTE''
				WHEN v.tren = 0 AND v.autobus >= 2 AND v.metro = 1 THEN ''D-COLECTIVO+2-SUBTE''
				WHEN v.tren = 0 AND v.autobus = 1 AND v.metro >= 2 THEN ''D-COLECTIVO-SUBTE+2''
				WHEN v.tren = 0 AND v.autobus >= 2 AND v.metro >= 2 THEN ''D-COLECTIVO+2-SUBTE+2''
				WHEN v.tren = 1 AND v.autobus = 1 AND v.metro = 0 THEN ''E-TREN-COLECTIVO''
				WHEN v.tren >= 2 AND v.autobus = 1 AND v.metro = 0 THEN ''E-TREN+2-COLECTIVO''
				WHEN v.tren = 1 AND v.autobus >= 2 AND v.metro = 0 THEN ''E-TREN-COLECTIVO+2''
				WHEN v.tren >= 2 AND v.autobus >= 2 AND v.metro = 0 THEN ''E-TREN+2-COLECTIVO+2''
				WHEN v.tren >= 1 AND v.autobus = 0 AND v.metro >= 1 THEN ''F-TREN-SUBTE''
				WHEN v.tren >= 1 AND v.autobus >= 1 AND v.metro >= 1 THEN ''G-TREN-COLECTIVO-SUBTE''
				ELSE ''Null''
			END AS ModoMultimodal,';
	SET @SQL = @SQL +
			'v.CombinacionesViaje, v.NombreCombinacion, v.ModoCombinacion, v.id_tarjeta, v.id_viaje,
			CASE
				WHEN v.hora BETWEEN 0 AND 7 THEN ''1 - madrugada''
				WHEN v.hora BETWEEN 7 AND 10 THEN ''2 - pico_ma�ana''
				WHEN v.hora BETWEEN 10 AND 16 THEN ''3 - mediodia''
				WHEN v.hora BETWEEN 16 AND 19 THEN ''4 - pico_tarde''
				WHEN v.hora BETWEEN 19 AND 24 THEN ''5 - noche''
				ELSE ''null''
			END AS pico_horario, v.hora, 
			SUM(v.ViajesExpandidos) AS ViajesExpandidos,
			SUM(v.tren) AS tren, SUM(v.autobus) AS autobus, SUM(v.metro) AS metro, SUM(v.cant_etapas) AS cant_etapas,
			AVG(v.distance_h3) AS distance_h3, AVG(v.distance_osm_drive) AS distance_osm_drive
		INTO '+QUOTENAME(@Database)+'.dbo._2_base_viajes
		FROM '+QUOTENAME(@Database)+'.[dbo].[_2_tabla01] v
		GROUP BY
			v.ParOD, v.IdO, v.IdD, v.z_origen, v.z_destino,
			v.TieneCombinacion, v.hora, v.CombinacionesViaje, v.NombreCombinacion, v.ModoCombinacion,
			v.tren, v.autobus, v.metro, v.id_tarjeta, v.id_viaje,';
	SET @sql = @sql +
		'CASE
			WHEN (v.tren = 0 AND v.autobus = 1 AND v.metro = 0) THEN ''A-COLECTIVO''
			WHEN (v.tren = 0 AND v.autobus = 2 AND v.metro = 0) THEN ''A-COLECTIVOx2''
			WHEN (v.tren = 0 AND v.autobus = 3 AND v.metro = 0) THEN ''A-COLECTIVOx3''
			WHEN (v.tren = 0 AND v.autobus >= 4 AND v.metro = 0) THEN ''A-COLECTIVO+4''
			WHEN (v.tren = 0 AND v.autobus = 0 AND v.metro = 1) THEN ''B-SUBTE''
			WHEN (v.tren = 0 AND v.autobus = 0 AND v.metro = 2) THEN ''B-SUBTEX2''
			WHEN (v.tren = 0 AND v.autobus = 0 AND v.metro = 3) THEN ''B-SUBTEx3''
			WHEN (v.tren = 0 AND v.autobus = 0 AND v.metro >= 4) THEN ''B-SUBTE+4''
			WHEN (v.tren = 1 AND v.autobus = 0 AND v.metro = 0) THEN ''C-TREN''
			WHEN (v.tren = 2 AND v.autobus = 0 AND v.metro = 0) THEN ''C-TRENx2''
			WHEN (v.tren >= 3 AND v.autobus = 0 AND v.metro = 0) THEN ''C-TREN+3''
			WHEN (v.tren = 0 AND v.autobus = 1 AND v.metro = 1) THEN ''D-COLECTIVO-SUBTE''
			WHEN (v.tren = 0 AND v.autobus >= 2 AND v.metro = 1) THEN ''D-COLECTIVO+2-SUBTE''
			WHEN (v.tren = 0 AND v.autobus = 1 AND v.metro >= 2) THEN ''D-COLECTIVO-SUBTE+2''
			WHEN (v.tren = 0 AND v.autobus >= 2 AND v.metro >= 2) THEN ''D-COLECTIVO+2-SUBTE+2''
			WHEN (v.tren = 1 AND v.autobus = 1 AND v.metro = 0) THEN ''E-TREN-COLECTIVO''
			WHEN (v.tren >= 2 AND v.autobus = 1 AND v.metro = 0) THEN ''E-TREN+2-COLECTIVO''
			WHEN (v.tren = 1 AND v.autobus >= 2 AND v.metro = 0) THEN ''E-TREN-COLECTIVO+2''
			WHEN (v.tren >= 2 AND v.autobus >= 2 AND v.metro = 0) THEN ''E-TREN+2-COLECTIVO+2''
			WHEN (v.tren >= 1 AND v.autobus = 0 AND v.metro >= 1) THEN ''F-TREN-SUBTE''
			WHEN (v.tren >= 1 AND v.autobus >= 1 AND v.metro >= 1) THEN ''G-TREN-COLECTIVO-SUBTE''
			ELSE ''Null''
		END,';
	SET @sql = @sql +
		'CASE
			WHEN v.hora BETWEEN 0 AND 7 THEN ''1 - madrugada''
			WHEN v.hora BETWEEN 7 AND 10 THEN ''2 - pico_ma�ana''
			WHEN v.hora BETWEEN 10 AND 16 THEN ''3 - mediodia''
			WHEN v.hora BETWEEN 16 AND 19 THEN ''4 - pico_tarde''
			WHEN v.hora BETWEEN 19 AND 24 THEN ''5 - noche''
			ELSE ''null''
		END;
		DROP TABLE IF EXISTS '+QUOTENAME(@database)+'.dbo._2_tabla01';
	print @sql ;EXEC sp_executesql @sql;

	-- 3. Base de etapas por Linea
	SET @sql = 
		'DROP TABLE IF EXISTS '+QUOTENAME(@database)+'.dbo._2_base_etapas_por_linea_por_ParOD;
		
		WITH ViajesMultimodales AS (
			SELECT
				v.ParOD, v.distancia, v.IdO, v.IdD, v.z_origen, v.z_destino, v.id_tarjeta, v.id_viaje, v.ModoMultimodal, 
				v.hora, v.pico_horario, v.TieneCombinacion, v.CombinacionesViaje, v.NombreCombinacion, v.ModoCombinacion, v.ViajesExpandidos,
				v.tren, v.autobus, v.metro, v.cant_etapas, v.distance_h3, v.distance_osm_drive,
				e.id_etapa, e.id_linea, CAST(e.factor_expansion_linea AS FLOAT) AS factor_expansion_linea,
				l.nombre_linea, l.empresa
			FROM '+QUOTENAME(@database)+'.[dbo]._2_base_viajes v
			LEFT JOIN [Base].[dbo].[etapas] e ON v.id_tarjeta = e.id_tarjeta 
				AND v.id_viaje = e.id_viaje
			LEFT JOIN [Base].[dbo].[lineas] l ON e.id_linea = l.id_linea
		)
		SELECT 
			v.ParOD, v.IdO, v.IdD, v.z_origen, v.z_destino, v.id_linea, v.nombre_linea, v.TieneCombinacion, v.ModoMultimodal,
			v.hora, v.pico_horario, v.distancia, v.empresa,
			CAST(COUNT(v.id_linea) AS INT) AS CantidadEtapas,
			SUM(v.factor_expansion_linea) AS SumaViajes
		INTO '+QUOTENAME(@database)+'.[dbo]._2_base_etapas_por_linea_por_ParOD
		FROM ViajesMultimodales v
		GROUP BY
			v.ParOD, v.IdO, v.IdD, v.z_origen, v.z_destino, v.id_linea, v.nombre_linea, v.empresa,
			v.TieneCombinacion, v.ModoMultimodal, v.hora, v.pico_horario, v.distancia
		ORDER BY v.ParOD;';
	print @sql ;EXEC sp_executesql @sql;
	
	-- 4. Etapas por Linea TC_0
	SET @sql = 
		'DROP TABLE IF EXISTS '+QUOTENAME(@database)+'.dbo._2_base_etapas_por_linea_por_ParOD_TC_0;
		SELECT 
			v.ParOD, v.IdO, v.IdD, v.z_origen, v.z_destino, v.id_linea, v.nombre_linea, v.TieneCombinacion, v.ModoMultimodal,
			v.hora, v.pico_horario, v.distancia, v.empresa,
			CAST(COUNT(v.id_linea) AS INT) AS CantidadEtapas,
			SUM(SumaViajes) AS SumaViajes
		INTO '+QUOTENAME(@database)+'.dbo._2_base_etapas_por_linea_por_ParOD_TC_0
		FROM '+QUOTENAME(@database)+'.dbo._2_base_etapas_por_linea_por_ParOD v
		WHERE v.id_linea NOT IN (
			SELECT id_linea FROM #LineaIds
		)
		GROUP BY
			v.ParOD, v.IdO, v.IdD, v.z_origen, v.z_destino, v.id_linea, v.nombre_linea, v.empresa, v.TieneCombinacion, v.ModoMultimodal,
			v.hora, v.pico_horario, v.distancia
		HAVING v.TieneCombinacion = 0
		ORDER BY v.ParOD;';
	print @sql ;EXEC sp_executesql @sql;

	-- 5. Etapas por Linea TC_1
	SET @sql = 
		'DROP TABLE IF EXISTS '+QUOTENAME(@database)+'.dbo._2_1_base_etapas_por_linea_por_ParOD_TC_1;
		SELECT 
			v.ParOD, v.IdO, v.IdD, v.z_origen, v.z_destino, v.id_linea, v.nombre_linea, v.TieneCombinacion, v.ModoMultimodal,
			v.hora, v.pico_horario, v.distancia, v.empresa,
			CAST(COUNT(v.id_linea) AS INT) AS CantidadEtapas,
			SUM(SumaViajes) AS SumaViajes
		INTO '+QUOTENAME(@database)+'.dbo._2_1_base_etapas_por_linea_por_ParOD_TC_1
		FROM '+QUOTENAME(@database)+'.dbo._2_base_etapas_por_linea_por_ParOD v
		WHERE v.id_linea IN (
			SELECT id_linea FROM #LineaIds
		)
		GROUP BY
			v.ParOD, v.IdO, v.IdD, v.z_origen, v.z_destino, v.id_linea, v.nombre_linea, v.empresa, v.TieneCombinacion, v.ModoMultimodal,
			v.hora, v.pico_horario, v.distancia
		HAVING v.TieneCombinacion = 1
		ORDER BY v.ParOD;
		';
	print @sql ;EXEC sp_executesql @sql;

	-- 6. Base Top_Lineas
	SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@database)+'.dbo._2_base_viajes_top_lineas;
		SELECT 
			v.ParOD, v.ModoMultimodal, v.distancia, v.hora, v.pico_horario, v.IdO,v.IdD, v.z_origen,v.z_destino,	
			v.id_linea, v.nombre_linea , v.empresa, v.TieneCombinacion,
			COUNT(v.id_linea) AS CantidadEtapas
		INTO '+QUOTENAME(@database)+'.dbo._2_base_viajes_top_lineas
		FROM '+QUOTENAME(@database)+'.dbo._2_base_etapas_por_linea_por_ParOD v
		GROUP BY
			v.ParOD, v.ModoMultimodal, v.hora, v.pico_horario, v.distancia, v.IdO,v.IdD,
			v.z_origen,v.z_destino, v.id_linea, v.nombre_linea, v.empresa, v.TieneCombinacion
		ORDER BY 
			v.ParOD,v.distancia,v.ModoMultimodal;';
	print @sql ;EXEC sp_executesql @sql;

	-- 7. Base Combinaciones por Linea
	SET @sql = 
		'DROP TABLE IF EXISTS '+QUOTENAME(@database)+'.dbo._2_base_combinaciones_por_linea_porParOD;
		WITH ViajesMultimodales AS (
			SELECT DISTINCT
				v.ParOD, v.distancia, v.IdO, v.IdD, v.z_origen, v.z_destino, v.id_tarjeta, v.id_viaje, 
				v.ModoMultimodal, v.hora, v.pico_horario, v.TieneCombinacion, v.CombinacionesViaje, 
				v.NombreCombinacion, v.ViajesExpandidos, v.tren, v.autobus, v.metro, 
				v.cant_etapas, v.distance_h3, v.distance_osm_drive
			FROM '+QUOTENAME(@database)+'.[dbo]._2_base_viajes v
		)
		SELECT DISTINCT
			v.ParOD, v.distancia, v.ModoMultimodal, v.pico_horario, v.IdO, v.IdD,
			v.z_origen, v.z_destino, v.TieneCombinacion, v.NombreCombinacion,
			COUNT(v.NombreCombinacion) AS CantidadRepeticiones,
			SUM(v.ViajesExpandidos) AS SumaViajes
		INTO '+QUOTENAME(@database)+'.dbo._2_base_combinaciones_por_linea_porParOD
		FROM ViajesMultimodales v
		GROUP BY
			v.ParOD, v.distancia, v.ModoMultimodal, v.pico_horario, v.IdO, v.IdD,
			v.z_origen, v.z_destino, v.TieneCombinacion, v.NombreCombinacion
		ORDER BY v.ParOD;';
	print @sql ;EXEC sp_executesql @sql;

	-- 8. Combinaciones TC_0
	SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@database)+'.dbo._2_2_base_combinaciones_por_linea_porParOD_TC_0;
		SELECT DISTINCT
			v.ParOD, v.distancia, v.ModoMultimodal, v.pico_horario, v.IdO, v.IdD,
			v.z_origen, v.z_destino, v.TieneCombinacion, v.NombreCombinacion,
			COUNT(v.NombreCombinacion) AS CantidadRepeticiones,
			SUM(v.SumaViajes) AS SumaViajes
		INTO '+QUOTENAME(@database)+'.dbo. _2_2_base_combinaciones_por_linea_porParOD_TC_0
		FROM '+QUOTENAME(@database)+'.dbo._2_base_combinaciones_por_linea_porParOD v
		WHERE v.TieneCombinacion = 0
		GROUP BY
			v.ParOD, v.distancia, v.ModoMultimodal, v.pico_horario, v.IdO, v.IdD,
			v.z_origen, v.z_destino, v.TieneCombinacion, v.NombreCombinacion
		ORDER BY v.ParOD;';
	print @sql ;EXEC sp_executesql @sql;

	-- 9. Combinaciones TC_1
	SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@database)+'.dbo._2_1_base_combinaciones_por_linea_porParOD_TC_1;
		SELECT DISTINCT
			v.ParOD, v.distancia, v.ModoMultimodal, v.pico_horario, v.IdO, v.IdD,
			v.z_origen, v.z_destino, v.TieneCombinacion, v.NombreCombinacion,
			COUNT(v.NombreCombinacion) AS CantidadRepeticiones,
			SUM(v.SumaViajes) AS SumaViajes
		INTO '+QUOTENAME(@database)+'.dbo. _2_1_base_combinaciones_por_linea_porParOD_TC_1
		FROM '+QUOTENAME(@database)+'.dbo._2_base_combinaciones_por_linea_porParOD v
		WHERE v.TieneCombinacion = 1
		GROUP BY
			v.ParOD, v.distancia, v.ModoMultimodal, v.pico_horario, v.IdO, v.IdD,
			v.z_origen, v.z_destino, v.TieneCombinacion, v.NombreCombinacion
		ORDER BY v.ParOD;';
	print @sql ;EXEC sp_executesql @sql;

	-- 10. Zonificacion del corredor
	SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@database)+'.dbo._2_base_zonas_unicas_totales;
		WITH ViajesMultimodales AS (
			SELECT 
				v.ModoMultimodal,
				v.TieneCombinacion,
				v.IdO, v.IdD,
				v.z_origen, v.z_destino,
				v.ViajesExpandidos
			FROM '+QUOTENAME(@database)+'.[dbo]._2_base_viajes v
		),
		ViajesPorZonaOrigen AS (
			SELECT 
				v.IdO AS Zona,
				v.z_origen AS Nombre,
				SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVO'' AND v.TieneCombinacion = 0 THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivo_tc_0,
				SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVO'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivo_tc_1, 
				-- COLECTIVOx2
				SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVOx2'' AND v.TieneCombinacion = 0 THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivox2_tc_0,
				SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVOx2'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivox2_tc_1,
				-- COLECTIVOx3
				SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVOx3'' AND v.TieneCombinacion = 0 THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivox3_tc_0,
				SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVOx3'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivox3_tc_1,
				-- COLECTIVO+4
				SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVO+4'' AND v.TieneCombinacion = 0 THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivoMas4_tc_0,
				SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVO+4'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivoMas4_tc_1,
				-- SUBTE
				SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTE'' AND v.TieneCombinacion = 0 THEN v.ViajesExpandidos ELSE 0 END) AS v_subte_tc_0,
				SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTE'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_subte_tc_1,
				-- SUBTEx2
				SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTEX2'' AND v.TieneCombinacion = 0 THEN v.ViajesExpandidos ELSE 0 END) AS v_subtex2_tc_0,
				SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTEX2'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_subtex2_tc_1,
				-- SUBTEx3
				SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTEx3'' AND v.TieneCombinacion = 0 THEN v.ViajesExpandidos ELSE 0 END) AS v_subtex3_tc_0,
				SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTEx3'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_subtex3_tc_1,
				-- SUBTE+4
				SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTE+4'' AND v.TieneCombinacion = 0 THEN v.ViajesExpandidos ELSE 0 END) AS v_subteMas4_tc_0,
				SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTE+4'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_subteMas4_tc_1,
				-- TREN
				SUM(CASE WHEN v.ModoMultimodal = ''C-TREN'' AND v.TieneCombinacion = 0 THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_tc_0,
				SUM(CASE WHEN v.ModoMultimodal = ''C-TREN'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_tc_1,';
	SET @sql = @SQL +
		'		-- TRENx2
				SUM(CASE WHEN v.ModoMultimodal = ''C-TRENx2'' AND v.TieneCombinacion = 0 THEN v.ViajesExpandidos ELSE 0 END) AS v_trenx2_tc_0,
				SUM(CASE WHEN v.ModoMultimodal = ''C-TRENx2'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_trenx2_tc_1,
				-- TREN+3
				SUM(CASE WHEN v.ModoMultimodal = ''C-TREN+3'' AND v.TieneCombinacion = 0 THEN v.ViajesExpandidos ELSE 0 END) AS v_trenMas3_tc_0,
				SUM(CASE WHEN v.ModoMultimodal = ''C-TREN+3'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_trenMas3_tc_1,
				-- COLECTIVO-SUBTE
				SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO-SUBTE'' AND v.TieneCombinacion = 0 THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivo_subte_tc_0,
				SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO-SUBTE'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivo_subte_tc_1,
				-- COLECTIVO+2-SUBTE
				SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO+2-SUBTE'' AND v.TieneCombinacion = 0 THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivoMas2_subte_tc_0,
				SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO+2-SUBTE'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivoMas2_subte_tc_1,
				-- COLECTIVO-SUBTE+2
				SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO-SUBTE+2'' AND v.TieneCombinacion = 0 THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivo_subteMas2_tc_0,
				SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO-SUBTE+2'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivo_subteMas2_tc_1,
				-- COLECTIVO+2-SUBTE+2
				SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO+2-SUBTE+2'' AND v.TieneCombinacion = 0 THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivoMas2_subteMas2_tc_0,
				SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO+2-SUBTE+2'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivoMas2_subteMas2_tc_1,
				-- TREN-COLECTIVO
				SUM(CASE WHEN v.ModoMultimodal = ''E-TREN-COLECTIVO'' AND v.TieneCombinacion = 0 THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_colectivo_tc_0,
				SUM(CASE WHEN v.ModoMultimodal = ''E-TREN-COLECTIVO'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_colectivo_tc_1,';
	SET @sql = @SQL +
		'		-- TREN+2-COLECTIVO
				SUM(CASE WHEN v.ModoMultimodal = ''E-TREN+2-COLECTIVO'' AND v.TieneCombinacion = 0 THEN v.ViajesExpandidos ELSE 0 END) AS v_treMas2_colectivo_tc_0,
				SUM(CASE WHEN v.ModoMultimodal = ''E-TREN+2-COLECTIVO'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_treMas2_colectivo_tc_1,
				-- TREN-COLECTIVO+2
				SUM(CASE WHEN v.ModoMultimodal = ''E-TREN-COLECTIVO+2'' AND v.TieneCombinacion = 0 THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_colectivoMas2_tc_0,
				SUM(CASE WHEN v.ModoMultimodal = ''E-TREN-COLECTIVO+2'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_colectivoMas2_tc_1,
				-- TREN-SUBTE
				SUM(CASE WHEN v.ModoMultimodal = ''F-TREN-SUBTE'' AND v.TieneCombinacion = 0 THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_subte_tc_0,
				SUM(CASE WHEN v.ModoMultimodal = ''F-TREN-SUBTE'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_subte_tc_1,
				-- TREN-COLECTIVO-SUBTE
				SUM(CASE WHEN v.ModoMultimodal = ''G-TREN-COLECTIVO-SUBTE'' AND v.TieneCombinacion = 0 THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_colectivo_subte_tc_0,
				SUM(CASE WHEN v.ModoMultimodal = ''G-TREN-COLECTIVO-SUBTE'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_colectivo_subte_tc_1,
				-- Totales generales
				SUM(CASE WHEN v.TieneCombinacion = 0 THEN v.ViajesExpandidos ELSE 0 END) AS v_totales_tc_0,
				SUM(CASE WHEN v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_totales_tc_1,
				SUM(v.ViajesExpandidos) AS v_totales
			FROM ViajesMultimodales v
			GROUP BY v.IdO, v.z_origen, v.TieneCombinacion
		),';
	SET @SQL = @SQL + 
		'ViajesPorZonaDestino AS (
			SELECT 
				v.IdD AS Zona,
				v.z_destino AS Nombre,
				SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVO'' AND v.TieneCombinacion = 0 THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivo_tc_0,
				SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVO'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivo_tc_1, 
				-- COLECTIVOx2
				SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVOx2'' AND v.TieneCombinacion = 0 THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivox2_tc_0,
				SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVOx2'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivox2_tc_1,
				-- COLECTIVOx3
				SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVOx3'' AND v.TieneCombinacion = 0 THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivox3_tc_0,
				SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVOx3'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivox3_tc_1,
				-- COLECTIVO+4
				SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVO+4'' AND v.TieneCombinacion = 0 THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivoMas4_tc_0,
				SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVO+4'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivoMas4_tc_1,
				-- SUBTE
				SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTE'' AND v.TieneCombinacion = 0 THEN v.ViajesExpandidos ELSE 0 END) AS v_subte_tc_0,
				SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTE'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_subte_tc_1,
				-- SUBTEx2
				SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTEX2'' AND v.TieneCombinacion = 0 THEN v.ViajesExpandidos ELSE 0 END) AS v_subtex2_tc_0,
				SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTEX2'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_subtex2_tc_1,
				-- SUBTEx3
				SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTEx3'' AND v.TieneCombinacion = 0 THEN v.ViajesExpandidos ELSE 0 END) AS v_subtex3_tc_0,
				SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTEx3'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_subtex3_tc_1,
				-- SUBTE+4
				SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTE+4'' AND v.TieneCombinacion = 0 THEN v.ViajesExpandidos ELSE 0 END) AS v_subteMas4_tc_0,
				SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTE+4'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_subteMas4_tc_1,
				-- TREN
				SUM(CASE WHEN v.ModoMultimodal = ''C-TREN'' AND v.TieneCombinacion = 0 THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_tc_0,
				SUM(CASE WHEN v.ModoMultimodal = ''C-TREN'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_tc_1,
				-- TRENx2
				SUM(CASE WHEN v.ModoMultimodal = ''C-TRENx2'' AND v.TieneCombinacion = 0 THEN v.ViajesExpandidos ELSE 0 END) AS v_trenx2_tc_0,';
	SET @sql = @SQL +
		'		SUM(CASE WHEN v.ModoMultimodal = ''C-TRENx2'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_trenx2_tc_1,
				-- TREN+3
				SUM(CASE WHEN v.ModoMultimodal = ''C-TREN+3'' AND v.TieneCombinacion = 0 THEN v.ViajesExpandidos ELSE 0 END) AS v_trenMas3_tc_0,
				SUM(CASE WHEN v.ModoMultimodal = ''C-TREN+3'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_trenMas3_tc_1,
				-- COLECTIVO-SUBTE
				SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO-SUBTE'' AND v.TieneCombinacion = 0 THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivo_subte_tc_0,
				SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO-SUBTE'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivo_subte_tc_1,
				-- COLECTIVO+2-SUBTE
				SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO+2-SUBTE'' AND v.TieneCombinacion = 0 THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivoMas2_subte_tc_0,
				SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO+2-SUBTE'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivoMas2_subte_tc_1,
				-- COLECTIVO-SUBTE+2
				SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO-SUBTE+2'' AND v.TieneCombinacion = 0 THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivo_subteMas2_tc_0,
				SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO-SUBTE+2'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivo_subteMas2_tc_1,
				-- COLECTIVO+2-SUBTE+2
				SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO+2-SUBTE+2'' AND v.TieneCombinacion = 0 THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivoMas2_subteMas2_tc_0,
				SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO+2-SUBTE+2'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivoMas2_subteMas2_tc_1,
				-- TREN-COLECTIVO
				SUM(CASE WHEN v.ModoMultimodal = ''E-TREN-COLECTIVO'' AND v.TieneCombinacion = 0 THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_colectivo_tc_0,
				SUM(CASE WHEN v.ModoMultimodal = ''E-TREN-COLECTIVO'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_colectivo_tc_1,';
	SET @sql = @SQL +
		'		-- TREN+2-COLECTIVO
				SUM(CASE WHEN v.ModoMultimodal = ''E-TREN+2-COLECTIVO'' AND v.TieneCombinacion = 0 THEN v.ViajesExpandidos ELSE 0 END) AS v_treMas2_colectivo_tc_0,
				SUM(CASE WHEN v.ModoMultimodal = ''E-TREN+2-COLECTIVO'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_treMas2_colectivo_tc_1,
				-- TREN-COLECTIVO+2
				SUM(CASE WHEN v.ModoMultimodal = ''E-TREN-COLECTIVO+2'' AND v.TieneCombinacion = 0 THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_colectivoMas2_tc_0,
				SUM(CASE WHEN v.ModoMultimodal = ''E-TREN-COLECTIVO+2'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_colectivoMas2_tc_1,
				-- TREN-SUBTE
				SUM(CASE WHEN v.ModoMultimodal = ''F-TREN-SUBTE'' AND v.TieneCombinacion = 0 THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_subte_tc_0,
				SUM(CASE WHEN v.ModoMultimodal = ''F-TREN-SUBTE'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_subte_tc_1,
				-- TREN-COLECTIVO-SUBTE
				SUM(CASE WHEN v.ModoMultimodal = ''G-TREN-COLECTIVO-SUBTE'' AND v.TieneCombinacion = 0 THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_colectivo_subte_tc_0,
				SUM(CASE WHEN v.ModoMultimodal = ''G-TREN-COLECTIVO-SUBTE'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_colectivo_subte_tc_1,
				-- Totales generales
				SUM(CASE WHEN v.TieneCombinacion = 0 THEN v.ViajesExpandidos ELSE 0 END) AS v_totales_tc_0,
				SUM(CASE WHEN v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_totales_tc_1,
				SUM(v.ViajesExpandidos) AS v_totales
			FROM ViajesMultimodales v
			GROUP BY v.IdD, v.z_destino,v.TieneCombinacion
		)';
	SET @SQL = @SQL +
		'SELECT 
			o.Zona,
			o.Nombre,
		--	z.zona_deriv,
		--	z.zona_deriv_tipo,
			SUM(COALESCE(o.v_colectivo_tc_0, 0) + COALESCE(d.v_colectivo_tc_0, 0))/4 AS v_colectivo_tc_0,
			SUM(COALESCE(o.v_colectivo_tc_1, 0) + COALESCE(d.v_colectivo_tc_1, 0))/4 AS v_colectivo_tc_1,
			SUM(COALESCE(o.v_colectivox2_tc_0, 0) + COALESCE(d.v_colectivox2_tc_0, 0))/4 AS v_colectivox2_tc_0,
			SUM(COALESCE(o.v_colectivox2_tc_1, 0) + COALESCE(d.v_colectivox2_tc_1, 0))/4 AS v_colectivox2_tc_1,
			SUM(COALESCE(o.v_colectivox3_tc_0, 0) + COALESCE(d.v_colectivox3_tc_0, 0))/4 AS v_colectivox3_tc_0,
			SUM(COALESCE(o.v_colectivox3_tc_1, 0) + COALESCE(d.v_colectivox3_tc_1, 0))/4 AS v_colectivox3_tc_1,
			SUM(COALESCE(o.v_colectivoMas4_tc_0, 0) + COALESCE(d.v_colectivoMas4_tc_0, 0))/4 AS v_colectivoMas4_tc_0,
			SUM(COALESCE(o.v_colectivoMas4_tc_1, 0) + COALESCE(d.v_colectivoMas4_tc_1, 0))/4 AS v_colectivoMas4_tc_1,
			SUM(COALESCE(o.v_subte_tc_0, 0) + COALESCE(d.v_subte_tc_0, 0))/4 AS v_subte_tc_0,
			SUM(COALESCE(o.v_subte_tc_1, 0) + COALESCE(d.v_subte_tc_1, 0))/4 AS v_subte_tc_1,
			SUM(COALESCE(o.v_subtex2_tc_0, 0) + COALESCE(d.v_subtex2_tc_0, 0))/4 AS v_subtex2_tc_0,
			SUM(COALESCE(o.v_subtex2_tc_1, 0) + COALESCE(d.v_subtex2_tc_1, 0))/4 AS v_subtex2_tc_1,
			SUM(COALESCE(o.v_subtex3_tc_0, 0) + COALESCE(d.v_subtex3_tc_0, 0))/4 AS v_subtex3_tc_0,
			SUM(COALESCE(o.v_subtex3_tc_1, 0) + COALESCE(d.v_subtex3_tc_1, 0))/4 AS v_subtex3_tc_1,
			SUM(COALESCE(o.v_subteMas4_tc_0, 0) + COALESCE(d.v_subteMas4_tc_0, 0))/4 AS v_subteMas4_tc_0,
			SUM(COALESCE(o.v_subteMas4_tc_1, 0) + COALESCE(d.v_subteMas4_tc_1, 0))/4 AS v_subteMas4_tc_1,
			SUM(COALESCE(o.v_tren_tc_0, 0) + COALESCE(d.v_tren_tc_0, 0))/4 AS v_tren_tc_0,
			SUM(COALESCE(o.v_tren_tc_1, 0) + COALESCE(d.v_tren_tc_1, 0))/4 AS v_tren_tc_1,
			SUM(COALESCE(o.v_trenx2_tc_0, 0) + COALESCE(d.v_trenx2_tc_0, 0))/4 AS v_trenx2_tc_0,
			SUM(COALESCE(o.v_trenx2_tc_1, 0) + COALESCE(d.v_trenx2_tc_1, 0))/4 AS v_trenx2_tc_1,
			SUM(COALESCE(o.v_trenMas3_tc_0, 0) + COALESCE(d.v_trenMas3_tc_0, 0))/4 AS v_trenMas3_tc_0,
			SUM(COALESCE(o.v_trenMas3_tc_1, 0) + COALESCE(d.v_trenMas3_tc_1, 0))/4 AS v_trenMas3_tc_1,
			SUM(COALESCE(o.v_colectivo_subte_tc_0, 0) + COALESCE(d.v_colectivo_subte_tc_0, 0))/4 AS v_colectivo_subte_tc_0,
			SUM(COALESCE(o.v_colectivo_subte_tc_1, 0) + COALESCE(d.v_colectivo_subte_tc_1, 0))/4 AS v_colectivo_subte_tc_1,
			SUM(COALESCE(o.v_colectivoMas2_subte_tc_0, 0) + COALESCE(d.v_colectivoMas2_subte_tc_0, 0))/4 AS v_colectivoMas2_subte_tc_0,
			SUM(COALESCE(o.v_colectivoMas2_subte_tc_1, 0) + COALESCE(d.v_colectivoMas2_subte_tc_1, 0))/4 AS v_colectivoMas2_subte_tc_1,
			SUM(COALESCE(o.v_colectivo_subteMas2_tc_0, 0) + COALESCE(d.v_colectivo_subteMas2_tc_0, 0))/4 AS v_colectivo_subteMas2_tc_0,
			SUM(COALESCE(o.v_colectivo_subteMas2_tc_1, 0) + COALESCE(d.v_colectivo_subteMas2_tc_1, 0))/4 AS v_colectivo_subteMas2_tc_1,
			SUM(COALESCE(o.v_colectivoMas2_subteMas2_tc_0, 0) + COALESCE(d.v_colectivoMas2_subteMas2_tc_0, 0))/4 AS v_colectivoMas2_subteMas2_tc_0,
			SUM(COALESCE(o.v_colectivoMas2_subteMas2_tc_1, 0) + COALESCE(d.v_colectivoMas2_subteMas2_tc_1, 0))/4 AS v_colectivoMas2_subteMas2_tc_1,
			SUM(COALESCE(o.v_tren_colectivo_tc_0, 0) + COALESCE(d.v_tren_colectivo_tc_0, 0))/4 AS v_tren_colectivo_tc_0,';
	SET @sql = @SQL +
		'	SUM(COALESCE(o.v_tren_colectivo_tc_1, 0) + COALESCE(d.v_tren_colectivo_tc_1, 0))/4 AS v_tren_colectivo_tc_1,
			SUM(COALESCE(o.v_treMas2_colectivo_tc_0, 0) + COALESCE(d.v_treMas2_colectivo_tc_0, 0))/4 AS v_treMas2_colectivo_tc_0,
			SUM(COALESCE(o.v_treMas2_colectivo_tc_1, 0) + COALESCE(d.v_treMas2_colectivo_tc_1, 0))/4 AS v_treMas2_colectivo_tc_1,
			SUM(COALESCE(o.v_tren_colectivoMas2_tc_0, 0) + COALESCE(d.v_tren_colectivoMas2_tc_0, 0))/4 AS v_tren_colectivoMas2_tc_0,
			SUM(COALESCE(o.v_tren_colectivoMas2_tc_1, 0) + COALESCE(d.v_tren_colectivoMas2_tc_1, 0))/4 AS v_tren_colectivoMas2_tc_1,
			SUM(COALESCE(o.v_tren_subte_tc_0, 0) + COALESCE(d.v_tren_subte_tc_0, 0))/4 AS v_tren_subte_tc_0,
			SUM(COALESCE(o.v_tren_subte_tc_1, 0) + COALESCE(d.v_tren_subte_tc_1, 0))/4 AS v_tren_subte_tc_1,
			SUM(COALESCE(o.v_tren_colectivo_subte_tc_0, 0) + COALESCE(d.v_tren_colectivo_subte_tc_0, 0))/4 AS v_tren_colectivo_subte_tc_0,
			SUM(COALESCE(o.v_tren_colectivo_subte_tc_1, 0) + COALESCE(d.v_tren_colectivo_subte_tc_1, 0))/4 AS v_tren_colectivo_subte_tc_1,
			SUM(COALESCE(o.v_totales_tc_0, 0) + COALESCE(d.v_totales_tc_0, 0))/4 AS v_totales_tc_0,
			SUM(COALESCE(o.v_totales_tc_1, 0) + COALESCE(d.v_totales_tc_1, 0))/4 AS v_totales_tc_1,
			SUM(COALESCE(o.v_totales, 0) + COALESCE(d.v_totales, 0))/4 AS v_totales
		INTO '+QUOTENAME(@database)+'.dbo._2_base_zonas_unicas_totales
		FROM ViajesPorZonaOrigen o
		FULL OUTER JOIN ViajesPorZonaDestino d ON o.Zona = d.Zona 
		--JOIN [Base].[dbo].[zonas_san_martin] z ON z.Id = o.Zona -- Cambiar zona por Corrida
		GROUP BY o.Zona, o.Nombre	--,z.zona_deriv,	z.zona_deriv_tipo
		ORDER BY o.Nombre;
		DELETE FROM '+QUOTENAME(@database)+'.dbo._2_base_zonas_unicas_totales WHERE Zona = '''' OR Zona IS NULL;';
	print @sql ;EXEC sp_executesql @sql;

	-- Confirmar transacci�n
	COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
 ROLLBACK TRANSACTION;
	PRINT 'Error Message: ' + ERROR_MESSAGE();
    PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10));
    PRINT 'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10));
    PRINT 'Error State: ' + CAST(ERROR_STATE() AS VARCHAR(10));
    PRINT 'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10));
    PRINT 'Error Procedure: ' + ERROR_PROCEDURE();
END CATCH;
END;
