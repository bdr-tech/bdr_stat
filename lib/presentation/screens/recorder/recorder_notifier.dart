// ─── Recording Notifier ───────────────────────────────────────────────────────
// StateNotifier and Provider for MatchRecordingScreen.
// Separated from match_recording_screen.dart for maintainability.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/event_queue.dart';
import '../../../core/services/supabase_service.dart';
import '../../../di/providers.dart';
import '../../providers/network_status_provider.dart';
import '../../providers/supabase_tournament_provider.dart';
import 'event_definitions.dart';
import 'recorder_state.dart';

// ─── Notifier ─────────────────────────────────────────────────────────────────

class RecordingNotifier extends StateNotifier<RecordingState> {
  RecordingNotifier({
    required this.matchId,
    required this.tournamentId,
    required this.ref,
    required int homeTeamId,
    required int awayTeamId,
    required String homeTeamName,
    required String awayTeamName,
  }) : super(RecordingState(
          homeTeamId: homeTeamId,
          awayTeamId: awayTeamId,
          homeTeamName: homeTeamName,
          awayTeamName: awayTeamName,
        )) {
    _init();
  }

  final int matchId;
  final String tournamentId;
  final Ref ref;
  final _queue = EventQueue();
  final _uuid = const Uuid();
  Timer? _gameTimer;
  Timer? _shotClockTimer;
  RealtimeChannel? _rosterChannel;
  DateTime? _gameTimerStartedAt;
  int _elapsedBeforePause = 0;
  ProviderSubscription<bool>? _networkSub;

  @override
  void dispose() {
    _gameTimer?.cancel();
    _shotClockTimer?.cancel();
    _networkSub?.close();
    if (_rosterChannel != null) {
      SupabaseService.instance.unsubscribe(_rosterChannel!);
    }
    super.dispose();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    await _queue.load();
    await Future.wait([
      _loadEvents(),
      _loadRoster(),
    ]);
    state = state.copyWith(
      isLoading: false,
      pendingCount: _queue.length,
    );

    // 경기 화면 진입 시 로스터 Realtime 구독 시작
    if (tournamentId.isNotEmpty) {
      _rosterChannel = SupabaseService.instance.subscribeToRoster(
        tournamentId: tournamentId,
        onChanged: _reloadRoster, // 웹에서 선수 변경 시 자동 갱신
      );
    }

    // 네트워크 복구 시 자동 flush + 미반영 상태 변경 재시도
    _networkSub = ref.listen<bool>(isOnlineProvider, (prev, isOnline) {
      if (prev == false && isOnline) {
        _onNetworkRecovered();
      }
    });
  }

  Future<void> _onNetworkRecovered() async {
    // 1. 오프라인 큐 flush
    if (!_queue.isEmpty) {
      await flushQueue();
    }
    // 2. 미반영 상태 변경 재시도
    if (state.pendingStatusChange != null) {
      final apiClient = ref.read(apiClientProvider);
      final result = await apiClient.updateMatchStatus(matchId, state.pendingStatusChange!);
      if (result.isSuccess) {
        state = state.copyWith(clearPendingStatus: true, clearError: true);
      }
    }
  }

  // §1.1 선수 명단 로드 — Supabase RPC 사용 (display_name 포함, 빠른 직접 쿼리)
  Future<void> _loadRoster() async {
    if (tournamentId.isEmpty) {
      // tournamentId 없으면 mybdr API 폴백
      final apiClient = ref.read(apiClientProvider);
      final result = await apiClient.getMatchRoster(matchId);
      if (!result.isSuccess) {
        state = state.copyWith(errorMessage: '선수 명단을 불러오지 못했습니다.');
        return;
      }
      final data = result.data!;
      state = state.copyWith(
        homePlayers: (data['home_players'] as List? ?? [])
            .map((p) => Map<String, dynamic>.from(p as Map))
            .toList(),
        awayPlayers: (data['away_players'] as List? ?? [])
            .map((p) => Map<String, dynamic>.from(p as Map))
            .toList(),
      );
      return;
    }

    try {
      // Supabase RPC: get_tournament_players → 전체 선수 목록 (display_name 포함)
      final players =
          await SupabaseService.instance.fetchTournamentPlayers(tournamentId);

      // tournament_team_id 기준으로 홈/원정 분리
      final homeId = state.homeTeamId;
      final awayId = state.awayTeamId;

      final homePlayers = players
          .where((p) => (p['tournament_team_id'] as int?) == homeId)
          .map((p) => {
                'id': p['player_id'],
                'name': p['display_name'],
                'jersey_number': p['jersey_number'],
                'is_starter': p['player_role'] == 'starter',
                'role': p['player_role'],
              })
          .toList();

      final awayPlayers = players
          .where((p) => (p['tournament_team_id'] as int?) == awayId)
          .map((p) => {
                'id': p['player_id'],
                'name': p['display_name'],
                'jersey_number': p['jersey_number'],
                'is_starter': p['player_role'] == 'starter',
                'role': p['player_role'],
              })
          .toList();

      state = state.copyWith(
        homePlayers: homePlayers.cast<Map<String, dynamic>>(),
        awayPlayers: awayPlayers.cast<Map<String, dynamic>>(),
      );
    } catch (e) {
      state = state.copyWith(errorMessage: '선수 명단을 불러오지 못했습니다.');
    }
  }

  /// Realtime 로스터 변경 감지 시 재로드
  Future<void> _reloadRoster() async {
    // 캐시 무효화 후 재조회
    ref.invalidate(supabasePlayersProvider(tournamentId));
    await _loadRoster();
  }

  Future<void> _loadEvents() async {
    final apiClient = ref.read(apiClientProvider);
    final result = await apiClient.getEvents(matchId);
    if (!result.isSuccess) return;

    final rawEvents = result.data!;
    final items = <RecordingEventItem>[];
    int homeScore = 0;
    int awayScore = 0;
    String homeTeamName = state.homeTeamName;
    String awayTeamName = state.awayTeamName;
    String matchStatus = state.matchStatus;
    int homeTeamFouls = 0;
    int awayTeamFouls = 0;

    for (final raw in rawEvents) {
      final e = raw as Map<String, dynamic>;
      final id = e['id'] as int? ?? 0;
      final clientEventId = e['client_event_id'] as String? ?? '';
      final eventType = e['event_type'] as String? ?? '';
      final createdAt =
          DateTime.tryParse(e['created_at']?.toString() ?? '') ?? DateTime.now();
      final quarter = e['quarter'] as int?;
      final gameTime = e['game_time'] as String?;
      final playerId = e['player_id'] as int?;

      final teamId = e['team_id'] as int?;
      String teamSide = '';
      if (teamId != null) {
        if (teamId == state.homeTeamId) teamSide = 'home';
        if (teamId == state.awayTeamId) teamSide = 'away';
      }

      // 파울 집계 — 현재 쿼터의 파울만 카운트 (쿼터별 리셋 규칙)
      if ((eventType == 'foul_personal' || eventType == 'foul_technical' ||
           eventType == 'foul_unsportsmanlike' || eventType == 'foul_offensive') &&
          quarter == state.currentQuarter) {
        if (teamSide == 'home') homeTeamFouls++;
        if (teamSide == 'away') awayTeamFouls++;
      }

      if (e['home_team_name'] != null) homeTeamName = e['home_team_name'] as String;
      if (e['away_team_name'] != null) awayTeamName = e['away_team_name'] as String;
      if (e['match_status'] != null) matchStatus = e['match_status'] as String;

      if (e['home_score_after'] != null) homeScore = e['home_score_after'] as int;
      if (e['away_score_after'] != null) awayScore = e['away_score_after'] as int;

      items.add(RecordingEventItem(
        id: id,
        clientEventId: clientEventId,
        eventType: eventType,
        createdAt: createdAt,
        teamSide: teamSide,
        quarter: quarter,
        gameTime: gameTime,
        playerId: playerId,
        value: e['value'] as int?,
      ));
    }

    if (rawEvents.isNotEmpty) {
      final last = rawEvents.last as Map<String, dynamic>;
      if (last['home_score'] != null) homeScore = last['home_score'] as int;
      if (last['away_score'] != null) awayScore = last['away_score'] as int;
    }

    state = state.copyWith(
      events: items.reversed.toList(),
      homeScore: homeScore,
      awayScore: awayScore,
      homeTeamName: homeTeamName,
      awayTeamName: awayTeamName,
      matchStatus: matchStatus,
      homeTeamFouls: homeTeamFouls,
      awayTeamFouls: awayTeamFouls,
    );

    // 진행 중이면 게임 타이머 재개
    if (matchStatus == 'in_progress') {
      _startGameTimer();
    }
  }

  // §1.2 경기 시작
  Future<void> startMatch() async {
    if (state.matchStatus != 'scheduled') return;
    state = state.copyWith(isLoading: true, clearError: true);

    final apiClient = ref.read(apiClientProvider);
    final result = await apiClient.updateMatchStatus(matchId, 'in_progress');

    if (result.isSuccess) {
      _startGameTimer();
      state = state.copyWith(matchStatus: 'in_progress', isLoading: false);
    } else {
      state = state.copyWith(isLoading: false, errorMessage: '경기 시작에 실패했습니다.');
    }
  }

  // §1.2 경기 종료
  Future<void> endMatch() async {
    if (state.matchStatus != 'in_progress') return;
    state = state.copyWith(isLoading: true, clearError: true);

    await _flushQueue();
    _stopGameTimer();
    _stopShotClock();

    final apiClient = ref.read(apiClientProvider);
    final isOnline = ref.read(isOnlineProvider);

    if (!isOnline) {
      // 오프라인: 로컬 상태만 변경, 복구 시 서버에 반영
      state = state.copyWith(
        matchStatus: 'completed',
        isLoading: false,
        pendingStatusChange: 'completed',
        errorMessage: '오프라인 상태입니다. 네트워크 복구 시 자동으로 경기 종료가 반영됩니다.',
      );
      return;
    }

    final result = await apiClient.updateMatchStatus(matchId, 'completed');
    if (result.isSuccess) {
      state = state.copyWith(matchStatus: 'completed', isLoading: false);
    } else {
      // API 실패 시에도 로컬 상태 변경 + 재시도 예약
      state = state.copyWith(
        matchStatus: 'completed',
        isLoading: false,
        pendingStatusChange: 'completed',
        errorMessage: '경기 종료 처리 중 오류가 발생했습니다. 자동으로 재시도합니다.',
      );
    }
  }

  /// 이벤트 기록
  Future<void> recordEvent(
    String eventType, {
    required String teamSide,
    int? value,
    int? playerId,
    String? playerName,
    // 교체 이벤트용
    int? outPlayerId,
    String? outPlayerName,
  }) async {
    // 파울/교체/타임아웃/슛실패/팀리바운드는 샷클락 없이도 기록 가능
    final needsShotClock = !shotClockExemptTypes.contains(eventType) &&
        !shotMissTypes.contains(eventType) &&
        eventType != 'rebound_team';
    if (needsShotClock && !state.canRecord) return;
    if (!needsShotClock && !state.canRecordAlways) return;

    final clientEventId = _uuid.v4();
    final apiClient = ref.read(apiClientProvider);
    final isOnline = ref.read(isOnlineProvider);

    final teamId = teamSide == 'home' ? state.homeTeamId : state.awayTeamId;
    final gameTime = _formatElapsed(state.elapsedSeconds);

    final eventData = <String, dynamic>{
      'event_type': eventType,
      'client_event_id': clientEventId,
      'team_id': teamId,
      'quarter': state.currentQuarter,
      'game_time': gameTime,
      if (value != null) 'value': value,
      if (playerId != null) 'player_id': playerId,
      if (outPlayerId != null) 'out_player_id': outPlayerId,
    };

    // 낙관적 점수 업데이트 (0 이하 방지)
    int newHome = state.homeScore;
    int newAway = state.awayScore;
    if (value != null && value > 0) {
      if (teamSide == 'home') newHome += value;
      if (teamSide == 'away') newAway += value;
    }

    // §1.5 파울 집계
    int newHomeFouls = state.homeTeamFouls;
    int newAwayFouls = state.awayTeamFouls;
    final isFoulEvent = eventType == 'foul_personal' ||
        eventType == 'foul_technical' ||
        eventType == 'foul_unsportsmanlike' ||
        eventType == 'foul_offensive';
    if (isFoulEvent) {
      if (teamSide == 'home') newHomeFouls++;
      if (teamSide == 'away') newAwayFouls++;
    }

    // 선수별 파울 카운트 업데이트
    Map<int, int>? newPlayerFouls;
    Map<int, int>? newPlayerTUFouls;
    int? ejectedPlayer;
    if (isFoulEvent && playerId != null) {
      newPlayerFouls = Map<int, int>.from(state.playerFoulCounts);
      newPlayerFouls[playerId] = (newPlayerFouls[playerId] ?? 0) + 1;

      // T+U 파울 합산 (2개 이상 → 퇴장)
      if (techUnsportFoulTypes.contains(eventType)) {
        newPlayerTUFouls = Map<int, int>.from(state.playerTechUnsportFouls);
        newPlayerTUFouls[playerId] = (newPlayerTUFouls[playerId] ?? 0) + 1;
        if (newPlayerTUFouls[playerId]! >= 2) {
          ejectedPlayer = playerId;
        }
      }
    }

    // §2.1 점수 이벤트 후 샷클락 24초 리셋
    if (value != null && value > 0) {
      _resetShotClock(24, restart: true);
    }
    // 오펜시브 리바운드 → 14초
    if (eventType == 'rebound_off') {
      _resetShotClock(14, restart: state.isShotClockRunning);
    }

    final optimisticItem = RecordingEventItem(
      id: 0,
      clientEventId: clientEventId,
      eventType: eventType,
      createdAt: DateTime.now(),
      teamSide: teamSide,
      quarter: state.currentQuarter,
      gameTime: gameTime,
      playerId: playerId,
      playerName: playerName,
      value: value,
      isPending: !isOnline,
    );

    state = state.copyWith(
      events: [optimisticItem, ...state.events],
      homeScore: newHome,
      awayScore: newAway,
      homeTeamFouls: newHomeFouls,
      awayTeamFouls: newAwayFouls,
      playerFoulCounts: newPlayerFouls,
      playerTechUnsportFouls: newPlayerTUFouls,
      ejectedPlayerId: ejectedPlayer,
    );

    if (!isOnline) {
      final pending = PendingEvent(
        clientEventId: clientEventId,
        matchId: matchId,
        data: eventData,
        createdAt: DateTime.now(),
      );
      await _queue.enqueue(pending);
      state = state.copyWith(pendingCount: _queue.length);
      return;
    }

    final result = await apiClient.postEvent(matchId, eventData);
    if (result.isSuccess) {
      final serverData = result.data!;
      final serverId = serverData['id'] as int? ?? 0;
      final sHome = serverData['home_score'] as int? ?? newHome;
      final sAway = serverData['away_score'] as int? ?? newAway;

      final updatedEvents = state.events.map((e) {
        if (e.clientEventId == clientEventId) {
          return RecordingEventItem(
            id: serverId,
            clientEventId: clientEventId,
            eventType: eventType,
            createdAt: e.createdAt,
            teamSide: teamSide,
            quarter: e.quarter,
            gameTime: e.gameTime,
            playerId: e.playerId,
            playerName: e.playerName,
            value: e.value,
            isPending: false,
          );
        }
        return e;
      }).toList();

      state = state.copyWith(
        events: updatedEvents,
        homeScore: sHome,
        awayScore: sAway,
      );
    } else {
      final pending = PendingEvent(
        clientEventId: clientEventId,
        matchId: matchId,
        data: eventData,
        createdAt: DateTime.now(),
      );
      await _queue.enqueue(pending);

      final updatedEvents = state.events.map((e) {
        if (e.clientEventId == clientEventId) {
          return RecordingEventItem(
            id: 0,
            clientEventId: clientEventId,
            eventType: eventType,
            createdAt: e.createdAt,
            teamSide: teamSide,
            quarter: e.quarter,
            gameTime: e.gameTime,
            playerId: e.playerId,
            playerName: e.playerName,
            value: e.value,
            isPending: true,
          );
        }
        return e;
      }).toList();

      state = state.copyWith(
        events: updatedEvents,
        pendingCount: _queue.length,
        errorMessage: '이벤트가 임시 저장됩니다. 네트워크 복구 시 자동 전송됩니다.',
      );
    }
  }

  // §1.4 선수 교체 (샷클락 없이도 기록 가능)
  Future<void> recordSubstitution({
    required String teamSide,
    required int outPlayerId,
    required String outPlayerName,
    required int inPlayerId,
    required String inPlayerName,
  }) async {
    if (!state.canRecordAlways) return;

    // 스타터 목록 로컬 업데이트 (out → in)
    final isHome = teamSide == 'home';
    final players = isHome
        ? List<Map<String, dynamic>>.from(state.homePlayers)
        : List<Map<String, dynamic>>.from(state.awayPlayers);

    for (final p in players) {
      if (p['id'] == outPlayerId) p['is_starter'] = false;
      if (p['id'] == inPlayerId) p['is_starter'] = true;
    }

    state = state.copyWith(
      homePlayers: isHome ? players : state.homePlayers,
      awayPlayers: isHome ? state.awayPlayers : players,
    );

    await recordEvent(
      'sub',
      teamSide: teamSide,
      playerId: inPlayerId,
      playerName: inPlayerName,
      outPlayerId: outPlayerId,
      outPlayerName: outPlayerName,
    );
  }

  /// Undo 마지막 이벤트
  Future<void> undoLastEvent() async {
    if (state.events.isEmpty) return;
    final last = state.events.first;

    if (last.isPending) {
      await _queue.removeByClientEventId(last.clientEventId);
      final updatedEvents =
          state.events.where((e) => e.clientEventId != last.clientEventId).toList();

      int newHome = state.homeScore;
      int newAway = state.awayScore;
      if (last.value != null) {
        if (last.teamSide == 'home') newHome = (newHome - last.value!).clamp(0, 9999);
        if (last.teamSide == 'away') newAway = (newAway - last.value!).clamp(0, 9999);
      }

      // 파울 되돌리기
      int newHomeFouls = state.homeTeamFouls;
      int newAwayFouls = state.awayTeamFouls;
      if (last.eventType == 'foul_personal' || last.eventType == 'foul_technical' ||
          last.eventType == 'foul_unsportsmanlike' || last.eventType == 'foul_offensive') {
        if (last.teamSide == 'home') newHomeFouls = (newHomeFouls - 1).clamp(0, 99);
        if (last.teamSide == 'away') newAwayFouls = (newAwayFouls - 1).clamp(0, 99);
      }

      state = state.copyWith(
        events: updatedEvents,
        homeScore: newHome,
        awayScore: newAway,
        homeTeamFouls: newHomeFouls,
        awayTeamFouls: newAwayFouls,
        pendingCount: _queue.length,
      );
      return;
    }

    if (last.id <= 0) return;
    final apiClient = ref.read(apiClientProvider);
    final result = await apiClient.undoEvent(matchId, last.id);

    if (result.isSuccess) {
      state = state.copyWith(
        events: state.events.where((e) => e.id != last.id).toList(),
      );
      await _loadEvents();
    } else {
      // 서버 Undo 실패 시 로컬에서라도 이벤트 제거 + 점수 보정
      int newHome = state.homeScore;
      int newAway = state.awayScore;
      if (last.value != null) {
        if (last.teamSide == 'home') newHome = (newHome - last.value!).clamp(0, 9999);
        if (last.teamSide == 'away') newAway = (newAway - last.value!).clamp(0, 9999);
      }
      state = state.copyWith(
        events: state.events.where((e) => e.id != last.id).toList(),
        homeScore: newHome,
        awayScore: newAway,
        errorMessage: '이벤트 취소가 서버에 반영되지 않았습니다. 네트워크를 확인해주세요.',
      );
    }
  }

  void setQuarter(int quarter) {
    // 쿼터 변경 시 팀 파울 초기화
    state = state.copyWith(
      currentQuarter: quarter,
      homeTeamFouls: 0,
      awayTeamFouls: 0,
    );
  }

  // §2.2 타임아웃 (샷클락 없이도 기록 가능)
  Future<void> recordTimeout(String teamSide) async {
    if (!state.canRecordAlways) return;
    final isHome = teamSide == 'home';

    final remaining = isHome ? state.homeTimeouts : state.awayTimeouts;
    if (remaining <= 0) {
      state = state.copyWith(errorMessage: '타임아웃이 남아있지 않습니다.');
      return;
    }

    _stopShotClock();

    state = state.copyWith(
      homeTimeouts: isHome ? remaining - 1 : state.homeTimeouts,
      awayTimeouts: isHome ? state.awayTimeouts : remaining - 1,
    );

    await recordEvent('timeout', teamSide: teamSide);
  }

  // §2.1 샷 클락 제어
  void startShotClock() {
    if (state.matchStatus != 'in_progress') return;
    _shotClockTimer?.cancel();
    _shotClockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.shotClockSeconds <= 0) {
        _shotClockTimer?.cancel();
        state = state.copyWith(isShotClockRunning: false, shotClockSeconds: 0);
        HapticFeedback.heavyImpact();
        return;
      }
      state = state.copyWith(shotClockSeconds: state.shotClockSeconds - 1);
    });
    state = state.copyWith(isShotClockRunning: true);
  }

  void stopShotClock() => _stopShotClock();

  void _stopShotClock() {
    _shotClockTimer?.cancel();
    state = state.copyWith(isShotClockRunning: false);
  }

  void resetShotClock24() => _resetShotClock(24, restart: false);
  void resetShotClock14() => _resetShotClock(14, restart: false);

  void _resetShotClock(int seconds, {required bool restart}) {
    _shotClockTimer?.cancel();
    state = state.copyWith(shotClockSeconds: seconds, isShotClockRunning: false);
    if (restart) startShotClock();
  }

  // 게임 타이머 (DateTime 기반 — tick 누락 방지)
  void _startGameTimer() {
    _gameTimer?.cancel();
    _gameTimerStartedAt = DateTime.now();
    _elapsedBeforePause = state.elapsedSeconds;
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      final elapsed = _elapsedBeforePause + now.difference(_gameTimerStartedAt!).inSeconds;
      state = state.copyWith(elapsedSeconds: elapsed);
    });
    state = state.copyWith(isTimerRunning: true);
  }

  void _stopGameTimer() {
    _gameTimer?.cancel();
    if (_gameTimerStartedAt != null) {
      _elapsedBeforePause = state.elapsedSeconds;
    }
    _gameTimerStartedAt = null;
    state = state.copyWith(isTimerRunning: false);
  }

  // §1.3 오프라인 큐 플러시 (네트워크 복구 시 자동 호출)
  Future<void> flushQueue({int retryCount = 0}) async {
    // 큐를 다시 로드하여 최신 상태 보장
    await _queue.load();
    if (_queue.isEmpty) {
      state = state.copyWith(pendingCount: 0, isSyncing: false);
      return;
    }
    state = state.copyWith(isSyncing: true, clearError: true);

    await _flushQueueInternal(retryCount: retryCount);
    state = state.copyWith(isSyncing: false, pendingCount: _queue.length);
  }

  Future<void> _flushQueue() async => _flushQueueInternal();

  Future<void> _flushQueueInternal({int retryCount = 0}) async {
    final pending = await _queue.dequeueByMatch(matchId);
    if (pending.isEmpty) return;

    final apiClient = ref.read(apiClientProvider);
    final events = pending
        .map((e) => {...e.data, 'client_event_id': e.clientEventId})
        .toList();

    final result = await apiClient.batchFlushEvents(matchId, events);
    if (result.isSuccess) {
      final updatedEvents = state.events.map((e) {
        if (e.isPending) {
          return RecordingEventItem(
            id: e.id,
            clientEventId: e.clientEventId,
            eventType: e.eventType,
            createdAt: e.createdAt,
            teamSide: e.teamSide,
            quarter: e.quarter,
            gameTime: e.gameTime,
            playerId: e.playerId,
            playerName: e.playerName,
            value: e.value,
            isPending: false,
          );
        }
        return e;
      }).toList();
      state = state.copyWith(events: updatedEvents, pendingCount: _queue.length);
      await _loadEvents();
    } else {
      // §1.3 지수 백오프 재시도 (최대 3회)
      if (retryCount < 3) {
        final delay = Duration(seconds: (1 << retryCount) * 2);
        await Future.delayed(delay);

        await _queue.requeueAll(pending);
        await _flushQueueInternal(retryCount: retryCount + 1);
      } else {
        await _queue.requeueAll(pending);
        state = state.copyWith(
          pendingCount: _queue.length,
          errorMessage: '임시 저장된 이벤트 전송에 실패했습니다. 잠시 후 다시 시도해 주세요.',
        );
      }
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
  void clearEjection() => state = state.copyWith(clearEjected: true);

  /// 선발/후보 토글 (로컬 상태만 변경 — 라인업 정렬용)
  void togglePlayerStarter(String teamSide, int playerId) {
    final isHome = teamSide == 'home';
    final players = isHome
        ? List<Map<String, dynamic>>.from(state.homePlayers)
        : List<Map<String, dynamic>>.from(state.awayPlayers);

    for (final p in players) {
      if (p['id'] == playerId) {
        p['is_starter'] = !(p['is_starter'] as bool? ?? false);
        break;
      }
    }

    state = state.copyWith(
      homePlayers: isHome ? players : state.homePlayers,
      awayPlayers: isHome ? state.awayPlayers : players,
    );
  }

  static String _formatElapsed(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final recordingProvider = StateNotifierProvider.autoDispose.family<RecordingNotifier,
    RecordingState, MatchRecordingArgs>((ref, args) {
  return RecordingNotifier(
    matchId: args.matchId,
    tournamentId: args.tournamentId,
    ref: ref,
    homeTeamId: args.homeTeamId,
    awayTeamId: args.awayTeamId,
    homeTeamName: args.homeTeamName,
    awayTeamName: args.awayTeamName,
  );
});
