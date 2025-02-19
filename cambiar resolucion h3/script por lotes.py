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

def actualizar_tabla_por_lotes(db_url, tabla, campo_hexagonos_9, campo_hexagonos_8, batch_size=100000):
    """
    Actualiza la tabla en la base de datos agregando el campo de hexágonos de resolución 8 por lotes.

    :param db_url: URL de conexión a la base de datos.
    :param tabla: Nombre de la tabla que contiene los hexágonos en resolución 9.
    :param campo_hexagonos_9: Nombre del campo que contiene los hexágonos en resolución 9.
    :param campo_hexagonos_8: Nombre del campo que se añadirá para almacenar los hexágonos en resolución 8.
    :param batch_size: Tamaño del lote a procesar en cada iteración.
    """
    # Conectar a la base de datos (SQL Server)
    engine = create_engine(db_url)
    
    offset = 0
    while True:
        # Leer los registros por lote (limitar a `batch_size` registros)
        query = f"""
        SELECT id, {campo_hexagonos_9} 
        FROM {tabla} 
        ORDER BY id
        OFFSET {offset} ROWS 
        FETCH NEXT {batch_size} ROWS ONLY;
        """
        df = pd.read_sql(query, engine)

        # Si no hay registros, terminar el ciclo
        if df.empty:
            break
        
        # Convertir los hexágonos de resolución 9 a 8
        df[campo_hexagonos_8] = convertir_hexagonos_resolucion_9_a_8(df[campo_hexagonos_9].tolist())

        # Crear un dataframe con los id y los hexágonos de resolución 8
        df_update = df[['id', campo_hexagonos_8]]

        # Generar la instrucción SQL de actualización por lote
        update_query = f"""
        UPDATE {tabla}
        SET {campo_hexagonos_8} = t.{campo_hexagonos_8}
        FROM {tabla} AS t
        INNER JOIN (VALUES 
        {', '.join([f"({row['id']}, '{row[campo_hexagonos_8]}')" for _, row in df_update.iterrows()])}) AS batch(id, {campo_hexagonos_8})
        ON {tabla}.id = batch.id;
        """

        # Ejecutar la actualización por lote
        with engine.connect() as conn:
            conn.execute(update_query)

        # Incrementar el offset para la siguiente iteración
        offset += batch_size

# Uso del script
db_url = 'mssql+pyodbc://usuario:contraseña@servidor/nombre_db?driver=ODBC+Driver+17+for+SQL+Server'  # Cambia esto a tu URL de conexión
tabla = 'tu_tabla'  # Nombre de la tabla
campo_hexagonos_9 = 'hexagon_resolucion_9'  # Campo que contiene los hexágonos en resolución 9
campo_hexagonos_8 = 'hexagon_resolucion_8'  # Campo donde se guardarán los hexágonos en resolución 8
batch_size = 100000  # Lote de 100,000 registros

# Actualizar la tabla por lotes con los hexágonos convertidos
actualizar_tabla_por_lotes(db_url, tabla, campo_hexagonos_9, campo_hexagonos_8, batch_size)
