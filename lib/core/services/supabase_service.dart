import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase 직접 연결 서비스
///
/// 아키텍처:
/// - Reads  : Supabase (tournaments, teams, players, matches, stats)
/// - Writes : mybdr REST API (events, score updates, status changes)
/// - Auth   : mybdr REST API (login/JWT) — Supabase anon key만 사용
/// - Realtime: Supabase native subscriptions (match_events 실시간 구독)
class SupabaseService {
  static final SupabaseService instance = SupabaseService._();
  SupabaseService._();

  static const _supabaseUrl = 'https://ykzpqpxydhbjpsiyqwfp.supabase.co';
  static const _supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
      '.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlrenBxcHh5ZGhianBzaXlxd2ZwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE1MzE1OTcsImV4cCI6MjA4NzEwNzU5N30'
      '.KVqfkHHXCGzUA8h3wRkN-OK45p8KrhbxzZBuNoXvtsI';

  SupabaseClient get _client => Supabase.instance.client;

  // ────────────────────────────────────────────
  // 초기화
  // ────────────────────────────────────────────

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        autoRefreshToken: false, // mybdr JWT 사용, Supabase 인증 불필요
      ),
    );
    debugPrint('[Supabase] initialized');
  }

  // ────────────────────────────────────────────
  // 대회(Tournament) 조회
  // ────────────────────────────────────────────

  /// 활성 대회 목록 (status가 registration/in_progress인 것)
  Future<List<Map<String, dynamic>>> fetchActiveTournaments() async {
    final res = await _client
        .from('tournaments')
        .select('''
          id, name, description, logo_url, banner_url,
          start_date, end_date, status, sport_type,
          max_teams, registration_end_at
        ''')
        .inFilter('status', ['registration', 'in_progress', 'active'])
        .order('start_date', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  /// 특정 대회 상세
  Future<Map<String, dynamic>?> fetchTournament(String tournamentId) async {
    final res = await _client
        .from('tournaments')
        .select()
        .eq('id', tournamentId)
        .maybeSingle();
    return res;
  }

  // ────────────────────────────────────────────
  // 팀(Team) 조회
  // ────────────────────────────────────────────

  /// 대회 참가 팀 목록 (teams 조인)
  Future<List<Map<String, dynamic>>> fetchTournamentTeams(
      String tournamentId) async {
    final res = await _client
        .from('tournament_teams')
        .select('''
          id, team_id, status, seed_number, group_name,
          wins, losses, draws, points_for, points_against, final_rank,
          teams!inner(id, name, logo_url, primary_color, secondary_color)
        ''')
        .eq('tournament_id', tournamentId)
        .eq('status', 'approved')
        .order('seed_number');
    return List<Map<String, dynamic>>.from(res);
  }

  // ────────────────────────────────────────────
  // 선수(Player) 조회 — SECURITY DEFINER RPC 사용
  // ────────────────────────────────────────────

  /// 대회 전체 선수 목록 (display_name 포함, users RLS 우회)
  ///
  // ⚠️ SECURITY NOTE: Supabase RLS가 tournament_team_players 테이블에
  // 올바르게 설정되어 있어야 합니다. RLS 미설정 시 다른 대회 데이터 노출 위험.
  // 프로덕션 배포 전 반드시 확인:
  //   - SELECT 정책: auth.uid() 기반 또는 tournament_id 기반 제한
  //   - RPC 함수(get_tournament_players)는 SECURITY DEFINER로 실행되므로
  //     함수 내부에서 tournament_id 필터링이 반드시 적용되어야 함.
  Future<List<Map<String, dynamic>>> fetchTournamentPlayers(
      String tournamentId) async {
    final res = await _client.rpc(
      'get_tournament_players',
      params: {'p_tournament_id': tournamentId},
    );
    return List<Map<String, dynamic>>.from(res as List);
  }

  // ────────────────────────────────────────────
  // 경기(Match) 조회
  // ────────────────────────────────────────────

  /// 대회 경기 일정 전체
  Future<List<Map<String, dynamic>>> fetchTournamentMatches(
      String tournamentId) async {
    final res = await _client
        .from('tournament_matches')
        .select('''
          id, uuid, home_team_id, away_team_id,
          round_name, round_number, match_number, group_name,
          scheduled_at, started_at, ended_at,
          home_score, away_score, quarter_scores, status,
          winner_team_id, venue_name, court_number
        ''')
        .eq('tournament_id', tournamentId)
        .order('scheduled_at');
    return List<Map<String, dynamic>>.from(res);
  }

  /// 단일 경기 상세 (bigint ID)
  Future<Map<String, dynamic>?> fetchMatch(int matchId) async {
    final res = await _client
        .from('tournament_matches')
        .select()
        .eq('id', matchId)
        .maybeSingle();
    return res;
  }

  // ────────────────────────────────────────────
  // 경기 이벤트(Match Events) 조회
  // ────────────────────────────────────────────

  /// 특정 경기의 이벤트 스트림
  Future<List<Map<String, dynamic>>> fetchMatchEvents(int matchId) async {
    final res = await _client
        .from('match_events')
        .select()
        .eq('tournament_match_id', matchId)
        .order('event_time');
    return List<Map<String, dynamic>>.from(res);
  }

  // ────────────────────────────────────────────
  // 선수 스탯 조회
  // ────────────────────────────────────────────

  /// 경기 박스스코어 (match_player_stats)
  Future<List<Map<String, dynamic>>> fetchMatchPlayerStats(
      int matchId) async {
    final res = await _client
        .from('match_player_stats')
        .select()
        .eq('tournament_match_id', matchId);
    return List<Map<String, dynamic>>.from(res);
  }

  // ────────────────────────────────────────────
  // Realtime 구독
  // ────────────────────────────────────────────

  /// 대회 팀 로스터 변경 실시간 구독 (tournament_team_players)
  ///
  /// 경기 직전 웹에서 선수 추가/비활성화 시 앱에 즉시 반영
  RealtimeChannel subscribeToRoster({
    required String tournamentId,
    required void Function() onChanged,
  }) {
    // tournament_team_players는 tournament_team_id를 통해 tournament_id와 연결
    // 필터를 tournament_teams로 직접 걸 수 없으므로 전체 insert/update 구독 후
    // 앱에서 provider invalidate로 처리 (변경 빈도가 낮아서 충분함)
    final channel = _client
        .channel('roster_$tournamentId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'tournament_team_players',
          callback: (_) => onChanged(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'tournament_team_players',
          callback: (_) => onChanged(),
        )
        .subscribe();
    return channel;
  }

  /// match_player_stats 실시간 구독 (박스스코어 실시간 갱신용)
  ///
  /// 경기 중 다른 기기/시스템에서 스탯 업데이트 시 앱에 반영
  RealtimeChannel subscribeToPlayerStats({
    required int matchId,
    required void Function(Map<String, dynamic> updatedStat) onUpdate,
  }) {
    final channel = _client
        .channel('player_stats_$matchId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'match_player_stats',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'tournament_match_id',
            value: matchId,
          ),
          callback: (payload) => onUpdate(payload.newRecord),
        )
        .subscribe();
    return channel;
  }

  /// 경기 점수 변경 실시간 구독 (tournament_matches)
  RealtimeChannel subscribeToMatchScore({
    required int matchId,
    required void Function(Map<String, dynamic> payload) onUpdate,
  }) {
    final channel = _client
        .channel('match_score_$matchId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'tournament_matches',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: matchId,
          ),
          callback: (payload) => onUpdate(payload.newRecord),
        )
        .subscribe();
    return channel;
  }

  /// 경기 이벤트 스트림 실시간 구독 (match_events)
  RealtimeChannel subscribeToMatchEvents({
    required int matchId,
    required void Function(Map<String, dynamic> newEvent) onInsert,
    required void Function(Map<String, dynamic> cancelledEvent) onUpdate,
  }) {
    final channel = _client
        .channel('match_events_$matchId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'match_events',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'tournament_match_id',
            value: matchId,
          ),
          callback: (payload) => onInsert(payload.newRecord),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'match_events',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'tournament_match_id',
            value: matchId,
          ),
          callback: (payload) => onUpdate(payload.newRecord),
        )
        .subscribe();
    return channel;
  }

  /// 구독 해제
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await _client.removeChannel(channel);
  }

  /// 모든 구독 해제 (앱 종료 또는 로그아웃 시)
  Future<void> unsubscribeAll() async {
    await _client.removeAllChannels();
  }
}
