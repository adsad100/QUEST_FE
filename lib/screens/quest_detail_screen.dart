// lib/screens/quest_detail_screen.dart
import 'package:flutter/material.dart';

import '../models/quest_detail.dart';
import '../services/quest_api_service.dart';
import 'quest_play_screen.dart';

class QuestDetailScreen extends StatefulWidget {
  final int questId;
  const QuestDetailScreen({Key? key, required this.questId}) : super(key: key);

  @override
  State<QuestDetailScreen> createState() => _QuestDetailScreenState();
}

class _QuestDetailScreenState extends State<QuestDetailScreen> {
  late final QuestApiService _apiService;
  late Future<QuestDetail> _questFuture;

  @override
  void initState() {
    super.initState();
    _apiService = QuestApiService();
    _questFuture = _apiService.fetchQuestDetail(widget.questId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('퀘스트 상세'),
      ),
      body: FutureBuilder<QuestDetail>(
        future: _questFuture,
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

          final quest = snapshot.data;
          if (quest == null) {
            return const Center(child: Text('퀘스트 정보를 찾을 수 없습니다.'));
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      quest.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (quest.summary != null) ...[
                      const SizedBox(height: 8),
                      Text(quest.summary!),
                    ],
                    if (quest.description != null) ...[
                      const SizedBox(height: 8),
                      Text(quest.description!),
                    ],
                    const SizedBox(height: 12),
                    if (quest.estimatedDurationMin != null)
                      Text('예상 소요 시간: ${quest.estimatedDurationMin}분'),
                    if (quest.totalDistanceM != null)
                      Text('총 거리: ${quest.totalDistanceM}m'),
                    const SizedBox(height: 16),
                    const Text(
                      '체크포인트',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...quest.checkpoints.map(
                      (checkpoint) => ListTile(
                        leading: CircleAvatar(
                          child: Text('${checkpoint.orderIndex}'),
                        ),
                        title: Text(checkpoint.name),
                        subtitle: Text(checkpoint.description ?? '설명 없음'),
                      ),
                    ),
                  ],
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QuestPlayScreen(questDetail: quest),
                          ),
                        );
                      },
                      child: const Text('퀘스트 시작'),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
