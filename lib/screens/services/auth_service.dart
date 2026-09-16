import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';

class AuthService {
  // Pour TÉLÉPHONE PHYSIQUE sur le même réseau WiFi
  static const String baseUrl = 'https://tracer77.duckdns.org/api';
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

      if (response.statusCode == 201) {
        // Succès - Sauvegarder token et utilisateur
        await _storage.write(key: 'token', value: data['token']);
        if (data['user'] != null) {
          await _storage.write(key: 'user_data', value: jsonEncode(data['user']));
        }
        return {
          'success': true,
          'message': 'Inscription réussie',
          'data': data,
        };
      } else {
        String errorMessage = 'Erreur lors de l\'inscription';
        
        if (data['errors'] != null) {
          if (data['errors']['email'] != null) {
            errorMessage = data['errors']['email'][0];
          } else if (data['errors']['nom'] != null) {
            errorMessage = data['errors']['nom'][0];
          } else if (data['errors']['password'] != null) {
            errorMessage = data['errors']['password'][0];
          }
        } else if (data['message'] != null) {
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
        // Sauvegarder le token
        await _storage.write(key: 'token', value: data['token']);
        
        // Sauvegarder l'utilisateur
        if (data['user'] != null) {
          await _storage.write(key: 'user_data', value: jsonEncode(data['user']));
        }
        
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
    await _storage.delete(key: 'user_data');
  }

  // Récupérer les infos de l'user connecté
  static Future<Map<String, dynamic>?> getUser() async {
    try {
      final token = await getToken();
      
      if (token == null) {
        print('🔴 Aucun token trouvé');
        return null;
      }
      
      print('🟢 Token trouvé, récupération de l\'utilisateur...');
      
      final response = await http.get(
        Uri.parse('$baseUrl/user'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('⏰ Timeout');
        },
      );
      
      print('📊 Status code getUser: ${response.statusCode}');
      print('📝 Réponse getUser: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Sauvegarder l'utilisateur en cache
        await _storage.write(key: 'user_data', value: jsonEncode(data));
        
        return data;
      } else if (response.statusCode == 401) {
        // Token expiré ou invalide
        await clearToken();
        return null;
      }
      
      return null;
    } catch (e) {
      print('❌ Erreur getUser: $e');
      
      // En cas d'erreur réseau, essayer de lire le cache
      try {
        final cachedUser = await _storage.read(key: 'user_data');
        if (cachedUser != null) {
          print('🟢 Utilisateur chargé depuis le cache');
          return jsonDecode(cachedUser);
        }
      } catch (cacheError) {
        print('❌ Erreur cache: $cacheError');
      }
      
      return null;
    }
  }

  // Récupérer l'utilisateur depuis le cache
  static Future<Map<String, dynamic>?> getCachedUser() async {
    try {
      final userData = await _storage.read(key: 'user_data');
      if (userData != null) {
        return jsonDecode(userData);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Mettre à jour le cache utilisateur
  static Future<void> updateCachedUser(Map<String, dynamic> userData) async {
    await _storage.write(key: 'user_data', value: jsonEncode(userData));
  }

  // Modifier le nom
  static Future<Map<String, dynamic>> updateName(String nom) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'Non authentifié'};
      }
      
      final response = await http.put(
        Uri.parse('$baseUrl/user/update-name'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'nom': nom}),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('⏰ Timeout');
        },
      );
      
      final data = jsonDecode(response.body);
      
      // Mettre à jour le cache
      if (response.statusCode == 200 && data['success'] == true) {
        final currentUser = await getCachedUser();
        if (currentUser != null) {
          currentUser['nom'] = nom;
          await updateCachedUser(currentUser);
        }
      }
      
      return data;
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
      if (token == null) {
        return {'success': false, 'message': 'Non authentifié'};
      }
      
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
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('⏰ Timeout');
        },
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
      if (token != null) {
        await http.delete(
          Uri.parse('$baseUrl/user/delete'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      }
      await clearToken();
    } catch (e) {
      // silencieux
    }
  }

  // Activer/désactiver le partage de position
  static Future<Map<String, dynamic>> togglePositionSharing() async {
    try {
      final token = await getToken();
      
      if (token == null) {
        return {'success': false, 'message': 'Non authentifié'};
      }
      
      print('🔄 Toggle position sharing...');
      
      final response = await http.post(
        Uri.parse('$baseUrl/user/toggle-position-sharing'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('⏰ Timeout');
        },
      );
      
      print('📊 Status code toggle: ${response.statusCode}');
      print('📝 Réponse toggle: ${response.body}');
      
      final data = jsonDecode(response.body);
      
      // Mettre à jour le cache utilisateur si succès
      if (response.statusCode == 200 && data['success'] == true) {
        final currentUser = await getCachedUser();
        if (currentUser != null) {
          currentUser['partage_position'] = data['partage_position'];
          await updateCachedUser(currentUser);
        }
      }
      
      return data;
    } catch (e) {
      print('❌ Erreur togglePositionSharing: $e');
      return {'success': false, 'message': 'Erreur de connexion au serveur.'};
    }
  }

  // Créer une famille
  static Future<Map<String, dynamic>> createFamily({String? nom}) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'Non authentifié'};
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/family/create'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'nom': nom}),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('⏰ Timeout');
        },
      );
      
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur.'};
    }
  }

  // Rejoindre une famille via un token d'invitation
  static Future<Map<String, dynamic>> acceptInvite(String token) async {
    try {
      final authToken = await getToken();
      if (authToken == null) {
        return {'success': false, 'message': 'Non authentifié'};
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/family/accept-invite'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'token': token}),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('⏰ Timeout');
        },
      );
      
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur.'};
    }
  }

  // Lister les membres et enfants de la famille
static Future<Map<String, dynamic>> getFamilyMembers() async {
  try {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/family/members'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return jsonDecode(response.body);
  } catch (e) {
    return {'success': false, 'message': 'Erreur de connexion au serveur.'};
  }
}

// Inviter un membre par email
static Future<Map<String, dynamic>> inviteMember(String email) async {
  try {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/family/invite'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'email': email}),
    );
    return jsonDecode(response.body);
  } catch (e) {
    return {'success': false, 'message': 'Erreur de connexion au serveur.'};
  }
}

// Retirer un membre
static Future<Map<String, dynamic>> removeMember(int id) async {
  try {
    final token = await getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/family/members/$id'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return jsonDecode(response.body);
  } catch (e) {
    return {'success': false, 'message': 'Erreur de connexion au serveur.'};
  }
}

// Ajouter un enfant
static Future<Map<String, dynamic>> addEnfant({
  required String nom,
  required String prenom,
  required String identifiantBoitier,
}) async {
  try {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/enfants'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'nom': nom,
        'prenom': prenom,
        'identifiant_boitier': identifiantBoitier,
      }),
    );
    return jsonDecode(response.body);
  } catch (e) {
    return {'success': false, 'message': 'Erreur de connexion au serveur.'};
  }
}
static Future<Map<String, dynamic>> forgotPassword(String email) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/forgot-password'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    return jsonDecode(response.body);
  } catch (e) {
    return {'success': false, 'message': 'Erreur de connexion au serveur.'};
  }
}

static Future<Map<String, dynamic>> resetPassword({
  required String email,
  required String token,
  required String password,
}) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/reset-password'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({
        'email': email,
        'token': token,
        'password': password,
        'password_confirmation': password,
      }),
    );
    return jsonDecode(response.body);
  } catch (e) {
    return {'success': false, 'message': 'Erreur de connexion au serveur.'};
  }
}

static Future<Map<String, dynamic>> addEnfantWithPhoto({
  required String prenom,
  required String identifiantBoitier,
  File? photo,
}) async {
  try {
    final token = await getToken();
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/enfants'));

    request.headers['Accept'] = 'application/json';
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['prenom'] = prenom;
    request.fields['identifiant_boitier'] = identifiantBoitier;

    if (photo != null) {
      request.files.add(await http.MultipartFile.fromPath('photo', photo.path));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return jsonDecode(response.body);
  } catch (e) {
    return {'success': false, 'message': 'Erreur de connexion au serveur.'};
  }
}

// Modifier un enfant (nom / photo)
static Future<Map<String, dynamic>> updateEnfant({
  required int enfantId,
  String? prenom,
  File? photo,
}) async {
  try {
    final token = await getToken();
    if (token == null) {
      return {'success': false, 'message': 'Non authentifié'};
    }

    // POST + _method=PUT : Laravel ne parse pas bien le multipart sur une vraie requête PUT
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/enfants/$enfantId?_method=PUT'),
    );
    request.headers['Accept'] = 'application/json';
    request.headers['Authorization'] = 'Bearer $token';

    if (prenom != null) request.fields['prenom'] = prenom;
    if (photo != null) {
      request.files.add(await http.MultipartFile.fromPath('photo', photo.path));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return jsonDecode(response.body);
  } catch (e) {
    return {'success': false, 'message': 'Erreur de connexion au serveur.'};
  }
}

// Retirer un enfant suivi
static Future<Map<String, dynamic>> deleteEnfant(int enfantId) async {
  try {
    final token = await getToken();
    if (token == null) {
      return {'success': false, 'message': 'Non authentifié'};
    }

    final response = await http.delete(
      Uri.parse('$baseUrl/enfants/$enfantId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return jsonDecode(response.body);
  } catch (e) {
    return {'success': false, 'message': 'Erreur de connexion au serveur.'};
  }
}

}