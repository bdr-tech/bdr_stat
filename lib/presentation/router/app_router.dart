import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/tournament/tournament_connect_screen.dart';
import '../screens/tournament/tournament_confirm_screen.dart';
import '../screens/tournament/tournament_list_screen.dart';
import '../screens/match/match_list_screen.dart';
import '../screens/match/starter_select_screen.dart';
import '../screens/recording/game_recording_screen.dart';
import '../screens/box_score/box_score_screen.dart';
import '../screens/shot_chart/shot_chart_screen.dart';
import '../screens/game_end/final_review_screen.dart';
import '../screens/game_end/mvp_select_screen.dart';
import '../screens/game_end/sync_result_screen.dart';
import '../screens/recording/play_by_play_edit_screen.dart';
import '../screens/analysis/game_analysis_screen.dart';
import '../screens/settings/data_management_screen.dart';
import '../screens/recorder/recorder_matches_screen.dart';
import '../screens/recorder/match_recording_screen.dart';

/// 라우터 프로바이더
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      // 스플래시
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // 로그인
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // 내 대회 목록
      GoRoute(
        path: '/tournaments',
        name: 'tournaments',
        builder: (context, state) => const TournamentListScreen(),
      ),

      // 대회 연결 (토큰 방식 - 하위 호환)
      GoRoute(
        path: '/connect',
        name: 'connect',
        builder: (context, state) => const TournamentConnectScreen(),
      ),

      // 대회 확인 및 데이터 다운로드
      GoRoute(
        path: '/confirm/:tournamentId',
        name: 'confirm',
        builder: (context, state) {
          final tournamentId = state.pathParameters['tournamentId']!;
          final token = state.extra as String?;
          return TournamentConfirmScreen(
            tournamentId: tournamentId,
            token: token ?? '',
          );
        },
      ),

      // 경기 목록
      GoRoute(
        path: '/matches',
        name: 'matches',
        builder: (context, state) => const MatchListScreen(),
      ),

      // 스타터 선택
      GoRoute(
        path: '/starter/:matchId',
        name: 'starter',
        builder: (context, state) {
          final matchId = int.parse(state.pathParameters['matchId']!);
          return StarterSelectScreen(matchId: matchId);
        },
      ),

      // 경기 기록
      GoRoute(
        path: '/recording/:matchId',
        name: 'recording',
        builder: (context, state) {
          final matchId = int.parse(state.pathParameters['matchId']!);
          return GameRecordingScreen(matchId: matchId);
        },
      ),

      // Play-by-Play 기록 수정
      GoRoute(
        path: '/play-edit/:matchId',
        name: 'playEdit',
        builder: (context, state) {
          final matchId = int.parse(state.pathParameters['matchId']!);
          final extra = state.extra as Map<String, dynamic>?;
          return PlayByPlayEditScreen(
            matchId: matchId,
            homeTeamId: extra?['homeTeamId'] ?? 0,
            awayTeamId: extra?['awayTeamId'] ?? 0,
            homeTeamName: extra?['homeTeamName'] ?? '',
            awayTeamName: extra?['awayTeamName'] ?? '',
          );
        },
      ),

      // 박스스코어
      GoRoute(
        path: '/box-score/:matchId',
        name: 'boxScore',
        builder: (context, state) {
          final matchId = int.parse(state.pathParameters['matchId']!);
          final extra = state.extra as Map<String, dynamic>?;
          return BoxScoreScreen(
            matchId: matchId,
            homeTeamName: extra?['homeTeamName'] ?? '',
            awayTeamName: extra?['awayTeamName'] ?? '',
            homeTeamId: extra?['homeTeamId'] ?? 0,
            awayTeamId: extra?['awayTeamId'] ?? 0,
            homeScore: extra?['homeScore'] ?? 0,
            awayScore: extra?['awayScore'] ?? 0,
            isLive: extra?['isLive'] ?? false,
          );
        },
      ),

      // 슛차트
      GoRoute(
        path: '/shot-chart/:matchId',
        name: 'shotChart',
        builder: (context, state) {
          final matchId = int.parse(state.pathParameters['matchId']!);
          final extra = state.extra as Map<String, dynamic>?;
          return ShotChartScreen(
            matchId: matchId,
            homeTeamId: extra?['homeTeamId'] ?? 0,
            awayTeamId: extra?['awayTeamId'] ?? 0,
            homeTeamName: extra?['homeTeamName'] ?? '',
            awayTeamName: extra?['awayTeamName'] ?? '',
          );
        },
      ),

      // 최종 검토
      GoRoute(
        path: '/final-review/:matchId',
        name: 'finalReview',
        builder: (context, state) {
          final matchId = int.parse(state.pathParameters['matchId']!);
          final extra = state.extra as Map<String, dynamic>?;
          return FinalReviewScreen(
            matchId: matchId,
            homeTeamId: extra?['homeTeamId'] ?? 0,
            awayTeamId: extra?['awayTeamId'] ?? 0,
            homeTeamName: extra?['homeTeamName'] ?? '',
            awayTeamName: extra?['awayTeamName'] ?? '',
            homeScore: extra?['homeScore'] ?? 0,
            awayScore: extra?['awayScore'] ?? 0,
          );
        },
      ),

      // MVP 선정
      GoRoute(
        path: '/mvp-select/:matchId',
        name: 'mvpSelect',
        builder: (context, state) {
          final matchId = int.parse(state.pathParameters['matchId']!);
          final extra = state.extra as Map<String, dynamic>?;
          return MvpSelectScreen(
            matchId: matchId,
            homeTeamId: extra?['homeTeamId'] ?? 0,
            awayTeamId: extra?['awayTeamId'] ?? 0,
            homeTeamName: extra?['homeTeamName'] ?? '',
            awayTeamName: extra?['awayTeamName'] ?? '',
            homeScore: extra?['homeScore'] ?? 0,
            awayScore: extra?['awayScore'] ?? 0,
          );
        },
      ),

      // 동기화 결과
      GoRoute(
        path: '/sync-result/:matchId',
        name: 'syncResult',
        builder: (context, state) {
          final matchId = int.parse(state.pathParameters['matchId']!);
          final extra = state.extra as Map<String, dynamic>?;
          return SyncResultScreen(
            matchId: matchId,
            homeTeamId: extra?['homeTeamId'] ?? 0,
            awayTeamId: extra?['awayTeamId'] ?? 0,
            homeTeamName: extra?['homeTeamName'] ?? '',
            awayTeamName: extra?['awayTeamName'] ?? '',
            homeScore: extra?['homeScore'] ?? 0,
            awayScore: extra?['awayScore'] ?? 0,
            mvpPlayerId: extra?['mvpPlayerId'],
          );
        },
      ),

      // 데이터 관리
      GoRoute(
        path: '/data-management',
        name: 'dataManagement',
        builder: (context, state) => const DataManagementScreen(),
      ),

      // 기록자 — 배정 경기 목록
      GoRoute(
        path: '/recorder/matches',
        name: 'recorderMatches',
        builder: (context, state) => const RecorderMatchesScreen(),
      ),

      // 기록자 — 경기 실시간 기록
      GoRoute(
        path: '/recorder/matches/:matchId/record',
        name: 'matchRecording',
        builder: (context, state) {
          final matchId = int.parse(state.pathParameters['matchId']!);
          final extra = state.extra as Map<String, dynamic>?;
          return MatchRecordingScreen(
            matchId: matchId,
            tournamentId: extra?['tournamentId'] as String? ?? '',
            homeTeamId: extra?['homeTeamId'] as int? ?? 0,
            awayTeamId: extra?['awayTeamId'] as int? ?? 0,
            homeTeamName: extra?['homeTeamName'] as String? ?? 'HOME',
            awayTeamName: extra?['awayTeamName'] as String? ?? 'AWAY',
          );
        },
      ),

      // 경기 분석
      GoRoute(
        path: '/analysis/:matchId',
        name: 'analysis',
        builder: (context, state) {
          final matchId = int.parse(state.pathParameters['matchId']!);
          final extra = state.extra as Map<String, dynamic>?;
          return GameAnalysisScreen(
            matchId: matchId,
            homeTeamId: extra?['homeTeamId'] ?? 0,
            awayTeamId: extra?['awayTeamId'] ?? 0,
            homeTeamName: extra?['homeTeamName'] ?? '',
            awayTeamName: extra?['awayTeamName'] ?? '',
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              '페이지를 찾을 수 없습니다',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(state.error?.message ?? ''),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('홈으로 이동'),
            ),
          ],
        ),
      ),
    ),
  );
});

/// 라우트 이름
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String tournaments = '/tournaments';
  static const String connect = '/connect';
  static const String confirm = '/confirm';
  static const String matches = '/matches';
  static const String starter = '/starter';
  static const String recording = '/recording';
  static const String playEdit = '/play-edit';
  static const String boxScore = '/box-score';
  static const String shotChart = '/shot-chart';
  static const String finalReview = '/final-review';
  static const String mvpSelect = '/mvp-select';
  static const String syncResult = '/sync-result';
  static const String analysis = '/analysis';
  static const String dataManagement = '/data-management';
  static const String recorderMatches = '/recorder/matches';
  static const String matchRecording = '/recorder/matches/:matchId/record';
}
