import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/sync_manager.dart';
import '../../../core/services/db_storage_monitor.dart';
import '../../../data/database/daos/tournament_dao.dart';
import '../../../di/providers.dart';

/// 대회별 캐시 현황 프로바이더
final _cacheStatsProvider =
    FutureProvider<List<TournamentCacheStats>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.tournamentDao.getAllCacheStats();
});

/// 데이터 관리 화면
class DataManagementScreen extends ConsumerStatefulWidget {
  const DataManagementScreen({super.key});

  @override
  ConsumerState<DataManagementScreen> createState() =>
      _DataManagementScreenState();
}

class _DataManagementScreenState extends ConsumerState<DataManagementScreen> {
  final Map<String, bool> _refreshingTournaments = {};

  @override
  Widget build(BuildContext context) {
    final cacheStats = ref.watch(_cacheStatsProvider);
    final unsyncedCount = ref.watch(unsyncedMatchCountProvider);
    final syncManager = ref.watch(syncManagerProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('데이터 관리'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: cacheStats.when(
        data: (stats) => _buildContent(stats, unsyncedCount, syncManager),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('오류: $error')),
      ),
    );
  }

  Widget _buildContent(
    List<TournamentCacheStats> stats,
    AsyncValue<int> unsyncedCount,
    SyncManager syncManager,
  ) {
    final storageState = ref.watch(dbStorageMonitorProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 동기화 요약 카드
        _buildSyncSummaryCard(unsyncedCount, syncManager),
        const SizedBox(height: 12),

        // DB 용량 현황 카드
        _buildStorageCard(storageState),
        const SizedBox(height: 24),

        // 연결된 대회 섹션
        const Text(
          '연결된 대회',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 12),

        if (stats.isEmpty)
          _buildEmptyState()
        else
          ...stats.map((stat) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildTournamentCard(stat),
              )),
      ],
    );
  }

  Widget _buildSyncSummaryCard(
    AsyncValue<int> unsyncedCount,
    SyncManager syncManager,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              unsyncedCount.when(
                data: (count) => Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: count == 0
                        ? AppTheme.successColor
                        : AppTheme.warningColor,
                    shape: BoxShape.circle,
                  ),
                ),
                loading: () => const SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (_, __) => Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppTheme.errorColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                '동기화 요약',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          unsyncedCount.when(
            data: (count) {
              if (count == 0) {
                return const Text(
                  '모든 데이터가 최신 상태입니다.',
                  style: TextStyle(color: AppTheme.textSecondary),
                );
              }
              return Text(
                '업로드 대기: $count건',
                style: const TextStyle(color: AppTheme.warningColor),
              );
            },
            loading: () => const Text(
              '확인 중...',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            error: (_, __) => const Text(
              '상태 확인 실패',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
          const SizedBox(height: 8),
          StreamBuilder<SyncQueueStatus>(
            stream: syncManager.statusStream,
            builder: (context, snapshot) {
              final status = snapshot.data ?? syncManager.getQueueStatus();
              final bgText = status.isProcessing
                  ? '백그라운드: 동기화 중'
                  : '백그라운드: 대기 중';
              return Text(
                bgText,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStorageCard(DbStorageState storageState) {
    final Color statusColor;
    final IconData statusIcon;
    final String statusText;

    switch (storageState.warningLevel) {
      case StorageWarningLevel.critical:
        statusColor = AppTheme.errorColor;
        statusIcon = Icons.storage;
        statusText = '용량 부족';
      case StorageWarningLevel.warning:
        statusColor = AppTheme.warningColor;
        statusIcon = Icons.disc_full;
        statusText = '주의';
      case StorageWarningLevel.normal:
        statusColor = AppTheme.successColor;
        statusIcon = Icons.check_circle;
        statusText = '정상';
    }

    final percent = (storageState.usagePercent * 100).clamp(0.0, 100.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 18),
              const SizedBox(width: 8),
              const Text(
                'DB 용량',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 프로그레스 바
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: storageState.usagePercent.clamp(0.0, 1.0),
              backgroundColor: AppTheme.textSecondary.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                storageState.formattedSize,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${percent.toStringAsFixed(1)}% / ${storageState.formattedMaxSize}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          if (storageState.needsWarning) ...[
            const SizedBox(height: 8),
            Text(
              storageState.isCritical
                  ? '종료된 대회 데이터를 삭제하여 공간을 확보해주세요.'
                  : '불필요한 대회 데이터를 정리하면 용량을 절약할 수 있습니다.',
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTournamentCard(TournamentCacheStats stat) {
    final isRefreshing = _refreshingTournaments[stat.tournamentId] ?? false;
    final currentTournamentId = ref.read(currentTournamentIdProvider);
    final isCurrentTournament = currentTournamentId == stat.tournamentId;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentTournament
            ? Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 대회 이름 + 상태
          Row(
            children: [
              Expanded(
                child: Text(
                  stat.tournamentName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(stat.tournamentStatus)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusText(stat.tournamentStatus),
                  style: TextStyle(
                    color: _getStatusColor(stat.tournamentStatus),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 캐시 현황
          const Text(
            '캐시 현황',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '팀 ${stat.teamCount}개 · 선수 ${stat.playerCount}명 · 경기 ${stat.matchCount}개',
            style: const TextStyle(fontSize: 14),
          ),
          if (stat.finishedMatchCount > 0 || stat.unsyncedMatchCount > 0) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '기록완료 ${stat.finishedMatchCount}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                if (stat.unsyncedMatchCount > 0) ...[
                  const Text(
                    ' · ',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  Text(
                    '업로드대기 ${stat.unsyncedMatchCount}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.warningColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 12),

          // 마지막 동기화
          const Text(
            '마지막 동기화',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                _formatRelativeTime(stat.lastSyncedAt),
                style: TextStyle(
                  fontSize: 14,
                  color:
                      stat.isSyncStale ? AppTheme.warningColor : null,
                  fontWeight:
                      stat.isSyncStale ? FontWeight.w500 : null,
                ),
              ),
              if (stat.isSyncStale) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.warning_amber,
                  size: 16,
                  color: AppTheme.warningColor,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // 액션 버튼
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isRefreshing
                      ? null
                      : () => _refreshTournament(stat.tournamentId),
                  icon: isRefreshing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh, size: 18),
                  label:
                      Text(isRefreshing ? '새로고침 중...' : '새로고침'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isCurrentTournament
                      ? null
                      : () => _deleteTournament(stat),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isCurrentTournament
                        ? AppTheme.textSecondary
                        : AppTheme.errorColor,
                    side: BorderSide(
                      color: isCurrentTournament
                          ? AppTheme.textSecondary.withValues(alpha: 0.3)
                          : AppTheme.errorColor.withValues(alpha: 0.5),
                    ),
                  ),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('삭제'),
                ),
              ),
            ],
          ),
          if (isCurrentTournament)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                '현재 사용 중인 대회는 삭제할 수 없습니다',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Icon(Icons.storage, size: 48, color: AppTheme.textSecondary),
          SizedBox(height: 12),
          Text(
            '연결된 대회가 없습니다',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshTournament(String tournamentId) async {
    setState(() => _refreshingTournaments[tournamentId] = true);

    final dataRefreshService = ref.read(dataRefreshServiceProvider);
    final result = await dataRefreshService.refreshTournamentData(tournamentId);

    if (!mounted) return;

    setState(() => _refreshingTournaments[tournamentId] = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.summary),
        backgroundColor:
            result.success ? AppTheme.successColor : AppTheme.errorColor,
      ),
    );

    // 캐시 현황 갱신
    ref.invalidate(_cacheStatsProvider);
    ref.invalidate(unsyncedMatchCountProvider);
    ref.read(dbStorageMonitorProvider.notifier).checkNow();
  }

  Future<void> _deleteTournament(TournamentCacheStats stat) async {
    // 미업로드 경기 경고
    if (stat.hasUnsyncedMatches) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('경고'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning,
                        color: AppTheme.errorColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '미업로드 경기 ${stat.unsyncedMatchCount}건이 있습니다.\n삭제 시 기록이 영구적으로 유실됩니다.',
                        style: const TextStyle(
                          color: AppTheme.errorColor,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('${stat.tournamentName}의 모든 데이터를 삭제하시겠습니까?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => context.pop(true),
              style:
                  TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
              child: const Text('삭제'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('데이터 삭제'),
          content:
              Text('${stat.tournamentName}의 캐시 데이터를 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => context.pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => context.pop(true),
              style:
                  TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
              child: const Text('삭제'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    // 삭제 실행
    final db = ref.read(databaseProvider);
    await db.tournamentDao.clearAllTournamentData(stat.tournamentId);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${stat.tournamentName} 데이터가 삭제되었습니다.'),
        backgroundColor: AppTheme.successColor,
      ),
    );

    ref.invalidate(_cacheStatsProvider);
    // 용량 다시 확인 + 경고 리셋
    final monitor = ref.read(dbStorageMonitorProvider.notifier);
    monitor.resetWarnings();
    monitor.checkNow();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ongoing':
        return AppTheme.successColor;
      case 'upcoming':
      case 'registration':
        return AppTheme.primaryColor;
      case 'completed':
        return AppTheme.textSecondary;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'ongoing':
        return '진행 중';
      case 'upcoming':
      case 'registration':
        return '예정';
      case 'completed':
        return '종료됨';
      case 'draft':
        return '준비 중';
      default:
        return status;
    }
  }

  String _formatRelativeTime(DateTime? time) {
    if (time == null) return '동기화 기록 없음';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${time.month}/${time.day}';
  }
}
