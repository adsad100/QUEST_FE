// lib/services/quest_api_service.dart
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/quest_detail.dart';
import '../models/quest_summary.dart';

class QuestApiService {
  QuestApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _buildUri(String path) => Uri.parse('${AppConfig.apiBaseUrl}$path');

  Future<List<QuestSummary>> fetchQuests() async {
    final response = await _client.get(_buildUri('/api/quests'));
    if (response.statusCode != 200) {
      throw Exception('Failed to load quests: ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((item) => QuestSummary.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<QuestDetail> fetchQuestDetail(int questId) async {
    final response = await _client.get(_buildUri('/api/quests/$questId'));
    if (response.statusCode != 200) {
      throw Exception('Failed to load quest detail: ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return QuestDetail.fromJson(decoded);
  }
}
