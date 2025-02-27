from flask import Flask, request, jsonify
import requests

app = Flask(__name__)

# Endpoint para obtener líneas disponibles
@app.route('/api/lineas', methods=['GET'])
def get_lineas():
    # Consulta a la base de datos para obtener las líneas únicas
    lineas = ["Línea 1", "Línea 2", "Línea 3"]  # Ejemplo
    return jsonify({"lineas": lineas})

# Endpoint para filtrar shapes
@app.route('/api/filtrar', methods=['POST'])
def filtrar_shapes():
    data = request.json
    lineas = data.get("lineas", [])
    empresas = data.get("empresas", [])
    ramales = data.get("ramales", [])

    # Construir el filtro CQL
    cql_filter = []
    if lineas:
        cql_filter.append(f"linea IN ({','.join([f'\"{l}\"' for l in lineas])})")
    if empresas:
        cql_filter.append(f"empresa IN ({','.join([f'\"{e}\"' for e in empresas])})")
    if ramales:
        cql_filter.append(f"ramal IN ({','.join([f'\"{r}\"' for r in ramales])})")
    cql_filter = " AND ".join(cql_filter)

    # Generar URL WMS
    url_wms = f"http://geoserver/wms?cql_filter={cql_filter}"
    return jsonify({"url_wms": url_wms})

if __name__ == '__main__':
    app.run(debug=True)