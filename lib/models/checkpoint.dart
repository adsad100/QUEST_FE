// lib/models/checkpoint.dart
class Checkpoint {
  final int id;
  final String name;
  final String? description;
  final double latitude;
  final double longitude;
  final int orderIndex;
  final int radiusM;

  const Checkpoint({
    required this.id,
    required this.name,
    this.description,
    required this.latitude,
    required this.longitude,
    required this.orderIndex,
    required this.radiusM,
  });

  factory Checkpoint.fromJson(Map<String, dynamic> json) {
    return Checkpoint(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      orderIndex: json['orderIndex'] as int,
      radiusM: json['radiusM'] as int,
    );
  }
}
