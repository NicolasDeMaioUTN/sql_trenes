import os
import pandas as pd
from sqlalchemy import create_engine
import logging
from datetime import datetime
from openpyxl import load_workbook

SERVER = r'DESKTOP-M88PORG\NICO_SUBE'
DATABASE = 'Linea48'
ESQUEMA = 'dbo'
directorio_destino = r'Z:\Analisis Urbantrips\Descarga'

# Configuración del logging
logging.basicConfig(
    filename='exportacion_tablas.log',
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
)

console_handler = logging.StreamHandler()
console_handler.setLevel(logging.INFO)
console_handler.setFormatter(logging.Formatter('%(asctime)s - %(levelname)s - %(message)s'))
logging.getLogger().addHandler(console_handler)

# Obtener la fecha y hora actual
fecha_hora_actual = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")

def eliminar_columnas_int_con_zeros(df):
    columnas_a_eliminar = [col for col in df.select_dtypes(include='float').columns if (df[col] == 0).all()]
    df = df.drop(columns=columnas_a_eliminar)
    return df



# Crear la subcarpeta del esquema
subcarpeta_destino = os.path.join(directorio_destino, DATABASE, DATABASE + ' - ' + fecha_hora_actual)
if not os.path.exists(subcarpeta_destino):
    os.makedirs(subcarpeta_destino)
    logging.info(f"Se creó la subcarpeta del esquema: {subcarpeta_destino}")

# Definir las carpetas principales y subcarpetas
estructura_carpetas = {
    "1 - Viajes Propios": [],
    "2 - Viajes Alternativos": [
        "a - Viajes del Corredor",
        "b - Viajes Alternativos",
        "c - Viajes Propios en el Corredor"
    ],
    "3 - Analisis de Zonas": []
}

subcarpetas_adicionales = {
    "c - Viajes Propios en el Corredor": [
        "a - Linea mas utilizada por cantidad de etapas",
        "b - Combinacion de viaje mas utilizada"
    ],
    "b - Viajes Alternativos": [
        "a - Linea mas utilizada por cantidad de etapas",
        "b - Combinacion de viaje mas utilizada"
    ]
}

# Crear la estructura de carpetas
for carpeta, subcarpetas in estructura_carpetas.items():
    ruta_carpeta = os.path.join(subcarpeta_destino, carpeta)
    if not os.path.exists(ruta_carpeta):
        os.makedirs(ruta_carpeta)
        logging.info(f"Se creó la carpeta: {ruta_carpeta}")
    
    for subcarpeta in subcarpetas:
        ruta_subcarpeta = os.path.join(ruta_carpeta, subcarpeta)
        if not os.path.exists(ruta_subcarpeta):
            os.makedirs(ruta_subcarpeta)
            logging.info(f"Se creó la subcarpeta: {ruta_subcarpeta}")

        # Crear subcarpetas adicionales para "a - Viajes del Corredor" y "b - Viajes Alternativos"
        if subcarpeta in subcarpetas_adicionales:
            for subsubcarpeta in subcarpetas_adicionales[subcarpeta]:
                ruta_subsubcarpeta = os.path.join(ruta_subcarpeta, subsubcarpeta)
                if not os.path.exists(ruta_subsubcarpeta):
                    os.makedirs(ruta_subsubcarpeta)
                    logging.info(f"Se creó la subsubcarpeta: {ruta_subsubcarpeta}")

def obtener_ruta_destino(tabla_nombre):
    """
    Devuelve la ruta de destino según el prefijo del nombre de la tabla.
    """
    if tabla_nombre.startswith("_1_"):
        return os.path.join(subcarpeta_destino, "1 - Viajes Propios")
    elif tabla_nombre.startswith("_2_1_1_"):
        return os.path.join(subcarpeta_destino, "2 - Viajes Alternativos", "c - Viajes Propios en el Corredor","b - Combinacion de viaje mas utilizada")
    elif tabla_nombre.startswith("_2_1_2_"):
        return os.path.join(subcarpeta_destino, "2 - Viajes Alternativos", "c - Viajes Propios en el Corredor","a - Linea mas utilizada por cantidad de etapas")
    elif tabla_nombre.startswith("_2_1_"):
        return os.path.join(subcarpeta_destino, "2 - Viajes Alternativos", "c - Viajes Propios en el Corredor")
    elif tabla_nombre.startswith("_2_2_1_"):
        return os.path.join(subcarpeta_destino, "2 - Viajes Alternativos", "b - Viajes Alternativos","b - Combinacion de viaje mas utilizada")
    elif tabla_nombre.startswith("_2_2_2_"):
        return os.path.join(subcarpeta_destino, "2 - Viajes Alternativos", "b - Viajes Alternativos","a - Linea mas utilizada por cantidad de etapas")
    elif tabla_nombre.startswith("_2_2_"):
        return os.path.join(subcarpeta_destino, "2 - Viajes Alternativos", "b - Viajes Alternativos")
    elif tabla_nombre.startswith("_2_3_"):
        return os.path.join(subcarpeta_destino, "2 - Viajes Alternativos", "a - Viajes del Corredor")
    elif tabla_nombre.startswith("_3_"):
        return os.path.join(subcarpeta_destino, "3 - Analisis de Zonas")
    else:
        return subcarpeta_destino  # Ruta por defecto si no coincide con ningún prefijo

connection_string = f"mssql+pyodbc://{SERVER}/{DATABASE}?driver=ODBC+Driver+17+for+SQL+Server"
engine = create_engine(connection_string)

try:
    with engine.connect() as connection:
        logging.info("Conexión exitosa con la base de datos.")
except Exception as e:
    logging.error(f"Error al conectar con la base de datos: {e}")
    raise

try:
    query_tablas = f"""
        SELECT TABLE_NAME
        FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_SCHEMA = '{ESQUEMA}'
        ORDER BY TABLE_NAME
    """
    tablas = pd.read_sql(query_tablas, engine)['TABLE_NAME'].tolist()
    logging.info(f"Se obtuvieron {len(tablas)} tablas del esquema '{DATABASE}.{ESQUEMA}'.")
except Exception as e:
    logging.error(f"Error al obtener las tablas del esquema '{DATABASE}.{ESQUEMA}': {e}")
    raise

# Exportar cada tabla en un archivo Excel independiente
for tabla in tablas:
    try:
        logging.info(f"Iniciando la exportación de la tabla '{tabla}' a las {fecha_hora_actual}...")
        
        # Obtener la ruta de destino basada en el nombre de la tabla
        carpeta_destino = obtener_ruta_destino(tabla)
        ruta_exportacion = os.path.join(carpeta_destino, f"{tabla}.xlsx")

        # Asegurarse de que la carpeta de destino existe
        if not os.path.exists(carpeta_destino):
            os.makedirs(carpeta_destino)
            logging.info(f"Se creó la carpeta de destino: {carpeta_destino}")

        # Leer los datos de la tabla con el esquema especificado
        query = f"SELECT * FROM {ESQUEMA}.{tabla}"
        df = pd.read_sql(query, engine)

        # Eliminar las columnas con tipo int y valores iguales a cero
        df = eliminar_columnas_int_con_zeros(df)

        # Guardar el DataFrame en un archivo Excel
        df.to_excel(ruta_exportacion, index=False)

        # Abrir el archivo Excel con openpyxl
        wb = load_workbook(ruta_exportacion)
        ws = wb.active

        # Inmovilizar la primera fila
        ws.freeze_panes = 'A2'

        # Aplicar un filtro a todas las columnas
        ws.auto_filter.ref = ws.dimensions  # Se aplica el filtro a todas las columnas con datos

        # Guardar el archivo modificado
        wb.save(ruta_exportacion)

        logging.info(f"Tabla '{tabla}' exportada exitosamente a '{ruta_exportacion}' a las {fecha_hora_actual}.")
    except Exception as e:
        logging.error(f"Error al exportar la tabla '{tabla}': {e}")

print(f"Todas las tablas del esquema '{DATABASE}.{ESQUEMA}' han sido exportadas a la subcarpeta '{subcarpeta_destino}' con fecha y hora '{fecha_hora_actual}'.")
logging.info(f"Proceso de exportación completado para el esquema '{DATABASE}.{ESQUEMA}' a la hora {fecha_hora_actual}.")
