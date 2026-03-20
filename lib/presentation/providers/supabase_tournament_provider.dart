import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/supabase_service.dart';
import '../../di/providers.dart';

// ────────────────────────────────────────────────────────────────
// 대회 데이터 캐시 (Supabase 직접 조회 결과)
// ────────────────────────────────────────────────────────────────

/// 활성 대회 목록 (Supabase)
final supabaseTournamentsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return SupabaseService.instance.fetchActiveTournaments();
});

/// 대회 참가팀 목록 (Supabase) — tournamentId(UUID)별 캐시
final supabaseTeamsProvider = FutureProvider.family<
    List<Map<String, dynamic>>, String>((ref, tournamentId) async {
  return SupabaseService.instance.fetchTournamentTeams(tournamentId);
});

/// 대회 선수 목록 (Supabase, display_name 포함) — tournamentId별 캐시
final supabasePlayersProvider = FutureProvider.family<
    List<Map<String, dynamic>>, String>((ref, tournamentId) async {
  return SupabaseService.instance.fetchTournamentPlayers(tournamentId);
});

/// 대회 경기 일정 (Supabase) — tournamentId별 캐시
final supabaseMatchesProvider = FutureProvider.family<
    List<Map<String, dynamic>>, String>((ref, tournamentId) async {
  return SupabaseService.instance.fetchTournamentMatches(tournamentId);
});

/// 단일 경기 상세 (Supabase) — matchId(bigint)별 캐시
final supabaseMatchProvider =
    FutureProvider.family<Map<String, dynamic>?, int>((ref, matchId) async {
  return SupabaseService.instance.fetchMatch(matchId);
});

// ────────────────────────────────────────────────────────────────
// 대회별 전체 데이터 한번에 Pre-fetch
// ────────────────────────────────────────────────────────────────

class TournamentPrefetchState {
  const TournamentPrefetchState({
    this.isLoading = false,
    this.lastFetchedAt,
    this.fetchedTournamentIds = const [],
    this.error,
  });

  final bool isLoading;
  final DateTime? lastFetchedAt;
  final List<String> fetchedTournamentIds;
  final String? error;

  bool get hasFetched => lastFetchedAt != null;

  TournamentPrefetchState copyWith({
    bool? isLoading,
    DateTime? lastFetchedAt,
    List<String>? fetchedTournamentIds,
    String? error,
  }) =>
      TournamentPrefetchState(
        isLoading: isLoading ?? this.isLoading,
        lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
        fetchedTournamentIds:
            fetchedTournamentIds ?? this.fetchedTournamentIds,
        error: error,
      );
}

class TournamentPrefetchNotifier
    extends StateNotifier<TournamentPrefetchState> {
  TournamentPrefetchNotifier(this._ref)
      : super(const TournamentPrefetchState());

  final Ref _ref;

  /// 로그인 후 내 담당 대회만 pre-fetch
  ///
  /// 흐름: mybdr API → 내 배정 경기 목록 → tournamentId 추출 → Supabase fetch
  /// 이유: 동시간대 여러 대회가 열려도 각 관계자는 자신의 담당 대회 데이터만 받음
  Future<void> prefetchAll() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 1. mybdr API: 내 배정 경기 목록 (JWT 인증 포함)
      final apiClient = _ref.read(apiClientProvider);
      final result = await apiClient.getRecorderMatches();

      if (!result.isSuccess || result.data == null) {
        debugPrint('[Supabase] Pre-fetch skipped: ${result.error}');
        state = state.copyWith(isLoading: false);
        return;
      }

      // 2. 담당 경기에서 고유 tournamentId(UUID) 추출
      final matches = result.data!;
      final ids = matches
          .map((m) => (m as Map<String, dynamic>)['tournament_id'] as String?)
          .whereType<String>()
          .toSet()
          .toList();

      if (ids.isEmpty) {
        debugPrint('[Supabase] Pre-fetch: no assigned tournaments');
        state = state.copyWith(isLoading: false, lastFetchedAt: DateTime.now());
        return;
      }

      debugPrint('[Supabase] Pre-fetch: ${ids.length} assigned tournaments');

      // 3. 담당 대회만 Supabase에서 병렬 로드
      await Future.wait(
        ids.map((id) => _prefetchTournament(id)),
        eagerError: false, // 일부 실패해도 나머지는 계속
      );

      state = state.copyWith(
        isLoading: false,
        lastFetchedAt: DateTime.now(),
        fetchedTournamentIds: ids,
      );
      debugPrint('[Supabase] Pre-fetch complete: ${ids.length} tournaments');
    } catch (e) {
      debugPrint('[Supabase] Pre-fetch error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _prefetchTournament(String tournamentId) async {
    // 프로바이더 캐시를 워밍업 (결과는 자동으로 Riverpod 캐시에 저장)
    await Future.wait([
      _ref.read(supabaseTeamsProvider(tournamentId).future),
      _ref.read(supabasePlayersProvider(tournamentId).future),
      _ref.read(supabaseMatchesProvider(tournamentId).future),
    ]);
    debugPrint('[Supabase] Pre-fetched tournament: $tournamentId');
  }

  /// 특정 대회만 새로고침
  Future<void> refreshTournament(String tournamentId) async {
    _ref.invalidate(supabaseTeamsProvider(tournamentId));
    _ref.invalidate(supabasePlayersProvider(tournamentId));
    _ref.invalidate(supabaseMatchesProvider(tournamentId));
    await _prefetchTournament(tournamentId);
  }

  /// 대회 로스터 Realtime 구독 시작 (경기 화면 진입 시 호출)
  ///
  /// 웹 어드민에서 선수 추가/수정 → 앱 자동 반영
  void watchRoster(String tournamentId) {
    SupabaseService.instance.subscribeToRoster(
      tournamentId: tournamentId,
      onChanged: () {
        // 선수 목록 캐시 무효화 → 자동 re-fetch
        _ref.invalidate(supabasePlayersProvider(tournamentId));
        debugPrint('[Supabase] Roster changed → re-fetching players');
      },
    );
  }
}

final tournamentPrefetchProvider =
    StateNotifierProvider<TournamentPrefetchNotifier, TournamentPrefetchState>(
  (ref) => TournamentPrefetchNotifier(ref),
);
