

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class PlacesAutocompleteService {
  final String apiKey;
  PlacesAutocompleteService({required this.apiKey});

  Future<List<Map<String, String>>> search(String input) async {
    if (input.trim().isEmpty) return [];

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json'
      '?input=${Uri.encodeComponent(input)}'
      '&key=$apiKey&language=fr&components=country:bj',
    );

    try {
      final response = await http.get(url);
      final data = jsonDecode(response.body);

      if (data['status'] == 'OK') {
        return (data['predictions'] as List)
            .map((p) => {
                  'description': p['description'] as String,
                  'place_id': p['place_id'] as String,
                })
            .toList();
      } else {
        // utile pour débugger : REQUEST_DENIED, ZERO_RESULTS, etc.
        // ignore: avoid_print
        print('Places Autocomplete status: ${data['status']} — ${data['error_message'] ?? ''}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('Erreur autocomplete: $e');
    }
    return [];
  }

  Future<Map<String, double>?> getLatLng(String placeId) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json'
      '?place_id=$placeId&fields=geometry&key=$apiKey',
    );

    try {
      final response = await http.get(url);
      final data = jsonDecode(response.body);

      if (data['status'] == 'OK') {
        final loc = data['result']['geometry']['location'];
        return {
          'lat': (loc['lat'] as num).toDouble(),
          'lng': (loc['lng'] as num).toDouble(),
        };
      }
    } catch (e) {
      // ignore: avoid_print
      print('Erreur getLatLng: $e');
    }
    return null;
  }
}