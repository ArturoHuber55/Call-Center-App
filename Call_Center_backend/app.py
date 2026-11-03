import mysql.connector
from mysql.connector import Error
from flask import Flask, jsonify, request
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

DB_CONFIG = {
    'host': '127.0.0.1',
    'user': 'root',
    'password': '',
    'database': 'callcenter_db'
}

def get_db_connection():
    return mysql.connector.connect(**DB_CONFIG)

@app.route('/', methods=['GET'])
def check_db_connection():
    connection = None
    try:
        connection = get_db_connection()
        if connection.is_connected():
            db_info = connection.get_server_info()
            return jsonify({
                "status": "success",
                "message": "Conexión exitosa a la base de datos MariaDB",
                "database": DB_CONFIG['database'],
                "server_version": db_info
            }), 200
    except Error as e:
        return jsonify({
            "status": "error",
            "message": "Error al conectar a la base de datos MariaDB",
            "error": str(e)
        }), 500
    finally:
        if connection is not None and connection.is_connected():
            connection.close()

@app.route('/login', methods=['POST'])
def login():
    data = request.get_json(silent=True) or {}
    correo = data.get('correo')
    contrasena = data.get('contrasena')

    if not correo or not contrasena:
        return jsonify({
            "status": "error",
            "message": "Credenciales inválidas"
        }), 401

    connection = None
    cursor = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        query = """
            SELECT id_agente, nombre, rol 
            FROM agentes 
            WHERE correo = %s AND contrasena = %s
        """
        cursor.execute(query, (correo, contrasena))
        agente = cursor.fetchone()

        if agente:
            return jsonify({
                "status": "success",
                "usuario": {
                    "id_agente": agente['id_agente'],
                    "nombre": agente['nombre'],
                    "rol": agente['rol']
                }
            }), 200
        else:
            return jsonify({
                "status": "error",
                "message": "Credenciales inválidas"
            }), 401
    except Error as e:
        return jsonify({
            "status": "error",
            "message": "Error en el servidor al consultar la base de datos",
            "error": str(e)
        }), 500
    finally:
        if cursor is not None:
            cursor.close()
        if connection is not None and connection.is_connected():
            connection.close()

@app.route('/registro', methods=['POST'])
def registro():
    data = request.get_json(silent=True) or {}
    nombre = data.get('nombre')
    correo = data.get('correo')
    telefono = data.get('telefono')
    contrasena = data.get('contrasena')
    rol = data.get('rol') or 'Agente'

    if not nombre or not correo or not contrasena:
        return jsonify({
            "status": "error",
            "message": "Faltan datos obligatorios"
        }), 400

    connection = None
    cursor = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor()
        cursor.execute(
            "INSERT INTO agentes (nombre, correo, telefono, contrasena, rol) VALUES (%s, %s, %s, %s, %s)",
            (nombre, correo, telefono, contrasena, rol)
        )
        connection.commit()
        return jsonify({"status": "success", "message": "Cuenta creada"}), 201
    except Error as e:
        return jsonify({
            "status": "error",
            "message": "No se pudo crear la cuenta",
            "error": str(e)
        }), 500
    finally:
        if cursor is not None:
            cursor.close()
        if connection is not None and connection.is_connected():
            connection.close()

@app.route('/guardar_llamada', methods=['POST'])
def guardar_llamada():
    data = request.get_json(silent=True) or {}
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute(
            "INSERT INTO llamadas (id_agente, id_cliente, duracion_segundos, motivo, estado_llamada, notas) "
            "VALUES (%s, %s, %s, %s, %s, %s)",
            (
                data.get('id_agente'),
                data.get('id_cliente'),
                data.get('duracion_segundos'),
                data.get('motivo'),
                data.get('estado_llamada'),
                data.get('notas'),
            )
        )
        conn.commit()
        return jsonify({"success": True, "message": "Llamada guardada correctamente"})
    except Exception as e:
        print(f'Error de MariaDB: {e}')
        return jsonify({"success": False, "error": str(e)}), 500
    finally:
        if cursor is not None:
            cursor.close()
        if conn is not None and conn.is_connected():
            conn.close()

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)

