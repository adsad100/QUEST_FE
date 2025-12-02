// lib/screens/quest_list_screen.dart
import 'package:flutter/material.dart';

import '../models/quest_status.dart';
import '../models/quest_summary.dart';
import '../services/quest_api_service.dart';
import '../services/quest_progress_repository.dart';
import 'quest_detail_screen.dart';

class QuestListScreen extends StatefulWidget {
  const QuestListScreen({super.key});

  @override
  State<QuestListScreen> createState() => _QuestListScreenState();
}

class _QuestListScreenState extends State<QuestListScreen> {
  late final QuestApiService _apiService;
  late Future<List<QuestSummary>> _futureQuests;
  final QuestProgressRepository _progressRepo = QuestProgressRepository();

  Map<int, QuestStatus> _statusMap = {};
  QuestFilter _selectedFilter = QuestFilter.all;

  @override
  void initState() {
    super.initState();
    _apiService = QuestApiService();
    _futureQuests = _loadQuests();
  }

  Future<List<QuestSummary>> _loadQuests() async {
    final quests = await _apiService.fetchQuests();
    final ids = quests.map((q) => q.id).toList();
    final statuses = await _progressRepo.getStatuses(ids);

    setState(() {
      _statusMap = statuses;
    });

    return quests;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('퀘스트 목록'),
      ),
      body: FutureBuilder<List<QuestSummary>>(
        future: _futureQuests,
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

          final filteredQuests = _applyFilter(quests);

          return Column(
            children: [
              _buildFilterChips(),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredQuests.length,
                  itemBuilder: (context, index) {
                    final quest = filteredQuests[index];
                    final theme = Theme.of(context);
                    final metaLine = buildMetaLine(quest);
                    final hasSummary = quest.summary != null && quest.summary!.trim().isNotEmpty;
                    final status = _statusMap[quest.id] ?? QuestStatus.notStarted;

                    return Card(
                      color: _cardColorFor(status, context),
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => QuestDetailScreen(questId: quest.id),
                            ),
                          ).then((value) {
                            setState(() {
                              _futureQuests = _loadQuests();
                            });
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
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _cardColorFor(QuestStatus status, BuildContext context) {
    switch (status) {
      case QuestStatus.completed:
        return const Color(0xFFE8F5E9);
      case QuestStatus.inProgress:
        return const Color(0xFFE3F2FD);
      case QuestStatus.notStarted:
      default:
        return Theme.of(context).cardColor;
    }
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

  List<QuestSummary> _applyFilter(List<QuestSummary> quests) {
    return quests.where((q) {
      final status = _statusMap[q.id] ?? QuestStatus.notStarted;

      switch (_selectedFilter) {
        case QuestFilter.all:
          return true;
        case QuestFilter.notStarted:
          return status == QuestStatus.notStarted;
        case QuestFilter.inProgress:
          return status == QuestStatus.inProgress;
        case QuestFilter.completed:
          return status == QuestStatus.completed;
      }
    }).toList();
  }

  Widget _buildFilterChips() {
    const spacing = 8.0;
    const horizontalPadding = 16.0;
    const chipsPerRow = 2;
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth =
        screenWidth - (horizontalPadding * 2) - (spacing * (chipsPerRow - 1));
    final chipWidth = availableWidth / chipsPerRow;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
      child: Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          _buildFilterChip(QuestFilter.all, '전체', chipWidth),
          _buildFilterChip(QuestFilter.notStarted, '미진행', chipWidth),
          _buildFilterChip(QuestFilter.inProgress, '진행중', chipWidth),
          _buildFilterChip(QuestFilter.completed, '완료', chipWidth),
        ],
      ),
    );
  }

  ChoiceChip _buildFilterChip(QuestFilter filter, String label, double width) {
    return ChoiceChip(
      showCheckmark: false,
      label: SizedBox(
        width: width,
        child: Center(child: Text(label)),
      ),
      selected: _selectedFilter == filter,
      onSelected: (_) {
        setState(() => _selectedFilter = filter);
      },
    );
  }
}
