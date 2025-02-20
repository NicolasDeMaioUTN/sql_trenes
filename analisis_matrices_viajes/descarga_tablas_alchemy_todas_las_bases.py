import os
import pandas as pd
from sqlalchemy import create_engine
import logging
from datetime import datetime
from openpyxl import load_workbook

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

SERVER = r'DESKTOP-M88PORG\NICO_SUBE'
ESQUEMA = 'dbo'
directorio_destino = r'Z:\Analisis Urbantrips\Descarga'

# Lista de bases de datos a procesar
BASES_DE_DATOS = ['SARMIENTO','MITRE','SUAREZ','MITRE_TIGRE','MITRE_ZARATE','URQUIZA','BELGRANO_SUR','ROCA','SAN_MARTIN','BELGRANO_NORTE','MITRE_CAPILLA',
                  'ROCA_UNIVERSITARIO','ROCA_CANUELAS_MONTE','ROCA_KORN_CHASCOMUS','ROCA_CANUELAS_LOBOS','ROCA_AGG','MITRE_AGG']  # Añade los nombres de las bases de datos


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

def obtener_ruta_destino(tabla_nombre, subcarpeta_destino):
    """
    Devuelve la ruta de destino según el prefijo del nombre de la tabla.
    """
    if tabla_nombre.startswith("_1_"):
        return os.path.join(subcarpeta_destino, "1 - Viajes Propios")
    elif tabla_nombre.startswith("_2_1_1_"):
        return os.path.join(subcarpeta_destino, "2 - Viajes Alternativos", "c - Viajes Propios en el Corredor", "b - Combinacion de viaje mas utilizada")
    elif tabla_nombre.startswith("_2_1_2_"):
        return os.path.join(subcarpeta_destino, "2 - Viajes Alternativos", "c - Viajes Propios en el Corredor", "a - Linea mas utilizada por cantidad de etapas")
    elif tabla_nombre.startswith("_2_1_"):
        return os.path.join(subcarpeta_destino, "2 - Viajes Alternativos", "c - Viajes Propios en el Corredor")
    elif tabla_nombre.startswith("_2_2_1_"):
        return os.path.join(subcarpeta_destino, "2 - Viajes Alternativos", "b - Viajes Alternativos", "b - Combinacion de viaje mas utilizada")
    elif tabla_nombre.startswith("_2_2_2_"):
        return os.path.join(subcarpeta_destino, "2 - Viajes Alternativos", "b - Viajes Alternativos", "a - Linea mas utilizada por cantidad de etapas")
    elif tabla_nombre.startswith("_2_2_"):
        return os.path.join(subcarpeta_destino, "2 - Viajes Alternativos", "b - Viajes Alternativos")
    elif tabla_nombre.startswith("_2_3_"):
        return os.path.join(subcarpeta_destino, "2 - Viajes Alternativos", "a - Viajes del Corredor")
    elif tabla_nombre.startswith("_3_"):
        return os.path.join(subcarpeta_destino, "3 - Analisis de Zonas")
    else:
        return subcarpeta_destino  # Ruta por defecto si no coincide con ningún prefijo

# Procesar cada base de datos
for DATABASE in BASES_DE_DATOS:
    logging.info(f"Inicio del proceso para la base de datos: {DATABASE}")
    
    # Crear la subcarpeta para la base de datos actual
    subcarpeta_destino = os.path.join(directorio_destino, DATABASE, DATABASE + ' - ' + fecha_hora_actual)
    if not os.path.exists(subcarpeta_destino):
        os.makedirs(subcarpeta_destino)
        logging.info(f"Se creó la subcarpeta del esquema: {subcarpeta_destino}")

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

            if subcarpeta in subcarpetas_adicionales:
                for subsubcarpeta in subcarpetas_adicionales[subcarpeta]:
                    ruta_subsubcarpeta = os.path.join(ruta_subcarpeta, subsubcarpeta)
                    if not os.path.exists(ruta_subsubcarpeta):
                        os.makedirs(ruta_subsubcarpeta)
                        logging.info(f"Se creó la subsubcarpeta: {ruta_subsubcarpeta}")

    # Crear la conexión para la base de datos actual
    connection_string = f"mssql+pyodbc://{SERVER}/{DATABASE}?driver=ODBC+Driver+17+for+SQL+Server"
    engine = create_engine(connection_string)

    try:
        with engine.connect() as connection:
            logging.info(f"Conexión exitosa con la base de datos {DATABASE}.")
    except Exception as e:
        logging.error(f"Error al conectar con la base de datos {DATABASE}: {e}")
        continue

    try:
        # Obtener las tablas del esquema
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
        continue

    # Exportar cada tabla de la base de datos actual
    for tabla in tablas:
        try:
            logging.info(f"Iniciando la exportación de la tabla '{tabla}'...")
            
            # Obtener la ruta de destino basada en el nombre de la tabla
            carpeta_destino = obtener_ruta_destino(tabla, subcarpeta_destino)
            ruta_exportacion = os.path.join(carpeta_destino, f"{tabla}.xlsx")

            # Leer los datos de la tabla
            query = f"SELECT * FROM {ESQUEMA}.{tabla}"
            df = pd.read_sql(query, engine)

            # Eliminar las columnas con valores float iguales a cero
            df = eliminar_columnas_int_con_zeros(df)

            # Guardar en un archivo Excel
            df.to_excel(ruta_exportacion, index=False)

            # Modificar el archivo Excel con openpyxl
            wb = load_workbook(ruta_exportacion)
            ws = wb.active
            ws.freeze_panes = 'A2'  # Inmovilizar la primera fila
            ws.auto_filter.ref = ws.dimensions  # Filtros
            wb.save(ruta_exportacion)

            logging.info(f"Tabla '{tabla}' exportada exitosamente a '{ruta_exportacion}'.")
        except Exception as e:
            logging.error(f"Error al exportar la tabla '{tabla}': {e}")

    logging.info(f"Proceso de exportación completado para la base de datos '{DATABASE}'.")

print("Proceso de exportación finalizado.")
