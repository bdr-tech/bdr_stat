import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/time_utils.dart';
import '../../../core/services/db_storage_monitor.dart';
import '../../../di/providers.dart';
import '../../../data/database/database.dart';

/// 경기 목록 화면
class MatchListScreen extends ConsumerStatefulWidget {
  const MatchListScreen({super.key});

  @override
  ConsumerState<MatchListScreen> createState() => _MatchListScreenState();
}

class _MatchListScreenState extends ConsumerState<MatchListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // 진행 중인 경기가 있으면 "진행 중" 탭으로 자동 이동
    _autoSelectTab();
  }

  Future<void> _autoSelectTab() async {
    final db = ref.read(databaseProvider);
    final tournamentId = ref.read(currentTournamentIdProvider);
    if (tournamentId == null) return;

    final inProgress = await db.matchDao.getMatchesByStatus(tournamentId, 'in_progress');
    if (inProgress.isNotEmpty && mounted) {
      _tabController.animateTo(1); // "진행 중" 탭
      return;
    }
    final scheduled = await db.matchDao.getMatchesByStatus(tournamentId, 'scheduled');
    if (scheduled.isEmpty && mounted) {
      // 예정 경기도 없으면 "완료" 탭
      final completed = await db.matchDao.getMatchesByStatus(tournamentId, 'completed');
      if (completed.isNotEmpty) {
        _tabController.animateTo(2);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unsyncedCount = ref.watch(unsyncedMatchCountProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('경기 목록'),
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshData,
            tooltip: '새로고침',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
            tooltip: '설정',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '예정'),
            Tab(text: '진행 중'),
            Tab(text: '완료'),
          ],
        ),
      ),
      body: Column(
        children: [
          // DB 용량 경고 배너
          const DbStorageWarningBanner(),
          // 동기화 상태 배너
          _SyncStatusBanner(
            unsyncedCount: unsyncedCount,
            onTap: () => context.push('/data-management'),
          ),
          // 경기 목록
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _MatchList(status: 'scheduled'),
                _MatchList(status: 'in_progress'),
                _MatchList(status: 'completed'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 양방향 새로고침: ① 서버→로컬 다운로드 ② 로컬→서버 업로드
  Future<void> _refreshData() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);

    final syncManager = ref.read(syncManagerProvider);
    final dataRefreshService = ref.read(dataRefreshServiceProvider);
    final tournamentId = ref.read(currentTournamentIdProvider);

    // 로딩 표시
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 16),
            Text('데이터 동기화 중...'),
          ],
        ),
        duration: Duration(seconds: 30),
      ),
    );

    // 네트워크 연결 확인
    final hasNetwork = await syncManager.checkNetworkConnection();
    if (!hasNetwork) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('네트워크 연결 후 다시 시도해주세요.'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
      }
      // 오프라인이어도 로컬 데이터 새로고침
      _invalidateMatchLists();
      setState(() => _isRefreshing = false);
      return;
    }

    final messages = <String>[];

    // Step 1: 서버→로컬 다운로드 (새 데이터 가져오기)
    if (tournamentId != null) {
      final refreshResult =
          await dataRefreshService.refreshTournamentData(tournamentId);
      if (refreshResult.success) {
        if (refreshResult.newMatchesAdded > 0 ||
            refreshResult.matchesUpdated > 0) {
          messages.add(refreshResult.summary);
        }
      } else {
        messages.add('다운로드 실패: ${refreshResult.errorMessage}');
      }
    }

    // Step 2: 로컬→서버 업로드 (미동기화 경기 전송)
    final syncResults = await syncManager.syncAllUnsyncedMatches(useQueue: false);
    final successCount = syncResults.values.where((r) => r.success).length;
    final failCount = syncResults.values.where((r) => !r.success).length;

    if (syncResults.isNotEmpty) {
      if (failCount == 0) {
        messages.add('$successCount개 경기 업로드 완료');
      } else {
        messages.add('업로드: 성공 $successCount개, 실패 $failCount개');
      }
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // 결과 표시
    final hasErrors = messages.any((m) => m.contains('실패'));
    final resultMessage =
        messages.isEmpty ? '모든 데이터가 최신 상태입니다.' : messages.join('\n');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(resultMessage),
        backgroundColor:
            hasErrors ? AppTheme.warningColor : AppTheme.successColor,
        duration: const Duration(seconds: 3),
        action: hasErrors
            ? SnackBarAction(
                label: '재시도',
                textColor: Colors.white,
                onPressed: _refreshData,
              )
            : null,
      ),
    );

    // 데이터 새로고침
    _invalidateMatchLists();
    ref.invalidate(unsyncedMatchCountProvider);
    setState(() => _isRefreshing = false);
  }

  void _invalidateMatchLists() {
    ref.invalidate(_matchListProvider('scheduled'));
    ref.invalidate(_matchListProvider('in_progress'));
    ref.invalidate(_matchListProvider('completed'));
  }

  void _openSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('설정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.storage),
              title: const Text('데이터 관리'),
              subtitle: const Text('캐시 현황, 새로고침, 삭제'),
              onTap: () {
                context.pop();
                context.push('/data-management');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('대회 연결 해제'),
              onTap: () {
                context.pop();
                _disconnectTournament();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Future<void> _disconnectTournament() async {
    final tournamentId = ref.read(currentTournamentIdProvider);
    final hasUnsynced = (await ref.read(unsyncedMatchCountProvider.future)) > 0;

    if (!mounted) return;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('연결 해제'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('대회 연결을 해제하시겠습니까?'),
            if (hasUnsynced) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: AppTheme.errorColor, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '미업로드 경기가 있습니다.\n데이터 삭제 시 기록이 유실됩니다.',
                        style: TextStyle(
                          color: AppTheme.errorColor,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(null),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => context.pop('token_only'),
            child: const Text('토큰만 해제'),
          ),
          TextButton(
            onPressed: () => context.pop('with_data'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('데이터와 함께 삭제'),
          ),
        ],
      ),
    );

    if (result == null || !mounted) return;

    final storage = ref.read(secureStorageProvider);

    if (result == 'with_data' && tournamentId != null) {
      // 이중 확인 (미업로드 경기가 있는 경우)
      if (hasUnsynced) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('정말 삭제하시겠습니까?'),
            content: const Text(
              '미업로드된 경기 기록이 영구적으로 삭제됩니다.\n이 작업은 되돌릴 수 없습니다.',
            ),
            actions: [
              TextButton(
                onPressed: () => context.pop(false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => context.pop(true),
                style: TextButton.styleFrom(
                    foregroundColor: AppTheme.errorColor),
                child: const Text('삭제'),
              ),
            ],
          ),
        );
        if (confirmed != true || !mounted) return;
      }

      // 데이터와 함께 삭제
      final db = ref.read(databaseProvider);
      await db.tournamentDao.clearAllTournamentData(tournamentId);
    }

    // 토큰 해제
    await storage.delete(key: 'api_token');
    await storage.delete(key: 'tournament_id');
    ref.read(currentTournamentIdProvider.notifier).state = null;

    if (mounted) {
      context.go('/connect');
    }
  }
}

/// 동기화 상태 배너
class _SyncStatusBanner extends StatelessWidget {
  const _SyncStatusBanner({
    required this.unsyncedCount,
    required this.onTap,
  });

  final AsyncValue<int> unsyncedCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return unsyncedCount.when(
      data: (count) {
        if (count == 0) return const SizedBox.shrink();

        return GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppTheme.warningColor.withValues(alpha: 0.15),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.warningColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '업로드 대기 $count건 · 탭하여 관리',
                    style: TextStyle(
                      color: AppTheme.warningColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppTheme.warningColor,
                  size: 20,
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// 경기 목록 위젯
class _MatchList extends ConsumerWidget {
  const _MatchList({required this.status});

  final String status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(_matchListProvider(status));

    return matchesAsync.when(
      data: (matches) {
        if (matches.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getEmptyIcon(),
                  size: 64,
                  color: AppTheme.textSecondary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  _getEmptyMessage(),
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: matches.length,
          itemBuilder: (context, index) => _MatchCard(
            match: matches[index],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('오류: $error'),
      ),
    );
  }

  IconData _getEmptyIcon() {
    switch (status) {
      case 'scheduled':
        return Icons.event_available;
      case 'in_progress':
        return Icons.sports_basketball;
      case 'completed':
        return Icons.check_circle_outline;
      default:
        return Icons.list;
    }
  }

  String _getEmptyMessage() {
    switch (status) {
      case 'scheduled':
        return '예정된 경기가 없습니다';
      case 'in_progress':
        return '진행 중인 경기가 없습니다';
      case 'completed':
        return '완료된 경기가 없습니다';
      default:
        return '경기가 없습니다';
    }
  }
}

/// 경기 카드 위젯
class _MatchCard extends ConsumerWidget {
  const _MatchCard({required this.match});

  final MatchWithTeams match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isScheduled = match.match.status == 'scheduled';
    final isInProgress = match.match.status == 'in_progress' || match.match.status == 'live';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.surfaceColor,
      child: InkWell(
        onTap: () => _onTap(context, ref),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 라운드 정보
              Container(
                width: 60,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      match.match.roundName ?? 'R${match.match.roundNumber ?? 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    if (match.match.groupName != null)
                      Text(
                        match.match.groupName!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // 홈팀
              Expanded(
                child: _TeamInfo(
                  teamName: match.homeTeam?.teamName ?? match.match.homeTeamName,
                  logoUrl: match.homeTeam?.teamLogoUrl,
                  isHome: true,
                ),
              ),

              // 점수 또는 시간
              Container(
                width: 120,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    if (isScheduled)
                      Text(
                        _formatScheduledTime(match.match.scheduledAt),
                        style: const TextStyle(color: AppTheme.textSecondary),
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${match.match.homeScore}',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const Text(
                            ' : ',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                          Text(
                            '${match.match.awayScore}',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    if (isInProgress) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.successColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${TimeUtils.getQuarterName(match.match.currentQuarter)} ${TimeUtils.formatClock(match.match.gameClockSeconds)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.successColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // 원정팀
              Expanded(
                child: _TeamInfo(
                  teamName: match.awayTeam?.teamName ?? match.match.awayTeamName,
                  logoUrl: match.awayTeam?.teamLogoUrl,
                  isHome: false,
                ),
              ),

              const SizedBox(width: 16),

              // 액션 버튼
              _buildActionButton(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, WidgetRef ref) {
    switch (match.match.status) {
      case 'scheduled':
        return ElevatedButton(
          onPressed: () => _startMatch(context, ref),
          child: const Text('기록 시작'),
        );
      case 'in_progress':
      case 'live':
        return ElevatedButton(
          onPressed: () => _continueMatch(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.successColor,
          ),
          child: const Text('계속'),
        );
      case 'completed':
      case 'finished':
        return OutlinedButton(
          onPressed: () => _viewMatch(context),
          child: const Text('상세보기'),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _onTap(BuildContext context, WidgetRef ref) {
    switch (match.match.status) {
      case 'scheduled':
        _startMatch(context, ref);
        break;
      case 'in_progress':
      case 'live':
        _continueMatch(context);
        break;
      case 'completed':
      case 'finished':
        _viewMatch(context);
        break;
    }
  }

  void _startMatch(BuildContext context, WidgetRef ref) {
    // 스타터 선택 화면으로 이동
    context.push('/starter/${match.match.id}');
  }

  void _continueMatch(BuildContext context) {
    // 기록 화면으로 바로 이동
    context.push('/recording/${match.match.id}');
  }

  void _viewMatch(BuildContext context) {
    // 경기 상세 화면으로 이동
    context.push('/recording/${match.match.id}');
  }

  String _formatScheduledTime(DateTime? time) {
    if (time == null) return '시간 미정';
    return '${time.month}/${time.day} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

/// 팀 정보 위젯
class _TeamInfo extends ConsumerWidget {
  const _TeamInfo({
    required this.teamName,
    this.logoUrl,
    required this.isHome,
  });

  final String teamName;
  final String? logoUrl;
  final bool isHome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // 팀 로고
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: logoUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    logoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.sports_basketball,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                )
              : const Icon(
                  Icons.sports_basketball,
                  color: AppTheme.primaryColor,
                ),
        ),
        const SizedBox(height: 8),
        Text(
          teamName,
          style: const TextStyle(fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          isHome ? 'HOME' : 'AWAY',
          style: const TextStyle(
            fontSize: 10,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// 경기 + 팀 정보 모델
class MatchWithTeams {
  final LocalMatche match;
  final LocalTournamentTeam? homeTeam;
  final LocalTournamentTeam? awayTeam;

  MatchWithTeams({
    required this.match,
    this.homeTeam,
    this.awayTeam,
  });
}

/// 경기 목록 Provider
final _matchListProvider =
    FutureProvider.family<List<MatchWithTeams>, String>((ref, status) async {
  final db = ref.watch(databaseProvider);
  final tournamentId = ref.watch(currentTournamentIdProvider);

  if (tournamentId == null) return [];

  final matches = await db.matchDao.getMatchesByStatus(tournamentId, status);
  final result = <MatchWithTeams>[];

  for (final match in matches) {
    final homeTeam = await db.tournamentDao.getTeamById(match.homeTeamId);
    final awayTeam = await db.tournamentDao.getTeamById(match.awayTeamId);
    result.add(MatchWithTeams(
      match: match,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
    ));
  }

  return result;
});
