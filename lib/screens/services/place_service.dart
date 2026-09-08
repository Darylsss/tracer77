

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../models/place.dart';

class PlaceService {
  final String baseUrl;
  final _storage = const FlutterSecureStorage();

  PlaceService({required this.baseUrl});

  Future<Map<String, String>> _headers() async {
    final token = await _storage.read(key: 'token'); // corrigé : 'token' au lieu de 'auth_token'
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<Place> createPlace(int enfantId, Place place) async {
  final response = await http.post(
    Uri.parse('$baseUrl/enfants/$enfantId/places'),
    headers: await _headers(),
    body: jsonEncode(place.toJson()),
  );

  if (response.statusCode == 201) {
    final data = jsonDecode(response.body);
    return Place.fromJson(data['place']); // <-- on extrait la sous-clé 'place'
  }
  throw Exception('Erreur lors de la création du lieu : ${response.body}');
}

  Future<List<Place>> getPlaces(int enfantId) async {
  final response = await http.get(
    Uri.parse('$baseUrl/enfants/$enfantId/places'),
    headers: await _headers(),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final List placesJson = data['places']; // <-- extraire la sous-clé 'places'
    return placesJson.map((e) => Place.fromJson(e)).toList();
  }
  throw Exception('Erreur lors du chargement des lieux');
}
}