import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/database/database.dart';
import '../../../data/database/daos/play_by_play_dao.dart';
import '../../../data/database/daos/player_stats_dao.dart';
import '../../../data/database/daos/edit_log_dao.dart';
import '../../../di/providers.dart';

/// Play-by-Play 기록 수정 화면
///
/// 시간순으로 플레이 기록을 보여주고,
/// 득점자 변경, 점수 종류 변경(2점↔3점), 기록 삭제 기능 제공
class PlayByPlayEditScreen extends ConsumerStatefulWidget {
  const PlayByPlayEditScreen({
    super.key,
    required this.matchId,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.homeTeamName,
    required this.awayTeamName,
  });

  final int matchId;
  final int homeTeamId;
  final int awayTeamId;
  final String homeTeamName;
  final String awayTeamName;

  @override
  ConsumerState<PlayByPlayEditScreen> createState() =>
      _PlayByPlayEditScreenState();
}

class _PlayByPlayEditScreenState extends ConsumerState<PlayByPlayEditScreen> {
  List<LocalPlayByPlay> _plays = [];
  bool _isLoading = true;
  int _selectedQuarter = 0; // 0 = 전체

  @override
  void initState() {
    super.initState();
    _loadPlays();
  }

  Future<void> _loadPlays() async {
    setState(() => _isLoading = true);

    final db = ref.read(databaseProvider);
    final playByPlayDao = PlayByPlayDao(db);

    List<LocalPlayByPlay> plays;
    if (_selectedQuarter == 0) {
      plays = await playByPlayDao.getPlaysByMatch(widget.matchId);
    } else {
      plays = await playByPlayDao.getPlaysByMatchAndQuarter(
        widget.matchId,
        _selectedQuarter,
      );
    }

    // 시간순 정렬 (쿼터 → 게임클럭 내림차순)
    plays.sort((a, b) {
      if (a.quarter != b.quarter) {
        return a.quarter.compareTo(b.quarter);
      }
      return b.gameClockSeconds.compareTo(a.gameClockSeconds);
    });

    setState(() {
      _plays = plays;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('기록 수정'),
        backgroundColor: AppTheme.surfaceColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          // 쿼터 필터
          PopupMenuButton<int>(
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selectedQuarter == 0 ? '전체' : 'Q$_selectedQuarter',
                  style: const TextStyle(fontSize: 14),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
            onSelected: (quarter) {
              setState(() => _selectedQuarter = quarter);
              _loadPlays();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 0, child: Text('전체 쿼터')),
              const PopupMenuItem(value: 1, child: Text('1쿼터')),
              const PopupMenuItem(value: 2, child: Text('2쿼터')),
              const PopupMenuItem(value: 3, child: Text('3쿼터')),
              const PopupMenuItem(value: 4, child: Text('4쿼터')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: '수정 이력',
            onPressed: _showEditHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _plays.isEmpty
              ? _buildEmptyState()
              : _buildPlayList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: AppTheme.textSecondary),
          const SizedBox(height: 16),
          Text(
            '기록이 없습니다',
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _plays.length,
      itemBuilder: (context, index) {
        final play = _plays[index];
        return _PlayCard(
          play: play,
          homeTeamId: widget.homeTeamId,
          awayTeamId: widget.awayTeamId,
          homeTeamName: widget.homeTeamName,
          awayTeamName: widget.awayTeamName,
          onEdit: () => _showEditDialog(play),
          onDelete: () => _confirmDelete(play),
        );
      },
    );
  }

  void _showEditDialog(LocalPlayByPlay play) {
    // 슛 기록만 수정 가능
    if (play.actionType != 'shot') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('슛 기록만 수정할 수 있습니다')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _EditBottomSheet(
        play: play,
        homeTeamId: widget.homeTeamId,
        awayTeamId: widget.awayTeamId,
        homeTeamName: widget.homeTeamName,
        awayTeamName: widget.awayTeamName,
        onSaved: () {
          Navigator.pop(context);
          _loadPlays();
        },
      ),
    );
  }

  void _confirmDelete(LocalPlayByPlay play) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('기록 삭제'),
        content: Text(
          '이 기록을 삭제하시겠습니까?\n\n${play.description ?? _getPlayDescription(play)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deletePlay(play);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePlay(LocalPlayByPlay play) async {
    final db = ref.read(databaseProvider);
    final playByPlayDao = PlayByPlayDao(db);
    final playerStatsDao = PlayerStatsDao(db);
    final editLogDao = EditLogDao(db);

    try {
      // 스탯 롤백
      if (play.actionType == 'shot') {
        await _rollbackShotStats(play, playerStatsDao);
      }

      // 삭제 이력 기록
      await editLogDao.logPlayDeleted(
        matchId: widget.matchId,
        playId: play.id,
        localId: play.localId,
        description: _getPlayDescription(play),
        oldValue: '{"actionType":"${play.actionType}","actionSubtype":"${play.actionSubtype}","isMade":${play.isMade},"points":${play.pointsScored}}',
      );

      // 기록 삭제
      await playByPlayDao.deletePlay(play.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('기록이 삭제되었습니다')),
        );
        _loadPlays();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 실패: $e')),
        );
      }
    }
  }

  Future<void> _rollbackShotStats(
    LocalPlayByPlay play,
    PlayerStatsDao dao,
  ) async {
    final stats = await dao.getStatsByPlayer(
      widget.matchId,
      play.tournamentTeamPlayerId,
    );
    if (stats == null) return;

    final isMade = play.isMade ?? false;
    final is3pt = play.actionSubtype == '3pt';
    final isFt = play.actionSubtype == 'ft';

    int fgm = stats.fieldGoalsMade;
    int fga = stats.fieldGoalsAttempted;
    int twoPm = stats.twoPointersMade;
    int twoPa = stats.twoPointersAttempted;
    int threePm = stats.threePointersMade;
    int threePa = stats.threePointersAttempted;
    int ftm = stats.freeThrowsMade;
    int fta = stats.freeThrowsAttempted;
    int pts = stats.points;

    if (isFt) {
      fta--;
      if (isMade) {
        ftm--;
        pts--;
      }
    } else if (is3pt) {
      fga--;
      threePa--;
      if (isMade) {
        fgm--;
        threePm--;
        pts -= 3;
      }
    } else {
      // 2pt
      fga--;
      twoPa--;
      if (isMade) {
        fgm--;
        twoPm--;
        pts -= 2;
      }
    }

    await dao.updateStats(
      widget.matchId,
      play.tournamentTeamPlayerId,
      {
        'fieldGoalsMade': fgm,
        'fieldGoalsAttempted': fga,
        'twoPointersMade': twoPm,
        'twoPointersAttempted': twoPa,
        'threePointersMade': threePm,
        'threePointersAttempted': threePa,
        'freeThrowsMade': ftm,
        'freeThrowsAttempted': fta,
        'points': pts,
      },
    );
  }

  String _getPlayDescription(LocalPlayByPlay play) {
    final time = _formatTime(play.gameClockSeconds);
    final prefix = 'Q${play.quarter} $time';

    switch (play.actionType) {
      case 'shot':
        final shotType = play.actionSubtype ?? '2pt';
        final result = (play.isMade ?? false) ? '성공' : '실패';
        return '$prefix - $shotType $result (${play.pointsScored}점)';
      case 'rebound':
        final type = play.actionSubtype == 'offensive' ? '공격' : '수비';
        return '$prefix - $type 리바운드';
      case 'assist':
        return '$prefix - 어시스트';
      case 'steal':
        return '$prefix - 스틸';
      case 'block':
        return '$prefix - 블락';
      case 'turnover':
        return '$prefix - 턴오버';
      case 'foul':
        return '$prefix - 파울';
      default:
        return '$prefix - ${play.actionType}';
    }
  }

  String _formatTime(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }

  void _showEditHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => _EditHistorySheet(
          matchId: widget.matchId,
          scrollController: scrollController,
        ),
      ),
    );
  }
}

/// 수정 이력 시트
class _EditHistorySheet extends ConsumerWidget {
  const _EditHistorySheet({
    required this.matchId,
    required this.scrollController,
  });

  final int matchId;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final editLogDao = EditLogDao(db);

    return Column(
      children: [
        // 헤더
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.history, size: 24),
              const SizedBox(width: 8),
              const Text(
                '수정 이력',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // 이력 목록
        Expanded(
          child: FutureBuilder<List<LocalEditLog>>(
            future: editLogDao.getLogsByMatch(matchId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final logs = snapshot.data ?? [];
              if (logs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 48, color: AppTheme.textSecondary),
                      const SizedBox(height: 16),
                      Text(
                        '수정 이력이 없습니다',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  return _EditLogCard(log: log);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 수정 이력 카드
class _EditLogCard extends StatelessWidget {
  const _EditLogCard({required this.log});

  final LocalEditLog log;

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color color;

    switch (log.editType) {
      case 'create':
        icon = Icons.add_circle;
        color = AppTheme.successColor;
        break;
      case 'update':
        icon = Icons.edit;
        color = AppTheme.warningColor;
        break;
      case 'delete':
        icon = Icons.delete;
        color = AppTheme.errorColor;
        break;
      default:
        icon = Icons.info;
        color = AppTheme.textSecondary;
    }

    return Card(
      color: AppTheme.backgroundColor,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.description ?? _getEditTypeLabel(log.editType),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDateTime(log.editedAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getEditTypeLabel(log.editType),
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getEditTypeLabel(String type) {
    switch (type) {
      case 'create':
        return '생성';
      case 'update':
        return '수정';
      case 'delete':
        return '삭제';
      default:
        return type;
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

/// 개별 플레이 카드
class _PlayCard extends ConsumerWidget {
  const _PlayCard({
    required this.play,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.onEdit,
    required this.onDelete,
  });

  final LocalPlayByPlay play;
  final int homeTeamId;
  final int awayTeamId;
  final String homeTeamName;
  final String awayTeamName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHomeTeam = play.tournamentTeamId == homeTeamId;
    final teamColor = isHomeTeam ? AppTheme.homeTeamColor : AppTheme.awayTeamColor;

    // 선수 정보 가져오기
    final playersAsync = ref.watch(teamPlayersProvider(play.tournamentTeamId));

    return Card(
      color: AppTheme.surfaceColor,
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 시간 & 쿼터
              SizedBox(
                width: 60,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Q${play.quarter}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      _formatTime(play.gameClockSeconds),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // 팀 색상 바
              Container(
                width: 4,
                height: 40,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: teamColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // 플레이 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 선수 이름
                    playersAsync.when(
                      data: (players) {
                        final player = players.firstWhere(
                          (p) => p.id == play.tournamentTeamPlayerId,
                          orElse: () => players.first,
                        );
                        return Text(
                          '#${player.jerseyNumber ?? 0} ${player.userName}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                      loading: () => const Text('...'),
                      error: (_, __) => const Text('선수'),
                    ),
                    const SizedBox(height: 4),
                    // 액션 설명
                    Row(
                      children: [
                        _buildActionIcon(),
                        const SizedBox(width: 8),
                        Text(
                          _getActionText(),
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        if (play.actionType == 'shot' && (play.isMade ?? false)) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.successColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '+${play.pointsScored}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.successColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // 점수 스냅샷
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${play.homeScoreAtTime} - ${play.awayScoreAtTime}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // 삭제 버튼
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: AppTheme.errorColor,
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionIcon() {
    IconData icon;
    Color color;

    switch (play.actionType) {
      case 'shot':
        final isMade = play.isMade ?? false;
        icon = isMade ? Icons.sports_basketball : Icons.sports_basketball_outlined;
        color = isMade ? AppTheme.successColor : AppTheme.errorColor;
        break;
      case 'rebound':
        icon = Icons.sync;
        color = AppTheme.warningColor;
        break;
      case 'assist':
        icon = Icons.assistant;
        color = AppTheme.primaryColor;
        break;
      case 'steal':
        icon = Icons.flash_on;
        color = AppTheme.successColor;
        break;
      case 'block':
        icon = Icons.block;
        color = AppTheme.errorColor;
        break;
      case 'turnover':
        icon = Icons.swap_horiz;
        color = AppTheme.errorColor;
        break;
      case 'foul':
        icon = Icons.warning;
        color = AppTheme.warningColor;
        break;
      default:
        icon = Icons.sports;
        color = AppTheme.textSecondary;
    }

    return Icon(icon, size: 20, color: color);
  }

  String _getActionText() {
    switch (play.actionType) {
      case 'shot':
        final shotType = play.actionSubtype ?? '2pt';
        final typeLabel = shotType == '3pt' ? '3점슛' : (shotType == 'ft' ? '자유투' : '2점슛');
        final result = (play.isMade ?? false) ? '성공' : '실패';
        return '$typeLabel $result';
      case 'rebound':
        return play.actionSubtype == 'offensive' ? '공격 리바운드' : '수비 리바운드';
      case 'assist':
        return '어시스트';
      case 'steal':
        return '스틸';
      case 'block':
        return '블락';
      case 'turnover':
        return '턴오버';
      case 'foul':
        return '파울';
      case 'substitution':
        return '교체';
      default:
        return play.actionType;
    }
  }

  String _formatTime(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }
}

/// 수정 바텀시트
class _EditBottomSheet extends ConsumerStatefulWidget {
  const _EditBottomSheet({
    required this.play,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.onSaved,
  });

  final LocalPlayByPlay play;
  final int homeTeamId;
  final int awayTeamId;
  final String homeTeamName;
  final String awayTeamName;
  final VoidCallback onSaved;

  @override
  ConsumerState<_EditBottomSheet> createState() => _EditBottomSheetState();
}

class _EditBottomSheetState extends ConsumerState<_EditBottomSheet> {
  late String _selectedSubtype;
  late bool _isMade;
  int? _selectedPlayerId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedSubtype = widget.play.actionSubtype ?? '2pt';
    _isMade = widget.play.isMade ?? false;
    _selectedPlayerId = widget.play.tournamentTeamPlayerId;
  }

  @override
  Widget build(BuildContext context) {
    final playersAsync = ref.watch(
      teamPlayersProvider(widget.play.tournamentTeamId),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                const Text(
                  '기록 수정',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),

            // 득점자 변경
            const Text(
              '득점자',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            playersAsync.when(
              data: (players) {
                final onCourtPlayers = players.toList();
                return DropdownButtonFormField<int>(
                  value: _selectedPlayerId,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppTheme.backgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: onCourtPlayers.map((player) {
                    return DropdownMenuItem(
                      value: player.id,
                      child: Text(
                        '#${player.jerseyNumber ?? 0} ${player.userName}',
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedPlayerId = value);
                  },
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('선수 목록 로드 실패'),
            ),
            const SizedBox(height: 20),

            // 슛 종류 변경
            const Text(
              '슛 종류',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildShotTypeChip('2pt', '2점슛'),
                const SizedBox(width: 8),
                _buildShotTypeChip('3pt', '3점슛'),
                const SizedBox(width: 8),
                _buildShotTypeChip('ft', '자유투'),
              ],
            ),
            const SizedBox(height: 20),

            // 성공/실패
            const Text(
              '결과',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildResultButton(true, '성공'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildResultButton(false, '실패'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 저장 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        '저장',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShotTypeChip(String type, String label) {
    final isSelected = _selectedSubtype == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedSubtype = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildResultButton(bool made, String label) {
    final isSelected = _isMade == made;
    final color = made ? AppTheme.successColor : AppTheme.errorColor;

    return GestureDetector(
      onTap: () => setState(() => _isMade = made),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? color : AppTheme.textPrimary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (_selectedPlayerId == null) return;

    setState(() => _isSaving = true);

    try {
      final db = ref.read(databaseProvider);
      final playByPlayDao = PlayByPlayDao(db);
      final playerStatsDao = PlayerStatsDao(db);
      final editLogDao = EditLogDao(db);

      final oldSubtype = widget.play.actionSubtype ?? '2pt';
      final oldMade = widget.play.isMade ?? false;
      final oldPlayerId = widget.play.tournamentTeamPlayerId;

      // 점수 계산
      int newPoints = 0;
      if (_isMade) {
        newPoints = _selectedSubtype == '3pt' ? 3 : (_selectedSubtype == 'ft' ? 1 : 2);
      }

      // 변경 내용 기록
      final changes = <String>[];
      if (oldPlayerId != _selectedPlayerId) {
        changes.add('득점자 변경');
      }
      if (oldSubtype != _selectedSubtype) {
        changes.add('슛 종류: $oldSubtype → $_selectedSubtype');
      }
      if (oldMade != _isMade) {
        changes.add('결과: ${oldMade ? "성공" : "실패"} → ${_isMade ? "성공" : "실패"}');
      }

      // 수정 이력 기록
      if (changes.isNotEmpty) {
        await editLogDao.logPlayUpdated(
          matchId: widget.play.localMatchId,
          playId: widget.play.id,
          localId: widget.play.localId,
          fieldName: changes.length == 1 ? changes.first : 'multiple',
          oldValue: '{"playerId":$oldPlayerId,"subtype":"$oldSubtype","isMade":$oldMade}',
          newValue: '{"playerId":$_selectedPlayerId,"subtype":"$_selectedSubtype","isMade":$_isMade}',
          description: changes.join(', '),
        );
      }

      // 플레이 기록 업데이트
      await playByPlayDao.updatePlay(
        widget.play.id,
        LocalPlayByPlaysCompanion(
          tournamentTeamPlayerId: Value(_selectedPlayerId!),
          actionSubtype: Value(_selectedSubtype),
          isMade: Value(_isMade),
          pointsScored: Value(newPoints),
          isSynced: const Value(false),
        ),
      );

      // 스탯 조정 (이전 선수의 스탯 감소, 새 선수의 스탯 증가)
      if (oldPlayerId != _selectedPlayerId ||
          oldSubtype != _selectedSubtype ||
          oldMade != _isMade) {
        // 이전 선수 스탯 롤백
        await _adjustPlayerStats(
          playerStatsDao,
          oldPlayerId,
          oldSubtype,
          oldMade,
          isAdding: false,
        );

        // 새 선수 스탯 추가
        await _adjustPlayerStats(
          playerStatsDao,
          _selectedPlayerId!,
          _selectedSubtype,
          _isMade,
          isAdding: true,
        );
      }

      widget.onSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _adjustPlayerStats(
    PlayerStatsDao dao,
    int playerId,
    String subtype,
    bool isMade, {
    required bool isAdding,
  }) async {
    final stats = await dao.getStatsByPlayer(widget.play.localMatchId, playerId);
    if (stats == null) return;

    final multiplier = isAdding ? 1 : -1;
    final is3pt = subtype == '3pt';
    final isFt = subtype == 'ft';

    int fgm = stats.fieldGoalsMade;
    int fga = stats.fieldGoalsAttempted;
    int twoPm = stats.twoPointersMade;
    int twoPa = stats.twoPointersAttempted;
    int threePm = stats.threePointersMade;
    int threePa = stats.threePointersAttempted;
    int ftm = stats.freeThrowsMade;
    int fta = stats.freeThrowsAttempted;
    int pts = stats.points;

    if (isFt) {
      fta += multiplier;
      if (isMade) {
        ftm += multiplier;
        pts += 1 * multiplier;
      }
    } else if (is3pt) {
      fga += multiplier;
      threePa += multiplier;
      if (isMade) {
        fgm += multiplier;
        threePm += multiplier;
        pts += 3 * multiplier;
      }
    } else {
      // 2pt
      fga += multiplier;
      twoPa += multiplier;
      if (isMade) {
        fgm += multiplier;
        twoPm += multiplier;
        pts += 2 * multiplier;
      }
    }

    await dao.updateStats(
      widget.play.localMatchId,
      playerId,
      {
        'fieldGoalsMade': fgm,
        'fieldGoalsAttempted': fga,
        'twoPointersMade': twoPm,
        'twoPointersAttempted': twoPa,
        'threePointersMade': threePm,
        'threePointersAttempted': threePa,
        'freeThrowsMade': ftm,
        'freeThrowsAttempted': fta,
        'points': pts,
      },
    );
  }
}
