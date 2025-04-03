SELECT l.id_linea, l.nombre_linea, l.modo FROM lineas l WHERE l.nombre_linea LIKE '%148%';

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
1250               ROCA_CANUELAS_LOBOS  ok
(512,1160,1161,1162,1250)				   ROCA_AGG				ok
(428,429,430,431,1146)						   MITRE_AGG			ok

// COLECTIVOS

919                BSAS_LINEA_136       Linea136    ok
114                BSAS_LINEA_088       Linea88     ok
102                BSAS_LINEA_046       Linea46     ok
124                BSAS_LINEA_148       Linea148    ok
109                BSAS_LINEA_070       Linea70     ok
143                BSAS_LINEA_029       Linea29     ok
68                 BSAS_LINEA_110       Linea110    ok  
132                BSAS_LINEA_178       Linea178    ok
916                BSAS_LINEA_174       Linea174    ok
149                BSAS_LINEA_051       Linea51     ok      
1263               LINEA_164_AMBA       Linea164    ok
154                BSAS_LINEA_080       Linea80     ok
91                 BSAS_LINEA_087       Linea87     ok
44                 BSAS_LINEA_135       Linea135    ok
141                BSAS_LINEA_002       Linea2      ok
1156               BSAS_LINEA_143       Linea143    ok
34                 LINEA 101            Linea101    ok
133                BSAS_LINEA_168       Linea168    ok
135                BSAS_LINEA_176       Linea176    ok
621                BSAS_LINEA_124       Linea 124   ok
1152               BSAS_LINEA_114       Linea114    ok
153                BSAS_LINEA_079       Linea79     ok
172                BSAS_LINEA_177       Linea177    ok
37                 LINEA 8              Linea8      ok
1253               BSAS_LINEA_133       Linea133    ok
45                 BSAS_LINEA_150       Linea150    ok
138                BSAS_LINEA_182       Linea182    ok
920                BSAS_LINEA_163       Linea163    ok
923                BSAS_LINEA_153       Linea153    ok


*/
CREATE DATABASE MITRE;   
EXEC BASE.DBO._001_1_Viajes_Propios_h3 'MITRE','428','Base_MITRE'
EXEC BASE.DBO._002_2_Datos_Basicos_h3 'MITRE','428','Base_MITRE'
EXEC BASE.DBO._003_2_Estadisticas_Corredor_h3 'MITRE','428','Base_MITRE'
EXEC BASE.DBO._004_2_Estadisticas_Viajes_Alternativos_h3 'MITRE','428','Base_MITRE'
EXEC BASE.DBO._005_2_Estadisticas_Viajes_Propios_en_el_Corredor_3 'MITRE','428','Base_MITRE'

CREATE DATABASE MITRE_AGG 
EXEC BASE.DBO._001_1_Viajes_Propios 'MITRE_AGG','428,429,430,431,1146','Base_OD_MITRE_AGG'
EXEC BASE.DBO._002_2_Datos_Basicos 'MITRE_AGG','428,429,430,431,1146','Base_OD_MITRE_AGG'
EXEC BASE.DBO._003_2_Estadisticas_Corredor 'MITRE_AGG','428,429,430,431,1146','Base_OD_MITRE_AGG'
EXEC BASE.DBO._006_1_Viajes_Propios_Grupo_Lineas 'MITRE_AGG','428,429,430,431,1146','Base_OD_MITRE_AGG'
EXEC BASE.DBO._007_2_Datos_Basicos_Grupo_Lineas 'MITRE_AGG','428,429,430,431,1146','Base_OD_MITRE_AGG'