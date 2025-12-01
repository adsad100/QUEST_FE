// lib/models/quest_detail.dart
import 'checkpoint.dart';

class QuestDetail {
  final int id;
  final String title;
  final String? summary;
  final String? description;
  final int? estimatedDurationMin;
  final int? totalDistanceM;
  final List<Checkpoint> checkpoints;

  const QuestDetail({
    required this.id,
    required this.title,
    this.summary,
    this.description,
    this.estimatedDurationMin,
    this.totalDistanceM,
    this.checkpoints = const [],
  });

  factory QuestDetail.fromJson(Map<String, dynamic> json) {
    final checkpointsJson = json['checkpoints'] as List<dynamic>?;
    return QuestDetail(
      id: json['id'] as int,
      title: json['title'] as String,
      summary: json['summary'] as String?,
      description: json['description'] as String?,
      estimatedDurationMin: json['estimatedDurationMin'] as int?,
      totalDistanceM: json['totalDistanceM'] as int?,
      checkpoints: checkpointsJson == null
          ? []
          : checkpointsJson
              .map((item) => Checkpoint.fromJson(item as Map<String, dynamic>))
              .toList(),
    );
  }
}
