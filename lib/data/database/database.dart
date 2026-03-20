import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables.dart';
import 'daos/tournament_dao.dart';
import 'daos/match_dao.dart';
import 'daos/player_stats_dao.dart';
import 'daos/play_by_play_dao.dart';
import 'daos/edit_log_dao.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    LocalTournaments,
    LocalTournamentTeams,
    LocalTournamentPlayers,
    LocalMatches,
    LocalPlayerStats,
    LocalPlayByPlays,
    RecentTournaments,
    LocalEditLogs,
  ],
  daos: [
    TournamentDao,
    MatchDao,
    PlayerStatsDao,
    PlayByPlayDao,
    EditLogDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // 테스트용 생성자
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        beforeOpen: (details) async {
          // 외래 키 제약 활성화
          await customStatement('PRAGMA foreign_keys = ON');
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // v4 → v5: T/U 파울 컬럼 추가
          if (from < 5) {
            await customStatement(
              'ALTER TABLE local_player_stats ADD COLUMN technical_fouls INTEGER NOT NULL DEFAULT 0',
            );
            await customStatement(
              'ALTER TABLE local_player_stats ADD COLUMN unsportsmanlike_fouls INTEGER NOT NULL DEFAULT 0',
            );
          }

          // v3 → v4: 액션 연동을 위한 linkedActionId 컬럼 추가
          if (from < 4) {
            await customStatement(
              'ALTER TABLE local_play_by_plays ADD COLUMN linked_action_id TEXT',
            );
          }

          // v2 → v3: 수정 이력 테이블 추가
          if (from < 3) {
            await m.createTable(localEditLogs);
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_edit_log_match ON local_edit_logs(local_match_id)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_edit_log_time ON local_edit_logs(edited_at)',
            );
          }

          // v1 → v2: 인덱스 추가 (성능 최적화)
          if (from < 2) {
            // LocalMatches 인덱스
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_match_tournament ON local_matches(tournament_id)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_match_status ON local_matches(status)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_match_sync ON local_matches(is_synced)',
            );

            // LocalPlayerStats 인덱스
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_player_stats_match ON local_player_stats(local_match_id)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_player_stats_player ON local_player_stats(tournament_team_player_id)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_player_stats_match_team ON local_player_stats(local_match_id, tournament_team_id)',
            );

            // LocalPlayByPlays 인덱스 (핵심!)
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_pbp_match ON local_play_by_plays(local_match_id)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_pbp_quarter ON local_play_by_plays(local_match_id, quarter)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_pbp_timeline ON local_play_by_plays(local_match_id, quarter, game_clock_seconds)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_pbp_player ON local_play_by_plays(tournament_team_player_id)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_pbp_action ON local_play_by_plays(local_match_id, action_type)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_pbp_sync ON local_play_by_plays(is_synced)',
            );
          }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'bdr_tournament.db'));
    return NativeDatabase.createInBackground(file);
  });
}
