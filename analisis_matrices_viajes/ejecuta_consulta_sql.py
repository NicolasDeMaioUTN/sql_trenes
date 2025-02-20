import pyodbc
import datetime

# Definición de las variables
linea_analisis = 'Mitre_AGG_Prueba'
cod_linea = '430'  # Línea única
base_pares = 'base_OD_' + linea_analisis
usuario = 'Nico'
contraseña = '1234'

# Función para escribir en el log
def escribir_log(mensaje):
    with open("log_procedimientos.txt", "a") as log_file:
        timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        log_file.write(f"{timestamp} - {mensaje}\n")

# Función para escribir en el log
def escribir_log(mensaje):
    with open("log_procedimientos.txt", "a") as log_file:
        timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        log_file.write(f"{timestamp} - {mensaje}\n")

# Función para ejecutar un procedimiento almacenado
def ejecutar_procedimiento(connection, procedimiento, parametros):
    try:
        cursor = connection.cursor()
        cursor.execute(f"USE BASE;")  # Cambiar a la base de datos correcta
        sql = f"EXEC Base.dbo.{procedimiento} {parametros};"
        cursor.execute(sql)
        print(f"Ejecutando: {sql}")
        connection.commit()
        print(f"Procedimiento: {procedimiento} ejecutado con éxito con parámetros {parametros}.")
        cursor.close()
    except Exception as e:
        connection.rollback()
        error_message = f"Error al ejecutar el procedimiento {procedimiento} con parámetros {parametros}. Detalles del error: {str(e)}"
        escribir_log(error_message)
        print(error_message)

# Conexión a SQL Server como administrador (para crear la base de datos y asignar permisos)
conexion = pyodbc.connect(
    r'Driver={ODBC Driver 17 for SQL Server};'
    r'Server=DESKTOP-M88PORG\NICO_SUBE;'
    r'Database=master;'  # Usamos 'master' para crear usuarios
    r'Trusted_Connection=yes;'
)

# Función para asignar permisos al usuario
def asignar_permisos_usuario(conexion, database_name, user_name, password):
    try:
        cursor = conexion.cursor()
        cursor.execute(f"""
        IF NOT EXISTS (SELECT * FROM sys.sql_logins WHERE name = '{user_name}')
        BEGIN
            CREATE LOGIN {user_name} WITH PASSWORD = '{password}';
        END
        """)
        escribir_log(f"Usuario '{user_name}' creado o ya existente.")

        cursor.execute(f"USE {database_name};")

        cursor.execute(f"""
        IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = '{user_name}')
        BEGIN
            CREATE USER {user_name} FOR LOGIN {user_name};
        END
        """)
        escribir_log(f"Usuario '{user_name}' asignado a la base de datos '{database_name}'.")
        print(f"Usuario '{user_name}' asignado a la base de datos '{database_name}'.")
        cursor.execute(f"""
        ALTER ROLE db_owner ADD MEMBER {user_name};
        """)
        escribir_log(f"Permisos asignados a '{user_name}' en la base de datos '{database_name}'.")
        print(f"Permisos asignados a '{user_name}' en la base de datos '{database_name}'.")
        conexion.commit()
        cursor.close()

    except Exception as e:
        conexion.rollback()
        error_message = f"Error al asignar permisos: {e}"
        escribir_log(error_message)
        print(error_message)

# Función para verificar y crear la base de datos si no existe
def crear_base_si_no_existe(connection, database_name):
    try:
        cursor = connection.cursor()
        cursor.execute(f"SELECT name FROM sys.databases WHERE name = '{database_name}'")
        database_exists = cursor.fetchone()
        if not database_exists:
            connection.autocommit = True
            cursor.execute(f"CREATE DATABASE {database_name}")
            escribir_log(f"Base de datos '{database_name}' creada con éxito.")
            print(f"Base de datos '{database_name}' creada con éxito.")
            connection.autocommit = False
        cursor.close()
    except Exception as e:
        error_message = f"Error al verificar o crear la base de datos: {e}"
        escribir_log(error_message)
        print(error_message)
        connection.rollback()

# Crear la base de datos si no existe
crear_base_si_no_existe(conexion, linea_analisis)

# Asignar permisos a un usuario específico en una base de datos específica
asignar_permisos_usuario(conexion, linea_analisis, usuario, contraseña)

# Cerrar la conexión inicial
conexion.close()

# Conexión a la nueva base de datos (ya con permisos asignados)
conexion = pyodbc.connect(
    f'Driver={{ODBC Driver 17 for SQL Server}};'
    f'Server=DESKTOP-M88PORG\\NICO_SUBE;'
    f'Database={linea_analisis};'
    'Trusted_Connection=yes;'
)

escribir_log(f"Conectado a la base de datos '{linea_analisis}'.")

# Lista de procedimientos almacenados y sus parámetros usando las variables
procedimientos = [
    ('_001_1_Viajes_Propios', f"'{linea_analisis}', '{cod_linea}', '{base_pares}'"),
    ('_002_2_Datos_Basicos', f"'{linea_analisis}', '{cod_linea}', '{base_pares}'"),
    ('_003_2_Estadisticas_Corredor', f"'{linea_analisis}', '{cod_linea}', '{base_pares}'"),
    ('_004_2_Estadisticas_Viajes_Alternativos', f"'{linea_analisis}', '{cod_linea}', '{base_pares}'"),
    ('_005_2_Estadisticas_Viajes_Propios_en_el_Corredor', f"'{linea_analisis}', '{cod_linea}', '{base_pares}'")
]

# Ejecutar los procedimientos almacenados en el orden especificado
for procedimiento, parametros in procedimientos:
    ejecutar_procedimiento(conexion, procedimiento, parametros)

# Cerrar la conexión
conexion.close()

"""
    -- Lineas solas
    ('_001_1_Viajes_Propios', f"'{linea_analisis}', '{cod_linea}', '{base_pares}'"),
    ('_002_2_Datos_Basicos', f"'{linea_analisis}', '{cod_linea}', '{base_pares}'"),

    -- Grupo de Lineas
    ('_006_1_Viajes_Propios_Grupo_Lineas', f"'{linea_analisis}', '{cod_linea}', '{base_pares}'"),
    ('_007_2_Datos_Basicos_Grupo_Lineas', f"'{linea_analisis}', '{cod_linea}', '{base_pares}'"),

"""
