import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  // Pour TÉLÉPHONE PHYSIQUE sur le même réseau WiFi
  static const String baseUrl = 'http://192.168.1.133:8000/api';
  static const _storage = FlutterSecureStorage();

  // Inscription
  static Future<Map<String, dynamic>> register({
    required String nom,
    required String email,
    required String password,
  }) async {
    try {
      print('📡 Tentative d\'inscription à: $baseUrl/register');
      
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'nom': nom,
          'email': email,
          'password': password,
          'password_confirmation': password,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('⏰ Connexion au serveur trop lente');
        },
      );
      
      print('📊 STATUS CODE: ${response.statusCode}');
      print('📝 REPONSE BRUTE: ${response.body}');

      final data = jsonDecode(response.body);

      // ✅ Gestion améliorée des erreurs
      if (response.statusCode == 201) {
        // Succès
        await _storage.write(key: 'token', value: data['token']);
        return {
          'success': true,
          'message': 'Inscription réussie',
          'data': data,
        };
      } else {
        // Erreur - Extraire le message d'erreur de Laravel
        String errorMessage = 'Erreur lors de l\'inscription';
        
        // Laravel retourne les erreurs de validation dans 'errors'
        if (data['errors'] != null) {
          // Pour l'email
          if (data['errors']['email'] != null) {
            errorMessage = data['errors']['email'][0];
          }
          // Pour le nom
          else if (data['errors']['nom'] != null) {
            errorMessage = data['errors']['nom'][0];
          }
          // Pour le mot de passe
          else if (data['errors']['password'] != null) {
            errorMessage = data['errors']['password'][0];
          }
        } 
        // Ou message direct
        else if (data['message'] != null) {
          errorMessage = data['message'];
        }

        return {
          'success': false,
          'message': errorMessage,
          'errors': data['errors'] ?? {},
        };
      }
    } catch (e) {
      print('❌ ERREUR AUTH: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur. Vérifiez que Laravel est démarré.',
      };
    }
  }

  // Connexion
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      print('📡 Tentative de connexion à: $baseUrl/login');

      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('⏰ Connexion au serveur trop lente');
        },
      );

      print('📊 STATUS CODE: ${response.statusCode}');
      print('📝 REPONSE BRUTE: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        await _storage.write(key: 'token', value: data['token']);
        return {
          'success': true,
          'message': 'Connexion réussie',
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Email ou mot de passe incorrect',
        };
      }
    } catch (e) {
      print('❌ ERREUR AUTH: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur. Vérifiez que Laravel est démarré.',
      };
    }
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: 'token');
  }

  // Récupérer les infos de l'user connecté
static Future<Map<String, dynamic>?> getUser() async {
  try {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/user'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  } catch (e) {
    return null;
  }
}

// Modifier le nom
static Future<Map<String, dynamic>> updateName(String nom) async {
  try {
    final token = await getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/user/update-name'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'nom': nom}),
    );
    return jsonDecode(response.body);
  } catch (e) {
    return {'success': false, 'message': 'Erreur de connexion au serveur.'};
  }
}

// Modifier le mot de passe
static Future<Map<String, dynamic>> updatePassword({
  required String currentPassword,
  required String newPassword,
}) async {
  try {
    final token = await getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/user/update-password'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': newPassword,
      }),
    );
    return jsonDecode(response.body);
  } catch (e) {
    return {'success': false, 'message': 'Erreur de connexion au serveur.'};
  }
}

// Supprimer le compte
static Future<void> deleteAccount() async {
  try {
    final token = await getToken();
    await http.delete(
      Uri.parse('$baseUrl/user/delete'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    await clearToken();
  } catch (e) {
    // silencieux
  }
}
}