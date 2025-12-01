// lib/screens/quest_play_screen.dart
import 'package:flutter/material.dart';

import '../models/quest_detail.dart';
import '../models/checkpoint.dart';

class QuestPlayScreen extends StatefulWidget {
  final QuestDetail questDetail;

  const QuestPlayScreen({super.key, required this.questDetail});

  @override
  State<QuestPlayScreen> createState() => _QuestPlayScreenState();
}

class _QuestPlayScreenState extends State<QuestPlayScreen> {
  late List<bool> _visited;

  @override
  void initState() {
    super.initState();
    _visited = List<bool>.filled(widget.questDetail.checkpoints.length, false);
  }

  void _toggleVisited(int index, bool? value) {
    setState(() {
      _visited[index] = value ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final checkpoints = widget.questDetail.checkpoints;
    final visitedCount = _visited.where((v) => v).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('퀘스트 진행'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('총 체크포인트: ${checkpoints.length}개'),
            const SizedBox(height: 4),
            Text('현재 진행상태: $visitedCount / ${checkpoints.length}'),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: checkpoints.length,
                itemBuilder: (context, index) {
                  final checkpoint = checkpoints[index];
                  final visited = _visited[index];
                  return Card(
                    child: CheckboxListTile(
                      value: visited,
                      onChanged: (value) => _toggleVisited(index, value),
                      title: Text('${checkpoint.orderIndex}. ${checkpoint.name}'),
                      subtitle: Text(checkpoint.description ?? '설명 없음'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
