import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/environment.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
        final GoogleSignInAccount? googleuser = await _googleSignIn.signIn();

        if (googleuser == null) {
            return {
                'success': false,
                'message': 'Inicio de sesion cancelado'
            };
        }
        
        final GoogleSignInAuthentication googleAuth = await googleuser.authentication;

        final String? token = googleAuth.idToken;

        if (token != null) {
            return await _sendTokenToBackend(token);
        } else {
            return {
                'success': false,
                'message': 'Token de Google no encontrado'
            };
        }
    } catch (e) {
        return {
            'success': false,
            'message': 'Error al iniciar sesion con Google: $e'
        };
    }
  }

  Future<Map<String, dynamic>> _sendTokenToBackend(String googleToken) async {
    final url = Uri.parse('${Environment.apiUrl}/api/auth/google/');

    try {
        print("Intentando conectar a: $url");

        final response = await http.post(
            url,
            headers: {'Content-type': 'application/json'},
            body: jsonEncode({
                'google_token': googleToken
            }),
        );

        print("Status Code: ${response.statusCode}");
        print("Body: ${response.body}");

        if (response.statusCode == 200) {
            final data = jsonDecode(response.body);

            await _storage.write(
                key: 'access_token',
                value: data['access']
            );

            await _storage.write(
                key: 'refresh_token',
                value: data['refresh']
            );

            if (data['user'] != null) {
                await _storage.write(
                    key: 'user_id',
                    value: data['user']['id'].toString()
                );
            }

            return {
                'success': true,
                'user': data['user'],
                'message': 'Login correcto'
            };
        } else {
            return {'success': false, 'message': 'Error de autenticacion'};
        }
    } catch (e) {
        return {'success': false, 'message': 'Error de conexion: $e'};
    }
  }

  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _storage.deleteAll();
  }

  Future<void> refreshToken() async {
    final refresh = await _storage.read(key: 'refresh_token');
    if (refresh == null) throw Exception("Sesión expirada");

    final response = await http.post(
        Uri.parse('${Environment.apiUrl}/api/auth/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refresh}),
    );

    if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _storage.write(key: 'access_token', value: data['access']);
    } else {
        await logout();
        throw Exception("Sesión expirada");
    }
  }
}