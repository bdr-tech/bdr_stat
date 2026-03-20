import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../di/providers.dart';
import '../../../data/database/database.dart';
import '../../../core/services/auto_save_manager.dart';
import '../../../core/services/battery_monitor.dart';
import '../../../core/services/app_recovery_service.dart';
import '../../widgets/court/basketball_court.dart';
import '../../widgets/timer/game_timer_widget.dart';
import '../../widgets/action_menu/radial_action_menu.dart';
import '../../widgets/game/team_foul_bonus_widget.dart';
import '../../widgets/dialogs/shot_result_dialog.dart';
import '../../widgets/dialogs/assist_select_dialog.dart';
import '../../widgets/dialogs/rebound_select_dialog.dart';
import '../../widgets/dialogs/free_throw_sequence.dart';
import '../../widgets/dialogs/timeout_dialog.dart';
import '../../widgets/dialogs/quarter_end_dialog.dart';
import '../../widgets/dialogs/overtime_dialog.dart';
import '../../widgets/dialogs/timeout_countdown_dialog.dart';
import '../../providers/undo_stack_provider.dart';
import '../../widgets/game/undo_snackbar.dart';
import '../../widgets/game/possession_arrow_widget.dart';
import '../../widgets/game/live_leader_widget.dart';
import '../../widgets/status/network_status_banner.dart';
import '../../widgets/search/jersey_number_search.dart';
import '../../widgets/dialogs/game_start_checklist_dialog.dart';
import '../../widgets/dialogs/game_share_dialog.dart';
import '../../../core/services/game_share_service.dart';

// Extracted widgets for refactoring
import 'models/player_with_stats.dart';
import 'widgets/court_with_players.dart';
import 'widgets/team_players_panel.dart';
import 'widgets/player_action_menu.dart';
import 'widgets/game_header.dart';
import 'widgets/draggable_bench_section.dart';
import 'widgets/live_game_log.dart';

/// 경기 기록 메인 화면
class GameRecordingScreen extends ConsumerStatefulWidget {
  const GameRecordingScreen({super.key, required this.matchId});

  final int matchId;

  @override
  ConsumerState<GameRecordingScreen> createState() =>
      _GameRecordingScreenState();
}

class _GameRecordingScreenState extends ConsumerState<GameRecordingScreen>
    with WidgetsBindingObserver {
  LocalMatche? _match;
  LocalTournamentTeam? _homeTeam;
  LocalTournamentTeam? _awayTeam;
  List<PlayerWithStats> _homePlayers = [];
  List<PlayerWithStats> _awayPlayers = [];

  bool _isLoading = true;

  // 슛 차트 마커
  final List<ShotMarker> _shotMarkers = [];

  // 마지막 슛 위치 (팝업 위치 + 슛차트 좌표)
  Offset? _lastShotGlobalPos;
  double _lastCourtX = 0;
  double _lastCourtY = 0;
  int _lastCourtZone = 0;

  // 팀 파울 관리
  final TeamFoulManager _teamFoulManager = TeamFoulManager();

  // 쿼터별 점수 관리
  final Map<String, Map<String, int>> _quarterScores = {};

  // 연장전 상태
  bool _isOvertime = false;
  int _overtimeNumber = 0;

  // FR-008/FR-010: 타임아웃 관리
  int _homeTimeoutsUsed = 0;
  int _awayTimeoutsUsed = 0;
  // 타임아웃 설정 (전반/후반/연장)
  int _timeoutsFirstHalf = 2;   // FIBA 기본: 전반 2
  int _timeoutsSecondHalf = 3;  // FIBA 기본: 후반 3
  int _timeoutsOvertime = 1;    // FIBA 기본: 연장 1

  // 서버 상태 동기화 플래그
  bool _serverStatusSynced = true;

  // 등번호 빠른 검색
  bool _showJerseySearch = false;
  String? _initialSearchNumber;
  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    debugPrint('🔴🔴🔴 BUILD v2 - 슛 후속 플로우 적용됨 🔴🔴🔴');
    WidgetsBinding.instance.addObserver(this);
    _loadData();
    _initializeTimer();
    _startAutoSave();
    _startAutoSync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopAutoSync();
    _stopAutoSave();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final autoSaveManager = ref.read(autoSaveManagerProvider.notifier);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // 앱이 백그라운드로 갈 때 저장
        autoSaveManager.onAppBackground();
        break;
      case AppLifecycleState.resumed:
        // 앱이 다시 활성화될 때
        autoSaveManager.onAppForeground();
        // 앱 복귀 시 즉시 동기화 시도
        ref.read(syncManagerProvider).startAutoSync(widget.matchId);
        break;
      default:
        break;
    }
  }

  void _startAutoSave() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(autoSaveManagerProvider.notifier).startAutoSave(widget.matchId);
    });
  }

  /// 서버 자동 동기화 시작 (45초 주기 + 네트워크 복구 감지)
  void _startAutoSync() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncManagerProvider).startAutoSync(widget.matchId);
    });
  }

  /// 서버 자동 동기화 중지
  void _stopAutoSync() {
    ref.read(syncManagerProvider).stopAutoSync();
  }

  void _stopAutoSave() {
    _saveClockToDb(); // 종료 전 시간 저장
    ref.read(autoSaveManagerProvider.notifier).stopAutoSave();
    // 정상 종료 기록
    ref.read(appRecoveryServiceProvider).recordNormalExit();
  }

  /// 현재 타이머 상태를 DB에 저장
  Future<void> _saveClockToDb() async {
    if (_match == null) return;
    final timerState = ref.read(gameTimerProvider);
    final db = ref.read(databaseProvider);
    await db.matchDao.updateMatchClock(
      widget.matchId,
      timerState.quarter,
      timerState.gameClockSeconds,
    );
  }

  /// 선수 스탯이 없을 때 자동 초기화 (다운로드 직후 경기 진입 시)
  Future<void> _initializePlayerStats(AppDatabase db, LocalMatche match) async {
    final homePlayers = await db.tournamentDao.getPlayersByTeam(match.homeTeamId);
    final awayPlayers = await db.tournamentDao.getPlayersByTeam(match.awayTeamId);

    // 스타터 우선, 없으면 첫 5명을 코트에 올림
    final homeStarters = homePlayers.where((p) => p.isStarter).toList();
    final awayStarters = awayPlayers.where((p) => p.isStarter).toList();
    final homeOnCourtIds = homeStarters.length >= 5
        ? homeStarters.take(5).map((p) => p.id).toSet()
        : homePlayers.take(5).map((p) => p.id).toSet();
    final awayOnCourtIds = awayStarters.length >= 5
        ? awayStarters.take(5).map((p) => p.id).toSet()
        : awayPlayers.take(5).map((p) => p.id).toSet();

    for (final p in homePlayers) {
      await db.playerStatsDao.initializeStats(
        matchId: widget.matchId,
        playerId: p.id,
        teamId: match.homeTeamId,
        isOnCourt: homeOnCourtIds.contains(p.id),
      );
    }
    for (final p in awayPlayers) {
      await db.playerStatsDao.initializeStats(
        matchId: widget.matchId,
        playerId: p.id,
        teamId: match.awayTeamId,
        isOnCourt: awayOnCourtIds.contains(p.id),
      );
    }
  }

  void _initializeTimer() {
    // 기본 초기화 (경기 데이터 로드 전 화면 표시용)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final timerNotifier = ref.read(gameTimerProvider.notifier);
      timerNotifier.initialize(quarterMinutes: 10, maxQuarters: 4);
    });
  }

  /// 경기 데이터 로드 후 DB에서 쿼터/시간 복원
  void _restoreTimerFromMatch() {
    final match = _match;
    if (match == null) return;
    final timerNotifier = ref.read(gameTimerProvider.notifier);
    if (match.currentQuarter > 0 || match.gameClockSeconds != 600) {
      timerNotifier.restore(
        quarter: match.currentQuarter > 0 ? match.currentQuarter : 1,
        gameClockSeconds: match.gameClockSeconds,
      );
    }
  }


  Future<void> _loadData() async {
    final db = ref.read(databaseProvider);

    // 경기 정보 로드
    final match = await db.matchDao.getMatchById(widget.matchId);
    if (match == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('경기 정보를 찾을 수 없습니다.')),
        );
        context.pop();
      }
      return;
    }

    // 팀 정보 로드
    final homeTeam = await db.tournamentDao.getTeamById(match.homeTeamId);
    final awayTeam = await db.tournamentDao.getTeamById(match.awayTeamId);

    // 선수 통계 로드
    var homeStats =
        await db.playerStatsDao.getStatsByTeam(widget.matchId, match.homeTeamId);
    var awayStats =
        await db.playerStatsDao.getStatsByTeam(widget.matchId, match.awayTeamId);

    // 선수 스탯이 없으면 자동 초기화 (다운로드 직후 or in_progress 경기 진입 시)
    if (homeStats.isEmpty || awayStats.isEmpty) {
      await _initializePlayerStats(db, match);
      homeStats = await db.playerStatsDao.getStatsByTeam(widget.matchId, match.homeTeamId);
      awayStats = await db.playerStatsDao.getStatsByTeam(widget.matchId, match.awayTeamId);
    }

    // 선수 정보와 통계 결합 (배치 쿼리로 성능 최적화)
    final homePlayerIds = homeStats.map((s) => s.tournamentTeamPlayerId).toList();
    final awayPlayerIds = awayStats.map((s) => s.tournamentTeamPlayerId).toList();

    final homePlayersList = await db.tournamentDao.getPlayersByIds(homePlayerIds);
    final awayPlayersList = await db.tournamentDao.getPlayersByIds(awayPlayerIds);

    final homePlayersMap = {for (var p in homePlayersList) p.id: p};
    final awayPlayersMap = {for (var p in awayPlayersList) p.id: p};

    final homePlayers = <PlayerWithStats>[];
    for (final stat in homeStats) {
      final player = homePlayersMap[stat.tournamentTeamPlayerId];
      if (player != null) {
        homePlayers.add(PlayerWithStats(player: player, stats: stat));
      }
    }

    final awayPlayers = <PlayerWithStats>[];
    for (final stat in awayStats) {
      final player = awayPlayersMap[stat.tournamentTeamPlayerId];
      if (player != null) {
        awayPlayers.add(PlayerWithStats(player: player, stats: stat));
      }
    }

    // 팀 파울 로드
    if (match.teamFoulsJson.isNotEmpty && match.teamFoulsJson != '{}') {
      try {
        final foulsJson = jsonDecode(match.teamFoulsJson) as Map<String, dynamic>;
        _teamFoulManager.fromJson(foulsJson);
      } catch (_) {
        // JSON 파싱 실패 시 무시
      }
    }

    setState(() {
      _match = match;
      _homeTeam = homeTeam;
      _awayTeam = awayTeam;
      _homePlayers = homePlayers;
      _awayPlayers = awayPlayers;
      _isLoading = false;
    });

    // DB에서 타이머 복원 (이어하기)
    _restoreTimerFromMatch();

    // 경기가 아직 시작되지 않았으면 체크리스트 표시
    if ((match.status == 'scheduled' || match.status == 'pending') && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showGameStartChecklist();
      });
    }

    // 이어하기: 로컬은 live인데 서버 동기화가 안 됐을 수 있으므로 재시도
    if (match.status == 'live' && match.serverId != null) {
      _serverStatusSynced = false;
      _syncServerStatus();
    }
  }

  /// 경기 시작 체크리스트 다이얼로그 표시
  Future<void> _showGameStartChecklist() async {
    if (!mounted || _match == null) return;

    final homeOnCourt = _homePlayers.where((p) => p.stats.isOnCourt).length;
    final awayOnCourt = _awayPlayers.where((p) => p.stats.isOnCourt).length;

    final jumpBallWinner = await showGameStartChecklistDialog(
      context: context,
      homeTeamName: _homeTeam?.teamName ?? '홈',
      awayTeamName: _awayTeam?.teamName ?? '원정',
      homeStarterCount: homeOnCourt,
      awayStarterCount: awayOnCourt,
      quarterMinutes: 10, // TODO: 대회 설정에서 가져오기
      totalQuarters: 4,
    );

    if (jumpBallWinner == null) {
      // 취소됨 - 이전 화면으로
      if (mounted) {
        context.pop();
      }
      return;
    }

    // 경기 시작 처리
    await _startGame(jumpBallWinner);
  }

  /// 경기 시작 처리
  Future<void> _startGame(bool homeWinsJumpBall) async {
    final db = ref.read(databaseProvider);
    final haptic = ref.read(hapticServiceProvider);

    // 로컬 상태 업데이트 (live 상태 변경 시 startedAt 자동 설정됨)
    await db.matchDao.updateMatchStatus(widget.matchId, 'live');

    // 서버 동기화 대기 상태로 설정
    _serverStatusSynced = false;

    // 서버에도 경기 시작 알림
    await _syncServerStatus();

    // 점프볼 승자에게 공격권 부여
    final timerNotifier = ref.read(gameTimerProvider.notifier);
    timerNotifier.setPossession(
      homeWinsJumpBall ? Possession.home : Possession.away,
    );

    // 타이머 시작
    timerNotifier.start();

    // 햅틱 피드백
    await haptic.quarterEnd(); // 경기 시작 알림

    // 경기 정보 새로고침
    await _refreshStats();
  }

  /// 서버에 경기 상태(in_progress) 동기화 — 실패 시 플래그 저장, 게임클락 토글 때 재시도
  Future<void> _syncServerStatus() async {
    if (_serverStatusSynced) return;
    if (_match?.serverId == null) return;

    final apiClient = ref.read(apiClientProvider);
    final result = await apiClient.updateMatchStatus(
      _match!.serverId!,
      'in_progress',
    );

    if (result.isSuccess) {
      _serverStatusSynced = true;
      debugPrint('[_syncServerStatus] 서버 상태 변경 성공: in_progress');
    } else {
      debugPrint('[_syncServerStatus] 서버 상태 변경 실패: ${result.error}');
    }
  }

  /// QR 코드 공유 다이얼로그 표시
  void _showShareDialog() {
    if (_match == null) return;

    final timerState = ref.read(gameTimerProvider);
    final shareData = GameShareData(
      matchId: _match!.id,
      serverId: _match!.serverId,
      localUuid: _match!.localUuid,
      homeTeamName: _homeTeam?.teamName ?? '홈',
      awayTeamName: _awayTeam?.teamName ?? '원정',
      homeScore: _match!.homeScore,
      awayScore: _match!.awayScore,
      currentQuarter: timerState.quarter,
      gameClockSeconds: timerState.gameClockSeconds,
      status: _match!.status,
    );

    showGameShareDialog(
      context: context,
      shareData: shareData,
    );
  }

  Future<void> _refreshStats() async {
    if (_match == null) return;

    final db = ref.read(databaseProvider);

    // 경기 새로고침
    final match = await db.matchDao.getMatchById(widget.matchId);

    // 선수 통계 새로고침
    final homeStats =
        await db.playerStatsDao.getStatsByTeam(widget.matchId, _match!.homeTeamId);
    final awayStats =
        await db.playerStatsDao.getStatsByTeam(widget.matchId, _match!.awayTeamId);

    // 배치 쿼리로 선수 정보 조회 (성능 최적화)
    final homePlayerIds = homeStats.map((s) => s.tournamentTeamPlayerId).toList();
    final awayPlayerIds = awayStats.map((s) => s.tournamentTeamPlayerId).toList();

    final homePlayersList = await db.tournamentDao.getPlayersByIds(homePlayerIds);
    final awayPlayersList = await db.tournamentDao.getPlayersByIds(awayPlayerIds);

    final homePlayersMap = {for (var p in homePlayersList) p.id: p};
    final awayPlayersMap = {for (var p in awayPlayersList) p.id: p};

    final homePlayers = <PlayerWithStats>[];
    for (final stat in homeStats) {
      final player = homePlayersMap[stat.tournamentTeamPlayerId];
      if (player != null) {
        homePlayers.add(PlayerWithStats(player: player, stats: stat));
      }
    }

    final awayPlayers = <PlayerWithStats>[];
    for (final stat in awayStats) {
      final player = awayPlayersMap[stat.tournamentTeamPlayerId];
      if (player != null) {
        awayPlayers.add(PlayerWithStats(player: player, stats: stat));
      }
    }

    setState(() {
      _match = match;
      _homePlayers = homePlayers;
      _awayPlayers = awayPlayers;
    });

    // 타이머 상태도 DB에 저장 (이어하기 위해)
    _saveClockToDb();
  }

  // 팀 색상 상수
  static const Color _homeTeamColor = Color(0xFFF97316); // 오렌지
  static const Color _awayTeamColor = Color(0xFF10B981); // 에메랄드 그린

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF080B0F),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 벤치 선수 분리
    final homeBenchPlayers = _homePlayers.where((p) => !p.stats.isOnCourt).toList();
    final awayBenchPlayers = _awayPlayers.where((p) => !p.stats.isOnCourt).toList();
    final isLeftHanded = ref.watch(isLeftHandedProvider);

    return Focus(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: const Color(0xFF080B0F),
        body: Stack(
          children: [
            // ── 배경: 실사 코트 사진 (어두운 오버레이) ──
            Positioned.fill(
              child: Image.asset(
                'assets/images/basketball_court_bg.png',
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.72),
              ),
            ),

            // ── 메인 콘텐츠 ──
            SafeArea(
              child: Stack(
                children: [
                  // 메인 콘텐츠
                  Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // 상태 배너 (배터리 경고, 네트워크 상태)
                  const BatteryWarningBanner(),
                  const NetworkStatusBanner(),

                  // 1. 헤더: 점수 및 쿼터 표시 + 액션 버튼 (9:3 레이아웃)
                  GameHeader(
                    homeTeamName: _homeTeam?.teamName ?? '홈',
                    awayTeamName: _awayTeam?.teamName ?? '원정',
                    homeScore: _match?.homeScore ?? 0,
                    awayScore: _match?.awayScore ?? 0,
                    homeTeamColor: _homeTeamColor,
                    awayTeamColor: _awayTeamColor,
                    isOvertime: _isOvertime,
                    overtimeNumber: _overtimeNumber,
                    onSharePressed: _showShareDialog,
                    onHomeScoreLongPress: () => _showScoreAdjustDialog(isHome: true),
                    onAwayScoreLongPress: () => _showScoreAdjustDialog(isHome: false),
                    onSendTap: _syncMatch,
                    onBoxScoreTap: _openBoxScore,
                    onSettingsTap: _showMatchMenu,
                  ),
                  const SizedBox(height: 16),

                  // 2. 메인 영역: 9:3 그리드 (코트+벤치 | 사이드바)
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _buildMainLayoutChildren(
                        isLeftHanded: isLeftHanded,
                        homeBenchPlayers: homeBenchPlayers,
                        awayBenchPlayers: awayBenchPlayers,
                      ),
                    ),
                  ),
                ],
              ),
            ),


            // 4. 등번호 빠른 검색 오버레이
            if (_showJerseySearch)
              Positioned.fill(
                child: JerseyNumberSearch(
                  homePlayers: _homePlayers,
                  awayPlayers: _awayPlayers,
                  homeTeamColor: _homeTeamColor,
                  awayTeamColor: _awayTeamColor,
                  initialNumber: _initialSearchNumber,
                  onPlayerSelected: (player, isHome) {
                    setState(() {
                      _showJerseySearch = false;
                      _initialSearchNumber = null;
                    });
                    _showPlayerActionMenu(player, isHome);
                  },
                  onDismiss: () {
                    setState(() {
                      _showJerseySearch = false;
                      _initialSearchNumber = null;
                    });
                  },
                ),
              ),
          ],
        ),
      ),
          ],
        ),
      ),
    );
  }

  /// 키보드 이벤트 처리 (등번호 빠른 검색)
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    // 검색 오버레이가 열려있으면 처리 안함
    if (_showJerseySearch) return KeyEventResult.ignored;

    // KeyDownEvent만 처리
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // 숫자 키 감지 (0-9)
    final key = event.logicalKey;
    String? digit;

    if (key == LogicalKeyboardKey.digit0 || key == LogicalKeyboardKey.numpad0) {
      digit = '0';
    } else if (key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.numpad1) {
      digit = '1';
    } else if (key == LogicalKeyboardKey.digit2 || key == LogicalKeyboardKey.numpad2) {
      digit = '2';
    } else if (key == LogicalKeyboardKey.digit3 || key == LogicalKeyboardKey.numpad3) {
      digit = '3';
    } else if (key == LogicalKeyboardKey.digit4 || key == LogicalKeyboardKey.numpad4) {
      digit = '4';
    } else if (key == LogicalKeyboardKey.digit5 || key == LogicalKeyboardKey.numpad5) {
      digit = '5';
    } else if (key == LogicalKeyboardKey.digit6 || key == LogicalKeyboardKey.numpad6) {
      digit = '6';
    } else if (key == LogicalKeyboardKey.digit7 || key == LogicalKeyboardKey.numpad7) {
      digit = '7';
    } else if (key == LogicalKeyboardKey.digit8 || key == LogicalKeyboardKey.numpad8) {
      digit = '8';
    } else if (key == LogicalKeyboardKey.digit9 || key == LogicalKeyboardKey.numpad9) {
      digit = '9';
    }

    if (digit != null) {
      setState(() {
        _showJerseySearch = true;
        _initialSearchNumber = digit;
      });
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  /// 왼손/오른손에 따라 메인 레이아웃 자식 위젯 순서 변경
  List<Widget> _buildMainLayoutChildren({
    required bool isLeftHanded,
    required List<PlayerWithStats> homeBenchPlayers,
    required List<PlayerWithStats> awayBenchPlayers,
  }) {
    final courtSection = Expanded(
      flex: 9,
      child: Column(
        children: [
          // 팀파울 + 타임아웃 상태 바
          _buildTeamStatusBar(),
          const SizedBox(height: 2),
          // 코트 + 스타팅
          Expanded(
            child: CourtWithPlayers(
              homePlayers: _homePlayers.where((p) => p.stats.isOnCourt).toList(),
              awayPlayers: _awayPlayers.where((p) => p.stats.isOnCourt).toList(),
              homeTeamColor: _homeTeamColor,
              awayTeamColor: _awayTeamColor,
              homeTeamName: _homeTeam?.teamName,
              awayTeamName: _awayTeam?.teamName,
              onPlayerTap: _onPlayerTap,
              onRadialAction: _handleRadialAction,
              shotMarkers: _shotMarkers,
              onQuickShot: _handleQuickShot,
              onDragShot: _handleDragShot,
              onShotPosition: (pos, rx, ry, zone) {
                _lastShotGlobalPos = pos;
                _lastCourtX = rx;
                _lastCourtY = ry;
                _lastCourtZone = zone;
              },
            ),
          ),
          // 벤치
          SizedBox(
            height: 48,
            child: DraggableBenchSection(
              homeTeamName: _homeTeam?.teamName ?? '홈',
              awayTeamName: _awayTeam?.teamName ?? '원정',
              homeBenchPlayers: homeBenchPlayers,
              awayBenchPlayers: awayBenchPlayers,
              homeOnCourtPlayers: _homePlayers.where((p) => p.stats.isOnCourt).toList(),
              awayOnCourtPlayers: _awayPlayers.where((p) => p.stats.isOnCourt).toList(),
              homeTeamColor: _homeTeamColor,
              awayTeamColor: _awayTeamColor,
              onSubstitution: _handleSubstitution,
            ),
          ),
        ],
      ),
    );

    final sidebarSection = Expanded(
      flex: 3,
      child: LiveGameLogPanel(
        matchId: widget.matchId,
        homeTeamId: _match?.homeTeamId ?? 0,
        awayTeamId: _match?.awayTeamId ?? 0,
        homeTeamName: _homeTeam?.teamName ?? '홈',
        awayTeamName: _awayTeam?.teamName ?? '원정',
        homeTeamColor: _homeTeamColor,
        awayTeamColor: _awayTeamColor,
        homePlayers: _homePlayers,
        awayPlayers: _awayPlayers,
        onUndoAction: _handleUndoAction,
        onEditAction: _handleEditAction,
        onTimerLongPress: _showTimerAdjustDialog,
        onShotClockLongPress: _showShotClockAdjustDialog,
      ),
    );

    if (isLeftHanded) {
      // 왼손잡이: 사이드바(왼쪽) | 코트(오른쪽) → 오른손이 코트 쪽
      return [sidebarSection, const SizedBox(width: 16), courtSection];
    } else {
      // 오른손잡이(기본): 코트(왼쪽) | 사이드바(오른쪽) → 왼손이 코트 쪽
      return [courtSection, const SizedBox(width: 16), sidebarSection];
    }
  }


  /// 기존 레이아웃 (필요시 전환 가능)
  // ignore: unused_element
  Widget _buildLegacyLayout() {
    return Column(
      children: [
        const BatteryWarningBanner(),
        const NetworkStatusBanner(),
        _buildInfoBar(),
        _buildTimerControlBar(),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: TeamPlayersPanel(
                  team: _homeTeam,
                  players: _homePlayers,
                  isHome: true,
                  onPlayerTap: _onPlayerTap,
                  onRadialAction: _handleRadialAction,
                ),
              ),
              Expanded(
                flex: 6,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CourtWithPlayers(
                      homePlayers: _homePlayers.where((p) => p.stats.isOnCourt).toList(),
                      awayPlayers: _awayPlayers.where((p) => p.stats.isOnCourt).toList(),
                      onPlayerTap: _onPlayerTap,
                      onRadialAction: _handleRadialAction,
                      shotMarkers: _shotMarkers,
                      onDragShot: _handleDragShot,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: TeamPlayersPanel(
                  team: _awayTeam,
                  players: _awayPlayers,
                  isHome: false,
                  onPlayerTap: _onPlayerTap,
                  onRadialAction: _handleRadialAction,
                ),
              ),
            ],
          ),
        ),
        _buildScoreboard(),
      ],
    );
  }

  /// 1. 상단 정보바: 대회명, 날짜, 경기정보, 네트워크 상태
  Widget _buildInfoBar() {
    // 대회 정보 가져오기
    final tournamentName = ref.watch(currentTournamentIdProvider.select(
      (id) => id != null ? '대회' : '대회 미선택',
    ));
    final matchDate = _match?.scheduledAt;
    final dateStr = matchDate != null
        ? '${matchDate.month}/${matchDate.day}'
        : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.cardColor,
      child: Row(
        children: [
          // 뒤로가기
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _showExitConfirmDialog(),
            tooltip: '나가기',
          ),

          // 대회명
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              tournamentName,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 날짜
          if (dateStr.isNotEmpty) ...[
            Text(
              dateStr,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
          ],

          // 경기 정보: Team A vs Team B
          Expanded(
            child: Text(
              '${_homeTeam?.teamName ?? '홈'} vs ${_awayTeam?.teamName ?? '원정'}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // 라운드 정보
          if (_match?.roundName != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.dividerColor),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _match!.roundName!,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],

          // 상태 아이콘들 (배터리, 자동 저장, 네트워크)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BatteryStatusIcon(),
              const SizedBox(width: 4),
              const _AutoSaveStatusIndicator(),
              const SizedBox(width: 4),
              const NetworkStatusIndicator(),
            ],
          ),
          const SizedBox(width: 8),

          // 메뉴
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showMatchMenu,
            tooltip: '메뉴',
          ),
        ],
      ),
    );
  }

  /// 2. 타이머 컨트롤 영역: 경기시간, 쿼터, 공격시간, 제어 버튼
  Widget _buildTimerControlBar() {
    final timerState = ref.watch(gameTimerProvider);
    final timerNotifier = ref.read(gameTimerProvider.notifier);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: AppTheme.surfaceColor,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
          // 경기 시간 (대형) - 탭: 시작/정지, 길게 누르기: 시간 조정
          GestureDetector(
            onTap: () {
              timerNotifier.toggle();
              // 서버 상태 미동기화 시 재시도
              if (!_serverStatusSynced) _syncServerStatus();
            },
            onLongPress: _showTimerAdjustDialog,
            child: Tooltip(
              message: '탭: 시작/정지, 길게 누르기: 시간 조정',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: timerState.isRunning
                      ? AppTheme.primaryColor.withValues(alpha: 0.2)
                      : AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: timerState.isRunning
                        ? AppTheme.primaryColor
                        : AppTheme.borderColor,
                  ),
                ),
                child: Text(
                  timerState.formattedGameClock,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: timerState.isRunning
                        ? AppTheme.primaryColor
                        : AppTheme.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // 쿼터 표시
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _isOvertime ? AppTheme.warningColor : AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _isOvertime
                  ? 'OT${_overtimeNumber > 1 ? _overtimeNumber : ''}'
                  : timerState.quarterLabel,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // 공격 시간 (샷클락) - 길게 누르기: 샷클락 조정
          GestureDetector(
            onLongPress: _showShotClockAdjustDialog,
            child: Tooltip(
              message: '길게 누르기: 샷클락 조정',
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: timerState.shotClockSeconds <= 5
                      ? AppTheme.errorColor
                      : AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: timerState.shotClockSeconds <= 5
                        ? AppTheme.errorColor
                        : AppTheme.borderColor,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  timerState.formattedShotClock,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: timerState.shotClockSeconds <= 5
                        ? Colors.white
                        : AppTheme.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),

          // 제어 버튼들
          Row(
            children: [
              // 일시정지/재개
              IconButton(
                icon: Icon(
                  timerState.isRunning ? Icons.pause : Icons.play_arrow,
                  size: 28,
                ),
                onPressed: timerNotifier.toggle,
                style: IconButton.styleFrom(
                  backgroundColor: timerState.isRunning
                      ? AppTheme.warningColor
                      : AppTheme.successColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(12),
                ),
                tooltip: timerState.isRunning ? '일시정지' : '재개',
              ),
              const SizedBox(width: 8),

              // 24초 리셋
              OutlinedButton(
                onPressed: () => timerNotifier.resetShotClock(seconds: 24),
                child: const Text('24'),
              ),
              const SizedBox(width: 4),

              // 14초 리셋
              OutlinedButton(
                onPressed: timerNotifier.resetShotClock14,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.secondaryColor,
                ),
                child: const Text('14'),
              ),
              const SizedBox(width: 12),

              // 쿼터 종료
              ElevatedButton.icon(
                onPressed: _showQuarterEndDialog,
                icon: const Icon(Icons.skip_next, size: 18),
                label: Text(_isOvertime ? 'OT 종료' : '쿼터 종료'),
              ),
              const SizedBox(width: 8),

              // 타임아웃
              OutlinedButton.icon(
                onPressed: _showTimeoutDialog,
                icon: const Icon(Icons.timer_off, size: 18),
                label: const Text('T/O'),
              ),
              const SizedBox(width: 8),

              // 실행 취소
              IconButton(
                onPressed: _undoLastActionWithConfirm,
                icon: const Icon(Icons.undo),
                tooltip: '실행 취소',
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }

  /// 4. 하단 스코어보드: 팀 파울 + 점수
  Widget _buildScoreboard() {
    // 성능 최적화: 전체 타이머 상태 대신 필요한 quarter만 구독
    final currentQuarter = ref.watch(
      gameTimerProvider.select((state) => state.quarter),
    );
    final homeFouls = _teamFoulManager.getFouls(currentQuarter, true);
    final awayFouls = _teamFoulManager.getFouls(currentQuarter, false);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: AppTheme.cardColor,
      child: Row(
        children: [
          // 홈팀 파울
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // 팀 파울 & 보너스
                TeamFoulBonusWidget(
                  teamName: '팀 파울',
                  fouls: homeFouls,
                  isHome: true,
                  compact: false,
                ),
                const SizedBox(width: 16),
                // 타임아웃 남은 횟수
                TimeoutRemainingWidget(
                  remaining: _match?.homeTimeoutsRemaining ?? 4,
                  isHome: true,
                  compact: false,
                ),
              ],
            ),
          ),

          // 홈팀 점수 - 길게 누르기: 점수 조정
          GestureDetector(
            onLongPress: () => _showScoreAdjustDialog(isHome: true),
            child: Tooltip(
              message: '길게 누르기: 점수 조정',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const PossessionIndicator(isHome: true),
                      const SizedBox(width: 4),
                      Text(
                        _homeTeam?.teamName ?? '홈',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${_match?.homeScore ?? 0}',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.homeTeamColor,
                        ),
                  ),
                ],
              ),
            ),
          ),

          // 중앙: 공격권 화살표
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 공격권 화살표
                PossessionArrowWidget(
                  homeTeamName: _homeTeam?.teamName ?? '홈',
                  awayTeamName: _awayTeam?.teamName ?? '원정',
                  size: PossessionArrowSize.medium,
                  showLabels: false,
                ),
                const SizedBox(height: 4),
                // 점수 구분 콜론
                Text(
                  ':',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ),

          // 원정팀 점수 - 길게 누르기: 점수 조정
          GestureDetector(
            onLongPress: () => _showScoreAdjustDialog(isHome: false),
            child: Tooltip(
              message: '길게 누르기: 점수 조정',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _awayTeam?.teamName ?? '원정',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const PossessionIndicator(isHome: false),
                    ],
                  ),
                  Text(
                    '${_match?.awayScore ?? 0}',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.awayTeamColor,
                        ),
                  ),
                ],
              ),
            ),
          ),

          // 원정팀 파울
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // 타임아웃 남은 횟수
                TimeoutRemainingWidget(
                  remaining: _match?.awayTimeoutsRemaining ?? 4,
                  isHome: false,
                  compact: false,
                ),
                const SizedBox(width: 16),
                // 팀 파울 & 보너스
                TeamFoulBonusWidget(
                  teamName: '팀 파울',
                  fouls: awayFouls,
                  isHome: false,
                  compact: false,
                ),
              ],
            ),
          ),

          // 실시간 리더 표시
          const SizedBox(width: 16),
          ExpandableLiveLeaderPanel(
            homePlayers: _homePlayers,
            awayPlayers: _awayPlayers,
            homeTeamName: _homeTeam?.teamName ?? '홈',
            awayTeamName: _awayTeam?.teamName ?? '원정',
          ),

          // 경기 종료 버튼
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _endGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('경기 종료'),
          ),
        ],
      ),
    );
  }

  void _onPlayerTap(PlayerWithStats player, bool isHome) {
    // 벤치 선수 탭 시에만 하단 팝업 표시
    // 코트 선수는 court_with_players 내부 에어커맨드로 처리
    if (!player.stats.isOnCourt) {
      _showPlayerActionMenu(player, isHome);
    }
  }

  void _handleRadialAction(RadialAction action, PlayerWithStats player, bool isHome) {

    switch (action.id) {
      case '2pt':
        _showShotFlowDialog(player, isHome, ShotType.twoPoint);
        break;
      case '2pt_made':
        _handleQuickShot(player, isHome, false);
        break;
      case '2pt_missed':
        _recordMissedShot(player, isHome, false);
        break;
      case '3pt':
        _showShotFlowDialog(player, isHome, ShotType.threePoint);
        break;
      case '3pt_made':
        _handleQuickShot(player, isHome, true);
        break;
      case '3pt_missed':
        _recordMissedShot(player, isHome, true);
        break;
      case 'ft':
      case 'ft_made':
      case 'ft_missed':
        _showFreeThrowFlow(player, isHome);
        break;
      case 'assist':
        _recordAction(player, isHome, 'assist');
        break;
      case 'rebound':
        _recordAction(player, isHome, 'rebound');
        break;
      case 'offensive_rebound':
        _recordOffensiveRebound(player, isHome);
        break;
      case 'defensive_rebound':
        _recordDefensiveRebound(player, isHome);
        break;
      case 'steal':
        _recordAction(player, isHome, 'steal');
        break;
      case 'block':
        _handleBlockWithRebound(player, isHome);
        break;
      case 'turnover':
        _recordAction(player, isHome, 'turnover');
        break;
      case 'foul':
        // FR-012: 파울은 서브메뉴에서 처리 (RadialActionMenu가 자동으로 서브메뉴 열음)
        // 레거시 호환: 서브메뉴 없이 호출될 경우 기본 personal foul
        _recordAction(player, isHome, 'foul');
        break;
      // FR-012: 파울 서브타입 처리
      case 'foul_offensive':
      case 'foul_personal':
      case 'foul_technical':
      case 'foul_unsportsmanlike':
      case 'foul_flagrant1':
      case 'foul_flagrant2':
        _recordFoulWithSubtype(player, isHome, action.id);
        break;
    }
  }

  /// 파울 서브타입 기록 (FR-012)
  Future<void> _recordFoulWithSubtype(PlayerWithStats player, bool isHome, String foulActionId) async {
    final db = ref.read(databaseProvider);
    final haptic = ref.read(hapticServiceProvider);

    try {
      // 파울 타입별 기록
      if (foulActionId == 'foul_technical') {
        await db.playerStatsDao.recordTechnicalFoul(widget.matchId, player.player.id);
      } else if (foulActionId == 'foul_unsportsmanlike') {
        await db.playerStatsDao.recordUnsportsmanlikeFoul(widget.matchId, player.player.id);
      } else {
        await db.playerStatsDao.recordFoul(widget.matchId, player.player.id);
      }
      final timerState = ref.read(gameTimerProvider);
      _teamFoulManager.addFoul(timerState.quarter, isHome);
      await db.matchDao.updateTeamFouls(
        widget.matchId,
        jsonEncode(_teamFoulManager.toJson()),
      );
      await haptic.foulRecorded();

      // 오펜스 파울 → 턴오버 자동 기록
      if (foulActionId == 'foul_offensive') {
        await db.playerStatsDao.recordTurnover(widget.matchId, player.player.id);
      }

      // 라이브 로그에 기록
      ref.read(undoStackProvider.notifier).recordFoul(
        playerId: player.player.id,
        playerName: player.player.userName,
        matchId: widget.matchId,
        isHome: isHome,
        foulType: foulActionId,
      );

      await _refreshStats();

      // 파울아웃(5파울) 또는 T+U 2개 → 자동 벤치 (교체 필요)
      final updatedStats = await db.playerStatsDao.getPlayerStats(widget.matchId, player.player.id);
      final isFouledOut = (updatedStats?.personalFouls ?? 0) >= 5;
      final isEjected = (updatedStats?.technicalFouls ?? 0) + (updatedStats?.unsportsmanlikeFouls ?? 0) >= 2;

      if ((isFouledOut || isEjected) && (updatedStats?.isOnCourt ?? false)) {
        if (mounted) {
          await _showFoulOutSubstitution(player, isHome, isEjected ? '퇴장 (T+U 2개)' : '파울아웃 (5파울)');
        }
      }
    } catch (e) {
      debugPrint('[RecordAction] Error recording foul ($foulActionId): $e');
    }
  }

  /// 파울아웃/퇴장 시 강제 교체 다이얼로그
  Future<void> _showFoulOutSubstitution(PlayerWithStats fouledOutPlayer, bool isHome, String reason) async {
    final benchPlayers = (isHome ? _homePlayers : _awayPlayers)
        .where((p) => !p.stats.isOnCourt && p.stats.personalFouls < 5)
        .toList();

    if (benchPlayers.isEmpty) {
      // 벤치에 교체 가능한 선수가 없으면 그냥 벤치로 내림
      final db = ref.read(databaseProvider);
      await db.playerStatsDao.setOnCourt(widget.matchId, fouledOutPlayer.player.id, false);
      await _refreshStats();
      return;
    }

    if (!mounted) return;

    final subIn = await showDialog<PlayerWithStats>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.errorColor),
              ),
              child: Text(
                '#${fouledOutPlayer.player.jerseyNumber ?? '-'} $reason',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.errorColor,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '교체 선수를 선택하세요',
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
          ],
        ),
        content: SizedBox(
          width: 300,
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: benchPlayers.map((p) {
              final teamColor = isHome ? _homeTeamColor : _awayTeamColor;
              return InkWell(
                onTap: () => Navigator.of(context).pop(p),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: teamColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: teamColor, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '${p.player.jerseyNumber ?? '-'}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: teamColor,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );

    if (subIn != null) {
      await _handleSubstitution(fouledOutPlayer, subIn, isHome);
    } else {
      // 다이얼로그 닫혔지만 선택 안 한 경우에도 벤치로 내림
      final db = ref.read(databaseProvider);
      await db.playerStatsDao.setOnCourt(widget.matchId, fouledOutPlayer.player.id, false);
      await _refreshStats();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // FR-008/FR-009: 타임아웃 + 팀파울 상태 바
  // ═══════════════════════════════════════════════════════════════

  /// 현재 half의 타임아웃 허용 횟수 (GameRulesModel 연동 FR-010)
  int _getTimeoutsAllowed() {
    final timerState = ref.read(gameTimerProvider);
    final quarter = timerState.quarter;
    if (quarter <= 2) return _timeoutsFirstHalf;
    if (quarter <= 4) return _timeoutsSecondHalf;
    return _timeoutsOvertime;
  }

  /// 팀파울 + 타임아웃 상태 바 (벤치 섹션 위에 표시)
  Widget _buildTeamStatusBar() {
    final timerState = ref.read(gameTimerProvider);
    final quarter = timerState.quarter;
    final maxTimeouts = _getTimeoutsAllowed();
    final homeFouls = _teamFoulManager.getFouls(quarter, true);
    final awayFouls = _teamFoulManager.getFouls(quarter, false);
    final homeTimeoutsRemaining = (maxTimeouts - _homeTimeoutsUsed).clamp(0, maxTimeouts);
    final awayTimeoutsRemaining = (maxTimeouts - _awayTimeoutsUsed).clamp(0, maxTimeouts);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor, width: 0.5),
      ),
      child: Row(
        children: [
          // 홈팀 상태
          Expanded(child: _buildTeamStatusSide(
            teamName: _homeTeam?.teamName ?? '홈',
            teamColor: _homeTeamColor,
            fouls: homeFouls,
            timeoutsRemaining: homeTimeoutsRemaining,
            maxTimeouts: maxTimeouts,
            isHome: true,
          )),
          Container(width: 1, height: 32, color: AppTheme.borderColor),
          // 원정팀 상태
          Expanded(child: _buildTeamStatusSide(
            teamName: _awayTeam?.teamName ?? '원정',
            teamColor: _awayTeamColor,
            fouls: awayFouls,
            timeoutsRemaining: awayTimeoutsRemaining,
            maxTimeouts: maxTimeouts,
            isHome: false,
          )),
        ],
      ),
    );
  }

  Widget _buildTeamStatusSide({
    required String teamName,
    required Color teamColor,
    required int fouls,
    required int timeoutsRemaining,
    required int maxTimeouts,
    required bool isHome,
  }) {
    final isInBonus = fouls >= 5;
    final canCallTimeout = timeoutsRemaining > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          // 파울 표시
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'F$fouls',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isInBonus ? AppTheme.warningColor : AppTheme.textSecondary,
                  ),
                ),
                if (isInBonus) ...[
                  const SizedBox(width: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text('B', style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              ],
            ),
          ),
          // T/O 버튼 (탭: 사용, 롱프레스: 설정)
          GestureDetector(
            onTap: canCallTimeout ? () => _handleTimeoutCalled(isHome) : null,
            onLongPress: () => _showTimeoutSettingsDialog(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: canCallTimeout ? teamColor.withValues(alpha: 0.15) : Colors.grey[800],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: canCallTimeout ? teamColor.withValues(alpha: 0.3) : Colors.grey[700]!,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_off, size: 12, color: canCallTimeout ? teamColor : Colors.grey[500]),
                  const SizedBox(width: 3),
                  Text(
                    'T/O $timeoutsRemaining',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: canCallTimeout ? teamColor : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 타임아웃 갯수 설정 팝업 (경기 전 세팅)
  void _showTimeoutSettingsDialog() {
    int firstHalf = _timeoutsFirstHalf;
    int secondHalf = _timeoutsSecondHalf;
    int overtime = _timeoutsOvertime;

    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 16)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('타임아웃 설정', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                    ),
                    child: const Text(
                      'FIBA 규칙: 전반에 사용하지 않은 타임아웃은\n후반으로 이월되지 않습니다.',
                      style: TextStyle(fontSize: 11, color: Colors.amber, height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _timeoutRow('전반 (Q1-Q2)', firstHalf, (v) => setDialogState(() => firstHalf = v)),
                  const SizedBox(height: 8),
                  _timeoutRow('후반 (Q3-Q4)', secondHalf, (v) => setDialogState(() => secondHalf = v)),
                  const SizedBox(height: 8),
                  _timeoutRow('연장 (OT)', overtime, (v) => setDialogState(() => overtime = v)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.cardColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.borderColor),
                            ),
                            child: const Center(child: Text('취소', style: TextStyle(fontSize: 13))),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _timeoutsFirstHalf = firstHalf;
                              _timeoutsSecondHalf = secondHalf;
                              _timeoutsOvertime = overtime;
                            });
                            Navigator.pop(ctx);
                            HapticFeedback.heavyImpact();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.5)),
                            ),
                            child: const Center(child: Text('저장', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryColor))),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _timeoutRow(String label, int value, ValueChanged<int> onChanged) {
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        GestureDetector(
          onTap: () { if (value > 0) onChanged(value - 1); HapticFeedback.heavyImpact(); },
          child: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: const Center(child: Text('-', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          ),
        ),
        SizedBox(
          width: 40,
          child: Center(
            child: Text('$value', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
        GestureDetector(
          onTap: () { if (value < 5) onChanged(value + 1); HapticFeedback.heavyImpact(); },
          child: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: const Center(child: Text('+', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          ),
        ),
      ],
    );
  }

  /// 타임아웃 호출 처리 (FR-008)
  Future<void> _handleTimeoutCalled(bool isHome) async {
    try {
      if (isHome) {
        _homeTimeoutsUsed++;
      } else {
        _awayTimeoutsUsed++;
      }

      // play-by-play 기록
      ref.read(undoStackProvider.notifier).recordTimeout(
        matchId: widget.matchId,
        isHome: isHome,
        teamName: isHome ? (_homeTeam?.teamName ?? '홈') : (_awayTeam?.teamName ?? '원정'),
      );

      final haptic = ref.read(hapticServiceProvider);
      await haptic.statRecorded();

      // 게임클락 일시정지
      final timerNotifier = ref.read(gameTimerProvider.notifier);
      timerNotifier.pause();

      if (mounted) {
        setState(() {});

        // 60초 카운트다운 오버레이 표시
        final teamColor = isHome ? _homeTeamColor : _awayTeamColor;
        TimeoutCountdownOverlay.show(
          context: context,
          isHome: isHome,
          teamColor: teamColor,
        );
      }
    } catch (e) {
      debugPrint('[Timeout] Error: $e');
    }
  }

  /// 슛 실패 직접 기록 (다이얼로그 없이)
  Future<void> _recordMissedShot(PlayerWithStats player, bool isHome, bool isThreePointer) async {

    final haptic = ref.read(hapticServiceProvider);
    final db = ref.read(databaseProvider);
    await haptic.shotMissed();

    if (isThreePointer) {
      await db.playerStatsDao.recordThreePointer(widget.matchId, player.player.id, false);
    } else {
      await db.playerStatsDao.recordTwoPointer(widget.matchId, player.player.id, false);
    }

    // 라이브 로그에 기록
    ref.read(undoStackProvider.notifier).recordShot(
      playerId: player.player.id,
      playerName: player.player.userName,
      matchId: widget.matchId,
      isMade: false,
      isThreePointer: isThreePointer,
      isHome: isHome,
    );

    await _refreshStats();
  }

  /// 공격 리바운드 직접 기록 (1-클릭)
  Future<void> _recordOffensiveRebound(PlayerWithStats player, bool isHome) async {
    try {
      final db = ref.read(databaseProvider);
      final haptic = ref.read(hapticServiceProvider);
      await db.playerStatsDao.recordRebound(widget.matchId, player.player.id, true);
      await haptic.statRecorded();
      ref.read(undoStackProvider.notifier).recordRebound(
        playerId: player.player.id, playerName: player.player.userName,
        matchId: widget.matchId, isOffensive: true, isHome: isHome,
      );
      await _refreshStats();
    } catch (e) {
      debugPrint('[RecordAction] Error recording offensive rebound: $e');
    }
  }

  /// 수비 리바운드 직접 기록 (1-클릭)
  Future<void> _recordDefensiveRebound(PlayerWithStats player, bool isHome) async {
    try {
      final db = ref.read(databaseProvider);
      final haptic = ref.read(hapticServiceProvider);
      await db.playerStatsDao.recordRebound(widget.matchId, player.player.id, false);
      await haptic.statRecorded();
      ref.read(undoStackProvider.notifier).recordRebound(
        playerId: player.player.id, playerName: player.player.userName,
        matchId: widget.matchId, isOffensive: false, isHome: isHome,
      );
      await _refreshStats();
    } catch (e) {
      debugPrint('[RecordAction] Error recording defensive rebound: $e');
    }
  }

  /// 빠른 슛 기록 (성공)
  Future<void> _handleQuickShot(PlayerWithStats player, bool isHome, bool isThreePointer) async {

    final haptic = ref.read(hapticServiceProvider);
    final db = ref.read(databaseProvider);

    try {
      if (isThreePointer) {
        await haptic.threePointerMade();
      } else {
        await haptic.shotMade();
      }

      final currentHome = _match?.homeScore ?? 0;
      final currentAway = _match?.awayScore ?? 0;

      final points = isThreePointer ? 3 : 2;
      final scoringTeamId = isHome ? _match!.homeTeamId : _match!.awayTeamId;
      final opponentTeamId = isHome ? _match!.awayTeamId : _match!.homeTeamId;

      if (isThreePointer) {
        await db.playerStatsDao.recordThreePointer(widget.matchId, player.player.id, true);
        await db.matchDao.updateScore(
          widget.matchId,
          isHome ? currentHome + 3 : currentHome,
          isHome ? currentAway : currentAway + 3,
        );
      } else {
        await db.playerStatsDao.recordTwoPointer(widget.matchId, player.player.id, true);
        await db.matchDao.updateScore(
          widget.matchId,
          isHome ? currentHome + 2 : currentHome,
          isHome ? currentAway : currentAway + 2,
        );
      }

      // FR-003: +/- 코트마진 업데이트
      await db.playerStatsDao.applyPlusMinusForScore(
        matchId: widget.matchId,
        scoringTeamId: scoringTeamId,
        opponentTeamId: opponentTeamId,
        points: points,
      );

      final timerNotifier = ref.read(gameTimerProvider.notifier);
      timerNotifier.setPossession(isHome ? Possession.away : Possession.home);

      // 라이브 로그에 기록
      ref.read(undoStackProvider.notifier).recordShot(
        playerId: player.player.id,
        playerName: player.player.userName,
        matchId: widget.matchId,
        isMade: true,
        isThreePointer: isThreePointer,
        isHome: isHome,
      );

      await _refreshStats();
    } catch (e) {
      debugPrint('[RecordAction] Error recording quick shot: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('슛 기록 실패: $e'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// 드래그 슛: 선수를 코트 위 특정 위치로 드래그해서 놓으면
  /// 해당 위치를 슛 차트에 기록하고 선수를 선택 상태로 전환
  void _handleDragShot(PlayerWithStats player, bool isHome, double x, double y, int zone) {
    // 에어커맨드에서 슈팅 액션을 선택하면 _handleRadialAction이 호출됨
    // 여기서는 드롭 위치만 표시 — 에어커맨드에서 성공/실패 선택
  }

  /// 블락 기록 후 리바운드 선택
  Future<void> _handleBlockWithRebound(PlayerWithStats player, bool isHome) async {
    final db = ref.read(databaseProvider);
    final haptic = ref.read(hapticServiceProvider);

    // 1. 블락 기록
    await db.playerStatsDao.recordBlock(widget.matchId, player.player.id);
    await haptic.statRecorded();

    ref.read(undoStackProvider.notifier).recordBlock(
      playerId: player.player.id,
      playerName: player.player.userName,
      matchId: widget.matchId,
      isHome: isHome,
    );

    // 2. 컴팩트 리바운드 선택 (블락한 팀 = 수비, 상대 = 공격)
    // shooter 기준: 블락당한 팀이 공격팀
    final dummyShooter = (isHome ? _awayPlayers : _homePlayers).firstOrNull;
    if (mounted && dummyShooter != null) {
      await _showCompactReboundPicker(dummyShooter, !isHome);
    }

    await _refreshStats();
  }

  /// 슛 기록 플로우 — 컴팩트 인라인 팝업
  Future<void> _showShotFlowDialog(PlayerWithStats player, bool isHome, ShotType shotType) async {
    final haptic = ref.read(hapticServiceProvider);
    final ptLabel = shotType == ShotType.threePoint ? '3점' : '2점';

    // 슛 위치 기준 팝업 좌표
    final shotPos = _lastShotGlobalPos;
    final screen = MediaQuery.of(context).size;

    // 1. 성공/실패 — 슛 위치 기준 팝업
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black26,
      builder: (ctx) => Stack(
        children: [
          // 배경 탭 → 취소
          Positioned.fill(child: GestureDetector(onTap: () => Navigator.pop(ctx))),
          Positioned(
            left: shotPos != null ? (shotPos.dx - 80).clamp(8, screen.width - 170) : screen.width / 2 - 80,
            top: shotPos != null ? (shotPos.dy - 36).clamp(8, screen.height - 80) : screen.height / 2 - 36,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 12)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _compactBtn('성공', AppTheme.shotMadeColor, () {
                      HapticFeedback.heavyImpact();
                      Navigator.pop(ctx, true);
                    }),
                    const SizedBox(width: 8),
                    _compactBtn('실패', AppTheme.shotMissedColor, () {
                      HapticFeedback.heavyImpact();
                      Navigator.pop(ctx, false);
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (result == null) return;
    final isMade = result;
    final db = ref.read(databaseProvider);

    if (isMade) {
      await haptic.shotMade();
    } else {
      await haptic.shotMissed();
    }

    // 2. DB 기록
    final curHome = _match?.homeScore ?? 0;
    final curAway = _match?.awayScore ?? 0;
    if (shotType == ShotType.twoPoint) {
      await db.playerStatsDao.recordTwoPointer(widget.matchId, player.player.id, isMade);
      if (isMade) {
        await db.matchDao.updateScore(widget.matchId,
          isHome ? curHome + 2 : curHome, isHome ? curAway : curAway + 2);
        await db.playerStatsDao.applyPlusMinusForScore(
          matchId: widget.matchId,
          scoringTeamId: isHome ? _match!.homeTeamId : _match!.awayTeamId,
          opponentTeamId: isHome ? _match!.awayTeamId : _match!.homeTeamId,
          points: 2,
        );
      }
    } else if (shotType == ShotType.threePoint) {
      await db.playerStatsDao.recordThreePointer(widget.matchId, player.player.id, isMade);
      if (isMade) {
        await db.matchDao.updateScore(widget.matchId,
          isHome ? curHome + 3 : curHome, isHome ? curAway : curAway + 3);
        await db.playerStatsDao.applyPlusMinusForScore(
          matchId: widget.matchId,
          scoringTeamId: isHome ? _match!.homeTeamId : _match!.awayTeamId,
          opponentTeamId: isHome ? _match!.awayTeamId : _match!.homeTeamId,
          points: 3,
        );
      }
    }

    // PBP 기록 (슛 좌표 포함)
    final teamId = isHome ? (_match?.homeTeamId ?? 0) : (_match?.awayTeamId ?? 0);
    final isThree = shotType == ShotType.threePoint;
    await _recordPBP(
      playerId: player.player.id,
      teamId: teamId,
      actionType: 'shot',
      actionSubtype: isThree ? '3pt' : '2pt',
      isMade: isMade,
      pointsScored: isMade ? (isThree ? 3 : 2) : 0,
      courtX: _lastCourtX,
      courtY: _lastCourtY,
      courtZone: _lastCourtZone,
    );

    // 3. 성공 → 어시스트 (백넘버 그리드)
    if (isMade && mounted) {
      final timerNotifier = ref.read(gameTimerProvider.notifier);
      timerNotifier.setPossession(isHome ? Possession.away : Possession.home);

      final teammates = (isHome ? _homePlayers : _awayPlayers)
          .where((p) => p.player.id != player.player.id && p.stats.isOnCourt)
          .toList();

      final assister = await showDialog<PlayerWithStats?>(
        context: context,
        barrierColor: Colors.black26,
        builder: (ctx) => Stack(
          children: [
            Positioned.fill(child: GestureDetector(onTap: () => Navigator.pop(ctx, null))),
            Positioned(
              left: shotPos != null ? (shotPos.dx - 140).clamp(8, screen.width - 288) : screen.width / 2 - 140,
              top: shotPos != null ? (shotPos.dy - 30).clamp(8, screen.height - 120) : screen.height / 2 - 60,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  constraints: const BoxConstraints(maxWidth: 280),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 12)],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('어시스트', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: teammates.map((t) => _jerseyBtn(
                          '${t.jerseyNumber ?? '-'}',
                          isHome ? _homeTeamColor : _awayTeamColor,
                          () { HapticFeedback.heavyImpact(); Navigator.pop(ctx, t); },
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );

      if (assister != null) {
        await db.playerStatsDao.recordAssist(widget.matchId, assister.player.id);
      }
    }

    // 4. 실패 → 리바운드/블락 (백넘버 그리드)
    if (!isMade && mounted) {
      await _showCompactReboundPicker(player, isHome, showBlockOption: false);
    }

    // 라이브 로그에 기록
    ref.read(undoStackProvider.notifier).recordShot(
      playerId: player.player.id,
      playerName: player.player.userName,
      matchId: widget.matchId,
      isMade: isMade,
      isThreePointer: shotType == ShotType.threePoint,
      isHome: isHome,
    );

    await _refreshStats();
  }

  // ─── 컴팩트 UI 헬퍼 ──────────────────────────────────────────────────────

  // ─── Play-by-Play 기록 헬퍼 ──────────────────────────────────────────────

  Future<void> _recordPBP({
    required int playerId,
    required int teamId,
    required String actionType,
    String? actionSubtype,
    bool? isMade,
    int pointsScored = 0,
    double? courtX,
    double? courtY,
    int? courtZone,
    int? assistPlayerId,
    int? reboundPlayerId,
    int? blockPlayerId,
  }) async {
    try {
      final db = ref.read(databaseProvider);
      final timerState = ref.read(gameTimerProvider);
      final localId = DateTime.now().microsecondsSinceEpoch.toString();

      await db.playByPlayDao.insertPlay(LocalPlayByPlaysCompanion(
        localId: Value(localId),
        localMatchId: Value(widget.matchId),
        tournamentTeamPlayerId: Value(playerId),
        tournamentTeamId: Value(teamId),
        quarter: Value(timerState.quarter),
        gameClockSeconds: Value(timerState.gameClockSeconds),
        shotClockSeconds: Value(timerState.shotClockSeconds),
        actionType: Value(actionType),
        actionSubtype: Value(actionSubtype),
        isMade: Value(isMade),
        pointsScored: Value(pointsScored),
        courtX: Value(courtX),
        courtY: Value(courtY),
        courtZone: Value(courtZone),
        homeScoreAtTime: Value(_match?.homeScore ?? 0),
        awayScoreAtTime: Value(_match?.awayScore ?? 0),
        assistPlayerId: Value(assistPlayerId),
        reboundPlayerId: Value(reboundPlayerId),
        blockPlayerId: Value(blockPlayerId),
        createdAt: Value(DateTime.now()),
        isSynced: const Value(false),
      ));
      debugPrint('[PBP] Recorded: $actionType ${actionSubtype ?? ''} player=$playerId courtX=$courtX courtY=$courtY');
    } catch (e) {
      debugPrint('[PBP] ERROR recording $actionType: $e');
    }
  }

  Widget _compactBtn(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 56,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8)],
        ),
        child: Center(
          child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _jerseyBtn(String number, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
        ),
        child: Center(
          child: Text(number, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  /// 컴팩트 리바운드 선택 (백넘버 그리드)
  Future<void> _showCompactReboundPicker(PlayerWithStats shooter, bool shooterIsHome, {bool showBlockOption = false}) async {
    final db = ref.read(databaseProvider);
    // 슛한 팀 = 공격팀, 상대 = 수비팀
    final offensePlayers = (shooterIsHome ? _homePlayers : _awayPlayers).where((p) => p.stats.isOnCourt).toList();
    final defensePlayers = (shooterIsHome ? _awayPlayers : _homePlayers).where((p) => p.stats.isOnCourt).toList();
    final offenseTeamName = shooterIsHome ? (_homeTeam?.teamName ?? '홈') : (_awayTeam?.teamName ?? '원정');
    final defenseTeamName = shooterIsHome ? (_awayTeam?.teamName ?? '원정') : (_homeTeam?.teamName ?? '홈');
    final offenseColor = shooterIsHome ? _homeTeamColor : _awayTeamColor;
    final defenseColor = shooterIsHome ? _awayTeamColor : _homeTeamColor;

    final shotPos = _lastShotGlobalPos;
    final screen = MediaQuery.of(context).size;

    final result = await showDialog<({PlayerWithStats? player, bool isOffensive, bool isTeamRebound, bool isBlock})?>(
      context: context,
      barrierColor: Colors.black26,
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(child: GestureDetector(onTap: () => Navigator.pop(ctx))),
          Positioned(
            left: shotPos != null ? (shotPos.dx - 150).clamp(8, screen.width - 308) : screen.width / 2 - 150,
            top: shotPos != null ? (shotPos.dy - 40).clamp(8, screen.height - 280) : screen.height / 2 - 120,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(10),
            constraints: const BoxConstraints(maxWidth: 300),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 12)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('리바운드', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                    if (showBlockOption) ...[
                      const SizedBox(width: 12),
                      const Text('|', style: TextStyle(color: AppTheme.textSecondary)),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.heavyImpact();
                          Navigator.pop(ctx, (player: null, isOffensive: false, isTeamRebound: false, isBlock: true));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.pink.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.pink.withValues(alpha: 0.5)),
                          ),
                          child: const Text('블락', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.pink)),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),

                // 수비팀 (상대) — 수비리바운드
                Text('$defenseTeamName (수비REB)', style: TextStyle(fontSize: 10, color: defenseColor)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ...defensePlayers.map((p) => _jerseyBtn(
                      '${p.jerseyNumber ?? '-'}', defenseColor,
                      () { HapticFeedback.heavyImpact(); Navigator.pop(ctx, (player: p, isOffensive: false, isTeamRebound: false, isBlock: false)); },
                    )),
                    // 팀 리바운드
                    GestureDetector(
                      onTap: () { HapticFeedback.heavyImpact(); Navigator.pop(ctx, (player: null, isOffensive: false, isTeamRebound: true, isBlock: false)); },
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: defenseColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: defenseColor.withValues(alpha: 0.3)),
                        ),
                        child: Center(child: Text(defenseTeamName, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: defenseColor))),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(height: 1, color: AppTheme.borderColor),
                const SizedBox(height: 8),

                // 공격팀 (우리) — 공격리바운드
                Text('$offenseTeamName (공격REB)', style: TextStyle(fontSize: 10, color: offenseColor)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ...offensePlayers.map((p) => _jerseyBtn(
                      '${p.jerseyNumber ?? '-'}', offenseColor,
                      () { HapticFeedback.heavyImpact(); Navigator.pop(ctx, (player: p, isOffensive: true, isTeamRebound: false, isBlock: false)); },
                    )),
                    GestureDetector(
                      onTap: () { HapticFeedback.heavyImpact(); Navigator.pop(ctx, (player: null, isOffensive: true, isTeamRebound: true, isBlock: false)); },
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: offenseColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: offenseColor.withValues(alpha: 0.3)),
                        ),
                        child: Center(child: Text(offenseTeamName, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: offenseColor))),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
          ),
        ],
      ),
    );

    if (result == null) return;

    if (result.isBlock) {
      // 블락 처리는 caller에서
      return;
    }

    if (result.player != null) {
      await db.playerStatsDao.recordRebound(
        widget.matchId,
        result.player!.player.id,
        result.isOffensive,
      );
    }

    // 공격권 전환
    final timerNotifier = ref.read(gameTimerProvider.notifier);
    if (result.isOffensive) {
      timerNotifier.setPossession(shooterIsHome ? Possession.home : Possession.away);
    } else {
      timerNotifier.setPossession(shooterIsHome ? Possession.away : Possession.home);
    }

    await _refreshStats();
  }

  /// 자유투 시퀀스 플로우
  Future<void> _showFreeThrowFlow(PlayerWithStats player, bool isHome, {int? initialCount}) async {
    final haptic = ref.read(hapticServiceProvider);

    final result = await showFreeThrowSequenceDialog(
      context: context,
      player: player.player,
      initialCount: initialCount,
    );

    if (result == null) return; // 취소

    final db = ref.read(databaseProvider);

    // 자유투 결과 기록 + 햅틱 피드백 + 라이브 로그
    final undoStack = ref.read(undoStackProvider.notifier);
    final ftScoringTeamId = isHome ? (_match?.homeTeamId ?? 0) : (_match?.awayTeamId ?? 0);
    final ftOpponentTeamId = isHome ? (_match?.awayTeamId ?? 0) : (_match?.homeTeamId ?? 0);
    for (int i = 0; i < result.results.length; i++) {
      final isMade = result.results[i];
      await db.playerStatsDao.recordFreeThrow(widget.matchId, player.player.id, isMade);
      if (isMade) {
        final ftHome = _match?.homeScore ?? 0;
        final ftAway = _match?.awayScore ?? 0;
        await db.matchDao.updateScore(widget.matchId,
          isHome ? ftHome + 1 : ftHome, isHome ? ftAway : ftAway + 1);
        // FR-003: +/- 업데이트
        await db.playerStatsDao.applyPlusMinusForScore(
          matchId: widget.matchId,
          scoringTeamId: ftScoringTeamId,
          opponentTeamId: ftOpponentTeamId,
          points: 1,
        );
        await _refreshStats(); // _match 갱신 (다음 자유투 누적 위해)
        await haptic.freeThrowMade();
      } else {
        await haptic.freeThrowMissed();
      }
      undoStack.recordFreeThrow(
        playerId: player.player.id,
        playerName: player.player.userName,
        matchId: widget.matchId,
        isMade: isMade,
        shotNumber: i + 1,
        totalShots: result.results.length,
        isHome: isHome,
      );
    }

    await _refreshStats();
  }


  Future<void> _recordAction(PlayerWithStats player, bool isHome, String actionType) async {
    final db = ref.read(databaseProvider);
    final haptic = ref.read(hapticServiceProvider);

    try {
      final aHome = _match?.homeScore ?? 0;
      final aAway = _match?.awayScore ?? 0;
      final scoringTeamId = isHome ? (_match?.homeTeamId ?? 0) : (_match?.awayTeamId ?? 0);
      final opponentTeamId = isHome ? (_match?.awayTeamId ?? 0) : (_match?.homeTeamId ?? 0);

      switch (actionType) {
        case 'twoPointMade':
          await db.playerStatsDao.recordTwoPointer(widget.matchId, player.player.id, true);
          await db.matchDao.updateScore(widget.matchId,
            isHome ? aHome + 2 : aHome, isHome ? aAway : aAway + 2);
          // FR-003: +/- 업데이트
          await db.playerStatsDao.applyPlusMinusForScore(
            matchId: widget.matchId, scoringTeamId: scoringTeamId,
            opponentTeamId: opponentTeamId, points: 2,
          );
          await haptic.shotMade();
          break;
        case 'twoPointMissed':
          await db.playerStatsDao.recordTwoPointer(widget.matchId, player.player.id, false);
          await haptic.shotMissed();
          break;
        case 'threePointMade':
          await db.playerStatsDao.recordThreePointer(widget.matchId, player.player.id, true);
          await db.matchDao.updateScore(widget.matchId,
            isHome ? aHome + 3 : aHome, isHome ? aAway : aAway + 3);
          // FR-003: +/- 업데이트
          await db.playerStatsDao.applyPlusMinusForScore(
            matchId: widget.matchId, scoringTeamId: scoringTeamId,
            opponentTeamId: opponentTeamId, points: 3,
          );
          await haptic.threePointerMade();
          break;
        case 'threePointMissed':
          await db.playerStatsDao.recordThreePointer(widget.matchId, player.player.id, false);
          await haptic.shotMissed();
          break;
        case 'freeThrowMade':
          await db.playerStatsDao.recordFreeThrow(widget.matchId, player.player.id, true);
          await db.matchDao.updateScore(widget.matchId,
            isHome ? aHome + 1 : aHome, isHome ? aAway : aAway + 1);
          // FR-003: +/- 업데이트
          await db.playerStatsDao.applyPlusMinusForScore(
            matchId: widget.matchId, scoringTeamId: scoringTeamId,
            opponentTeamId: opponentTeamId, points: 1,
          );
          await haptic.freeThrowMade();
          break;
        case 'freeThrowMissed':
          await db.playerStatsDao.recordFreeThrow(widget.matchId, player.player.id, false);
          await haptic.freeThrowMissed();
          break;
        case 'assist':
          await db.playerStatsDao.recordAssist(widget.matchId, player.player.id);
          await haptic.statRecorded();
          break;
        case 'rebound':
          await db.playerStatsDao.recordRebound(widget.matchId, player.player.id, false);
          await haptic.statRecorded();
          break;
        case 'steal':
          await db.playerStatsDao.recordSteal(widget.matchId, player.player.id);
          ref.read(gameTimerProvider.notifier).setPossession(
            isHome ? Possession.home : Possession.away,
          );
          await haptic.statRecorded();
          break;
        case 'block':
          await db.playerStatsDao.recordBlock(widget.matchId, player.player.id);
          await haptic.statRecorded();
          break;
        case 'turnover':
          await db.playerStatsDao.recordTurnover(widget.matchId, player.player.id);
          ref.read(gameTimerProvider.notifier).setPossession(
            isHome ? Possession.away : Possession.home,
          );
          await haptic.turnover();
          break;
        case 'foul':
          await db.playerStatsDao.recordFoul(widget.matchId, player.player.id);
          final timerState = ref.read(gameTimerProvider);
          _teamFoulManager.addFoul(timerState.quarter, isHome);
          await db.matchDao.updateTeamFouls(
            widget.matchId,
            jsonEncode(_teamFoulManager.toJson()),
          );
          await haptic.foulRecorded();
          break;
      }

      // PBP 기록
      final teamId = isHome ? (_match?.homeTeamId ?? 0) : (_match?.awayTeamId ?? 0);
      await _recordPBP(
        playerId: player.player.id,
        teamId: teamId,
        actionType: actionType,
      );

      await _refreshStats();
    } catch (e) {
      debugPrint('[RecordAction] Error recording $actionType: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('기록 실패: $actionType ($e)'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // 라이브 로그에 기록 (undoStack)
    final undoStack = ref.read(undoStackProvider.notifier);
    switch (actionType) {
      case 'twoPointMade':
        undoStack.recordShot(playerId: player.player.id, playerName: player.player.userName, matchId: widget.matchId, isMade: true, isThreePointer: false, isHome: isHome);
        break;
      case 'twoPointMissed':
        undoStack.recordShot(playerId: player.player.id, playerName: player.player.userName, matchId: widget.matchId, isMade: false, isThreePointer: false, isHome: isHome);
        break;
      case 'threePointMade':
        undoStack.recordShot(playerId: player.player.id, playerName: player.player.userName, matchId: widget.matchId, isMade: true, isThreePointer: true, isHome: isHome);
        break;
      case 'threePointMissed':
        undoStack.recordShot(playerId: player.player.id, playerName: player.player.userName, matchId: widget.matchId, isMade: false, isThreePointer: true, isHome: isHome);
        break;
      case 'freeThrowMade':
        undoStack.recordFreeThrow(playerId: player.player.id, playerName: player.player.userName, matchId: widget.matchId, isMade: true, shotNumber: 1, totalShots: 1, isHome: isHome);
        break;
      case 'freeThrowMissed':
        undoStack.recordFreeThrow(playerId: player.player.id, playerName: player.player.userName, matchId: widget.matchId, isMade: false, shotNumber: 1, totalShots: 1, isHome: isHome);
        break;
      case 'assist':
        undoStack.recordAssist(playerId: player.player.id, playerName: player.player.userName, matchId: widget.matchId, isHome: isHome);
        break;
      case 'rebound':
        undoStack.recordRebound(playerId: player.player.id, playerName: player.player.userName, matchId: widget.matchId, isOffensive: false, isHome: isHome);
        break;
      case 'steal':
        undoStack.recordSteal(playerId: player.player.id, playerName: player.player.userName, matchId: widget.matchId, isHome: isHome);
        break;
      case 'block':
        undoStack.recordBlock(playerId: player.player.id, playerName: player.player.userName, matchId: widget.matchId, isHome: isHome);
        break;
      case 'turnover':
        undoStack.recordTurnover(playerId: player.player.id, playerName: player.player.userName, matchId: widget.matchId, isHome: isHome);
        break;
      case 'foul':
        undoStack.recordFoul(playerId: player.player.id, playerName: player.player.userName, matchId: widget.matchId, isHome: isHome);
        break;
    }
  }



  void _showPlayerActionMenu(PlayerWithStats player, bool isHome) {
    // 벤치 선수 목록 가져오기
    final players = isHome ? _homePlayers : _awayPlayers;
    final benchPlayers = players.where((p) => !p.stats.isOnCourt).toList();
    final teamName = isHome
        ? (_homeTeam?.teamName ?? '홈')
        : (_awayTeam?.teamName ?? '원정');

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => PlayerActionMenu(
        player: player,
        isHome: isHome,
        matchId: widget.matchId,
        benchPlayers: benchPlayers,
        teamName: teamName,
        homeTeamName: _homeTeam?.teamName ?? '홈',
        awayTeamName: _awayTeam?.teamName ?? '원정',
        homePlayers: _homePlayers,
        awayPlayers: _awayPlayers,
        onActionComplete: () {
          Navigator.pop(context);
          _refreshStats();
        },
      ),
    );
  }

  void _showTimerAdjustDialog() {
    final timerNotifier = ref.read(gameTimerProvider.notifier);
    final timerState = ref.read(gameTimerProvider);
    final currentMinutes = timerState.gameClockSeconds ~/ 60;
    final currentSeconds = timerState.gameClockSeconds % 60;
    final minuteController = TextEditingController(text: currentMinutes.toString());
    final secondController = TextEditingController(text: currentSeconds.toString().padLeft(2, '0'));

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('시간 조정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 빠른 조정 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton(
                  onPressed: () {
                    timerNotifier.adjustGameClock(-60);
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('-1:00'),
                ),
                OutlinedButton(
                  onPressed: () {
                    timerNotifier.adjustGameClock(-10);
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('-0:10'),
                ),
                OutlinedButton(
                  onPressed: () {
                    timerNotifier.adjustGameClock(10);
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('+0:10'),
                ),
                OutlinedButton(
                  onPressed: () {
                    timerNotifier.adjustGameClock(60);
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('+1:00'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            // 직접 입력
            const Text('직접 입력', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 60,
                  child: TextField(
                    controller: minuteController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      labelText: '분',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(':', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ),
                SizedBox(
                  width: 60,
                  child: TextField(
                    controller: secondController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      labelText: '초',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    final minutes = int.tryParse(minuteController.text) ?? 0;
                    final seconds = (int.tryParse(secondController.text) ?? 0).clamp(0, 59);
                    timerNotifier.setGameClock(minutes * 60 + seconds);
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('설정'),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  void _showShotClockAdjustDialog() {
    final timerNotifier = ref.read(gameTimerProvider.notifier);
    final timerState = ref.read(gameTimerProvider);
    final controller = TextEditingController(text: timerState.shotClockSeconds.toString());

    showDialog(
      context: context,
      builder: (dialogContext) {
        int currentValue = timerState.shotClockSeconds;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: AppTheme.surfaceColor,
            title: const Text('샷클락 조정'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 현재 값 표시
                Text(
                  '$currentValue',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 16),
                // 프리셋 버튼
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final preset in [24, 14, 10, 5])
                      ElevatedButton(
                        onPressed: () {
                          timerNotifier.setShotClock(preset);
                          Navigator.pop(dialogContext);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: preset == 24
                              ? AppTheme.primaryColor
                              : preset == 14
                                  ? AppTheme.secondaryColor
                                  : null,
                          minimumSize: const Size(56, 40),
                        ),
                        child: Text('$preset'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // +/- 버튼
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        setDialogState(() {
                          currentValue = (currentValue - 5).clamp(0, 99);
                          controller.text = currentValue.toString();
                        });
                      },
                      child: const Text('-5'),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        setDialogState(() {
                          currentValue = (currentValue - 1).clamp(0, 99);
                          controller.text = currentValue.toString();
                        });
                      },
                      child: const Text('-1'),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        setDialogState(() {
                          currentValue = (currentValue + 1).clamp(0, 99);
                          controller.text = currentValue.toString();
                        });
                      },
                      child: const Text('+1'),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        setDialogState(() {
                          currentValue = (currentValue + 5).clamp(0, 99);
                          controller.text = currentValue.toString();
                        });
                      },
                      child: const Text('+5'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                // 직접 입력
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          labelText: '초',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        ),
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (value) {
                          setDialogState(() {
                            currentValue = (int.tryParse(value) ?? 0).clamp(0, 99);
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        timerNotifier.setShotClock(currentValue);
                        Navigator.pop(dialogContext);
                      },
                      child: const Text('설정'),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('닫기'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showScoreAdjustDialog({required bool isHome}) {
    final teamName = isHome
        ? (_homeTeam?.teamName ?? '홈')
        : (_awayTeam?.teamName ?? '원정');
    final currentScore = isHome
        ? (_match?.homeScore ?? 0)
        : (_match?.awayScore ?? 0);
    final controller = TextEditingController(text: currentScore.toString());

    showDialog(
      context: context,
      builder: (dialogContext) {
        int adjustedScore = currentScore;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: AppTheme.surfaceColor,
            title: Text('$teamName 점수 조정'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 현재 점수 표시
                Text(
                  '$adjustedScore',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: isHome ? AppTheme.homeTeamColor : AppTheme.awayTeamColor,
                  ),
                ),
                const SizedBox(height: 16),
                // 조정 버튼
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final delta in [-3, -2, -1, 1, 2, 3])
                      OutlinedButton(
                        onPressed: () {
                          setDialogState(() {
                            adjustedScore = (adjustedScore + delta).clamp(0, 999);
                            controller.text = adjustedScore.toString();
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: delta < 0 ? AppTheme.errorColor : AppTheme.successColor,
                          minimumSize: const Size(48, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: Text(delta > 0 ? '+$delta' : '$delta'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                // 직접 입력
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          labelText: '점수',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        ),
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (value) {
                          setDialogState(() {
                            adjustedScore = (int.tryParse(value) ?? 0).clamp(0, 999);
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        final db = ref.read(databaseProvider);
                        final homeScore = isHome ? adjustedScore : (_match?.homeScore ?? 0);
                        final awayScore = isHome ? (_match?.awayScore ?? 0) : adjustedScore;
                        await db.matchDao.updateScore(widget.matchId, homeScore, awayScore);
                        await _refreshStats();
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                      },
                      child: const Text('설정'),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('닫기'),
              ),
              // 적용 버튼 (현재 adjustedScore로 빠르게 적용)
              ElevatedButton(
                onPressed: () async {
                  final db = ref.read(databaseProvider);
                  final homeScore = isHome ? adjustedScore : (_match?.homeScore ?? 0);
                  final awayScore = isHome ? (_match?.awayScore ?? 0) : adjustedScore;
                  await db.matchDao.updateScore(widget.matchId, homeScore, awayScore);
                  await _refreshStats();
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                },
                child: const Text('적용'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _endGame() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('경기 종료'),
        content: const Text('경기를 종료하고 최종 검토 화면으로 이동합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('검토하기'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // 쿼터별 점수 저장
      final db = ref.read(databaseProvider);
      await db.matchDao.updateQuarterScores(
        widget.matchId,
        jsonEncode(_quarterScores),
      );

      // 자동 저장 중지 및 수동 저장
      await ref.read(autoSaveManagerProvider.notifier).saveNow();
      _stopAutoSave();

      // 최종 검토 화면으로 이동
      if (!mounted) return;
      context.push(
        '/final-review/${widget.matchId}',
        extra: {
          'homeTeamId': _homeTeam?.id ?? 0,
          'awayTeamId': _awayTeam?.id ?? 0,
          'homeTeamName': _homeTeam?.teamName ?? '',
          'awayTeamName': _awayTeam?.teamName ?? '',
          'homeScore': _match?.homeScore ?? 0,
          'awayScore': _match?.awayScore ?? 0,
        },
      );
    }
  }

  void _showExitConfirmDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('기록 화면 나가기'),
        content: const Text('경기 기록 화면을 나가시겠습니까?\n데이터는 자동 저장됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('나가기'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // 나가기 전 수동 저장
      await ref.read(autoSaveManagerProvider.notifier).saveNow();
      _stopAutoSave();
      if (!mounted) return;
      context.go('/matches');
    }
  }

  void _showMatchMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: ListTileTheme(
          iconColor: AppTheme.textPrimary,
          textColor: AppTheme.textPrimary,
          child: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.table_chart),
                title: const Text('박스스코어'),
                subtitle: Text('선수별 상세 통계', style: TextStyle(color: AppTheme.textSecondary)),
                onTap: () {
                  Navigator.pop(context);
                  _openBoxScore();
                },
              ),
              ListTile(
                leading: const Icon(Icons.scatter_plot),
                title: const Text('슛 차트'),
                subtitle: Text('슛 위치 및 성공률', style: TextStyle(color: AppTheme.textSecondary)),
                onTap: () {
                  Navigator.pop(context);
                  _openShotChart();
                },
              ),
              ListTile(
                leading: const Icon(Icons.analytics),
                title: const Text('경기 분석'),
                subtitle: Text('종합 통계 및 효율성', style: TextStyle(color: AppTheme.textSecondary)),
                onTap: () {
                  Navigator.pop(context);
                  _openAnalysis();
                },
              ),
              ListTile(
                leading: const Icon(Icons.leaderboard),
                title: const Text('실시간 리더보드'),
                subtitle: Text('득점, 리바운드, 어시스트 순위', style: TextStyle(color: AppTheme.textSecondary)),
                onTap: () {
                  Navigator.pop(context);
                  _openLeaderboard();
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_note),
                title: const Text('기록 수정'),
                subtitle: Text('득점자 변경, 기록 삭제', style: TextStyle(color: AppTheme.textSecondary)),
                onTap: () {
                  Navigator.pop(context);
                  _openPlayEdit();
                },
              ),
              Divider(color: AppTheme.borderColor),
              ListTile(
                leading: const Icon(Icons.sync),
                title: const Text('서버와 동기화'),
                onTap: () {
                  Navigator.pop(context);
                  _syncMatch();
                },
              ),
              Divider(color: AppTheme.borderColor),
              Consumer(
                builder: (context, ref, _) {
                  final isLeftHanded = ref.watch(isLeftHandedProvider);
                  return SwitchListTile(
                    secondary: Icon(isLeftHanded ? Icons.back_hand : Icons.front_hand),
                    title: Text(isLeftHanded ? '왼손잡이 모드' : '오른손잡이 모드'),
                    subtitle: Text(
                      isLeftHanded ? '사이드바가 왼쪽' : '사이드바가 오른쪽',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    value: isLeftHanded,
                    onChanged: (_) {
                      ref.read(isLeftHandedProvider.notifier).toggle();
                    },
                  );
                },
              ),
            ],
          )),
        ),
      ),
    );
  }

  void _openBoxScore() {
    context.push(
      '/box-score/${widget.matchId}',
      extra: {
        'homeTeamName': _homeTeam?.teamName ?? '홈',
        'awayTeamName': _awayTeam?.teamName ?? '원정',
        'homeTeamId': _match?.homeTeamId ?? 0,
        'awayTeamId': _match?.awayTeamId ?? 0,
        'homeScore': _match?.homeScore ?? 0,
        'awayScore': _match?.awayScore ?? 0,
        'isLive': true,
      },
    );
  }

  void _openShotChart() {
    context.push(
      '/shot-chart/${widget.matchId}',
      extra: {
        'homeTeamId': _match?.homeTeamId ?? 0,
        'awayTeamId': _match?.awayTeamId ?? 0,
        'homeTeamName': _homeTeam?.teamName ?? '홈',
        'awayTeamName': _awayTeam?.teamName ?? '원정',
      },
    );
  }

  void _openAnalysis() {
    context.push(
      '/analysis/${widget.matchId}',
      extra: {
        'homeTeamId': _match?.homeTeamId ?? 0,
        'awayTeamId': _match?.awayTeamId ?? 0,
        'homeTeamName': _homeTeam?.teamName ?? '홈',
        'awayTeamName': _awayTeam?.teamName ?? '원정',
      },
    );
  }

  void _openLeaderboard() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '리더보드 닫기',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            child: LiveLeaderDrawer(
              homePlayers: _homePlayers,
              awayPlayers: _awayPlayers,
              homeTeamName: _homeTeam?.teamName ?? '홈',
              awayTeamName: _awayTeam?.teamName ?? '원정',
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        );
      },
    );
  }

  void _openPlayEdit() {
    context.push(
      '/play-edit/${widget.matchId}',
      extra: {
        'homeTeamId': _match?.homeTeamId ?? 0,
        'awayTeamId': _match?.awayTeamId ?? 0,
        'homeTeamName': _homeTeam?.teamName ?? '홈',
        'awayTeamName': _awayTeam?.teamName ?? '원정',
      },
    );
  }

  /// 서버와 동기화
  Future<void> _syncMatch() async {
    final syncManager = ref.read(syncManagerProvider);

    // 네트워크 연결 확인
    final hasNetwork = await syncManager.checkNetworkConnection();
    if (!hasNetwork) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('네트워크 연결을 확인해주세요.'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
      }
      return;
    }

    // 로딩 표시
    if (mounted) {
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
              Text('동기화 중...'),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );
    }

    // 동기화 실행
    final result = await syncManager.syncMatch(widget.matchId);

    if (!mounted) return;

    // 기존 스낵바 제거
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '동기화 완료! (선수: ${result.playerCount ?? 0}명, 플레이: ${result.playByPlayCount ?? 0}개)',
          ),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? '동기화 실패'),
          backgroundColor: AppTheme.errorColor,
          action: SnackBarAction(
            label: '재시도',
            textColor: Colors.white,
            onPressed: _syncMatch,
          ),
        ),
      );
    }
  }

  // ============================================================
  // Phase 5: 경기 진행 관리 핸들러
  // ============================================================

  /// 타임아웃 다이얼로그 표시
  Future<void> _showTimeoutDialog() async {
    final timerNotifier = ref.read(gameTimerProvider.notifier);
    final haptic = ref.read(hapticServiceProvider);

    // 타이머 일시정지
    timerNotifier.pause();

    final result = await showTimeoutDialog(
      context: context,
      homeTeamName: _homeTeam?.teamName ?? '홈',
      awayTeamName: _awayTeam?.teamName ?? '원정',
      homeTimeoutsRemaining: _match?.homeTimeoutsRemaining ?? 5,
      awayTimeoutsRemaining: _match?.awayTimeoutsRemaining ?? 5,
    );

    if (result != null && _match != null) {
      final db = ref.read(databaseProvider);

      // 타임아웃 타입에 따라 처리
      if (result.type == TimeoutType.official) {
        // 공식 타임아웃 - 카운트 감소 없음
        await haptic.timeout();
        if (!mounted) return;
        UndoSnackbar.showSuccess(
          context: context,
          message: '공식 타임아웃: ${result.reason ?? "기타"}',
        );
      } else {
        // 팀 타임아웃 - 카운트 감소
        final isHome = result.type == TimeoutType.home;

        if (isHome) {
          await db.matchDao.updateTimeouts(widget.matchId, homeTimeouts: (_match!.homeTimeoutsRemaining) - 1);
        } else {
          await db.matchDao.updateTimeouts(widget.matchId, awayTimeouts: (_match!.awayTimeoutsRemaining) - 1);
        }

        // 햅틱 피드백 (타임아웃)
        await haptic.timeout();

        // Undo 스택에 추가
        ref.read(undoStackProvider.notifier).recordTimeout(
          matchId: widget.matchId,
          teamName: isHome ? (_homeTeam?.teamName ?? '홈') : (_awayTeam?.teamName ?? '원정'),
          isHome: isHome,
          isOfficial: false,
        );

        if (!mounted) return;
        UndoSnackbar.showSuccess(
          context: context,
          message: '${isHome ? _homeTeam?.teamName ?? "홈" : _awayTeam?.teamName ?? "원정"} 타임아웃',
        );

        // 경기 정보 새로고침
        await _refreshStats();
      }
    }
  }

  /// 쿼터 종료 다이얼로그 표시
  Future<void> _showQuarterEndDialog() async {
    final timerNotifier = ref.read(gameTimerProvider.notifier);
    final timerState = ref.read(gameTimerProvider);

    // 타이머 일시정지
    timerNotifier.pause();

    // 현재 쿼터 점수 저장
    _saveCurrentQuarterScore();

    final result = await showQuarterEndDialog(
      context: context,
      currentQuarter: _isOvertime ? timerState.maxQuarters + _overtimeNumber : timerState.quarter,
      maxQuarters: timerState.maxQuarters,
      homeTeamName: _homeTeam?.teamName ?? '홈',
      awayTeamName: _awayTeam?.teamName ?? '원정',
      homeScore: _match?.homeScore ?? 0,
      awayScore: _match?.awayScore ?? 0,
      quarterScores: _quarterScores,
      isOvertime: _isOvertime,
      overtimeNumber: _overtimeNumber,
    );

    if (result != null) {
      switch (result.action) {
        case QuarterEndAction.nextQuarter:
          await _startNextQuarter();
          break;
        case QuarterEndAction.viewBoxScore:
          // TODO: 박스스코어 화면으로 이동
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('박스스코어 화면 (준비 중)')),
            );
          }
          break;
        case QuarterEndAction.endGame:
          await _finishGame();
          break;
        case QuarterEndAction.overtime:
          await _showOvertimeSetupDialog();
          break;
      }
    }
  }

  /// 현재 쿼터 점수 저장
  void _saveCurrentQuarterScore() {
    final timerState = ref.read(gameTimerProvider);
    final quarterKey = _isOvertime
        ? 'OT${_overtimeNumber > 0 ? _overtimeNumber : 1}'
        : 'Q${timerState.quarter}';

    // 이전 쿼터들의 점수 합계 계산
    int prevHomeTotal = 0;
    int prevAwayTotal = 0;
    _quarterScores.forEach((key, scores) {
      prevHomeTotal += scores['home'] ?? 0;
      prevAwayTotal += scores['away'] ?? 0;
    });

    // 현재 쿼터 점수 = 현재 총점 - 이전 쿼터 합계
    _quarterScores[quarterKey] = {
      'home': (_match?.homeScore ?? 0) - prevHomeTotal,
      'away': (_match?.awayScore ?? 0) - prevAwayTotal,
    };
  }

  /// 다음 쿼터 시작
  Future<void> _startNextQuarter() async {
    final timerNotifier = ref.read(gameTimerProvider.notifier);
    final timerState = ref.read(gameTimerProvider);
    final haptic = ref.read(hapticServiceProvider);

    // 쿼터 종료 햅틱 피드백
    await haptic.quarterEnd();

    // 다음 쿼터로 이동
    timerNotifier.nextQuarter();

    // 팀 파울 리셋
    _teamFoulManager.resetForQuarter(timerState.quarter + 1);

    // DB에 팀 파울 저장
    final db = ref.read(databaseProvider);
    await db.matchDao.updateTeamFouls(
      widget.matchId,
      jsonEncode(_teamFoulManager.toJson()),
    );

    setState(() {});

    if (mounted) {
      UndoSnackbar.showSuccess(
        context: context,
        message: '${timerState.quarter + 1}쿼터 시작',
      );
    }
  }

  /// 연장전 설정 다이얼로그
  Future<void> _showOvertimeSetupDialog() async {
    final settings = await showOvertimeDialog(
      context: context,
      homeTeamName: _homeTeam?.teamName ?? '홈',
      awayTeamName: _awayTeam?.teamName ?? '원정',
      score: _match?.homeScore ?? 0,
      overtimeNumber: _overtimeNumber + 1,
    );

    if (settings != null) {
      await _startOvertime(settings);
    }
  }

  /// 연장전 시작
  Future<void> _startOvertime(OvertimeSettings settings) async {
    final timerNotifier = ref.read(gameTimerProvider.notifier);

    setState(() {
      _isOvertime = true;
      _overtimeNumber += 1;
    });

    // 연장전 타이머 설정
    timerNotifier.startOvertime(minutes: settings.minutes);

    // 팀 파울 리셋 (옵션에 따라)
    if (settings.resetTeamFouls) {
      final timerState = ref.read(gameTimerProvider);
      _teamFoulManager.resetForQuarter(timerState.quarter);

      final db = ref.read(databaseProvider);
      await db.matchDao.updateTeamFouls(
        widget.matchId,
        jsonEncode(_teamFoulManager.toJson()),
      );
    }

    // 추가 타임아웃 부여
    if (settings.additionalTimeouts > 0 && _match != null) {
      final db = ref.read(databaseProvider);
      await db.matchDao.updateTimeouts(
        widget.matchId,
        homeTimeouts: (_match!.homeTimeoutsRemaining) + settings.additionalTimeouts,
        awayTimeouts: (_match!.awayTimeoutsRemaining) + settings.additionalTimeouts,
      );
      await _refreshStats();
    }

    if (mounted) {
      UndoSnackbar.showSuccess(
        context: context,
        message: '$_overtimeNumber차 연장전 시작 (${settings.minutes}분)',
      );
    }
  }

  /// 경기 종료 처리
  Future<void> _finishGame() async {
    final db = ref.read(databaseProvider);

    // 쿼터별 점수 저장
    await db.matchDao.updateQuarterScores(
      widget.matchId,
      jsonEncode(_quarterScores),
    );

    // 경기 상태 완료로 변경
    await db.matchDao.updateMatchStatus(widget.matchId, 'completed');

    // Undo 스택 초기화
    ref.read(undoStackProvider.notifier).clear();

    // 자동 저장 중지 및 정상 종료 기록
    _stopAutoSave();

    if (mounted) {
      context.go('/matches');
    }
  }

  /// Undo 확인 후 실행 취소
  Future<void> _undoLastActionWithConfirm() async {
    final undoStack = ref.read(undoStackProvider);
    final haptic = ref.read(hapticServiceProvider);

    if (undoStack.isEmpty) {
      if (mounted) {
        UndoSnackbar.showError(
          context: context,
          message: '취소할 기록이 없습니다',
        );
      }
      return;
    }

    final lastAction = undoStack.lastAction!;
    final linkedActions = undoStack.findLinkedActions(lastAction.id);

    // 연관 액션이 있으면 확인 다이얼로그
    if (linkedActions.isNotEmpty) {
      final confirmed = await showUndoConfirmDialog(
        context: context,
        action: lastAction,
        linkedActions: linkedActions,
      );

      if (confirmed != true) return;
    }

    // Undo 실행
    final undoneActions = ref.read(undoStackProvider.notifier).undoById(
      lastAction.id,
      includeLinked: true,
    );

    // DB에서 실제 기록 삭제
    await _undoActionsInDatabase(undoneActions);

    // 햅틱 피드백 (실행 취소)
    if (undoneActions.isNotEmpty) {
      await haptic.undo();
    }

    // 데이터 새로고침
    await _refreshStats();

    if (mounted && undoneActions.isNotEmpty) {
      UndoSnackbar.show(
        context: context,
        action: lastAction,
        onUndo: () {}, // 이미 취소됨
        duration: const Duration(seconds: 2),
      );
    }
  }

  /// DB에서 액션 취소 처리
  Future<void> _undoActionsInDatabase(List<UndoableAction> actions) async {
    final db = ref.read(databaseProvider);

    for (final action in actions) {
      switch (action.type) {
        case UndoableActionType.shot:
          // 슛 기록 취소
          final isMade = action.data['isMade'] as bool? ?? false;
          final isThree = action.data['isThreePointer'] as bool? ?? false;

          if (isThree) {
            await db.playerStatsDao.recordThreePointer(
              widget.matchId,
              action.playerId,
              isMade,
              increment: -1, // 감소
            );
          } else {
            await db.playerStatsDao.recordTwoPointer(
              widget.matchId,
              action.playerId,
              isMade,
              increment: -1,
            );
          }

          // 점수 복원
          if (isMade) {
            final points = isThree ? 3 : 2;
            // 어느 팀인지 확인 필요
            final isHome = _homePlayers.any((p) => p.player.id == action.playerId);
            await db.matchDao.updateScore(
              widget.matchId,
              isHome ? -points : 0,
              isHome ? 0 : -points,
            );

            // FR-003: +/- 역방향 적용 (Undo)
            final undoScoringTeamId = isHome ? (_match?.homeTeamId ?? 0) : (_match?.awayTeamId ?? 0);
            final undoOpponentTeamId = isHome ? (_match?.awayTeamId ?? 0) : (_match?.homeTeamId ?? 0);
            await db.playerStatsDao.revertPlusMinusForScore(
              matchId: widget.matchId,
              scoringTeamId: undoScoringTeamId,
              opponentTeamId: undoOpponentTeamId,
              points: points,
            );

            // 슛 마커 제거
            if (_shotMarkers.isNotEmpty) {
              setState(() {
                _shotMarkers.removeLast();
              });
            }
          }
          break;

        case UndoableActionType.freeThrow:
          final isMade = action.data['isMade'] as bool? ?? false;
          await db.playerStatsDao.recordFreeThrow(
            widget.matchId,
            action.playerId,
            isMade,
            increment: -1,
          );
          if (isMade) {
            final isHome = _homePlayers.any((p) => p.player.id == action.playerId);
            await db.matchDao.updateScore(
              widget.matchId,
              isHome ? -1 : 0,
              isHome ? 0 : -1,
            );
            // FR-003: +/- 역방향 적용 (Undo)
            final ftUndoScoringTeamId = isHome ? (_match?.homeTeamId ?? 0) : (_match?.awayTeamId ?? 0);
            final ftUndoOpponentTeamId = isHome ? (_match?.awayTeamId ?? 0) : (_match?.homeTeamId ?? 0);
            await db.playerStatsDao.revertPlusMinusForScore(
              matchId: widget.matchId,
              scoringTeamId: ftUndoScoringTeamId,
              opponentTeamId: ftUndoOpponentTeamId,
              points: 1,
            );
          }
          break;

        case UndoableActionType.assist:
          await db.playerStatsDao.recordAssist(
            widget.matchId,
            action.playerId,
            increment: -1,
          );
          break;

        case UndoableActionType.rebound:
          final isOffensive = action.data['isOffensive'] as bool? ?? false;
          await db.playerStatsDao.recordRebound(
            widget.matchId,
            action.playerId,
            isOffensive,
            increment: -1,
          );
          break;

        case UndoableActionType.steal:
          await db.playerStatsDao.recordSteal(
            widget.matchId,
            action.playerId,
            increment: -1,
          );
          break;

        case UndoableActionType.block:
          await db.playerStatsDao.recordBlock(
            widget.matchId,
            action.playerId,
            increment: -1,
          );
          break;

        case UndoableActionType.turnover:
          await db.playerStatsDao.recordTurnover(
            widget.matchId,
            action.playerId,
            increment: -1,
          );
          break;

        case UndoableActionType.foul:
          // 파울 Undo 전 현재 상태 확인
          final foulPlayerStats = await db.playerStatsDao.getPlayerStats(
            widget.matchId, action.playerId);
          final wasFouledOut = foulPlayerStats?.fouledOut ?? false;
          final wasEjected = foulPlayerStats?.ejected ?? false;

          // T/U 파울 타입별 감소
          final foulType = action.data['foulType'] as String?;
          if (foulType == 'foul_technical') {
            await db.playerStatsDao.recordTechnicalFoul(widget.matchId, action.playerId);
            // recordTechnicalFoul은 +1이므로 수동 감소
            await customFoulUndo(db, action.playerId, technical: true);
          } else if (foulType == 'foul_unsportsmanlike') {
            await customFoulUndo(db, action.playerId, unsportsmanlike: true);
          } else {
            await db.playerStatsDao.recordFoul(
              widget.matchId,
              action.playerId,
              increment: -1,
            );
          }

          // 팀 파울 감소
          final isHome = _homePlayers.any((p) => p.player.id == action.playerId);
          final timerState = ref.read(gameTimerProvider);
          _teamFoulManager.removeFoul(timerState.quarter, isHome);
          await db.matchDao.updateTeamFouls(
            widget.matchId,
            jsonEncode(_teamFoulManager.toJson()),
          );

          // 파울아웃/퇴장이었다면 → 코트 복귀 다이얼로그
          if ((wasFouledOut || wasEjected) && mounted) {
            final updatedStats = await db.playerStatsDao.getPlayerStats(
              widget.matchId, action.playerId);
            final nowFouledOut = (updatedStats?.personalFouls ?? 0) >= 5;
            final nowEjected = (updatedStats?.technicalFouls ?? 0) +
                (updatedStats?.unsportsmanlikeFouls ?? 0) >= 2;

            // 더 이상 파울아웃/퇴장 아니면 복귀 제안
            if (!nowFouledOut && !nowEjected) {
              await _showReturnToCourtDialog(action.playerId, isHome);
            }
          }
          break;

        case UndoableActionType.timeout:
          // 타임아웃 복원
          final isHome = action.data['isHome'] as bool? ?? false;
          final isOfficial = action.data['isOfficial'] as bool? ?? false;
          if (!isOfficial) {
            if (isHome) {
              await db.matchDao.updateTimeouts(
                widget.matchId,
                homeTimeouts: (_match?.homeTimeoutsRemaining ?? 0) + 1,
              );
            } else {
              await db.matchDao.updateTimeouts(
                widget.matchId,
                awayTimeouts: (_match?.awayTimeoutsRemaining ?? 0) + 1,
              );
            }
          }
          break;

        case UndoableActionType.substitution:
          // 교체 취소 - 선수 상태 복원
          final subOutId = action.data['subOutPlayerId'] as int?;
          final subInId = action.data['subInPlayerId'] as int?;
          if (subOutId != null && subInId != null) {
            await db.playerStatsDao.setOnCourt(
              widget.matchId,
              subOutId,
              true, // subOut을 다시 코트로
            );
            await db.playerStatsDao.setOnCourt(
              widget.matchId,
              subInId,
              false, // subIn을 다시 벤치로
            );
          }
          break;
      }
    }
  }

  /// 선수 교체 처리 (드래그앤드롭)
  Future<void> _handleSubstitution(
    PlayerWithStats subOut,
    PlayerWithStats subIn,
    bool isHome,
  ) async {
    final db = ref.read(databaseProvider);
    final haptic = ref.read(hapticServiceProvider);

    await haptic.substitution();

    // 직접 투입 (코트에 5명 미만일 때 subOut == subIn)
    if (subOut.player.id == subIn.player.id) {
      await db.playerStatsDao.setOnCourt(widget.matchId, subIn.player.id, true);
      await _refreshStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('#${subIn.jerseyNumber ?? '-'} ${subIn.name} 코트 투입'),
          duration: const Duration(seconds: 2),
        ));
      }
      return;
    }

    // 일반 교체
    await db.playerStatsDao.setOnCourt(widget.matchId, subOut.player.id, false);
    await db.playerStatsDao.setOnCourt(widget.matchId, subIn.player.id, true);

    // Undo 스택에 기록
    ref.read(undoStackProvider.notifier).recordSubstitution(
      matchId: widget.matchId,
      subOutPlayerId: subOut.player.id,
      subOutPlayerName: subOut.player.userName,
      subInPlayerId: subIn.player.id,
      subInPlayerName: subIn.player.userName,
      isHome: isHome,
    );

    // 데이터 새로고침
    await _refreshStats();

    if (mounted) {
      // 기존 스낵바 제거 후 새로 표시
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '교체: #${subOut.player.jerseyNumber ?? '-'} → #${subIn.player.jerseyNumber ?? '-'}',
          ),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: '취소',
            onPressed: () async {
              // 교체 취소
              await db.playerStatsDao.setOnCourt(
                widget.matchId,
                subOut.player.id,
                true,
              );
              await db.playerStatsDao.setOnCourt(
                widget.matchId,
                subIn.player.id,
                false,
              );
              ref.read(undoStackProvider.notifier).undoLast();
              await _refreshStats();
            },
          ),
        ),
      );
    }
  }

  /// 라이브 로그에서 액션 취소 처리
  /// 로그 수정 핸들러 — Undo 후 수정된 데이터로 재기록
  Future<void> _handleEditAction(UndoableAction original, Map<String, dynamic> editedData) async {
    final db = ref.read(databaseProvider);
    final undoNotifier = ref.read(undoStackProvider.notifier);

    // 1. 기존 기록 Undo (DB에서 삭제)
    final undoneActions = undoNotifier.undoById(original.id, includeLinked: false);
    await _undoActionsInDatabase(undoneActions);

    // 2. 수정된 데이터로 병합
    final mergedData = Map<String, dynamic>.from(original.data)..addAll(editedData);
    final isHome = mergedData['isHome'] as bool? ?? true;
    // 선수 변경 시 새 playerId 사용
    final targetPlayerId = mergedData['playerId'] as int? ?? original.playerId;
    final targetPlayerName = mergedData['playerName'] as String? ?? original.playerName;
    final allPlayers = [..._homePlayers, ..._awayPlayers];
    final player = allPlayers.where((p) => p.player.id == targetPlayerId).firstOrNull;

    if (player == null) {
      debugPrint('[EditAction] Player not found: $targetPlayerId');
      await _refreshStats();
      return;
    }

    // 3. 수정된 내용으로 재기록
    switch (original.type) {
      case UndoableActionType.shot:
        final isMade = mergedData['isMade'] as bool? ?? false;
        final isThree = mergedData['isThreePointer'] as bool? ?? false;
        if (isThree) {
          await db.playerStatsDao.recordThreePointer(widget.matchId, targetPlayerId, isMade);
        } else {
          await db.playerStatsDao.recordTwoPointer(widget.matchId, targetPlayerId, isMade);
        }
        if (isMade) {
          final points = isThree ? 3 : 2;
          final curHome = _match?.homeScore ?? 0;
          final curAway = _match?.awayScore ?? 0;
          await db.matchDao.updateScore(widget.matchId,
            isHome ? curHome + points : curHome, isHome ? curAway : curAway + points);
        }
        undoNotifier.recordShot(
          playerId: targetPlayerId,
          playerName: targetPlayerName,
          matchId: widget.matchId,
          isMade: isMade,
          isThreePointer: isThree,
          isHome: isHome,
        );
        break;

      case UndoableActionType.foul:
        await db.playerStatsDao.recordFoul(widget.matchId, targetPlayerId);
        undoNotifier.recordFoul(
          playerId: targetPlayerId,
          playerName: targetPlayerName,
          matchId: widget.matchId,
          isHome: isHome,
        );
        break;

      case UndoableActionType.steal:
        await db.playerStatsDao.recordSteal(widget.matchId, targetPlayerId);
        undoNotifier.recordSteal(playerId: targetPlayerId, playerName: targetPlayerName, matchId: widget.matchId, isHome: isHome);
        break;

      case UndoableActionType.block:
        await db.playerStatsDao.recordBlock(widget.matchId, targetPlayerId);
        undoNotifier.recordBlock(playerId: targetPlayerId, playerName: targetPlayerName, matchId: widget.matchId, isHome: isHome);
        break;

      case UndoableActionType.turnover:
        await db.playerStatsDao.recordTurnover(widget.matchId, targetPlayerId);
        undoNotifier.recordTurnover(playerId: targetPlayerId, playerName: targetPlayerName, matchId: widget.matchId, isHome: isHome);
        break;

      case UndoableActionType.assist:
        await db.playerStatsDao.recordAssist(widget.matchId, targetPlayerId);
        undoNotifier.recordAssist(playerId: targetPlayerId, playerName: targetPlayerName, matchId: widget.matchId, isHome: isHome);
        break;

      case UndoableActionType.rebound:
        final isOff = mergedData['isOffensive'] as bool? ?? false;
        await db.playerStatsDao.recordRebound(widget.matchId, targetPlayerId, isOff);
        undoNotifier.recordRebound(playerId: targetPlayerId, playerName: targetPlayerName, matchId: widget.matchId, isOffensive: isOff, isHome: isHome);
        break;

      default:
        break;
    }

    await _refreshStats();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('기록이 수정되었습니다'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// T/U 파울 수동 감소 (recordFoul increment:-1 + T or U 감소)
  Future<void> customFoulUndo(AppDatabase db, int playerId, {bool technical = false, bool unsportsmanlike = false}) async {
    await db.playerStatsDao.recordFoul(widget.matchId, playerId, increment: -1);
    if (technical) {
      await db.customStatement(
        'UPDATE local_player_stats SET technical_fouls = MAX(0, technical_fouls - 1), '
        'ejected = CASE WHEN technical_fouls - 1 + unsportsmanlike_fouls >= 2 THEN 1 ELSE 0 END, '
        'updated_at = ? WHERE local_match_id = ? AND tournament_team_player_id = ?',
        [DateTime.now().millisecondsSinceEpoch ~/ 1000, widget.matchId, playerId],
      );
    }
    if (unsportsmanlike) {
      await db.customStatement(
        'UPDATE local_player_stats SET unsportsmanlike_fouls = MAX(0, unsportsmanlike_fouls - 1), '
        'ejected = CASE WHEN technical_fouls + unsportsmanlike_fouls - 1 >= 2 THEN 1 ELSE 0 END, '
        'updated_at = ? WHERE local_match_id = ? AND tournament_team_player_id = ?',
        [DateTime.now().millisecondsSinceEpoch ~/ 1000, widget.matchId, playerId],
      );
    }
  }

  /// 파울아웃 취소 → 코트 복귀 다이얼로그
  Future<void> _showReturnToCourtDialog(int playerId, bool isHome) async {
    final players = isHome ? _homePlayers : _awayPlayers;
    final player = players.where((p) => p.player.id == playerId).firstOrNull;
    if (player == null) return;

    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black38,
      builder: (ctx) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 280,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 12)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '#${player.jerseyNumber ?? '-'} ${player.name}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  '파울아웃이 취소되었습니다.\n코트에 복귀시키겠습니까?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () { HapticFeedback.heavyImpact(); Navigator.pop(ctx, false); },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                          child: const Center(child: Text('벤치 유지', style: TextStyle(fontSize: 13))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () { HapticFeedback.heavyImpact(); Navigator.pop(ctx, true); },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.5)),
                          ),
                          child: const Center(child: Text('코트 복귀', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.successColor))),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result == true) {
      final db = ref.read(databaseProvider);
      await db.playerStatsDao.setOnCourt(widget.matchId, playerId, true);
      await db.playerStatsDao.setFouledOut(widget.matchId, playerId, false);
      await _refreshStats();
    }
  }

  Future<void> _handleUndoAction(UndoableAction action) async {
    // 연관 액션 확인
    final undoStack = ref.read(undoStackProvider);
    final linkedActions = undoStack.findLinkedActions(action.id);

    // 연관 액션이 있으면 확인 다이얼로그
    if (linkedActions.isNotEmpty) {
      final confirmed = await showUndoConfirmDialog(
        context: context,
        action: action,
        linkedActions: linkedActions,
      );

      if (confirmed != true) return;
    }

    // Undo 실행
    final undoneActions = ref.read(undoStackProvider.notifier).undoById(
      action.id,
      includeLinked: true,
    );

    // DB에서 실제 기록 삭제
    await _undoActionsInDatabase(undoneActions);

    // 데이터 새로고침
    await _refreshStats();

    if (mounted && undoneActions.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${action.description} 취소됨'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

/// 자동 저장 상태 인디케이터
class _AutoSaveStatusIndicator extends ConsumerWidget {
  const _AutoSaveStatusIndicator();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(autoSaveStatusProvider);
    final lastSaved = ref.watch(lastSavedTimeProvider);

    IconData icon;
    Color color;
    String tooltip;

    switch (status) {
      case AutoSaveStatus.idle:
        icon = Icons.cloud_done_outlined;
        color = AppTheme.textSecondary;
        tooltip = lastSaved != null
            ? '저장됨 ${_formatTime(lastSaved)}'
            : '자동 저장 대기';
        break;
      case AutoSaveStatus.saving:
        icon = Icons.cloud_sync;
        color = AppTheme.primaryColor;
        tooltip = '저장 중...';
        break;
      case AutoSaveStatus.saved:
        icon = Icons.cloud_done;
        color = AppTheme.successColor;
        tooltip = '저장 완료';
        break;
      case AutoSaveStatus.error:
        icon = Icons.cloud_off;
        color = AppTheme.errorColor;
        tooltip = '저장 실패';
        break;
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status == AutoSaveStatus.saving)
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color,
                ),
              )
            else
              Icon(icon, color: color, size: 14),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) {
      return '방금';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}분 전';
    } else {
      return '${diff.inHours}시간 전';
    }
  }
}

