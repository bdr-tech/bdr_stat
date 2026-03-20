// ─── Match Recording Screen ───────────────────────────────────────────────────
// Layout (v2):
//
//  ┌─ AppBar (team names + start/stop) ──────────────────────┐
//  ├─ Network banners ───────────────────────────────────────┤
//  ├─ ScoreboardHeader (~30%) ───────────────────────────────┤
//  │   Score │ Q/Clock/ShotClock(tappable) │ Score           │
//  │   Fouls │  [▶ 18s] [↺24] [↺14]       │ Fouls           │
//  │   TO    │                             │ TO              │
//  └─ Row ──────────────────────────────────────────────────┤
//     │ Column (flex:7)                    │ RightPanel(130) │
//     │  ├─ CourtLayer (Expanded)          │  LOG header     │
//     │  │   └─ Starters (both teams)      │  EventLog       │
//     │  └─ BenchRow (h:76, tap→AirCmd)    │                 │
//     └────────────────────────────────────┴─────────────────┘
//
// One-touch: tap any player (court starter OR bench) → CourtRadialMenuOverlay

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/bdr_design_system.dart';
import '../../../di/providers.dart';
import '../../providers/network_status_provider.dart';
import 'event_definitions.dart';
import 'recorder_notifier.dart';
import 'recorder_state.dart';
import 'widgets/bench_row.dart';
import 'widgets/court_layer.dart';
import 'widgets/right_panel.dart';
import 'widgets/scoreboard_header.dart';
import 'widgets/shot_follow_up_overlay.dart';
import 'widgets/syncing_banner.dart';
import 'widgets/team_picker.dart';
import 'widgets/substitution_sheet.dart';

// ─── Screen ──────────────────────────────────────────────────────────────────

class MatchRecordingScreen extends ConsumerStatefulWidget {
  const MatchRecordingScreen({
    super.key,
    required this.matchId,
    this.tournamentId = '',
    this.homeTeamId = 0,
    this.awayTeamId = 0,
    this.homeTeamName = 'HOME',
    this.awayTeamName = 'AWAY',
  });

  final int matchId;
  final String tournamentId;
  final int homeTeamId;
  final int awayTeamId;
  final String homeTeamName;
  final String awayTeamName;

  @override
  ConsumerState<MatchRecordingScreen> createState() =>
      _MatchRecordingScreenState();
}

class _MatchRecordingScreenState extends ConsumerState<MatchRecordingScreen> {
  late final MatchRecordingArgs _args;
  bool _wasOffline = false;
  bool _offlineBannerDismissed = false;

  // ── Court UX state ─────────────────────────────────────────────────────────
  final Map<int, Offset> _playerPositions = {};
  RadialMenuTarget? _activeRadialTarget;
  bool _shotOnlyRadial = false;
  FollowUpState? _followUp;

  void _initDefaultPositions(
    List<Map<String, dynamic>> homePlayers,
    List<Map<String, dynamic>> awayPlayers,
  ) {
    if (_playerPositions.isNotEmpty) return;
    const homeDefaults = [
      Offset(0.35, 0.50), Offset(0.25, 0.25), Offset(0.15, 0.15),
      Offset(0.20, 0.38), Offset(0.08, 0.50),
    ];
    const awayDefaults = [
      Offset(0.65, 0.50), Offset(0.75, 0.25), Offset(0.85, 0.15),
      Offset(0.80, 0.38), Offset(0.92, 0.50),
    ];
    final hs = homePlayers.where((p) => p['is_starter'] == true).toList();
    final as_ = awayPlayers.where((p) => p['is_starter'] == true).toList();
    setState(() {
      for (var i = 0; i < hs.length && i < homeDefaults.length; i++) {
        _playerPositions[hs[i]['id'] as int] = homeDefaults[i];
      }
      for (var i = 0; i < as_.length && i < awayDefaults.length; i++) {
        _playerPositions[as_[i]['id'] as int] = awayDefaults[i];
      }
    });
  }

  void _openRadialMenu(
    Map<String, dynamic> player,
    String teamSide,
    Offset screenCenter, {
    bool shotOnly = false,
  }) {
    setState(() {
      _shotOnlyRadial = shotOnly;
      _activeRadialTarget = RadialMenuTarget(
        player: player,
        teamSide: teamSide,
        screenCenter: screenCenter,
      );
    });
  }

  /// 코트 빈 곳 탭 → 가장 가까운 선수 기준 슛 메뉴
  void _openShotMenuAtPosition(Offset globalPos, RecordingState state) {
    // 코트 좌우로 홈/어웨이 판별 (화면 중앙 기준)
    final screenWidth = MediaQuery.of(context).size.width;
    final isLeftHalf = globalPos.dx < screenWidth / 2;
    final teamSide = isLeftHalf ? 'home' : 'away';
    final players = teamSide == 'home' ? state.homePlayers : state.awayPlayers;
    final starters = players.where((p) => p['is_starter'] == true).toList();
    if (starters.isEmpty) return;

    // 가장 가까운 스타터 찾기
    Map<String, dynamic>? closest;
    double minDist = double.infinity;
    for (final p in starters) {
      final pos = _playerPositions[p['id'] as int];
      if (pos == null) continue;
      // 상대 좌표를 대략적 글로벌로 변환 (정확하지 않아도 됨)
      final dist = (globalPos.dx / screenWidth - pos.dx).abs() +
          (globalPos.dy / MediaQuery.of(context).size.height - pos.dy).abs();
      if (dist < minDist) {
        minDist = dist;
        closest = p;
      }
    }
    closest ??= starters.first;

    _openRadialMenu(closest, teamSide, globalPos, shotOnly: true);
  }

  void _closeRadialMenu() {
    setState(() {
      _activeRadialTarget = null;
      _shotOnlyRadial = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _args = MatchRecordingArgs(
      matchId: widget.matchId,
      tournamentId: widget.tournamentId,
      homeTeamId: widget.homeTeamId,
      awayTeamId: widget.awayTeamId,
      homeTeamName: widget.homeTeamName,
      awayTeamName: widget.awayTeamName,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _wasOffline = !ref.read(isOnlineProvider);
      ref.listenManual(isOnlineProvider, (prev, next) {
        if (_wasOffline && next == true) {
          // 온라인 복구 시 자동 flush + 배너 리셋
          setState(() => _offlineBannerDismissed = false);
          ref.read(recordingProvider(_args).notifier).flushQueue();
        }
        if (next == false && prev == true) {
          // 오프라인 전환 시 배너 다시 표시
          setState(() => _offlineBannerDismissed = false);
        }
        _wasOffline = next == false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recordingProvider(_args));
    final notifier = ref.read(recordingProvider(_args).notifier);
    final isOnline = ref.watch(isOnlineProvider);
    final isLeftHanded = ref.watch(isLeftHandedProvider);

    ref.listen(recordingProvider(_args), (prev, next) {
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.errorMessage!),
          backgroundColor: AppTheme.warningColor,
          action: SnackBarAction(
            label: '닫기',
            textColor: Colors.white,
            onPressed: notifier.clearError,
          ),
        ));
      }
      // T+U 파울 퇴장 알림
      if (next.ejectedPlayerId != null && next.ejectedPlayerId != prev?.ejectedPlayerId) {
        final pid = next.ejectedPlayerId!;
        final allPlayers = [...next.homePlayers, ...next.awayPlayers];
        final player = allPlayers.firstWhere(
          (p) => p['id'] == pid,
          orElse: () => <String, dynamic>{},
        );
        final name = player['name'] as String? ?? '#$pid';
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('⚠️ $name 퇴장! (T+U 파울 2개)'),
          backgroundColor: AppTheme.errorColor,
          duration: const Duration(seconds: 4),
        ));
        // 퇴장 상태 리셋
        notifier.clearEjection();
      }
    });

    // Initialize default court positions on first roster load
    if (_playerPositions.isEmpty && state.homePlayers.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _initDefaultPositions(state.homePlayers, state.awayPlayers);
      });
    }

    return Scaffold(
      backgroundColor: DS.bg,
      appBar: _buildAppBar(context, state, notifier, isOnline),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(children: [
              SafeArea(
                child: Column(children: [
                  // ── Network banners ─────────────────────────────────────
                  if (!isOnline && !_offlineBannerDismissed)
                    OfflineBanner(
                      pendingCount: state.pendingCount,
                      onDismiss: () => setState(() => _offlineBannerDismissed = true),
                    ),
                  if (isOnline && state.isSyncing)
                    SyncingBanner(pendingCount: state.pendingCount),
                  if (isOnline && !state.isSyncing && state.pendingCount > 0)
                    FlushBanner(
                      pendingCount: state.pendingCount,
                      onFlush: notifier.flushQueue,
                    ),

                  // ── Top ~30%: Interactive scoreboard ────────────────────
                  Flexible(
                    flex: 0,
                    child: ScoreboardHeader(
                    state: state,
                    onShotClockToggle: state.isShotClockRunning
                        ? notifier.stopShotClock
                        : notifier.startShotClock,
                    onReset24: notifier.resetShotClock24,
                    onReset14: notifier.resetShotClock14,
                    onQuarterChange: (q) =>
                        _confirmQuarterChange(context, state, notifier, q),
                    onTimeout: notifier.recordTimeout,
                  )),

                  // ── Bottom ~70%: Court + Event log ───────────────────────
                  Expanded(
                    child: Row(children: [
                      // Left: Event log panel (왼손잡이 모드)
                      if (isLeftHanded)
                        _buildLogPanel(state, notifier, fromLeft: true),

                      // Court column (starters + bench)
                      Expanded(
                        child: Column(children: [
                          // Basketball court with both teams' starters
                          Expanded(
                            child: CourtLayer(
                              state: state,
                              playerPositions: _playerPositions,
                              onPlayerTap: (player, teamSide, pos) =>
                                  _openRadialMenu(player, teamSide, pos),
                              onCourtTap: (globalPos) =>
                                  _openShotMenuAtPosition(globalPos, state),
                            ),
                          ),

                          // Bench row — single tap opens Air Command
                          BenchRow(
                            state: state,
                            onPlayerTap: (player, teamSide, pos) =>
                                _openRadialMenu(player, teamSide, pos),
                          ),
                        ]),
                      ),

                      // Right: Event log panel (오른손잡이 모드, 기본)
                      if (!isLeftHanded)
                        _buildLogPanel(state, notifier, fromLeft: false),
                    ]),
                  ),
                ]),
              ),

              // Air Command radial menu overlay
              if (_activeRadialTarget != null)
                CourtRadialMenuOverlay(
                  target: _activeRadialTarget!,
                  state: state,
                  shotOnly: _shotOnlyRadial,
                  onDismiss: _closeRadialMenu,
                  onSelect: (def) => _handleRadialSelect(def, notifier),
                ),

              // Shot follow-up overlay (성공/실패 → 어시스트/리바운드)
              if (_followUp != null)
                ShotFollowUpOverlay(
                  followUp: _followUp!,
                  recordingState: state,
                  onShotResult: (made) => _handleShotResult(made, notifier),
                  onAssistSelect: (id, name) => _handleAssistSelect(id, name, notifier),
                  onReboundSelect: (type, team, id, name) =>
                      _handleReboundSelect(type, team, id, name, notifier),
                  onDismiss: () => setState(() => _followUp = null),
                ),
            ]),
    );
  }

  // ─── Radial Menu + Follow-Up Handlers ────────────────────────────────────────

  void _handleRadialSelect(EventDef def, RecordingNotifier notifier) {
    final target = _activeRadialTarget!;
    _closeRadialMenu();
    HapticFeedback.mediumImpact();

    final isShot = scoreEventTypes.contains(def.type);
    final isBlock = def.type == 'block';

    if (isShot) {
      // 슛 → 성공/실패 오버레이
      setState(() {
        _followUp = FollowUpState(
          position: target.screenCenter,
          teamSide: target.teamSide,
          playerId: target.player['id'] as int,
          playerName: target.player['name'] as String? ?? '',
          shotType: def.type,
          step: FollowUpStep.madeOrMissed,
        );
      });
    } else if (isBlock) {
      // 블락 → 블락 기록 후 리바운드 오버레이
      notifier.recordEvent(
        def.type,
        teamSide: target.teamSide,
        playerId: target.player['id'] as int?,
        playerName: target.player['name'] as String?,
      );
      // 블락 후 리바운드 선택 (상대팀 슛이 실패한 것)
      final shooterTeam = target.teamSide == 'home' ? 'away' : 'home';
      setState(() {
        _followUp = FollowUpState(
          position: target.screenCenter,
          teamSide: shooterTeam, // 슛한 팀 = 블락 당한 팀의 상대
          playerId: 0,
          playerName: '',
          shotType: '2pt',
          step: FollowUpStep.rebound,
          fromBlock: true,
        );
      });
    } else {
      // 기타 (STL, TO, FOUL) → 즉시 기록
      notifier.recordEvent(
        def.type,
        teamSide: target.teamSide,
        value: def.value,
        playerId: target.player['id'] as int?,
        playerName: target.player['name'] as String?,
      );
    }
  }

  void _handleShotResult(bool made, RecordingNotifier notifier) {
    final fu = _followUp!;
    if (made) {
      // 성공 → 득점 기록 → 어시스트 선택
      final def = eventDefs.firstWhere((d) => d.type == fu.shotType);
      notifier.recordEvent(
        fu.shotType,
        teamSide: fu.teamSide,
        value: def.value,
        playerId: fu.playerId,
        playerName: fu.playerName,
      );
      setState(() {
        _followUp = fu.copyWith(step: FollowUpStep.assist);
      });
    } else {
      // 실패 → 슛 실패 기록 → 리바운드 선택
      final missType = '${fu.shotType}_miss';
      notifier.recordEvent(
        missType,
        teamSide: fu.teamSide,
        playerId: fu.playerId,
        playerName: fu.playerName,
      );
      setState(() {
        _followUp = fu.copyWith(step: FollowUpStep.rebound);
      });
    }
  }

  void _handleAssistSelect(int? assistPlayerId, String? assistPlayerName, RecordingNotifier notifier) {
    final fu = _followUp!;
    if (assistPlayerId != null) {
      notifier.recordEvent(
        'assist',
        teamSide: fu.teamSide,
        playerId: assistPlayerId,
        playerName: assistPlayerName,
      );
    }
    setState(() => _followUp = null);
  }

  void _handleReboundSelect(
    String reboundType,
    String teamSide,
    int? playerId,
    String? playerName,
    RecordingNotifier notifier,
  ) {
    notifier.recordEvent(
      reboundType,
      teamSide: teamSide,
      playerId: playerId,
      playerName: playerName,
    );
    setState(() => _followUp = null);
  }

  // ─── Log Panel ──────────────────────────────────────────────────────────────

  Widget _buildLogPanel(RecordingState state, RecordingNotifier notifier,
      {required bool fromLeft}) {
    return Container(
      width: 130,
      decoration: BoxDecoration(
        color: DS.surface,
        border: Border(
          left: fromLeft
              ? BorderSide.none
              : const BorderSide(color: DS.glassBorder, width: 1),
          right: fromLeft
              ? const BorderSide(color: DS.glassBorder, width: 1)
              : BorderSide.none,
        ),
      ),
      child: RightPanel(
        state: state,
        onUndo: () => _confirmUndo(context, notifier),
      ),
    );
  }

  // ─── AppBar ────────────────────────────────────────────────────────────────

  AppBar _buildAppBar(
    BuildContext context,
    RecordingState state,
    RecordingNotifier notifier,
    bool isOnline,
  ) {
    final title = '${state.homeTeamName} vs ${state.awayTeamName}';

    return AppBar(
      backgroundColor: DS.bg,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new,
            size: 18, color: DS.textSecondary),
        onPressed: () => context.pop(),
      ),
      title: Text(
        title,
        style: DSText.jakartaBold(color: DS.textSecondary, size: 13),
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        // Settings (hand preference)
        IconButton(
          icon: const Icon(Icons.settings_outlined,
              color: DS.textSecondary, size: 20),
          tooltip: '설정',
          onPressed: () => _showSettingsDialog(context),
        ),

        // Share live scoreboard
        if (state.matchStatus == 'in_progress')
          IconButton(
            icon: const Icon(Icons.share_outlined,
                color: DS.textSecondary, size: 20),
            tooltip: '실시간 스코어보드 공유',
            onPressed: () => _showShareDialog(context, state),
          ),

        // Start match
        if (state.matchStatus == 'scheduled')
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TapScaleButton(
              onTap: () => _confirmStartMatch(context, notifier),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: DS.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(DS.radiusSm),
                  border:
                      Border.all(color: DS.success.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_arrow_rounded,
                        color: DS.success, size: 16),
                    const SizedBox(width: 4),
                    Text('시작', style: DSText.jakartaButton(color: DS.success)),
                  ],
                ),
              ),
            ),
          ),

        // End match
        if (state.matchStatus == 'in_progress')
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TapScaleButton(
              onTap: () => _confirmEndMatch(context, notifier),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: DS.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(DS.radiusSm),
                  border: Border.all(color: DS.error.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stop_rounded, color: DS.error, size: 16),
                    const SizedBox(width: 4),
                    Text('종료', style: DSText.jakartaButton(color: DS.error)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ─── Dialogs & Confirmations ───────────────────────────────────────────────

  void _showSettingsDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Consumer(
        builder: (_, settingsRef, __) {
          final isLeftHanded = settingsRef.watch(isLeftHandedProvider);
          return AlertDialog(
            title: const Text('설정'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  secondary: Icon(isLeftHanded ? Icons.back_hand : Icons.front_hand),
                  title: Text(isLeftHanded ? '왼손잡이 모드' : '오른손잡이 모드'),
                  subtitle: Text(isLeftHanded ? '로그 패널이 왼쪽' : '로그 패널이 오른쪽'),
                  value: isLeftHanded,
                  onChanged: (_) =>
                      settingsRef.read(isLeftHandedProvider.notifier).toggle(),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => ctx.pop(), child: const Text('닫기')),
            ],
          );
        },
      ),
    );
  }

  void _showShareDialog(BuildContext context, RecordingState state) {
    final url = 'https://mybdr.kr/live/${widget.matchId}';
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('실시간 스코어보드'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('아래 URL을 공유하면 실시간 점수를 볼 수 있습니다.',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(url,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.primaryColor,
                          fontFamily: 'monospace',
                        )),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy,
                        size: 18, color: AppTheme.primaryColor),
                    tooltip: '복사',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: url));
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                        content: Text('URL이 복사되었습니다.'),
                        duration: Duration(seconds: 2),
                      ));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => ctx.pop(), child: const Text('닫기')),
        ],
      ),
    );
  }

  Future<void> _confirmStartMatch(
      BuildContext context, RecordingNotifier notifier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('경기 시작'),
        content: const Text('경기를 시작하시겠습니까?'),
        actions: [
          TextButton(
              onPressed: () => ctx.pop(false), child: const Text('취소')),
          ElevatedButton(
              onPressed: () => ctx.pop(true), child: const Text('시작')),
        ],
      ),
    );
    if (confirmed == true) await notifier.startMatch();
  }

  Future<void> _confirmEndMatch(
      BuildContext context, RecordingNotifier notifier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('경기 종료'),
        content: const Text('경기를 종료하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
              onPressed: () => ctx.pop(false), child: const Text('취소')),
          ElevatedButton(
            onPressed: () => ctx.pop(true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor),
            child: const Text('종료'),
          ),
        ],
      ),
    );
    if (confirmed == true) await notifier.endMatch();
  }

  Future<void> _confirmQuarterChange(
    BuildContext context,
    RecordingState state,
    RecordingNotifier notifier,
    int q,
  ) async {
    // Show full quarter picker dialog
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('쿼터 변경'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(6, (i) {
            final quarter = i + 1;
            final label = quarter <= 4 ? 'Q$quarter' : 'OT${quarter - 4}';
            final isSelected = state.currentQuarter == quarter;
            return ListTile(
              title: Text(label),
              trailing: isSelected
                  ? const Icon(Icons.check, color: DS.gold)
                  : null,
              onTap: () async {
                ctx.pop();
                await _applyQuarterChange(context, state, notifier, quarter);
              },
            );
          }),
        ),
        actions: [
          TextButton(onPressed: () => ctx.pop(), child: const Text('취소')),
        ],
      ),
    );
  }

  Future<void> _applyQuarterChange(
    BuildContext context,
    RecordingState state,
    RecordingNotifier notifier,
    int q,
  ) async {
    final totalFouls = state.homeTeamFouls + state.awayTeamFouls;
    if (totalFouls == 0) {
      HapticFeedback.selectionClick();
      notifier.setQuarter(q);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('쿼터 변경'),
        content: Text(
          '쿼터를 변경하면 팀 파울이 초기화됩니다.\n\n'
          '${state.homeTeamName}: ${state.homeTeamFouls}파울\n'
          '${state.awayTeamName}: ${state.awayTeamFouls}파울\n\n'
          '계속하시겠습니까?',
        ),
        actions: [
          TextButton(
              onPressed: () => ctx.pop(false), child: const Text('취소')),
          ElevatedButton(
              onPressed: () => ctx.pop(true), child: const Text('변경')),
        ],
      ),
    );
    if (confirmed == true) {
      HapticFeedback.selectionClick();
      notifier.setQuarter(q);
    }
  }

  Future<void> _confirmUndo(
      BuildContext context, RecordingNotifier notifier) async {
    final topEvent =
        ref.read(recordingProvider(_args)).events.firstOrNull;
    if (topEvent == null) return;
    final def = eventDefs.firstWhere(
      (d) => d.type == topEvent.eventType,
      orElse: () => EventDef(
          topEvent.eventType, topEvent.eventType, Icons.circle, AppTheme.textHint),
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('마지막 이벤트 취소'),
        content: Text('"${def.label}"을(를) 취소하시겠습니까?'),
        actions: [
          TextButton(
              onPressed: () => ctx.pop(false), child: const Text('아니오')),
          ElevatedButton(
              onPressed: () => ctx.pop(true), child: const Text('취소하기')),
        ],
      ),
    );
    if (confirmed == true) await notifier.undoLastEvent();
  }

  // ─── Unused helpers (kept for backward compatibility) ─────────────────────

  // ignore: unused_element
  Future<void> _showTeamPicker(
    BuildContext context,
    RecordingState state,
    RecordingNotifier notifier,
    String eventType,
    int? value,
  ) async {
    HapticFeedback.lightImpact();
    final def = eventDefs.firstWhere(
      (d) => d.type == eventType,
      orElse: () => const EventDef('', '', Icons.circle, Colors.grey),
    );

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => TeamPickerSheet(
        eventLabel: def.label,
        homeTeamName: state.homeTeamName,
        awayTeamName: state.awayTeamName,
        homePlayers: state.homePlayers,
        awayPlayers: state.awayPlayers,
        onPick: (teamSide, playerId, playerName) {
          Navigator.of(ctx).pop();
          notifier.recordEvent(
            eventType,
            teamSide: teamSide,
            value: value,
            playerId: playerId,
            playerName: playerName,
          );
        },
        onToggleStarter: notifier.togglePlayerStarter,
      ),
    );
  }

  // ignore: unused_element
  Future<void> _showSubstitutionPicker(
    BuildContext context,
    RecordingState state,
    RecordingNotifier notifier,
  ) async {
    HapticFeedback.lightImpact();
    if (state.homePlayers.isEmpty && state.awayPlayers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('선수 명단이 없습니다.'),
        backgroundColor: AppTheme.warningColor,
      ));
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SubstitutionSheet(
        homeTeamName: state.homeTeamName,
        awayTeamName: state.awayTeamName,
        homePlayers: state.homePlayers,
        awayPlayers: state.awayPlayers,
        onSubstitute: (teamSide, outId, outName, inId, inName) {
          Navigator.of(ctx).pop();
          notifier.recordSubstitution(
            teamSide: teamSide,
            outPlayerId: outId,
            outPlayerName: outName,
            inPlayerId: inId,
            inPlayerName: inName,
          );
        },
      ),
    );
  }
}
