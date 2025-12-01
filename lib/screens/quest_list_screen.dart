// lib/screens/quest_list_screen.dart
import 'package:flutter/material.dart';

import '../models/quest_summary.dart';
import '../services/quest_api_service.dart';
import 'quest_detail_screen.dart';

class QuestListScreen extends StatefulWidget {
  const QuestListScreen({super.key});

  @override
  State<QuestListScreen> createState() => _QuestListScreenState();
}

class _QuestListScreenState extends State<QuestListScreen> {
  late final QuestApiService _apiService;
  late Future<List<QuestSummary>> _questsFuture;

  @override
  void initState() {
    super.initState();
    _apiService = QuestApiService();
    _questsFuture = _apiService.fetchQuests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('퀘스트 목록'),
      ),
      body: FutureBuilder<List<QuestSummary>>(
        future: _questsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('데이터를 불러오는 중 오류가 발생했습니다.'),
                  const SizedBox(height: 8),
                  Text('${snapshot.error}'),
                ],
              ),
            );
          }

          final quests = snapshot.data;
          if (quests == null || quests.isEmpty) {
            return const Center(child: Text('퀘스트가 없습니다.'));
          }

          return ListView.builder(
            itemCount: quests.length,
            itemBuilder: (context, index) {
              final quest = quests[index];
              return ListTile(
                title: Text(quest.title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (quest.summary != null) Text(quest.summary!),
                    if (quest.estimatedDurationMin != null)
                      Text('예상 소요 시간: ${quest.estimatedDurationMin}분'),
                    if (quest.totalDistanceM != null)
                      Text('총 거리: ${quest.totalDistanceM}m'),
                    if (quest.checkpointCount != null)
                      Text('체크포인트: ${quest.checkpointCount}개'),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuestDetailScreen(questId: quest.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
