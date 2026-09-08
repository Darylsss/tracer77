enum PlaceType { domicile, ecole, proche, autre }

extension PlaceTypeExtension on PlaceType {
  String get value {
    switch (this) {
      case PlaceType.domicile:
        return 'domicile';
      case PlaceType.ecole:
        return 'ecole';
      case PlaceType.proche:
        return 'proche';
      case PlaceType.autre:
        return 'autre';
    }
  }

  String get defaultLabel {
    switch (this) {
      case PlaceType.domicile:
        return 'Domicile';
      case PlaceType.ecole:
        return 'École';
      case PlaceType.proche:
        return 'Domicile d\'un proche';
      case PlaceType.autre:
        return '';
    }
  }

  String get title {
    switch (this) {
      case PlaceType.domicile:
        return 'Ajouter un domicile';
      case PlaceType.ecole:
        return 'Ajouter une école';
      case PlaceType.proche:
        return 'Ajouter le domicile d\'un proche';
      case PlaceType.autre:
        return 'Ajoutez un lieu';
    }
  }
}

class Place {
  final int? id;
  final int enfantId;
  final PlaceType type;
  final String nom;
  final double latitude;
  final double longitude;
  final int rayon;

  Place({
    this.id,
    required this.enfantId,
    required this.type,
    required this.nom,
    required this.latitude,
    required this.longitude,
    this.rayon = 100,
  });

  Map<String, dynamic> toJson() => {
        'type': type.value,
        'nom': nom,
        'latitude': latitude,
        'longitude': longitude,
        'rayon': rayon,
      }; // enfantId ne va pas dans le body, il est déjà dans l'URL

  factory Place.fromJson(Map<String, dynamic> json) => Place(
        id: json['id'],
        enfantId: json['enfant_id'],
        type: PlaceType.values.firstWhere((t) => t.value == json['type']),
        nom: json['nom'],
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        rayon: json['rayon'] ?? 100,
      );
}