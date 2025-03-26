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
			v.ParOD, v.h3_o, v.h3_d,
            v.distancia,
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
			v.ParOD, v.distancia, v.h3_o, v.h3_d,
		ORDER BY
			v.ParOD;';
		EXEC sp_executesql @sql;

		-- 2. Calculo agrupado de viajes por ParOD y horario | _2_3_agrupado_corredor_ParOD_horario
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_3_agrupado_corredor_ParOD_horario;
		SELECT 
			v.ParOD, v.distancia,
			v.h3_o, v.h3_d,
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
			v.h3_o, v.h3_d,
			v.hora,v.pico_horario,
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

		-- 6. Calculo distribuci�n de viajes por ModoMultimodal y Combinacion | _2_3_distribucion_corredor_MultiModal_ModoCombinacion
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

		-- 7. Calculo distribuci�n de viajes por Distancia y ModoMultimodal | _2_3_distribucion_corredor_distancia_MultiModal
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

		-- 8. Calculo distribuci�n de viajes por ModoMultimodal, Combinacion y horario | _2_3_distribucion_corredor_MultiModal_ModoCombinacion
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

		-- 9. Calculo distribuci�n de viajes por ModoMultimodal, Combinacion, distancia y horario | _2_3_distribucion_corredor_distancia_ModoMultiModal_Combinacion_distancia_horario
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

		-- 10. Calculo de distribuci�n de viajes por Horario y distancia | _2_3_distribucion_corredor_horario_distancia
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

		-- 11. Calculo de distribuci�n de viajes por horario y modo de combinacion | _2_3_distribucion_corredor_horario_ModoCombinacion
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
			v.ParOD, v.distancia,v.h3_o,v.h3_d, v.ModoMultimodal, v.id_linea, v.nombre_linea, v.empresa,
			COUNT (v.id_linea) AS CantidadEtapas
		INTO '+QUOTENAME(@Database)+'.dbo._2_3_2_etapas_por_linea_porParOD_ModoMultimodal
		FROM '+QUOTENAME(@Database)+'.dbo._2_base_etapas_por_linea_por_ParOD v
		GROUP BY
			v.ParOD, v.h3_o,v.h3_d, v.distancia, v.ModoMultimodal, v.id_linea, v.nombre_linea,	v.empresa
		ORDER BY
			v.ParOD,v.distancia,v.ModoMultimodal;';
		EXEC sp_executesql @sql;

		-- 13. Calculo de etapas de cada linea por ParOD | _2_3_2_etapas_por_linea_porParOD
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_3_2_etapas_por_linea_porParOD;
		SELECT 
			v.ParOD, v.distancia,v.h3_o,v.h3_d, v.id_linea, v.nombre_linea, v.empresa,
			COUNT (v.id_linea) AS CantidadEtapas
		INTO '+QUOTENAME(@Database)+'.dbo._2_3_2_etapas_por_linea_porParOD
		FROM '+QUOTENAME(@Database)+'.dbo._2_base_etapas_por_linea_por_ParOD v
		GROUP BY
			v.ParOD, v.h3_o, v.h3_d, v.distancia, v.id_linea, v.nombre_linea, v.empresa
		ORDER BY
			v.ParOD,v.distancia;';
		EXEC sp_executesql @sql;

		-- 14. Calculo de etapas de cada linea por Distancia | _2_3_2_etapas_por_linea_por_distancia
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_3_2_etapas_por_linea_por_distancia;
		SELECT 
			v.distancia,v.h3_o,v.h3_d, v.id_linea, v.nombre_linea, v.empresa,
			COUNT (v.id_linea) AS CantidadEtapas
		INTO '+QUOTENAME(@Database)+'.dbo._2_3_2_etapas_por_linea_por_distancia
		FROM '+QUOTENAME(@Database)+'.dbo._2_base_etapas_por_linea_por_ParOD v
		GROUP BY
			v.distancia, v.h3_o,v.h3_d, v.id_linea, v.nombre_linea, v.empresa
		ORDER BY
			v.distancia;';
		EXEC sp_executesql @sql;

		-- 15. Calculo de etapas de cada linea por ModoMultimodal | _2_3_2_etapas_por_linea_por_ModoMultimodal
		SET @sql =
			'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_3_2_etapas_por_linea_por_ModoMultimodal;
			SELECT 
				v.ModoMultimodal,v.h3_o,v.h3_d, v.id_linea, v.nombre_linea, v.empresa,
				COUNT (v.id_linea) AS CantidadEtapas
			INTO '+QUOTENAME(@Database)+'.dbo._2_3_2_etapas_por_linea_por_ModoMultimodal
			FROM '+QUOTENAME(@Database)+'.dbo._2_base_etapas_por_linea_por_ParOD v
			GROUP BY
				v.ModoMultimodal, v.h3_o,v.h3_d, v.id_linea, v.nombre_linea,	v.empresa
			ORDER BY
				v.ModoMultimodal;';
		EXEC sp_executesql @sql;

		-- 16. Combinacion de viaje por ParOD | _2_3_1_combinacion_corredor_mas_utilizadas_porParOD
		SET @sql =
			'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_3_1_combinacion_corredor_mas_utilizadas_porParOD;
			SELECT 
				ParOD, distancia, NombreCombinacion, CantidadRepeticiones, SumaViajes,
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
					ParOD, distancia, NombreCombinacion, CantidadRepeticiones,
					SUM(SumaViajes) AS SumaViajes,
					ROW_NUMBER() OVER (PARTITION BY ParOD ORDER BY SUM(SumaViajes) DESC) AS NroFila -- Rankeo
				FROM '+QUOTENAME(@Database)+'.dbo._2_base_combinaciones_por_linea_porParOD
				GROUP BY
					ParOD, distancia,NombreCombinacion, CantidadRepeticiones
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

		-- 17. Combinacion de viaje por ParOD y Modo | _2_3_1_combinacion_corredor_utilizadas_ParOD_Modo
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_3_1_combinacion_corredor_utilizadas_ParOD_Modo;
		SELECT 
			ParOD, NombreCombinacion, distancia, ModoMultimodal, CantidadRepeticiones, SumaViajes,
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
		INTO '+QUOTENAME(@Database)+'.dbo._2_3_1_combinacion_corredor_utilizadas_ParOD_Modo -- Lineas M�s Utilizadas ParOD y Modo
		FROM (
			SELECT 
				ParOD, NombreCombinacion, distancia, CantidadRepeticiones, ModoMultimodal,
				SUM(SumaViajes) AS SumaViajes, 
				ROW_NUMBER() OVER (PARTITION BY ParOD, ModoMultimodal ORDER BY SUM(SumaViajes) DESC) AS NroFila -- Rankeo
			FROM '+QUOTENAME(@Database)+'.dbo._2_base_combinaciones_por_linea_porParOD
			GROUP BY
				ParOD,NombreCombinacion, distancia, ModoMultimodal, CantidadRepeticiones
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

		-- 18. Combinacion de viaje por ParOD y Horario| _2_3_1_combinacion_corredor_utilizadas_ParOD_Horario
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_3_1_combinacion_corredor_utilizadas_ParOD_Horario;
		SELECT 
			ParOD,distancia , ,NombreCombinacion, distancia, pico_horario, CantidadRepeticiones, SumaViajes,
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
		INTO '+QUOTENAME(@Database)+'.dbo._2_3_1_combinacion_corredor_utilizadas_ParOD_Horario -- Lineas M�s Utilizadas ParOD y Modo
		FROM (
			SELECT 
				ParOD,NombreCombinacion, distancia, pico_horario, CantidadRepeticiones,
				SUM(SumaViajes) AS SumaViajes, -- Primero calculo la suma de etapas por par OD
				ROW_NUMBER() OVER (PARTITION BY ParOD, NombreCombinacion,pico_horario ORDER BY SUM(SumaViajes) DESC) AS NroFila -- Rankeo
			FROM '+QUOTENAME(@Database)+'.dbo._2_base_combinaciones_por_linea_porParOD
			GROUP BY
				ParOD,NombreCombinacion, distancia, pico_horario, CantidadRepeticiones
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

		-- 19. Combinacion de viaje por ParOD, Modo y Distancia | _2_3_1_combinacion_corredor_utilizadas_ParOD_Modo_Distancia
		SET @sql =
		'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_3_1_combinacion_corredor_utilizadas_ParOD_Modo_Distancia;
		SELECT 
			ParOD, distancia,NombreCombinacion, ModoMultimodal, CantidadRepeticiones, SumaViajes,
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
		INTO '+QUOTENAME(@Database)+'.dbo._2_3_1_combinacion_corredor_utilizadas_ParOD_Modo_Distancia -- Lineas M�s Utilizadas ParOD y Modo
		FROM (
			SELECT 
				ParOD, NombreCombinacion,distancia, ModoMultimodal, CantidadRepeticiones,
				SUM(SumaViajes) AS SumaViajes, -- Primero calculo la suma de etapas por par OD
				ROW_NUMBER() OVER (PARTITION BY ParOD, ModoMultimodal, distancia ORDER BY SUM(SumaViajes) DESC) AS NroFila -- Rankeo
			FROM '+QUOTENAME(@Database)+'.dbo._2_base_combinaciones_por_linea_porParOD
			GROUP BY
				ParOD,NombreCombinacion, distancia, ModoMultimodal,CantidadRepeticiones
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

		-- 20. Combinacion de viaje por ParOd, Modo, Distancia y Modo | _2_3_1_combinacion_corredor_utilizadas_ParOD_Modo_Distancia_horario
		SET @sql =
			'DROP TABLE IF EXISTS '+QUOTENAME(@Database)+'.dbo._2_3_1_combinacion_corredor_utilizadas_ParOD_Modo_Distancia_horario;
			SELECT 
				ParOD,distancia,NombreCombinacion, ModoMultimodal, pico_horario, CantidadRepeticiones,SumaViajes,
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
			INTO '+QUOTENAME(@Database)+'.dbo._2_3_1_combinacion_corredor_utilizadas_ParOD_Modo_Distancia_horario -- Lineas M�s Utilizadas ParOD y Modo
			FROM (
				SELECT 
					ParOD,NombreCombinacion, distancia, ModoMultimodal, pico_horario, CantidadRepeticiones,
					SUM(SumaViajes) AS SumaViajes, -- Primero calculo la suma de etapas por par OD
					ROW_NUMBER() OVER (PARTITION BY ParOD, ModoMultimodal, distancia, pico_horario ORDER BY SUM(SumaViajes) DESC) AS NroFila -- Rankeo
				FROM '+QUOTENAME(@Database)+'.dbo._2_base_combinaciones_por_linea_porParOD
				GROUP BY
					ParOD,NombreCombinacion, distancia, ModoMultimodal, pico_horario,CantidadRepeticiones
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
		INTO '+QUOTENAME(@Database)+'.dbo._2_3_1_combinacion_corredor_utilizadas_ModoMultimodal -- Lineas M�s Utilizadas ParOD y Modo
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
			INTO '+QUOTENAME(@Database)+'.dbo._2_3_1_combinacion_corredor_utilizadas_horario -- Lineas M�s Utilizadas ParOD y Modo
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
			INTO '+QUOTENAME(@Database)+'.dbo._2_3_1_combinacion_corredor_utilizadas_Distancia_Modo -- Lineas M�s Utilizadas ParOD y Modo
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
		INTO '+QUOTENAME(@Database)+'.dbo._2_3_1_combinacion_corredor_utilizadas_Distancia_Modo_Horario -- Lineas M�s Utilizadas ParOD y Modo
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
		
	-- Confirmar transacci�n
	COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
 ROLLBACK TRANSACTION;
	PRINT 'Error en la transacci�n: ' + ERROR_MESSAGE();
  PRINT 'Numero de error: ' + CAST(ERROR_NUMBER() AS NVARCHAR(10);
  PRINT 'Procedimiento: ' + ERROR_PROCEDURE();
  PRINT 'Linea: ' + CAST(ERROR_LINE() AS NVARCHAR(10);
 END CATCH;
END;