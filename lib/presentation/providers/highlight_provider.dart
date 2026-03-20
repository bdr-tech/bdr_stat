import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/game_highlight_service.dart';
import '../../core/services/llm_summary_service.dart';
import '../../data/database/database.dart';

/// 현재 경기 하이라이트 프로바이더
///
/// 경기 ID를 받아서 하이라이트를 추출하고 관리
final gameHighlightsProvider = StateNotifierProvider.family<
    GameHighlightsNotifier, AsyncValue<GameHighlights?>, int>((ref, matchId) {
  return GameHighlightsNotifier(ref, matchId);
});

/// 경기 하이라이트 상태 관리자
class GameHighlightsNotifier extends StateNotifier<AsyncValue<GameHighlights?>> {
  GameHighlightsNotifier(Ref ref, int matchId) : super(const AsyncValue.data(null));

  /// 하이라이트 추출 실행
  Future<void> extractHighlights({
    required LocalMatche match,
    required List<LocalPlayByPlay> events,
    required List<LocalPlayerStat> playerStats,
    required Map<int, String> playerNames,
  }) async {
    state = const AsyncValue.loading();

    try {
      final highlights = GameHighlightService.instance.extractHighlights(
        match: match,
        events: events,
        playerStats: playerStats,
        playerNames: playerNames,
      );

      state = AsyncValue.data(highlights);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 하이라이트 초기화
  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// AI 요약 상태
enum AISummaryStatus {
  idle, // 대기
  loading, // 생성 중
  success, // 성공
  error, // 실패
}

/// AI 요약 상태 모델
class AISummaryState {
  final AISummaryStatus status;
  final LLMSummaryResult? result;
  final String? errorMessage;

  const AISummaryState({
    this.status = AISummaryStatus.idle,
    this.result,
    this.errorMessage,
  });

  AISummaryState copyWith({
    AISummaryStatus? status,
    LLMSummaryResult? result,
    String? errorMessage,
  }) {
    return AISummaryState(
      status: status ?? this.status,
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isLoading => status == AISummaryStatus.loading;
  bool get hasResult => result != null;
}

/// AI 요약 프로바이더
final aiSummaryProvider =
    StateNotifierProvider.family<AISummaryNotifier, AISummaryState, int>(
        (ref, matchId) {
  return AISummaryNotifier(ref, matchId);
});

/// AI 요약 상태 관리자
class AISummaryNotifier extends StateNotifier<AISummaryState> {
  AISummaryNotifier(this._ref, this._matchId) : super(const AISummaryState());

  final Ref _ref;
  final int _matchId;

  /// AI 요약 생성
  Future<void> generateSummary(GameHighlights highlights) async {
    state = state.copyWith(status: AISummaryStatus.loading);

    try {
      // 캐시 확인
      final cache = _ref.read(llmSummaryCacheProvider);
      final cached = cache[_matchId];

      if (cached != null) {
        state = state.copyWith(
          status: AISummaryStatus.success,
          result: cached,
        );
        return;
      }

      // LLM 요약 생성
      final service = _ref.read(llmSummaryServiceProvider);
      final result = await service.generateSummary(highlights);

      // 캐시 저장
      _ref.read(llmSummaryCacheProvider.notifier).cacheResult(result);

      state = state.copyWith(
        status: AISummaryStatus.success,
        result: result,
      );
    } catch (e) {
      state = state.copyWith(
        status: AISummaryStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// 요약 새로고침 (캐시 무시)
  Future<void> refreshSummary(GameHighlights highlights) async {
    state = state.copyWith(status: AISummaryStatus.loading);

    try {
      final service = _ref.read(llmSummaryServiceProvider);
      final result = await service.generateSummary(highlights, forceRefresh: true);

      // 캐시 업데이트
      _ref.read(llmSummaryCacheProvider.notifier).cacheResult(result);

      state = state.copyWith(
        status: AISummaryStatus.success,
        result: result,
      );
    } catch (e) {
      state = state.copyWith(
        status: AISummaryStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// 상태 초기화
  void reset() {
    state = const AISummaryState();
  }
}

/// 하이라이트 + AI 요약 통합 프로바이더
///
/// 경기 종료 시 자동으로 하이라이트 추출 및 AI 요약 생성
final gameEndSummaryProvider = FutureProvider.family<GameEndSummary?, GameEndSummaryParams>(
  (ref, params) async {
    // 하이라이트 추출
    final highlights = GameHighlightService.instance.extractHighlights(
      match: params.match,
      events: params.events,
      playerStats: params.playerStats,
      playerNames: params.playerNames,
    );

    // AI 요약 생성
    final llmService = ref.read(llmSummaryServiceProvider);
    final summaryResult = await llmService.generateSummary(highlights);

    // 소셜 공유용 데이터
    final shareCard = GameHighlightService.instance.generateShareCard(
      highlights,
      aiSummary: summaryResult.summary,
    );

    return GameEndSummary(
      highlights: highlights,
      summary: summaryResult,
      shareCard: shareCard,
    );
  },
);

/// 경기 종료 요약 파라미터
class GameEndSummaryParams {
  final LocalMatche match;
  final List<LocalPlayByPlay> events;
  final List<LocalPlayerStat> playerStats;
  final Map<int, String> playerNames;

  const GameEndSummaryParams({
    required this.match,
    required this.events,
    required this.playerStats,
    required this.playerNames,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameEndSummaryParams &&
          runtimeType == other.runtimeType &&
          match.id == other.match.id;

  @override
  int get hashCode => match.id.hashCode;
}

/// 경기 종료 요약 결과
class GameEndSummary {
  final GameHighlights highlights;
  final LLMSummaryResult summary;
  final SocialShareCard shareCard;

  const GameEndSummary({
    required this.highlights,
    required this.summary,
    required this.shareCard,
  });

  /// 트위터 공유 텍스트
  String get twitterText =>
      GameHighlightService.instance.generateTwitterText(shareCard);

  /// 인스타그램 공유 텍스트
  String get instagramText =>
      GameHighlightService.instance.generateInstagramText(shareCard);
}
