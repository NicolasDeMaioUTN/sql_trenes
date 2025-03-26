USE [Base]
GO
/****** Object:  StoredProcedure [dbo].[_001_1_Viajes_Propios]    Script Date: 26/3/2025 12:42:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[_001_1_Viajes_Propios]
 @Database NVARCHAR(15), -- Base de datos = Linea de analisis
 @IdLinea NVARCHAR(50), -- Se debe utilizar id_linea "123.0"
 @BasePares NVARCHAR(20) -- Nombre de la base de pares a crear
AS
BEGIN
 BEGIN TRY
	BEGIN TRANSACTION;
	DECLARE @sql NVARCHAR(MAX);
		-- 1. Creo tabla inicial viajes | _1_viajes
		SET @sql = 
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._1_viajes;
		SELECT DISTINCT 
			CONCAT(v.Ido, ''---'', v.Idd) AS ParOD, -- Par OD
			v.id_tarjeta, v.id_viaje, v.hora, -- Datos tarjeta
			v.IdO, v.IdD, -- Reemplazo de IdO e IdD por h3_o y h3_d
			o.zonas AS z_origen, d.zonas AS z_destino, -- Zona microzonas
			STRING_AGG(CAST(e.id_linea AS NVARCHAR(MAX)), ''-'') WITHIN GROUP (ORDER BY e.id_etapa) AS CombinacionesViaje,
			STRING_AGG(CAST(l.nombre_linea AS NVARCHAR(MAX)), ''-'') WITHIN GROUP (ORDER BY e.id_etapa) AS NombreCombinacion,
			STRING_AGG(CAST(l.modo AS NVARCHAR(MAX)), ''-'') WITHIN GROUP (ORDER BY e.id_etapa) AS ModoCombinacion,
			CAST(v.factor_expansion_linea AS FLOAT) AS ViajesExpandidos,
			CAST(v.tren AS INT) AS tren,
			CAST(v.autobus AS INT) AS autobus,
			CAST(v.metro AS INT) AS metro,
			CAST(v.cant_etapas AS INT) AS cant_etapas,
			CAST (v.distance_H3 AS FLOAT) AS distance_h3,
			CAST (v.distance_osm_drive AS FLOAT) AS distance_osm_drive
		INTO '+QUOTENAME(@Database)+'.dbo._1_viajes
		FROM [Base].[dbo].[viajes] v
		LEFT JOIN [Base].[dbo].[etapas] e ON v.id_tarjeta = e.id_tarjeta AND v.id_viaje = e.id_viaje
		LEFT JOIN [Base].[dbo].[microzonas] o ON v.ido = o.id -- Se cambió de IdO a h3_o
		LEFT JOIN [Base].[dbo].[microzonas] d ON v.idd = d.id -- Se cambió de IdD a h3_d
		LEFT JOIN [Base].[dbo].[lineas] l ON e.id_linea = l.id_linea
		WHERE EXISTS (
			SELECT 1
			FROM [Base].[dbo].[etapas] e2
			WHERE e2.id_tarjeta = v.id_tarjeta 
				AND e2.id_viaje = v.id_viaje 
				AND e2.id_linea = '+QUOTENAME(@IdLinea,'''')+' -- Linea Buscada
		)
		GROUP BY v.IdO, v.IdD, v.distance_h3, v.distance_osm_drive, v.id_tarjeta, v.id_viaje, v.hora, o.zonas, d.zonas, v.factor_expansion_linea, v.tren, v.autobus, v.metro, v.cant_etapas;';
		EXEC sp_executesql @sql, N'@IdLinea NVARCHAR(10)', @IdLinea;


		-- 2. Borro Base Viajes
		SET @sql = 'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._1_base_viajes;';
		EXEC sp_executesql @sql;

		-- 3. Creo Base Viajes
		SET @sql = 'SELECT DISTINCT 
				CASE
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
					WHEN (v.tren = 0 AND v.autobus >= 2 AND v.metro >= 2) THEN ''D-COLECTIVO+2-SUBTE+2''
					WHEN (v.tren = 0 AND v.autobus = 1 AND v.metro >= 2) THEN ''D-COLECTIVO-SUBTE+2''
					WHEN (v.tren = 1 AND v.autobus = 1 AND v.metro = 0) THEN ''E-TREN-COLECTIVO''
					WHEN (v.tren >= 2 AND v.autobus = 1 AND v.metro = 0) THEN ''E-TREN+2-COLECTIVO''
					WHEN (v.tren = 1 AND v.autobus >= 2 AND v.metro = 0) THEN ''E-TREN-COLECTIVO+2''
					WHEN (v.tren >= 2 AND v.autobus >= 2 AND v.metro = 0) THEN ''E-TREN+2-COLECTIVO+2''
				';
		SET @sql = @sql + '
				WHEN (v.tren >= 1 AND v.autobus = 0 AND v.metro >= 1) THEN ''F-TREN-SUBTE''
				WHEN (v.tren >= 1 AND v.autobus >= 1 AND v.metro >= 1) THEN ''G-TREN-COLECTIVO-SUBTE''
				ELSE ''Null''
			END AS ModoMultimodal,
			CASE
				WHEN AVG(CAST(v.distance_osm_drive AS FLOAT)) >= 90 THEN ''90--100''
				WHEN AVG(CAST(v.distance_osm_drive AS FLOAT)) >= 80 AND AVG(CAST(v.distance_osm_drive AS FLOAT)) < 90 THEN ''80---90''
				WHEN AVG(CAST(v.distance_osm_drive AS FLOAT)) >= 70 AND AVG(CAST(v.distance_osm_drive AS FLOAT)) < 80 THEN ''70---80''
				WHEN AVG(CAST(v.distance_osm_drive AS FLOAT)) >= 60 AND AVG(CAST(v.distance_osm_drive AS FLOAT)) < 70 THEN ''60---70''
				WHEN AVG(CAST(v.distance_osm_drive AS FLOAT)) >= 50 AND AVG(CAST(v.distance_osm_drive AS FLOAT)) < 60 THEN ''50---60''
				WHEN AVG(CAST(v.distance_osm_drive AS FLOAT)) >= 40 AND AVG(CAST(v.distance_osm_drive AS FLOAT)) < 50 THEN ''40---50''
				WHEN AVG(CAST(v.distance_osm_drive AS FLOAT)) >= 30 AND AVG(CAST(v.distance_osm_drive AS FLOAT)) < 40 THEN ''30---40''
				WHEN AVG(CAST(v.distance_osm_drive AS FLOAT)) >= 20 AND AVG(CAST(v.distance_osm_drive AS FLOAT)) < 30 THEN ''20---30''
				WHEN AVG(CAST(v.distance_osm_drive AS FLOAT)) >= 10 AND AVG(CAST(v.distance_osm_drive AS FLOAT)) < 20 THEN ''10---20''
				WHEN AVG(CAST(v.distance_osm_drive AS FLOAT)) >= 5 AND AVG(CAST(v.distance_osm_drive AS FLOAT)) < 10 THEN ''05---10''
				WHEN AVG(CAST(v.distance_osm_drive AS FLOAT)) >= 2 AND AVG(CAST(v.distance_osm_drive AS FLOAT)) < 5 THEN ''02---05''
				WHEN AVG(CAST(v.distance_osm_drive AS FLOAT)) < 2 THEN ''00---02''
			END AS distancia
			';
		SET @sql = @sql + '
			,CASE
				WHEN v.hora BETWEEN 0 AND 7 THEN ''1 - madrugada''
				WHEN v.hora BETWEEN 7 AND 10 THEN ''2 - pico_ma�ana''
				WHEN v.hora BETWEEN 10 AND 16 THEN ''3 - mediodia''
				WHEN v.hora BETWEEN 16 AND 19 THEN ''4 - pico_tarde''
				WHEN v.hora BETWEEN 19 AND 24 THEN ''5 - noche''
				ELSE ''null''
			END AS pico_horario,
			v.ParOD,
			v.id_tarjeta, v.id_viaje, v.hora,
			v.IdO, 
			v.IdD, 
			v.z_origen, v.z_destino, 
			v.ViajesExpandidos,
			v.tren, v.autobus, v.metro, v.cant_etapas,
			v.distance_h3, v.distance_osm_drive
			INTO '+QUOTENAME(@Database)+'.dbo._1_base_viajes
			FROM '+QUOTENAME(@Database)+'.dbo._1_viajes v
			GROUP BY
			CASE
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
				WHEN (v.tren = 0 AND v.autobus >= 2 AND v.metro >= 2) THEN ''D-COLECTIVO+2-SUBTE+2''
				WHEN (v.tren = 0 AND v.autobus = 1 AND v.metro >= 2) THEN ''D-COLECTIVO-SUBTE+2''
				WHEN (v.tren = 1 AND v.autobus = 1 AND v.metro = 0) THEN ''E-TREN-COLECTIVO''
				WHEN (v.tren >= 2 AND v.autobus = 1 AND v.metro = 0) THEN ''E-TREN+2-COLECTIVO''
				WHEN (v.tren = 1 AND v.autobus >= 2 AND v.metro = 0) THEN ''E-TREN-COLECTIVO+2''
				WHEN (v.tren >= 2 AND v.autobus >= 2 AND v.metro = 0) THEN ''E-TREN+2-COLECTIVO+2''
				WHEN (v.tren >= 1 AND v.autobus = 0 AND v.metro >= 1) THEN ''F-TREN-SUBTE''
				WHEN (v.tren >= 1 AND v.autobus >= 1 AND v.metro >= 1) THEN ''G-TREN-COLECTIVO-SUBTE''
			END,
			v.ParOD,
			v.id_tarjeta, v.id_viaje, v.hora,
			v.IdO, 
			v.IdD, 
			v.z_origen, v.z_destino,
			v.ViajesExpandidos,
			v.tren, v.autobus, v.metro, v.cant_etapas,
			v.distance_h3, v.distance_osm_drive;';
		EXEC sp_executesql @sql;

		-- 4. Borro Viajes inicial
		SET @sql = 'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.[dbo]._1_viajes;';
		EXEC sp_executesql @sql;

		-- 5. Creo Base Pares OD
		SET @sql = 'DROP TABLE IF EXISTS Base.[dbo].'+QUOTENAME(@BasePares)+';';		
		EXEC sp_executesql @sql;		

		SET @sql = 
			'SELECT DISTINCT b.ParOD, b.IdO, b.z_origen, b.IdD, b.z_destino
			INTO [Base].[dbo].'+QUOTENAME(@BasePares)+'
			FROM '+QUOTENAME(@Database)+'.[dbo].[_1_base_viajes] b
			WHERE (b.IdO <> '''' OR b.IdO IS NOT NULL) 
			AND (b.IdD <> '''' OR b.IdD IS NOT NULL);';
		EXEC sp_executesql @sql;		
			
		SET @sql = 'DELETE FROM Base.[dbo].'+QUOTENAME(@BasePares)+' WHERE ParOD = '''' OR ParOD IS NULL;';
		EXEC sp_executesql @sql;

		-- 6. Zonificacion de Viajes Propios
		SET @sql = 'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._1_base_zonas_unicas_totales;';
		EXEC sp_executesql @sql;

		SET @sql = 
			'WITH ViajesMultimodales AS (
				SELECT 
					v.ModoMultimodal,
					v.IdO, v.IdD,
					v.z_origen, v.z_destino,
					v.ViajesExpandidos
				FROM ' + QUOTENAME(@Database) + '.[dbo]._1_base_viajes v
			),
			ViajesPorZonaOrigen AS (
				SELECT 
					v.IdO AS Zona,
					v.z_origen AS Nombre,
					SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVO'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivo,
					SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVOx2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivox2,
					SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVOx3'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivox3,
					SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVO+4'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivoMas4,
					SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_subte,
					SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTEX2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_subtex2,
					SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTEx3'' THEN v.ViajesExpandidos ELSE 0 END) AS v_subtex3,
					SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTE+4'' THEN v.ViajesExpandidos ELSE 0 END) AS v_subteMas4,
					SUM(CASE WHEN v.ModoMultimodal = ''C-TREN'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren,
					SUM(CASE WHEN v.ModoMultimodal = ''C-TRENx2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_trenx2,
					SUM(CASE WHEN v.ModoMultimodal = ''C-TREN+3'' THEN v.ViajesExpandidos ELSE 0 END) AS v_trenMas3,
					SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivo_subte,
					SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO+2-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivoMas2_subte,
					SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO-SUBTE+2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivo_subteMas2,
					SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO+2-SUBTE+2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivoMas2_subteMas2,
					SUM(CASE WHEN v.ModoMultimodal = ''E-TREN-COLECTIVO'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_colectivo,
					SUM(CASE WHEN v.ModoMultimodal = ''E-TREN+2-COLECTIVO'' THEN v.ViajesExpandidos ELSE 0 END) AS v_trenMas2_colectivo,
					SUM(CASE WHEN v.ModoMultimodal = ''E-TREN-COLECTIVO+2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_colectivoMas2,
					SUM(CASE WHEN v.ModoMultimodal = ''F-TREN-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_subte,
					SUM(CASE WHEN v.ModoMultimodal = ''G-TREN-COLECTIVO-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_colectivo_subte,
					SUM(v.ViajesExpandidos) AS v_totales
				FROM ViajesMultimodales v
				GROUP BY v.IdO, v.z_origen
			),';
		SET @sql = @sql + '
			ViajesPorZonaDestino AS (
				SELECT 
					v.IdD AS Zona,
					v.z_destino AS Nombre,
					SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVO'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivo,
					SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVOx2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivox2,
					SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVOx3'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivox3,
					SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVO+4'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivoMas4,
					SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_subte,
					SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTEX2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_subtex2,
					SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTEx3'' THEN v.ViajesExpandidos ELSE 0 END) AS v_subtex3,
					SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTE+4'' THEN v.ViajesExpandidos ELSE 0 END) AS v_subteMas4,
					SUM(CASE WHEN v.ModoMultimodal = ''C-TREN'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren,
					SUM(CASE WHEN v.ModoMultimodal = ''C-TRENx2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_trenx2,
					SUM(CASE WHEN v.ModoMultimodal = ''C-TREN+3'' THEN v.ViajesExpandidos ELSE 0 END) AS v_trenMas3,
					SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivo_subte,
					SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO+2-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivoMas2_subte,
					SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO-SUBTE+2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivo_subteMas2,
					SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO+2-SUBTE+2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivoMas2_subteMas2,
					SUM(CASE WHEN v.ModoMultimodal = ''E-TREN-COLECTIVO'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_colectivo,
					SUM(CASE WHEN v.ModoMultimodal = ''E-TREN+2-COLECTIVO'' THEN v.ViajesExpandidos ELSE 0 END) AS v_trenMas2_colectivo,
					SUM(CASE WHEN v.ModoMultimodal = ''E-TREN-COLECTIVO+2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_colectivoMas2,
					SUM(CASE WHEN v.ModoMultimodal = ''F-TREN-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_subte,
					SUM(CASE WHEN v.ModoMultimodal = ''G-TREN-COLECTIVO-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_colectivo_subte,
					SUM(v.ViajesExpandidos) AS v_totales
				FROM ViajesMultimodales v
				GROUP BY v.IdD, v.z_destino
			)';
		SET @sql = @sql + '
			SELECT 
				o.Zona,
				o.Nombre,
				SUM(COALESCE(o.v_colectivo, 0) + COALESCE(d.v_colectivo, 0)) / 2 AS v_colectivo,
				SUM(COALESCE(o.v_colectivox2, 0) + COALESCE(d.v_colectivox2, 0)) / 2 AS v_colectivox2,
				SUM(COALESCE(o.v_colectivox3, 0) + COALESCE(d.v_colectivox3, 0)) / 2 AS v_colectivox3,
				SUM(COALESCE(o.v_colectivoMas4, 0) + COALESCE(d.v_colectivoMas4, 0)) / 2 AS v_colectivoMas4,
				SUM(COALESCE(o.v_subte, 0) + COALESCE(d.v_subte, 0)) / 2 AS v_subte,
				SUM(COALESCE(o.v_subtex2, 0) + COALESCE(d.v_subtex2, 0)) / 2 AS v_subtex2,
				SUM(COALESCE(o.v_subtex3, 0) + COALESCE(d.v_subtex3, 0)) / 2 AS v_subtex3,
				SUM(COALESCE(o.v_subteMas4, 0) + COALESCE(d.v_subteMas4, 0)) / 2 AS v_subteMas4,
				SUM(COALESCE(o.v_tren, 0) + COALESCE(d.v_tren, 0)) / 2 AS v_tren,
				SUM(COALESCE(o.v_trenx2, 0) + COALESCE(d.v_trenx2, 0)) / 2 AS v_trenx2,
				SUM(COALESCE(o.v_trenMas3, 0) + COALESCE(d.v_trenMas3, 0)) / 2 AS v_trenMas3,
				SUM(COALESCE(o.v_colectivo_subte, 0) + COALESCE(d.v_colectivo_subte, 0)) / 2 AS v_colectivo_subte,
				SUM(COALESCE(o.v_colectivoMas2_subte, 0) + COALESCE(d.v_colectivoMas2_subte, 0)) / 2 AS v_colectivoMas2_subte,
				SUM(COALESCE(o.v_colectivo_subteMas2, 0) + COALESCE(d.v_colectivo_subteMas2, 0)) / 2 AS v_colectivo_subteMas2,
				SUM(COALESCE(o.v_colectivoMas2_subteMas2, 0) + COALESCE(d.v_colectivoMas2_subteMas2, 0)) / 2 AS v_colectivoMas2_subteMas2,
				SUM(COALESCE(o.v_tren_colectivo, 0) + COALESCE(d.v_tren_colectivo, 0)) / 2 AS v_tren_colectivo,
				SUM(COALESCE(o.v_trenMas2_colectivo, 0) + COALESCE(d.v_trenMas2_colectivo, 0)) / 2 AS v_trenMas2_colectivo,
				SUM(COALESCE(o.v_tren_colectivoMas2, 0) + COALESCE(d.v_tren_colectivoMas2, 0)) / 2 AS v_tren_colectivoMas2,
				SUM(COALESCE(o.v_tren_subte, 0) + COALESCE(d.v_tren_subte, 0)) / 2 AS v_tren_subte,
				SUM(COALESCE(o.v_tren_colectivo_subte, 0) + COALESCE(d.v_tren_colectivo_subte, 0)) / 2 AS v_tren_colectivo_subte,
				SUM(COALESCE(o.v_totales, 0) + COALESCE(d.v_totales, 0)) / 2 AS v_totales
			INTO ' + QUOTENAME(@Database) + '.[dbo]._1_base_zonas_unicas_totales
			FROM ViajesPorZonaOrigen o
			FULL OUTER JOIN ViajesPorZonaDestino d ON o.Zona = d.Zona 
			GROUP BY o.Zona, o.Nombre
			ORDER BY o.Nombre;';	 
		EXEC sp_executesql @sql;

		SET @sql = 'DELETE FROM '+QUOTENAME(@Database)+'.[dbo]._1_base_zonas_unicas_totales WHERE Zona = '''' OR Zona IS NULL;';
		EXEC sp_executesql @sql;

	-- Confirmar transacci�n
	COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
 ROLLBACK TRANSACTION;
	PRINT 'Error en la transacci�n: ' + ERROR_MESSAGE();
 	PRINT 'Procedimiento: ' + ERROR_PROCEDURE();
  END CATCH;
END;
