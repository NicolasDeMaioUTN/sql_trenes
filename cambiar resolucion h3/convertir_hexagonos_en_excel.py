import pandas as pd
import h3

# Cargar el archivo Excel con todas las hojas
archivo_excel = r"Z:\Viajes por Hexagono.xlsx"
df_sheets = pd.read_excel(archivo_excel, sheet_name=None, dtype=str)  # Cargar todas las hojas con datos como strings

def convertir_h3_a_res8(h3_res9):
    """Convierte un hexágono de resolución 9 a resolución 8."""
    if pd.notna(h3_res9):  # Verifica que no sea NaN
        h3_res9 = str(h3_res9).strip()  # Asegura que es string y limpia espacios
        if h3.is_valid_cell(h3_res9):  # Verifica que sea un hexágono válido
            return h3.cell_to_parent(h3_res9, 8)  # Convierte a resolución 8
    return None  # Si no es válido, retorna None

# Procesar todas las hojas del archivo
for sheet_name, df in df_sheets.items():
    if 'h3_o_Res9' in df.columns:  
        df['h3_o_Res8'] = df['h3_o_Res9'].apply(convertir_h3_a_res8)  # Agregamos sin borrar h3_o_Res9
        print(f"✔ Procesada la hoja: {sheet_name}")

# Guardar el archivo con todas las hojas actualizadas
archivo_salida = "archivo_actualizado.xlsx"
with pd.ExcelWriter(archivo_salida, engine='openpyxl') as writer:
    for sheet_name, df in df_sheets.items():
        df.to_excel(writer, sheet_name=sheet_name, index=False)

print(f"✅ Conversión completada. Archivo guardado como '{archivo_salida}'.")
