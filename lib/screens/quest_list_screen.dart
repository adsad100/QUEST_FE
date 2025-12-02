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

          return ListView.separated(
            itemCount: quests.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final quest = quests[index];
              final theme = Theme.of(context);
              final metaLine = buildMetaLine(quest);
              final hasSummary = quest.summary != null && quest.summary!.trim().isNotEmpty;

              return Card(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuestDetailScreen(questId: quest.id),
                      ),
                    ).then((value) {
                      setState(() {});
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quest.title,
                          style: theme.textTheme.titleMedium,
                        ),
                        if (hasSummary) ...[
                          const SizedBox(height: 4),
                          Text(
                            quest.summary!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                            ),
                          ),
                        ],
                        if (metaLine.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            metaLine,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String buildMetaLine(QuestSummary quest) {
    final parts = <String>[];
    if (quest.estimatedDurationMin != null) {
      parts.add('${quest.estimatedDurationMin}분');
    }
    if (quest.totalDistanceM != null) {
      parts.add('${quest.totalDistanceM}m');
    }
    if (quest.checkpointCount != null) {
      parts.add('체크포인트 ${quest.checkpointCount}개');
    }

    return parts.join(' · ');
  }
}
