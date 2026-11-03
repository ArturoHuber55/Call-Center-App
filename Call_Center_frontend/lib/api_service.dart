import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'http://127.0.0.1:5000';
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  static Future<Map<String, dynamic>> _post(
      String path, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$path'),
        headers: _headers,
        body: jsonEncode(body),
      );
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'status': 'error', 'message': 'Respuesta inválida del servidor'};
    } catch (e) {
      return {'status': 'error', 'message': 'No se pudo conectar: $e'};
    }
  }

  static Future<Map<String, dynamic>> login(
      String correo, String contrasena) {
    return _post('/login', {'correo': correo, 'contrasena': contrasena});
  }

  static Future<Map<String, dynamic>> registro(
      String nombre, String correo, String contrasena,
      {String rol = 'Agente', String? telefono}) {
    return _post('/registro', {
      'nombre': nombre,
      'correo': correo,
      'contrasena': contrasena,
      'rol': rol,
      if (telefono != null) 'telefono': telefono,
    });
  }
}
