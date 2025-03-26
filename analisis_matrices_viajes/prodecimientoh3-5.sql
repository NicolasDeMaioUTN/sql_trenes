CREATE PROCEDURE _005_2_Estadisticas_Viajes_Propios_en_el_Corredor
 @Database NVARCHAR(15), -- Par�metro de entrada para la base de datos
 @IdLinea NVARCHAR(50),
 @BasePares NVARCHAR(20) -- Nombre de la base de pares a crear
AS
BEGIN
	DECLARE @sql NVARCHAR(MAX);
 	BEGIN TRY
	-- Inicia la transacci�n
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
			v.h3_o, v.h3_d,			
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
			v.ParOD, v.h3_o, v.h3_d
		ORDER BY
			v.ParOD;';
		EXEC sp_executesql @sql;

		-- 3. Calculo agrupado de viajes por ParOD y horario | _2_2_agrupado_ParOD_horario_tc_1
		SET @sql =
			'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_agrupado_ParOD_horario_tc_1;
			SELECT 
				v.ParOD, v.distancia,
				v.h3_o, v.h3_d,				
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
			v.h3_o, v.h3_d,
			v.hora,v.pico_horario			
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

		-- 7. Calculo distribuci�n de viajes por ModoMultimodal y Combinacion | _2_2_distribucion_MultiModal_ModoCombinacion_tc_1
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

		-- 8. Calculo distribuci�n de viajes por Distancia y ModoMultimodal | _2_2_distribucion_distancia_MultiModal_tc_1
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

		-- 9. Calculo distribuci�n de viajes por ModoMultimodal, Combinacion y horario | _2_2_distribucion_distancia_ModoMultiModal_Combinacion_horario_tc_1
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

		-- 10. Calculo distribuci�n de viajes por ModoMultimodal, Combinacion, distancia y horario | _2_2_distribucion_distancia_ModoMultiModal_Combinacion_distancia_horario_0
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

		-- 11. Calculo de distribuci�n de viajes por Horario y distancia | _2_2_distribucion_horario_distancia_tc_1
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

		-- 12. Calculo de distribuci�n de viajes por horario y modo de combinacion | _2_2_distribucion_horario_ModoCombinacion_tc_1
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
			v.ParOD, v.distancia,v.h3_o,v.h3_d,  v.ModoMultimodal, v.id_linea, v.nombre_linea, v.empresa,
			COUNT (v.id_linea) AS CantidadEtapas
		INTO '+QUOTENAME(@Database)+'.dbo._2_2_2_etapas_por_linea_porParOD_ModoMultimodal_tc_1
		FROM '+QUOTENAME(@Database)+'.dbo._2_base_etapas_por_linea_por_ParOD_tc_1 v
		GROUP BY
			v.ParOD, v.h3_o,v.h3_d,  v.distancia, v.ModoMultimodal, v.id_linea, v.nombre_linea,	v.empresa
		ORDER BY
			v.ParOD,v.distancia,v.ModoMultimodal;';
		EXEC sp_executesql @sql;

		-- 14. Calculo de etapas de cada linea por ParOD | _2_2_2_etapas_por_linea_porParOD_tc_1
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_2_etapas_por_linea_porParOD_tc_1;
		SELECT 
			v.ParOD, v.distancia,v.h3_o,v.h3_d,  v.id_linea, v.nombre_linea, v.empresa,
			COUNT (v.id_linea) AS CantidadEtapas
		INTO '+QUOTENAME(@Database)+'.dbo._2_2_2_etapas_por_linea_porParOD_tc_1
		FROM '+QUOTENAME(@Database)+'.dbo._2_base_etapas_por_linea_por_ParOD_tc_1 v
		GROUP BY
			v.ParOD, v.h3_o,v.h3_d,  v.distancia, v.id_linea, v.nombre_linea,	v.empresa
		ORDER BY
			v.ParOD,v.distancia;';
		EXEC sp_executesql @sql;

		-- 15. Calculo de etapas de cada linea por Distancia | _2_2_2_etapas_por_linea_por_distancia_tc_1
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_2_etapas_por_linea_por_distancia_tc_1;
		SELECT 
			v.distancia,v.h3_o,v.h3_d,  v.id_linea, v.nombre_linea, v.empresa,
			COUNT (v.id_linea) AS CantidadEtapas
		INTO '+QUOTENAME(@Database)+'.dbo._2_2_2_etapas_por_linea_por_distancia_tc_1
		FROM '+QUOTENAME(@Database)+'.dbo._2_base_etapas_por_linea_por_ParOD_tc_1 v
		GROUP BY
			v.distancia, v.h3_o,v.h3_d,  v.id_linea, v.nombre_linea,	v.empresa
		ORDER BY
			v.distancia;';
		EXEC sp_executesql @sql;

		-- 16. Calculo de etapas de cada linea por ModoMultimodal | _2_2_2_etapas_por_linea_por_ModoMultimodal_tc_1
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_2_etapas_por_linea_por_ModoMultimodal_tc_1;
		SELECT 
			v.ModoMultimodal,v.h3_o,v.h3_d,  v.id_linea, v.nombre_linea, v.empresa,
			COUNT (v.id_linea) AS CantidadEtapas
		INTO '+QUOTENAME(@Database)+'.dbo._2_2_2_etapas_por_linea_por_ModoMultimodal_tc_1
		FROM '+QUOTENAME(@Database)+'.dbo._2_base_etapas_por_linea_por_ParOD_tc_1 v
		GROUP BY
			v.ModoMultimodal, v.h3_o,v.h3_d,  v.id_linea, v.nombre_linea,	v.empresa
		ORDER BY
			v.ModoMultimodal;';
		EXEC sp_executesql @sql;

		-- 17. Combinacion de viaje por ParOD | _2_2_1_combinacion_mas_utilizadas_porParOD_tc_1
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_2_1_combinacion_mas_utilizadas_porParOD_tc_1;
		SELECT 
			ParOD, distancia,  NombreCombinacion, CantidadRepeticiones, SumaViajes,
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
				ParOD, distancia,   NombreCombinacion, CantidadRepeticiones,
				SUM(SumaViajes) AS SumaViajes, -- Primero calculo la suma de etapas por par OD,
				ROW_NUMBER() OVER (PARTITION BY ParOD ORDER BY SUM(SumaViajes) DESC) AS NroFila -- Rankeo
			FROM '+QUOTENAME(@Database)+'.dbo._2_2_base_combinaciones_por_linea_porParOD_tc_1
			GROUP BY
				ParOD,   distancia,NombreCombinacion, CantidadRepeticiones
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
			-- Dividir NombreCombinacion en la s�ptima parte
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
			ParOD,   NombreCombinacion, distancia, ModoMultimodal, CantidadRepeticiones, SumaViajes,
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
		INTO '+QUOTENAME(@Database)+'.dbo._2_2_1_combinacion_utilizadas_ParOD_Modo_tc_1 -- Lineas M�s Utilizadas ParOD y Modo
		FROM (
			SELECT 
				ParOD,   NombreCombinacion, distancia, CantidadRepeticiones, ModoMultimodal,
				SUM(SumaViajes) AS SumaViajes, 
				ROW_NUMBER() OVER (PARTITION BY ParOD, ModoMultimodal ORDER BY SUM(SumaViajes) DESC) AS NroFila -- Rankeo
			FROM '+QUOTENAME(@Database)+'.dbo._2_2_base_combinaciones_por_linea_porParOD_tc_1
			GROUP BY
				ParOD,  NombreCombinacion, distancia, ModoMultimodal, CantidadRepeticiones
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
			-- Dividir NombreCombinacion en la s�ptima parte
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
				ParOD,distancia  NombreCombinacion, distancia, pico_horario, CantidadRepeticiones, SumaViajes,
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
			INTO '+QUOTENAME(@Database)+'.dbo._2_2_1_combinacion_utilizadas_ParOD_Horario_tc_1 -- Lineas Mas Utilizadas ParOD y Modo
			FROM (
				SELECT 
					ParOD,  NombreCombinacion, distancia, pico_horario, CantidadRepeticiones,
					SUM(SumaViajes) AS SumaViajes, -- Primero calculo la suma de etapas por par OD
					ROW_NUMBER() OVER (PARTITION BY ParOD, NombreCombinacion,pico_horario ORDER BY SUM(SumaViajes) DESC) AS NroFila -- Rankeo
				FROM '+QUOTENAME(@Database)+'.dbo._2_2_base_combinaciones_por_linea_porParOD_tc_1
				GROUP BY
					ParOD,  NombreCombinacion, distancia, pico_horario, CantidadRepeticiones
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
			-- Dividir NombreCombinacion en la s�ptima parte
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
				ParOD, distancia,  NombreCombinacion, ModoMultimodal, CantidadRepeticiones, SumaViajes,
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
			INTO '+QUOTENAME(@Database)+'.dbo._2_2_1_combinacion_utilizadas_ParOD_Modo_Distancia_tc_1 -- Lineas Mas Utilizadas ParOD y Modo
			FROM (
				SELECT 
					ParOD,   NombreCombinacion,distancia, ModoMultimodal, CantidadRepeticiones,
					SUM(SumaViajes) AS SumaViajes, -- Primero calculo la suma de etapas por par OD
					ROW_NUMBER() OVER (PARTITION BY ParOD, ModoMultimodal, distancia ORDER BY SUM(SumaViajes) DESC) AS NroFila -- Rankeo
				FROM '+QUOTENAME(@Database)+'.dbo._2_2_base_combinaciones_por_linea_porParOD_tc_1
				GROUP BY
					ParOD,  NombreCombinacion, distancia, ModoMultimodal,CantidadRepeticiones
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
			-- Dividir NombreCombinacion en la s�ptima parte
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
				ParOD,distancia,  NombreCombinacion, ModoMultimodal, pico_horario, CantidadRepeticiones,SumaViajes,
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
			INTO '+QUOTENAME(@Database)+'.dbo._2_2_1_combinacion_utilizadas_ParOD_Modo_Distancia_horario_tc_1 -- Lineas M�s Utilizadas ParOD y Modo
			FROM (
				SELECT 
					ParOD,  NombreCombinacion, distancia, ModoMultimodal, pico_horario, CantidadRepeticiones,
					SUM(SumaViajes) AS SumaViajes, -- Primero calculo la suma de etapas por par OD
					ROW_NUMBER() OVER (PARTITION BY ParOD, ModoMultimodal, distancia, pico_horario ORDER BY SUM(SumaViajes) DESC) AS NroFila -- Rankeo
				FROM '+QUOTENAME(@Database)+'.dbo._2_2_base_combinaciones_por_linea_porParOD_tc_1
				GROUP BY
					ParOD,  NombreCombinacion, distancia, ModoMultimodal, pico_horario,CantidadRepeticiones
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
			-- Dividir NombreCombinacion en la s�ptima parte
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
			-- Dividir NombreCombinacion en la s�ptima parte
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
			INTO '+QUOTENAME(@Database)+'.dbo._2_2_1_combinacion_utilizadas_ModoMultimodal_tc_1 -- Lineas M�s Utilizadas ParOD y Modo
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
			-- Dividir NombreCombinacion en la s�ptima parte
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
		INTO '+QUOTENAME(@Database)+'.dbo._2_2_1_combinacion_utilizadas_horario_tc_1 -- Lineas M�s Utilizadas ParOD y Modo
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
				-- Dividir NombreCombinacion en la s�ptima parte
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
		INTO '+QUOTENAME(@Database)+'.dbo._2_2_1_combinacion_utilizadas_Distancia_Modo_tc_1 -- Lineas M�s Utilizadas ParOD y Modo
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
			-- Dividir NombreCombinacion en la s�ptima parte
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
			INTO '+QUOTENAME(@Database)+'.dbo._2_2_1_combinacion_utilizadas_Distancia_Modo_Horario_tc_1 -- Lineas M�s Utilizadas ParOD y Modo
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
			-- Dividir NombreCombinacion en la s�ptima parte
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

		-- Confirmar transacci�n
		COMMIT TRANSACTION;

		END TRY
		BEGIN CATCH
		-- Si ocurre un error, revertir la transacci�n
		ROLLBACK TRANSACTION;
		PRINT 'Error en la transacci�n: '+ERROR_MESSAGE();
		PRINT 'Error en la transacci�n: ' + ERROR_MESSAGE();
		PRINT 'N�mero de error: ' + CAST(ERROR_NUMBER() AS NVARCHAR(10);
		PRINT 'Procedimiento: ' + ERROR_PROCEDURE();
		PRINT 'L�nea: ' + CAST(ERROR_LINE() AS NVARCHAR(10);
		END CATCH;
END;