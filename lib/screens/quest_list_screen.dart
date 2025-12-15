// lib/screens/quest_list_screen.dart
import 'package:flutter/material.dart';

import '../models/quest_status.dart';
import '../models/quest_summary.dart';
import '../services/quest_api_service.dart';
import '../services/quest_cache_repository.dart';
import '../services/quest_progress_repository.dart';
import 'quest_detail_screen.dart';

class QuestListScreen extends StatefulWidget {
  const QuestListScreen({super.key});

  @override
  State<QuestListScreen> createState() => _QuestListScreenState();
}

class _QuestListScreenState extends State<QuestListScreen> {
  final QuestApiService _questApiService = QuestApiService();
  final QuestCacheRepository _cacheRepository = QuestCacheRepository();
  final QuestProgressRepository _progressRepo = QuestProgressRepository();

  List<QuestSummary> _quests = [];
  Map<int, QuestStatus> _statusMap = {};
  Map<int, int> _completedCountMap = {};
  QuestFilter _selectedFilter = QuestFilter.all;

  bool _hasCache = false; // 캐시로 채워진 적이 있는지
  bool _isRefreshing = false; // 네트워크로 최신 데이터 가져오는 중인지
  String? _errorMessage; // 네트워크 실패 시 메시지

  @override
  void initState() {
    super.initState();
    _initLoad();
  }

  Future<void> _initLoad() async {
    // 1) 캐시 먼저 로딩
    final cached = await _cacheRepository.loadQuestList();
    if (cached != null && cached.isNotEmpty) {
      setState(() {
        _quests = cached;
        _hasCache = true;
      });
      await _rebuildProgressMaps(cached);
    }

    // 2) 네트워크로 최신 데이터 갱신 시도
    await _refreshFromNetwork();
  }

  Future<void> _refreshFromNetwork() async {
    setState(() {
      _isRefreshing = true;
      _errorMessage = null;
    });

    try {
      final fresh = await _questApiService.fetchQuests();

      // 성공하면 캐시에 저장 (캐시가 없던 경우에도 저장)
      await _cacheRepository.saveQuestList(fresh);

      setState(() {
        _quests = fresh;
        _hasCache = true;
        _isRefreshing = false;
        _errorMessage = null;
      });

      // 캐시 저장이 완료되었더라도 진행 상태 계산이 실패하면
      // 화면이 네트워크 오류로 넘어가지 않도록 별도 처리
      try {
        await _rebuildProgressMaps(fresh);
      } catch (_) {
        // 상태 계산 실패는 캐싱/목록 표시와 분리
      }
    } catch (e) {
      setState(() {
        _isRefreshing = false;
        _errorMessage = '네트워크를 확인하세요. 저장된 정보를 보여드리고 있어요.';
      });
    }
  }

  Future<void> _rebuildProgressMaps(List<QuestSummary> quests) async {
    final ids = quests.map((q) => q.id).toList();
    final statuses = await _progressRepo.getStatuses(ids);
    final completedCounts = await _progressRepo.getCompletedCountForQuests(ids);

    setState(() {
      _statusMap = statuses;
      _completedCountMap = completedCounts;
    });
  }

  Future<void> _reloadStatuses() async {
    if (_quests.isEmpty) return;
    await _rebuildProgressMaps(_quests);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget content;

    if (_quests.isEmpty && !_hasCache && _isRefreshing) {
      // 캐시도 없고 최초 로딩 중 → 풀스크린 로딩
      content = const Center(
        child: CircularProgressIndicator(),
      );
    } else if (_quests.isEmpty && !_hasCache && _errorMessage != null) {
      // 캐시도 없고 네트워크도 실패 → 에러 화면
      content = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('퀘스트를 불러오지 못했어요.'),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshFromNetwork,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    } else {
      // 캐시 또는 최신 데이터가 있는 상태 → 기존 리스트 UI
      content = _buildQuestList(context);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('퀘스트 목록'),
      ),
      body: Stack(
        children: [
          content,
          // 1) 네트워크 갱신 중일 때 반투명 오버레이
          if (_isRefreshing && _hasCache)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.05),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('퀘스트를 불러오는 중이에요...'),
                  ],
                ),
              ),
            ),
          // 2) 캐시가 있고, 네트워크는 실패한 상태에서 보여줄 상단 배너
          if (_errorMessage != null && _hasCache)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Material(
                color: Colors.red.withOpacity(0.08),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.red[800],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuestList(BuildContext context) {
    final filteredQuests = _applyFilter(_quests);

    return Column(
      children: [
        _buildFilterChips(),
        Expanded(
          child: ListView.builder(
            itemCount: filteredQuests.length,
            itemBuilder: (context, index) {
              final quest = filteredQuests[index];
              final theme = Theme.of(context);
              final hasSummary = quest.summary != null && quest.summary!.trim().isNotEmpty;
              final status = _statusMap[quest.id] ?? QuestStatus.notStarted;
              final completedCount = _completedCountMap[quest.id] ?? 0;
              final totalCount = quest.checkpointCount ?? 0;
              final statusText = _statusLabel(status);
              final metaLine = buildMetaLine(
                quest,
                completedCount,
                totalCount,
              );

              return Card(
                color: _cardColorFor(status, context),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: InkWell(
                  onTap: () async {
                    final changed = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuestDetailScreen(questId: quest.id),
                      ),
                    );

                    if (changed == true) {
                      await _reloadStatuses();
                    }
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
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  metaLine,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                              Text(
                                statusText,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
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

  String _statusLabel(QuestStatus status) {
    switch (status) {
      case QuestStatus.notStarted:
        return '미진행';
      case QuestStatus.inProgress:
        return '진행중';
      case QuestStatus.completed:
        return '완료';
    }
  }

  String buildMetaLine(QuestSummary quest, int completedCount, int totalCount) {
    final parts = <String>[];
    if (quest.estimatedDurationMin != null) {
      parts.add('${quest.estimatedDurationMin}분');
    }
    if (quest.totalDistanceM != null) {
      parts.add('${quest.totalDistanceM}m');
    }
    if (totalCount > 0) {
      parts.add('체크포인트 $completedCount / $totalCount');
    } else if (quest.checkpointCount != null) {
      parts.add('체크포인트 정보 없음');
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(child: _buildFilterChip(QuestFilter.all, '전체', const Color.fromARGB(255, 228, 228, 228))),
          const SizedBox(width: 8),
          Expanded(child: _buildFilterChip(QuestFilter.notStarted, '미진행', const Color.fromARGB(255, 228, 228, 228))),
          const SizedBox(width: 8),
          Expanded(child: _buildFilterChip(QuestFilter.inProgress, '진행중', _cardColorFor(QuestStatus.inProgress, context))),
          const SizedBox(width: 8),
          Expanded(child: _buildFilterChip(QuestFilter.completed, '완료', _cardColorFor(QuestStatus.completed, context))),
        ],
      ),
    );
  }

  ChoiceChip _buildFilterChip(QuestFilter filter, String label, Color color) {
    return ChoiceChip(
      showCheckmark: false,
      side: const BorderSide(color: Color(0xFFCFD3DA)),
      label: Center(child: Text(label)),
      selected: _selectedFilter == filter,
      selectedColor: color,
      onSelected: (_) {
        setState(() => _selectedFilter = filter);
      },
    );
  }
}
