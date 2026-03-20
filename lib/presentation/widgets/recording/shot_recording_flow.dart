import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' hide Column;

import '../../../core/theme/app_theme.dart';
import '../../../data/database/database.dart';
import '../court/basketball_court.dart';

/// 슛 기록 상태
enum ShotRecordingStep {
  selectPlayer, // 선수 선택
  selectShotType, // 슛 종류 선택 (2점/3점)
  selectCourtPosition, // 코트 위치 터치
  selectResult, // 성공/실패
  selectAssist, // 어시스트 선수 선택 (성공 시)
  selectRebound, // 리바운드 선수 선택 (실패 시)
  completed, // 완료
}

/// 슛 기록 데이터
class ShotRecordingData {
  final LocalTournamentPlayer? player;
  final String? shotType; // '2pt', '3pt', 'ft'
  final double? courtX;
  final double? courtY;
  final int? courtZone;
  final bool? isMade;
  final LocalTournamentPlayer? assistPlayer;
  final LocalTournamentPlayer? reboundPlayer;
  final bool? isOffensiveRebound;

  const ShotRecordingData({
    this.player,
    this.shotType,
    this.courtX,
    this.courtY,
    this.courtZone,
    this.isMade,
    this.assistPlayer,
    this.reboundPlayer,
    this.isOffensiveRebound,
  });

  ShotRecordingData copyWith({
    LocalTournamentPlayer? player,
    String? shotType,
    double? courtX,
    double? courtY,
    int? courtZone,
    bool? isMade,
    LocalTournamentPlayer? assistPlayer,
    LocalTournamentPlayer? reboundPlayer,
    bool? isOffensiveRebound,
  }) {
    return ShotRecordingData(
      player: player ?? this.player,
      shotType: shotType ?? this.shotType,
      courtX: courtX ?? this.courtX,
      courtY: courtY ?? this.courtY,
      courtZone: courtZone ?? this.courtZone,
      isMade: isMade ?? this.isMade,
      assistPlayer: assistPlayer ?? this.assistPlayer,
      reboundPlayer: reboundPlayer ?? this.reboundPlayer,
      isOffensiveRebound: isOffensiveRebound ?? this.isOffensiveRebound,
    );
  }

  int get points {
    if (isMade != true) return 0;
    switch (shotType) {
      case '3pt':
        return 3;
      case '2pt':
        return 2;
      case 'ft':
        return 1;
      default:
        return 0;
    }
  }

  bool get isThreePointer => shotType == '3pt';
}

/// 슛 기록 플로우 위젯
class ShotRecordingFlow extends ConsumerStatefulWidget {
  const ShotRecordingFlow({
    super.key,
    required this.teamPlayers,
    required this.opponentPlayers,
    required this.teamId,
    required this.opponentTeamId,
    required this.currentQuarter,
    required this.gameClockSeconds,
    required this.homeScore,
    required this.awayScore,
    required this.isHomeTeam,
    required this.onShotRecorded,
    this.selectedPlayer,
  });

  final List<LocalTournamentPlayer> teamPlayers;
  final List<LocalTournamentPlayer> opponentPlayers;
  final int teamId;
  final int opponentTeamId;
  final int currentQuarter;
  final int gameClockSeconds;
  final int homeScore;
  final int awayScore;
  final bool isHomeTeam;
  final void Function(ShotRecordingData data) onShotRecorded;
  final LocalTournamentPlayer? selectedPlayer;

  @override
  ConsumerState<ShotRecordingFlow> createState() => _ShotRecordingFlowState();
}

class _ShotRecordingFlowState extends ConsumerState<ShotRecordingFlow> {
  ShotRecordingStep _currentStep = ShotRecordingStep.selectShotType;
  ShotRecordingData _data = const ShotRecordingData();
  final List<ShotMarker> _shotMarkers = [];

  @override
  void initState() {
    super.initState();
    if (widget.selectedPlayer != null) {
      _data = _data.copyWith(player: widget.selectedPlayer);
    }
  }

  void _selectShotType(String type) {
    setState(() {
      _data = _data.copyWith(shotType: type);
      if (type == 'ft') {
        // 자유투는 코트 위치 선택 건너뛰기
        _currentStep = ShotRecordingStep.selectResult;
      } else {
        _currentStep = ShotRecordingStep.selectCourtPosition;
      }
    });
  }

  void _selectCourtPosition(double x, double y, int zone) {
    setState(() {
      // 3점선 체크
      final isThree = CourtZones.isThreePointZone(zone);
      final shotType = isThree ? '3pt' : '2pt';

      _data = _data.copyWith(
        courtX: x,
        courtY: y,
        courtZone: zone,
        shotType: shotType,
      );
      _currentStep = ShotRecordingStep.selectResult;
    });
  }

  void _selectResult(bool isMade) {
    setState(() {
      _data = _data.copyWith(isMade: isMade);

      // 슛 마커 추가
      if (_data.courtX != null && _data.courtY != null) {
        _shotMarkers.add(ShotMarker(
          x: _data.courtX!,
          y: _data.courtY!,
          isMade: isMade,
          isThreePointer: _data.isThreePointer,
        ));
      }

      if (isMade) {
        _currentStep = ShotRecordingStep.selectAssist;
      } else {
        _currentStep = ShotRecordingStep.selectRebound;
      }
    });
  }

  void _selectAssist(LocalTournamentPlayer? player) {
    setState(() {
      _data = _data.copyWith(assistPlayer: player);
      _currentStep = ShotRecordingStep.completed;
    });
    _complete();
  }

  void _selectRebound(LocalTournamentPlayer? player, bool isOffensive) {
    setState(() {
      _data = _data.copyWith(
        reboundPlayer: player,
        isOffensiveRebound: isOffensive,
      );
      _currentStep = ShotRecordingStep.completed;
    });
    _complete();
  }

  void _skipAssistOrRebound() {
    setState(() {
      _currentStep = ShotRecordingStep.completed;
    });
    _complete();
  }

  void _complete() {
    widget.onShotRecorded(_data);
    // 리셋
    setState(() {
      _currentStep = ShotRecordingStep.selectShotType;
      _data = ShotRecordingData(player: widget.selectedPlayer);
    });
  }

  void _cancel() {
    setState(() {
      _currentStep = ShotRecordingStep.selectShotType;
      _data = ShotRecordingData(player: widget.selectedPlayer);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 진행 상태 표시
        _buildProgressIndicator(),
        const SizedBox(height: 16),

        // 현재 단계 UI
        Expanded(
          child: _buildCurrentStepUI(),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    final steps = [
      '슛 종류',
      '위치',
      '결과',
      _data.isMade == true ? '어시스트' : '리바운드',
    ];

    int currentIndex;
    switch (_currentStep) {
      case ShotRecordingStep.selectShotType:
        currentIndex = 0;
        break;
      case ShotRecordingStep.selectCourtPosition:
        currentIndex = 1;
        break;
      case ShotRecordingStep.selectResult:
        currentIndex = 2;
        break;
      case ShotRecordingStep.selectAssist:
      case ShotRecordingStep.selectRebound:
        currentIndex = 3;
        break;
      default:
        currentIndex = 0;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(steps.length, (index) {
        final isActive = index == currentIndex;
        final isCompleted = index < currentIndex;

        return Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.primaryColor
                    : (isCompleted
                        ? AppTheme.successColor
                        : AppTheme.backgroundColor),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                steps[index],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: (isActive || isCompleted)
                      ? Colors.white
                      : AppTheme.textSecondary,
                ),
              ),
            ),
            if (index < steps.length - 1)
              Container(
                width: 20,
                height: 2,
                color: isCompleted
                    ? AppTheme.successColor
                    : AppTheme.borderColor,
              ),
          ],
        );
      }),
    );
  }

  Widget _buildCurrentStepUI() {
    switch (_currentStep) {
      case ShotRecordingStep.selectShotType:
        return _buildShotTypeSelector();
      case ShotRecordingStep.selectCourtPosition:
        return _buildCourtPositionSelector();
      case ShotRecordingStep.selectResult:
        return _buildResultSelector();
      case ShotRecordingStep.selectAssist:
        return _buildAssistSelector();
      case ShotRecordingStep.selectRebound:
        return _buildReboundSelector();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildShotTypeSelector() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_data.player != null)
          Text(
            '${_data.player!.userName} 슛 기록',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ShotTypeButton(
              label: '2점',
              icon: Icons.sports_basketball,
              color: AppTheme.primaryColor,
              onTap: () => _selectShotType('2pt'),
            ),
            const SizedBox(width: 16),
            _ShotTypeButton(
              label: '3점',
              icon: Icons.star,
              color: AppTheme.secondaryColor,
              onTap: () => _selectShotType('3pt'),
            ),
            const SizedBox(width: 16),
            _ShotTypeButton(
              label: '자유투',
              icon: Icons.check_circle,
              color: AppTheme.warningColor,
              onTap: () => _selectShotType('ft'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: _cancel,
          child: const Text('취소'),
        ),
      ],
    );
  }

  Widget _buildCourtPositionSelector() {
    return Column(
      children: [
        Text(
          '${_data.shotType == '3pt' ? '3점' : '2점'} 슛 위치를 터치하세요',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: BasketballCourt(
              onCourtTap: _selectCourtPosition,
              shots: _shotMarkers,
              showZones: true,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: _cancel,
              child: const Text('취소'),
            ),
            const SizedBox(width: 16),
            TextButton(
              onPressed: () {
                // 위치 없이 진행 (위치 모름)
                setState(() {
                  _currentStep = ShotRecordingStep.selectResult;
                });
              },
              child: const Text('위치 건너뛰기'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResultSelector() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_data.courtZone != null)
          Text(
            '${CourtZones.getZoneName(_data.courtZone!)} ${_data.shotType == '3pt' ? '3점' : '2점'}',
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
            ),
          ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ResultButton(
              label: '성공',
              icon: Icons.check_circle,
              color: AppTheme.shotMadeColor,
              onTap: () => _selectResult(true),
            ),
            const SizedBox(width: 32),
            _ResultButton(
              label: '실패',
              icon: Icons.cancel,
              color: AppTheme.shotMissedColor,
              onTap: () => _selectResult(false),
            ),
          ],
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: _cancel,
          child: const Text('취소'),
        ),
      ],
    );
  }

  Widget _buildAssistSelector() {
    // 본인 제외한 팀 동료
    final availablePlayers = widget.teamPlayers
        .where((p) => p.id != _data.player?.id)
        .toList();

    return Column(
      children: [
        const Text(
          '어시스트한 선수를 선택하세요',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: availablePlayers.length,
            itemBuilder: (context, index) {
              final player = availablePlayers[index];
              return _PlayerSelectButton(
                player: player,
                onTap: () => _selectAssist(player),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: _skipAssistOrRebound,
                child: const Text('어시스트 없음'),
              ),
              const SizedBox(width: 16),
              TextButton(
                onPressed: _cancel,
                child: const Text('취소'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReboundSelector() {
    return Column(
      children: [
        const Text(
          '리바운드 선수를 선택하세요',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),

        // 오펜시브 리바운드 (우리 팀)
        Expanded(
          child: Row(
            children: [
              // 우리 팀 (오펜시브)
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '오펜시브 리바운드',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: widget.teamPlayers.length,
                        itemBuilder: (context, index) {
                          final player = widget.teamPlayers[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: _PlayerSelectButton(
                              player: player,
                              onTap: () => _selectRebound(player, true),
                              compact: true,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const VerticalDivider(),

              // 상대 팀 (디펜시브)
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '디펜시브 리바운드',
                        style: TextStyle(
                          color: AppTheme.secondaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: widget.opponentPlayers.length,
                        itemBuilder: (context, index) {
                          final player = widget.opponentPlayers[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: _PlayerSelectButton(
                              player: player,
                              onTap: () => _selectRebound(player, false),
                              compact: true,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: _skipAssistOrRebound,
                child: const Text('리바운드 없음'),
              ),
              const SizedBox(width: 16),
              TextButton(
                onPressed: _cancel,
                child: const Text('취소'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 슛 종류 버튼
class _ShotTypeButton extends StatelessWidget {
  const _ShotTypeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 36),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 결과 버튼
class _ResultButton extends StatelessWidget {
  const _ResultButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 56),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 선수 선택 버튼
class _PlayerSelectButton extends StatelessWidget {
  const _PlayerSelectButton({
    required this.player,
    required this.onTap,
    this.compact = false,
  });

  final LocalTournamentPlayer player;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Row(
            children: [
              if (player.jerseyNumber != null)
                Text(
                  '#${player.jerseyNumber}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              if (player.jerseyNumber != null) const SizedBox(width: 8),
              Expanded(
                child: Text(
                  player.userName,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.surfaceColor,
        foregroundColor: AppTheme.textPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (player.jerseyNumber != null)
            Text(
              '#${player.jerseyNumber}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          if (player.jerseyNumber != null) const SizedBox(width: 8),
          Flexible(
            child: Text(
              player.userName,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// 슛 기록 서비스 (실제 DB 저장)
class ShotRecordingService {
  final AppDatabase database;

  ShotRecordingService(this.database);

  Future<void> recordShot({
    required int localMatchId,
    required ShotRecordingData data,
    required int quarter,
    required int gameClockSeconds,
    required int homeScore,
    required int awayScore,
    required int teamId,
  }) async {
    if (data.player == null) return;

    final localId = const Uuid().v4();
    final now = DateTime.now();

    // Play-by-Play 기록
    await database.playByPlayDao.insertPlay(
      LocalPlayByPlaysCompanion.insert(
        localId: localId,
        localMatchId: localMatchId,
        tournamentTeamPlayerId: data.player!.id,
        tournamentTeamId: teamId,
        quarter: quarter,
        gameClockSeconds: gameClockSeconds,
        actionType: 'shot',
        actionSubtype: Value(data.shotType),
        isMade: Value(data.isMade ?? false),
        pointsScored: Value(data.points),
        courtX: Value(data.courtX),
        courtY: Value(data.courtY),
        courtZone: Value(data.courtZone),
        assistPlayerId: Value(data.assistPlayer?.id),
        homeScoreAtTime: homeScore,
        awayScoreAtTime: awayScore,
        createdAt: now,
      ),
    );

    // 어시스트 기록
    if (data.isMade == true && data.assistPlayer != null) {
      final assistLocalId = const Uuid().v4();
      await database.playByPlayDao.insertPlay(
        LocalPlayByPlaysCompanion.insert(
          localId: assistLocalId,
          localMatchId: localMatchId,
          tournamentTeamPlayerId: data.assistPlayer!.id,
          tournamentTeamId: teamId,
          quarter: quarter,
          gameClockSeconds: gameClockSeconds,
          actionType: 'assist',
          homeScoreAtTime: homeScore,
          awayScoreAtTime: awayScore,
          createdAt: now,
        ),
      );
    }

    // 리바운드 기록
    if (data.isMade == false && data.reboundPlayer != null) {
      final reboundLocalId = const Uuid().v4();
      final reboundTeamId =
          data.isOffensiveRebound == true ? teamId : data.reboundPlayer!.tournamentTeamId;

      await database.playByPlayDao.insertPlay(
        LocalPlayByPlaysCompanion.insert(
          localId: reboundLocalId,
          localMatchId: localMatchId,
          tournamentTeamPlayerId: data.reboundPlayer!.id,
          tournamentTeamId: reboundTeamId,
          quarter: quarter,
          gameClockSeconds: gameClockSeconds,
          actionType: 'rebound',
          actionSubtype: Value(
              data.isOffensiveRebound == true ? 'offensive' : 'defensive'),
          homeScoreAtTime: homeScore,
          awayScoreAtTime: awayScore,
          createdAt: now,
        ),
      );
    }

    // 선수 스탯 업데이트
    await _updatePlayerStats(localMatchId, data, teamId);
  }

  Future<void> _updatePlayerStats(
    int localMatchId,
    ShotRecordingData data,
    int teamId,
  ) async {
    if (data.player == null) return;

    final existingStat = await database.playerStatsDao.getPlayerStats(
      localMatchId,
      data.player!.id,
    );

    if (existingStat == null) return;

    // 슛 통계 업데이트
    int fgMade = existingStat.fieldGoalsMade;
    int fgAttempted = existingStat.fieldGoalsAttempted;
    int twoMade = existingStat.twoPointersMade;
    int twoAttempted = existingStat.twoPointersAttempted;
    int threeMade = existingStat.threePointersMade;
    int threeAttempted = existingStat.threePointersAttempted;
    int ftMade = existingStat.freeThrowsMade;
    int ftAttempted = existingStat.freeThrowsAttempted;
    int points = existingStat.points;

    switch (data.shotType) {
      case '2pt':
        fgAttempted++;
        twoAttempted++;
        if (data.isMade == true) {
          fgMade++;
          twoMade++;
          points += 2;
        }
        break;
      case '3pt':
        fgAttempted++;
        threeAttempted++;
        if (data.isMade == true) {
          fgMade++;
          threeMade++;
          points += 3;
        }
        break;
      case 'ft':
        ftAttempted++;
        if (data.isMade == true) {
          ftMade++;
          points += 1;
        }
        break;
    }

    await database.playerStatsDao.updatePlayerStats(
      existingStat.id,
      LocalPlayerStatsCompanion(
        fieldGoalsMade: Value(fgMade),
        fieldGoalsAttempted: Value(fgAttempted),
        twoPointersMade: Value(twoMade),
        twoPointersAttempted: Value(twoAttempted),
        threePointersMade: Value(threeMade),
        threePointersAttempted: Value(threeAttempted),
        freeThrowsMade: Value(ftMade),
        freeThrowsAttempted: Value(ftAttempted),
        points: Value(points),
        updatedAt: Value(DateTime.now()),
      ),
    );

    // 어시스트 업데이트
    if (data.isMade == true && data.assistPlayer != null) {
      final assistStat = await database.playerStatsDao.getPlayerStats(
        localMatchId,
        data.assistPlayer!.id,
      );
      if (assistStat != null) {
        await database.playerStatsDao.updatePlayerStats(
          assistStat.id,
          LocalPlayerStatsCompanion(
            assists: Value(assistStat.assists + 1),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
    }

    // 리바운드 업데이트
    if (data.isMade == false && data.reboundPlayer != null) {
      final reboundStat = await database.playerStatsDao.getPlayerStats(
        localMatchId,
        data.reboundPlayer!.id,
      );
      if (reboundStat != null) {
        final isOffensive = data.isOffensiveRebound == true;
        await database.playerStatsDao.updatePlayerStats(
          reboundStat.id,
          LocalPlayerStatsCompanion(
            offensiveRebounds: Value(
                reboundStat.offensiveRebounds + (isOffensive ? 1 : 0)),
            defensiveRebounds: Value(
                reboundStat.defensiveRebounds + (isOffensive ? 0 : 1)),
            totalRebounds: Value(reboundStat.totalRebounds + 1),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
    }
  }
}
