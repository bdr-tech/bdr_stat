import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../providers/undo_stack_provider.dart';
import '../../../widgets/timer/game_timer_widget.dart';
import '../models/player_with_stats.dart';

/// 실시간 게임 로그 패널 (Sprint 2: FR-005, FR-011)
class LiveGameLogPanel extends ConsumerWidget {
  const LiveGameLogPanel({
    super.key,
    required this.matchId,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.homeTeamName,
    required this.awayTeamName,
    this.homeTeamColor = const Color(0xFFF97316),
    this.awayTeamColor = const Color(0xFF10B981),
    this.onUndoAction,
    this.onEditAction,
    this.homePlayers = const [],
    this.awayPlayers = const [],
    this.onTimerLongPress,
    this.onShotClockLongPress,
  });

  final int matchId;
  final int homeTeamId;
  final int awayTeamId;
  final String homeTeamName;
  final String awayTeamName;
  final Color homeTeamColor;
  final Color awayTeamColor;
  final List<PlayerWithStats> homePlayers;
  final List<PlayerWithStats> awayPlayers;
  final void Function(UndoableAction action)? onUndoAction;
  final void Function(UndoableAction original, Map<String, dynamic> editedData)? onEditAction;
  final VoidCallback? onTimerLongPress;
  final VoidCallback? onShotClockLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(gameTimerProvider);
    final timerNotifier = ref.read(gameTimerProvider.notifier);
    final undoStack = ref.watch(undoStackProvider);

    return Column(
      children: [
        // 게임 시계 + 위아래 화살표
        _buildGameClock(timerState, timerNotifier),
        const SizedBox(height: 20),

        // 샷 클락 + 위아래 화살표 (독립 동작)
        _buildShotClock(timerState, timerNotifier),
        const SizedBox(height: 20),

        // 쿼터 컨트롤 (탭 전환 가능)
        _buildQuarterControl(timerState, timerNotifier),
        const SizedBox(height: 16),

        // 라이브 로그 (최하단, 남는 공간 채움)
        Expanded(
          child: _buildLogSection(undoStack),
        ),
      ],
    );
  }

  /// 게임클락 + 위아래 화살표 (FR-005)
  Widget _buildGameClock(GameTimerState timerState, GameTimerNotifier timerNotifier) {
    return GestureDetector(
      onTap: timerNotifier.toggle,
      onLongPress: onTimerLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: timerState.isRunning
                ? const Color(0xFF10B981)
                : const Color(0xFF1E293B),
            width: 2,
          ),
          boxShadow: [
            if (timerState.isRunning)
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: -5,
              ),
          ],
        ),
        child: Column(
          children: [
            // 위 화살표 (증가)
            SizedBox(
              width: double.infinity,
              height: 32,
              child: GestureDetector(
                onTap: () {
                  if (timerState.isGameClockShowingDecimal) {
                    timerNotifier.adjustGameClockTenths(1);
                  } else {
                    timerNotifier.adjustGameClock(1);
                  }
                  HapticFeedback.lightImpact();
                },
                behavior: HitTestBehavior.opaque,
                child: Icon(
                  Icons.keyboard_arrow_up,
                  size: 28,
                  color: Colors.grey[400],
                ),
              ),
            ),
            // 게임클락 시간
            Text(
              timerState.formattedGameClock,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: timerState.isRunning
                    ? const Color(0xFF10B981)
                    : Colors.grey[400],
                letterSpacing: 4,
                shadows: timerState.isRunning
                    ? [
                        const Shadow(
                          color: Color(0xFF10B981),
                          blurRadius: 10,
                        ),
                      ]
                    : null,
              ),
            ),
            // 아래 화살표 (감소)
            SizedBox(
              width: double.infinity,
              height: 32,
              child: GestureDetector(
                onTap: () {
                  if (timerState.isGameClockShowingDecimal) {
                    timerNotifier.adjustGameClockTenths(-1);
                  } else {
                    timerNotifier.adjustGameClock(-1);
                  }
                  HapticFeedback.lightImpact();
                },
                behavior: HitTestBehavior.opaque,
                child: Icon(
                  Icons.keyboard_arrow_down,
                  size: 28,
                  color: Colors.grey[400],
                ),
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  timerState.isRunning ? Icons.play_arrow : Icons.pause,
                  size: 12,
                  color: timerState.isRunning
                      ? const Color(0xFF10B981)
                      : Colors.grey[400],
                ),
                const SizedBox(width: 4),
                Text(
                  timerState.isRunning ? 'RUNNING' : 'PAUSED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: timerState.isRunning
                        ? const Color(0xFF10B981)
                        : Colors.grey[400],
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 샷클락 + 위아래 화살표 (독립 동작)
  Widget _buildShotClock(GameTimerState timerState, GameTimerNotifier timerNotifier) {
    final isLow = timerState.shotClockTenths < (timerState.shotClockDecimalThreshold * 10);

    return Row(
      children: [
        // 14초 리셋
        Expanded(
          child: GestureDetector(
            onTap: timerNotifier.resetShotClock14,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: const Center(
                child: Text(
                  '14',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // 샷 클락 (중앙, 독립 toggle)
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: () {
              if (timerState.isShotClockPaused) {
                timerNotifier.startShotClock();
              } else {
                timerNotifier.pauseShotClock();
              }
              HapticFeedback.lightImpact();
            },
            onLongPress: onShotClockLongPress,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: isLow ? Colors.red.withValues(alpha: 0.2) : Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isLow ? Colors.red : const Color(0xFF1E293B),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  // 위 화살표 (+1초)
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: GestureDetector(
                      onTap: () {
                        timerNotifier.adjustShotClock(10);
                        HapticFeedback.lightImpact();
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Icon(
                        Icons.keyboard_arrow_up,
                        size: 28,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                  Text(
                    timerState.formattedShotClock,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: isLow ? Colors.red : const Color(0xFFEF4444),
                      letterSpacing: 2,
                      shadows: [
                        Shadow(
                          color: isLow ? Colors.red : const Color(0xFFEF4444),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  // 아래 화살표 (-1초)
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: GestureDetector(
                      onTap: () {
                        timerNotifier.adjustShotClock(-10);
                        HapticFeedback.lightImpact();
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        size: 28,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'SHOT CLOCK',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[400],
                          letterSpacing: 1,
                        ),
                      ),
                      if (timerState.isShotClockPaused) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text(
                            'PAUSED',
                            style: TextStyle(
                              fontSize: 7,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // 24초 리셋
        Expanded(
          child: GestureDetector(
            onTap: () => timerNotifier.resetShotClock(seconds: 24),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: const Center(
                child: Text(
                  '24',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuarterControl(GameTimerState timerState, GameTimerNotifier timerNotifier) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          timerState.maxQuarters,
          (index) {
            final quarter = index + 1;
            final isCurrent = timerState.quarter == quarter;
            final isPast = timerState.quarter > quarter;
            final isNext = quarter == timerState.quarter + 1;

            return GestureDetector(
              onTap: !isCurrent ? () {
                timerNotifier.setQuarter(quarter);
                HapticFeedback.heavyImpact();
              } : null,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCurrent
                      ? const Color(0xFF10B981)
                      : (isPast ? AppTheme.primaryColor.withValues(alpha: 0.3) : Colors.transparent),
                  border: Border.all(
                    color: isCurrent
                        ? const Color(0xFF10B981)
                        : (isPast ? AppTheme.primaryColor
                            : (isNext ? const Color(0xFF10B981).withValues(alpha: 0.5) : AppTheme.borderColor)),
                    width: isNext ? 2.5 : 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    'Q$quarter',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isCurrent || isPast
                          ? Colors.white
                          : (isNext ? const Color(0xFF10B981).withValues(alpha: 0.7) : AppTheme.textSecondary),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 로그 섹션 (FR-011: 고정 높이, 최대 4줄)
  Widget _buildLogSection(UndoStackState undoStack) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.borderColor,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // 헤더 (32px)
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'LIVE LOG',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${undoStack.length}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),

          // 로그 리스트 (최대 4개, 스크롤 없음)
          Expanded(
            child: undoStack.isEmpty
                ? _buildEmptyState()
                : _buildLogList(undoStack),
          ),
        ],
      ),
    );
  }

  /// 최근 4개 로그 항목 표시 (FR-011)
  Widget _buildLogList(UndoStackState undoStack) {
    final actions = undoStack.actions;
    final displayCount = math.min(actions.length, 4);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8),
      itemCount: displayCount,
      itemBuilder: (context, index) {
        // 최신 항목이 위에 오도록 역순
        final action = actions[actions.length - 1 - index];
        return _LogItem(
          action: action,
          isLatest: index == 0,
          homeTeamColor: homeTeamColor,
          awayTeamColor: awayTeamColor,
          homePlayers: homePlayers,
          awayPlayers: awayPlayers,
          homeTeamName: homeTeamName,
          awayTeamName: awayTeamName,
          onUndo: onUndoAction,
          onEdit: onEditAction,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sports_basketball,
            size: 40,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 12),
          Text(
            'RECORDING...',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              color: Colors.grey[500],
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '선수를 탭하여 기록을 시작하세요',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}

/// 로그 아이템
class _LogItem extends StatelessWidget {
  const _LogItem({
    required this.action,
    required this.isLatest,
    required this.homeTeamColor,
    required this.awayTeamColor,
    this.homePlayers = const [],
    this.awayPlayers = const [],
    this.homeTeamName = 'HOME',
    this.awayTeamName = 'AWAY',
    this.onUndo,
    this.onEdit,
  });

  final UndoableAction action;
  final bool isLatest;
  final Color homeTeamColor;
  final Color awayTeamColor;
  final List<PlayerWithStats> homePlayers;
  final List<PlayerWithStats> awayPlayers;
  final String homeTeamName;
  final String awayTeamName;
  final void Function(UndoableAction action)? onUndo;
  final void Function(UndoableAction original, Map<String, dynamic> editedData)? onEdit;

  Color get _teamColor {
    final isHome = action.data['isHome'] as bool? ?? true;
    return isHome ? homeTeamColor : awayTeamColor;
  }

  IconData get _actionIcon {
    switch (action.type) {
      case UndoableActionType.shot:
        final isMade = action.data['isMade'] as bool? ?? false;
        final isThree = action.data['isThreePointer'] as bool? ?? false;
        if (isThree) {
          return isMade ? Icons.star : Icons.star_outline;
        }
        return isMade ? Icons.sports_basketball : Icons.sports_basketball_outlined;
      case UndoableActionType.freeThrow:
        final isMade = action.data['isMade'] as bool? ?? false;
        return isMade ? Icons.check_circle : Icons.cancel;
      case UndoableActionType.assist:
        return Icons.compare_arrows;
      case UndoableActionType.rebound:
        return Icons.replay;
      case UndoableActionType.steal:
        return Icons.flash_on;
      case UndoableActionType.block:
        return Icons.block;
      case UndoableActionType.turnover:
        return Icons.error_outline;
      case UndoableActionType.foul:
        return Icons.front_hand;
      case UndoableActionType.timeout:
        return Icons.timer_off;
      case UndoableActionType.substitution:
        return Icons.swap_horiz;
    }
  }

  Color get _actionColor {
    switch (action.type) {
      case UndoableActionType.shot:
      case UndoableActionType.freeThrow:
        final isMade = action.data['isMade'] as bool? ?? false;
        return isMade ? AppTheme.successColor : AppTheme.errorColor;
      case UndoableActionType.assist:
      case UndoableActionType.rebound:
        return AppTheme.primaryColor;
      case UndoableActionType.steal:
      case UndoableActionType.block:
        return AppTheme.successColor;
      case UndoableActionType.turnover:
        return AppTheme.warningColor;
      case UndoableActionType.foul:
        return AppTheme.errorColor;
      case UndoableActionType.timeout:
      case UndoableActionType.substitution:
        return AppTheme.secondaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        HapticFeedback.heavyImpact();
        _showEditDialog(context);
      },
      child: Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: isLatest
            ? _teamColor.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isLatest
            ? Border.all(color: _teamColor.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        children: [
          // 팀 컬러 인디케이터
          Container(
            width: 3,
            height: 28,
            decoration: BoxDecoration(
              color: _teamColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),

          // 액션 아이콘
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: _actionColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _actionIcon,
              size: 10,
              color: _actionColor,
            ),
          ),
          const SizedBox(width: 6),

          // 내용
          Expanded(
            child: Text(
              '${action.typeLabel} #${action.playerName}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: isLatest ? FontWeight.bold : FontWeight.normal,
                color: isLatest ? AppTheme.textPrimary : AppTheme.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // 점수 변화
          if (action.pointsChange > 0)
            Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Text(
                '+${action.pointsChange}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.successColor,
                ),
              ),
            ),

          // Undo 버튼
          if (onUndo != null)
            GestureDetector(
              onTap: () => onUndo?.call(action),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.undo,
                  size: 12,
                  color: AppTheme.errorColor,
                ),
              ),
            ),
        ],
      ),
    ), // GestureDetector
    );
  }

  /// 롱프레스 → 풀 에디터 다이얼로그
  void _showEditDialog(BuildContext context) {
    final isHome = action.data['isHome'] as bool? ?? true;
    final isMade = action.data['isMade'] as bool?;
    final isThree = action.data['isThreePointer'] as bool?;
    final currentPlayers = isHome ? homePlayers : awayPlayers;
    final otherPlayers = isHome ? awayPlayers : homePlayers;

    // 스탯 타입 옵션
    const statTypes = [
      (type: UndoableActionType.shot, label: '슛'),
      (type: UndoableActionType.freeThrow, label: '자유투'),
      (type: UndoableActionType.assist, label: '어시스트'),
      (type: UndoableActionType.rebound, label: '리바운드'),
      (type: UndoableActionType.steal, label: '스틸'),
      (type: UndoableActionType.block, label: '블락'),
      (type: UndoableActionType.turnover, label: '턴오버'),
      (type: UndoableActionType.foul, label: '파울'),
    ];

    showDialog(
      context: context,
      barrierColor: Colors.black38,
      builder: (ctx) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 320,
            constraints: const BoxConstraints(maxHeight: 480),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 16)],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 헤더
                  Row(
                    children: [
                      Icon(_actionIcon, color: _actionColor, size: 18),
                      const SizedBox(width: 6),
                      const Text('로그 수정', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: const Icon(Icons.close, size: 18, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  const Divider(height: 12),

                  // ── 스탯 변경 ──
                  _sectionLabel('스탯'),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: statTypes.map((s) => _chip(
                      s.label,
                      action.type == s.type,
                      _actionColor,
                      () {
                        Navigator.pop(ctx);
                        HapticFeedback.heavyImpact();
                        // 타입 변경은 기존 Undo + 새 타입으로 재기록
                        onEdit?.call(action, {'_changeType': s.type.name});
                      },
                    )).toList(),
                  ),

                  // ── 결과 (슛/자유투) ──
                  if (isMade != null) ...[
                    const SizedBox(height: 8),
                    _sectionLabel('결과'),
                    Row(children: [
                      _chip('성공', isMade == true, AppTheme.successColor, () {
                        Navigator.pop(ctx); HapticFeedback.heavyImpact();
                        onEdit?.call(action, {'isMade': true});
                      }),
                      const SizedBox(width: 6),
                      _chip('실패', isMade == false, AppTheme.errorColor, () {
                        Navigator.pop(ctx); HapticFeedback.heavyImpact();
                        onEdit?.call(action, {'isMade': false});
                      }),
                      if (isThree != null) ...[
                        const SizedBox(width: 12),
                        _chip('2점', isThree == false, Colors.orange, () {
                          Navigator.pop(ctx); HapticFeedback.heavyImpact();
                          onEdit?.call(action, {'isThreePointer': false});
                        }),
                        const SizedBox(width: 6),
                        _chip('3점', isThree == true, Colors.purple, () {
                          Navigator.pop(ctx); HapticFeedback.heavyImpact();
                          onEdit?.call(action, {'isThreePointer': true});
                        }),
                      ],
                    ]),
                  ],

                  // ── 팀 변경 ──
                  const SizedBox(height: 8),
                  _sectionLabel('팀'),
                  Row(children: [
                    _chip(homeTeamName, isHome, homeTeamColor, () {
                      Navigator.pop(ctx); HapticFeedback.heavyImpact();
                      onEdit?.call(action, {'isHome': true});
                    }),
                    const SizedBox(width: 6),
                    _chip(awayTeamName, !isHome, awayTeamColor, () {
                      Navigator.pop(ctx); HapticFeedback.heavyImpact();
                      onEdit?.call(action, {'isHome': false});
                    }),
                  ]),

                  // ── 선수 변경 ──
                  const SizedBox(height: 8),
                  _sectionLabel('선수 (#${action.playerName})'),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: currentPlayers.map((p) {
                      final isCurrent = p.player.id == action.playerId;
                      return _chip(
                        '#${p.jerseyNumber ?? '-'}',
                        isCurrent,
                        isHome ? homeTeamColor : awayTeamColor,
                        isCurrent ? null : () {
                          Navigator.pop(ctx); HapticFeedback.heavyImpact();
                          onEdit?.call(action, {
                            'playerId': p.player.id,
                            'playerName': p.player.userName,
                          });
                        },
                      );
                    }).toList(),
                  ),

                  // ── 시간 ──
                  const SizedBox(height: 8),
                  _sectionLabel('시간'),
                  Text(
                    _formatTime(action.timestamp),
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),

                  const SizedBox(height: 12),
                  // Undo 버튼
                  if (onUndo != null)
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        HapticFeedback.heavyImpact();
                        onUndo?.call(action);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.4)),
                        ),
                        child: const Center(
                          child: Text('삭제 (Undo)', style: TextStyle(
                            color: AppTheme.errorColor, fontSize: 13, fontWeight: FontWeight.bold,
                          )),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
  );

  Widget _chip(String label, bool isSelected, Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: isSelected ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color.withValues(alpha: 0.6) : AppTheme.borderColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? color : AppTheme.textSecondary,
        )),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }
}
