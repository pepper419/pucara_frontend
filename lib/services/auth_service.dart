import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'http://192.168.18.3:8000/api';

  /// Registro estándar de usuarios
  static Future<bool> register({
    required String nombre,
    required String email,
    required String contrasena,
  }) async {
    final url = Uri.parse('$baseUrl/usuarios/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre,
        'email': email,
        'contrasena': contrasena,
        'rol': 'usuario', // puedes cambiar por 'admin' si deseas registrar admins
      }),
    );

    if (response.statusCode == 201) {
      return true;
    } else {
      print('❌ Error al registrar: ${response.body}');
      return false;
    }
  }

  /// Login y almacenamiento de sesión
  static Future<String?> login({
    required String email,
    required String contrasena,
  }) async {
    final url = Uri.parse('$baseUrl/login/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'contrasena': contrasena,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'];
      final nombre = data['nombre'];
      final rol = data['rol'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setString('nombre', nombre);
      await prefs.setString('rol', rol);

      return nombre;
    } else {
      print('❌ Error al iniciar sesión: ${response.body}');
      return null;
    }
  }

  /// Cerrar sesión
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Obtener datos del usuario actual desde preferencias
  static Future<Map<String, String?>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'token': prefs.getString('token'),
      'nombre': prefs.getString('nombre'),
      'rol': prefs.getString('rol'),
    };
  }
}


