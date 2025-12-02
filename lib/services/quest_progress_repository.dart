import 'package:shared_preferences/shared_preferences.dart';

import '../models/quest_status.dart';

class QuestProgressRepository {
  static const _prefix = 'quest_status_';
  static const _checkpointPrefix = 'quest_checkpoints_';

  Future<QuestStatus> getStatus(int questId) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('$_prefix$questId');
    return _stringToStatus(stored);
  }

  Future<Map<int, QuestStatus>> getStatuses(List<int> questIds) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<int, QuestStatus> result = {};

    for (final id in questIds) {
      final stored = prefs.getString('$_prefix$id');
      result[id] = _stringToStatus(stored);
    }

    return result;
  }

  Future<void> setStatus(int questId, QuestStatus status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$questId', _statusToString(status));
  }

  Future<Set<int>> getVisitedCheckpoints(int questId) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('$_checkpointPrefix$questId');
    if (stored == null) return {};

    return stored
        .map((value) => int.tryParse(value))
        .whereType<int>()
        .toSet();
  }

  Future<void> setVisitedCheckpoints(int questId, List<int> checkpointIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      '$_checkpointPrefix$questId',
      checkpointIds.map((id) => id.toString()).toList(),
    );
  }

  QuestStatus _stringToStatus(String? value) {
    switch (value) {
      case 'in_progress':
        return QuestStatus.inProgress;
      case 'completed':
        return QuestStatus.completed;
      case 'not_started':
      default:
        return QuestStatus.notStarted;
    }
  }

  String _statusToString(QuestStatus status) {
    switch (status) {
      case QuestStatus.inProgress:
        return 'in_progress';
      case QuestStatus.completed:
        return 'completed';
      case QuestStatus.notStarted:
        return 'not_started';
    }
  }
}
