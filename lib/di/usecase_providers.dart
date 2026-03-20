import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/usecases/usecases.dart';
import 'providers.dart';

/// UseCase Providers
///
/// CLAUDE.md 액션 연동 자동화 요구사항을 위한 UseCase 의존성 주입

/// 스틸 기록 UseCase Provider
/// 스틸 기록 시 상대 턴오버 자동 연동
final recordStealUseCaseProvider = Provider<RecordStealUseCase>((ref) {
  final database = ref.watch(databaseProvider);
  return RecordStealUseCase(database);
});

/// 블락 기록 UseCase Provider
/// 블락 기록 시 상대 슛 실패 자동 연동
final recordBlockUseCaseProvider = Provider<RecordBlockUseCase>((ref) {
  final database = ref.watch(databaseProvider);
  return RecordBlockUseCase(database);
});

/// 파울 기록 UseCase Provider
/// 오펜시브 파울 → 턴오버, 슈팅 파울 → 자유투 시퀀스
final recordFoulUseCaseProvider = Provider<RecordFoulUseCase>((ref) {
  final database = ref.watch(databaseProvider);
  return RecordFoulUseCase(database);
});
