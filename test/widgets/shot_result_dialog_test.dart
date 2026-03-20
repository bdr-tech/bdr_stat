import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bdr_tournament_recorder/presentation/widgets/dialogs/shot_result_dialog.dart';
import 'package:bdr_tournament_recorder/data/database/database.dart';

/// Helper to create a test app with GoRouter
Widget createTestApp(Widget child) {
  final router = GoRouter(
    initialLocation: '/test',
    routes: [
      GoRoute(
        path: '/test',
        builder: (context, state) => Scaffold(body: child),
      ),
    ],
  );

  return ProviderScope(
    child: MaterialApp.router(
      routerConfig: router,
    ),
  );
}

void main() {
  group('ShotType enum', () {
    test('should have correct values', () {
      expect(ShotType.values.length, 3);
      expect(ShotType.twoPoint, isNotNull);
      expect(ShotType.threePoint, isNotNull);
      expect(ShotType.freeThrow, isNotNull);
    });
  });

  group('ShotResultDialog', () {
    late LocalTournamentPlayer mockPlayer;

    setUp(() {
      mockPlayer = LocalTournamentPlayer(
        id: 1,
        tournamentTeamId: 1,
        userName: 'Test Player',
        jerseyNumber: 23,
        position: 'G',
        role: 'player',
        isStarter: true,
        isActive: true,
        syncedAt: DateTime.now(),
      );
    });

    testWidgets('should display player name and shot type', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ShotResultDialog(
                player: mockPlayer,
                shotType: ShotType.twoPoint,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Test Player'), findsOneWidget);
      expect(find.text('2점슛'), findsOneWidget);
      expect(find.text('#23'), findsOneWidget);
    });

    testWidgets('should display 3점슛 for threePoint shot type', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ShotResultDialog(
                player: mockPlayer,
                shotType: ShotType.threePoint,
              ),
            ),
          ),
        ),
      );

      expect(find.text('3점슛'), findsOneWidget);
    });

    testWidgets('should display 자유투 for freeThrow shot type', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ShotResultDialog(
                player: mockPlayer,
                shotType: ShotType.freeThrow,
              ),
            ),
          ),
        ),
      );

      expect(find.text('자유투'), findsOneWidget);
    });

    testWidgets('should display zone name when provided', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ShotResultDialog(
                player: mockPlayer,
                shotType: ShotType.twoPoint,
                zoneName: '페인트 존',
              ),
            ),
          ),
        ),
      );

      expect(find.text('페인트 존'), findsOneWidget);
    });

    testWidgets('should have success and failure buttons', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ShotResultDialog(
                player: mockPlayer,
                shotType: ShotType.twoPoint,
              ),
            ),
          ),
        ),
      );

      expect(find.text('성공'), findsOneWidget);
      expect(find.text('실패'), findsOneWidget);
      expect(find.text('취소'), findsOneWidget);
    });

    // Note: Callback + navigation tests are covered by integration tests
    // since context.pop() requires a full navigation stack.
    // The callback is invoked before pop(), ensuring proper behavior.
  });

  group('showShotResultDialog helper', () {
    test('function should exist and be callable', () {
      // showShotResultDialog is a helper function that should exist
      expect(showShotResultDialog, isA<Function>());
    });
  });
}
