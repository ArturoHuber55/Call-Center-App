import pandas as pd
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

@app.route('/importar_clientes', methods=['POST'])
def importar_clientes():
    archivo = request.files.get('documento')
    if archivo is None or archivo.filename == '':
        return jsonify({
            "status": "error",
            "message": "No se envió ningún archivo en 'documento'"
        }), 400

    connection = None
    cursor = None
    try:
        df = pd.read_excel(archivo)
        df = df.iloc[:, :3]

        connection = get_db_connection()
        cursor = connection.cursor()
        query = "INSERT INTO clientes (nombre_completo, correo_contacto, telefono) VALUES (%s, %s, %s)"

        importados = 0
        for _, fila in df.iterrows():
            if fila.isnull().all():
                continue
            valores = []
            for v in fila:
                valores.append(None if pd.isna(v) else str(v).strip())
            if not any(valores):
                continue
            cursor.execute(query, tuple(valores))
            importados += 1

        connection.commit()
        return jsonify({
            "status": "success",
            "message": f"{importados} clientes importados correctamente",
            "importados": importados
        }), 200
    except Exception as e:
        if connection is not None and connection.is_connected():
            connection.rollback()
        return jsonify({
            "status": "error",
            "message": "Error al importar clientes",
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

@app.route('/programar_llamada', methods=['POST'])
def programar_llamada():
    data = request.get_json(silent=True) or {}
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute(
            "INSERT INTO llamadas (id_agente, id_cliente, motivo, notas, estado_llamada, duracion_segundos) "
            "VALUES (1, %s, %s, %s, 'Pendiente', 0)",
            (data.get('id_cliente'), data.get('motivo'), data.get('notas'))
        )
        conn.commit()
        return jsonify({"success": True, "message": "Llamada programada correctamente"}), 201
    except Exception as e:
        print(f'Error de MariaDB: {e}')
        return jsonify({"success": False, "error": str(e)}), 500
    finally:
        if cursor is not None:
            cursor.close()
        if conn is not None and conn.is_connected():
            conn.close()

@app.route('/llamadas_pendientes', methods=['GET'])
def llamadas_pendientes():
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute(
            "SELECT llamadas.id_llamada, llamadas.id_cliente, clientes.nombre_completo, "
            "clientes.telefono, clientes.correo_contacto, llamadas.motivo "
            "FROM llamadas "
            "JOIN clientes ON llamadas.id_cliente = clientes.id_cliente "
            "WHERE llamadas.estado_llamada = 'Pendiente' "
            "ORDER BY llamadas.id_llamada ASC"
        )
        return jsonify(cursor.fetchall()), 200
    except Exception as e:
        print(f'Error de MariaDB: {e}')
        return jsonify({"success": False, "error": str(e)}), 500
    finally:
        if cursor is not None:
            cursor.close()
        if conn is not None and conn.is_connected():
            conn.close()

@app.route('/historial_llamadas', methods=['GET'])
def historial_llamadas():
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute(
            "SELECT clientes.nombre_completo, clientes.correo_contacto, clientes.telefono, "
            "llamadas.fecha_llamada, llamadas.duracion_segundos, llamadas.motivo, llamadas.estado_llamada, "
            "GREATEST((SELECT COUNT(*) FROM llamadas l2 "
            "WHERE l2.id_cliente = llamadas.id_cliente AND l2.estado_llamada != 'Pendiente') - 1, 0) "
            "AS llamadas_anteriores "
            "FROM llamadas "
            "JOIN clientes ON llamadas.id_cliente = clientes.id_cliente "
            "WHERE llamadas.estado_llamada != 'Pendiente' "
            "ORDER BY llamadas.fecha_llamada DESC"
        )
        return jsonify(cursor.fetchall()), 200
    except Exception as e:
        print(f'Error de MariaDB: {e}')
        return jsonify({"success": False, "error": str(e)}), 500
    finally:
        if cursor is not None:
            cursor.close()
        if conn is not None and conn.is_connected():
            conn.close()

@app.route('/eliminar_llamada/<int:id_llamada>', methods=['DELETE'])
def eliminar_llamada(id_llamada):
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute(
            "DELETE FROM llamadas WHERE id_llamada = %s AND estado_llamada = 'Pendiente'",
            (id_llamada,)
        )
        conn.commit()
        return jsonify({
            "success": True,
            "message": "Llamada eliminada correctamente"
        }), 200
    except Exception as e:
        print(f'Error de MariaDB: {e}')
        return jsonify({"success": False, "error": str(e)}), 500
    finally:
        if cursor is not None:
            cursor.close()
        if conn is not None and conn.is_connected():
            conn.close()

@app.route('/finalizar_llamada/<int:id_llamada>', methods=['PUT'])
def finalizar_llamada(id_llamada):
    data = request.get_json(silent=True) or {}
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute(
            "UPDATE llamadas SET duracion_segundos = %s, estado_llamada = %s, notas = %s, motivo = %s "
            "WHERE id_llamada = %s",
            (data.get('duracion_segundos'), data.get('estado_llamada'),
             data.get('notas'), data.get('motivo'), id_llamada)
        )
        conn.commit()
        return jsonify({"success": True, "message": "Llamada finalizada correctamente"}), 200
    except Exception as e:
        print(f'Error de MariaDB: {e}')
        return jsonify({"success": False, "error": str(e)}), 500
    finally:
        if cursor is not None:
            cursor.close()
        if conn is not None and conn.is_connected():
            conn.close()

@app.route('/estadisticas', methods=['GET'])
def estadisticas():
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)

        cursor.execute("SELECT COUNT(*) AS total FROM llamadas WHERE estado_llamada != 'Pendiente'")
        total_llamadas = cursor.fetchone()['total']

        cursor.execute("SELECT AVG(duracion_segundos) AS promedio FROM llamadas WHERE estado_llamada != 'Pendiente'")
        promedio = cursor.fetchone()['promedio']
        duracion_promedio = float(promedio) if promedio is not None else 0.0

        cursor.execute("SELECT motivo, COUNT(*) AS total FROM llamadas WHERE estado_llamada != 'Pendiente' GROUP BY motivo")
        por_motivo = cursor.fetchall()

        cursor.execute("SELECT estado_llamada, COUNT(*) AS total FROM llamadas WHERE estado_llamada != 'Pendiente' GROUP BY estado_llamada")
        por_estado = cursor.fetchall()

        return jsonify({
            "total_llamadas": total_llamadas,
            "duracion_promedio_segundos": duracion_promedio,
            "por_motivo": por_motivo,
            "por_estado": por_estado
        }), 200
    except Exception as e:
        print(f'Error de MariaDB: {e}')
        return jsonify({"success": False, "error": str(e)}), 500
    finally:
        if cursor is not None:
            cursor.close()
        if conn is not None and conn.is_connected():
            conn.close()

@app.route('/clientes', methods=['GET'])
def obtener_clientes():
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute(
            "SELECT clientes.id_cliente, clientes.nombre_completo, clientes.telefono, clientes.correo_contacto, "
            "(SELECT COUNT(*) FROM llamadas l WHERE l.id_cliente = clientes.id_cliente "
            "AND l.estado_llamada != 'Pendiente') AS llamadas_anteriores "
            "FROM clientes"
        )
        clientes = cursor.fetchall()
        return jsonify(clientes), 200
    except Exception as e:
        print(f'Error de MariaDB: {e}')
        return jsonify({"success": False, "error": str(e)}), 500
    finally:
        if cursor is not None:
            cursor.close()
        if conn is not None and conn.is_connected():
            conn.close()

@app.route('/crear_cliente', methods=['POST'])
def crear_cliente():
    data = request.get_json(silent=True) or {}
    nombre_completo = data.get('nombre_completo')
    telefono = data.get('telefono')
    correo_contacto = data.get('correo_contacto')

    if not nombre_completo or not telefono or not correo_contacto:
        return jsonify({
            "success": False,
            "error": "Faltan datos obligatorios (nombre_completo, telefono, correo_contacto)"
        }), 400

    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute(
            "INSERT INTO clientes (nombre_completo, telefono, correo_contacto) VALUES (%s, %s, %s)",
            (nombre_completo, telefono, correo_contacto)
        )
        conn.commit()
        return jsonify({
            "success": True,
            "message": "Cliente creado correctamente",
            "id_cliente": cursor.lastrowid
        }), 201
    except Exception as e:
        print(f'Error de MariaDB: {e}')
        return jsonify({"success": False, "error": str(e)}), 500
    finally:
        if cursor is not None:
            cursor.close()
        if conn is not None and conn.is_connected():
            conn.close()

@app.route('/editar_cliente/<int:id_cliente>', methods=['PUT'])
def editar_cliente(id_cliente):
    data = request.get_json(silent=True) or {}
    nombre_completo = data.get('nombre_completo')
    telefono = data.get('telefono')
    correo_contacto = data.get('correo_contacto')

    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute(
            "UPDATE clientes SET nombre_completo = %s, telefono = %s, correo_contacto = %s WHERE id_cliente = %s",
            (nombre_completo, telefono, correo_contacto, id_cliente)
        )
        conn.commit()
        return jsonify({
            "success": True,
            "message": "Cliente actualizado correctamente"
        }), 200
    except Exception as e:
        print(f'Error de MariaDB: {e}')
        return jsonify({"success": False, "error": str(e)}), 500
    finally:
        if cursor is not None:
            cursor.close()
        if conn is not None and conn.is_connected():
            conn.close()

@app.route('/eliminar_cliente/<int:id_cliente>', methods=['DELETE'])
def eliminar_cliente(id_cliente):
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("DELETE FROM clientes WHERE id_cliente = %s", (id_cliente,))
        conn.commit()
        return jsonify({
            "success": True,
            "message": "Cliente eliminado correctamente"
        }), 200
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

