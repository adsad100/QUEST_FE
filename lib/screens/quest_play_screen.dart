// lib/screens/quest_play_screen.dart
import 'package:flutter/material.dart';

import '../models/quest_detail.dart';
import '../models/checkpoint.dart';
import '../models/quest_status.dart';
import '../services/quest_progress_repository.dart';

class QuestPlayScreen extends StatefulWidget {
  final QuestDetail questDetail;

  const QuestPlayScreen({super.key, required this.questDetail});

  @override
  State<QuestPlayScreen> createState() => _QuestPlayScreenState();
}

class _QuestPlayScreenState extends State<QuestPlayScreen> {
  late List<bool> _checked;
  final QuestProgressRepository _progressRepo = QuestProgressRepository();
  bool _statusChanged = false;

  @override
  void initState() {
    super.initState();
    _checked = List<bool>.filled(widget.questDetail.checkpoints.length, false);
    _loadCompletedCheckpoints();
  }

  Future<void> _toggleVisited(int index, bool? value) async {
    setState(() {
      _checked[index] = value ?? false;
    });

    await _updateStatusAndCheckpoints();
  }

  Future<void> _loadCompletedCheckpoints() async {
    final savedVisited =
        await _progressRepo.getCompletedCheckpoints(widget.questDetail.id);

    if (!mounted) return;

    setState(() {
      for (var i = 0; i < widget.questDetail.checkpoints.length; i++) {
        final checkpointId = widget.questDetail.checkpoints[i].id;
        _checked[i] = savedVisited.contains(checkpointId);
      }
    });
  }

  Future<void> _updateStatusAndCheckpoints() async {
    final total = _checked.length;
    final completedCount = _checked.where((v) => v).length;

    final completedIds = <int>{};
    for (int i = 0; i < _checked.length; i++) {
      if (_checked[i]) {
        final cpId = widget.questDetail.checkpoints[i].id;
        completedIds.add(cpId);
      }
    }
    await _progressRepo.setCompletedCheckpoints(widget.questDetail.id, completedIds);

    QuestStatus newStatus;
    if (completedCount == 0) {
      newStatus = QuestStatus.notStarted;
    } else if (completedCount == total) {
      newStatus = QuestStatus.completed;
    } else {
      newStatus = QuestStatus.inProgress;
    }
    await _progressRepo.setStatus(widget.questDetail.id, newStatus);

    _statusChanged = true;
  }

  @override
  Widget build(BuildContext context) {
    final checkpoints = widget.questDetail.checkpoints;
    final visitedCount = _checked.where((v) => v).length;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        Navigator.pop(context, _statusChanged);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('퀘스트 진행'),
          leading: BackButton(
            onPressed: () => Navigator.pop(context, _statusChanged),
          ),
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
                    final visited = _checked[index];
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
      ),
    );
  }
}
