USE Base
/*
id_linea		   Nombre_linea                                   
---------		   ------------------------
427                SARMIENTO			ok                                   
428                MITRE				ok                           
429                SUAREZ				ok                             
430                MITRE_TIGRE			ok                            
431                MITRE_ZARATE			ok
447                URQUIZA				ok                                     
348                BELGRANO_SUR			ok                           
512                ROCA					ok                            
350                SAN_MARTIN			ok                             
458                BELGRANO_NORTE		ok                             
1146               MITRE_CAPILLA		ok                             
1160               ROCA_UNIVERSITARIO	ok                           
1161               ROCA_CANUELAS_MONTE  ok                        
1162               ROCA_KORN_CHASCOMUS  ok                        
1250               ROCA_CANUELAS_LOBOS  

(512,1160,1161,1162,1250)				   ROCA_AGG				ok
(428,430,431,1146)						   MITRE_AGG			ok

*/
CREATE DATABASE MITRE;   
EXEC BASE.DBO._001_1_Viajes_Propios 'MITRE','428','Base_MITRE'
EXEC BASE.DBO._002_2_Datos_Basicos 'MITRE','428','Base_MITRE'
EXEC BASE.DBO._003_2_Estadisticas_Corredor 'MITRE','428','Base_MITRE'
EXEC BASE.DBO._004_2_Estadisticas_Viajes_Alternativos 'MITRE','428','Base_MITRE'
EXEC BASE.DBO._005_2_Estadisticas_Viajes_Propios_en_el_Corredor 'MITRE','428','Base_MITRE'

CREATE DATABASE MITRE_AGG 
EXEC BASE.DBO._001_1_Viajes_Propios 'MITRE_AGG','428,430,431,1146','Base_OD_MITRE_AGG'
EXEC BASE.DBO._002_2_Datos_Basicos 'MITRE_AGG','428,430,431,1146','Base_OD_MITRE_AGG'
EXEC BASE.DBO._003_2_Estadisticas_Corredor 'MITRE_AGG','428,430,431,1146','Base_OD_MITRE_AGG'
EXEC BASE.DBO._006_1_Viajes_Propios_Grupo_Lineas 'MITRE_AGG','428,430,431,1146','Base_OD_MITRE_AGG'
EXEC BASE.DBO._007_2_Datos_Basicos_Grupo_Lineas 'MITRE_AGG','428,430,431,1146','Base_OD_MITRE_AGG'