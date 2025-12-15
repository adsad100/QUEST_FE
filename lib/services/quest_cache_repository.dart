import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/quest_summary.dart';

class QuestCacheRepository {
  static const _keyQuests = 'quests_cache';
  static const _keyQuestsUpdatedAt = 'quests_cache_updated_at';

  /// 캐시에 저장된 퀘스트 목록을 불러옵니다.
  /// 없으면 null을 반환합니다.
  Future<List<QuestSummary>?> loadQuestList() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyQuests);
    if (jsonString == null || jsonString.isEmpty) {
      return null;
    }

    try {
      final List<dynamic> decoded = json.decode(jsonString) as List<dynamic>;
      return decoded
          .map((e) => QuestSummary.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // 파싱 실패 시 캐시를 무시합니다.
      return null;
    }
  }

  /// 퀘스트 목록을 JSON 형태로 캐시에 저장합니다.
  Future<void> saveQuestList(List<QuestSummary> quests) async {
    final prefs = await SharedPreferences.getInstance();
    final list = quests.map((q) => q.toJson()).toList();
    final jsonString = json.encode(list);
    await prefs.setString(_keyQuests, jsonString);
    await prefs.setInt(
      _keyQuestsUpdatedAt,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// 마지막으로 캐시가 갱신된 시각(ms)을 반환합니다.
  /// 없으면 null.
  Future<int?> getLastUpdatedAt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyQuestsUpdatedAt);
  }

}
