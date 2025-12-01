// lib/models/quest_summary.dart
class QuestSummary {
  final int id;
  final String title;
  final String? summary;
  final int? estimatedDurationMin;
  final int? totalDistanceM;
  final int? checkpointCount;

  const QuestSummary({
    required this.id,
    required this.title,
    this.summary,
    this.estimatedDurationMin,
    this.totalDistanceM,
    this.checkpointCount,
  });

  factory QuestSummary.fromJson(Map<String, dynamic> json) {
    return QuestSummary(
      id: json['id'] as int,
      title: json['title'] as String,
      summary: json['summary'] as String?,
      estimatedDurationMin: json['estimatedDurationMin'] as int?,
      totalDistanceM: json['totalDistanceM'] as int?,
      checkpointCount: json['checkpointCount'] as int?,
    );
  }
}
