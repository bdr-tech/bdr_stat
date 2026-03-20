import 'package:drift/drift.dart';
import '../database.dart';
import '../tables.dart';

part 'edit_log_dao.g.dart';

@DriftAccessor(tables: [LocalEditLogs])
class EditLogDao extends DatabaseAccessor<AppDatabase>
    with _$EditLogDaoMixin {
  EditLogDao(super.db);

  // ═══════════════════════════════════════════════════════════════
  // Edit Log CRUD
  // ═══════════════════════════════════════════════════════════════

  /// 수정 이력 추가
  Future<int> insertLog(LocalEditLogsCompanion log) async {
    return into(localEditLogs).insert(log);
  }

  /// 경기별 수정 이력 조회
  Future<List<LocalEditLog>> getLogsByMatch(int matchId) async {
    return (select(localEditLogs)
          ..where((l) => l.localMatchId.equals(matchId))
          ..orderBy([(l) => OrderingTerm.desc(l.editedAt)]))
        .get();
  }

  /// 경기별 수정 이력 스트림
  Stream<List<LocalEditLog>> watchLogsByMatch(int matchId) {
    return (select(localEditLogs)
          ..where((l) => l.localMatchId.equals(matchId))
          ..orderBy([(l) => OrderingTerm.desc(l.editedAt)]))
        .watch();
  }

  /// 특정 대상의 수정 이력
  Future<List<LocalEditLog>> getLogsByTarget(
    int matchId,
    String targetType,
    int targetId,
  ) async {
    return (select(localEditLogs)
          ..where((l) =>
              l.localMatchId.equals(matchId) &
              l.targetType.equals(targetType) &
              l.targetId.equals(targetId))
          ..orderBy([(l) => OrderingTerm.desc(l.editedAt)]))
        .get();
  }

  /// 최근 N개 수정 이력
  Future<List<LocalEditLog>> getRecentLogs(int matchId, {int limit = 20}) async {
    return (select(localEditLogs)
          ..where((l) => l.localMatchId.equals(matchId))
          ..orderBy([(l) => OrderingTerm.desc(l.editedAt)])
          ..limit(limit))
        .get();
  }

  /// 수정 이력 삭제 (경기별)
  Future<void> deleteLogsByMatch(int matchId) async {
    await (delete(localEditLogs)
          ..where((l) => l.localMatchId.equals(matchId)))
        .go();
  }

  // ═══════════════════════════════════════════════════════════════
  // Helper Methods
  // ═══════════════════════════════════════════════════════════════

  /// Play-by-Play 생성 로그
  Future<void> logPlayCreated({
    required int matchId,
    required int playId,
    required String localId,
    required String description,
  }) async {
    await insertLog(LocalEditLogsCompanion.insert(
      localMatchId: matchId,
      targetType: 'play_by_play',
      targetId: playId,
      targetLocalId: Value(localId),
      editType: 'create',
      description: Value(description),
      editedAt: DateTime.now(),
    ));
  }

  /// Play-by-Play 수정 로그
  Future<void> logPlayUpdated({
    required int matchId,
    required int playId,
    required String localId,
    required String fieldName,
    required String oldValue,
    required String newValue,
    required String description,
  }) async {
    await insertLog(LocalEditLogsCompanion.insert(
      localMatchId: matchId,
      targetType: 'play_by_play',
      targetId: playId,
      targetLocalId: Value(localId),
      editType: 'update',
      fieldName: Value(fieldName),
      oldValue: Value(oldValue),
      newValue: Value(newValue),
      description: Value(description),
      editedAt: DateTime.now(),
    ));
  }

  /// Play-by-Play 삭제 로그
  Future<void> logPlayDeleted({
    required int matchId,
    required int playId,
    required String localId,
    required String description,
    String? oldValue,
  }) async {
    await insertLog(LocalEditLogsCompanion.insert(
      localMatchId: matchId,
      targetType: 'play_by_play',
      targetId: playId,
      targetLocalId: Value(localId),
      editType: 'delete',
      oldValue: Value(oldValue),
      description: Value(description),
      editedAt: DateTime.now(),
    ));
  }

  /// 선수 스탯 수정 로그
  Future<void> logStatsUpdated({
    required int matchId,
    required int playerId,
    required String fieldName,
    required String oldValue,
    required String newValue,
    required String description,
  }) async {
    await insertLog(LocalEditLogsCompanion.insert(
      localMatchId: matchId,
      targetType: 'player_stats',
      targetId: playerId,
      editType: 'update',
      fieldName: Value(fieldName),
      oldValue: Value(oldValue),
      newValue: Value(newValue),
      description: Value(description),
      editedAt: DateTime.now(),
    ));
  }
}
