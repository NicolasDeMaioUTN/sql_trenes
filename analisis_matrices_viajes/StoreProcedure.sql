CREATE PROCEDURE _001_1_Viajes_Propios
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
			CONCAT(v.IdO, ''---'', v.IdD) AS ParOD, -- Par OD
			v.id_tarjeta, v.id_viaje, v.hora, -- Datos tarjeta
			v.IdO, v.IdD, -- Microzonas
			o.zonas AS z_origen, d.zonas AS z_destino, -- Zona microzonas
			STRING_AGG(CAST(e.id_linea AS NVARCHAR(MAX), ''-'') WITHIN GROUP (ORDER BY e.id_etapa) AS CombinacionesViaje,
			STRING_AGG(CAST(l.nombre_linea AS NVARCHAR(MAX), ''-'') WITHIN GROUP (ORDER BY e.id_etapa) AS NombreCombinacion,
			STRING_AGG(CAST(l.modo AS NVARCHAR(MAX), ''-'') WITHIN GROUP (ORDER BY e.id_etapa) AS ModoCombinacion
			CAST(v.factor_expansion_linea AS FLOAT) AS ViajesExpandidos,
			CAST(v.tren AS INT) AS tren,
			CAST(v.autobus AS INT) AS autobus,
			CAST(v.metro AS INT) AS metro,
			CAST(v.cant_etapas AS INT) AS cant_etapas,
			CAST(v.distance_h3 AS FLOAT) AS distance_h3,
			CAST(v.distance_osm_drive AS FLOAT) AS distance_osm_drive
		INTO '+QUOTENAME(@Database)+'.dbo._1_viajes
		FROM [Base].[dbo].[viajes] v
		LEFT JOIN [Base].[dbo].[etapas] e ON v.id_tarjeta = e.id_tarjeta AND v.id_viaje = e.id_viaje
		LEFT JOIN [Base].[dbo].[microzonas] o ON v.IdO = o.id
		LEFT JOIN [Base].[dbo].[microzonas] d ON v.IdD = d.id
		LEFT JOIN [Base].[dbo].[lineas] l ON e.id_linea = l.id_linea
		WHERE EXISTS (
			SELECT 1
			FROM [Base].[dbo].[etapas] e2
			WHERE e2.id_tarjeta = v.id_tarjeta 
				AND e2.id_viaje = v.id_viaje 
				AND e2.id_linea = '+QUOTENAME(@IdLinea,'''')+' -- Linea Buscada
		);';
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
				WHEN v.hora BETWEEN 7 AND 10 THEN ''2 - pico_mañana''
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
			FROM '+QUOTENAME(@Database)+'.[dbo]._1_base_viajes v
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
		SET @SQL = @SQL + '
		SELECT 
			o.Zona,
			o.Nombre,
			SUM(COALESCE(o.v_colectivo, 0)+COALESCE(d.v_colectivo, 0)/2 AS v_colectivo,
			SUM(COALESCE(o.v_colectivox2, 0)+COALESCE(d.v_colectivox2, 0)/2 AS v_colectivox2,
			SUM(COALESCE(o.v_colectivox3, 0)+COALESCE(d.v_colectivox3, 0)/2 AS v_colectivox3,
			SUM(COALESCE(o.v_colectivoMas4, 0)+COALESCE(d.v_colectivoMas4, 0)/2 AS v_colectivoMas4,
			SUM(COALESCE(o.v_subte, 0)+COALESCE(d.v_subte, 0)/2 AS v_subte,
			SUM(COALESCE(o.v_subtex2, 0)+COALESCE(d.v_subtex2, 0)/2 AS v_subtex2,
			SUM(COALESCE(o.v_subtex3, 0)+COALESCE(d.v_subtex3, 0)/2 AS v_subtex3,
			SUM(COALESCE(o.v_subteMas4, 0)+COALESCE(d.v_subteMas4, 0)/2 AS v_subteMas4,
			SUM(COALESCE(o.v_tren, 0)+COALESCE(d.v_tren, 0)/2 AS v_tren,
			SUM(COALESCE(o.v_trenx2, 0)+COALESCE(d.v_trenx2, 0)/2 AS v_trenx2,
			SUM(COALESCE(o.v_trenMas3, 0)+COALESCE(d.v_trenMas3, 0)/2 AS v_trenMas3,
			SUM(COALESCE(o.v_colectivo_subte, 0)+COALESCE(d.v_colectivo_subte, 0)/2 AS v_colectivo_subte,
			SUM(COALESCE(o.v_colectivoMas2_subte, 0)+COALESCE(d.v_colectivoMas2_subte, 0)/2 AS v_colectivoMas2_subte,
			SUM(COALESCE(o.v_colectivo_subteMas2, 0)+COALESCE(d.v_colectivo_subteMas2, 0)/2 AS v_colectivo_subteMas2,
			SUM(COALESCE(o.v_colectivoMas2_subteMas2, 0)+COALESCE(d.v_colectivoMas2_subteMas2, 0)/2 AS v_colectivoMas2_subteMas2,
			SUM(COALESCE(o.v_tren_colectivo, 0)+COALESCE(d.v_tren_colectivo, 0)/2 AS v_tren_colectivo,
			SUM(COALESCE(o.v_trenMas2_colectivo, 0)+COALESCE(d.v_trenMas2_colectivo, 0)/2 AS v_trenMas2_colectivo,
			SUM(COALESCE(o.v_tren_colectivoMas2, 0)+COALESCE(d.v_tren_colectivoMas2, 0)/2 AS v_tren_colectivoMas2,
			SUM(COALESCE(o.v_tren_subte, 0)+COALESCE(d.v_tren_subte, 0)/2 AS v_tren_subte,
			SUM(COALESCE(o.v_tren_colectivo_subte, 0)+COALESCE(d.v_tren_colectivo_subte, 0)/2 AS v_tren_colectivo_subte,
			SUM(COALESCE(o.v_totales, 0)+COALESCE(d.v_totales, 0)/2 AS v_totales
		INTO '+QUOTENAME(@Database)+'.[dbo]._1_base_zonas_unicas_totales
		FROM ViajesPorZonaOrigen o
		FULL OUTER JOIN ViajesPorZonaDestino d ON o.Zona = d.Zona 
		GROUP BY o.Zona, o.Nombre
		ORDER BY o.Nombre;';
		EXEC sp_executesql @sql;

		SET @sql = 'DELETE FROM '+QUOTENAME(@Database)+'.[dbo]._1_base_zonas_unicas_totales WHERE Zona = '''' OR Zona IS NULL;';
		EXEC sp_executesql @sql;

	-- Confirmar transacción
	COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
 ROLLBACK TRANSACTION;
	PRINT 'Error en la transacción: ' + ERROR_MESSAGE();
  PRINT 'Procedimiento: ' + ERROR_PROCEDURE();
  END CATCH;
END;


CREATE PROCEDURE _002_2_Datos_Basicos
 @Database NVARCHAR(15), -- Base de datos = Linea de analisis
 @IdLinea NVARCHAR(50), -- Se debe utilizar id_linea "123.0"
 @BasePares NVARCHAR(20) -- Nombre de la base de pares a crear
AS
BEGIN
 BEGIN TRY
	BEGIN TRANSACTION;
  DECLARE @sql NVARCHAR(MAX);
	-- 1. Base de Viajes del Corredor
	SET @sql =
			'DROP TABLE IF EXISTS '+QUOTENAME(@database)+'.dbo._2_tabla01;
			SELECT DISTINCT
				CONCAT(v.IdO,''---'',v.IdD) AS ParOD,
				v.IdO, v.IdD,
				o.zonas AS z_origen, d.zonas AS z_destino,
				v.hora, v.id_tarjeta, v.id_viaje,
				STRING_AGG(CAST(e.id_linea AS NVARCHAR(MAX), ''-'') WITHIN GROUP (ORDER BY e.id_etapa) AS CombinacionesViaje,
				STRING_AGG(CAST(l.nombre_linea AS NVARCHAR(MAX), ''-'') WITHIN GROUP (ORDER BY e.id_etapa) AS NombreCombinacion,
				STRING_AGG(CAST(l.modo AS NVARCHAR(MAX), ''-'') WITHIN GROUP (ORDER BY e.id_etapa) AS ModoCombinacion,
				CASE 
					WHEN EXISTS (
						SELECT 1
						FROM [Base].[dbo].[etapas] e2
						WHERE e2.id_tarjeta = v.id_tarjeta 
						 AND e2.id_viaje = v.id_viaje 
						 AND e2.id_linea = '+QUOTENAME(@IdLinea,'''')+' -- Linea Buscada
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
	PRINT @sql;
	EXEC sp_executesql @sql;

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
				WHEN v.hora BETWEEN 7 AND 10 THEN ''2 - pico_mañana''
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
			END,';
	SET @sql = @sql +
			'CASE
				WHEN v.hora BETWEEN 0 AND 7 THEN ''1 - madrugada''
				WHEN v.hora BETWEEN 7 AND 10 THEN ''2 - pico_mañana''
				WHEN v.hora BETWEEN 10 AND 16 THEN ''3 - mediodia''
				WHEN v.hora BETWEEN 16 AND 19 THEN ''4 - pico_tarde''
				WHEN v.hora BETWEEN 19 AND 24 THEN ''5 - noche''
				ELSE ''null''
			END;
			DROP TABLE IF EXISTS '+QUOTENAME(@database)+'.dbo._2_tabla01';
	EXEC sp_executesql @sql;

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
	EXEC sp_executesql @sql;
	
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
		WHERE v.id_linea <> '+QUOTENAME(@IdLinea,'''')+'
		GROUP BY
			v.ParOD, v.IdO, v.IdD, v.z_origen, v.z_destino, v.id_linea, v.nombre_linea, v.empresa, v.TieneCombinacion, v.ModoMultimodal,
			v.hora, v.pico_horario, v.distancia
		HAVING v.TieneCombinacion = 0
		ORDER BY v.ParOD;';
	EXEC sp_executesql @sql;

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
		WHERE v.id_linea = '+QUOTENAME(@IdLinea,'''')+'
		GROUP BY
			v.ParOD, v.IdO, v.IdD, v.z_origen, v.z_destino, v.id_linea, v.nombre_linea, v.empresa, v.TieneCombinacion, v.ModoMultimodal,
			v.hora, v.pico_horario, v.distancia
		HAVING v.TieneCombinacion = 1
		ORDER BY v.ParOD;
		';
	EXEC sp_executesql @sql;

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
	EXEC sp_executesql @sql;

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
	EXEC sp_executesql @sql;

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
	EXEC sp_executesql @sql;

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
	EXEC sp_executesql @sql;

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
	EXEC sp_executesql @sql;


	-- Confirmar transacción
	COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
 ROLLBACK TRANSACTION;
	PRINT 'Error en la transacción: ' + ERROR_MESSAGE();
  PRINT 'Número de error: ' + CAST(ERROR_NUMBER() AS NVARCHAR(10);
  PRINT 'Procedimiento: ' + ERROR_PROCEDURE();
  PRINT 'Línea: ' + CAST(ERROR_LINE() AS NVARCHAR(10);
 END CATCH;
END;


CREATE PROCEDURE _003_2_Estadisticas_Corredor
 @Database NVARCHAR(15), -- Base de datos = Linea de analisis
 @IdLinea NVARCHAR(50), -- Se debe utilizar id_linea "123.0"
 @BasePares NVARCHAR(20) -- Nombre de la base de pares a crear
AS
BEGIN
 BEGIN TRY
	BEGIN TRANSACTION;
	DECLARE @sql NVARCHAR(MAX);
		-- 1. Calculo agrupado de viajes por ParOD | _2_3_agrupado_corredor_ParOD
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@database)+'.dbo._2_3_agrupado_corredor_ParOD;
		SELECT 
			v.ParOD, v.distancia,
			v.IdO, v.IdD,
			v.z_origen,v.z_destino,
			-- COLECTIVO
			SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVO'' AND v.TieneCombinacion = 0 THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivo_tc_0,
			SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVO'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivo_tc_1, 
			-- COLECTIVOx2
			SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVOx2'' AND v.TieneCombinacion = 0 THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivox2_tc_0,
			SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVOx2'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivox2_tc_1,
			-- COLECTIVOx3
			SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVOx3'' AND v.TieneCombinacion = 0 THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivox3_tc_0,
			SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVOx3'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivox3_tc_1,';
		SET @SQL = @SQL + '
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
			SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO+2-SUBTE+2'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivoMas2_subteMas2_tc_1,';
		SET @SQL = @SQL + '
			-- TREN-COLECTIVO
			SUM(CASE WHEN v.ModoMultimodal = ''E-TREN-COLECTIVO'' AND v.TieneCombinacion = 0 THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_colectivo_tc_0,
			SUM(CASE WHEN v.ModoMultimodal = ''E-TREN-COLECTIVO'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_colectivo_tc_1,
			-- TREN+2-COLECTIVO
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
			SUM(v.ViajesExpandidos) AS v_totales,
			COUNT(DISTINCT v.id_tarjeta) AS TarjetasUnicas,
			SUM(CAST(v.tren AS INT) AS tren,
			SUM(CAST(v.autobus AS INT) AS autobus,
			SUM(CAST(v.metro AS INT) AS metro,
			SUM(CAST(v.cant_etapas AS INT) AS SumaEtapas,
			AVG(CAST(v.cant_etapas AS INT) AS PromedioEtapas,
			AVG(CAST(v.distance_h3 AS FLOAT) AS Promediodistance_h3,
			AVG(CAST(v.distance_osm_drive AS FLOAT)) AS Promediodistance_osm_drive
		INTO '+QUOTENAME(@database)+'.dbo._2_3_agrupado_corredor_ParOD
		FROM '+QUOTENAME(@database)+'.[dbo]._2_base_viajes v
		GROUP BY
			v.ParOD, v.distancia, v.IdO, v.IdD, v.z_origen,v.z_destino
		ORDER BY
			v.ParOD;';
		EXEC sp_executesql @sql;

		-- 2. Calculo agrupado de viajes por ParOD y horario | _2_3_agrupado_corredor_ParOD_horario
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_3_agrupado_corredor_ParOD_horario;
		SELECT 
			v.ParOD, v.distancia,
			v.IdO, v.IdD,
			v.z_origen,v.z_destino,
			v.hora, v.pico_horario,
				-- COLECTIVO
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
			SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTEx3'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_subtex3_tc_1,';
		SET @SQL = @SQL + '
			-- SUBTE+4
			SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTE+4'' AND v.TieneCombinacion = 0 THEN v.ViajesExpandidos ELSE 0 END) AS v_subteMas4_tc_0,
			SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTE+4'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_subteMas4_tc_1,
			-- TREN
			SUM(CASE WHEN v.ModoMultimodal = ''C-TREN'' AND v.TieneCombinacion = 0 THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_tc_0,
			SUM(CASE WHEN v.ModoMultimodal = ''C-TREN'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_tc_1,
			-- TRENx2
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
		SET @SQL = @SQL + '
			-- TREN+2-COLECTIVO
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
			SUM(v.ViajesExpandidos) AS v_totales,
			COUNT(DISTINCT v.id_tarjeta) AS TarjetasUnicas,
			SUM(CAST(v.tren AS INT) AS tren,
			SUM(CAST(v.autobus AS INT) AS autobus,
			SUM(CAST(v.metro AS INT) AS metro,
			SUM(CAST(v.cant_etapas AS INT) AS SumaEtapas,
			AVG(CAST(v.cant_etapas AS INT) AS PromedioEtapas,
			AVG(CAST(v.distance_h3 AS FLOAT) AS Promediodistance_h3,
			AVG(CAST(v.distance_osm_drive AS FLOAT)) AS Promediodistance_osm_drive
		INTO '+QUOTENAME(@Database)+'.[dbo]._2_3_agrupado_corredor_ParOD_horario
		FROM '+QUOTENAME(@Database)+'.[dbo]._2_base_viajes v
		GROUP BY
			v.ParOD, v.distancia,
			v.IdO, v.IdD,
			v.hora,v.pico_horario,
			v.z_origen,v.z_destino
		ORDER BY
			v.ParOD;';
		EXEC sp_executesql @sql;

		-- 3. Calculo agrupado de viajes por Distancia | _2_3_agrupado_corredor_distancia
		SET @sql =
			'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_3_agrupado_corredor_distancia;
			SELECT 
				v.distancia,
				 -- COLECTIVO
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
				SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTE'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_subte_tc_1,';
		SET @SQL = @SQL + '
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
		SET @SQL = @SQL + '
		-- TREN+2-COLECTIVO
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
		SUM(v.ViajesExpandidos) AS v_totales,
		COUNT(DISTINCT v.id_tarjeta) AS TarjetasUnicas,
		SUM(CAST(v.tren AS INT) AS tren,
		SUM(CAST(v.autobus AS INT) AS autobus,
		SUM(CAST(v.metro AS INT) AS metro,
		SUM(CAST(v.cant_etapas AS INT) AS SumaEtapas,
		AVG(CAST(v.cant_etapas AS INT) AS PromedioEtapas,
		AVG(CAST(v.distance_h3 AS FLOAT) AS Promediodistance_h3,
		AVG(CAST(v.distance_osm_drive AS FLOAT)) AS Promediodistance_osm_drive
	INTO '+QUOTENAME(@Database)+'.dbo._2_3_agrupado_corredor_distancia
	FROM '+QUOTENAME(@Database)+'.dbo._2_base_viajes v
	GROUP BY
		v.distancia
	ORDER BY
		v.distancia;';
		EXEC sp_executesql @sql;

		-- 4. Calculo agrupado de viajes por Hora | _2_3_agrupado_corredor_hora
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_3_agrupado_corredor_hora;
		SELECT 
			v.hora,
			 -- COLECTIVO
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
			SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVO+4'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivoMas4_tc_1,';
		SET @SQL = @SQL + '
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
			SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO+2-SUBTE'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivoMas2_subte_tc_1,';
		SET @SQL = @SQL + '
			-- COLECTIVO-SUBTE+2
			SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO-SUBTE+2'' AND v.TieneCombinacion = 0 THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivo_subteMas2_tc_0,
			SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO-SUBTE+2'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivo_subteMas2_tc_1,
			-- COLECTIVO+2-SUBTE+2
			SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO+2-SUBTE+2'' AND v.TieneCombinacion = 0 THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivoMas2_subteMas2_tc_0,
			SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO+2-SUBTE+2'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivoMas2_subteMas2_tc_1,
			-- TREN-COLECTIVO
			SUM(CASE WHEN v.ModoMultimodal = ''E-TREN-COLECTIVO'' AND v.TieneCombinacion = 0 THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_colectivo_tc_0,
			SUM(CASE WHEN v.ModoMultimodal = ''E-TREN-COLECTIVO'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_colectivo_tc_1,
			-- TREN+2-COLECTIVO
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
			SUM(v.ViajesExpandidos) AS v_totales,
			COUNT(DISTINCT v.id_tarjeta) AS TarjetasUnicas,
			SUM(CAST(v.tren AS INT) AS tren,
			SUM(CAST(v.autobus AS INT) AS autobus,
			SUM(CAST(v.metro AS INT) AS metro,
			SUM(CAST(v.cant_etapas AS INT) AS SumaEtapas,
			AVG(CAST(v.cant_etapas AS INT) AS PromedioEtapas,
			AVG(CAST(v.distance_h3 AS FLOAT) AS Promediodistance_h3,
			AVG(CAST(v.distance_osm_drive AS FLOAT)) AS Promediodistance_osm_drive
		INTO '+QUOTENAME(@Database)+'.dbo._2_3_agrupado_corredor_hora
		FROM '+QUOTENAME(@Database)+'.dbo._2_base_viajes v
		GROUP BY
		 v.hora
		ORDER BY
			v.hora;';
		EXEC sp_executesql @sql;

		-- 5. Calculo agrupado de viajes por Pico Horario | _2_3_agrupado_corredor_Pico_Horario
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_3_agrupado_corredor_Pico_Horario;
		SELECT 
			v.pico_horario,
			 -- COLECTIVO
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
			SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTEX2'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_subtex2_tc_1,';
		SET @SQL = @SQL + '
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
			SUM(CASE WHEN v.ModoMultimodal = ''C-TRENx2'' AND v.TieneCombinacion = 0 THEN v.ViajesExpandidos ELSE 0 END) AS v_trenx2_tc_0,
			SUM(CASE WHEN v.ModoMultimodal = ''C-TRENx2'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_trenx2_tc_1,
			-- TREN+3
			SUM(CASE WHEN v.ModoMultimodal = ''C-TREN+3'' AND v.TieneCombinacion = 0 THEN v.ViajesExpandidos ELSE 0 END) AS v_trenMas3_tc_0,
			SUM(CASE WHEN v.ModoMultimodal = ''C-TREN+3'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_trenMas3_tc_1,
			-- COLECTIVO-SUBTE
			SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO-SUBTE'' AND v.TieneCombinacion = 0 THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivo_subte_tc_0,
			SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO-SUBTE'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivo_subte_tc_1,';
		SET @SQL = @SQL + '
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
			SUM(CASE WHEN v.ModoMultimodal = ''E-TREN-COLECTIVO'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_colectivo_tc_1,
			-- TREN+2-COLECTIVO
			SUM(CASE WHEN v.ModoMultimodal = ''E-TREN+2-COLECTIVO'' AND v.TieneCombinacion = 0 THEN v.ViajesExpandidos ELSE 0 END) AS v_treMas2_colectivo_tc_0,
			SUM(CASE WHEN v.ModoMultimodal = ''E-TREN+2-COLECTIVO'' AND v.TieneCombinacion = 1 THEN v.ViajesExpandidos ELSE 0 END) AS v_treMas2_colectivo_tc_1,';
		SET @SQL = @SQL + '
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
			SUM(v.ViajesExpandidos) AS v_totales,
			COUNT(DISTINCT v.id_tarjeta) AS TarjetasUnicas,
			SUM(CAST(v.tren AS INT) AS tren,
			SUM(CAST(v.autobus AS INT) AS autobus,
			SUM(CAST(v.metro AS INT) AS metro,
			SUM(CAST(v.cant_etapas AS INT) AS SumaEtapas,
			AVG(CAST(v.cant_etapas AS INT) AS PromedioEtapas,
			AVG(CAST(v.distance_h3 AS FLOAT) AS Promediodistance_h3,
			AVG(CAST(v.distance_osm_drive AS FLOAT)) AS Promediodistance_osm_drive
		INTO '+QUOTENAME(@Database)+'.dbo._2_3_agrupado_corredor_Pico_Horario
		FROM '+QUOTENAME(@Database)+'.dbo._2_base_viajes v
		GROUP BY
			v.pico_horario
		ORDER BY
			v.pico_horario;';
		EXEC sp_executesql @sql;

		-- 6. Calculo distribución de viajes por ModoMultimodal y Combinacion | _2_3_distribucion_corredor_MultiModal_ModoCombinacion
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_3_distribucion_corredor_MultiModal_ModoCombinacion;
		SELECT 
			v.ModoMultimodal, v.ModoCombinacion,v.TieneCombinacion,
			SUM(v.ViajesExpandidos) AS v_totales,
			CASE WHEN (SELECT SUM(v.ViajesExpandidos) FROM '+QUOTENAME(@Database)+'.dbo._2_base_viajes v) > 0 
			 THEN SUM(v.ViajesExpandidos) / (SELECT SUM(v.ViajesExpandidos) FROM '+QUOTENAME(@Database)+'.dbo._2_base_viajes v)
			 ELSE 0 
			END AS Porcentaje,
			COUNT(DISTINCT v.id_tarjeta) AS TarjetasUnicas,
			SUM(CAST(v.tren AS INT) AS tren,
			SUM(CAST(v.autobus AS INT) AS autobus,
			SUM(CAST(v.metro AS INT) AS metro,
			SUM(CAST(v.cant_etapas AS INT) AS SumaEtapas,
			AVG(CAST(v.cant_etapas AS INT) AS PromedioEtapas,
			AVG(CAST(v.distance_h3 AS FLOAT) AS PromedioDistance_h3,
			AVG(CAST(v.distance_osm_drive AS FLOAT)) AS PromedioDistance_osm_drive
		INTO '+QUOTENAME(@Database)+'.dbo._2_3_distribucion_corredor_MultiModal_ModoCombinacion
		FROM '+QUOTENAME(@Database)+'.dbo._2_base_viajes v
		GROUP BY
			v.ModoMultimodal, v.ModoCombinacion,v.TieneCombinacion
		ORDER BY
			v.ModoMultimodal;';
		EXEC sp_executesql @sql;

		-- 7. Calculo distribución de viajes por Distancia y ModoMultimodal | _2_3_distribucion_corredor_distancia_MultiModal
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_3_distribucion_corredor_distancia_MultiModal;
		SELECT 
			v.distancia, v.ModoMultimodal,v.TieneCombinacion,
			SUM(v.ViajesExpandidos) AS v_totales,
			CASE WHEN (SELECT SUM(v.ViajesExpandidos) FROM '+QUOTENAME(@Database)+'.dbo._2_base_viajes v) > 0 
			 THEN SUM(v.ViajesExpandidos) / (SELECT SUM(v.ViajesExpandidos) FROM '+QUOTENAME(@Database)+'.dbo._2_base_viajes v)
			 ELSE 0 
			END AS Porcentaje,
			COUNT(DISTINCT v.id_tarjeta) AS TarjetasUnicas,
			SUM(CAST(v.tren AS INT) AS tren,
			SUM(CAST(v.autobus AS INT) AS autobus,
			SUM(CAST(v.metro AS INT) AS metro,
			SUM(CAST(v.cant_etapas AS INT) AS SumaEtapas,
			AVG(CAST(v.cant_etapas AS INT) AS PromedioEtapas,
			AVG(CAST(v.distance_h3 AS FLOAT) AS PromedioDistance_h3,
			AVG(CAST(v.distance_osm_drive AS FLOAT)) AS PromedioDistance_osm_drive
		INTO '+QUOTENAME(@Database)+'.dbo._2_3_distribucion_corredor_distancia_MultiModal
		FROM '+QUOTENAME(@Database)+'.dbo._2_base_viajes v
		GROUP BY
			v.distancia, v.ModoMultimodal,v.TieneCombinacion
		ORDER BY
			v.distancia;';
		EXEC sp_executesql @sql;

		-- 8. Calculo distribución de viajes por ModoMultimodal, Combinacion y horario | _2_3_distribucion_corredor_MultiModal_ModoCombinacion
		SET @sql =
			'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_3_distribucion_corredor_distancia_ModoMultiModal_Combinacion_horario;
			SELECT 
				v.ModoMultimodal,v.ModoCombinacion,v.pico_horario,v.TieneCombinacion,
				SUM(v.ViajesExpandidos) AS v_totales,
				CASE WHEN (SELECT SUM(v.ViajesExpandidos) FROM '+QUOTENAME(@Database)+'.dbo._2_base_viajes v) > 0 
				 THEN SUM(v.ViajesExpandidos) / (SELECT SUM(v.ViajesExpandidos) FROM '+QUOTENAME(@Database)+'.dbo._2_base_viajes v)
				 ELSE 0 
				END AS Porcentaje,
				COUNT(DISTINCT v.id_tarjeta) AS TarjetasUnicas,
				SUM(CAST(v.tren AS INT) AS tren,
				SUM(CAST(v.autobus AS INT) AS autobus,
				SUM(CAST(v.metro AS INT) AS metro,
				SUM(CAST(v.cant_etapas AS INT) AS SumaEtapas,
				AVG(CAST(v.cant_etapas AS INT) AS PromedioEtapas,
				AVG(CAST(v.distance_h3 AS FLOAT) AS PromedioDistance_h3,
				AVG(CAST(v.distance_osm_drive AS FLOAT)) AS PromedioDistance_osm_drive
			INTO '+QUOTENAME(@Database)+'.dbo._2_3_distribucion_corredor_distancia_ModoMultiModal_Combinacion_horario
			FROM '+QUOTENAME(@Database)+'.dbo._2_base_viajes v
			GROUP BY
				v.ModoMultimodal,v.ModoCombinacion,v.pico_horario,v.TieneCombinacion
			ORDER BY
				v.ModoMultimodal;';
		EXEC sp_executesql @sql;

		-- 9. Calculo distribución de viajes por ModoMultimodal, Combinacion, distancia y horario | _2_3_distribucion_corredor_distancia_ModoMultiModal_Combinacion_distancia_horario
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_3_distribucion_corredor_distancia_ModoMultiModal_Combinacion_distancia_horario;
		SELECT 
			v.ModoMultimodal,v.ModoCombinacion,v.distancia,v.pico_horario,v.TieneCombinacion,
			SUM(v.ViajesExpandidos) AS v_totales,
			CASE WHEN (SELECT SUM(v.ViajesExpandidos) FROM '+QUOTENAME(@Database)+'.dbo._2_base_viajes v) > 0 
			 THEN SUM(v.ViajesExpandidos) / (SELECT SUM(v.ViajesExpandidos) FROM '+QUOTENAME(@Database)+'.dbo._2_base_viajes v)
			 ELSE 0 
			END AS Porcentaje,
			COUNT(DISTINCT v.id_tarjeta) AS TarjetasUnicas,
			SUM(CAST(v.tren AS INT) AS tren,
			SUM(CAST(v.autobus AS INT) AS autobus,
			SUM(CAST(v.metro AS INT) AS metro,
			SUM(CAST(v.cant_etapas AS INT) AS SumaEtapas,
			AVG(CAST(v.cant_etapas AS INT) AS PromedioEtapas,
			AVG(CAST(v.distance_h3 AS FLOAT) AS PromedioDistance_h3,
			AVG(CAST(v.distance_osm_drive AS FLOAT)) AS PromedioDistance_osm_drive
		INTO '+QUOTENAME(@Database)+'.dbo._2_3_distribucion_corredor_distancia_ModoMultiModal_Combinacion_distancia_horario
		FROM '+QUOTENAME(@Database)+'.dbo._2_base_viajes v
		GROUP BY
			v.ModoMultimodal,v.ModoCombinacion,v.distancia,v.pico_horario,v.TieneCombinacion
		ORDER BY
			v.ModoMultimodal,v.ModoCombinacion,v.distancia;';
		EXEC sp_executesql @sql;

		-- 10. Calculo de distribución de viajes por Horario y distancia | _2_3_distribucion_corredor_horario_distancia
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_3_distribucion_corredor_horario_distancia;
		SELECT 
			v.pico_horario, v.distancia, v.TieneCombinacion,
			SUM(v.ViajesExpandidos) AS v_totales,
			CASE WHEN (SELECT SUM(v.ViajesExpandidos) FROM '+QUOTENAME(@Database)+'.dbo._2_base_viajes v) > 0 
			 THEN SUM(v.ViajesExpandidos) / (SELECT SUM(v.ViajesExpandidos) FROM '+QUOTENAME(@Database)+'.dbo._2_base_viajes v)
			 ELSE 0 
			END AS Porcentaje,
			COUNT(DISTINCT v.id_tarjeta) AS TarjetasUnicas,
			SUM(CAST(v.tren AS INT) AS tren,
			SUM(CAST(v.autobus AS INT) AS autobus,
			SUM(CAST(v.metro AS INT) AS metro,
			SUM(CAST(v.cant_etapas AS INT) AS SumaEtapas,
			AVG(CAST(v.cant_etapas AS INT) AS PromedioEtapas,
			AVG(CAST(v.distance_h3 AS FLOAT) AS PromedioDistance_h3,
			AVG(CAST(v.distance_osm_drive AS FLOAT)) AS PromedioDistance_osm_drive
		INTO '+QUOTENAME(@Database)+'.dbo._2_3_distribucion_corredor_horario_distancia
		FROM '+QUOTENAME(@Database)+'.dbo._2_base_viajes v
		GROUP BY
			v.pico_horario, v.distancia, v.TieneCombinacion
		ORDER BY
			v.pico_horario, v.distancia;';
		EXEC sp_executesql @sql;

		-- 11. Calculo de distribución de viajes por horario y modo de combinacion | _2_3_distribucion_corredor_horario_ModoCombinacion
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_3_distribucion_corredor_horario_ModoCombinacion;
		SELECT 
			v.pico_horario, v.ModoCombinacion, v.TieneCombinacion,
			SUM(v.ViajesExpandidos) AS v_totales,
			CASE WHEN (SELECT SUM(v.ViajesExpandidos) FROM '+QUOTENAME(@Database)+'.dbo._2_base_viajes v) > 0 
			 THEN SUM(v.ViajesExpandidos) / (SELECT SUM(v.ViajesExpandidos) FROM '+QUOTENAME(@Database)+'.dbo._2_base_viajes v)
			 ELSE 0 
			END AS Porcentaje,
			COUNT(DISTINCT v.id_tarjeta) AS TarjetasUnicas,
			SUM(CAST(v.tren AS INT) AS tren,
			SUM(CAST(v.autobus AS INT) AS autobus,
			SUM(CAST(v.metro AS INT) AS metro,
			SUM(CAST(v.cant_etapas AS INT) AS SumaEtapas,
			AVG(CAST(v.cant_etapas AS INT) AS PromedioEtapas,
			AVG(CAST(v.distance_h3 AS FLOAT) AS PromedioDistance_h3,
			AVG(CAST(v.distance_osm_drive AS FLOAT)) AS PromedioDistance_osm_drive
		INTO '+QUOTENAME(@Database)+'.dbo._2_3_distribucion_corredor_horario_ModoCombinacion
		FROM '+QUOTENAME(@Database)+'.dbo._2_base_viajes v
		GROUP BY
			v.pico_horario, v.ModoCombinacion, v.TieneCombinacion
		ORDER BY
			v.pico_horario, v.ModoCombinacion;';
		EXEC sp_executesql @sql;
		
		-- 12. Calculo de etapas de cada linea por ParOD y Modo Multimodal | _2_3_2_etapas_por_linea_porParOD_ModoMultimodal
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_3_2_etapas_por_linea_porParOD_ModoMultimodal;
		SELECT 
			v.ParOD, v.distancia,v.IdO,v.IdD, v.z_origen,v.z_destino, v.ModoMultimodal, v.id_linea, v.nombre_linea, v.empresa,
			COUNT (v.id_linea) AS CantidadEtapas
		INTO '+QUOTENAME(@Database)+'.dbo._2_3_2_etapas_por_linea_porParOD_ModoMultimodal
		FROM '+QUOTENAME(@Database)+'.dbo._2_base_etapas_por_linea_por_ParOD v
		GROUP BY
			v.ParOD, v.IdO,v.IdD, v.z_origen,v.z_destino, v.distancia, v.ModoMultimodal, v.id_linea, v.nombre_linea,	v.empresa
		ORDER BY
			v.ParOD,v.distancia,v.ModoMultimodal;';
		EXEC sp_executesql @sql;

		-- 13. Calculo de etapas de cada linea por ParOD | _2_3_2_etapas_por_linea_porParOD
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_3_2_etapas_por_linea_porParOD;
		SELECT 
			v.ParOD, v.distancia,v.IdO,v.IdD, v.z_origen,v.z_destino, v.id_linea, v.nombre_linea, v.empresa,
			COUNT (v.id_linea) AS CantidadEtapas
		INTO '+QUOTENAME(@Database)+'.dbo._2_3_2_etapas_por_linea_porParOD
		FROM '+QUOTENAME(@Database)+'.dbo._2_base_etapas_por_linea_por_ParOD v
		GROUP BY
			v.ParOD, v.IdO,v.IdD, v.z_origen,v.z_destino, v.distancia, v.id_linea, v.nombre_linea,	v.empresa
		ORDER BY
			v.ParOD,v.distancia;';
		EXEC sp_executesql @sql;

		-- 14. Calculo de etapas de cada linea por Distancia | _2_3_2_etapas_por_linea_por_distancia
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_3_2_etapas_por_linea_por_distancia;
		SELECT 
			v.distancia,v.IdO,v.IdD, v.z_origen,v.z_destino, v.id_linea, v.nombre_linea, v.empresa,
			COUNT (v.id_linea) AS CantidadEtapas
		INTO '+QUOTENAME(@Database)+'.dbo._2_3_2_etapas_por_linea_por_distancia
		FROM '+QUOTENAME(@Database)+'.dbo._2_base_etapas_por_linea_por_ParOD v
		GROUP BY
			v.distancia, v.IdO,v.IdD, v.z_origen,v.z_destino, v.id_linea, v.nombre_linea, v.empresa
		ORDER BY
			v.distancia;';
		EXEC sp_executesql @sql;

		-- 15. Calculo de etapas de cada linea por ModoMultimodal | _2_3_2_etapas_por_linea_por_ModoMultimodal
		SET @sql =
			'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_3_2_etapas_por_linea_por_ModoMultimodal;
			SELECT 
				v.ModoMultimodal,v.IdO,v.IdD, v.z_origen,v.z_destino, v.id_linea, v.nombre_linea, v.empresa,
				COUNT (v.id_linea) AS CantidadEtapas
			INTO '+QUOTENAME(@Database)+'.dbo._2_3_2_etapas_por_linea_por_ModoMultimodal
			FROM '+QUOTENAME(@Database)+'.dbo._2_base_etapas_por_linea_por_ParOD v
			GROUP BY
				v.ModoMultimodal, v.IdO,v.IdD, v.z_origen,v.z_destino, v.id_linea, v.nombre_linea,	v.empresa
			ORDER BY
				v.ModoMultimodal;';
		EXEC sp_executesql @sql;

		-- 16. Combinacion de viaje por ParOD | _2_3_1_combinacion_corredor_mas_utilizadas_porParOD
		SET @sql =
			'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_3_1_combinacion_corredor_mas_utilizadas_porParOD;
			SELECT 
				ParOD, distancia,z_origen, z_destino, NombreCombinacion, CantidadRepeticiones, SumaViajes,
				PARTITIONED.NombreCombinacion_Part1 AS Etapa1,
				PARTITIONED2.NombreCombinacion_Part2 AS Etapa2,
				PARTITIONED3.NombreCombinacion_Part3 AS Etapa3,
				PARTITIONED4.NombreCombinacion_Part4 AS Etapa4,
				PARTITIONED5.NombreCombinacion_Part5 AS Etapa5,
				PARTITIONED6.NombreCombinacion_Part6 AS Etapa6,
				PARTITIONED7.NombreCombinacion_Part7 AS Etapa7,
				PARTITIONED8.NombreCombinacion_Part8 AS Etapa8,
				PARTITIONED9.NombreCombinacion_Part9 AS Etapa9,
				ROW_NUMBER() OVER (PARTITION BY ParOD ORDER BY SumaViajes DESC) AS NroFila
			INTO '+QUOTENAME(@Database)+'.dbo._2_3_1_combinacion_corredor_mas_utilizadas_porParOD
			FROM (
				SELECT 
					ParOD, distancia, z_origen, z_destino, NombreCombinacion, CantidadRepeticiones,
					SUM(SumaViajes) AS SumaViajes, -- Primero calculo la suma de etapas por par OD,
					ROW_NUMBER() OVER (PARTITION BY ParOD ORDER BY SUM(SumaViajes) DESC) AS NroFila -- Rankeo
				FROM '+QUOTENAME(@Database)+'.dbo._2_base_combinaciones_por_linea_porParOD
				GROUP BY
					ParOD, z_origen, z_destino, distancia,NombreCombinacion, CantidadRepeticiones
			) AS Subquery';
		SET @SQL = @SQL + '
			OUTER APPLY (
				-- Dividir NombreCombinacion en la primera parte
				SELECT 
					value AS NombreCombinacion_Part1
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED -- Parte 1
			OUTER APPLY (
				-- Dividir NombreCombinacion en la segunda parte
				SELECT 
					value AS NombreCombinacion_Part2
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED2 -- Parte 2

			OUTER APPLY (
				-- Dividir NombreCombinacion en la tercera parte
				SELECT 
					value AS NombreCombinacion_Part3
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED3 -- Parte 3

			OUTER APPLY (
				-- Dividir NombreCombinacion en la cuarta parte
				SELECT 
					value AS NombreCombinacion_Part4
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 3 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED4 -- Parte 4';
		SET @SQL = @SQL + '
		OUTER APPLY (
			-- Dividir NombreCombinacion en la quinta parte
			SELECT 
				value AS NombreCombinacion_Part5
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 4 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED5 -- Parte 5

		OUTER APPLY (
			-- Dividir NombreCombinacion en la sexta parte
			SELECT 
				value AS NombreCombinacion_Part6
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 5 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED6 -- Parte 6

		OUTER APPLY (
			-- Dividir NombreCombinacion en la séptima parte
			SELECT 
				value AS NombreCombinacion_Part7
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 6 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED7 -- Parte 7

		OUTER APPLY (
			-- Dividir NombreCombinacion en la octava parte
			SELECT 
				value AS NombreCombinacion_Part8
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 7 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED8 -- Parte 8

		OUTER APPLY (
			-- Dividir NombreCombinacion en la novena parte
			SELECT 
				value AS NombreCombinacion_Part9
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 8 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED9 -- Parte 9
		WHERE NroFila <= 10;';
		EXEC sp_executesql @sql;

		-- 17. Combinacion de viaje por ParOD y Modo | _2_3_1_combinacion_corredor_utilizadas_ParOD_Modo
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_3_1_combinacion_corredor_utilizadas_ParOD_Modo;
		SELECT 
			ParOD, z_origen, z_destino, NombreCombinacion, distancia, ModoMultimodal, CantidadRepeticiones, SumaViajes,
			ROW_NUMBER() OVER (PARTITION BY ParOD, ModoMultimodal ORDER BY SumaViajes DESC) AS NroFila, -- Rankeo
			PARTITIONED.NombreCombinacion_Part1 AS Etapa1,
			PARTITIONED2.NombreCombinacion_Part2 AS Etapa2,
			PARTITIONED3.NombreCombinacion_Part3 AS Etapa3,
			PARTITIONED4.NombreCombinacion_Part4 AS Etapa4,
			PARTITIONED5.NombreCombinacion_Part5 AS Etapa5,
			PARTITIONED6.NombreCombinacion_Part6 AS Etapa6,
			PARTITIONED7.NombreCombinacion_Part7 AS Etapa7,
			PARTITIONED8.NombreCombinacion_Part8 AS Etapa8,
			PARTITIONED9.NombreCombinacion_Part9 AS Etapa9
		INTO '+QUOTENAME(@Database)+'.dbo._2_3_1_combinacion_corredor_utilizadas_ParOD_Modo -- Lineas Más Utilizadas ParOD y Modo
		FROM (
			SELECT 
				ParOD, z_origen, z_destino, NombreCombinacion, distancia, CantidadRepeticiones, ModoMultimodal,
				SUM(SumaViajes) AS SumaViajes, 
				ROW_NUMBER() OVER (PARTITION BY ParOD, ModoMultimodal ORDER BY SUM(SumaViajes) DESC) AS NroFila -- Rankeo
			FROM '+QUOTENAME(@Database)+'.dbo._2_base_combinaciones_por_linea_porParOD
			GROUP BY
				ParOD, z_origen, z_destino,NombreCombinacion, distancia, ModoMultimodal, CantidadRepeticiones
		) AS Subquery';
		SET @SQL = @SQL + '
			OUTER APPLY (
				-- Dividir NombreCombinacion en la primera parte
				SELECT 
					value AS NombreCombinacion_Part1
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED -- Parte 1

			OUTER APPLY (
				-- Dividir NombreCombinacion en la segunda parte
				SELECT 
					value AS NombreCombinacion_Part2
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED2 -- Parte 2

			OUTER APPLY (
				-- Dividir NombreCombinacion en la tercera parte
				SELECT 
					value AS NombreCombinacion_Part3
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED3 -- Parte 3

			OUTER APPLY (
				-- Dividir NombreCombinacion en la cuarta parte
				SELECT 
					value AS NombreCombinacion_Part4
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 3 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED4 -- Parte 4

			OUTER APPLY (
				-- Dividir NombreCombinacion en la quinta parte
				SELECT 
					value AS NombreCombinacion_Part5
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 4 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED5 -- Parte 5';
		SET @SQL = @SQL + '
			OUTER APPLY (
				-- Dividir NombreCombinacion en la sexta parte
				SELECT 
					value AS NombreCombinacion_Part6
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 5 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED6 -- Parte 6

			OUTER APPLY (
				-- Dividir NombreCombinacion en la séptima parte
				SELECT 
					value AS NombreCombinacion_Part7
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 6 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED7 -- Parte 7

			OUTER APPLY (
				-- Dividir NombreCombinacion en la octava parte
				SELECT 
					value AS NombreCombinacion_Part8
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 7 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED8 -- Parte 8

			OUTER APPLY (
				-- Dividir NombreCombinacion en la novena parte
				SELECT 
					value AS NombreCombinacion_Part9
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 8 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED9 -- Parte 9
			WHERE NroFila <= 10;';
		EXEC sp_executesql @sql;

		-- 18. Combinacion de viaje por ParOD y Horario| _2_3_1_combinacion_corredor_utilizadas_ParOD_Horario
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_3_1_combinacion_corredor_utilizadas_ParOD_Horario;
		SELECT 
			ParOD,distancia z_origen, z_destino,NombreCombinacion, distancia, pico_horario, CantidadRepeticiones, SumaViajes,
			ROW_NUMBER() OVER (PARTITION BY ParOD, pico_horario ORDER BY SumaViajes DESC) AS NroFila, -- Rankeo
			PARTITIONED.NombreCombinacion_Part1 AS Etapa1,
			PARTITIONED2.NombreCombinacion_Part2 AS Etapa2,
			PARTITIONED3.NombreCombinacion_Part3 AS Etapa3,
			PARTITIONED4.NombreCombinacion_Part4 AS Etapa4,
			PARTITIONED5.NombreCombinacion_Part5 AS Etapa5,
			PARTITIONED6.NombreCombinacion_Part6 AS Etapa6,
			PARTITIONED7.NombreCombinacion_Part7 AS Etapa7,
			PARTITIONED8.NombreCombinacion_Part8 AS Etapa8,
			PARTITIONED9.NombreCombinacion_Part9 AS Etapa9';
		SET @SQL = @SQL + '
		INTO '+QUOTENAME(@Database)+'.dbo._2_3_1_combinacion_corredor_utilizadas_ParOD_Horario -- Lineas Más Utilizadas ParOD y Modo
		FROM (
			SELECT 
				ParOD, z_origen, z_destino,NombreCombinacion, distancia, pico_horario, CantidadRepeticiones,
				SUM(SumaViajes) AS SumaViajes, -- Primero calculo la suma de etapas por par OD
				ROW_NUMBER() OVER (PARTITION BY ParOD, NombreCombinacion,pico_horario ORDER BY SUM(SumaViajes) DESC) AS NroFila -- Rankeo
			FROM '+QUOTENAME(@Database)+'.dbo._2_base_combinaciones_por_linea_porParOD
			GROUP BY
				ParOD, z_origen, z_destino,NombreCombinacion, distancia, pico_horario, CantidadRepeticiones
		) AS Subquery
		OUTER APPLY (
			-- Dividir NombreCombinacion en la primera parte
			SELECT 
				value AS NombreCombinacion_Part1
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED -- Parte 1';
		SET @SQL = @SQL + '
		OUTER APPLY (
			-- Dividir NombreCombinacion en la segunda parte
			SELECT 
				value AS NombreCombinacion_Part2
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED2 -- Parte 2

		OUTER APPLY (
			-- Dividir NombreCombinacion en la tercera parte
			SELECT 
				value AS NombreCombinacion_Part3
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED3 -- Parte 3

		OUTER APPLY (
			-- Dividir NombreCombinacion en la cuarta parte
			SELECT 
				value AS NombreCombinacion_Part4
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 3 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED4 -- Parte 4

		OUTER APPLY (
			-- Dividir NombreCombinacion en la quinta parte
			SELECT 
				value AS NombreCombinacion_Part5
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 4 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED5 -- Parte 5';
		SET @SQL = @SQL + '

		OUTER APPLY (
			-- Dividir NombreCombinacion en la sexta parte
			SELECT 
				value AS NombreCombinacion_Part6
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 5 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED6 -- Parte 6

		OUTER APPLY (
			-- Dividir NombreCombinacion en la séptima parte
			SELECT 
				value AS NombreCombinacion_Part7
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 6 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED7 -- Parte 7

		OUTER APPLY (
			-- Dividir NombreCombinacion en la octava parte
			SELECT 
				value AS NombreCombinacion_Part8
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 7 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED8 -- Parte 8

		OUTER APPLY (
			-- Dividir NombreCombinacion en la novena parte
			SELECT 
				value AS NombreCombinacion_Part9
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 8 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED9 -- Parte 9
		WHERE NroFila <= 10;';
		EXEC sp_executesql @sql;

		-- 19. Combinacion de viaje por ParOD, Modo y Distancia | _2_3_1_combinacion_corredor_utilizadas_ParOD_Modo_Distancia
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_3_1_combinacion_corredor_utilizadas_ParOD_Modo_Distancia;
		SELECT 
			ParOD, distancia, z_origen, z_destino,NombreCombinacion, ModoMultimodal, CantidadRepeticiones, SumaViajes,
			ROW_NUMBER() OVER (PARTITION BY ParOD, ModoMultimodal, distancia ORDER BY SumaViajes DESC) AS NroFila, -- Rankeo
			PARTITIONED.NombreCombinacion_Part1 AS Etapa1,
			PARTITIONED2.NombreCombinacion_Part2 AS Etapa2,
			PARTITIONED3.NombreCombinacion_Part3 AS Etapa3,
			PARTITIONED4.NombreCombinacion_Part4 AS Etapa4,
			PARTITIONED5.NombreCombinacion_Part5 AS Etapa5,
			PARTITIONED6.NombreCombinacion_Part6 AS Etapa6,
			PARTITIONED7.NombreCombinacion_Part7 AS Etapa7,
			PARTITIONED8.NombreCombinacion_Part8 AS Etapa8,
			PARTITIONED9.NombreCombinacion_Part9 AS Etapa9
		INTO '+QUOTENAME(@Database)+'.dbo._2_3_1_combinacion_corredor_utilizadas_ParOD_Modo_Distancia -- Lineas Más Utilizadas ParOD y Modo
		FROM (
			SELECT 
				ParOD, z_origen, z_destino, NombreCombinacion,distancia, ModoMultimodal, CantidadRepeticiones,
				SUM(SumaViajes) AS SumaViajes, -- Primero calculo la suma de etapas por par OD
				ROW_NUMBER() OVER (PARTITION BY ParOD, ModoMultimodal, distancia ORDER BY SUM(SumaViajes) DESC) AS NroFila -- Rankeo
			FROM '+QUOTENAME(@Database)+'.dbo._2_base_combinaciones_por_linea_porParOD
			GROUP BY
				ParOD, z_origen, z_destino,NombreCombinacion, distancia, ModoMultimodal,CantidadRepeticiones
		) AS Subquery
		';
		SET @SQL = @SQL + '
		OUTER APPLY (
			-- Dividir NombreCombinacion en la primera parte
			SELECT 
				value AS NombreCombinacion_Part1
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED -- Parte 1

		OUTER APPLY (
			-- Dividir NombreCombinacion en la segunda parte
			SELECT 
				value AS NombreCombinacion_Part2
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED2 -- Parte 2

		OUTER APPLY (
			-- Dividir NombreCombinacion en la tercera parte
			SELECT 
				value AS NombreCombinacion_Part3
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED3 -- Parte 3

		OUTER APPLY (
			-- Dividir NombreCombinacion en la cuarta parte
			SELECT 
				value AS NombreCombinacion_Part4
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 3 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED4 -- Parte 4';
		SET @SQL = @SQL + '
			OUTER APPLY (
				-- Dividir NombreCombinacion en la quinta parte
				SELECT 
					value AS NombreCombinacion_Part5
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 4 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED5 -- Parte 5

			OUTER APPLY (
				-- Dividir NombreCombinacion en la sexta parte
				SELECT 
					value AS NombreCombinacion_Part6
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 5 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED6 -- Parte 6

			OUTER APPLY (
				-- Dividir NombreCombinacion en la séptima parte
				SELECT 
					value AS NombreCombinacion_Part7
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 6 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED7 -- Parte 7

			OUTER APPLY (
				-- Dividir NombreCombinacion en la octava parte
				SELECT 
					value AS NombreCombinacion_Part8
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 7 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED8 -- Parte 8

			OUTER APPLY (
				-- Dividir NombreCombinacion en la novena parte
				SELECT 
					value AS NombreCombinacion_Part9
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 8 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED9 -- Parte 9
			WHERE NroFila <= 10;';
		EXEC sp_executesql @sql;

		-- 20. Combinacion de viaje por ParOd, Modo, Distancia y Modo | _2_3_1_combinacion_corredor_utilizadas_ParOD_Modo_Distancia_horario
		SET @sql =
			'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_3_1_combinacion_corredor_utilizadas_ParOD_Modo_Distancia_horario;
			SELECT 
				ParOD,distancia, z_origen, z_destino,NombreCombinacion, ModoMultimodal, pico_horario, CantidadRepeticiones,SumaViajes,
				ROW_NUMBER() OVER (PARTITION BY ParOD, ModoMultimodal, distancia, pico_horario ORDER BY SumaViajes DESC) AS NroFila, -- Rankeo
				PARTITIONED.NombreCombinacion_Part1 AS Etapa1,
				PARTITIONED2.NombreCombinacion_Part2 AS Etapa2,
				PARTITIONED3.NombreCombinacion_Part3 AS Etapa3,
				PARTITIONED4.NombreCombinacion_Part4 AS Etapa4,
				PARTITIONED5.NombreCombinacion_Part5 AS Etapa5,
				PARTITIONED6.NombreCombinacion_Part6 AS Etapa6,
				PARTITIONED7.NombreCombinacion_Part7 AS Etapa7,
				PARTITIONED8.NombreCombinacion_Part8 AS Etapa8,
				PARTITIONED9.NombreCombinacion_Part9 AS Etapa9
			INTO '+QUOTENAME(@Database)+'.dbo._2_3_1_combinacion_corredor_utilizadas_ParOD_Modo_Distancia_horario -- Lineas Más Utilizadas ParOD y Modo
			FROM (
				SELECT 
					ParOD, z_origen, z_destino,NombreCombinacion, distancia, ModoMultimodal, pico_horario, CantidadRepeticiones,
					SUM(SumaViajes) AS SumaViajes, -- Primero calculo la suma de etapas por par OD
					ROW_NUMBER() OVER (PARTITION BY ParOD, ModoMultimodal, distancia, pico_horario ORDER BY SUM(SumaViajes) DESC) AS NroFila -- Rankeo
				FROM '+QUOTENAME(@Database)+'.dbo._2_base_combinaciones_por_linea_porParOD
				GROUP BY
					ParOD, z_origen, z_destino,NombreCombinacion, distancia, ModoMultimodal, pico_horario,CantidadRepeticiones
			) AS Subquery';
		SET @SQL = @SQL + '
			OUTER APPLY (
				-- Dividir NombreCombinacion en la primera parte
				SELECT 
					value AS NombreCombinacion_Part1
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED -- Parte 1
			OUTER APPLY (
				-- Dividir NombreCombinacion en la segunda parte
				SELECT 
					value AS NombreCombinacion_Part2
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED2 -- Parte 2
			OUTER APPLY (
				-- Dividir NombreCombinacion en la tercera parte
				SELECT 
					value AS NombreCombinacion_Part3
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED3 -- Parte 3
			OUTER APPLY (
				-- Dividir NombreCombinacion en la cuarta parte
				SELECT 
					value AS NombreCombinacion_Part4
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 3 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED4 -- Parte 4';
		SET @SQL = @SQL + '
			OUTER APPLY (
				-- Dividir NombreCombinacion en la quinta parte
				SELECT 
					value AS NombreCombinacion_Part5
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 4 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED5 -- Parte 5

			OUTER APPLY (
				-- Dividir NombreCombinacion en la sexta parte
				SELECT 
					value AS NombreCombinacion_Part6
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 5 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED6 -- Parte 6

			OUTER APPLY (
				-- Dividir NombreCombinacion en la séptima parte
				SELECT 
					value AS NombreCombinacion_Part7
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 6 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED7 -- Parte 7

			OUTER APPLY (
				-- Dividir NombreCombinacion en la octava parte
				SELECT 
					value AS NombreCombinacion_Part8
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 7 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED8 -- Parte 8

			OUTER APPLY (
				-- Dividir NombreCombinacion en la novena parte
				SELECT 
					value AS NombreCombinacion_Part9
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 8 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED9 -- Parte 9
			WHERE NroFila <= 10;';
		EXEC sp_executesql @sql;

		-- 21. Combinacion de viaje por Distancia | _2_3_1_combinacion_corredor_utilizadas_Distancia
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_3_1_combinacion_corredor_utilizadas_Distancia;
		SELECT 
			distancia, 
			NombreCombinacion,
			SUM(CantidadRepeticiones) AS CantidadRepeticiones,
			SUM(SumaViajes) AS SumaViajes,
			ROW_NUMBER() OVER (PARTITION BY distancia ORDER BY SUM(SumaViajes) DESC) AS NroFila,
			PARTITIONED.NombreCombinacion_Part1 AS Etapa1,
			PARTITIONED2.NombreCombinacion_Part2 AS Etapa2,
			PARTITIONED3.NombreCombinacion_Part3 AS Etapa3,
			PARTITIONED4.NombreCombinacion_Part4 AS Etapa4,
			PARTITIONED5.NombreCombinacion_Part5 AS Etapa5,
			PARTITIONED6.NombreCombinacion_Part6 AS Etapa6,
			PARTITIONED7.NombreCombinacion_Part7 AS Etapa7,
			PARTITIONED8.NombreCombinacion_Part8 AS Etapa8,
			PARTITIONED9.NombreCombinacion_Part9 AS Etapa9
		INTO '+QUOTENAME(@Database)+'.dbo._2_3_1_combinacion_corredor_utilizadas_Distancia
		FROM (
			SELECT 
				distancia, 
				NombreCombinacion,
				SUM(CantidadRepeticiones) AS CantidadRepeticiones,
				SUM(SumaViajes) AS SumaViajes, -- Primero calculo la suma de etapas por par OD
				ROW_NUMBER() OVER (PARTITION BY distancia ORDER BY SUM(SumaViajes) DESC) AS NroFila
			FROM '+QUOTENAME(@Database)+'.dbo._2_base_combinaciones_por_linea_porParOD
			GROUP BY 
				distancia, 
				NombreCombinacion
		) AS Subquery';
		SET @SQL = @SQL + '
		OUTER APPLY (
			-- Dividir NombreCombinacion en la primera parte
			SELECT 
				value AS NombreCombinacion_Part1
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED -- Parte 1
		OUTER APPLY (
			-- Dividir NombreCombinacion en la segunda parte
			SELECT 
				value AS NombreCombinacion_Part2
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED2 -- Parte 2
		OUTER APPLY (
			-- Dividir NombreCombinacion en la tercera parte
			SELECT 
				value AS NombreCombinacion_Part3
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED3 -- Parte 3
		OUTER APPLY (
			-- Dividir NombreCombinacion en la cuarta parte
			SELECT 
				value AS NombreCombinacion_Part4
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 3 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED4 -- Parte 4';
		SET @SQL = @SQL + '
		OUTER APPLY (
			-- Dividir NombreCombinacion en la quinta parte
			SELECT 
				value AS NombreCombinacion_Part5
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 4 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED5 -- Parte 5
		OUTER APPLY (
			-- Dividir NombreCombinacion en la sexta parte
			SELECT 
				value AS NombreCombinacion_Part6
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 5 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED6 -- Parte 6
		OUTER APPLY (
			-- Dividir NombreCombinacion en la séptima parte
			SELECT 
				value AS NombreCombinacion_Part7
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 6 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED7 -- Parte 7
		OUTER APPLY (
			-- Dividir NombreCombinacion en la octava parte
			SELECT 
				value AS NombreCombinacion_Part8
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 7 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED8 -- Parte 8
		OUTER APPLY (
			-- Dividir NombreCombinacion en la novena parte
			SELECT 
				value AS NombreCombinacion_Part9
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 8 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED9 -- Parte 9
		WHERE NroFila <= 10
		GROUP BY 
			distancia, NombreCombinacion,
			PARTITIONED.NombreCombinacion_Part1,
			PARTITIONED2.NombreCombinacion_Part2,
			PARTITIONED3.NombreCombinacion_Part3,
			PARTITIONED4.NombreCombinacion_Part4,
			PARTITIONED5.NombreCombinacion_Part5,
			PARTITIONED6.NombreCombinacion_Part6,
			PARTITIONED7.NombreCombinacion_Part7,
			PARTITIONED8.NombreCombinacion_Part8,
			PARTITIONED9.NombreCombinacion_Part9;';
		EXEC sp_executesql @sql;

		-- 22. Combinacion de viaje por Modo Multimodal | _2_3_1_combinacion_corredor_utilizadas_ModoMultimodal
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_3_1_combinacion_corredor_utilizadas_ModoMultimodal;
		SELECT 
			ModoMultimodal,NombreCombinacion,
			SUM(CantidadRepeticiones) AS CantidadRepeticiones,
			SUM(SumaViajes) AS SumaViajes,
			ROW_NUMBER() OVER (PARTITION BY ModoMultimodal ORDER BY SUM(SumaViajes) DESC) AS NroFila,
			PARTITIONED.NombreCombinacion_Part1 AS Etapa1,
			PARTITIONED2.NombreCombinacion_Part2 AS Etapa2,
			PARTITIONED3.NombreCombinacion_Part3 AS Etapa3,
			PARTITIONED4.NombreCombinacion_Part4 AS Etapa4,
			PARTITIONED5.NombreCombinacion_Part5 AS Etapa5,
			PARTITIONED6.NombreCombinacion_Part6 AS Etapa6,
			PARTITIONED7.NombreCombinacion_Part7 AS Etapa7,
			PARTITIONED8.NombreCombinacion_Part8 AS Etapa8,
			PARTITIONED9.NombreCombinacion_Part9 AS Etapa9
		INTO '+QUOTENAME(@Database)+'.dbo._2_3_1_combinacion_corredor_utilizadas_ModoMultimodal -- Lineas Más Utilizadas ParOD y Modo
		FROM (
			SELECT 
				ModoMultimodal,NombreCombinacion,
				SUM(CantidadRepeticiones) AS CantidadRepeticiones,
				SUM(SumaViajes) AS SumaViajes, -- Primero calculo la suma de etapas por par OD
				ROW_NUMBER() OVER (PARTITION BY ModoMultimodal ORDER BY SUM(SumaViajes) DESC) AS NroFila -- Rankeo
			FROM '+QUOTENAME(@Database)+'.dbo._2_base_combinaciones_por_linea_porParOD
			GROUP BY
				ModoMultimodal,NombreCombinacion
		) AS Subquery';
		SET @SQL = @SQL + '
		OUTER APPLY (
			-- Dividir NombreCombinacion en la primera parte
			SELECT 
				value AS NombreCombinacion_Part1
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED -- Parte 1
		OUTER APPLY (
			-- Dividir NombreCombinacion en la segunda parte
			SELECT 
				value AS NombreCombinacion_Part2
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED2 -- Parte 2
		OUTER APPLY (
			-- Dividir NombreCombinacion en la tercera parte
			SELECT 
				value AS NombreCombinacion_Part3
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED3 -- Parte 3
		OUTER APPLY (
			-- Dividir NombreCombinacion en la cuarta parte
			SELECT 
				value AS NombreCombinacion_Part4
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 3 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED4 -- Parte 4
		OUTER APPLY (
			-- Dividir NombreCombinacion en la quinta parte
			SELECT 
				value AS NombreCombinacion_Part5
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 4 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED5 -- Parte 5';
		SET @SQL = @SQL + '
		OUTER APPLY (
			-- Dividir NombreCombinacion en la sexta parte
			SELECT 
				value AS NombreCombinacion_Part6
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 5 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED6 -- Parte 6
		OUTER APPLY (
			-- Dividir NombreCombinacion en la séptima parte
			SELECT 
				value AS NombreCombinacion_Part7
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 6 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED7 -- Parte 7
		OUTER APPLY (
			-- Dividir NombreCombinacion en la octava parte
			SELECT 
				value AS NombreCombinacion_Part8
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 7 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED8 -- Parte 8
		OUTER APPLY (
			-- Dividir NombreCombinacion en la novena parte
			SELECT 
				value AS NombreCombinacion_Part9
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 8 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED9 -- Parte 9
		WHERE NroFila <= 10
		GROUP BY 
			ModoMultimodal, NombreCombinacion,
			PARTITIONED.NombreCombinacion_Part1,
			PARTITIONED2.NombreCombinacion_Part2,
			PARTITIONED3.NombreCombinacion_Part3,
			PARTITIONED4.NombreCombinacion_Part4,
			PARTITIONED5.NombreCombinacion_Part5,
			PARTITIONED6.NombreCombinacion_Part6,
			PARTITIONED7.NombreCombinacion_Part7,
			PARTITIONED8.NombreCombinacion_Part8,
			PARTITIONED9.NombreCombinacion_Part9;';
		EXEC sp_executesql @sql;

		-- 23. Combinacion de viaje por Horario | _2_3_1_combinacion_corredor_utilizadas_horario
		SET @sql =
			'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_3_1_combinacion_corredor_utilizadas_horario;
			SELECT 
				pico_horario, NombreCombinacion, 
				SUM(CantidadRepeticiones) AS CantidadRepeticiones,
				SUM(SumaViajes) AS TotalViajes,
				ROW_NUMBER() OVER (PARTITION BY pico_horario ORDER BY SUM(SumaViajes) DESC) AS NroFila,
				PARTITIONED.NombreCombinacion_Part1 AS Etapa1,
				PARTITIONED2.NombreCombinacion_Part2 AS Etapa2,
				PARTITIONED3.NombreCombinacion_Part3 AS Etapa3,
				PARTITIONED4.NombreCombinacion_Part4 AS Etapa4,
				PARTITIONED5.NombreCombinacion_Part5 AS Etapa5,
				PARTITIONED6.NombreCombinacion_Part6 AS Etapa6,
				PARTITIONED7.NombreCombinacion_Part7 AS Etapa7,
				PARTITIONED8.NombreCombinacion_Part8 AS Etapa8,
				PARTITIONED9.NombreCombinacion_Part9 AS Etapa9
			INTO '+QUOTENAME(@Database)+'.dbo._2_3_1_combinacion_corredor_utilizadas_horario -- Lineas Más Utilizadas ParOD y Modo
			FROM (
				SELECT 
					pico_horario,NombreCombinacion,
					SUM(CantidadRepeticiones) AS CantidadRepeticiones,
					SUM(SumaViajes) AS SumaViajes, -- Primero calculo la suma de etapas por par OD
					ROW_NUMBER() OVER (PARTITION BY pico_horario ORDER BY SUM(SumaViajes) DESC) AS NroFila -- Rankeo
				FROM '+QUOTENAME(@Database)+'.dbo._2_base_combinaciones_por_linea_porParOD
				GROUP BY
					pico_horario, NombreCombinacion
			) AS Subquery';
		SET @SQL = @SQL + '
		OUTER APPLY (
			-- Dividir NombreCombinacion en la primera parte
			SELECT 
				value AS NombreCombinacion_Part1
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED -- Parte 1
		OUTER APPLY (
			-- Dividir NombreCombinacion en la segunda parte
			SELECT 
				value AS NombreCombinacion_Part2
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED2 -- Parte 2
		OUTER APPLY (
			-- Dividir NombreCombinacion en la tercera parte
			SELECT 
				value AS NombreCombinacion_Part3
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED3 -- Parte 3
		OUTER APPLY (
			-- Dividir NombreCombinacion en la cuarta parte
			SELECT 
				value AS NombreCombinacion_Part4
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 3 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED4 -- Parte 4';
		SET @SQL = @SQL + '
		OUTER APPLY (
			-- Dividir NombreCombinacion en la quinta parte
			SELECT 
				value AS NombreCombinacion_Part5
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 4 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED5 -- Parte 5
		OUTER APPLY (
			-- Dividir NombreCombinacion en la sexta parte
			SELECT 
				value AS NombreCombinacion_Part6
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 5 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED6 -- Parte 6
		OUTER APPLY (
			-- Dividir NombreCombinacion en la séptima parte
			SELECT 
				value AS NombreCombinacion_Part7
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 6 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED7 -- Parte 7
		OUTER APPLY (
			-- Dividir NombreCombinacion en la octava parte
			SELECT 
				value AS NombreCombinacion_Part8
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 7 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED8 -- Parte 8
		OUTER APPLY (
			-- Dividir NombreCombinacion en la novena parte
			SELECT 
				value AS NombreCombinacion_Part9
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 8 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED9 -- Parte 9
		WHERE NroFila <= 10
		GROUP BY 
			pico_horario, NombreCombinacion,
			PARTITIONED.NombreCombinacion_Part1,
			PARTITIONED2.NombreCombinacion_Part2,
			PARTITIONED3.NombreCombinacion_Part3,
			PARTITIONED4.NombreCombinacion_Part4,
			PARTITIONED5.NombreCombinacion_Part5,
			PARTITIONED6.NombreCombinacion_Part6,
			PARTITIONED7.NombreCombinacion_Part7,
			PARTITIONED8.NombreCombinacion_Part8,
			PARTITIONED9.NombreCombinacion_Part9;';
		EXEC sp_executesql @sql;

		-- 24. Combinacion de viaje por Distancia y Modo | _2_3_1_combinacion_corredor_utilizadas_Distancia_Modo
		SET @sql =
			'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_3_1_combinacion_corredor_utilizadas_Distancia_Modo;
			SELECT 
				Distancia, ModoMultimodal, NombreCombinacion, 
				SUM(CantidadRepeticiones) AS CantidadRepeticiones,
				SUM(SumaViajes) AS TotalViajes,
				ROW_NUMBER() OVER (PARTITION BY Distancia, ModoMultimodal ORDER BY SUM(SumaViajes) DESC) AS NroFila,
				PARTITIONED.NombreCombinacion_Part1 AS Etapa1,
				PARTITIONED2.NombreCombinacion_Part2 AS Etapa2,
				PARTITIONED3.NombreCombinacion_Part3 AS Etapa3,
				PARTITIONED4.NombreCombinacion_Part4 AS Etapa4,
				PARTITIONED5.NombreCombinacion_Part5 AS Etapa5,
				PARTITIONED6.NombreCombinacion_Part6 AS Etapa6,
				PARTITIONED7.NombreCombinacion_Part7 AS Etapa7,
				PARTITIONED8.NombreCombinacion_Part8 AS Etapa8,
				PARTITIONED9.NombreCombinacion_Part9 AS Etapa9
			INTO '+QUOTENAME(@Database)+'.dbo._2_3_1_combinacion_corredor_utilizadas_Distancia_Modo -- Lineas Más Utilizadas ParOD y Modo
			FROM (
				SELECT 
					Distancia, ModoMultimodal,NombreCombinacion,
					SUM(CantidadRepeticiones) AS CantidadRepeticiones,
					SUM(SumaViajes) AS SumaViajes, -- Primero calculo la suma de etapas por par OD
					ROW_NUMBER() OVER (PARTITION BY Distancia, ModoMultimodal ORDER BY SUM(SumaViajes) DESC) AS NroFila -- Rankeo
				FROM '+QUOTENAME(@Database)+'.dbo._2_base_combinaciones_por_linea_porParOD
				GROUP BY
					Distancia, ModoMultimodal, NombreCombinacion
			) AS Subquery';
		SET @SQL = @SQL + '
			OUTER APPLY (
				-- Dividir NombreCombinacion en la primera parte
				SELECT 
					value AS NombreCombinacion_Part1
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED -- Parte 1
			OUTER APPLY (
				-- Dividir NombreCombinacion en la segunda parte
				SELECT 
					value AS NombreCombinacion_Part2
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED2 -- Parte 2
			OUTER APPLY (
				-- Dividir NombreCombinacion en la tercera parte
				SELECT 
					value AS NombreCombinacion_Part3
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED3 -- Parte 3
			OUTER APPLY (
				-- Dividir NombreCombinacion en la cuarta parte
				SELECT 
					value AS NombreCombinacion_Part4
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 3 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED4 -- Parte 4
			OUTER APPLY (
				-- Dividir NombreCombinacion en la quinta parte
				SELECT 
					value AS NombreCombinacion_Part5
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 4 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED5 -- Parte 5';
		SET @SQL = @SQL + '
			OUTER APPLY (
				-- Dividir NombreCombinacion en la sexta parte
				SELECT 
					value AS NombreCombinacion_Part6
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 5 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED6 -- Parte 6
			OUTER APPLY (
				-- Dividir NombreCombinacion en la séptima parte
				SELECT 
					value AS NombreCombinacion_Part7
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 6 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED7 -- Parte 7
			OUTER APPLY (
				-- Dividir NombreCombinacion en la octava parte
				SELECT 
					value AS NombreCombinacion_Part8
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 7 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED8 -- Parte 8
			OUTER APPLY (
				-- Dividir NombreCombinacion en la novena parte
				SELECT 
					value AS NombreCombinacion_Part9
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 8 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED9 -- Parte 9
			WHERE NroFila <= 10
			GROUP BY 
				Distancia, ModoMultimodal, NombreCombinacion,
				PARTITIONED.NombreCombinacion_Part1,
				PARTITIONED2.NombreCombinacion_Part2,
				PARTITIONED3.NombreCombinacion_Part3,
				PARTITIONED4.NombreCombinacion_Part4,
				PARTITIONED5.NombreCombinacion_Part5,
				PARTITIONED6.NombreCombinacion_Part6,
				PARTITIONED7.NombreCombinacion_Part7,
				PARTITIONED8.NombreCombinacion_Part8,
				PARTITIONED9.NombreCombinacion_Part9;';
		EXEC sp_executesql @sql;

		-- 25. Combinacion de viaje por Distancia, Modo y Horario | _2_3_1_combinacion_corredor_utilizadas_Distancia_Modo_Horario
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_3_1_combinacion_corredor_utilizadas_Distancia_Modo_Horario;
		SELECT 
			Distancia, pico_horario, ModoMultimodal,NombreCombinacion,
			SUM(CantidadRepeticiones) AS CantidadRepeticiones,
			SUM(SumaViajes) AS TotalViajes,
			ROW_NUMBER() OVER (PARTITION BY Distancia, pico_horario, ModoMultimodal ORDER BY SUM(SumaViajes) DESC) AS NroFila,
			PARTITIONED.NombreCombinacion_Part1 AS Etapa1,
			PARTITIONED2.NombreCombinacion_Part2 AS Etapa2,
			PARTITIONED3.NombreCombinacion_Part3 AS Etapa3,
			PARTITIONED4.NombreCombinacion_Part4 AS Etapa4,
			PARTITIONED5.NombreCombinacion_Part5 AS Etapa5,
			PARTITIONED6.NombreCombinacion_Part6 AS Etapa6,
			PARTITIONED7.NombreCombinacion_Part7 AS Etapa7,
			PARTITIONED8.NombreCombinacion_Part8 AS Etapa8,
			PARTITIONED9.NombreCombinacion_Part9 AS Etapa9
		INTO '+QUOTENAME(@Database)+'.dbo._2_3_1_combinacion_corredor_utilizadas_Distancia_Modo_Horario -- Lineas Más Utilizadas ParOD y Modo
		FROM (
			SELECT 
				Distancia,pico_horario, ModoMultimodal,NombreCombinacion,
				SUM(CantidadRepeticiones) AS CantidadRepeticiones,
				SUM(SumaViajes) AS SumaViajes, -- Primero calculo la suma de etapas por par OD
				ROW_NUMBER() OVER (PARTITION BY Distancia, pico_horario, ModoMultimodal ORDER BY SUM(SumaViajes) DESC) AS NroFila -- Rankeo
			FROM '+QUOTENAME(@Database)+'.dbo._2_base_combinaciones_por_linea_porParOD
			WHERE TieneCombinacion = 0
			GROUP BY
				Distancia, pico_horario, ModoMultimodal, NombreCombinacion
		) AS Subquery';
		SET @SQL = @SQL + '
			OUTER APPLY (
				-- Dividir NombreCombinacion en la primera parte
				SELECT 
					value AS NombreCombinacion_Part1
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED -- Parte 1
			OUTER APPLY (
				-- Dividir NombreCombinacion en la segunda parte
				SELECT 
					value AS NombreCombinacion_Part2
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED2 -- Parte 2
			OUTER APPLY (
				-- Dividir NombreCombinacion en la tercera parte
				SELECT 
					value AS NombreCombinacion_Part3
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED3 -- Parte 3
			OUTER APPLY (
				-- Dividir NombreCombinacion en la cuarta parte
				SELECT 
					value AS NombreCombinacion_Part4
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 3 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED4 -- Parte 4';
		SET @SQL = @SQL + '
		OUTER APPLY (
			-- Dividir NombreCombinacion en la quinta parte
			SELECT 
				value AS NombreCombinacion_Part5
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 4 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED5 -- Parte 5
		OUTER APPLY (
			-- Dividir NombreCombinacion en la sexta parte
			SELECT 
				value AS NombreCombinacion_Part6
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 5 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED6 -- Parte 6
		OUTER APPLY (
			-- Dividir NombreCombinacion en la séptima parte
			SELECT 
				value AS NombreCombinacion_Part7
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 6 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED7 -- Parte 7
		OUTER APPLY (
			-- Dividir NombreCombinacion en la octava parte
			SELECT 
				value AS NombreCombinacion_Part8
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 7 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED8 -- Parte 8';
		SET @SQL = @SQL + '
		OUTER APPLY (
			-- Dividir NombreCombinacion en la novena parte
			SELECT 
				value AS NombreCombinacion_Part9
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 8 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED9 -- Parte 9
		WHERE NroFila <= 10
		GROUP BY 
			Distancia, pico_horario, ModoMultimodal, NombreCombinacion,
			PARTITIONED.NombreCombinacion_Part1,
			PARTITIONED2.NombreCombinacion_Part2,
			PARTITIONED3.NombreCombinacion_Part3,
			PARTITIONED4.NombreCombinacion_Part4,
			PARTITIONED5.NombreCombinacion_Part5,
			PARTITIONED6.NombreCombinacion_Part6,
			PARTITIONED7.NombreCombinacion_Part7,
			PARTITIONED8.NombreCombinacion_Part8,
			PARTITIONED9.NombreCombinacion_Part9;';
		EXEC sp_executesql @sql;
		
	-- Confirmar transacción
	COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
 ROLLBACK TRANSACTION;
	PRINT 'Error en la transacción: ' + ERROR_MESSAGE();
  PRINT 'Número de error: ' + CAST(ERROR_NUMBER() AS NVARCHAR(10);
  PRINT 'Procedimiento: ' + ERROR_PROCEDURE();
  PRINT 'Línea: ' + CAST(ERROR_LINE() AS NVARCHAR(10);
 END CATCH;
END;

CREATE PROCEDURE _004_2_Estadisticas_Viajes_Alternativos
 @Database NVARCHAR(15), -- Parámetro de entrada para la base de datos
 @IdLinea NVARCHAR(50),
 @BasePares NVARCHAR(20) -- Nombre de la base de pares a crear
AS
BEGIN
	DECLARE @sql NVARCHAR(MAX);
 BEGIN TRY
 -- Inicia la transacción
 BEGIN TRANSACTION;

		-- 1. Base de viajes alternativos | _2_2_base_viajes_tc_0
		SET @sql =
		'SELECT * 
		INTO '+QUOTENAME(@database)+'.dbo._2_2_base_viajes_tc_0
		FROM '+QUOTENAME(@database)+'.[dbo]._2_base_viajes v
		WHERE v.TieneCombinacion = 0';
		EXEC sp_executesql @sql;

		-- 2. Calculo agrupado de viajes por ParOD | _2_2_agrupado_ParOD_tc_0
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@database)+'.dbo._2_2_agrupado_ParOD_tc_0;
		SELECT 
			v.ParOD, v.distancia,
			v.IdO, v.IdD,
			v.z_origen,v.z_destino,
			-- COLECTIVO
			SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVO'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivo_tc_0,
			-- COLECTIVOx2
			SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVOx2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivox2_tc_0,
			-- COLECTIVOx3
			SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVOx3'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivox3_tc_0,
			-- COLECTIVO+4
			SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVO+4'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivoMas4_tc_0,
			-- SUBTE
			SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_subte_tc_0,
			-- SUBTEx2
			SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTEX2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_subtex2_tc_0,
			-- SUBTEx3
			SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTEx3'' THEN v.ViajesExpandidos ELSE 0 END) AS v_subtex3_tc_0,
			-- SUBTE+4
			SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTE+4'' THEN v.ViajesExpandidos ELSE 0 END) AS v_subteMas4_tc_0,
			-- TREN
			SUM(CASE WHEN v.ModoMultimodal = ''C-TREN'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_tc_0,
			-- TRENx2
			SUM(CASE WHEN v.ModoMultimodal = ''C-TRENx2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_trenx2_tc_0,
			-- TREN+3
			SUM(CASE WHEN v.ModoMultimodal = ''C-TREN+3'' THEN v.ViajesExpandidos ELSE 0 END) AS v_trenMas3_tc_0,
			-- COLECTIVO-SUBTE
			SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivo_subte_tc_0,
			-- COLECTIVO+2-SUBTE
			SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO+2-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivoMas2_subte_tc_0,
			-- COLECTIVO-SUBTE+2
			SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO-SUBTE+2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivo_subteMas2_tc_0,
			-- COLECTIVO+2-SUBTE+2
			SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO+2-SUBTE+2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivoMas2_subteMas2_tc_0,
			-- TREN-COLECTIVO
			SUM(CASE WHEN v.ModoMultimodal = ''E-TREN-COLECTIVO'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_colectivo_tc_0,
			-- TREN+2-COLECTIVO
			SUM(CASE WHEN v.ModoMultimodal = ''E-TREN+2-COLECTIVO'' THEN v.ViajesExpandidos ELSE 0 END) AS v_treMas2_colectivo_tc_0,
			-- TREN-COLECTIVO+2
			SUM(CASE WHEN v.ModoMultimodal = ''E-TREN-COLECTIVO+2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_colectivoMas2_tc_0,
			-- TREN-SUBTE
			SUM(CASE WHEN v.ModoMultimodal = ''F-TREN-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_subte_tc_0,
			-- TREN-COLECTIVO-SUBTE
			SUM(CASE WHEN v.ModoMultimodal = ''G-TREN-COLECTIVO-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_colectivo_subte_tc_0,
			-- Totales generales';
		SET @sql = @sql + '
			SUM(v.ViajesExpandidos) AS v_totales_tc_0,
			COUNT(DISTINCT v.id_tarjeta) AS TarjetasUnicas,
			SUM(CAST(v.tren AS INT) AS tren,
			SUM(CAST(v.autobus AS INT) AS autobus,
			SUM(CAST(v.metro AS INT) AS metro,
			SUM(CAST(v.cant_etapas AS INT) AS SumaEtapas,
			AVG(CAST(v.cant_etapas AS INT) AS PromedioEtapas,
			AVG(CAST(v.distance_h3 AS FLOAT) AS Promediodistance_h3,
			AVG(CAST(v.distance_osm_drive AS FLOAT)) AS Promediodistance_osm_drive
		INTO '+QUOTENAME(@database)+'.dbo._2_2_agrupado_ParOD_tc_0
		FROM '+QUOTENAME(@database)+'.[dbo]._2_2_base_viajes_tc_0 v
		GROUP BY
			v.ParOD, v.IdO, v.IdD, v.z_origen,v.z_destino
		ORDER BY
			v.ParOD;';
		EXEC sp_executesql @sql;

		-- 3. Calculo agrupado de viajes por ParOD y horario | _2_2_agrupado_ParOD_horario_tc_0
		SET @sql =
			'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_agrupado_ParOD_horario_tc_0;
			SELECT 
				v.ParOD, v.distancia,
				v.IdO, v.IdD,
				v.z_origen,v.z_destino,
				v.hora, v.pico_horario,
				-- COLECTIVO
				SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVO'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivo_tc_0,
				-- COLECTIVOx2
				SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVOx2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivox2_tc_0,
				-- COLECTIVOx3
				SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVOx3'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivox3_tc_0,
				-- COLECTIVO+4
				SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVO+4'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivoMas4_tc_0,
				-- SUBTE
				SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_subte_tc_0,
				-- SUBTEx2
				SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTEX2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_subtex2_tc_0,
				-- SUBTEx3
				SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTEx3'' THEN v.ViajesExpandidos ELSE 0 END) AS v_subtex3_tc_0,
				-- SUBTE+4
				SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTE+4'' THEN v.ViajesExpandidos ELSE 0 END) AS v_subteMas4_tc_0,
				-- TREN
				SUM(CASE WHEN v.ModoMultimodal = ''C-TREN'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_tc_0,
				-- TRENx2
				SUM(CASE WHEN v.ModoMultimodal = ''C-TRENx2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_trenx2_tc_0,
				-- TREN+3
				SUM(CASE WHEN v.ModoMultimodal = ''C-TREN+3'' THEN v.ViajesExpandidos ELSE 0 END) AS v_trenMas3_tc_0,
				-- COLECTIVO-SUBTE
				SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivo_subte_tc_0,
				-- COLECTIVO+2-SUBTE
				SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO+2-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivoMas2_subte_tc_0,
				-- COLECTIVO-SUBTE+2
				SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO-SUBTE+2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivo_subteMas2_tc_0,
				-- COLECTIVO+2-SUBTE+2
				SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO+2-SUBTE+2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivoMas2_subteMas2_tc_0,
				-- TREN-COLECTIVO
				SUM(CASE WHEN v.ModoMultimodal = ''E-TREN-COLECTIVO'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_colectivo_tc_0,';
		SET @sql = @sql + '
			-- TREN+2-COLECTIVO
			SUM(CASE WHEN v.ModoMultimodal = ''E-TREN+2-COLECTIVO'' THEN v.ViajesExpandidos ELSE 0 END) AS v_treMas2_colectivo_tc_0,
			-- TREN-COLECTIVO+2
			SUM(CASE WHEN v.ModoMultimodal = ''E-TREN-COLECTIVO+2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_colectivoMas2_tc_0,
			-- TREN-SUBTE
			SUM(CASE WHEN v.ModoMultimodal = ''F-TREN-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_subte_tc_0,
			-- TREN-COLECTIVO-SUBTE
			SUM(CASE WHEN v.ModoMultimodal = ''G-TREN-COLECTIVO-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_colectivo_subte_tc_0,
			-- Totales generales
			SUM(v.ViajesExpandidos) AS v_totales_tc_0,
			COUNT(DISTINCT v.id_tarjeta) AS TarjetasUnicas,
			SUM(CAST(v.tren AS INT) AS tren,
			SUM(CAST(v.autobus AS INT) AS autobus,
			SUM(CAST(v.metro AS INT) AS metro,
			SUM(CAST(v.cant_etapas AS INT) AS SumaEtapas,
			AVG(CAST(v.cant_etapas AS INT) AS PromedioEtapas,
			AVG(CAST(v.distance_h3 AS FLOAT) AS Promediodistance_h3,
			AVG(CAST(v.distance_osm_drive AS FLOAT)) AS Promediodistance_osm_drive
		INTO '+QUOTENAME(@Database)+'.[dbo]._2_2_agrupado_ParOD_horario_tc_0
		FROM '+QUOTENAME(@database)+'.[dbo]._2_2_base_viajes_tc_0 v
		GROUP BY
			v.ParOD, v.distancia,
			v.IdO, v.IdD,
			v.hora,v.pico_horario,
			v.z_origen,v.z_destino
		ORDER BY
			v.ParOD;';
		EXEC sp_executesql @sql;

		-- 4. Calculo agrupado de viajes por Distancia | _2_2_agrupado_distancia_tc_0
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_agrupado_distancia_tc_0;
		SELECT 
			v.distancia,
			-- COLECTIVO
			SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVO'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivo_tc_0,
			-- COLECTIVOx2
			SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVOx2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivox2_tc_0,
			-- COLECTIVOx3
			SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVOx3'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivox3_tc_0,
			-- COLECTIVO+4
			SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVO+4'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivoMas4_tc_0,
			-- SUBTE
			SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_subte_tc_0,
			-- SUBTEx2
			SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTEX2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_subtex2_tc_0,
			-- SUBTEx3
			SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTEx3'' THEN v.ViajesExpandidos ELSE 0 END) AS v_subtex3_tc_0,
			-- SUBTE+4
			SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTE+4'' THEN v.ViajesExpandidos ELSE 0 END) AS v_subteMas4_tc_0,
			-- TREN
			SUM(CASE WHEN v.ModoMultimodal = ''C-TREN'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_tc_0,
			-- TRENx2
			SUM(CASE WHEN v.ModoMultimodal = ''C-TRENx2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_trenx2_tc_0,
			-- TREN+3
			SUM(CASE WHEN v.ModoMultimodal = ''C-TREN+3'' THEN v.ViajesExpandidos ELSE 0 END) AS v_trenMas3_tc_0,
			-- COLECTIVO-SUBTE
			SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivo_subte_tc_0,
			-- COLECTIVO+2-SUBTE
			SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO+2-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivoMas2_subte_tc_0,
			-- COLECTIVO-SUBTE+2
			SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO-SUBTE+2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivo_subteMas2_tc_0,
			-- COLECTIVO+2-SUBTE+2
			SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO+2-SUBTE+2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivoMas2_subteMas2_tc_0,
			-- TREN-COLECTIVO
			SUM(CASE WHEN v.ModoMultimodal = ''E-TREN-COLECTIVO'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_colectivo_tc_0,
			-- TREN+2-COLECTIVO
			SUM(CASE WHEN v.ModoMultimodal = ''E-TREN+2-COLECTIVO'' THEN v.ViajesExpandidos ELSE 0 END) AS v_treMas2_colectivo_tc_0,
			-- TREN-COLECTIVO+2
			SUM(CASE WHEN v.ModoMultimodal = ''E-TREN-COLECTIVO+2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_colectivoMas2_tc_0,
			-- TREN-SUBTE
			SUM(CASE WHEN v.ModoMultimodal = ''F-TREN-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_subte_tc_0,
			-- TREN-COLECTIVO-SUBTE
			SUM(CASE WHEN v.ModoMultimodal = ''G-TREN-COLECTIVO-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_colectivo_subte_tc_0,
			-- Totales generales
			SUM(v.ViajesExpandidos) AS v_totales_tc_0,
			COUNT(DISTINCT v.id_tarjeta) AS TarjetasUnicas,
			SUM(CAST(v.tren AS INT) AS tren,
			SUM(CAST(v.autobus AS INT) AS autobus,
			SUM(CAST(v.metro AS INT) AS metro,
			SUM(CAST(v.cant_etapas AS INT) AS SumaEtapas,
			AVG(CAST(v.cant_etapas AS INT) AS PromedioEtapas,
			AVG(CAST(v.distance_h3 AS FLOAT) AS Promediodistance_h3,
			AVG(CAST(v.distance_osm_drive AS FLOAT)) AS Promediodistance_osm_drive
		INTO '+QUOTENAME(@Database)+'.dbo._2_2_agrupado_distancia_tc_0
		FROM '+QUOTENAME(@database)+'.[dbo]._2_2_base_viajes_tc_0 v
		GROUP BY
		 v.distancia
		ORDER BY
			v.distancia;';
		EXEC sp_executesql @sql;

		-- 5. Calculo agrupado de viajes por Hora | _2_2_agrupado_hora_tc_0
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_agrupado_hora_tc_0;
		SELECT 
			v.hora,
			-- COLECTIVO
			SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVO'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivo_tc_0,
			-- COLECTIVOx2
			SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVOx2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivox2_tc_0,
			-- COLECTIVOx3
			SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVOx3'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivox3_tc_0,
			-- COLECTIVO+4
			SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVO+4'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivoMas4_tc_0,
			-- SUBTE
			SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_subte_tc_0,
			-- SUBTEx2
			SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTEX2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_subtex2_tc_0,
			-- SUBTEx3
			SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTEx3'' THEN v.ViajesExpandidos ELSE 0 END) AS v_subtex3_tc_0,
			-- SUBTE+4
			SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTE+4'' THEN v.ViajesExpandidos ELSE 0 END) AS v_subteMas4_tc_0,
			-- TREN
			SUM(CASE WHEN v.ModoMultimodal = ''C-TREN'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_tc_0,
			-- TRENx2
			SUM(CASE WHEN v.ModoMultimodal = ''C-TRENx2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_trenx2_tc_0,
			-- TREN+3
			SUM(CASE WHEN v.ModoMultimodal = ''C-TREN+3'' THEN v.ViajesExpandidos ELSE 0 END) AS v_trenMas3_tc_0,
			-- COLECTIVO-SUBTE
			SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivo_subte_tc_0,
			-- COLECTIVO+2-SUBTE
			SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO+2-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivoMas2_subte_tc_0,
			-- COLECTIVO-SUBTE+2
			SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO-SUBTE+2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivo_subteMas2_tc_0,
			-- COLECTIVO+2-SUBTE+2
			SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO+2-SUBTE+2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivoMas2_subteMas2_tc_0,
			-- TREN-COLECTIVO
			SUM(CASE WHEN v.ModoMultimodal = ''E-TREN-COLECTIVO'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_colectivo_tc_0,
			-- TREN+2-COLECTIVO
			SUM(CASE WHEN v.ModoMultimodal = ''E-TREN+2-COLECTIVO'' THEN v.ViajesExpandidos ELSE 0 END) AS v_treMas2_colectivo_tc_0,
			-- TREN-COLECTIVO+2
			SUM(CASE WHEN v.ModoMultimodal = ''E-TREN-COLECTIVO+2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_colectivoMas2_tc_0,
			-- TREN-SUBTE
			SUM(CASE WHEN v.ModoMultimodal = ''F-TREN-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_subte_tc_0,
			-- TREN-COLECTIVO-SUBTE
			SUM(CASE WHEN v.ModoMultimodal = ''G-TREN-COLECTIVO-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_colectivo_subte_tc_0,
			-- Totales generales
			SUM(v.ViajesExpandidos) AS v_totales_tc_0,
			COUNT(DISTINCT v.id_tarjeta) AS TarjetasUnicas,
			SUM(CAST(v.tren AS INT) AS tren,
			SUM(CAST(v.autobus AS INT) AS autobus,
			SUM(CAST(v.metro AS INT) AS metro,
			SUM(CAST(v.cant_etapas AS INT) AS SumaEtapas,
			AVG(CAST(v.cant_etapas AS INT) AS PromedioEtapas,
			AVG(CAST(v.distance_h3 AS FLOAT) AS Promediodistance_h3,
			AVG(CAST(v.distance_osm_drive AS FLOAT)) AS Promediodistance_osm_drive
		INTO '+QUOTENAME(@Database)+'.dbo._2_2_agrupado_hora_tc_0
		FROM '+QUOTENAME(@database)+'.[dbo]._2_2_base_viajes_tc_0 v
		GROUP BY
		 v.hora
		ORDER BY
			v.hora;';
		EXEC sp_executesql @sql;

		-- 6. Calculo agrupado de viajes por Pico Horario | _2_2_agrupado_Pico_Horario_tc_0
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_agrupado_Pico_Horario_tc_0;
		SELECT 
			v.pico_horario,
			-- COLECTIVO
			SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVO'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivo_tc_0,
			-- COLECTIVOx2
			SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVOx2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivox2_tc_0,
			-- COLECTIVOx3
			SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVOx3'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivox3_tc_0,
			-- COLECTIVO+4
			SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVO+4'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivoMas4_tc_0,
			-- SUBTE
			SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_subte_tc_0,
			-- SUBTEx2
			SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTEX2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_subtex2_tc_0,
			-- SUBTEx3
			SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTEx3'' THEN v.ViajesExpandidos ELSE 0 END) AS v_subtex3_tc_0,
			-- SUBTE+4
			SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTE+4'' THEN v.ViajesExpandidos ELSE 0 END) AS v_subteMas4_tc_0,
			-- TREN
			SUM(CASE WHEN v.ModoMultimodal = ''C-TREN'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_tc_0,
			-- TRENx2
			SUM(CASE WHEN v.ModoMultimodal = ''C-TRENx2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_trenx2_tc_0,
			-- TREN+3
			SUM(CASE WHEN v.ModoMultimodal = ''C-TREN+3'' THEN v.ViajesExpandidos ELSE 0 END) AS v_trenMas3_tc_0,
			-- COLECTIVO-SUBTE
			SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivo_subte_tc_0,
			-- COLECTIVO+2-SUBTE
			SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO+2-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivoMas2_subte_tc_0,
			-- COLECTIVO-SUBTE+2
			SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO-SUBTE+2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivo_subteMas2_tc_0,
			-- COLECTIVO+2-SUBTE+2
			SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO+2-SUBTE+2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivoMas2_subteMas2_tc_0,
			-- TREN-COLECTIVO
			SUM(CASE WHEN v.ModoMultimodal = ''E-TREN-COLECTIVO'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_colectivo_tc_0,
			-- TREN+2-COLECTIVO
			SUM(CASE WHEN v.ModoMultimodal = ''E-TREN+2-COLECTIVO'' THEN v.ViajesExpandidos ELSE 0 END) AS v_treMas2_colectivo_tc_0,
			-- TREN-COLECTIVO+2
			SUM(CASE WHEN v.ModoMultimodal = ''E-TREN-COLECTIVO+2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_colectivoMas2_tc_0,
			-- TREN-SUBTE
			SUM(CASE WHEN v.ModoMultimodal = ''F-TREN-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_subte_tc_0,
			-- TREN-COLECTIVO-SUBTE
			SUM(CASE WHEN v.ModoMultimodal = ''G-TREN-COLECTIVO-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_colectivo_subte_tc_0,
			-- Totales generales
			SUM(v.ViajesExpandidos) AS v_totales_tc_0,
			COUNT(DISTINCT v.id_tarjeta) AS TarjetasUnicas,
			SUM(CAST(v.tren AS INT) AS tren,
			SUM(CAST(v.autobus AS INT) AS autobus,
			SUM(CAST(v.metro AS INT) AS metro,
			SUM(CAST(v.cant_etapas AS INT) AS SumaEtapas,
			AVG(CAST(v.cant_etapas AS INT) AS PromedioEtapas,
			AVG(CAST(v.distance_h3 AS FLOAT) AS Promediodistance_h3,
			AVG(CAST(v.distance_osm_drive AS FLOAT)) AS Promediodistance_osm_drive
		INTO '+QUOTENAME(@Database)+'.dbo._2_2_agrupado_Pico_Horario_tc_0
		FROM '+QUOTENAME(@database)+'.[dbo]._2_2_base_viajes_tc_0 v
		GROUP BY
			v.pico_horario
		ORDER BY
			v.pico_horario;';
		EXEC sp_executesql @sql;

		-- 7. Calculo distribución de viajes por ModoMultimodal y Combinacion | _2_2_distribucion_MultiModal_ModoCombinacion_tc_0
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_distribucion_MultiModal_ModoCombinacion_tc_0;
		SELECT 
			v.ModoMultimodal, v.ModoCombinacion,v.TieneCombinacion,
			SUM(v.ViajesExpandidos) AS v_totales,
			CASE WHEN (SELECT SUM(v.ViajesExpandidos) FROM '+QUOTENAME(@database)+'.[dbo]._2_2_base_viajes_tc_0 v) > 0 
			 THEN SUM(v.ViajesExpandidos) / (SELECT SUM(v.ViajesExpandidos) FROM '+QUOTENAME(@database)+'.[dbo]._2_2_base_viajes_tc_0 v)
			 ELSE 0 
			END AS Porcentaje,
			COUNT(DISTINCT v.id_tarjeta) AS TarjetasUnicas,
			SUM(CAST(v.tren AS INT) AS tren,
			SUM(CAST(v.autobus AS INT) AS autobus,
			SUM(CAST(v.metro AS INT) AS metro,
			SUM(CAST(v.cant_etapas AS INT) AS SumaEtapas,
			AVG(CAST(v.cant_etapas AS INT) AS PromedioEtapas,
			AVG(CAST(v.distance_h3 AS FLOAT) AS PromedioDistance_h3,
			AVG(CAST(v.distance_osm_drive AS FLOAT)) AS PromedioDistance_osm_drive
		INTO '+QUOTENAME(@Database)+'.dbo._2_2_distribucion_MultiModal_ModoCombinacion_tc_0
		FROM '+QUOTENAME(@database)+'.[dbo]._2_2_base_viajes_tc_0 v
		WHERE v.TieneCombinacion = 0
		GROUP BY
			v.ModoMultimodal, v.ModoCombinacion,v.TieneCombinacion
		ORDER BY
			v.ModoMultimodal;';
		EXEC sp_executesql @sql;

		-- 8. Calculo distribución de viajes por Distancia y ModoMultimodal | _2_2_distribucion_distancia_MultiModal_tc_0
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_distribucion_distancia_MultiModal_tc_0;
		SELECT 
			v.distancia, v.ModoMultimodal,v.TieneCombinacion,
			SUM(v.ViajesExpandidos) AS v_totales,
			CASE WHEN (SELECT SUM(v.ViajesExpandidos) FROM '+QUOTENAME(@database)+'.[dbo]._2_2_base_viajes_tc_0 v) > 0 
			 THEN SUM(v.ViajesExpandidos) / (SELECT SUM(v.ViajesExpandidos) FROM '+QUOTENAME(@database)+'.[dbo]._2_2_base_viajes_tc_0 v)
			 ELSE 0 
			END AS Porcentaje,
			COUNT(DISTINCT v.id_tarjeta) AS TarjetasUnicas,
			SUM(CAST(v.tren AS INT) AS tren,
			SUM(CAST(v.autobus AS INT) AS autobus,
			SUM(CAST(v.metro AS INT) AS metro,
			SUM(CAST(v.cant_etapas AS INT) AS SumaEtapas,
			AVG(CAST(v.cant_etapas AS INT) AS PromedioEtapas,
			AVG(CAST(v.distance_h3 AS FLOAT) AS PromedioDistance_h3,
			AVG(CAST(v.distance_osm_drive AS FLOAT)) AS PromedioDistance_osm_drive
		INTO '+QUOTENAME(@Database)+'.dbo._2_2_distribucion_distancia_MultiModal_tc_0
		 FROM '+QUOTENAME(@database)+'.[dbo]._2_2_base_viajes_tc_0 v
		GROUP BY
			v.distancia, v.ModoMultimodal,v.TieneCombinacion
		ORDER BY
			v.distancia;';
		EXEC sp_executesql @sql;

		-- 9. Calculo distribución de viajes por ModoMultimodal, Combinacion y horario | _2_2_distribucion_distancia_ModoMultiModal_Combinacion_horario_tc_0
		SET @sql =
			'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_distribucion_distancia_ModoMultiModal_Combinacion_horario_tc_0;
			SELECT 
				v.ModoMultimodal,v.ModoCombinacion,v.pico_horario,v.TieneCombinacion,
				SUM(v.ViajesExpandidos) AS v_totales,
				CASE WHEN (SELECT SUM(v.ViajesExpandidos) FROM '+QUOTENAME(@database)+'.[dbo]._2_2_base_viajes_tc_0 v) > 0 
				 THEN SUM(v.ViajesExpandidos) / (SELECT SUM(v.ViajesExpandidos) FROM '+QUOTENAME(@database)+'.[dbo]._2_2_base_viajes_tc_0 v)
				 ELSE 0 
				END AS Porcentaje,
				COUNT(DISTINCT v.id_tarjeta) AS TarjetasUnicas,
				SUM(CAST(v.tren AS INT) AS tren,
				SUM(CAST(v.autobus AS INT) AS autobus,
				SUM(CAST(v.metro AS INT) AS metro,
				SUM(CAST(v.cant_etapas AS INT) AS SumaEtapas,
				AVG(CAST(v.cant_etapas AS INT) AS PromedioEtapas,
				AVG(CAST(v.distance_h3 AS FLOAT) AS PromedioDistance_h3,
				AVG(CAST(v.distance_osm_drive AS FLOAT)) AS PromedioDistance_osm_drive
			INTO '+QUOTENAME(@Database)+'.dbo._2_2_distribucion_distancia_ModoMultiModal_Combinacion_horario_tc_0
			 FROM '+QUOTENAME(@database)+'.[dbo]._2_2_base_viajes_tc_0 v
			GROUP BY
				v.ModoMultimodal,v.ModoCombinacion,v.pico_horario,v.TieneCombinacion
			ORDER BY
				v.ModoMultimodal,v.ModoCombinacion,v.pico_horario;';
		EXEC sp_executesql @sql;

		-- 10. Calculo distribución de viajes por ModoMultimodal, Combinacion, distancia y horario | _2_2_distribucion_distancia_ModoMultiModal_Combinacion_distancia_horario_0
		SET @sql =
			'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_distribucion_distancia_ModoMultiModal_Combinacion_distancia_horario_0;
			SELECT 
				v.ModoMultimodal,v.ModoCombinacion,v.distancia,v.pico_horario,v.TieneCombinacion,
				SUM(v.ViajesExpandidos) AS v_totales,
				CASE WHEN (SELECT SUM(v.ViajesExpandidos) FROM '+QUOTENAME(@database)+'.[dbo]._2_2_base_viajes_tc_0 v) > 0 
				 THEN SUM(v.ViajesExpandidos) / (SELECT SUM(v.ViajesExpandidos) FROM '+QUOTENAME(@database)+'.[dbo]._2_2_base_viajes_tc_0 v)
				 ELSE 0 
				END AS Porcentaje,
				COUNT(DISTINCT v.id_tarjeta) AS TarjetasUnicas,
				SUM(CAST(v.tren AS INT) AS tren,
				SUM(CAST(v.autobus AS INT) AS autobus,
				SUM(CAST(v.metro AS INT) AS metro,
				SUM(CAST(v.cant_etapas AS INT) AS SumaEtapas,
				AVG(CAST(v.cant_etapas AS INT) AS PromedioEtapas,
				AVG(CAST(v.distance_h3 AS FLOAT) AS PromedioDistance_h3,
				AVG(CAST(v.distance_osm_drive AS FLOAT)) AS PromedioDistance_osm_drive
			INTO '+QUOTENAME(@Database)+'.dbo._2_2_distribucion_distancia_ModoMultiModal_Combinacion_distancia_horario_0
			 FROM '+QUOTENAME(@database)+'.[dbo]._2_2_base_viajes_tc_0 v
			GROUP BY
				v.ModoMultimodal,v.ModoCombinacion,v.distancia,v.pico_horario,v.TieneCombinacion
			ORDER BY
				v.ModoMultimodal,v.ModoCombinacion,v.distancia,v.pico_horario;';
		EXEC sp_executesql @sql;

		-- 11. Calculo de distribución de viajes por Horario y distancia | _2_2_distribucion_horario_distancia_tc_0
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_distribucion_horario_distancia_tc_0;
		SELECT 
			v.pico_horario, v.distancia, v.TieneCombinacion,
			SUM(v.ViajesExpandidos) AS v_totales,
			CASE WHEN (SELECT SUM(v.ViajesExpandidos) FROM '+QUOTENAME(@database)+'.[dbo]._2_2_base_viajes_tc_0 v) > 0 
			 THEN SUM(v.ViajesExpandidos) / (SELECT SUM(v.ViajesExpandidos) FROM '+QUOTENAME(@database)+'.[dbo]._2_2_base_viajes_tc_0 v)
			 ELSE 0 
			END AS Porcentaje,
			COUNT(DISTINCT v.id_tarjeta) AS TarjetasUnicas,
			SUM(CAST(v.tren AS INT) AS tren,
			SUM(CAST(v.autobus AS INT) AS autobus,
			SUM(CAST(v.metro AS INT) AS metro,
			SUM(CAST(v.cant_etapas AS INT) AS SumaEtapas,
			AVG(CAST(v.cant_etapas AS INT) AS PromedioEtapas,
			AVG(CAST(v.distance_h3 AS FLOAT) AS PromedioDistance_h3,
			AVG(CAST(v.distance_osm_drive AS FLOAT)) AS PromedioDistance_osm_drive
		INTO '+QUOTENAME(@Database)+'.dbo._2_2_distribucion_horario_distancia_tc_0
		FROM '+QUOTENAME(@database)+'.[dbo]._2_2_base_viajes_tc_0 v
		GROUP BY
			v.pico_horario, v.distancia, v.TieneCombinacion
		ORDER BY
			v.pico_horario, v.distancia;';
		EXEC sp_executesql @sql;

		-- 12. Calculo de distribución de viajes por horario y modo de combinacion | _2_2_distribucion_horario_ModoCombinacion_tc_0
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_distribucion_horario_ModoCombinacion_tc_0;
		SELECT 
			v.pico_horario, v.ModoCombinacion, v.TieneCombinacion,
			SUM(v.ViajesExpandidos) AS v_totales,
			CASE WHEN (SELECT SUM(v.ViajesExpandidos) FROM '+QUOTENAME(@database)+'.[dbo]._2_2_base_viajes_tc_0 v) > 0 
			 THEN SUM(v.ViajesExpandidos) / (SELECT SUM(v.ViajesExpandidos) FROM '+QUOTENAME(@database)+'.[dbo]._2_2_base_viajes_tc_0 v)
			 ELSE 0 
			END AS Porcentaje,
			COUNT(DISTINCT v.id_tarjeta) AS TarjetasUnicas,
			SUM(CAST(v.tren AS INT) AS tren,
			SUM(CAST(v.autobus AS INT) AS autobus,
			SUM(CAST(v.metro AS INT) AS metro,
			SUM(CAST(v.cant_etapas AS INT) AS SumaEtapas,
			AVG(CAST(v.cant_etapas AS INT) AS PromedioEtapas,
			AVG(CAST(v.distance_h3 AS FLOAT) AS PromedioDistance_h3,
			AVG(CAST(v.distance_osm_drive AS FLOAT)) AS PromedioDistance_osm_drive
		INTO '+QUOTENAME(@Database)+'.dbo._2_2_distribucion_horario_ModoCombinacion_tc_0
		FROM '+QUOTENAME(@database)+'.[dbo]._2_2_base_viajes_tc_0 v
		GROUP BY
			v.pico_horario, v.ModoCombinacion, v.TieneCombinacion
		ORDER BY
			v.pico_horario, v.ModoCombinacion;';
		EXEC sp_executesql @sql;
		
		-- 13. Calculo de etapas de cada linea por ParOD y Modo Multimodal | _2_2_2_etapas_por_linea_porParOD_ModoMultimodal_tc_0
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_2_etapas_por_linea_porParOD_ModoMultimodal_tc_0;
		SELECT 
			v.ParOD, v.distancia,v.IdO,v.IdD, v.z_origen,v.z_destino, v.ModoMultimodal, v.id_linea, v.nombre_linea, v.empresa,
			COUNT (v.id_linea) AS CantidadEtapas
		INTO '+QUOTENAME(@Database)+'.dbo._2_2_2_etapas_por_linea_porParOD_ModoMultimodal_tc_0
		FROM '+QUOTENAME(@Database)+'.dbo._2_base_etapas_por_linea_por_ParOD_tc_0 v
		GROUP BY
			v.ParOD, v.IdO,v.IdD, v.z_origen,v.z_destino, v.distancia, v.ModoMultimodal, v.id_linea, v.nombre_linea,	v.empresa
		ORDER BY
			v.ParOD,v.distancia,v.ModoMultimodal;';
		EXEC sp_executesql @sql;

		-- 14. Calculo de etapas de cada linea por ParOD | _2_2_2_etapas_por_linea_porParOD_tc_0
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_2_etapas_por_linea_porParOD_tc_0;
		SELECT 
			v.ParOD, v.distancia,v.IdO,v.IdD, v.z_origen,v.z_destino, v.id_linea, v.nombre_linea, v.empresa,
			COUNT (v.id_linea) AS CantidadEtapas
		INTO '+QUOTENAME(@Database)+'.dbo._2_2_2_etapas_por_linea_porParOD_tc_0
		FROM '+QUOTENAME(@Database)+'.dbo._2_base_etapas_por_linea_por_ParOD_tc_0 v
		GROUP BY
			v.ParOD, v.IdO,v.IdD, v.z_origen,v.z_destino, v.distancia, v.id_linea, v.nombre_linea,	v.empresa
		ORDER BY
			v.ParOD,v.distancia;';
		EXEC sp_executesql @sql;

		-- 15. Calculo de etapas de cada linea por Distancia | _2_2_2_etapas_por_linea_por_distancia_tc_0
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_2_etapas_por_linea_por_distancia_tc_0;
		SELECT 
			v.distancia,v.IdO,v.IdD, v.z_origen,v.z_destino, v.id_linea, v.nombre_linea, v.empresa,
			COUNT (v.id_linea) AS CantidadEtapas
		INTO '+QUOTENAME(@Database)+'.dbo._2_2_2_etapas_por_linea_por_distancia_tc_0
		FROM '+QUOTENAME(@Database)+'.dbo._2_base_etapas_por_linea_por_ParOD_tc_0 v
		GROUP BY
			v.distancia, v.IdO,v.IdD, v.z_origen,v.z_destino, v.id_linea, v.nombre_linea,	v.empresa
		ORDER BY
			v.distancia;';
		EXEC sp_executesql @sql;

		-- 16. Calculo de etapas de cada linea por ModoMultimodal | _2_2_2_etapas_por_linea_por_ModoMultimodal_tc_0
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_2_etapas_por_linea_por_ModoMultimodal_tc_0;
		SELECT 
			v.ModoMultimodal,v.IdO,v.IdD, v.z_origen,v.z_destino, v.id_linea, v.nombre_linea, v.empresa,
			COUNT (v.id_linea) AS CantidadEtapas
		INTO '+QUOTENAME(@Database)+'.dbo._2_2_2_etapas_por_linea_por_ModoMultimodal_tc_0
		FROM '+QUOTENAME(@Database)+'.dbo._2_base_etapas_por_linea_por_ParOD_tc_0 v
		GROUP BY
			v.ModoMultimodal, v.IdO,v.IdD, v.z_origen,v.z_destino, v.id_linea, v.nombre_linea,	v.empresa
		ORDER BY
			v.ModoMultimodal;';
		EXEC sp_executesql @sql;

		-- 17. Combinacion de viaje por ParOD | _2_2_1_combinacion_mas_utilizadas_porParOD_tc_0
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_1_combinacion_mas_utilizadas_porParOD_tc_0;
		SELECT 
			ParOD, distancia,z_origen, z_destino, NombreCombinacion, CantidadRepeticiones, SumaViajes,
			PARTITIONED.NombreCombinacion_Part1 AS Etapa1,
			PARTITIONED2.NombreCombinacion_Part2 AS Etapa2,
			PARTITIONED3.NombreCombinacion_Part3 AS Etapa3,
			PARTITIONED4.NombreCombinacion_Part4 AS Etapa4,
			PARTITIONED5.NombreCombinacion_Part5 AS Etapa5,
			PARTITIONED6.NombreCombinacion_Part6 AS Etapa6,
			PARTITIONED7.NombreCombinacion_Part7 AS Etapa7,
			PARTITIONED8.NombreCombinacion_Part8 AS Etapa8,
			PARTITIONED9.NombreCombinacion_Part9 AS Etapa9,
			ROW_NUMBER() OVER (PARTITION BY ParOD ORDER BY SumaViajes DESC) AS NroFila
		INTO '+QUOTENAME(@Database)+'.dbo._2_2_1_combinacion_mas_utilizadas_porParOD_tc_0
		FROM (
			SELECT 
				ParOD, distancia, z_origen, z_destino, NombreCombinacion, CantidadRepeticiones,
				SUM(SumaViajes) AS SumaViajes, -- Primero calculo la suma de etapas por par OD,
				ROW_NUMBER() OVER (PARTITION BY ParOD ORDER BY SUM(SumaViajes) DESC) AS NroFila -- Rankeo
			FROM '+QUOTENAME(@Database)+'.dbo._2_2_base_combinaciones_por_linea_porParOD_TC_0
			GROUP BY
				ParOD, z_origen, z_destino, distancia,NombreCombinacion, CantidadRepeticiones
		) AS Subquery';
		SET @sql = @sql + '
		OUTER APPLY (
			-- Dividir NombreCombinacion en la primera parte
			SELECT 
				value AS NombreCombinacion_Part1
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED -- Parte 1
		OUTER APPLY (
			-- Dividir NombreCombinacion en la segunda parte
			SELECT 
				value AS NombreCombinacion_Part2
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED2 -- Parte 2

		OUTER APPLY (
			-- Dividir NombreCombinacion en la tercera parte
			SELECT 
				value AS NombreCombinacion_Part3
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED3 -- Parte 3

		OUTER APPLY (
			-- Dividir NombreCombinacion en la cuarta parte
			SELECT 
				value AS NombreCombinacion_Part4
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 3 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED4 -- Parte 4';
		SET @sql = @sql + '

		OUTER APPLY (
			-- Dividir NombreCombinacion en la quinta parte
			SELECT 
				value AS NombreCombinacion_Part5
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 4 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED5 -- Parte 5

		OUTER APPLY (
			-- Dividir NombreCombinacion en la sexta parte
			SELECT 
				value AS NombreCombinacion_Part6
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 5 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED6 -- Parte 6

		OUTER APPLY (
			-- Dividir NombreCombinacion en la séptima parte
			SELECT 
				value AS NombreCombinacion_Part7
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 6 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED7 -- Parte 7

		OUTER APPLY (
			-- Dividir NombreCombinacion en la octava parte
			SELECT 
				value AS NombreCombinacion_Part8
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 7 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED8 -- Parte 8

		OUTER APPLY (
			-- Dividir NombreCombinacion en la novena parte
			SELECT 
				value AS NombreCombinacion_Part9
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 8 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED9 -- Parte 9
		WHERE NroFila <= 10;';
		EXEC sp_executesql @sql;

		-- 18. Combinacion de viaje por ParOD y Modo | _2_2_1_combinacion_utilizadas_ParOD_Modo_tc_0
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_1_combinacion_utilizadas_ParOD_Modo_tc_0;
		SELECT 
			ParOD, z_origen, z_destino, NombreCombinacion, distancia, ModoMultimodal, CantidadRepeticiones, SumaViajes,
			ROW_NUMBER() OVER (PARTITION BY ParOD, ModoMultimodal ORDER BY SumaViajes DESC) AS NroFila, -- Rankeo
			PARTITIONED.NombreCombinacion_Part1 AS Etapa1,
			PARTITIONED2.NombreCombinacion_Part2 AS Etapa2,
			PARTITIONED3.NombreCombinacion_Part3 AS Etapa3,
			PARTITIONED4.NombreCombinacion_Part4 AS Etapa4,
			PARTITIONED5.NombreCombinacion_Part5 AS Etapa5,
			PARTITIONED6.NombreCombinacion_Part6 AS Etapa6,
			PARTITIONED7.NombreCombinacion_Part7 AS Etapa7,
			PARTITIONED8.NombreCombinacion_Part8 AS Etapa8,
			PARTITIONED9.NombreCombinacion_Part9 AS Etapa9
		INTO '+QUOTENAME(@Database)+'.dbo._2_2_1_combinacion_utilizadas_ParOD_Modo_tc_0 -- Lineas Más Utilizadas ParOD y Modo
		FROM (
			SELECT 
				ParOD, z_origen, z_destino, NombreCombinacion, distancia, CantidadRepeticiones, ModoMultimodal,
				SUM(SumaViajes) AS SumaViajes, 
				ROW_NUMBER() OVER (PARTITION BY ParOD, ModoMultimodal ORDER BY SUM(SumaViajes) DESC) AS NroFila -- Rankeo
			FROM '+QUOTENAME(@Database)+'.dbo._2_2_base_combinaciones_por_linea_porParOD_TC_0
			GROUP BY
				ParOD, z_origen, z_destino,NombreCombinacion, distancia, ModoMultimodal, CantidadRepeticiones
		) AS Subquery';
		SET @sql = @sql + '
		OUTER APPLY (
			-- Dividir NombreCombinacion en la primera parte
			SELECT 
				value AS NombreCombinacion_Part1
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED -- Parte 1

		OUTER APPLY (
			-- Dividir NombreCombinacion en la segunda parte
			SELECT 
				value AS NombreCombinacion_Part2
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED2 -- Parte 2

		OUTER APPLY (
			-- Dividir NombreCombinacion en la tercera parte
			SELECT 
				value AS NombreCombinacion_Part3
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED3 -- Parte 3

		OUTER APPLY (
			-- Dividir NombreCombinacion en la cuarta parte
			SELECT 
				value AS NombreCombinacion_Part4
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 3 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED4 -- Parte 4

		OUTER APPLY (
			-- Dividir NombreCombinacion en la quinta parte
			SELECT 
				value AS NombreCombinacion_Part5
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 4 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED5 -- Parte 5

		OUTER APPLY (
			-- Dividir NombreCombinacion en la sexta parte
			SELECT 
				value AS NombreCombinacion_Part6
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 5 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED6 -- Parte 6';
		SET @sql = @sql + '

		OUTER APPLY (
			-- Dividir NombreCombinacion en la séptima parte
			SELECT 
				value AS NombreCombinacion_Part7
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 6 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED7 -- Parte 7

		OUTER APPLY (
			-- Dividir NombreCombinacion en la octava parte
			SELECT 
				value AS NombreCombinacion_Part8
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 7 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED8 -- Parte 8

		OUTER APPLY (
			-- Dividir NombreCombinacion en la novena parte
			SELECT 
				value AS NombreCombinacion_Part9
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 8 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED9 -- Parte 9
		WHERE NroFila <= 10;';
		EXEC sp_executesql @sql;

		-- 19. Combinacion de viaje por ParOD y Horario| _2_2_1_combinacion_utilizadas_ParOD_Horario_tc_0
		SET @sql =
			'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_1_combinacion_utilizadas_ParOD_Horario_tc_0;
			SELECT 
				ParOD,distancia z_origen, z_destino,NombreCombinacion, distancia, pico_horario, CantidadRepeticiones, SumaViajes,
				ROW_NUMBER() OVER (PARTITION BY ParOD, pico_horario ORDER BY SumaViajes DESC) AS NroFila, -- Rankeo
				PARTITIONED.NombreCombinacion_Part1 AS Etapa1,
				PARTITIONED2.NombreCombinacion_Part2 AS Etapa2,
				PARTITIONED3.NombreCombinacion_Part3 AS Etapa3,
				PARTITIONED4.NombreCombinacion_Part4 AS Etapa4,
				PARTITIONED5.NombreCombinacion_Part5 AS Etapa5,
				PARTITIONED6.NombreCombinacion_Part6 AS Etapa6,
				PARTITIONED7.NombreCombinacion_Part7 AS Etapa7,
				PARTITIONED8.NombreCombinacion_Part8 AS Etapa8,
				PARTITIONED9.NombreCombinacion_Part9 AS Etapa9
			INTO '+QUOTENAME(@Database)+'.dbo._2_2_1_combinacion_utilizadas_ParOD_Horario_tc_0 -- Lineas Más Utilizadas ParOD y Modo
			FROM (
				SELECT 
					ParOD, z_origen, z_destino,NombreCombinacion, distancia, pico_horario, CantidadRepeticiones,
					SUM(SumaViajes) AS SumaViajes, -- Primero calculo la suma de etapas por par OD
					ROW_NUMBER() OVER (PARTITION BY ParOD, NombreCombinacion,pico_horario ORDER BY SUM(SumaViajes) DESC) AS NroFila -- Rankeo
				FROM '+QUOTENAME(@Database)+'.dbo._2_2_base_combinaciones_por_linea_porParOD_TC_0
				GROUP BY
					ParOD, z_origen, z_destino,NombreCombinacion, distancia, pico_horario, CantidadRepeticiones
			) AS Subquery';
		SET @sql = @sql + '
			OUTER APPLY (
				-- Dividir NombreCombinacion en la primera parte
				SELECT 
					value AS NombreCombinacion_Part1
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED -- Parte 1

			OUTER APPLY (
				-- Dividir NombreCombinacion en la segunda parte
				SELECT 
					value AS NombreCombinacion_Part2
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED2 -- Parte 2

			OUTER APPLY (
				-- Dividir NombreCombinacion en la tercera parte
				SELECT 
					value AS NombreCombinacion_Part3
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED3 -- Parte 3

			OUTER APPLY (
				-- Dividir NombreCombinacion en la cuarta parte
				SELECT 
					value AS NombreCombinacion_Part4
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 3 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED4 -- Parte 4

			OUTER APPLY (
				-- Dividir NombreCombinacion en la quinta parte
				SELECT 
					value AS NombreCombinacion_Part5
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 4 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED5 -- Parte 5';
		SET @sql = @sql + '

		OUTER APPLY (
			-- Dividir NombreCombinacion en la sexta parte
			SELECT 
				value AS NombreCombinacion_Part6
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 5 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED6 -- Parte 6

		OUTER APPLY (
			-- Dividir NombreCombinacion en la séptima parte
			SELECT 
				value AS NombreCombinacion_Part7
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 6 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED7 -- Parte 7

		OUTER APPLY (
			-- Dividir NombreCombinacion en la octava parte
			SELECT 
				value AS NombreCombinacion_Part8
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 7 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED8 -- Parte 8

		OUTER APPLY (
			-- Dividir NombreCombinacion en la novena parte
			SELECT 
				value AS NombreCombinacion_Part9
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 8 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED9 -- Parte 9
		WHERE NroFila <= 10;';
		EXEC sp_executesql @sql;

		-- 20. Combinacion de viaje por ParOD, Modo y Distancia | _2_2_1_combinacion_utilizadas_ParOD_Modo_Distancia_tc_0
		SET @sql =
			'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_1_combinacion_utilizadas_ParOD_Modo_Distancia_tc_0;
			SELECT 
				ParOD, distancia, z_origen, z_destino,NombreCombinacion, ModoMultimodal, CantidadRepeticiones, SumaViajes,
				ROW_NUMBER() OVER (PARTITION BY ParOD, ModoMultimodal, distancia ORDER BY SumaViajes DESC) AS NroFila, -- Rankeo
				PARTITIONED.NombreCombinacion_Part1 AS Etapa1,
				PARTITIONED2.NombreCombinacion_Part2 AS Etapa2,
				PARTITIONED3.NombreCombinacion_Part3 AS Etapa3,
				PARTITIONED4.NombreCombinacion_Part4 AS Etapa4,
				PARTITIONED5.NombreCombinacion_Part5 AS Etapa5,
				PARTITIONED6.NombreCombinacion_Part6 AS Etapa6,
				PARTITIONED7.NombreCombinacion_Part7 AS Etapa7,
				PARTITIONED8.NombreCombinacion_Part8 AS Etapa8,
				PARTITIONED9.NombreCombinacion_Part9 AS Etapa9
			INTO '+QUOTENAME(@Database)+'.dbo._2_2_1_combinacion_utilizadas_ParOD_Modo_Distancia_tc_0 -- Lineas Más Utilizadas ParOD y Modo
			FROM (
				SELECT 
					ParOD, z_origen, z_destino, NombreCombinacion,distancia, ModoMultimodal, CantidadRepeticiones,
					SUM(SumaViajes) AS SumaViajes, -- Primero calculo la suma de etapas por par OD
					ROW_NUMBER() OVER (PARTITION BY ParOD, ModoMultimodal, distancia ORDER BY SUM(SumaViajes) DESC) AS NroFila -- Rankeo
				FROM '+QUOTENAME(@Database)+'.dbo._2_2_base_combinaciones_por_linea_porParOD_TC_0
				GROUP BY
					ParOD, z_origen, z_destino,NombreCombinacion, distancia, ModoMultimodal,CantidadRepeticiones
			) AS Subquery
			OUTER APPLY (
				-- Dividir NombreCombinacion en la primera parte
				SELECT 
					value AS NombreCombinacion_Part1
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED -- Parte 1';
		SET @sql = @sql + '
			OUTER APPLY (
				-- Dividir NombreCombinacion en la segunda parte
				SELECT 
					value AS NombreCombinacion_Part2
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED2 -- Parte 2

			OUTER APPLY (
				-- Dividir NombreCombinacion en la tercera parte
				SELECT 
					value AS NombreCombinacion_Part3
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED3 -- Parte 3

			OUTER APPLY (
				-- Dividir NombreCombinacion en la cuarta parte
				SELECT 
					value AS NombreCombinacion_Part4
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 3 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED4 -- Parte 4

			OUTER APPLY (
				-- Dividir NombreCombinacion en la quinta parte
				SELECT 
					value AS NombreCombinacion_Part5
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 4 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED5 -- Parte 5';
		SET @sql = @sql + '
		OUTER APPLY (
			-- Dividir NombreCombinacion en la sexta parte
			SELECT 
				value AS NombreCombinacion_Part6
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 5 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED6 -- Parte 6

		OUTER APPLY (
			-- Dividir NombreCombinacion en la séptima parte
			SELECT 
				value AS NombreCombinacion_Part7
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 6 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED7 -- Parte 7

		OUTER APPLY (
			-- Dividir NombreCombinacion en la octava parte
			SELECT 
				value AS NombreCombinacion_Part8
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 7 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED8 -- Parte 8

		OUTER APPLY (
			-- Dividir NombreCombinacion en la novena parte
			SELECT 
				value AS NombreCombinacion_Part9
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 8 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED9 -- Parte 9
		WHERE NroFila <= 10;';
		EXEC sp_executesql @sql;

		-- 21. Combinacion de viaje por ParOd, Modo, Distancia y Modo | _2_2_1_combinacion_utilizadas_ParOD_Modo_Distancia_horario_tc_0
		SET @sql =
			'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_1_combinacion_utilizadas_ParOD_Modo_Distancia_horario_tc_0;
			SELECT 
				ParOD,distancia, z_origen, z_destino,NombreCombinacion, ModoMultimodal, pico_horario, CantidadRepeticiones,SumaViajes,
				ROW_NUMBER() OVER (PARTITION BY ParOD, ModoMultimodal, distancia, pico_horario ORDER BY SumaViajes DESC) AS NroFila, -- Rankeo
				PARTITIONED.NombreCombinacion_Part1 AS Etapa1,
				PARTITIONED2.NombreCombinacion_Part2 AS Etapa2,
				PARTITIONED3.NombreCombinacion_Part3 AS Etapa3,
				PARTITIONED4.NombreCombinacion_Part4 AS Etapa4,
				PARTITIONED5.NombreCombinacion_Part5 AS Etapa5,
				PARTITIONED6.NombreCombinacion_Part6 AS Etapa6,
				PARTITIONED7.NombreCombinacion_Part7 AS Etapa7,
				PARTITIONED8.NombreCombinacion_Part8 AS Etapa8,
				PARTITIONED9.NombreCombinacion_Part9 AS Etapa9
			INTO '+QUOTENAME(@Database)+'.dbo._2_2_1_combinacion_utilizadas_ParOD_Modo_Distancia_horario_tc_0 -- Lineas Más Utilizadas ParOD y Modo
			FROM (
				SELECT 
					ParOD, z_origen, z_destino,NombreCombinacion, distancia, ModoMultimodal, pico_horario, CantidadRepeticiones,
					SUM(SumaViajes) AS SumaViajes, -- Primero calculo la suma de etapas por par OD
					ROW_NUMBER() OVER (PARTITION BY ParOD, ModoMultimodal, distancia, pico_horario ORDER BY SUM(SumaViajes) DESC) AS NroFila -- Rankeo
				FROM '+QUOTENAME(@Database)+'.dbo._2_2_base_combinaciones_por_linea_porParOD_TC_0
				GROUP BY
					ParOD, z_origen, z_destino,NombreCombinacion, distancia, ModoMultimodal, pico_horario,CantidadRepeticiones
			) AS Subquery';
		SET @sql = @sql + '
		OUTER APPLY (
			-- Dividir NombreCombinacion en la primera parte
			SELECT 
				value AS NombreCombinacion_Part1
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED -- Parte 1
		OUTER APPLY (
			-- Dividir NombreCombinacion en la segunda parte
			SELECT 
				value AS NombreCombinacion_Part2
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED2 -- Parte 2
		OUTER APPLY (
			-- Dividir NombreCombinacion en la tercera parte
			SELECT 
				value AS NombreCombinacion_Part3
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED3 -- Parte 3
		OUTER APPLY (
			-- Dividir NombreCombinacion en la cuarta parte
			SELECT 
				value AS NombreCombinacion_Part4
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 3 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED4 -- Parte 4
		OUTER APPLY (
			-- Dividir NombreCombinacion en la quinta parte
			SELECT 
				value AS NombreCombinacion_Part5
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 4 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED5 -- Parte 5';
		SET @sql = @sql + '
		OUTER APPLY (
			-- Dividir NombreCombinacion en la sexta parte
			SELECT 
				value AS NombreCombinacion_Part6
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 5 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED6 -- Parte 6

		OUTER APPLY (
			-- Dividir NombreCombinacion en la séptima parte
			SELECT 
				value AS NombreCombinacion_Part7
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 6 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED7 -- Parte 7

		OUTER APPLY (
			-- Dividir NombreCombinacion en la octava parte
			SELECT 
				value AS NombreCombinacion_Part8
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 7 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED8 -- Parte 8

		OUTER APPLY (
			-- Dividir NombreCombinacion en la novena parte
			SELECT 
				value AS NombreCombinacion_Part9
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 8 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED9 -- Parte 9
		WHERE NroFila <= 10;';
		EXEC sp_executesql @sql;

		-- 22. Combinacion de viaje por Distancia | _2_2_1_combinacion_utilizadas_Distancia_tc_0
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_1_combinacion_utilizadas_Distancia_tc_0;
		SELECT 
			distancia, 
			NombreCombinacion,
			SUM(CantidadRepeticiones) AS CantidadRepeticiones,
			SUM(SumaViajes) AS SumaViajes,
			ROW_NUMBER() OVER (PARTITION BY distancia ORDER BY SUM(SumaViajes) DESC) AS NroFila,
			PARTITIONED.NombreCombinacion_Part1 AS Etapa1,
			PARTITIONED2.NombreCombinacion_Part2 AS Etapa2,
			PARTITIONED3.NombreCombinacion_Part3 AS Etapa3,
			PARTITIONED4.NombreCombinacion_Part4 AS Etapa4,
			PARTITIONED5.NombreCombinacion_Part5 AS Etapa5,
			PARTITIONED6.NombreCombinacion_Part6 AS Etapa6,
			PARTITIONED7.NombreCombinacion_Part7 AS Etapa7,
			PARTITIONED8.NombreCombinacion_Part8 AS Etapa8,
			PARTITIONED9.NombreCombinacion_Part9 AS Etapa9
		INTO '+QUOTENAME(@Database)+'.dbo._2_2_1_combinacion_utilizadas_Distancia_tc_0
		FROM (
			SELECT 
				distancia, 
				NombreCombinacion,
				SUM(CantidadRepeticiones) AS CantidadRepeticiones,
				SUM(SumaViajes) AS SumaViajes, -- Primero calculo la suma de etapas por par OD
				ROW_NUMBER() OVER (PARTITION BY distancia ORDER BY SUM(SumaViajes) DESC) AS NroFila
			FROM '+QUOTENAME(@Database)+'.dbo._2_2_base_combinaciones_por_linea_porParOD_TC_0
			GROUP BY 
				distancia, 
				NombreCombinacion
		) AS Subquery';
		SET @sql = @sql + '
			OUTER APPLY (
				-- Dividir NombreCombinacion en la primera parte
				SELECT 
					value AS NombreCombinacion_Part1
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED -- Parte 1
			OUTER APPLY (
				-- Dividir NombreCombinacion en la segunda parte
				SELECT 
					value AS NombreCombinacion_Part2
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED2 -- Parte 2
			OUTER APPLY (
				-- Dividir NombreCombinacion en la tercera parte
				SELECT 
					value AS NombreCombinacion_Part3
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED3 -- Parte 3
			OUTER APPLY (
				-- Dividir NombreCombinacion en la cuarta parte
				SELECT 
					value AS NombreCombinacion_Part4
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 3 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED4 -- Parte 4
			OUTER APPLY (
				-- Dividir NombreCombinacion en la quinta parte
				SELECT 
					value AS NombreCombinacion_Part5
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 4 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED5 -- Parte 5';
		SET @sql = @sql + '
		OUTER APPLY (
			-- Dividir NombreCombinacion en la sexta parte
			SELECT 
				value AS NombreCombinacion_Part6
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 5 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED6 -- Parte 6
		OUTER APPLY (
			-- Dividir NombreCombinacion en la séptima parte
			SELECT 
				value AS NombreCombinacion_Part7
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 6 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED7 -- Parte 7
		OUTER APPLY (
			-- Dividir NombreCombinacion en la octava parte
			SELECT 
				value AS NombreCombinacion_Part8
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 7 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED8 -- Parte 8
		OUTER APPLY (
			-- Dividir NombreCombinacion en la novena parte
			SELECT 
				value AS NombreCombinacion_Part9
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 8 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED9 -- Parte 9
		WHERE NroFila <= 10
		GROUP BY 
			distancia, NombreCombinacion,
			PARTITIONED.NombreCombinacion_Part1,
			PARTITIONED2.NombreCombinacion_Part2,
			PARTITIONED3.NombreCombinacion_Part3,
			PARTITIONED4.NombreCombinacion_Part4,
			PARTITIONED5.NombreCombinacion_Part5,
			PARTITIONED6.NombreCombinacion_Part6,
			PARTITIONED7.NombreCombinacion_Part7,
			PARTITIONED8.NombreCombinacion_Part8,
			PARTITIONED9.NombreCombinacion_Part9;';
		EXEC sp_executesql @sql;

		-- 23. Combinacion de viaje por Modo Multimodal | _2_2_1_combinacion_utilizadas_ModoMultimodal_tc_0
		SET @sql =
			'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_1_combinacion_utilizadas_ModoMultimodal_tc_0;
			SELECT 
				ModoMultimodal,NombreCombinacion,
				SUM(CantidadRepeticiones) AS CantidadRepeticiones,
				SUM(SumaViajes) AS SumaViajes,
				ROW_NUMBER() OVER (PARTITION BY ModoMultimodal ORDER BY SUM(SumaViajes) DESC) AS NroFila,
				PARTITIONED.NombreCombinacion_Part1 AS Etapa1,
				PARTITIONED2.NombreCombinacion_Part2 AS Etapa2,
				PARTITIONED3.NombreCombinacion_Part3 AS Etapa3,
				PARTITIONED4.NombreCombinacion_Part4 AS Etapa4,
				PARTITIONED5.NombreCombinacion_Part5 AS Etapa5,
				PARTITIONED6.NombreCombinacion_Part6 AS Etapa6,
				PARTITIONED7.NombreCombinacion_Part7 AS Etapa7,
				PARTITIONED8.NombreCombinacion_Part8 AS Etapa8,
				PARTITIONED9.NombreCombinacion_Part9 AS Etapa9
			INTO '+QUOTENAME(@Database)+'.dbo._2_2_1_combinacion_utilizadas_ModoMultimodal_tc_0 -- Lineas Más Utilizadas ParOD y Modo
			FROM (
				SELECT 
					ModoMultimodal,NombreCombinacion,
					SUM(CantidadRepeticiones) AS CantidadRepeticiones,
					SUM(SumaViajes) AS SumaViajes, -- Primero calculo la suma de etapas por par OD
					ROW_NUMBER() OVER (PARTITION BY ModoMultimodal ORDER BY SUM(SumaViajes) DESC) AS NroFila -- Rankeo
				FROM '+QUOTENAME(@Database)+'.dbo._2_2_base_combinaciones_por_linea_porParOD_TC_0
				GROUP BY
					ModoMultimodal,NombreCombinacion
			) AS Subquery';
		SET @sql = @sql + '
			OUTER APPLY (
				-- Dividir NombreCombinacion en la primera parte
				SELECT 
					value AS NombreCombinacion_Part1
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED -- Parte 1
			OUTER APPLY (
				-- Dividir NombreCombinacion en la segunda parte
				SELECT 
					value AS NombreCombinacion_Part2
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED2 -- Parte 2
			OUTER APPLY (
				-- Dividir NombreCombinacion en la tercera parte
				SELECT 
					value AS NombreCombinacion_Part3
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED3 -- Parte 3
			OUTER APPLY (
				-- Dividir NombreCombinacion en la cuarta parte
				SELECT 
					value AS NombreCombinacion_Part4
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 3 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED4 -- Parte 4
			OUTER APPLY (
				-- Dividir NombreCombinacion en la quinta parte
				SELECT 
					value AS NombreCombinacion_Part5
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 4 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED5 -- Parte 5';
		SET @sql = @sql + '
		OUTER APPLY (
			-- Dividir NombreCombinacion en la sexta parte
			SELECT 
				value AS NombreCombinacion_Part6
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 5 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED6 -- Parte 6
		OUTER APPLY (
			-- Dividir NombreCombinacion en la séptima parte
			SELECT 
				value AS NombreCombinacion_Part7
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 6 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED7 -- Parte 7
		OUTER APPLY (
			-- Dividir NombreCombinacion en la octava parte
			SELECT 
				value AS NombreCombinacion_Part8
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 7 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED8 -- Parte 8
		OUTER APPLY (
			-- Dividir NombreCombinacion en la novena parte
			SELECT 
				value AS NombreCombinacion_Part9
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 8 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED9 -- Parte 9
		WHERE NroFila <= 10
		GROUP BY 
			ModoMultimodal, NombreCombinacion,
			PARTITIONED.NombreCombinacion_Part1,
			PARTITIONED2.NombreCombinacion_Part2,
			PARTITIONED3.NombreCombinacion_Part3,
			PARTITIONED4.NombreCombinacion_Part4,
			PARTITIONED5.NombreCombinacion_Part5,
			PARTITIONED6.NombreCombinacion_Part6,
			PARTITIONED7.NombreCombinacion_Part7,
			PARTITIONED8.NombreCombinacion_Part8,
			PARTITIONED9.NombreCombinacion_Part9;';
		EXEC sp_executesql @sql;

		-- 24. Combinacion de viaje por Horario | _2_2_1_combinacion_utilizadas_horario_tc_0
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_1_combinacion_utilizadas_horario_tc_0;
		SELECT 
			pico_horario, NombreCombinacion, 
			SUM(CantidadRepeticiones) AS CantidadRepeticiones,
			SUM(SumaViajes) AS TotalViajes,
			ROW_NUMBER() OVER (PARTITION BY pico_horario ORDER BY SUM(SumaViajes) DESC) AS NroFila,
			PARTITIONED.NombreCombinacion_Part1 AS Etapa1,
			PARTITIONED2.NombreCombinacion_Part2 AS Etapa2,
			PARTITIONED3.NombreCombinacion_Part3 AS Etapa3,
			PARTITIONED4.NombreCombinacion_Part4 AS Etapa4,
			PARTITIONED5.NombreCombinacion_Part5 AS Etapa5,
			PARTITIONED6.NombreCombinacion_Part6 AS Etapa6,
			PARTITIONED7.NombreCombinacion_Part7 AS Etapa7,
			PARTITIONED8.NombreCombinacion_Part8 AS Etapa8,
			PARTITIONED9.NombreCombinacion_Part9 AS Etapa9
		INTO '+QUOTENAME(@Database)+'.dbo._2_2_1_combinacion_utilizadas_horario_tc_0 -- Lineas Más Utilizadas ParOD y Modo
		FROM (
			SELECT 
				pico_horario,NombreCombinacion,
				SUM(CantidadRepeticiones) AS CantidadRepeticiones,
				SUM(SumaViajes) AS SumaViajes, -- Primero calculo la suma de etapas por par OD
				ROW_NUMBER() OVER (PARTITION BY pico_horario ORDER BY SUM(SumaViajes) DESC) AS NroFila -- Rankeo
			FROM '+QUOTENAME(@Database)+'.dbo._2_2_base_combinaciones_por_linea_porParOD_TC_0
			GROUP BY
				pico_horario, NombreCombinacion
		) AS Subquery';
		SET @sql = @sql + '
			OUTER APPLY (
				-- Dividir NombreCombinacion en la primera parte
				SELECT 
					value AS NombreCombinacion_Part1
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED -- Parte 1
			OUTER APPLY (
				-- Dividir NombreCombinacion en la segunda parte
				SELECT 
					value AS NombreCombinacion_Part2
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED2 -- Parte 2
			OUTER APPLY (
				-- Dividir NombreCombinacion en la tercera parte
				SELECT 
					value AS NombreCombinacion_Part3
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED3 -- Parte 3
			OUTER APPLY (
				-- Dividir NombreCombinacion en la cuarta parte
				SELECT 
					value AS NombreCombinacion_Part4
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 3 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED4 -- Parte 4
			OUTER APPLY (
				-- Dividir NombreCombinacion en la quinta parte
				SELECT 
					value AS NombreCombinacion_Part5
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 4 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED5 -- Parte 5';
		SET @sql = @sql + '
			OUTER APPLY (
				-- Dividir NombreCombinacion en la sexta parte
				SELECT 
					value AS NombreCombinacion_Part6
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 5 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED6 -- Parte 6
			OUTER APPLY (
				-- Dividir NombreCombinacion en la séptima parte
				SELECT 
					value AS NombreCombinacion_Part7
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 6 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED7 -- Parte 7
			OUTER APPLY (
				-- Dividir NombreCombinacion en la octava parte
				SELECT 
					value AS NombreCombinacion_Part8
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 7 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED8 -- Parte 8
			OUTER APPLY (
				-- Dividir NombreCombinacion en la novena parte
				SELECT 
					value AS NombreCombinacion_Part9
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 8 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED9 -- Parte 9
			WHERE NroFila <= 10
			GROUP BY 
				pico_horario, NombreCombinacion,
				PARTITIONED.NombreCombinacion_Part1,
				PARTITIONED2.NombreCombinacion_Part2,
				PARTITIONED3.NombreCombinacion_Part3,
				PARTITIONED4.NombreCombinacion_Part4,
				PARTITIONED5.NombreCombinacion_Part5,
				PARTITIONED6.NombreCombinacion_Part6,
				PARTITIONED7.NombreCombinacion_Part7,
				PARTITIONED8.NombreCombinacion_Part8,
				PARTITIONED9.NombreCombinacion_Part9;';
		EXEC sp_executesql @sql;

		-- 25. Combinacion de viaje por Distancia y Modo | _2_2_1_combinacion_utilizadas_Distancia_Modo_tc_0
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_1_combinacion_utilizadas_Distancia_Modo_tc_0;
		SELECT 
			Distancia, ModoMultimodal, NombreCombinacion, 
			SUM(CantidadRepeticiones) AS CantidadRepeticiones,
			SUM(SumaViajes) AS TotalViajes,
			ROW_NUMBER() OVER (PARTITION BY Distancia, ModoMultimodal ORDER BY SUM(SumaViajes) DESC) AS NroFila,
			PARTITIONED.NombreCombinacion_Part1 AS Etapa1,
			PARTITIONED2.NombreCombinacion_Part2 AS Etapa2,
			PARTITIONED3.NombreCombinacion_Part3 AS Etapa3,
			PARTITIONED4.NombreCombinacion_Part4 AS Etapa4,
			PARTITIONED5.NombreCombinacion_Part5 AS Etapa5,
			PARTITIONED6.NombreCombinacion_Part6 AS Etapa6,
			PARTITIONED7.NombreCombinacion_Part7 AS Etapa7,
			PARTITIONED8.NombreCombinacion_Part8 AS Etapa8,
			PARTITIONED9.NombreCombinacion_Part9 AS Etapa9
		INTO '+QUOTENAME(@Database)+'.dbo._2_2_1_combinacion_utilizadas_Distancia_Modo_tc_0 -- Lineas Más Utilizadas ParOD y Modo
		FROM (
			SELECT 
				Distancia, ModoMultimodal,NombreCombinacion,
				SUM(CantidadRepeticiones) AS CantidadRepeticiones,
				SUM(SumaViajes) AS SumaViajes, -- Primero calculo la suma de etapas por par OD
				ROW_NUMBER() OVER (PARTITION BY Distancia, ModoMultimodal ORDER BY SUM(SumaViajes) DESC) AS NroFila -- Rankeo
			FROM '+QUOTENAME(@Database)+'.dbo._2_2_base_combinaciones_por_linea_porParOD_TC_0
			GROUP BY
				Distancia, ModoMultimodal, NombreCombinacion
		) AS Subquery';
		SET @sql = @sql + '
			OUTER APPLY (
				-- Dividir NombreCombinacion en la primera parte
				SELECT 
					value AS NombreCombinacion_Part1
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED -- Parte 1
			OUTER APPLY (
				-- Dividir NombreCombinacion en la segunda parte
				SELECT 
					value AS NombreCombinacion_Part2
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED2 -- Parte 2
			OUTER APPLY (
				-- Dividir NombreCombinacion en la tercera parte
				SELECT 
					value AS NombreCombinacion_Part3
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED3 -- Parte 3
			OUTER APPLY (
				-- Dividir NombreCombinacion en la cuarta parte
				SELECT 
					value AS NombreCombinacion_Part4
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 3 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED4 -- Parte 4';
		SET @sql = @sql + '
		OUTER APPLY (
			-- Dividir NombreCombinacion en la quinta parte
			SELECT 
				value AS NombreCombinacion_Part5
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 4 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED5 -- Parte 5
		OUTER APPLY (
			-- Dividir NombreCombinacion en la sexta parte
			SELECT 
				value AS NombreCombinacion_Part6
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 5 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED6 -- Parte 6
		OUTER APPLY (
			-- Dividir NombreCombinacion en la séptima parte
			SELECT 
				value AS NombreCombinacion_Part7
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 6 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED7 -- Parte 7
		OUTER APPLY (
			-- Dividir NombreCombinacion en la octava parte
			SELECT 
				value AS NombreCombinacion_Part8
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 7 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED8 -- Parte 8
		OUTER APPLY (
			-- Dividir NombreCombinacion en la novena parte
			SELECT 
				value AS NombreCombinacion_Part9
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 8 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED9 -- Parte 9
		WHERE NroFila <= 10
		GROUP BY 
			Distancia, ModoMultimodal, NombreCombinacion,
			PARTITIONED.NombreCombinacion_Part1,
			PARTITIONED2.NombreCombinacion_Part2,
			PARTITIONED3.NombreCombinacion_Part3,
			PARTITIONED4.NombreCombinacion_Part4,
			PARTITIONED5.NombreCombinacion_Part5,
			PARTITIONED6.NombreCombinacion_Part6,
			PARTITIONED7.NombreCombinacion_Part7,
			PARTITIONED8.NombreCombinacion_Part8,
			PARTITIONED9.NombreCombinacion_Part9;';
		EXEC sp_executesql @sql;

		-- 26. Combinacion de viaje por Distancia, Modo y Horario | _2_2_1_combinacion_utilizadas_Distancia_Modo_Horario_tc_0
		SET @sql =
			'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_1_combinacion_utilizadas_Distancia_Modo_Horario_tc_0;
			SELECT 
				Distancia, pico_horario, ModoMultimodal,NombreCombinacion,
				SUM(CantidadRepeticiones) AS CantidadRepeticiones,
				SUM(SumaViajes) AS TotalViajes,
				ROW_NUMBER() OVER (PARTITION BY Distancia, pico_horario, ModoMultimodal ORDER BY SUM(SumaViajes) DESC) AS NroFila,
				PARTITIONED.NombreCombinacion_Part1 AS Etapa1,
				PARTITIONED2.NombreCombinacion_Part2 AS Etapa2,
				PARTITIONED3.NombreCombinacion_Part3 AS Etapa3,
				PARTITIONED4.NombreCombinacion_Part4 AS Etapa4,
				PARTITIONED5.NombreCombinacion_Part5 AS Etapa5,
				PARTITIONED6.NombreCombinacion_Part6 AS Etapa6,
				PARTITIONED7.NombreCombinacion_Part7 AS Etapa7,
				PARTITIONED8.NombreCombinacion_Part8 AS Etapa8,
				PARTITIONED9.NombreCombinacion_Part9 AS Etapa9
			INTO '+QUOTENAME(@Database)+'.dbo._2_2_1_combinacion_utilizadas_Distancia_Modo_Horario_tc_0 -- Lineas Más Utilizadas ParOD y Modo
			FROM (
				SELECT 
					Distancia,pico_horario, ModoMultimodal,NombreCombinacion,
					SUM(CantidadRepeticiones) AS CantidadRepeticiones,
					SUM(SumaViajes) AS SumaViajes, -- Primero calculo la suma de etapas por par OD
					ROW_NUMBER() OVER (PARTITION BY Distancia, pico_horario, ModoMultimodal ORDER BY SUM(SumaViajes) DESC) AS NroFila -- Rankeo
				FROM '+QUOTENAME(@Database)+'.dbo._2_2_base_combinaciones_por_linea_porParOD_TC_0
				WHERE TieneCombinacion = 0
				GROUP BY
					Distancia, pico_horario, ModoMultimodal, NombreCombinacion
			) AS Subquery';
		SET @sql = @sql + '
		OUTER APPLY (
			-- Dividir NombreCombinacion en la primera parte
			SELECT 
				value AS NombreCombinacion_Part1
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED -- Parte 1
		OUTER APPLY (
			-- Dividir NombreCombinacion en la segunda parte
			SELECT 
				value AS NombreCombinacion_Part2
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED2 -- Parte 2
		OUTER APPLY (
			-- Dividir NombreCombinacion en la tercera parte
			SELECT 
				value AS NombreCombinacion_Part3
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED3 -- Parte 3
		OUTER APPLY (
			-- Dividir NombreCombinacion en la cuarta parte
			SELECT 
				value AS NombreCombinacion_Part4
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 3 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED4 -- Parte 4';
		SET @sql = @sql + '
		OUTER APPLY (
			-- Dividir NombreCombinacion en la quinta parte
			SELECT 
				value AS NombreCombinacion_Part5
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 4 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED5 -- Parte 5
		OUTER APPLY (
			-- Dividir NombreCombinacion en la sexta parte
			SELECT 
				value AS NombreCombinacion_Part6
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 5 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED6 -- Parte 6
		OUTER APPLY (
			-- Dividir NombreCombinacion en la séptima parte
			SELECT 
				value AS NombreCombinacion_Part7
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 6 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED7 -- Parte 7
		OUTER APPLY (
			-- Dividir NombreCombinacion en la octava parte
			SELECT 
				value AS NombreCombinacion_Part8
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 7 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED8 -- Parte 8
		OUTER APPLY (
			-- Dividir NombreCombinacion en la novena parte
			SELECT 
				value AS NombreCombinacion_Part9
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 8 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED9 -- Parte 9
		WHERE NroFila <= 10
		GROUP BY 
			Distancia, pico_horario, ModoMultimodal, NombreCombinacion,
			PARTITIONED.NombreCombinacion_Part1,
			PARTITIONED2.NombreCombinacion_Part2,
			PARTITIONED3.NombreCombinacion_Part3,
			PARTITIONED4.NombreCombinacion_Part4,
			PARTITIONED5.NombreCombinacion_Part5,
			PARTITIONED6.NombreCombinacion_Part6,
			PARTITIONED7.NombreCombinacion_Part7,
			PARTITIONED8.NombreCombinacion_Part8,
			PARTITIONED9.NombreCombinacion_Part9;';
		EXEC sp_executesql @sql;
		
		-- 27. Linea mas utilizada por ModoMultimodal | _2_2_2_top_linea_mas_utilizadas_ModoMultimodal_tc_0
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_2_top_por_linea_por_ModoMultimodal_tc_0;
		SELECT 
			ModoMultimodal, id_linea, nombre_linea, empresa, CantidadEtapas,
			ROW_NUMBER() OVER (PARTITION BY ModoMultimodal ORDER BY CantidadEtapas DESC) AS NroFila
		INTO '+QUOTENAME(@Database)+'.dbo._2_2_2_top_linea_mas_utilizadas_ModoMultimodal_tc_0 
		FROM (
			SELECT 
				ModoMultimodal, id_linea, nombre_linea, empresa,
				SUM(CantidadEtapas) AS CantidadEtapas,
				ROW_NUMBER() OVER (PARTITION BY ModoMultimodal ORDER BY SUM(CantidadEtapas) DESC) AS NroFila
			FROM '+QUOTENAME(@Database)+'.dbo._2_base_viajes_top_lineas 
			WHERE TieneCombinacion = 0
			GROUP BY
				ModoMultimodal, id_linea, nombre_linea, empresa
		) AS Subquery
		WHERE NroFila <= 10;';
		EXEC sp_executesql @sql;
				
		-- 28. Linea mas utilizada por Distancia | _2_2_2_top_linea_mas_utilizadas_Distancia_tc_0
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_2_top_linea_mas_utilizadas_Distancia_tc_0;
		SELECT 
			distancia, id_linea, nombre_linea, empresa, CantidadEtapas,
			ROW_NUMBER() OVER (PARTITION BY distancia ORDER BY CantidadEtapas DESC) AS NroFila -- Rankeo
		INTO '+QUOTENAME(@Database)+'.dbo._2_top_linea_mas_utilizadas_Distancia_tc_0
		FROM (
			SELECT 
				distancia, id_linea, nombre_linea, empresa,
				SUM(CantidadEtapas) AS CantidadEtapas,
				ROW_NUMBER() OVER (PARTITION BY distancia ORDER BY SUM(CantidadEtapas) DESC) AS NroFila -- Rankeo
			FROM '+QUOTENAME(@Database)+'.dbo._2_base_viajes_top_lineas 
			WHERE TieneCombinacion = 0
			GROUP BY
				distancia, id_linea, nombre_linea, empresa
		) AS Subquery
		WHERE NroFila <= 10;';
		EXEC sp_executesql @sql;

		-- 29. Linea mas utilizada por Pico Horario | _2_2_2_top_linea_mas_utilizadas_pico_horario_tc_0
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_2_top_linea_mas_utilizadas_pico_horario_tc_0;
		SELECT 
			pico_horario, id_linea, nombre_linea, empresa, CantidadEtapas,
			ROW_NUMBER() OVER (PARTITION BY pico_horario ORDER BY CantidadEtapas DESC) AS NroFila
		INTO '+QUOTENAME(@Database)+'.dbo._2_2_2_top_linea_mas_utilizadas_horario_tc_0
		FROM (
			SELECT 
				pico_horario, id_linea, nombre_linea, empresa,
				SUM(CantidadEtapas) AS CantidadEtapas,
				ROW_NUMBER() OVER (PARTITION BY pico_horario ORDER BY SUM(CantidadEtapas) DESC) AS NroFila
			FROM '+QUOTENAME(@Database)+'.dbo._2_base_viajes_top_lineas 
			WHERE TieneCombinacion = 0
			GROUP BY
				pico_horario,id_linea, nombre_linea, empresa
		) AS Subquery
		WHERE NroFila <= 10;';
		EXEC sp_executesql @sql;
		
		-- 30. Linea mas utilizada por Hora | _2_2_2_top_linea_mas_utilizadas_hora_tc_0
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_2_top_linea_mas_utilizadas_hora_tc_0;
		SELECT 
			hora, id_linea, nombre_linea, empresa, CantidadEtapas,
			ROW_NUMBER() OVER (PARTITION BY hora ORDER BY CantidadEtapas DESC) AS NroFila
		INTO '+QUOTENAME(@Database)+'.dbo._2_2_2_top_linea_mas_utilizadas_hora_tc_0
		FROM (
			SELECT 
				hora, id_linea, nombre_linea, empresa,
				SUM(CantidadEtapas) AS CantidadEtapas,
				ROW_NUMBER() OVER (PARTITION BY hora ORDER BY SUM(CantidadEtapas) DESC) AS NroFila
			FROM '+QUOTENAME(@Database)+'.dbo._2_base_viajes_top_lineas 
			WHERE TieneCombinacion = 0
			GROUP BY
				hora, id_linea, nombre_linea, empresa
		) AS Subquery
		WHERE NroFila <= 10;';
		EXEC sp_executesql @sql; 

		-- 31. Linea mas utilizada por Distancia Horario | _2_2_2_top_linea_mas_utilizadas_Distancia_horario_tc_0
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_2_top_linea_mas_utilizadas_Distancia_horario_tc_0;
		SELECT 
			distancia, pico_horario, id_linea, nombre_linea, empresa, CantidadEtapas,
			ROW_NUMBER() OVER (PARTITION BY distancia, pico_horario ORDER BY CantidadEtapas DESC) AS NroFila -- Rankeo
		INTO '+QUOTENAME(@Database)+'.dbo._2_2_2_top_linea_mas_utilizadas_Distancia_horario_tc_0
		FROM (
			SELECT 
				distancia, pico_horario, id_linea, nombre_linea, empresa,
				SUM(CantidadEtapas) AS CantidadEtapas, 
				ROW_NUMBER() OVER (PARTITION BY distancia, pico_horario ORDER BY SUM(CantidadEtapas) DESC) AS NroFila
			FROM '+QUOTENAME(@Database)+'.dbo._2_base_viajes_top_lineas 
			WHERE TieneCombinacion = 0
			GROUP BY
				distancia, pico_horario, id_linea, nombre_linea, empresa
		) AS Subquery
		WHERE NroFila <= 10;';
		EXEC sp_executesql @sql; 

		-- 32. Linea mas utilizada por ModoMultimodal y PicoHorario | _2_2_2_top_linea_mas_utilizadas_ModoMultimodal_PicoHorario_tc_0
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_2_top_linea_mas_utilizadas_ModoMultimodal_PicoHorario_tc_0;
		SELECT 
			ModoMultimodal, pico_horario, id_linea, nombre_linea, empresa, CantidadEtapas,
			ROW_NUMBER() OVER (PARTITION BY ModoMultimodal, pico_horario ORDER BY CantidadEtapas DESC) AS NroFila -- Rankeo
		INTO '+QUOTENAME(@Database)+'.dbo._2_2_2_top_linea_mas_utilizadas_ModoMultimodal_PicoHorario_tc_0
		FROM (
			SELECT 
				ModoMultimodal, pico_horario, id_linea, nombre_linea, empresa,
				SUM(CantidadEtapas) AS CantidadEtapas, 
				ROW_NUMBER() OVER (PARTITION BY ModoMultimodal, pico_horario ORDER BY SUM(CantidadEtapas) DESC) AS NroFila
			FROM '+QUOTENAME(@Database)+'.dbo._2_base_viajes_top_lineas 
			WHERE TieneCombinacion = 0
			GROUP BY
				ModoMultimodal, pico_horario, id_linea, nombre_linea, empresa
		) AS Subquery
		WHERE NroFila <= 10;';
		EXEC sp_executesql @sql; 

		-- 33. Linea mas utilizada por ModoMultimodal y Distancia | _2_2_2_top_linea_mas_utilizadas_ModoMultimodal_Distancia_tc_0
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_2_top_linea_mas_utilizadas_ModoMultimodal_Distancia_tc_0;
		SELECT 
			ModoMultimodal, distancia, id_linea, nombre_linea, empresa, CantidadEtapas,
			ROW_NUMBER() OVER (PARTITION BY ModoMultimodal, distancia ORDER BY CantidadEtapas DESC) AS NroFila -- Rankeo
		INTO '+QUOTENAME(@Database)+'.dbo._2_2_2_top_linea_mas_utilizadas_ModoMultimodal_Distancia_tc_0
		FROM (
			SELECT 
				ModoMultimodal, distancia, id_linea, nombre_linea, empresa,
				SUM(CantidadEtapas) AS CantidadEtapas, 
				ROW_NUMBER() OVER (PARTITION BY ModoMultimodal, distancia ORDER BY SUM(CantidadEtapas) DESC) AS NroFila
			FROM '+QUOTENAME(@Database)+'.dbo._2_base_viajes_top_lineas 
			WHERE TieneCombinacion = 0
			GROUP BY
				ModoMultimodal, distancia, id_linea, nombre_linea, empresa
		) AS Subquery
		WHERE NroFila <= 10;';
		EXEC sp_executesql @sql; 

-- Confirmar transacción
 COMMIT TRANSACTION;

 END TRY
 BEGIN CATCH
 -- Si ocurre un error, revertir la transacción
 ROLLBACK TRANSACTION;
	PRINT 'Error en la transacción: '+ERROR_MESSAGE();
 	PRINT 'Error en la transacción: ' + ERROR_MESSAGE();
    PRINT 'Número de error: ' + CAST(ERROR_NUMBER() AS NVARCHAR(10);
    PRINT 'Procedimiento: ' + ERROR_PROCEDURE();
    PRINT 'Línea: ' + CAST(ERROR_LINE() AS NVARCHAR(10);
 END CATCH;
END;


CREATE PROCEDURE _005_2_Estadisticas_Viajes_Propios_en_el_Corredor
 @Database NVARCHAR(15), -- Parámetro de entrada para la base de datos
 @IdLinea NVARCHAR(50),
 @BasePares NVARCHAR(20) -- Nombre de la base de pares a crear
AS
BEGIN
	DECLARE @sql NVARCHAR(MAX);
 BEGIN TRY
 -- Inicia la transacción
 BEGIN TRANSACTION;

		-- 1. Base de viajes alternativos | _2_2_base_viajes_tc_1
		SET @sql =
		'SELECT * 
		INTO '+QUOTENAME(@database)+'.dbo._2_2_base_viajes_tc_1
		FROM '+QUOTENAME(@database)+'.[dbo]._2_base_viajes v
		WHERE v.TieneCombinacion = 1';
		EXEC sp_executesql @sql;

		-- 2. Calculo agrupado de viajes por ParOD | _2_2_agrupado_ParOD_tc_1
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@database)+'.dbo._2_2_agrupado_ParOD_tc_1;
		SELECT 
			v.ParOD, v.distancia,
			v.IdO, v.IdD,
			v.z_origen,v.z_destino,
			-- COLECTIVO
			SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVO'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivo_tc_1,
			-- COLECTIVOx2
			SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVOx2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivox2_tc_1,
			-- COLECTIVOx3
			SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVOx3'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivox3_tc_1,
			-- COLECTIVO+4
			SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVO+4'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivoMas4_tc_1,
			-- SUBTE
			SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_subte_tc_1,
			-- SUBTEx2
			SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTEX2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_subtex2_tc_1,
			-- SUBTEx3
			SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTEx3'' THEN v.ViajesExpandidos ELSE 0 END) AS v_subtex3_tc_1,
			-- SUBTE+4
			SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTE+4'' THEN v.ViajesExpandidos ELSE 0 END) AS v_subteMas4_tc_1,
			-- TREN
			SUM(CASE WHEN v.ModoMultimodal = ''C-TREN'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_tc_1,
			-- TRENx2
			SUM(CASE WHEN v.ModoMultimodal = ''C-TRENx2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_trenx2_tc_1,
			-- TREN+3
			SUM(CASE WHEN v.ModoMultimodal = ''C-TREN+3'' THEN v.ViajesExpandidos ELSE 0 END) AS v_trenMas3_tc_1,
			-- COLECTIVO-SUBTE
			SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivo_subte_tc_1,
			-- COLECTIVO+2-SUBTE
			SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO+2-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivoMas2_subte_tc_1,
			-- COLECTIVO-SUBTE+2
			SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO-SUBTE+2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivo_subteMas2_tc_1,
			-- COLECTIVO+2-SUBTE+2
			SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO+2-SUBTE+2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivoMas2_subteMas2_tc_1,
			-- TREN-COLECTIVO
			SUM(CASE WHEN v.ModoMultimodal = ''E-TREN-COLECTIVO'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_colectivo_tc_1,
			-- TREN+2-COLECTIVO
			SUM(CASE WHEN v.ModoMultimodal = ''E-TREN+2-COLECTIVO'' THEN v.ViajesExpandidos ELSE 0 END) AS v_treMas2_colectivo_tc_1,
			-- TREN-COLECTIVO+2
			SUM(CASE WHEN v.ModoMultimodal = ''E-TREN-COLECTIVO+2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_colectivoMas2_tc_1,
			-- TREN-SUBTE
			SUM(CASE WHEN v.ModoMultimodal = ''F-TREN-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_subte_tc_1,
			-- TREN-COLECTIVO-SUBTE
			SUM(CASE WHEN v.ModoMultimodal = ''G-TREN-COLECTIVO-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_colectivo_subte_tc_1,
			-- Totales generales';
		SET @sql = @sql + '
			SUM(v.ViajesExpandidos) AS v_totales_tc_1,
			COUNT(DISTINCT v.id_tarjeta) AS TarjetasUnicas,
			SUM(CAST(v.tren AS INT) AS tren,
			SUM(CAST(v.autobus AS INT) AS autobus,
			SUM(CAST(v.metro AS INT) AS metro,
			SUM(CAST(v.cant_etapas AS INT) AS SumaEtapas,
			AVG(CAST(v.cant_etapas AS INT) AS PromedioEtapas,
			AVG(CAST(v.distance_h3 AS FLOAT) AS Promediodistance_h3,
			AVG(CAST(v.distance_osm_drive AS FLOAT)) AS Promediodistance_osm_drive
		INTO '+QUOTENAME(@database)+'.dbo._2_2_agrupado_ParOD_tc_1
		FROM '+QUOTENAME(@database)+'.[dbo]._2_2_base_viajes_tc_1 v
		GROUP BY
			v.ParOD, v.IdO, v.IdD, v.z_origen,v.z_destino
		ORDER BY
			v.ParOD;';
		EXEC sp_executesql @sql;

		-- 3. Calculo agrupado de viajes por ParOD y horario | _2_2_agrupado_ParOD_horario_tc_1
		SET @sql =
			'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_agrupado_ParOD_horario_tc_1;
			SELECT 
				v.ParOD, v.distancia,
				v.IdO, v.IdD,
				v.z_origen,v.z_destino,
				v.hora, v.pico_horario,
				-- COLECTIVO
				SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVO'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivo_tc_1,
				-- COLECTIVOx2
				SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVOx2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivox2_tc_1,
				-- COLECTIVOx3
				SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVOx3'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivox3_tc_1,
				-- COLECTIVO+4
				SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVO+4'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivoMas4_tc_1,
				-- SUBTE
				SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_subte_tc_1,
				-- SUBTEx2
				SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTEX2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_subtex2_tc_1,
				-- SUBTEx3
				SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTEx3'' THEN v.ViajesExpandidos ELSE 0 END) AS v_subtex3_tc_1,
				-- SUBTE+4
				SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTE+4'' THEN v.ViajesExpandidos ELSE 0 END) AS v_subteMas4_tc_1,
				-- TREN
				SUM(CASE WHEN v.ModoMultimodal = ''C-TREN'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_tc_1,
				-- TRENx2
				SUM(CASE WHEN v.ModoMultimodal = ''C-TRENx2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_trenx2_tc_1,
				-- TREN+3
				SUM(CASE WHEN v.ModoMultimodal = ''C-TREN+3'' THEN v.ViajesExpandidos ELSE 0 END) AS v_trenMas3_tc_1,
				-- COLECTIVO-SUBTE
				SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivo_subte_tc_1,
				-- COLECTIVO+2-SUBTE
				SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO+2-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivoMas2_subte_tc_1,
				-- COLECTIVO-SUBTE+2
				SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO-SUBTE+2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivo_subteMas2_tc_1,
				-- COLECTIVO+2-SUBTE+2
				SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO+2-SUBTE+2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivoMas2_subteMas2_tc_1,
				-- TREN-COLECTIVO
				SUM(CASE WHEN v.ModoMultimodal = ''E-TREN-COLECTIVO'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_colectivo_tc_1,';
		SET @sql = @sql + '
			-- TREN+2-COLECTIVO
			SUM(CASE WHEN v.ModoMultimodal = ''E-TREN+2-COLECTIVO'' THEN v.ViajesExpandidos ELSE 0 END) AS v_treMas2_colectivo_tc_1,
			-- TREN-COLECTIVO+2
			SUM(CASE WHEN v.ModoMultimodal = ''E-TREN-COLECTIVO+2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_colectivoMas2_tc_1,
			-- TREN-SUBTE
			SUM(CASE WHEN v.ModoMultimodal = ''F-TREN-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_subte_tc_1,
			-- TREN-COLECTIVO-SUBTE
			SUM(CASE WHEN v.ModoMultimodal = ''G-TREN-COLECTIVO-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_colectivo_subte_tc_1,
			-- Totales generales
			SUM(v.ViajesExpandidos) AS v_totales_tc_1,
			COUNT(DISTINCT v.id_tarjeta) AS TarjetasUnicas,
			SUM(CAST(v.tren AS INT) AS tren,
			SUM(CAST(v.autobus AS INT) AS autobus,
			SUM(CAST(v.metro AS INT) AS metro,
			SUM(CAST(v.cant_etapas AS INT) AS SumaEtapas,
			AVG(CAST(v.cant_etapas AS INT) AS PromedioEtapas,
			AVG(CAST(v.distance_h3 AS FLOAT) AS Promediodistance_h3,
			AVG(CAST(v.distance_osm_drive AS FLOAT)) AS Promediodistance_osm_drive
		INTO '+QUOTENAME(@Database)+'.[dbo]._2_2_agrupado_ParOD_horario_tc_1
		FROM '+QUOTENAME(@database)+'.[dbo]._2_2_base_viajes_tc_1 v
		GROUP BY
			v.ParOD, v.distancia,
			v.IdO, v.IdD,
			v.hora,v.pico_horario,
			v.z_origen,v.z_destino
		ORDER BY
			v.ParOD;';
		EXEC sp_executesql @sql;

		-- 4. Calculo agrupado de viajes por Distancia | _2_2_agrupado_distancia_tc_1
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_agrupado_distancia_tc_1;
		SELECT 
			v.distancia,
			-- COLECTIVO
			SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVO'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivo_tc_1,
			-- COLECTIVOx2
			SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVOx2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivox2_tc_1,
			-- COLECTIVOx3
			SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVOx3'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivox3_tc_1,
			-- COLECTIVO+4
			SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVO+4'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivoMas4_tc_1,
			-- SUBTE
			SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_subte_tc_1,
			-- SUBTEx2
			SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTEX2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_subtex2_tc_1,
			-- SUBTEx3
			SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTEx3'' THEN v.ViajesExpandidos ELSE 0 END) AS v_subtex3_tc_1,
			-- SUBTE+4
			SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTE+4'' THEN v.ViajesExpandidos ELSE 0 END) AS v_subteMas4_tc_1,
			-- TREN
			SUM(CASE WHEN v.ModoMultimodal = ''C-TREN'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_tc_1,
			-- TRENx2
			SUM(CASE WHEN v.ModoMultimodal = ''C-TRENx2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_trenx2_tc_1,
			-- TREN+3
			SUM(CASE WHEN v.ModoMultimodal = ''C-TREN+3'' THEN v.ViajesExpandidos ELSE 0 END) AS v_trenMas3_tc_1,
			-- COLECTIVO-SUBTE
			SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivo_subte_tc_1,
			-- COLECTIVO+2-SUBTE
			SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO+2-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivoMas2_subte_tc_1,
			-- COLECTIVO-SUBTE+2
			SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO-SUBTE+2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivo_subteMas2_tc_1,
			-- COLECTIVO+2-SUBTE+2
			SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO+2-SUBTE+2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivoMas2_subteMas2_tc_1,
			-- TREN-COLECTIVO
			SUM(CASE WHEN v.ModoMultimodal = ''E-TREN-COLECTIVO'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_colectivo_tc_1,
			-- TREN+2-COLECTIVO
			SUM(CASE WHEN v.ModoMultimodal = ''E-TREN+2-COLECTIVO'' THEN v.ViajesExpandidos ELSE 0 END) AS v_treMas2_colectivo_tc_1,
			-- TREN-COLECTIVO+2
			SUM(CASE WHEN v.ModoMultimodal = ''E-TREN-COLECTIVO+2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_colectivoMas2_tc_1,
			-- TREN-SUBTE
			SUM(CASE WHEN v.ModoMultimodal = ''F-TREN-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_subte_tc_1,
			-- TREN-COLECTIVO-SUBTE
			SUM(CASE WHEN v.ModoMultimodal = ''G-TREN-COLECTIVO-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_colectivo_subte_tc_1,
			-- Totales generales
			SUM(v.ViajesExpandidos) AS v_totales_tc_1,
			COUNT(DISTINCT v.id_tarjeta) AS TarjetasUnicas,
			SUM(CAST(v.tren AS INT) AS tren,
			SUM(CAST(v.autobus AS INT) AS autobus,
			SUM(CAST(v.metro AS INT) AS metro,
			SUM(CAST(v.cant_etapas AS INT) AS SumaEtapas,
			AVG(CAST(v.cant_etapas AS INT) AS PromedioEtapas,
			AVG(CAST(v.distance_h3 AS FLOAT) AS Promediodistance_h3,
			AVG(CAST(v.distance_osm_drive AS FLOAT)) AS Promediodistance_osm_drive
		INTO '+QUOTENAME(@Database)+'.dbo._2_2_agrupado_distancia_tc_1
		FROM '+QUOTENAME(@database)+'.[dbo]._2_2_base_viajes_tc_1 v
		GROUP BY
		 v.distancia
		ORDER BY
			v.distancia;';
		EXEC sp_executesql @sql;

		-- 5. Calculo agrupado de viajes por Hora | _2_2_agrupado_hora_tc_1
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_agrupado_hora_tc_1;
		SELECT 
			v.hora,
			-- COLECTIVO
			SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVO'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivo_tc_1,
			-- COLECTIVOx2
			SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVOx2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivox2_tc_1,
			-- COLECTIVOx3
			SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVOx3'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivox3_tc_1,
			-- COLECTIVO+4
			SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVO+4'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivoMas4_tc_1,
			-- SUBTE
			SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_subte_tc_1,
			-- SUBTEx2
			SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTEX2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_subtex2_tc_1,
			-- SUBTEx3
			SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTEx3'' THEN v.ViajesExpandidos ELSE 0 END) AS v_subtex3_tc_1,
			-- SUBTE+4
			SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTE+4'' THEN v.ViajesExpandidos ELSE 0 END) AS v_subteMas4_tc_1,
			-- TREN
			SUM(CASE WHEN v.ModoMultimodal = ''C-TREN'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_tc_1,
			-- TRENx2
			SUM(CASE WHEN v.ModoMultimodal = ''C-TRENx2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_trenx2_tc_1,
			-- TREN+3
			SUM(CASE WHEN v.ModoMultimodal = ''C-TREN+3'' THEN v.ViajesExpandidos ELSE 0 END) AS v_trenMas3_tc_1,
			-- COLECTIVO-SUBTE
			SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivo_subte_tc_1,
			-- COLECTIVO+2-SUBTE
			SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO+2-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivoMas2_subte_tc_1,
			-- COLECTIVO-SUBTE+2
			SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO-SUBTE+2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivo_subteMas2_tc_1,
			-- COLECTIVO+2-SUBTE+2
			SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO+2-SUBTE+2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivoMas2_subteMas2_tc_1,
			-- TREN-COLECTIVO
			SUM(CASE WHEN v.ModoMultimodal = ''E-TREN-COLECTIVO'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_colectivo_tc_1,
			-- TREN+2-COLECTIVO
			SUM(CASE WHEN v.ModoMultimodal = ''E-TREN+2-COLECTIVO'' THEN v.ViajesExpandidos ELSE 0 END) AS v_treMas2_colectivo_tc_1,
			-- TREN-COLECTIVO+2
			SUM(CASE WHEN v.ModoMultimodal = ''E-TREN-COLECTIVO+2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_colectivoMas2_tc_1,
			-- TREN-SUBTE
			SUM(CASE WHEN v.ModoMultimodal = ''F-TREN-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_subte_tc_1,
			-- TREN-COLECTIVO-SUBTE
			SUM(CASE WHEN v.ModoMultimodal = ''G-TREN-COLECTIVO-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_colectivo_subte_tc_1,
			-- Totales generales
			SUM(v.ViajesExpandidos) AS v_totales_tc_1,
			COUNT(DISTINCT v.id_tarjeta) AS TarjetasUnicas,
			SUM(CAST(v.tren AS INT) AS tren,
			SUM(CAST(v.autobus AS INT) AS autobus,
			SUM(CAST(v.metro AS INT) AS metro,
			SUM(CAST(v.cant_etapas AS INT) AS SumaEtapas,
			AVG(CAST(v.cant_etapas AS INT) AS PromedioEtapas,
			AVG(CAST(v.distance_h3 AS FLOAT) AS Promediodistance_h3,
			AVG(CAST(v.distance_osm_drive AS FLOAT)) AS Promediodistance_osm_drive
		INTO '+QUOTENAME(@Database)+'.dbo._2_2_agrupado_hora_tc_1
		FROM '+QUOTENAME(@database)+'.[dbo]._2_2_base_viajes_tc_1 v
		GROUP BY
		 v.hora
		ORDER BY
			v.hora;';
		EXEC sp_executesql @sql;

		-- 6. Calculo agrupado de viajes por Pico Horario | _2_2_agrupado_Pico_Horario_tc_1
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_agrupado_Pico_Horario_tc_1;
		SELECT 
			v.pico_horario,
			-- COLECTIVO
			SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVO'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivo_tc_1,
			-- COLECTIVOx2
			SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVOx2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivox2_tc_1,
			-- COLECTIVOx3
			SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVOx3'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivox3_tc_1,
			-- COLECTIVO+4
			SUM(CASE WHEN v.ModoMultimodal = ''A-COLECTIVO+4'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivoMas4_tc_1,
			-- SUBTE
			SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_subte_tc_1,
			-- SUBTEx2
			SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTEX2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_subtex2_tc_1,
			-- SUBTEx3
			SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTEx3'' THEN v.ViajesExpandidos ELSE 0 END) AS v_subtex3_tc_1,
			-- SUBTE+4
			SUM(CASE WHEN v.ModoMultimodal = ''B-SUBTE+4'' THEN v.ViajesExpandidos ELSE 0 END) AS v_subteMas4_tc_1,
			-- TREN
			SUM(CASE WHEN v.ModoMultimodal = ''C-TREN'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_tc_1,
			-- TRENx2
			SUM(CASE WHEN v.ModoMultimodal = ''C-TRENx2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_trenx2_tc_1,
			-- TREN+3
			SUM(CASE WHEN v.ModoMultimodal = ''C-TREN+3'' THEN v.ViajesExpandidos ELSE 0 END) AS v_trenMas3_tc_1,
			-- COLECTIVO-SUBTE
			SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivo_subte_tc_1,
			-- COLECTIVO+2-SUBTE
			SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO+2-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivoMas2_subte_tc_1,
			-- COLECTIVO-SUBTE+2
			SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO-SUBTE+2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivo_subteMas2_tc_1,
			-- COLECTIVO+2-SUBTE+2
			SUM(CASE WHEN v.ModoMultimodal = ''D-COLECTIVO+2-SUBTE+2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_colectivoMas2_subteMas2_tc_1,
			-- TREN-COLECTIVO
			SUM(CASE WHEN v.ModoMultimodal = ''E-TREN-COLECTIVO'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_colectivo_tc_1,
			-- TREN+2-COLECTIVO
			SUM(CASE WHEN v.ModoMultimodal = ''E-TREN+2-COLECTIVO'' THEN v.ViajesExpandidos ELSE 0 END) AS v_treMas2_colectivo_tc_1,
			-- TREN-COLECTIVO+2
			SUM(CASE WHEN v.ModoMultimodal = ''E-TREN-COLECTIVO+2'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_colectivoMas2_tc_1,
			-- TREN-SUBTE
			SUM(CASE WHEN v.ModoMultimodal = ''F-TREN-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_subte_tc_1,
			-- TREN-COLECTIVO-SUBTE
			SUM(CASE WHEN v.ModoMultimodal = ''G-TREN-COLECTIVO-SUBTE'' THEN v.ViajesExpandidos ELSE 0 END) AS v_tren_colectivo_subte_tc_1,
			-- Totales generales
			SUM(v.ViajesExpandidos) AS v_totales_tc_1,
			COUNT(DISTINCT v.id_tarjeta) AS TarjetasUnicas,
			SUM(CAST(v.tren AS INT) AS tren,
			SUM(CAST(v.autobus AS INT) AS autobus,
			SUM(CAST(v.metro AS INT) AS metro,
			SUM(CAST(v.cant_etapas AS INT) AS SumaEtapas,
			AVG(CAST(v.cant_etapas AS INT) AS PromedioEtapas,
			AVG(CAST(v.distance_h3 AS FLOAT) AS Promediodistance_h3,
			AVG(CAST(v.distance_osm_drive AS FLOAT)) AS Promediodistance_osm_drive
		INTO '+QUOTENAME(@Database)+'.dbo._2_2_agrupado_Pico_Horario_tc_1
		FROM '+QUOTENAME(@database)+'.[dbo]._2_2_base_viajes_tc_1 v
		GROUP BY
			v.pico_horario
		ORDER BY
			v.pico_horario;';
		EXEC sp_executesql @sql;

		-- 7. Calculo distribución de viajes por ModoMultimodal y Combinacion | _2_2_distribucion_MultiModal_ModoCombinacion_tc_1
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_distribucion_MultiModal_ModoCombinacion_tc_1;
		SELECT 
			v.ModoMultimodal, v.ModoCombinacion,v.TieneCombinacion,
			SUM(v.ViajesExpandidos) AS v_totales,
			CASE WHEN (SELECT SUM(v.ViajesExpandidos) FROM '+QUOTENAME(@database)+'.[dbo]._2_2_base_viajes_tc_1 v) > 0 
			 THEN SUM(v.ViajesExpandidos) / (SELECT SUM(v.ViajesExpandidos) FROM '+QUOTENAME(@database)+'.[dbo]._2_2_base_viajes_tc_1 v)
			 ELSE 0 
			END AS Porcentaje,
			COUNT(DISTINCT v.id_tarjeta) AS TarjetasUnicas,
			SUM(CAST(v.tren AS INT) AS tren,
			SUM(CAST(v.autobus AS INT) AS autobus,
			SUM(CAST(v.metro AS INT) AS metro,
			SUM(CAST(v.cant_etapas AS INT) AS SumaEtapas,
			AVG(CAST(v.cant_etapas AS INT) AS PromedioEtapas,
			AVG(CAST(v.distance_h3 AS FLOAT) AS PromedioDistance_h3,
			AVG(CAST(v.distance_osm_drive AS FLOAT)) AS PromedioDistance_osm_drive
		INTO '+QUOTENAME(@Database)+'.dbo._2_2_distribucion_MultiModal_ModoCombinacion_tc_1
		FROM '+QUOTENAME(@database)+'.[dbo]._2_2_base_viajes_tc_1 v
		WHERE v.TieneCombinacion = 0
		GROUP BY
			v.ModoMultimodal, v.ModoCombinacion,v.TieneCombinacion
		ORDER BY
			v.ModoMultimodal;';
		EXEC sp_executesql @sql;

		-- 8. Calculo distribución de viajes por Distancia y ModoMultimodal | _2_2_distribucion_distancia_MultiModal_tc_1
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_distribucion_distancia_MultiModal_tc_1;
		SELECT 
			v.distancia, v.ModoMultimodal,v.TieneCombinacion,
			SUM(v.ViajesExpandidos) AS v_totales,
			CASE WHEN (SELECT SUM(v.ViajesExpandidos) FROM '+QUOTENAME(@database)+'.[dbo]._2_2_base_viajes_tc_1 v) > 0 
			 THEN SUM(v.ViajesExpandidos) / (SELECT SUM(v.ViajesExpandidos) FROM '+QUOTENAME(@database)+'.[dbo]._2_2_base_viajes_tc_1 v)
			 ELSE 0 
			END AS Porcentaje,
			COUNT(DISTINCT v.id_tarjeta) AS TarjetasUnicas,
			SUM(CAST(v.tren AS INT) AS tren,
			SUM(CAST(v.autobus AS INT) AS autobus,
			SUM(CAST(v.metro AS INT) AS metro,
			SUM(CAST(v.cant_etapas AS INT) AS SumaEtapas,
			AVG(CAST(v.cant_etapas AS INT) AS PromedioEtapas,
			AVG(CAST(v.distance_h3 AS FLOAT) AS PromedioDistance_h3,
			AVG(CAST(v.distance_osm_drive AS FLOAT)) AS PromedioDistance_osm_drive
		INTO '+QUOTENAME(@Database)+'.dbo._2_2_distribucion_distancia_MultiModal_tc_1
		 FROM '+QUOTENAME(@database)+'.[dbo]._2_2_base_viajes_tc_1 v
		GROUP BY
			v.distancia, v.ModoMultimodal,v.TieneCombinacion
		ORDER BY
			v.distancia;';
		EXEC sp_executesql @sql;

		-- 9. Calculo distribución de viajes por ModoMultimodal, Combinacion y horario | _2_2_distribucion_distancia_ModoMultiModal_Combinacion_horario_tc_1
		SET @sql =
			'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_distribucion_distancia_ModoMultiModal_Combinacion_horario_tc_1;
			SELECT 
				v.ModoMultimodal,v.ModoCombinacion,v.pico_horario,v.TieneCombinacion,
				SUM(v.ViajesExpandidos) AS v_totales,
				CASE WHEN (SELECT SUM(v.ViajesExpandidos) FROM '+QUOTENAME(@database)+'.[dbo]._2_2_base_viajes_tc_1 v) > 0 
				 THEN SUM(v.ViajesExpandidos) / (SELECT SUM(v.ViajesExpandidos) FROM '+QUOTENAME(@database)+'.[dbo]._2_2_base_viajes_tc_1 v)
				 ELSE 0 
				END AS Porcentaje,
				COUNT(DISTINCT v.id_tarjeta) AS TarjetasUnicas,
				SUM(CAST(v.tren AS INT) AS tren,
				SUM(CAST(v.autobus AS INT) AS autobus,
				SUM(CAST(v.metro AS INT) AS metro,
				SUM(CAST(v.cant_etapas AS INT) AS SumaEtapas,
				AVG(CAST(v.cant_etapas AS INT) AS PromedioEtapas,
				AVG(CAST(v.distance_h3 AS FLOAT) AS PromedioDistance_h3,
				AVG(CAST(v.distance_osm_drive AS FLOAT)) AS PromedioDistance_osm_drive
			INTO '+QUOTENAME(@Database)+'.dbo._2_2_distribucion_distancia_ModoMultiModal_Combinacion_horario_tc_1
			 FROM '+QUOTENAME(@database)+'.[dbo]._2_2_base_viajes_tc_1 v
			GROUP BY
				v.ModoMultimodal,v.ModoCombinacion,v.pico_horario,v.TieneCombinacion
			ORDER BY
				v.ModoMultimodal,v.ModoCombinacion,v.pico_horario;';
		EXEC sp_executesql @sql;

		-- 10. Calculo distribución de viajes por ModoMultimodal, Combinacion, distancia y horario | _2_2_distribucion_distancia_ModoMultiModal_Combinacion_distancia_horario_0
		SET @sql =
			'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_distribucion_distancia_ModoMultiModal_Combinacion_distancia_horario_0;
			SELECT 
				v.ModoMultimodal,v.ModoCombinacion,v.distancia,v.pico_horario,v.TieneCombinacion,
				SUM(v.ViajesExpandidos) AS v_totales,
				CASE WHEN (SELECT SUM(v.ViajesExpandidos) FROM '+QUOTENAME(@database)+'.[dbo]._2_2_base_viajes_tc_1 v) > 0 
				 THEN SUM(v.ViajesExpandidos) / (SELECT SUM(v.ViajesExpandidos) FROM '+QUOTENAME(@database)+'.[dbo]._2_2_base_viajes_tc_1 v)
				 ELSE 0 
				END AS Porcentaje,
				COUNT(DISTINCT v.id_tarjeta) AS TarjetasUnicas,
				SUM(CAST(v.tren AS INT) AS tren,
				SUM(CAST(v.autobus AS INT) AS autobus,
				SUM(CAST(v.metro AS INT) AS metro,
				SUM(CAST(v.cant_etapas AS INT) AS SumaEtapas,
				AVG(CAST(v.cant_etapas AS INT) AS PromedioEtapas,
				AVG(CAST(v.distance_h3 AS FLOAT) AS PromedioDistance_h3,
				AVG(CAST(v.distance_osm_drive AS FLOAT)) AS PromedioDistance_osm_drive
			INTO '+QUOTENAME(@Database)+'.dbo._2_2_distribucion_distancia_ModoMultiModal_Combinacion_distancia_horario_0
			 FROM '+QUOTENAME(@database)+'.[dbo]._2_2_base_viajes_tc_1 v
			GROUP BY
				v.ModoMultimodal,v.ModoCombinacion,v.distancia,v.pico_horario,v.TieneCombinacion
			ORDER BY
				v.ModoMultimodal,v.ModoCombinacion,v.distancia,v.pico_horario;';
		EXEC sp_executesql @sql;

		-- 11. Calculo de distribución de viajes por Horario y distancia | _2_2_distribucion_horario_distancia_tc_1
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_distribucion_horario_distancia_tc_1;
		SELECT 
			v.pico_horario, v.distancia, v.TieneCombinacion,
			SUM(v.ViajesExpandidos) AS v_totales,
			CASE WHEN (SELECT SUM(v.ViajesExpandidos) FROM '+QUOTENAME(@database)+'.[dbo]._2_2_base_viajes_tc_1 v) > 0 
			 THEN SUM(v.ViajesExpandidos) / (SELECT SUM(v.ViajesExpandidos) FROM '+QUOTENAME(@database)+'.[dbo]._2_2_base_viajes_tc_1 v)
			 ELSE 0 
			END AS Porcentaje,
			COUNT(DISTINCT v.id_tarjeta) AS TarjetasUnicas,
			SUM(CAST(v.tren AS INT) AS tren,
			SUM(CAST(v.autobus AS INT) AS autobus,
			SUM(CAST(v.metro AS INT) AS metro,
			SUM(CAST(v.cant_etapas AS INT) AS SumaEtapas,
			AVG(CAST(v.cant_etapas AS INT) AS PromedioEtapas,
			AVG(CAST(v.distance_h3 AS FLOAT) AS PromedioDistance_h3,
			AVG(CAST(v.distance_osm_drive AS FLOAT)) AS PromedioDistance_osm_drive
		INTO '+QUOTENAME(@Database)+'.dbo._2_2_distribucion_horario_distancia_tc_1
		FROM '+QUOTENAME(@database)+'.[dbo]._2_2_base_viajes_tc_1 v
		GROUP BY
			v.pico_horario, v.distancia, v.TieneCombinacion
		ORDER BY
			v.pico_horario, v.distancia;';
		EXEC sp_executesql @sql;

		-- 12. Calculo de distribución de viajes por horario y modo de combinacion | _2_2_distribucion_horario_ModoCombinacion_tc_1
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_distribucion_horario_ModoCombinacion_tc_1;
		SELECT 
			v.pico_horario, v.ModoCombinacion, v.TieneCombinacion,
			SUM(v.ViajesExpandidos) AS v_totales,
			CASE WHEN (SELECT SUM(v.ViajesExpandidos) FROM '+QUOTENAME(@database)+'.[dbo]._2_2_base_viajes_tc_1 v) > 0 
			 THEN SUM(v.ViajesExpandidos) / (SELECT SUM(v.ViajesExpandidos) FROM '+QUOTENAME(@database)+'.[dbo]._2_2_base_viajes_tc_1 v)
			 ELSE 0 
			END AS Porcentaje,
			COUNT(DISTINCT v.id_tarjeta) AS TarjetasUnicas,
			SUM(CAST(v.tren AS INT) AS tren,
			SUM(CAST(v.autobus AS INT) AS autobus,
			SUM(CAST(v.metro AS INT) AS metro,
			SUM(CAST(v.cant_etapas AS INT) AS SumaEtapas,
			AVG(CAST(v.cant_etapas AS INT) AS PromedioEtapas,
			AVG(CAST(v.distance_h3 AS FLOAT) AS PromedioDistance_h3,
			AVG(CAST(v.distance_osm_drive AS FLOAT)) AS PromedioDistance_osm_drive
		INTO '+QUOTENAME(@Database)+'.dbo._2_2_distribucion_horario_ModoCombinacion_tc_1
		FROM '+QUOTENAME(@database)+'.[dbo]._2_2_base_viajes_tc_1 v
		GROUP BY
			v.pico_horario, v.ModoCombinacion, v.TieneCombinacion
		ORDER BY
			v.pico_horario, v.ModoCombinacion;';
		EXEC sp_executesql @sql;
		
		-- 13. Calculo de etapas de cada linea por ParOD y Modo Multimodal | _2_2_2_etapas_por_linea_porParOD_ModoMultimodal_tc_1
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_2_etapas_por_linea_porParOD_ModoMultimodal_tc_1;
		SELECT 
			v.ParOD, v.distancia,v.IdO,v.IdD, v.z_origen,v.z_destino, v.ModoMultimodal, v.id_linea, v.nombre_linea, v.empresa,
			COUNT (v.id_linea) AS CantidadEtapas
		INTO '+QUOTENAME(@Database)+'.dbo._2_2_2_etapas_por_linea_porParOD_ModoMultimodal_tc_1
		FROM '+QUOTENAME(@Database)+'.dbo._2_base_etapas_por_linea_por_ParOD_tc_1 v
		GROUP BY
			v.ParOD, v.IdO,v.IdD, v.z_origen,v.z_destino, v.distancia, v.ModoMultimodal, v.id_linea, v.nombre_linea,	v.empresa
		ORDER BY
			v.ParOD,v.distancia,v.ModoMultimodal;';
		EXEC sp_executesql @sql;

		-- 14. Calculo de etapas de cada linea por ParOD | _2_2_2_etapas_por_linea_porParOD_tc_1
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_2_etapas_por_linea_porParOD_tc_1;
		SELECT 
			v.ParOD, v.distancia,v.IdO,v.IdD, v.z_origen,v.z_destino, v.id_linea, v.nombre_linea, v.empresa,
			COUNT (v.id_linea) AS CantidadEtapas
		INTO '+QUOTENAME(@Database)+'.dbo._2_2_2_etapas_por_linea_porParOD_tc_1
		FROM '+QUOTENAME(@Database)+'.dbo._2_base_etapas_por_linea_por_ParOD_tc_1 v
		GROUP BY
			v.ParOD, v.IdO,v.IdD, v.z_origen,v.z_destino, v.distancia, v.id_linea, v.nombre_linea,	v.empresa
		ORDER BY
			v.ParOD,v.distancia;';
		EXEC sp_executesql @sql;

		-- 15. Calculo de etapas de cada linea por Distancia | _2_2_2_etapas_por_linea_por_distancia_tc_1
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_2_etapas_por_linea_por_distancia_tc_1;
		SELECT 
			v.distancia,v.IdO,v.IdD, v.z_origen,v.z_destino, v.id_linea, v.nombre_linea, v.empresa,
			COUNT (v.id_linea) AS CantidadEtapas
		INTO '+QUOTENAME(@Database)+'.dbo._2_2_2_etapas_por_linea_por_distancia_tc_1
		FROM '+QUOTENAME(@Database)+'.dbo._2_base_etapas_por_linea_por_ParOD_tc_1 v
		GROUP BY
			v.distancia, v.IdO,v.IdD, v.z_origen,v.z_destino, v.id_linea, v.nombre_linea,	v.empresa
		ORDER BY
			v.distancia;';
		EXEC sp_executesql @sql;

		-- 16. Calculo de etapas de cada linea por ModoMultimodal | _2_2_2_etapas_por_linea_por_ModoMultimodal_tc_1
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_2_etapas_por_linea_por_ModoMultimodal_tc_1;
		SELECT 
			v.ModoMultimodal,v.IdO,v.IdD, v.z_origen,v.z_destino, v.id_linea, v.nombre_linea, v.empresa,
			COUNT (v.id_linea) AS CantidadEtapas
		INTO '+QUOTENAME(@Database)+'.dbo._2_2_2_etapas_por_linea_por_ModoMultimodal_tc_1
		FROM '+QUOTENAME(@Database)+'.dbo._2_base_etapas_por_linea_por_ParOD_tc_1 v
		GROUP BY
			v.ModoMultimodal, v.IdO,v.IdD, v.z_origen,v.z_destino, v.id_linea, v.nombre_linea,	v.empresa
		ORDER BY
			v.ModoMultimodal;';
		EXEC sp_executesql @sql;

		-- 17. Combinacion de viaje por ParOD | _2_2_1_combinacion_mas_utilizadas_porParOD_tc_1
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_1_combinacion_mas_utilizadas_porParOD_tc_1;
		SELECT 
			ParOD, distancia,z_origen, z_destino, NombreCombinacion, CantidadRepeticiones, SumaViajes,
			PARTITIONED.NombreCombinacion_Part1 AS Etapa1,
			PARTITIONED2.NombreCombinacion_Part2 AS Etapa2,
			PARTITIONED3.NombreCombinacion_Part3 AS Etapa3,
			PARTITIONED4.NombreCombinacion_Part4 AS Etapa4,
			PARTITIONED5.NombreCombinacion_Part5 AS Etapa5,
			PARTITIONED6.NombreCombinacion_Part6 AS Etapa6,
			PARTITIONED7.NombreCombinacion_Part7 AS Etapa7,
			PARTITIONED8.NombreCombinacion_Part8 AS Etapa8,
			PARTITIONED9.NombreCombinacion_Part9 AS Etapa9,
			ROW_NUMBER() OVER (PARTITION BY ParOD ORDER BY SumaViajes DESC) AS NroFila
		INTO '+QUOTENAME(@Database)+'.dbo._2_2_1_combinacion_mas_utilizadas_porParOD_tc_1
		FROM (
			SELECT 
				ParOD, distancia, z_origen, z_destino, NombreCombinacion, CantidadRepeticiones,
				SUM(SumaViajes) AS SumaViajes, -- Primero calculo la suma de etapas por par OD,
				ROW_NUMBER() OVER (PARTITION BY ParOD ORDER BY SUM(SumaViajes) DESC) AS NroFila -- Rankeo
			FROM '+QUOTENAME(@Database)+'.dbo._2_2_base_combinaciones_por_linea_porParOD_tc_1
			GROUP BY
				ParOD, z_origen, z_destino, distancia,NombreCombinacion, CantidadRepeticiones
		) AS Subquery';
		SET @sql = @sql + '
		OUTER APPLY (
			-- Dividir NombreCombinacion en la primera parte
			SELECT 
				value AS NombreCombinacion_Part1
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED -- Parte 1
		OUTER APPLY (
			-- Dividir NombreCombinacion en la segunda parte
			SELECT 
				value AS NombreCombinacion_Part2
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED2 -- Parte 2

		OUTER APPLY (
			-- Dividir NombreCombinacion en la tercera parte
			SELECT 
				value AS NombreCombinacion_Part3
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED3 -- Parte 3

		OUTER APPLY (
			-- Dividir NombreCombinacion en la cuarta parte
			SELECT 
				value AS NombreCombinacion_Part4
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 3 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED4 -- Parte 4';
		SET @sql = @sql + '

		OUTER APPLY (
			-- Dividir NombreCombinacion en la quinta parte
			SELECT 
				value AS NombreCombinacion_Part5
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 4 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED5 -- Parte 5

		OUTER APPLY (
			-- Dividir NombreCombinacion en la sexta parte
			SELECT 
				value AS NombreCombinacion_Part6
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 5 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED6 -- Parte 6

		OUTER APPLY (
			-- Dividir NombreCombinacion en la séptima parte
			SELECT 
				value AS NombreCombinacion_Part7
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 6 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED7 -- Parte 7

		OUTER APPLY (
			-- Dividir NombreCombinacion en la octava parte
			SELECT 
				value AS NombreCombinacion_Part8
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 7 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED8 -- Parte 8

		OUTER APPLY (
			-- Dividir NombreCombinacion en la novena parte
			SELECT 
				value AS NombreCombinacion_Part9
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 8 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED9 -- Parte 9
		WHERE NroFila <= 10;';
		EXEC sp_executesql @sql;

		-- 18. Combinacion de viaje por ParOD y Modo | _2_2_1_combinacion_utilizadas_ParOD_Modo_tc_1
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_1_combinacion_utilizadas_ParOD_Modo_tc_1;
		SELECT 
			ParOD, z_origen, z_destino, NombreCombinacion, distancia, ModoMultimodal, CantidadRepeticiones, SumaViajes,
			ROW_NUMBER() OVER (PARTITION BY ParOD, ModoMultimodal ORDER BY SumaViajes DESC) AS NroFila, -- Rankeo
			PARTITIONED.NombreCombinacion_Part1 AS Etapa1,
			PARTITIONED2.NombreCombinacion_Part2 AS Etapa2,
			PARTITIONED3.NombreCombinacion_Part3 AS Etapa3,
			PARTITIONED4.NombreCombinacion_Part4 AS Etapa4,
			PARTITIONED5.NombreCombinacion_Part5 AS Etapa5,
			PARTITIONED6.NombreCombinacion_Part6 AS Etapa6,
			PARTITIONED7.NombreCombinacion_Part7 AS Etapa7,
			PARTITIONED8.NombreCombinacion_Part8 AS Etapa8,
			PARTITIONED9.NombreCombinacion_Part9 AS Etapa9
		INTO '+QUOTENAME(@Database)+'.dbo._2_2_1_combinacion_utilizadas_ParOD_Modo_tc_1 -- Lineas Más Utilizadas ParOD y Modo
		FROM (
			SELECT 
				ParOD, z_origen, z_destino, NombreCombinacion, distancia, CantidadRepeticiones, ModoMultimodal,
				SUM(SumaViajes) AS SumaViajes, 
				ROW_NUMBER() OVER (PARTITION BY ParOD, ModoMultimodal ORDER BY SUM(SumaViajes) DESC) AS NroFila -- Rankeo
			FROM '+QUOTENAME(@Database)+'.dbo._2_2_base_combinaciones_por_linea_porParOD_tc_1
			GROUP BY
				ParOD, z_origen, z_destino,NombreCombinacion, distancia, ModoMultimodal, CantidadRepeticiones
		) AS Subquery';
		SET @sql = @sql + '
		OUTER APPLY (
			-- Dividir NombreCombinacion en la primera parte
			SELECT 
				value AS NombreCombinacion_Part1
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED -- Parte 1

		OUTER APPLY (
			-- Dividir NombreCombinacion en la segunda parte
			SELECT 
				value AS NombreCombinacion_Part2
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED2 -- Parte 2

		OUTER APPLY (
			-- Dividir NombreCombinacion en la tercera parte
			SELECT 
				value AS NombreCombinacion_Part3
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED3 -- Parte 3

		OUTER APPLY (
			-- Dividir NombreCombinacion en la cuarta parte
			SELECT 
				value AS NombreCombinacion_Part4
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 3 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED4 -- Parte 4

		OUTER APPLY (
			-- Dividir NombreCombinacion en la quinta parte
			SELECT 
				value AS NombreCombinacion_Part5
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 4 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED5 -- Parte 5

		OUTER APPLY (
			-- Dividir NombreCombinacion en la sexta parte
			SELECT 
				value AS NombreCombinacion_Part6
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 5 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED6 -- Parte 6';
		SET @sql = @sql + '

		OUTER APPLY (
			-- Dividir NombreCombinacion en la séptima parte
			SELECT 
				value AS NombreCombinacion_Part7
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 6 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED7 -- Parte 7

		OUTER APPLY (
			-- Dividir NombreCombinacion en la octava parte
			SELECT 
				value AS NombreCombinacion_Part8
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 7 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED8 -- Parte 8

		OUTER APPLY (
			-- Dividir NombreCombinacion en la novena parte
			SELECT 
				value AS NombreCombinacion_Part9
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 8 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED9 -- Parte 9
		WHERE NroFila <= 10;';
		EXEC sp_executesql @sql;

		-- 19. Combinacion de viaje por ParOD y Horario| _2_2_1_combinacion_utilizadas_ParOD_Horario_tc_1
		SET @sql =
			'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_1_combinacion_utilizadas_ParOD_Horario_tc_1;
			SELECT 
				ParOD,distancia z_origen, z_destino,NombreCombinacion, distancia, pico_horario, CantidadRepeticiones, SumaViajes,
				ROW_NUMBER() OVER (PARTITION BY ParOD, pico_horario ORDER BY SumaViajes DESC) AS NroFila, -- Rankeo
				PARTITIONED.NombreCombinacion_Part1 AS Etapa1,
				PARTITIONED2.NombreCombinacion_Part2 AS Etapa2,
				PARTITIONED3.NombreCombinacion_Part3 AS Etapa3,
				PARTITIONED4.NombreCombinacion_Part4 AS Etapa4,
				PARTITIONED5.NombreCombinacion_Part5 AS Etapa5,
				PARTITIONED6.NombreCombinacion_Part6 AS Etapa6,
				PARTITIONED7.NombreCombinacion_Part7 AS Etapa7,
				PARTITIONED8.NombreCombinacion_Part8 AS Etapa8,
				PARTITIONED9.NombreCombinacion_Part9 AS Etapa9
			INTO '+QUOTENAME(@Database)+'.dbo._2_2_1_combinacion_utilizadas_ParOD_Horario_tc_1 -- Lineas Más Utilizadas ParOD y Modo
			FROM (
				SELECT 
					ParOD, z_origen, z_destino,NombreCombinacion, distancia, pico_horario, CantidadRepeticiones,
					SUM(SumaViajes) AS SumaViajes, -- Primero calculo la suma de etapas por par OD
					ROW_NUMBER() OVER (PARTITION BY ParOD, NombreCombinacion,pico_horario ORDER BY SUM(SumaViajes) DESC) AS NroFila -- Rankeo
				FROM '+QUOTENAME(@Database)+'.dbo._2_2_base_combinaciones_por_linea_porParOD_tc_1
				GROUP BY
					ParOD, z_origen, z_destino,NombreCombinacion, distancia, pico_horario, CantidadRepeticiones
			) AS Subquery';
		SET @sql = @sql + '
			OUTER APPLY (
				-- Dividir NombreCombinacion en la primera parte
				SELECT 
					value AS NombreCombinacion_Part1
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED -- Parte 1

			OUTER APPLY (
				-- Dividir NombreCombinacion en la segunda parte
				SELECT 
					value AS NombreCombinacion_Part2
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED2 -- Parte 2

			OUTER APPLY (
				-- Dividir NombreCombinacion en la tercera parte
				SELECT 
					value AS NombreCombinacion_Part3
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED3 -- Parte 3

			OUTER APPLY (
				-- Dividir NombreCombinacion en la cuarta parte
				SELECT 
					value AS NombreCombinacion_Part4
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 3 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED4 -- Parte 4

			OUTER APPLY (
				-- Dividir NombreCombinacion en la quinta parte
				SELECT 
					value AS NombreCombinacion_Part5
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 4 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED5 -- Parte 5';
		SET @sql = @sql + '

		OUTER APPLY (
			-- Dividir NombreCombinacion en la sexta parte
			SELECT 
				value AS NombreCombinacion_Part6
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 5 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED6 -- Parte 6

		OUTER APPLY (
			-- Dividir NombreCombinacion en la séptima parte
			SELECT 
				value AS NombreCombinacion_Part7
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 6 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED7 -- Parte 7

		OUTER APPLY (
			-- Dividir NombreCombinacion en la octava parte
			SELECT 
				value AS NombreCombinacion_Part8
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 7 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED8 -- Parte 8

		OUTER APPLY (
			-- Dividir NombreCombinacion en la novena parte
			SELECT 
				value AS NombreCombinacion_Part9
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 8 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED9 -- Parte 9
		WHERE NroFila <= 10;';
		EXEC sp_executesql @sql;

		-- 20. Combinacion de viaje por ParOD, Modo y Distancia | _2_2_1_combinacion_utilizadas_ParOD_Modo_Distancia_tc_1
		SET @sql =
			'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_1_combinacion_utilizadas_ParOD_Modo_Distancia_tc_1;
			SELECT 
				ParOD, distancia, z_origen, z_destino,NombreCombinacion, ModoMultimodal, CantidadRepeticiones, SumaViajes,
				ROW_NUMBER() OVER (PARTITION BY ParOD, ModoMultimodal, distancia ORDER BY SumaViajes DESC) AS NroFila, -- Rankeo
				PARTITIONED.NombreCombinacion_Part1 AS Etapa1,
				PARTITIONED2.NombreCombinacion_Part2 AS Etapa2,
				PARTITIONED3.NombreCombinacion_Part3 AS Etapa3,
				PARTITIONED4.NombreCombinacion_Part4 AS Etapa4,
				PARTITIONED5.NombreCombinacion_Part5 AS Etapa5,
				PARTITIONED6.NombreCombinacion_Part6 AS Etapa6,
				PARTITIONED7.NombreCombinacion_Part7 AS Etapa7,
				PARTITIONED8.NombreCombinacion_Part8 AS Etapa8,
				PARTITIONED9.NombreCombinacion_Part9 AS Etapa9
			INTO '+QUOTENAME(@Database)+'.dbo._2_2_1_combinacion_utilizadas_ParOD_Modo_Distancia_tc_1 -- Lineas Más Utilizadas ParOD y Modo
			FROM (
				SELECT 
					ParOD, z_origen, z_destino, NombreCombinacion,distancia, ModoMultimodal, CantidadRepeticiones,
					SUM(SumaViajes) AS SumaViajes, -- Primero calculo la suma de etapas por par OD
					ROW_NUMBER() OVER (PARTITION BY ParOD, ModoMultimodal, distancia ORDER BY SUM(SumaViajes) DESC) AS NroFila -- Rankeo
				FROM '+QUOTENAME(@Database)+'.dbo._2_2_base_combinaciones_por_linea_porParOD_tc_1
				GROUP BY
					ParOD, z_origen, z_destino,NombreCombinacion, distancia, ModoMultimodal,CantidadRepeticiones
			) AS Subquery
			OUTER APPLY (
				-- Dividir NombreCombinacion en la primera parte
				SELECT 
					value AS NombreCombinacion_Part1
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED -- Parte 1';
		SET @sql = @sql + '
			OUTER APPLY (
				-- Dividir NombreCombinacion en la segunda parte
				SELECT 
					value AS NombreCombinacion_Part2
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED2 -- Parte 2

			OUTER APPLY (
				-- Dividir NombreCombinacion en la tercera parte
				SELECT 
					value AS NombreCombinacion_Part3
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED3 -- Parte 3

			OUTER APPLY (
				-- Dividir NombreCombinacion en la cuarta parte
				SELECT 
					value AS NombreCombinacion_Part4
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 3 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED4 -- Parte 4

			OUTER APPLY (
				-- Dividir NombreCombinacion en la quinta parte
				SELECT 
					value AS NombreCombinacion_Part5
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 4 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED5 -- Parte 5';
		SET @sql = @sql + '
		OUTER APPLY (
			-- Dividir NombreCombinacion en la sexta parte
			SELECT 
				value AS NombreCombinacion_Part6
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 5 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED6 -- Parte 6

		OUTER APPLY (
			-- Dividir NombreCombinacion en la séptima parte
			SELECT 
				value AS NombreCombinacion_Part7
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 6 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED7 -- Parte 7

		OUTER APPLY (
			-- Dividir NombreCombinacion en la octava parte
			SELECT 
				value AS NombreCombinacion_Part8
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 7 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED8 -- Parte 8

		OUTER APPLY (
			-- Dividir NombreCombinacion en la novena parte
			SELECT 
				value AS NombreCombinacion_Part9
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 8 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED9 -- Parte 9
		WHERE NroFila <= 10;';
		EXEC sp_executesql @sql;

		-- 21. Combinacion de viaje por ParOd, Modo, Distancia y Modo | _2_2_1_combinacion_utilizadas_ParOD_Modo_Distancia_horario_tc_1
		SET @sql =
			'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_1_combinacion_utilizadas_ParOD_Modo_Distancia_horario_tc_1;
			SELECT 
				ParOD,distancia, z_origen, z_destino,NombreCombinacion, ModoMultimodal, pico_horario, CantidadRepeticiones,SumaViajes,
				ROW_NUMBER() OVER (PARTITION BY ParOD, ModoMultimodal, distancia, pico_horario ORDER BY SumaViajes DESC) AS NroFila, -- Rankeo
				PARTITIONED.NombreCombinacion_Part1 AS Etapa1,
				PARTITIONED2.NombreCombinacion_Part2 AS Etapa2,
				PARTITIONED3.NombreCombinacion_Part3 AS Etapa3,
				PARTITIONED4.NombreCombinacion_Part4 AS Etapa4,
				PARTITIONED5.NombreCombinacion_Part5 AS Etapa5,
				PARTITIONED6.NombreCombinacion_Part6 AS Etapa6,
				PARTITIONED7.NombreCombinacion_Part7 AS Etapa7,
				PARTITIONED8.NombreCombinacion_Part8 AS Etapa8,
				PARTITIONED9.NombreCombinacion_Part9 AS Etapa9
			INTO '+QUOTENAME(@Database)+'.dbo._2_2_1_combinacion_utilizadas_ParOD_Modo_Distancia_horario_tc_1 -- Lineas Más Utilizadas ParOD y Modo
			FROM (
				SELECT 
					ParOD, z_origen, z_destino,NombreCombinacion, distancia, ModoMultimodal, pico_horario, CantidadRepeticiones,
					SUM(SumaViajes) AS SumaViajes, -- Primero calculo la suma de etapas por par OD
					ROW_NUMBER() OVER (PARTITION BY ParOD, ModoMultimodal, distancia, pico_horario ORDER BY SUM(SumaViajes) DESC) AS NroFila -- Rankeo
				FROM '+QUOTENAME(@Database)+'.dbo._2_2_base_combinaciones_por_linea_porParOD_tc_1
				GROUP BY
					ParOD, z_origen, z_destino,NombreCombinacion, distancia, ModoMultimodal, pico_horario,CantidadRepeticiones
			) AS Subquery';
		SET @sql = @sql + '
		OUTER APPLY (
			-- Dividir NombreCombinacion en la primera parte
			SELECT 
				value AS NombreCombinacion_Part1
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED -- Parte 1
		OUTER APPLY (
			-- Dividir NombreCombinacion en la segunda parte
			SELECT 
				value AS NombreCombinacion_Part2
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED2 -- Parte 2
		OUTER APPLY (
			-- Dividir NombreCombinacion en la tercera parte
			SELECT 
				value AS NombreCombinacion_Part3
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED3 -- Parte 3
		OUTER APPLY (
			-- Dividir NombreCombinacion en la cuarta parte
			SELECT 
				value AS NombreCombinacion_Part4
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 3 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED4 -- Parte 4
		OUTER APPLY (
			-- Dividir NombreCombinacion en la quinta parte
			SELECT 
				value AS NombreCombinacion_Part5
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 4 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED5 -- Parte 5';
		SET @sql = @sql + '
		OUTER APPLY (
			-- Dividir NombreCombinacion en la sexta parte
			SELECT 
				value AS NombreCombinacion_Part6
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 5 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED6 -- Parte 6

		OUTER APPLY (
			-- Dividir NombreCombinacion en la séptima parte
			SELECT 
				value AS NombreCombinacion_Part7
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 6 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED7 -- Parte 7

		OUTER APPLY (
			-- Dividir NombreCombinacion en la octava parte
			SELECT 
				value AS NombreCombinacion_Part8
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 7 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED8 -- Parte 8

		OUTER APPLY (
			-- Dividir NombreCombinacion en la novena parte
			SELECT 
				value AS NombreCombinacion_Part9
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 8 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED9 -- Parte 9
		WHERE NroFila <= 10;';
		EXEC sp_executesql @sql;

		-- 22. Combinacion de viaje por Distancia | _2_2_1_combinacion_utilizadas_Distancia_tc_1
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_1_combinacion_utilizadas_Distancia_tc_1;
		SELECT 
			distancia, 
			NombreCombinacion,
			SUM(CantidadRepeticiones) AS CantidadRepeticiones,
			SUM(SumaViajes) AS SumaViajes,
			ROW_NUMBER() OVER (PARTITION BY distancia ORDER BY SUM(SumaViajes) DESC) AS NroFila,
			PARTITIONED.NombreCombinacion_Part1 AS Etapa1,
			PARTITIONED2.NombreCombinacion_Part2 AS Etapa2,
			PARTITIONED3.NombreCombinacion_Part3 AS Etapa3,
			PARTITIONED4.NombreCombinacion_Part4 AS Etapa4,
			PARTITIONED5.NombreCombinacion_Part5 AS Etapa5,
			PARTITIONED6.NombreCombinacion_Part6 AS Etapa6,
			PARTITIONED7.NombreCombinacion_Part7 AS Etapa7,
			PARTITIONED8.NombreCombinacion_Part8 AS Etapa8,
			PARTITIONED9.NombreCombinacion_Part9 AS Etapa9
		INTO '+QUOTENAME(@Database)+'.dbo._2_2_1_combinacion_utilizadas_Distancia_tc_1
		FROM (
			SELECT 
				distancia, 
				NombreCombinacion,
				SUM(CantidadRepeticiones) AS CantidadRepeticiones,
				SUM(SumaViajes) AS SumaViajes, -- Primero calculo la suma de etapas por par OD
				ROW_NUMBER() OVER (PARTITION BY distancia ORDER BY SUM(SumaViajes) DESC) AS NroFila
			FROM '+QUOTENAME(@Database)+'.dbo._2_2_base_combinaciones_por_linea_porParOD_tc_1
			GROUP BY 
				distancia, 
				NombreCombinacion
		) AS Subquery';
		SET @sql = @sql + '
			OUTER APPLY (
				-- Dividir NombreCombinacion en la primera parte
				SELECT 
					value AS NombreCombinacion_Part1
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED -- Parte 1
			OUTER APPLY (
				-- Dividir NombreCombinacion en la segunda parte
				SELECT 
					value AS NombreCombinacion_Part2
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED2 -- Parte 2
			OUTER APPLY (
				-- Dividir NombreCombinacion en la tercera parte
				SELECT 
					value AS NombreCombinacion_Part3
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED3 -- Parte 3
			OUTER APPLY (
				-- Dividir NombreCombinacion en la cuarta parte
				SELECT 
					value AS NombreCombinacion_Part4
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 3 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED4 -- Parte 4
			OUTER APPLY (
				-- Dividir NombreCombinacion en la quinta parte
				SELECT 
					value AS NombreCombinacion_Part5
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 4 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED5 -- Parte 5';
		SET @sql = @sql + '
		OUTER APPLY (
			-- Dividir NombreCombinacion en la sexta parte
			SELECT 
				value AS NombreCombinacion_Part6
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 5 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED6 -- Parte 6
		OUTER APPLY (
			-- Dividir NombreCombinacion en la séptima parte
			SELECT 
				value AS NombreCombinacion_Part7
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 6 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED7 -- Parte 7
		OUTER APPLY (
			-- Dividir NombreCombinacion en la octava parte
			SELECT 
				value AS NombreCombinacion_Part8
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 7 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED8 -- Parte 8
		OUTER APPLY (
			-- Dividir NombreCombinacion en la novena parte
			SELECT 
				value AS NombreCombinacion_Part9
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 8 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED9 -- Parte 9
		WHERE NroFila <= 10
		GROUP BY 
			distancia, NombreCombinacion,
			PARTITIONED.NombreCombinacion_Part1,
			PARTITIONED2.NombreCombinacion_Part2,
			PARTITIONED3.NombreCombinacion_Part3,
			PARTITIONED4.NombreCombinacion_Part4,
			PARTITIONED5.NombreCombinacion_Part5,
			PARTITIONED6.NombreCombinacion_Part6,
			PARTITIONED7.NombreCombinacion_Part7,
			PARTITIONED8.NombreCombinacion_Part8,
			PARTITIONED9.NombreCombinacion_Part9;';
		EXEC sp_executesql @sql;

		-- 23. Combinacion de viaje por Modo Multimodal | _2_2_1_combinacion_utilizadas_ModoMultimodal_tc_1
		SET @sql =
			'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_1_combinacion_utilizadas_ModoMultimodal_tc_1;
			SELECT 
				ModoMultimodal,NombreCombinacion,
				SUM(CantidadRepeticiones) AS CantidadRepeticiones,
				SUM(SumaViajes) AS SumaViajes,
				ROW_NUMBER() OVER (PARTITION BY ModoMultimodal ORDER BY SUM(SumaViajes) DESC) AS NroFila,
				PARTITIONED.NombreCombinacion_Part1 AS Etapa1,
				PARTITIONED2.NombreCombinacion_Part2 AS Etapa2,
				PARTITIONED3.NombreCombinacion_Part3 AS Etapa3,
				PARTITIONED4.NombreCombinacion_Part4 AS Etapa4,
				PARTITIONED5.NombreCombinacion_Part5 AS Etapa5,
				PARTITIONED6.NombreCombinacion_Part6 AS Etapa6,
				PARTITIONED7.NombreCombinacion_Part7 AS Etapa7,
				PARTITIONED8.NombreCombinacion_Part8 AS Etapa8,
				PARTITIONED9.NombreCombinacion_Part9 AS Etapa9
			INTO '+QUOTENAME(@Database)+'.dbo._2_2_1_combinacion_utilizadas_ModoMultimodal_tc_1 -- Lineas Más Utilizadas ParOD y Modo
			FROM (
				SELECT 
					ModoMultimodal,NombreCombinacion,
					SUM(CantidadRepeticiones) AS CantidadRepeticiones,
					SUM(SumaViajes) AS SumaViajes, -- Primero calculo la suma de etapas por par OD
					ROW_NUMBER() OVER (PARTITION BY ModoMultimodal ORDER BY SUM(SumaViajes) DESC) AS NroFila -- Rankeo
				FROM '+QUOTENAME(@Database)+'.dbo._2_2_base_combinaciones_por_linea_porParOD_tc_1
				GROUP BY
					ModoMultimodal,NombreCombinacion
			) AS Subquery';
		SET @sql = @sql + '
			OUTER APPLY (
				-- Dividir NombreCombinacion en la primera parte
				SELECT 
					value AS NombreCombinacion_Part1
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED -- Parte 1
			OUTER APPLY (
				-- Dividir NombreCombinacion en la segunda parte
				SELECT 
					value AS NombreCombinacion_Part2
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED2 -- Parte 2
			OUTER APPLY (
				-- Dividir NombreCombinacion en la tercera parte
				SELECT 
					value AS NombreCombinacion_Part3
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED3 -- Parte 3
			OUTER APPLY (
				-- Dividir NombreCombinacion en la cuarta parte
				SELECT 
					value AS NombreCombinacion_Part4
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 3 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED4 -- Parte 4
			OUTER APPLY (
				-- Dividir NombreCombinacion en la quinta parte
				SELECT 
					value AS NombreCombinacion_Part5
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 4 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED5 -- Parte 5';
		SET @sql = @sql + '
		OUTER APPLY (
			-- Dividir NombreCombinacion en la sexta parte
			SELECT 
				value AS NombreCombinacion_Part6
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 5 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED6 -- Parte 6
		OUTER APPLY (
			-- Dividir NombreCombinacion en la séptima parte
			SELECT 
				value AS NombreCombinacion_Part7
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 6 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED7 -- Parte 7
		OUTER APPLY (
			-- Dividir NombreCombinacion en la octava parte
			SELECT 
				value AS NombreCombinacion_Part8
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 7 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED8 -- Parte 8
		OUTER APPLY (
			-- Dividir NombreCombinacion en la novena parte
			SELECT 
				value AS NombreCombinacion_Part9
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 8 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED9 -- Parte 9
		WHERE NroFila <= 10
		GROUP BY 
			ModoMultimodal, NombreCombinacion,
			PARTITIONED.NombreCombinacion_Part1,
			PARTITIONED2.NombreCombinacion_Part2,
			PARTITIONED3.NombreCombinacion_Part3,
			PARTITIONED4.NombreCombinacion_Part4,
			PARTITIONED5.NombreCombinacion_Part5,
			PARTITIONED6.NombreCombinacion_Part6,
			PARTITIONED7.NombreCombinacion_Part7,
			PARTITIONED8.NombreCombinacion_Part8,
			PARTITIONED9.NombreCombinacion_Part9;';
		EXEC sp_executesql @sql;

		-- 24. Combinacion de viaje por Horario | _2_2_1_combinacion_utilizadas_horario_tc_1
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_1_combinacion_utilizadas_horario_tc_1;
		SELECT 
			pico_horario, NombreCombinacion, 
			SUM(CantidadRepeticiones) AS CantidadRepeticiones,
			SUM(SumaViajes) AS TotalViajes,
			ROW_NUMBER() OVER (PARTITION BY pico_horario ORDER BY SUM(SumaViajes) DESC) AS NroFila,
			PARTITIONED.NombreCombinacion_Part1 AS Etapa1,
			PARTITIONED2.NombreCombinacion_Part2 AS Etapa2,
			PARTITIONED3.NombreCombinacion_Part3 AS Etapa3,
			PARTITIONED4.NombreCombinacion_Part4 AS Etapa4,
			PARTITIONED5.NombreCombinacion_Part5 AS Etapa5,
			PARTITIONED6.NombreCombinacion_Part6 AS Etapa6,
			PARTITIONED7.NombreCombinacion_Part7 AS Etapa7,
			PARTITIONED8.NombreCombinacion_Part8 AS Etapa8,
			PARTITIONED9.NombreCombinacion_Part9 AS Etapa9
		INTO '+QUOTENAME(@Database)+'.dbo._2_2_1_combinacion_utilizadas_horario_tc_1 -- Lineas Más Utilizadas ParOD y Modo
		FROM (
			SELECT 
				pico_horario,NombreCombinacion,
				SUM(CantidadRepeticiones) AS CantidadRepeticiones,
				SUM(SumaViajes) AS SumaViajes, -- Primero calculo la suma de etapas por par OD
				ROW_NUMBER() OVER (PARTITION BY pico_horario ORDER BY SUM(SumaViajes) DESC) AS NroFila -- Rankeo
			FROM '+QUOTENAME(@Database)+'.dbo._2_2_base_combinaciones_por_linea_porParOD_tc_1
			GROUP BY
				pico_horario, NombreCombinacion
		) AS Subquery';
		SET @sql = @sql + '
			OUTER APPLY (
				-- Dividir NombreCombinacion en la primera parte
				SELECT 
					value AS NombreCombinacion_Part1
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED -- Parte 1
			OUTER APPLY (
				-- Dividir NombreCombinacion en la segunda parte
				SELECT 
					value AS NombreCombinacion_Part2
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED2 -- Parte 2
			OUTER APPLY (
				-- Dividir NombreCombinacion en la tercera parte
				SELECT 
					value AS NombreCombinacion_Part3
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED3 -- Parte 3
			OUTER APPLY (
				-- Dividir NombreCombinacion en la cuarta parte
				SELECT 
					value AS NombreCombinacion_Part4
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 3 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED4 -- Parte 4
			OUTER APPLY (
				-- Dividir NombreCombinacion en la quinta parte
				SELECT 
					value AS NombreCombinacion_Part5
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 4 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED5 -- Parte 5';
		SET @sql = @sql + '
			OUTER APPLY (
				-- Dividir NombreCombinacion en la sexta parte
				SELECT 
					value AS NombreCombinacion_Part6
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 5 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED6 -- Parte 6
			OUTER APPLY (
				-- Dividir NombreCombinacion en la séptima parte
				SELECT 
					value AS NombreCombinacion_Part7
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 6 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED7 -- Parte 7
			OUTER APPLY (
				-- Dividir NombreCombinacion en la octava parte
				SELECT 
					value AS NombreCombinacion_Part8
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 7 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED8 -- Parte 8
			OUTER APPLY (
				-- Dividir NombreCombinacion en la novena parte
				SELECT 
					value AS NombreCombinacion_Part9
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 8 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED9 -- Parte 9
			WHERE NroFila <= 10
			GROUP BY 
				pico_horario, NombreCombinacion,
				PARTITIONED.NombreCombinacion_Part1,
				PARTITIONED2.NombreCombinacion_Part2,
				PARTITIONED3.NombreCombinacion_Part3,
				PARTITIONED4.NombreCombinacion_Part4,
				PARTITIONED5.NombreCombinacion_Part5,
				PARTITIONED6.NombreCombinacion_Part6,
				PARTITIONED7.NombreCombinacion_Part7,
				PARTITIONED8.NombreCombinacion_Part8,
				PARTITIONED9.NombreCombinacion_Part9;';
		EXEC sp_executesql @sql;

		-- 25. Combinacion de viaje por Distancia y Modo | _2_2_1_combinacion_utilizadas_Distancia_Modo_tc_1
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_1_combinacion_utilizadas_Distancia_Modo_tc_1;
		SELECT 
			Distancia, ModoMultimodal, NombreCombinacion, 
			SUM(CantidadRepeticiones) AS CantidadRepeticiones,
			SUM(SumaViajes) AS TotalViajes,
			ROW_NUMBER() OVER (PARTITION BY Distancia, ModoMultimodal ORDER BY SUM(SumaViajes) DESC) AS NroFila,
			PARTITIONED.NombreCombinacion_Part1 AS Etapa1,
			PARTITIONED2.NombreCombinacion_Part2 AS Etapa2,
			PARTITIONED3.NombreCombinacion_Part3 AS Etapa3,
			PARTITIONED4.NombreCombinacion_Part4 AS Etapa4,
			PARTITIONED5.NombreCombinacion_Part5 AS Etapa5,
			PARTITIONED6.NombreCombinacion_Part6 AS Etapa6,
			PARTITIONED7.NombreCombinacion_Part7 AS Etapa7,
			PARTITIONED8.NombreCombinacion_Part8 AS Etapa8,
			PARTITIONED9.NombreCombinacion_Part9 AS Etapa9
		INTO '+QUOTENAME(@Database)+'.dbo._2_2_1_combinacion_utilizadas_Distancia_Modo_tc_1 -- Lineas Más Utilizadas ParOD y Modo
		FROM (
			SELECT 
				Distancia, ModoMultimodal,NombreCombinacion,
				SUM(CantidadRepeticiones) AS CantidadRepeticiones,
				SUM(SumaViajes) AS SumaViajes, -- Primero calculo la suma de etapas por par OD
				ROW_NUMBER() OVER (PARTITION BY Distancia, ModoMultimodal ORDER BY SUM(SumaViajes) DESC) AS NroFila -- Rankeo
			FROM '+QUOTENAME(@Database)+'.dbo._2_2_base_combinaciones_por_linea_porParOD_tc_1
			GROUP BY
				Distancia, ModoMultimodal, NombreCombinacion
		) AS Subquery';
		SET @sql = @sql + '
			OUTER APPLY (
				-- Dividir NombreCombinacion en la primera parte
				SELECT 
					value AS NombreCombinacion_Part1
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED -- Parte 1
			OUTER APPLY (
				-- Dividir NombreCombinacion en la segunda parte
				SELECT 
					value AS NombreCombinacion_Part2
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED2 -- Parte 2
			OUTER APPLY (
				-- Dividir NombreCombinacion en la tercera parte
				SELECT 
					value AS NombreCombinacion_Part3
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED3 -- Parte 3
			OUTER APPLY (
				-- Dividir NombreCombinacion en la cuarta parte
				SELECT 
					value AS NombreCombinacion_Part4
				FROM STRING_SPLIT(NombreCombinacion, ''-'')
				ORDER BY (SELECT NULL)
				OFFSET 3 ROWS FETCH NEXT 1 ROWS ONLY
			) AS PARTITIONED4 -- Parte 4';
		SET @sql = @sql + '
		OUTER APPLY (
			-- Dividir NombreCombinacion en la quinta parte
			SELECT 
				value AS NombreCombinacion_Part5
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 4 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED5 -- Parte 5
		OUTER APPLY (
			-- Dividir NombreCombinacion en la sexta parte
			SELECT 
				value AS NombreCombinacion_Part6
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 5 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED6 -- Parte 6
		OUTER APPLY (
			-- Dividir NombreCombinacion en la séptima parte
			SELECT 
				value AS NombreCombinacion_Part7
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 6 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED7 -- Parte 7
		OUTER APPLY (
			-- Dividir NombreCombinacion en la octava parte
			SELECT 
				value AS NombreCombinacion_Part8
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 7 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED8 -- Parte 8
		OUTER APPLY (
			-- Dividir NombreCombinacion en la novena parte
			SELECT 
				value AS NombreCombinacion_Part9
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 8 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED9 -- Parte 9
		WHERE NroFila <= 10
		GROUP BY 
			Distancia, ModoMultimodal, NombreCombinacion,
			PARTITIONED.NombreCombinacion_Part1,
			PARTITIONED2.NombreCombinacion_Part2,
			PARTITIONED3.NombreCombinacion_Part3,
			PARTITIONED4.NombreCombinacion_Part4,
			PARTITIONED5.NombreCombinacion_Part5,
			PARTITIONED6.NombreCombinacion_Part6,
			PARTITIONED7.NombreCombinacion_Part7,
			PARTITIONED8.NombreCombinacion_Part8,
			PARTITIONED9.NombreCombinacion_Part9;';
		EXEC sp_executesql @sql;

		-- 26. Combinacion de viaje por Distancia, Modo y Horario | _2_2_1_combinacion_utilizadas_Distancia_Modo_Horario_tc_1
		SET @sql =
			'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_1_combinacion_utilizadas_Distancia_Modo_Horario_tc_1;
			SELECT 
				Distancia, pico_horario, ModoMultimodal,NombreCombinacion,
				SUM(CantidadRepeticiones) AS CantidadRepeticiones,
				SUM(SumaViajes) AS TotalViajes,
				ROW_NUMBER() OVER (PARTITION BY Distancia, pico_horario, ModoMultimodal ORDER BY SUM(SumaViajes) DESC) AS NroFila,
				PARTITIONED.NombreCombinacion_Part1 AS Etapa1,
				PARTITIONED2.NombreCombinacion_Part2 AS Etapa2,
				PARTITIONED3.NombreCombinacion_Part3 AS Etapa3,
				PARTITIONED4.NombreCombinacion_Part4 AS Etapa4,
				PARTITIONED5.NombreCombinacion_Part5 AS Etapa5,
				PARTITIONED6.NombreCombinacion_Part6 AS Etapa6,
				PARTITIONED7.NombreCombinacion_Part7 AS Etapa7,
				PARTITIONED8.NombreCombinacion_Part8 AS Etapa8,
				PARTITIONED9.NombreCombinacion_Part9 AS Etapa9
			INTO '+QUOTENAME(@Database)+'.dbo._2_2_1_combinacion_utilizadas_Distancia_Modo_Horario_tc_1 -- Lineas Más Utilizadas ParOD y Modo
			FROM (
				SELECT 
					Distancia,pico_horario, ModoMultimodal,NombreCombinacion,
					SUM(CantidadRepeticiones) AS CantidadRepeticiones,
					SUM(SumaViajes) AS SumaViajes, -- Primero calculo la suma de etapas por par OD
					ROW_NUMBER() OVER (PARTITION BY Distancia, pico_horario, ModoMultimodal ORDER BY SUM(SumaViajes) DESC) AS NroFila -- Rankeo
				FROM '+QUOTENAME(@Database)+'.dbo._2_2_base_combinaciones_por_linea_porParOD_tc_1
				WHERE TieneCombinacion = 0
				GROUP BY
					Distancia, pico_horario, ModoMultimodal, NombreCombinacion
			) AS Subquery';
		SET @sql = @sql + '
		OUTER APPLY (
			-- Dividir NombreCombinacion en la primera parte
			SELECT 
				value AS NombreCombinacion_Part1
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED -- Parte 1
		OUTER APPLY (
			-- Dividir NombreCombinacion en la segunda parte
			SELECT 
				value AS NombreCombinacion_Part2
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED2 -- Parte 2
		OUTER APPLY (
			-- Dividir NombreCombinacion en la tercera parte
			SELECT 
				value AS NombreCombinacion_Part3
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED3 -- Parte 3
		OUTER APPLY (
			-- Dividir NombreCombinacion en la cuarta parte
			SELECT 
				value AS NombreCombinacion_Part4
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 3 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED4 -- Parte 4';
		SET @sql = @sql + '
		OUTER APPLY (
			-- Dividir NombreCombinacion en la quinta parte
			SELECT 
				value AS NombreCombinacion_Part5
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 4 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED5 -- Parte 5
		OUTER APPLY (
			-- Dividir NombreCombinacion en la sexta parte
			SELECT 
				value AS NombreCombinacion_Part6
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 5 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED6 -- Parte 6
		OUTER APPLY (
			-- Dividir NombreCombinacion en la séptima parte
			SELECT 
				value AS NombreCombinacion_Part7
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 6 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED7 -- Parte 7
		OUTER APPLY (
			-- Dividir NombreCombinacion en la octava parte
			SELECT 
				value AS NombreCombinacion_Part8
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 7 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED8 -- Parte 8
		OUTER APPLY (
			-- Dividir NombreCombinacion en la novena parte
			SELECT 
				value AS NombreCombinacion_Part9
			FROM STRING_SPLIT(NombreCombinacion, ''-'')
			ORDER BY (SELECT NULL)
			OFFSET 8 ROWS FETCH NEXT 1 ROWS ONLY
		) AS PARTITIONED9 -- Parte 9
		WHERE NroFila <= 10
		GROUP BY 
			Distancia, pico_horario, ModoMultimodal, NombreCombinacion,
			PARTITIONED.NombreCombinacion_Part1,
			PARTITIONED2.NombreCombinacion_Part2,
			PARTITIONED3.NombreCombinacion_Part3,
			PARTITIONED4.NombreCombinacion_Part4,
			PARTITIONED5.NombreCombinacion_Part5,
			PARTITIONED6.NombreCombinacion_Part6,
			PARTITIONED7.NombreCombinacion_Part7,
			PARTITIONED8.NombreCombinacion_Part8,
			PARTITIONED9.NombreCombinacion_Part9;';
		EXEC sp_executesql @sql;
		
		-- 27. Linea mas utilizada por ModoMultimodal | _2_2_2_top_linea_mas_utilizadas_ModoMultimodal_tc_1
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_2_top_por_linea_por_ModoMultimodal_tc_1;
		SELECT 
			ModoMultimodal, id_linea, nombre_linea, empresa, CantidadEtapas,
			ROW_NUMBER() OVER (PARTITION BY ModoMultimodal ORDER BY CantidadEtapas DESC) AS NroFila
		INTO '+QUOTENAME(@Database)+'.dbo._2_2_2_top_linea_mas_utilizadas_ModoMultimodal_tc_1 
		FROM (
			SELECT 
				ModoMultimodal, id_linea, nombre_linea, empresa,
				SUM(CantidadEtapas) AS CantidadEtapas,
				ROW_NUMBER() OVER (PARTITION BY ModoMultimodal ORDER BY SUM(CantidadEtapas) DESC) AS NroFila
			FROM '+QUOTENAME(@Database)+'.dbo._2_base_viajes_top_lineas 
			WHERE TieneCombinacion = 0
			GROUP BY
				ModoMultimodal, id_linea, nombre_linea, empresa
		) AS Subquery
		WHERE NroFila <= 10;';
		EXEC sp_executesql @sql;
				
		-- 28. Linea mas utilizada por Distancia | _2_2_2_top_linea_mas_utilizadas_Distancia_tc_1
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_2_top_linea_mas_utilizadas_Distancia_tc_1;
		SELECT 
			distancia, id_linea, nombre_linea, empresa, CantidadEtapas,
			ROW_NUMBER() OVER (PARTITION BY distancia ORDER BY CantidadEtapas DESC) AS NroFila -- Rankeo
		INTO '+QUOTENAME(@Database)+'.dbo._2_top_linea_mas_utilizadas_Distancia_tc_1
		FROM (
			SELECT 
				distancia, id_linea, nombre_linea, empresa,
				SUM(CantidadEtapas) AS CantidadEtapas,
				ROW_NUMBER() OVER (PARTITION BY distancia ORDER BY SUM(CantidadEtapas) DESC) AS NroFila -- Rankeo
			FROM '+QUOTENAME(@Database)+'.dbo._2_base_viajes_top_lineas 
			WHERE TieneCombinacion = 0
			GROUP BY
				distancia, id_linea, nombre_linea, empresa
		) AS Subquery
		WHERE NroFila <= 10;';
		EXEC sp_executesql @sql;

		-- 29. Linea mas utilizada por Pico Horario | _2_2_2_top_linea_mas_utilizadas_pico_horario_tc_1
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_2_top_linea_mas_utilizadas_pico_horario_tc_1;
		SELECT 
			pico_horario, id_linea, nombre_linea, empresa, CantidadEtapas,
			ROW_NUMBER() OVER (PARTITION BY pico_horario ORDER BY CantidadEtapas DESC) AS NroFila
		INTO '+QUOTENAME(@Database)+'.dbo._2_2_2_top_linea_mas_utilizadas_horario_tc_1
		FROM (
			SELECT 
				pico_horario, id_linea, nombre_linea, empresa,
				SUM(CantidadEtapas) AS CantidadEtapas,
				ROW_NUMBER() OVER (PARTITION BY pico_horario ORDER BY SUM(CantidadEtapas) DESC) AS NroFila
			FROM '+QUOTENAME(@Database)+'.dbo._2_base_viajes_top_lineas 
			WHERE TieneCombinacion = 0
			GROUP BY
				pico_horario,id_linea, nombre_linea, empresa
		) AS Subquery
		WHERE NroFila <= 10;';
		EXEC sp_executesql @sql;
		
		-- 30. Linea mas utilizada por Hora | _2_2_2_top_linea_mas_utilizadas_hora_tc_1
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_2_top_linea_mas_utilizadas_hora_tc_1;
		SELECT 
			hora, id_linea, nombre_linea, empresa, CantidadEtapas,
			ROW_NUMBER() OVER (PARTITION BY hora ORDER BY CantidadEtapas DESC) AS NroFila
		INTO '+QUOTENAME(@Database)+'.dbo._2_2_2_top_linea_mas_utilizadas_hora_tc_1
		FROM (
			SELECT 
				hora, id_linea, nombre_linea, empresa,
				SUM(CantidadEtapas) AS CantidadEtapas,
				ROW_NUMBER() OVER (PARTITION BY hora ORDER BY SUM(CantidadEtapas) DESC) AS NroFila
			FROM '+QUOTENAME(@Database)+'.dbo._2_base_viajes_top_lineas 
			WHERE TieneCombinacion = 0
			GROUP BY
				hora, id_linea, nombre_linea, empresa
		) AS Subquery
		WHERE NroFila <= 10;';
		EXEC sp_executesql @sql; 

		-- 31. Linea mas utilizada por Distancia Horario | _2_2_2_top_linea_mas_utilizadas_Distancia_horario_tc_1
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_2_top_linea_mas_utilizadas_Distancia_horario_tc_1;
		SELECT 
			distancia, pico_horario, id_linea, nombre_linea, empresa, CantidadEtapas,
			ROW_NUMBER() OVER (PARTITION BY distancia, pico_horario ORDER BY CantidadEtapas DESC) AS NroFila -- Rankeo
		INTO '+QUOTENAME(@Database)+'.dbo._2_2_2_top_linea_mas_utilizadas_Distancia_horario_tc_1
		FROM (
			SELECT 
				distancia, pico_horario, id_linea, nombre_linea, empresa,
				SUM(CantidadEtapas) AS CantidadEtapas, 
				ROW_NUMBER() OVER (PARTITION BY distancia, pico_horario ORDER BY SUM(CantidadEtapas) DESC) AS NroFila
			FROM '+QUOTENAME(@Database)+'.dbo._2_base_viajes_top_lineas 
			WHERE TieneCombinacion = 0
			GROUP BY
				distancia, pico_horario, id_linea, nombre_linea, empresa
		) AS Subquery
		WHERE NroFila <= 10;';
		EXEC sp_executesql @sql; 

		-- 32. Linea mas utilizada por ModoMultimodal y PicoHorario | _2_2_2_top_linea_mas_utilizadas_ModoMultimodal_PicoHorario_tc_1
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_2_top_linea_mas_utilizadas_ModoMultimodal_PicoHorario_tc_1;
		SELECT 
			ModoMultimodal, pico_horario, id_linea, nombre_linea, empresa, CantidadEtapas,
			ROW_NUMBER() OVER (PARTITION BY ModoMultimodal, pico_horario ORDER BY CantidadEtapas DESC) AS NroFila -- Rankeo
		INTO '+QUOTENAME(@Database)+'.dbo._2_2_2_top_linea_mas_utilizadas_ModoMultimodal_PicoHorario_tc_1
		FROM (
			SELECT 
				ModoMultimodal, pico_horario, id_linea, nombre_linea, empresa,
				SUM(CantidadEtapas) AS CantidadEtapas, 
				ROW_NUMBER() OVER (PARTITION BY ModoMultimodal, pico_horario ORDER BY SUM(CantidadEtapas) DESC) AS NroFila
			FROM '+QUOTENAME(@Database)+'.dbo._2_base_viajes_top_lineas 
			WHERE TieneCombinacion = 0
			GROUP BY
				ModoMultimodal, pico_horario, id_linea, nombre_linea, empresa
		) AS Subquery
		WHERE NroFila <= 10;';
		EXEC sp_executesql @sql; 

		-- 33. Linea mas utilizada por ModoMultimodal y Distancia | _2_2_2_top_linea_mas_utilizadas_ModoMultimodal_Distancia_tc_1
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_2_top_linea_mas_utilizadas_ModoMultimodal_Distancia_tc_1;
		SELECT 
			ModoMultimodal, distancia, id_linea, nombre_linea, empresa, CantidadEtapas,
			ROW_NUMBER() OVER (PARTITION BY ModoMultimodal, distancia ORDER BY CantidadEtapas DESC) AS NroFila -- Rankeo
		INTO '+QUOTENAME(@Database)+'.dbo._2_2_2_top_linea_mas_utilizadas_ModoMultimodal_Distancia_tc_1
		FROM (
			SELECT 
				ModoMultimodal, distancia, id_linea, nombre_linea, empresa,
				SUM(CantidadEtapas) AS CantidadEtapas, 
				ROW_NUMBER() OVER (PARTITION BY ModoMultimodal, distancia ORDER BY SUM(CantidadEtapas) DESC) AS NroFila
			FROM '+QUOTENAME(@Database)+'.dbo._2_base_viajes_top_lineas 
			WHERE TieneCombinacion = 0
			GROUP BY
				ModoMultimodal, distancia, id_linea, nombre_linea, empresa
		) AS Subquery
		WHERE NroFila <= 10;';
		EXEC sp_executesql @sql; 

-- Confirmar transacción
 COMMIT TRANSACTION;

 END TRY
 BEGIN CATCH
 -- Si ocurre un error, revertir la transacción
 ROLLBACK TRANSACTION;
	PRINT 'Error en la transacción: '+ERROR_MESSAGE();
 	PRINT 'Error en la transacción: ' + ERROR_MESSAGE();
    PRINT 'Número de error: ' + CAST(ERROR_NUMBER() AS NVARCHAR(10);
    PRINT 'Procedimiento: ' + ERROR_PROCEDURE();
    PRINT 'Línea: ' + CAST(ERROR_LINE() AS NVARCHAR(10);
 END CATCH;
END;

DROP PROCEDURE _006_1_Viajes_Propios_Grupo_Lineas
CREATE PROCEDURE _006_1_Viajes_Propios_Grupo_Lineas
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

		-- 1. Creo tabla inicial viajes | _1_viajes
		SET @sql = 
			'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._1_viajes;
			SELECT DISTINCT 
				CONCAT(v.IdO, ''---'', v.IdD) AS ParOD, -- Par OD
				v.id_tarjeta, v.id_viaje, v.hora, -- Datos tarjeta
				v.IdO, v.IdD, -- Microzonas
				o.zonas AS z_origen, d.zonas AS z_destino, -- Zona microzonas
				STRING_AGG(CAST(e.id_linea AS NVARCHAR(MAX)), ''-'') WITHIN GROUP (ORDER BY e.id_etapa) AS CombinacionesViaje,
				STRING_AGG(CAST(l.nombre_linea AS NVARCHAR(MAX)), ''-'') WITHIN GROUP (ORDER BY e.id_etapa) AS NombreCombinacion,
				STRING_AGG(CAST(l.modo AS NVARCHAR(MAX)), ''-'') WITHIN GROUP (ORDER BY e.id_etapa) AS ModoCombinacion,
				CAST(v.factor_expansion_linea AS FLOAT) AS ViajesExpandidos,
				CAST(v.tren AS INT) AS tren,
				CAST(v.autobus AS INT) AS autobus,
				CAST(v.metro AS INT) AS metro,
				CAST(v.cant_etapas AS INT) AS cant_etapas,
				CAST(v.distance_h3 AS FLOAT) AS distance_h3,
				CAST(v.distance_osm_drive AS FLOAT) AS distance_osm_drive
			INTO '+QUOTENAME(@Database)+'.dbo._1_viajes
			FROM [Base].[dbo].[viajes] v
			LEFT JOIN [Base].[dbo].[etapas] e ON v.id_tarjeta = e.id_tarjeta AND v.id_viaje = e.id_viaje
			LEFT JOIN [Base].[dbo].[microzonas] o ON v.IdO = o.id
			LEFT JOIN [Base].[dbo].[microzonas] d ON v.IdD = d.id
			WHERE EXISTS (
				SELECT 1
				FROM [Base].[dbo].[etapas] e2
				JOIN #LineaIds li ON e2.id_linea = li.id_linea
				WHERE e2.id_tarjeta = v.id_tarjeta 
					AND e2.id_viaje = v.id_viaje
			);';
		PRINT @sql;
		EXEC sp_executesql @sql;


		-- 2. Borro Base Viajes
		SET @sql = 'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._1_base_viajes;';
		PRINT @sql;
		EXEC sp_executesql @sql;

		-- 3. Creo Base Viajes
		SET @sql = 
		'SELECT DISTINCT 
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
					WHEN (v.tren >= 2 AND v.autobus >= 2 AND v.metro = 0) THEN ''E-TREN+2-COLECTIVO+2''';
		SET @sql = @sql + 
					'WHEN (v.tren >= 1 AND v.autobus = 0 AND v.metro >= 1) THEN ''F-TREN-SUBTE''
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
				END AS distancia,';
		SET @sql = @sql + '
				CASE
					WHEN v.hora BETWEEN 0 AND 7 THEN ''1 - madrugada''
					WHEN v.hora BETWEEN 7 AND 10 THEN ''2 - pico_mañana''
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
		PRINT @sql;
		EXEC sp_executesql @sql;

		-- 4. Borro Viajes inicial
		SET @sql = 'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.[dbo]._1_viajes;';
		PRINT @sql;
		EXEC sp_executesql @sql;

		-- 5. Creo Base Pares OD
		SET @sql = 'DROP TABLE IF EXISTS Base.[dbo].'+QUOTENAME(@BasePares)+';';		
		PRINT @sql;
		EXEC sp_executesql @sql;		

		SET @sql = 
			'SELECT DISTINCT b.ParOD, b.IdO, b.z_origen, b.IdD, b.z_destino
			INTO [Base].[dbo].'+QUOTENAME(@BasePares)+'
			FROM '+QUOTENAME(@Database)+'.[dbo].[_1_base_viajes] b
			WHERE (b.IdO <> '''' OR b.IdO IS NOT NULL) 
			AND (b.IdD <> '''' OR b.IdD IS NOT NULL);';
		PRINT @sql;
		EXEC sp_executesql @sql;		
			
		SET @sql = 'DELETE FROM Base.[dbo].'+QUOTENAME(@BasePares)+' WHERE ParOD = '''' OR ParOD IS NULL;';
		PRINT @sql;
		EXEC sp_executesql @sql;

		-- 6. Zonificacion de Viajes Propios
		SET @sql = 'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._1_base_zonas_unicas_totales;';
		PRINT @sql;
		EXEC sp_executesql @sql;

		SET @sql = 
		'WITH ViajesMultimodales AS (
			SELECT 
				v.ModoMultimodal,
				v.IdO, v.IdD,
				v.z_origen, v.z_destino,
				v.ViajesExpandidos
			FROM '+QUOTENAME(@Database)+'.[dbo]._1_base_viajes v
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
		SET @SQL = @SQL + '
		SELECT 
			o.Zona,
			o.Nombre,
			SUM(COALESCE(o.v_colectivo, 0)+COALESCE(d.v_colectivo, 0))/2 AS v_colectivo,
			SUM(COALESCE(o.v_colectivox2, 0)+COALESCE(d.v_colectivox2, 0))/2 AS v_colectivox2,
			SUM(COALESCE(o.v_colectivox3, 0)+COALESCE(d.v_colectivox3, 0))/2 AS v_colectivox3,
			SUM(COALESCE(o.v_colectivoMas4, 0)+COALESCE(d.v_colectivoMas4, 0))/2 AS v_colectivoMas4,
			SUM(COALESCE(o.v_subte, 0)+COALESCE(d.v_subte, 0))/2 AS v_subte,
			SUM(COALESCE(o.v_subtex2, 0)+COALESCE(d.v_subtex2, 0))/2 AS v_subtex2,
			SUM(COALESCE(o.v_subtex3, 0)+COALESCE(d.v_subtex3, 0))/2 AS v_subtex3,
			SUM(COALESCE(o.v_subteMas4, 0)+COALESCE(d.v_subteMas4, 0))/2 AS v_subteMas4,
			SUM(COALESCE(o.v_tren, 0)+COALESCE(d.v_tren, 0))/2 AS v_tren,
			SUM(COALESCE(o.v_trenx2, 0)+COALESCE(d.v_trenx2, 0))/2 AS v_trenx2,
			SUM(COALESCE(o.v_trenMas3, 0)+COALESCE(d.v_trenMas3, 0))/2 AS v_trenMas3,
			SUM(COALESCE(o.v_colectivo_subte, 0)+COALESCE(d.v_colectivo_subte, 0))/2 AS v_colectivo_subte,
			SUM(COALESCE(o.v_colectivoMas2_subte, 0)+COALESCE(d.v_colectivoMas2_subte, 0))/2 AS v_colectivoMas2_subte,
			SUM(COALESCE(o.v_colectivo_subteMas2, 0)+COALESCE(d.v_colectivo_subteMas2, 0))/2 AS v_colectivo_subteMas2,
			SUM(COALESCE(o.v_colectivoMas2_subteMas2, 0)+COALESCE(d.v_colectivoMas2_subteMas2, 0))/2 AS v_colectivoMas2_subteMas2,
			SUM(COALESCE(o.v_tren_colectivo, 0)+COALESCE(d.v_tren_colectivo, 0))/2 AS v_tren_colectivo,
			SUM(COALESCE(o.v_trenMas2_colectivo, 0)+COALESCE(d.v_trenMas2_colectivo, 0))/2 AS v_trenMas2_colectivo,
			SUM(COALESCE(o.v_tren_colectivoMas2, 0)+COALESCE(d.v_tren_colectivoMas2, 0))/2 AS v_tren_colectivoMas2,
			SUM(COALESCE(o.v_tren_subte, 0)+COALESCE(d.v_tren_subte, 0))/2 AS v_tren_subte,
			SUM(COALESCE(o.v_tren_colectivo_subte, 0)+COALESCE(d.v_tren_colectivo_subte, 0))/2 AS v_tren_colectivo_subte,
			SUM(COALESCE(o.v_totales, 0)+COALESCE(d.v_totales, 0))/2 AS v_totales
		INTO '+QUOTENAME(@Database)+'.[dbo]._1_base_zonas_unicas_totales
		FROM ViajesPorZonaOrigen o
		FULL OUTER JOIN ViajesPorZonaDestino d ON o.Zona = d.Zona 
		GROUP BY o.Zona, o.Nombre
		ORDER BY o.Nombre;';
		PRINT @sql;
		EXEC sp_executesql @sql;

		SET @sql = 'DELETE FROM '+QUOTENAME(@Database)+'.[dbo]._1_base_zonas_unicas_totales WHERE Zona = '''' OR Zona IS NULL;';
		PRINT @sql;
		EXEC sp_executesql @sql;

	-- Confirmar transacción
	COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
 ROLLBACK TRANSACTION;
    PRINT 'Error en la transacción: ' + ERROR_MESSAGE();
    PRINT 'Número de error: ' + CAST(ERROR_NUMBER() AS NVARCHAR(10));
    PRINT 'Procedimiento: ' + ERROR_PROCEDURE();
    PRINT 'Línea: ' + CAST(ERROR_LINE() AS NVARCHAR(10));
 END CATCH;
END;

CREATE PROCEDURE _007_2_Datos_Basicos_Grupo_Lineas
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
				STRING_AGG(CAST(e.id_linea AS NVARCHAR(MAX), ''-'') WITHIN GROUP (ORDER BY e.id_etapa) AS CombinacionesViaje,
				STRING_AGG(CAST(l.nombre_linea AS NVARCHAR(MAX), ''-'') WITHIN GROUP (ORDER BY e.id_etapa) AS NombreCombinacion,
				STRING_AGG(CAST(l.modo AS NVARCHAR(MAX), ''-'') WITHIN GROUP (ORDER BY e.id_etapa) AS ModoCombinacion,
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
				WHEN v.hora BETWEEN 7 AND 10 THEN ''2 - pico_mañana''
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
			WHEN v.hora BETWEEN 7 AND 10 THEN ''2 - pico_mañana''
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

	-- Confirmar transacción
	COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
 ROLLBACK TRANSACTION;
    PRINT 'Error en la transacción: ' + ERROR_MESSAGE();
    PRINT 'Número de error: ' + CAST(ERROR_NUMBER() AS NVARCHAR(10));
    PRINT 'Procedimiento: ' + ERROR_PROCEDURE();
    PRINT 'Línea: ' + CAST(ERROR_LINE() AS NVARCHAR(10));
END CATCH;
END;

USE Base;
SELECT * 
FROM sys.procedures
ORDER BY name



