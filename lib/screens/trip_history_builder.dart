import 'dart:math' as math;
import '../models/position.dart' as models;
import '../models/place.dart';

enum TripEventType { trajet, arrivee }

class TripEvent {
  final TripEventType type;
  final String title;
  final DateTime start;
  final DateTime? end; // null si toujours en cours / dernier point connu
  final double? distanceKm; // pour un trajet
  final bool? secure; // pour une arrivée
  final Map<String, dynamic>? alerte; // alerte liée si zone non autorisée
  final double lat;
  final double lng;

  TripEvent({
    required this.type,
    required this.title,
    required this.start,
    this.end,
    this.distanceKm,
    this.secure,
    this.alerte,
    required this.lat,
    required this.lng,
  });
}

class TripHistoryBuilder {
  /// Distance en mètres entre deux points (formule de Haversine)
  static double _distanceMetres(double lat1, double lng1, double lat2, double lng2) {
    const rayonTerre = 6371000.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLng = _deg2rad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) * math.cos(_deg2rad(lat2)) * math.sin(dLng / 2) * math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return rayonTerre * c;
  }

  static double _deg2rad(double deg) => deg * (math.pi / 180);

  /// Trouve le lieu (Place) qui contient cette position, s'il y en a un.
  static Place? _placeAt(double lat, double lng, List<Place> places) {
    for (final p in places) {
      if (_distanceMetres(lat, lng, p.latitude, p.longitude) <= p.rayon) {
        return p;
      }
    }
    return null;
  }

  /// Construit la liste d'événements (trajets + arrivées) à partir des
  /// positions brutes d'une journée et des lieux enregistrés de l'enfant.
  /// [alertes] : liste des alertes de l'enfant (pour lier "Voir alerte").
  /// [resolveUnknown] : callback optionnel pour nommer une zone non reconnue
  /// (reverse-geocoding) — appelé une seule fois par zone détectée.
  static Future<List<TripEvent>> build({
    required List<models.Position> positions,
    required List<Place> places,
    required List<dynamic> alertes,
    Future<String?> Function(double lat, double lng)? resolveUnknown,
  }) async {
    if (positions.isEmpty) return [];

    final events = <TripEvent>[];

    Place? runPlace = _placeAt(positions.first.lat, positions.first.lng, places);
    int runStartIndex = 0;

    Future<void> closeRun(int endIndex) async {
      final startPos = positions[runStartIndex];
      final endPos = positions[endIndex];

      if (runPlace != null) {
        // Séjour dans un lieu connu -> "sécurisé"
        events.add(TripEvent(
          type: TripEventType.arrivee,
          title: 'Arrivée à ${runPlace!.nom}',
          start: startPos.createdAt,
          end: endPos.createdAt,
          secure: true,
          lat: startPos.lat,
          lng: startPos.lng,
        ));
      } else {
        // Pas de lieu connu : si le point final est stable assez longtemps,
        // on considère que c'est un arrêt dans une zone non reconnue.
        final dureeMinutes = endPos.createdAt.difference(startPos.createdAt).inMinutes;
        final deplacement = _distanceMetres(startPos.lat, startPos.lng, endPos.lat, endPos.lng);

        if (dureeMinutes >= 5 && deplacement < 80 && runStartIndex != 0) {
          String label = 'Zone non autorisée';
          if (resolveUnknown != null) {
            final nom = await resolveUnknown(endPos.lat, endPos.lng);
            if (nom != null) label = nom;
          }

          // Alerte proche dans le temps pour ce point (hors SOS)
          final Map<String, dynamic>? alerteLiee = alertes.cast<Map<String, dynamic>?>().firstWhere(
                (a) {
                  if (a == null || a['type'] == 'sos') return false;
                  final dt = DateTime.tryParse(a['created_at']?.toString() ?? '');
                  if (dt == null) return false;
                  return dt.difference(startPos.createdAt).inMinutes.abs() < 60;
                },
                orElse: () => null,
              );

          events.add(TripEvent(
            type: TripEventType.arrivee,
            title: 'Arrivée à $label',
            start: startPos.createdAt,
            end: endPos.createdAt,
            secure: false,
            alerte: alerteLiee,
            lat: endPos.lat,
            lng: endPos.lng,
          ));
        }
      }
    }

    for (int i = 1; i < positions.length; i++) {
      final place = _placeAt(positions[i].lat, positions[i].lng, places);
      final samePlaceId = place?.id;
      final runPlaceId = runPlace?.id;
      final samePlace = samePlaceId == runPlaceId;

      if (!samePlace) {
        await closeRun(i - 1);

        // Trajet parcouru entre le run précédent et celui-ci
        final depart = positions[runStartIndex];
        double distanceKm = 0;
        for (int j = runStartIndex; j < i - 1; j++) {
          distanceKm += _distanceMetres(
                positions[j].lat,
                positions[j].lng,
                positions[j + 1].lat,
                positions[j + 1].lng,
              ) /
              1000;
        }

        events.add(TripEvent(
          type: TripEventType.trajet,
          title: runPlace != null
              ? (place != null ? 'Trajet ${runPlace.nom} - ${place.nom}' : 'Trajet ${runPlace.nom} - ...')
              : (place != null ? 'Trajet ... - ${place.nom}' : 'Déplacement'),
          start: depart.createdAt,
          end: positions[i].createdAt,
          distanceKm: distanceKm,
          lat: depart.lat,
          lng: depart.lng,
        ));

        runPlace = place;
        runStartIndex = i;
      }
    }
    await closeRun(positions.length - 1);

    return events;
  }
}