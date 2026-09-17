import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/position.dart' as models;

class PositionService {
  final String baseUrl;
  final _storage = const FlutterSecureStorage();

  PositionService({required this.baseUrl});

  Future<Map<String, String>> _headers() async {
    final token = await _storage.read(key: 'token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// periode: aujourdhui | hier | avant_hier | semaine
  Future<List<models.Position>> getHistorique(int enfantId, String periode) async {
    final response = await http.get(
      Uri.parse('$baseUrl/enfants/$enfantId/historique?periode=$periode'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List raw = data['positions'] ?? [];
      return raw.map((e) => models.Position.fromJson(e)).toList();
    }
    throw Exception('Erreur lors du chargement de l\'historique : ${response.body}');
  }

  /// Donne un nom de lieu approximatif pour une position qui ne correspond
  /// à aucun lieu enregistré (utilisé pour "Zone non autorisée").
  Future<String?> reverseGeocode(double lat, double lng) async {
    final apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';
    if (apiKey.isEmpty) return null;

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json'
      '?latlng=$lat,$lng&key=$apiKey&language=fr',
    );

    try {
      final response = await http.get(url);
      final data = jsonDecode(response.body);
      if (data['status'] == 'OK' && (data['results'] as List).isNotEmpty) {
        final components = data['results'][0]['address_components'] as List;
        // On privilégie le quartier/la localité plutôt que l'adresse complète
        final match = components.firstWhere(
          (c) => (c['types'] as List).contains('sublocality') ||
              (c['types'] as List).contains('locality'),
          orElse: () => components.first,
        );
        return match['long_name'];
      }
    } catch (_) {
      // silencieux : on retombe sur un libellé générique
    }
    return null;
  }
}