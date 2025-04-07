SELECT *
  FROM [Hex_Procrear].[dbo].[_1_base_viajes]
WHERE [h3_d] <> ''


-- First add the columns if they don't exist
ALTER TABLE BASE.DBO.etapas_2024_11_16
ADD distance_osm_drive FLOAT NULL,
    distance_h3 FLOAT NULL;

-- Then update the values
UPDATE e
SET e.distance_osm_drive = d.distance_osm_drive,
    e.distance_h3 = d.distance_h3
FROM BASE.DBO.etapas_2024_11_16 e
LEFT JOIN BASE.DBO.distancias_2024_11_16 d 
    ON d.h3_o = e.h3_o AND d.h3_d = e.h3_d;



-- First add the columns if they don't exist
ALTER TABLE BASE.DBO.viajes_2024_11_16
ADD distance_osm_drive FLOAT NULL,
    distance_h3 FLOAT NULL;

-- Then update the values using a subquery with SUM
UPDATE v
SET v.distance_osm_drive = e_sum.osm_sum,
    v.distance_h3 = e_sum.h3_sum
FROM BASE.DBO.viajes_2024_11_16 v
JOIN (
    SELECT 
        id_tarjeta, 
        id_viaje,
        SUM(CAST (distance_osm_drive AS FLOAT)) AS osm_sum,
        SUM(CAST (distance_h3 AS FLOAT)) AS h3_sum
    FROM [Base].[dbo].[etapas]
    GROUP BY id_tarjeta, id_viaje
) e_sum ON v.id_tarjeta = e_sum.id_tarjeta AND v.id_viaje = e_sum.id_viaje;

--
SELECT *
FROM BASE.DBO.viajes_2024_11_16 v



UPDATE e
SET e.distance_osm_drive = d.distance_osm_drive,
    e.distance_h3 = d.distance_h3
FROM BASE.DBO.viajes_2024_11_16 e
LEFT JOIN BASE.DBO.distancias_2024_11_16 d 
    ON d.h3_o = e.h3_o AND d.h3_d = e.h3_d
WHERE e.distance_h3 = '' AND e.h3_d <> '';
