# pip install pandas sqlalchemy pyodbc h3

import pandas as pd
from sqlalchemy import create_engine
import h3

def convertir_hexagonos_resolucion_9_a_8(hexagonos_resolucion_9):
    """
    Convierte una lista de hexágonos H3 de resolución 9 a resolución 8.

    :param hexagonos_resolucion_9: Lista de hexágonos en resolución 9 (como cadenas hexadecimales)
    :return: Lista de hexágonos en resolución 8
    """
    hexagonos_resolucion_8 = []

    for hexagon in hexagonos_resolucion_9:
        # Convertir el hexágono H3 de resolución 9 a resolución 8
        hex_resolucion_8 = h3.h3_to_parent(hexagon, 8)
        hexagonos_resolucion_8.append(hex_resolucion_8)

    return hexagonos_resolucion_8

def actualizar_tabla_con_hexagonos_resolucion_8(db_url, tabla, campo_hexagonos_9, campo_hexagonos_8):
    """
    Actualiza la tabla en la base de datos agregando el campo de hexágonos de resolución 8.

    :param db_url: URL de conexión a la base de datos.
    :param tabla: Nombre de la tabla que contiene los hexágonos en resolución 9.
    :param campo_hexagonos_9: Nombre del campo que contiene los hexágonos en resolución 9.
    :param campo_hexagonos_8: Nombre del campo que se añadirá para almacenar los hexágonos en resolución 8.
    """
    # Conectar a la base de datos (SQL Server)
    engine = create_engine(db_url)
    
    # Leer los hexágonos de la tabla
    query = f"SELECT id, {campo_hexagonos_9} FROM {tabla}"
    df = pd.read_sql(query, engine)

    # Convertir los hexágonos de resolución 9 a 8
    df[campo_hexagonos_8] = convertir_hexagonos_resolucion_9_a_8(df[campo_hexagonos_9].tolist())

    # Actualizar la tabla con los nuevos hexágonos de resolución 8
    with engine.connect() as conn:
        for idx, row in df.iterrows():
            # Realizar un UPDATE para cada fila
            query_update = f"""
            UPDATE {tabla}
            SET {campo_hexagonos_8} = '{row[campo_hexagonos_8]}'
            WHERE id = {row['id']}
            """
            conn.execute(query_update)

# Uso del script
db_url = 'mssql+pyodbc://usuario:contraseña@servidor/nombre_db?driver=ODBC+Driver+17+for+SQL+Server'  # Cambia esto a tu URL de conexión
tabla = 'tu_tabla'  # Nombre de la tabla
campo_hexagonos_9 = 'hexagon_resolucion_9'  # Campo que contiene los hexágonos en resolución 9
campo_hexagonos_8 = 'hexagon_resolucion_8'  # Campo donde se guardarán los hexágonos en resolución 8

# Actualizar la tabla con los hexágonos convertidos
actualizar_tabla_con_hexagonos_resolucion_8(db_url, tabla, campo_hexagonos_9, campo_hexagonos_8)
