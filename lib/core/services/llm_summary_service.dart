// TODO(phase2): This service is not yet integrated.
// Planned for Phase 2 release. Do not call from production code.
// Depends on: game_highlight_service.dart (also phase2), external OpenAI API key.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game_highlight_service.dart';

/// LLM 요약 서비스 프로바이더
// TODO(phase2): Provider not registered in main DI. Wire up only after Phase 2 design approval.
final llmSummaryServiceProvider = Provider<LLMSummaryService>((ref) {
  return LLMSummaryService();
});

/// LLM 요약 캐시 프로바이더 (matchId -> summary)
final llmSummaryCacheProvider =
    StateNotifierProvider<LLMSummaryCacheNotifier, Map<int, LLMSummaryResult>>(
        (ref) {
  return LLMSummaryCacheNotifier();
});

/// LLM 요약 서비스
///
/// OpenAI GPT-4o-mini를 사용한 경기 요약 생성
/// - 비용 최적화: 토큰 사용량 제한
/// - 오프라인 대응: 로컬 요약 폴백
/// - 캐싱: 같은 경기 반복 요청 방지
///
// TODO(phase2): Class not connected to any screen. Full integration planned for Phase 2.
class LLMSummaryService {
  static const String _openAiApiKeyPref = 'openai_api_key';
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _model = 'gpt-4o-mini';
  static const int _maxTokens = 200;

  String? _apiKey;

  /// API 키 설정
  Future<void> setApiKey(String apiKey) async {
    _apiKey = apiKey;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_openAiApiKeyPref, apiKey);
  }

  /// 저장된 API 키 로드
  Future<String?> loadApiKey() async {
    if (_apiKey != null) return _apiKey;
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString(_openAiApiKeyPref);
    return _apiKey;
  }

  /// API 키 유효성 확인
  Future<bool> hasValidApiKey() async {
    final key = await loadApiKey();
    return key != null && key.isNotEmpty && key.startsWith('sk-');
  }

  /// 경기 요약 생성
  ///
  /// [highlights] 추출된 경기 하이라이트
  /// [forceRefresh] 캐시 무시하고 새로 생성
  /// Returns: LLM 생성 요약 또는 로컬 요약 (오프라인/에러 시)
  Future<LLMSummaryResult> generateSummary(
    GameHighlights highlights, {
    bool forceRefresh = false,
  }) async {
    final apiKey = await loadApiKey();

    // API 키 없으면 로컬 요약 반환
    if (apiKey == null || apiKey.isEmpty) {
      return _createLocalSummary(highlights);
    }

    try {
      final prompt =
          GameHighlightService.instance.generateSummaryPrompt(highlights);

      final response = await _callOpenAI(
        apiKey: apiKey,
        prompt: prompt,
        systemPrompt: _systemPrompt,
      );

      return LLMSummaryResult(
        matchId: highlights.matchId,
        summary: response.trim(),
        source: LLMSummarySource.openAI,
        tokensUsed: _estimateTokens(prompt, response),
        generatedAt: DateTime.now(),
        isSuccess: true,
      );
    } catch (e) {
      debugPrint('LLM 요약 생성 실패: $e');

      // 폴백: 로컬 요약
      return _createLocalSummary(highlights, error: e.toString());
    }
  }

  /// OpenAI API 호출
  Future<String> _callOpenAI({
    required String apiKey,
    required String prompt,
    required String systemPrompt,
  }) async {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    try {
      final response = await dio.post(
        _baseUrl,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
        ),
        data: {
          'model': _model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': _maxTokens,
          'temperature': 0.7,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final choices = data['choices'] as List;
        if (choices.isNotEmpty) {
          final message = choices[0]['message'] as Map<String, dynamic>;
          return message['content'] as String;
        }
        throw Exception('빈 응답');
      } else {
        throw Exception('API 오류: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('유효하지 않은 API 키');
      } else if (e.response?.statusCode == 429) {
        throw Exception('API 요청 한도 초과');
      }
      throw Exception('API 오류: ${e.message}');
    }
  }

  /// 로컬 요약 생성 (API 없이)
  LLMSummaryResult _createLocalSummary(
    GameHighlights highlights, {
    String? error,
  }) {
    final localSummary =
        GameHighlightService.instance.generateQuickSummary(highlights);

    return LLMSummaryResult(
      matchId: highlights.matchId,
      summary: localSummary,
      source: LLMSummarySource.local,
      tokensUsed: 0,
      generatedAt: DateTime.now(),
      isSuccess: error == null,
      errorMessage: error,
    );
  }

  /// 토큰 사용량 추정 (간단한 휴리스틱)
  int _estimateTokens(String prompt, String response) {
    // 한글 기준 약 0.5자당 1토큰
    return ((prompt.length + response.length) / 2).round();
  }

  /// 시스템 프롬프트
  static const String _systemPrompt = '''
당신은 농구 경기 요약 전문가입니다.
다음 규칙을 따르세요:
1. 2-3문장으로 간결하게 요약
2. 승패, 핵심 선수, 중요 플레이 포함
3. 숫자는 정확하게 사용
4. 흥미롭고 역동적인 표현 사용
5. 한국어로 작성
''';

  /// 소셜 미디어용 요약 생성
  Future<SocialSummaries> generateSocialSummaries(
    GameHighlights highlights,
  ) async {
    final mainSummary = await generateSummary(highlights);

    final shareCard = GameHighlightService.instance.generateShareCard(
      highlights,
      aiSummary: mainSummary.summary,
    );

    return SocialSummaries(
      mainSummary: mainSummary.summary,
      twitterText:
          GameHighlightService.instance.generateTwitterText(shareCard),
      instagramText:
          GameHighlightService.instance.generateInstagramText(shareCard),
      shareCard: shareCard,
    );
  }
}

/// LLM 요약 결과
class LLMSummaryResult {
  final int matchId;
  final String summary;
  final LLMSummarySource source;
  final int tokensUsed;
  final DateTime generatedAt;
  final bool isSuccess;
  final String? errorMessage;

  const LLMSummaryResult({
    required this.matchId,
    required this.summary,
    required this.source,
    required this.tokensUsed,
    required this.generatedAt,
    required this.isSuccess,
    this.errorMessage,
  });

  /// 토큰당 예상 비용 (USD)
  double get estimatedCost {
    // GPT-4o-mini: $0.15 / 1M input, $0.60 / 1M output
    // 간단히 평균 $0.375 / 1M으로 계산
    return tokensUsed * 0.000000375;
  }

  Map<String, dynamic> toJson() => {
        'matchId': matchId,
        'summary': summary,
        'source': source.name,
        'tokensUsed': tokensUsed,
        'generatedAt': generatedAt.toIso8601String(),
        'isSuccess': isSuccess,
        'errorMessage': errorMessage,
      };

  factory LLMSummaryResult.fromJson(Map<String, dynamic> json) {
    return LLMSummaryResult(
      matchId: json['matchId'] as int,
      summary: json['summary'] as String,
      source: LLMSummarySource.values.firstWhere(
        (e) => e.name == json['source'],
        orElse: () => LLMSummarySource.local,
      ),
      tokensUsed: json['tokensUsed'] as int,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      isSuccess: json['isSuccess'] as bool,
      errorMessage: json['errorMessage'] as String?,
    );
  }
}

/// 요약 출처
enum LLMSummarySource {
  openAI, // OpenAI API
  local, // 로컬 생성
  cached, // 캐시에서 로드
}

/// 소셜 미디어 요약 모음
class SocialSummaries {
  final String mainSummary;
  final String twitterText;
  final String instagramText;
  final SocialShareCard shareCard;

  const SocialSummaries({
    required this.mainSummary,
    required this.twitterText,
    required this.instagramText,
    required this.shareCard,
  });
}

/// LLM 요약 캐시 상태 관리
class LLMSummaryCacheNotifier extends StateNotifier<Map<int, LLMSummaryResult>> {
  LLMSummaryCacheNotifier() : super({});

  static const String _cacheKey = 'llm_summary_cache';

  /// 캐시에 저장
  void cacheResult(LLMSummaryResult result) {
    state = {...state, result.matchId: result};
    _saveToDisk();
  }

  /// 캐시에서 조회
  LLMSummaryResult? getCached(int matchId) {
    return state[matchId];
  }

  /// 캐시 삭제
  void clearCache(int matchId) {
    state = Map.from(state)..remove(matchId);
    _saveToDisk();
  }

  /// 전체 캐시 삭제
  void clearAll() {
    state = {};
    _saveToDisk();
  }

  /// 디스크에서 로드
  Future<void> loadFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cacheKey);
      if (jsonString != null) {
        final data = jsonDecode(jsonString) as Map<String, dynamic>;
        state = data.map(
          (key, value) => MapEntry(
            int.parse(key),
            LLMSummaryResult.fromJson(value as Map<String, dynamic>),
          ),
        );
      }
    } catch (e) {
      debugPrint('캐시 로드 실패: $e');
    }
  }

  /// 디스크에 저장
  Future<void> _saveToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = state.map(
        (key, value) => MapEntry(key.toString(), value.toJson()),
      );
      await prefs.setString(_cacheKey, jsonEncode(data));
    } catch (e) {
      debugPrint('캐시 저장 실패: $e');
    }
  }

  /// 캐시 통계
  LLMCacheStats get stats {
    int totalTokens = 0;
    int openAiCount = 0;
    int localCount = 0;

    for (final result in state.values) {
      totalTokens += result.tokensUsed;
      if (result.source == LLMSummarySource.openAI) {
        openAiCount++;
      } else {
        localCount++;
      }
    }

    return LLMCacheStats(
      totalEntries: state.length,
      openAiEntries: openAiCount,
      localEntries: localCount,
      totalTokensUsed: totalTokens,
      estimatedTotalCost: totalTokens * 0.000000375,
    );
  }
}

/// 캐시 통계
class LLMCacheStats {
  final int totalEntries;
  final int openAiEntries;
  final int localEntries;
  final int totalTokensUsed;
  final double estimatedTotalCost;

  const LLMCacheStats({
    required this.totalEntries,
    required this.openAiEntries,
    required this.localEntries,
    required this.totalTokensUsed,
    required this.estimatedTotalCost,
  });
}
