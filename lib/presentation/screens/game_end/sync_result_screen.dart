import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/sync_manager.dart';
import '../../../di/providers.dart';
import '../../widgets/dialogs/conflict_resolution_dialog.dart';

/// 동기화 상태
enum SyncStatus {
  pending, // 대기 중
  syncing, // 동기화 중
  success, // 성공
  failed, // 실패
  offline, // 오프라인
  conflict, // 충돌 발생
}

/// 동기화 결과 화면
class SyncResultScreen extends ConsumerStatefulWidget {
  const SyncResultScreen({
    super.key,
    required this.matchId,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.homeScore,
    required this.awayScore,
    this.mvpPlayerId,
  });

  final int matchId;
  final int homeTeamId;
  final int awayTeamId;
  final String homeTeamName;
  final String awayTeamName;
  final int homeScore;
  final int awayScore;
  final int? mvpPlayerId;

  @override
  ConsumerState<SyncResultScreen> createState() => _SyncResultScreenState();
}

class _SyncResultScreenState extends ConsumerState<SyncResultScreen> {
  SyncStatus _status = SyncStatus.pending;
  double _progress = 0.0;
  String _statusMessage = '데이터 저장 중...';
  String? _errorMessage;
  SyncResultData? _syncResult;
  ConflictInfo? _conflictInfo;

  @override
  void initState() {
    super.initState();
    _startSync();
  }

  Future<void> _startSync() async {
    final syncManager = ref.read(syncManagerProvider);

    // 1. 로컬 저장 확인
    setState(() {
      _status = SyncStatus.syncing;
      _progress = 0.2;
      _statusMessage = '로컬 데이터 확인 중...';
    });

    await Future.delayed(const Duration(milliseconds: 500));

    // 2. 네트워크 상태 확인
    setState(() {
      _progress = 0.4;
      _statusMessage = '네트워크 상태 확인 중...';
    });

    final isConnected = await syncManager.checkNetworkConnection();

    if (!isConnected) {
      setState(() {
        _status = SyncStatus.offline;
        _progress = 1.0;
        _statusMessage = '오프라인 모드';
      });
      return;
    }

    // 3. 서버 동기화
    setState(() {
      _progress = 0.6;
      _statusMessage = '서버에 데이터 전송 중...';
    });

    final result = await syncManager.syncMatch(widget.matchId);

    if (result.success) {
      setState(() {
        _status = SyncStatus.success;
        _progress = 1.0;
        _statusMessage = '동기화 완료!';
        _syncResult = result;
      });
    } else if (result.hasConflict == true) {
      // 충돌 발생
      setState(() {
        _status = SyncStatus.conflict;
        _progress = 1.0;
        _statusMessage = '데이터 충돌 발생';
        _errorMessage = result.conflictResolution;
      });

      // 충돌 정보 생성 (캐시된 서버 데이터 사용)
      _buildConflictInfo(syncManager, result);
    } else {
      setState(() {
        _status = SyncStatus.failed;
        _progress = 1.0;
        _statusMessage = '동기화 실패';
        _errorMessage = result.errorMessage;
      });
    }
  }

  Future<void> _buildConflictInfo(SyncManager syncManager, SyncResultData result) async {
    final database = ref.read(databaseProvider);
    final deviceManager = ref.read(deviceManagerProvider);
    final match = await database.matchDao.getMatchById(widget.matchId);
    if (match == null) return;

    final cachedServerData = syncManager.getCachedServerData(match.localUuid);
    if (cachedServerData == null) return;

    final differences = <ConflictDifference>[];

    // 점수 비교
    final serverHomeScore = cachedServerData['home_score'] as int?;
    final serverAwayScore = cachedServerData['away_score'] as int?;

    if (serverHomeScore != null && serverHomeScore != match.homeScore) {
      differences.add(ConflictDifference(
        field: 'home_score',
        fieldLabel: '${widget.homeTeamName} 점수',
        localValue: match.homeScore,
        serverValue: serverHomeScore,
      ));
    }

    if (serverAwayScore != null && serverAwayScore != match.awayScore) {
      differences.add(ConflictDifference(
        field: 'away_score',
        fieldLabel: '${widget.awayTeamName} 점수',
        localValue: match.awayScore,
        serverValue: serverAwayScore,
      ));
    }

    final serverUpdatedAt = cachedServerData['updated_at'] as String?;
    final serverDevice = cachedServerData['device'] as Map<String, dynamic>?;
    final serverDeviceName = serverDevice?['device_name'] as String?;

    // 현재 기기 이름 가져오기
    final currentDevice = deviceManager.currentDevice;
    final localDeviceName = currentDevice?.deviceName ?? '이 기기';

    _conflictInfo = ConflictInfo(
      matchLocalUuid: match.localUuid,
      conflictType: 'server_newer',
      differences: differences,
      localUpdatedAt: match.updatedAt,
      serverUpdatedAt: serverUpdatedAt != null
          ? DateTime.tryParse(serverUpdatedAt) ?? DateTime.now()
          : DateTime.now(),
      localDeviceName: localDeviceName,
      serverDeviceName: serverDeviceName ?? '다른 기기',
      localData: {
        'home_score': match.homeScore,
        'away_score': match.awayScore,
      },
      serverData: cachedServerData,
    );

    setState(() {});
  }

  Future<void> _retrySyn() async {
    setState(() {
      _status = SyncStatus.pending;
      _progress = 0.0;
      _statusMessage = '재시도 중...';
      _errorMessage = null;
    });
    await _startSync();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('경기 저장'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 상태 아이콘
              _buildStatusIcon(),
              const SizedBox(height: 32),

              // 진행 상태
              _buildProgress(),
              const SizedBox(height: 16),

              // 상태 메시지
              Text(
                _statusMessage,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // 에러 메시지
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.errorColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 32),

              // 결과 정보
              if (_status == SyncStatus.success && _syncResult != null)
                _buildSyncResultInfo(),

              // 오프라인 안내
              if (_status == SyncStatus.offline) _buildOfflineInfo(),

              // 충돌 안내
              if (_status == SyncStatus.conflict) _buildConflictInfo2(),

              const SizedBox(height: 32),

              // 버튼
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    IconData icon;
    Color color;
    double size = 80;

    switch (_status) {
      case SyncStatus.pending:
      case SyncStatus.syncing:
        return SizedBox(
          width: size,
          height: size,
          child: const CircularProgressIndicator(
            strokeWidth: 6,
            valueColor: AlwaysStoppedAnimation(AppTheme.primaryColor),
          ),
        );
      case SyncStatus.success:
        icon = Icons.check_circle;
        color = AppTheme.successColor;
        break;
      case SyncStatus.failed:
        icon = Icons.error;
        color = AppTheme.errorColor;
        break;
      case SyncStatus.offline:
        icon = Icons.wifi_off;
        color = AppTheme.warningColor;
        break;
      case SyncStatus.conflict:
        icon = Icons.warning_amber_rounded;
        color = AppTheme.warningColor;
        break;
    }

    return Icon(icon, size: size, color: color);
  }

  Widget _buildProgress() {
    if (_status == SyncStatus.success ||
        _status == SyncStatus.failed ||
        _status == SyncStatus.offline) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: 200,
      child: LinearProgressIndicator(
        value: _progress,
        backgroundColor: AppTheme.dividerColor,
        valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
      ),
    );
  }

  Widget _buildSyncResultInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.successColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_done,
                color: AppTheme.successColor,
              ),
              const SizedBox(width: 8),
              const Text(
                '서버 동기화 완료',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.successColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          // 경기 정보
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.homeTeamName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                ' ${widget.homeScore} : ${widget.awayScore} ',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              Text(
                widget.awayTeamName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_syncResult?.playerCount != null)
            Text(
              '${_syncResult!.playerCount}명 선수 기록 업데이트',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          if (_syncResult?.playByPlayCount != null)
            Text(
              '${_syncResult!.playByPlayCount}개 플레이 기록 저장',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConflictInfo2() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warningColor),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sync_problem,
                color: AppTheme.warningColor,
              ),
              SizedBox(width: 8),
              Text(
                '데이터 충돌 발생',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.warningColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '다른 기기에서 수정된 데이터가 있습니다.\n충돌을 해결해야 동기화를 완료할 수 있습니다.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          if (_conflictInfo != null && _conflictInfo!.significantDifferences.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    '${_conflictInfo!.significantDifferences.length}개의 차이점',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._conflictInfo!.significantDifferences.take(3).map((diff) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${diff.fieldLabel}: ',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                          Text(
                            '${diff.localValue} → ${diff.serverValue}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOfflineInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warningColor),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.save,
                color: AppTheme.warningColor,
              ),
              SizedBox(width: 8),
              Text(
                '로컬 저장 완료',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.warningColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '경기 기록이 기기에 저장되었습니다.\n인터넷 연결 시 자동으로 동기화됩니다.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.warningColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              '미동기화 경기: 1건',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    switch (_status) {
      case SyncStatus.pending:
      case SyncStatus.syncing:
        return const SizedBox.shrink();

      case SyncStatus.success:
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _goToMatchList,
                icon: const Icon(Icons.list),
                label: const Text('경기 목록으로'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _goToBoxScore,
              child: const Text('박스스코어 확인'),
            ),
          ],
        );

      case SyncStatus.failed:
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _retrySyn,
                icon: const Icon(Icons.refresh),
                label: const Text('다시 시도'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _goToMatchList,
              child: const Text('나중에 동기화'),
            ),
          ],
        );

      case SyncStatus.offline:
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _goToMatchList,
                icon: const Icon(Icons.list),
                label: const Text('경기 목록으로'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _retrySyn,
              icon: const Icon(Icons.wifi),
              label: const Text('Wi-Fi 연결 후 재시도'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textPrimary,
                side: const BorderSide(color: AppTheme.dividerColor),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        );

      case SyncStatus.conflict:
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _conflictInfo != null ? _resolveConflict : null,
                icon: const Icon(Icons.tune),
                label: const Text('충돌 해결'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.warningColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _useLocalData,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: const BorderSide(color: AppTheme.primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('이 기기 사용'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _useServerData,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.secondaryColor,
                      side: const BorderSide(color: AppTheme.secondaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('서버 데이터'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _goToMatchList,
              child: const Text('나중에 해결'),
            ),
          ],
        );
    }
  }

  Future<void> _resolveConflict() async {
    if (_conflictInfo == null) return;

    final result = await showConflictResolutionDialog(
      context: context,
      conflict: _conflictInfo!,
    );

    if (result == null) return;

    switch (result.strategy) {
      case ConflictResolutionStrategy.keepLocal:
        await _useLocalData();
        break;
      case ConflictResolutionStrategy.keepServer:
        await _useServerData();
        break;
      case ConflictResolutionStrategy.merge:
      case ConflictResolutionStrategy.manual:
        // TODO: 병합 로직 구현
        await _useLocalData();
        break;
    }
  }

  Future<void> _useLocalData() async {
    setState(() {
      _status = SyncStatus.syncing;
      _statusMessage = '로컬 데이터로 덮어쓰는 중...';
      _progress = 0.5;
    });

    final syncManager = ref.read(syncManagerProvider);

    // 충돌 해결: 로컬 데이터 사용
    final result = await syncManager.resolveConflictWithLocal(widget.matchId);

    if (result.success) {
      setState(() {
        _status = SyncStatus.success;
        _progress = 1.0;
        _statusMessage = '로컬 데이터로 동기화 완료!';
        _syncResult = result;
        _conflictInfo = null;
      });
    } else {
      setState(() {
        _status = SyncStatus.failed;
        _progress = 1.0;
        _statusMessage = '동기화 실패';
        _errorMessage = result.errorMessage;
      });
    }
  }

  Future<void> _useServerData() async {
    setState(() {
      _status = SyncStatus.syncing;
      _statusMessage = '서버 데이터로 복원 중...';
      _progress = 0.5;
    });

    final syncManager = ref.read(syncManagerProvider);

    // 충돌 해결: 서버 데이터 사용
    final result = await syncManager.resolveConflictWithServer(widget.matchId);

    if (result.success) {
      setState(() {
        _status = SyncStatus.success;
        _progress = 1.0;
        _statusMessage = '서버 데이터로 복원 완료!';
        _syncResult = result;
        _conflictInfo = null;
      });
    } else {
      setState(() {
        _status = SyncStatus.failed;
        _progress = 1.0;
        _statusMessage = '복원 실패';
        _errorMessage = result.errorMessage;
      });
    }
  }

  void _goToMatchList() {
    context.go('/matches');
  }

  void _goToBoxScore() {
    context.push(
      '/box-score/${widget.matchId}',
      extra: {
        'homeTeamName': widget.homeTeamName,
        'awayTeamName': widget.awayTeamName,
        'homeTeamId': widget.homeTeamId,
        'awayTeamId': widget.awayTeamId,
        'homeScore': widget.homeScore,
        'awayScore': widget.awayScore,
        'isLive': false,
      },
    );
  }
}
