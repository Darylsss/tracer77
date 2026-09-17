class Position {
  final int id;
  final double lat;
  final double lng;
  final double vitesse;
  final DateTime createdAt;

  Position({
    required this.id,
    required this.lat,
    required this.lng,
    required this.vitesse,
    required this.createdAt,
  });

  factory Position.fromJson(Map<String, dynamic> json) => Position(
        id: json['id'],
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        vitesse: json['vitesse'] != null ? (json['vitesse'] as num).toDouble() : 0,
        createdAt: DateTime.parse(json['created_at']),
      );
}