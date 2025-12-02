import 'package:shared_preferences/shared_preferences.dart';

import '../models/quest_status.dart';

class QuestProgressRepository {
  static const _prefixStatus = 'quest_status_';
  static const _prefixChecked = 'quest_checked_';

  Future<QuestStatus> getStatus(int questId) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('$_prefixStatus$questId');
    return _stringToStatus(stored);
  }

  Future<Map<int, QuestStatus>> getStatuses(List<int> questIds) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<int, QuestStatus> result = {};

    for (final id in questIds) {
      final stored = prefs.getString('$_prefixStatus$id');
      result[id] = _stringToStatus(stored);
    }

    return result;
  }

  Future<void> setStatus(int questId, QuestStatus status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefixStatus$questId', _statusToString(status));
  }

  /// 해당 퀘스트에서 완료된 체크포인트 id 목록을 반환
  Future<Set<int>> getCompletedCheckpoints(int questId) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('$_prefixChecked$questId');
    return _stringToIdSet(stored);
  }

  /// 여러 퀘스트에 대한 완료된 체크포인트 개수를 한 번에 가져오기
  /// key: questId, value: completedCount
  Future<Map<int, int>> getCompletedCountForQuests(List<int> questIds) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<int, int> result = {};

    for (final id in questIds) {
      final stored = prefs.getString('$_prefixChecked$id');
      result[id] = _stringToIdSet(stored).length;
    }

    return result;
  }

  /// 완료된 체크포인트 id 집합을 저장
  Future<void> setCompletedCheckpoints(
    int questId,
    Set<int> checkpointIds,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = _idSetToString(checkpointIds);
    await prefs.setString('$_prefixChecked$questId', stored);
  }

  Set<int> _stringToIdSet(String? value) {
    if (value == null || value.isEmpty) return {};

    return value
        .split(',')
        .map((part) => int.tryParse(part.trim()))
        .whereType<int>()
        .toSet();
  }

  String _idSetToString(Set<int> ids) {
    if (ids.isEmpty) return '';
    return ids.map((id) => id.toString()).join(',');
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
