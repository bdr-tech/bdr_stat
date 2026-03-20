import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' hide Column;

import '../../../core/theme/app_theme.dart';
import '../../../di/providers.dart';
import '../../../data/api/api_client.dart';
import '../../../data/database/database.dart';

/// 대회 확인 및 데이터 다운로드 화면
class TournamentConfirmScreen extends ConsumerStatefulWidget {
  const TournamentConfirmScreen({
    super.key,
    required this.tournamentId,
    required this.token,
  });

  final String tournamentId;
  final String token;

  @override
  ConsumerState<TournamentConfirmScreen> createState() =>
      _TournamentConfirmScreenState();
}

class _TournamentConfirmScreenState
    extends ConsumerState<TournamentConfirmScreen> {
  TournamentData? _tournament;
  bool _isLoading = true;
  bool _isDownloading = false;
  String? _errorMessage;

  // 다운로드 진행 상태
  String _downloadStatus = '';
  double _downloadProgress = 0;

  @override
  void initState() {
    super.initState();
    _loadTournamentInfo();
  }

  Future<void> _loadTournamentInfo() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      apiClient.setApiToken(widget.token);

      final result = await apiClient.verifyTournament(widget.token);

      if (!mounted) return;

      if (result.isSuccess && result.data != null) {
        setState(() {
          _tournament = result.data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result.error ?? '대회 정보를 불러올 수 없습니다.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '오류: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _downloadAndSave() async {
    setState(() {
      _isDownloading = true;
      _downloadStatus = '데이터 다운로드 중...';
      _downloadProgress = 0.1;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final db = ref.read(databaseProvider);
      final storage = ref.read(secureStorageProvider);

      // 1. 전체 데이터 다운로드
      setState(() {
        _downloadStatus = '대회 데이터 다운로드 중...';
        _downloadProgress = 0.2;
      });

      final result = await apiClient.getTournamentFullData(widget.tournamentId);

      if (!result.isSuccess || result.data == null) {
        throw Exception(result.error ?? '데이터 다운로드 실패');
      }

      final fullData = result.data!;

      // 2. 로컬 DB에 트랜잭션으로 일괄 저장
      setState(() {
        _downloadStatus = '대회 데이터 저장 중...';
        _downloadProgress = 0.4;
      });

      final now = DateTime.now();

      // 대회 + 팀 + 선수 트랜잭션 일괄 저장
      await db.tournamentDao.saveTournamentData(
        tournament: LocalTournamentsCompanion.insert(
          id: fullData.tournament.id,
          name: fullData.tournament.name,
          status: fullData.tournament.status,
          startDate: Value(fullData.tournament.startDate),
          endDate: Value(fullData.tournament.endDate),
          venueName: Value(fullData.tournament.venueName),
          venueAddress: Value(fullData.tournament.venueAddress),
          gameRulesJson: jsonEncode(fullData.tournament.gameRules ?? {}),
          apiToken: widget.token,
          syncedAt: now,
        ),
        teams: fullData.teams.map((team) {
          return LocalTournamentTeamsCompanion.insert(
            id: Value(team.id),
            tournamentId: team.tournamentId,
            teamId: team.teamId,
            teamName: team.teamName,
            teamLogoUrl: Value(team.teamLogoUrl),
            primaryColor: Value(team.primaryColor),
            secondaryColor: Value(team.secondaryColor),
            groupName: Value(team.groupName),
            seedNumber: Value(team.seedNumber),
            syncedAt: now,
          );
        }).toList(),
        players: fullData.players.map((player) {
          return LocalTournamentPlayersCompanion.insert(
            id: Value(player.id),
            tournamentTeamId: player.tournamentTeamId,
            userId: Value(player.userId),
            userName: player.userName,
            userNickname: Value(player.userNickname),
            profileImageUrl: Value(player.profileImageUrl),
            jerseyNumber: Value(player.jerseyNumber),
            position: Value(player.position),
            role: player.role,
            isStarter: Value(player.isStarter),
            isActive: Value(player.isActive),
            bdrDnaCode: Value(player.bdrDnaCode),
            syncedAt: now,
          );
        }).toList(),
      );

      setState(() {
        _downloadStatus = '경기 정보 저장 중...';
        _downloadProgress = 0.85;
      });

      // 경기 저장
      for (final match in fullData.matches) {
        // 홈팀, 어웨이팀 이름 찾기
        final homeTeam = fullData.teams.firstWhere(
          (t) => t.id == match.homeTeamId,
          orElse: () => fullData.teams.first,
        );
        final awayTeam = fullData.teams.firstWhere(
          (t) => t.id == match.awayTeamId,
          orElse: () => fullData.teams.first,
        );

        await db.matchDao.saveMatch(LocalMatchesCompanion.insert(
          serverId: Value(match.id),
          serverUuid: Value(match.uuid),
          localUuid: 'local_${match.uuid}',
          tournamentId: match.tournamentId,
          homeTeamId: match.homeTeamId,
          awayTeamId: match.awayTeamId,
          homeTeamName: homeTeam.teamName,
          awayTeamName: awayTeam.teamName,
          roundName: Value(match.roundName),
          roundNumber: Value(match.roundNumber),
          groupName: Value(match.groupName),
          scheduledAt: Value(match.scheduledAt),
          status: Value(match.status),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }

      // 3. 토큰 저장
      setState(() {
        _downloadStatus = '설정 저장 중...';
        _downloadProgress = 0.95;
      });

      try {
        await storage.write(key: 'api_token', value: widget.token);
        await storage.write(key: 'tournament_id', value: widget.tournamentId);
      } catch (e) {
        // macOS Keychain 권한 문제 - 무시 (앱 재시작 시 재연결 필요)
        debugPrint('⚠️ SecureStorage 저장 실패: $e');
      }

      // 최근 연결 기록 저장
      await db.tournamentDao.saveRecentTournament(RecentTournamentsCompanion.insert(
        tournamentId: widget.tournamentId,
        tournamentName: fullData.tournament.name,
        apiToken: widget.token,
        connectedAt: DateTime.now(),
      ));

      // 현재 대회 ID 설정
      ref.read(currentTournamentIdProvider.notifier).state = widget.tournamentId;

      setState(() {
        _downloadStatus = '완료!';
        _downloadProgress = 1.0;
      });

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // 경기 목록으로 이동
      context.go('/matches');
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _errorMessage = '다운로드 실패: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('대회 확인'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/connect'),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: AppTheme.errorColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/connect'),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_tournament == null) {
      return const Center(
        child: Text('대회 정보를 불러올 수 없습니다.'),
      );
    }

    return _isDownloading ? _buildDownloadProgress() : _buildTournamentInfo();
  }

  Widget _buildTournamentInfo() {
    final tournament = _tournament!;

    return Center(
      child: Container(
        width: 600,
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 대회 아이콘
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.emoji_events,
                size: 48,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),

            // 대회 이름
            Text(
              tournament.name,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // 상태 뱃지
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: _getStatusColor(tournament.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getStatusColor(tournament.status),
                ),
              ),
              child: Text(
                _getStatusText(tournament.status),
                style: TextStyle(
                  color: _getStatusColor(tournament.status),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // 대회 정보
            _buildInfoRow(Icons.calendar_today, '기간',
                _formatDateRange(tournament.startDate, tournament.endDate)),
            if (tournament.venueName != null)
              _buildInfoRow(Icons.location_on, '장소', tournament.venueName!),
            if (tournament.teamCount != null)
              _buildInfoRow(
                  Icons.groups, '참가 팀', '${tournament.teamCount}팀'),

            const SizedBox(height: 32),

            // 연결 버튼
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _downloadAndSave,
                child: const Text(
                  '이 대회에 연결',
                  style: TextStyle(
                    fontSize: 18,
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textSecondary, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadProgress() {
    return Center(
      child: Container(
        width: 400,
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 24),
            Text(
              _downloadStatus,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _downloadProgress,
                minHeight: 8,
                backgroundColor: AppTheme.backgroundColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(_downloadProgress * 100).toInt()}%',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ongoing':
        return AppTheme.successColor;
      case 'upcoming':
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
        return '예정';
      case 'completed':
        return '종료';
      default:
        return status;
    }
  }

  String _formatDateRange(DateTime? start, DateTime? end) {
    if (start == null) return '-';
    final startStr = '${start.month}/${start.day}';
    if (end == null) return startStr;
    final endStr = '${end.month}/${end.day}';
    return '$startStr - $endStr';
  }
}
