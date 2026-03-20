import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 오프라인 큐에 저장될 단일 이벤트
class PendingEvent {
  PendingEvent({
    required this.clientEventId,
    required this.matchId,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
  });

  factory PendingEvent.fromJson(Map<String, dynamic> json) => PendingEvent(
        clientEventId: json['client_event_id'] as String,
        matchId: json['match_id'] as int,
        data: Map<String, dynamic>.from(json['data'] as Map),
        createdAt: DateTime.parse(json['created_at'] as String),
        retryCount: json['retry_count'] as int? ?? 0,
      );

  final String clientEventId;
  final int matchId;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final int retryCount;

  /// 재시도 횟수를 증가시킨 복사본 반환
  PendingEvent copyWithRetry() => PendingEvent(
        clientEventId: clientEventId,
        matchId: matchId,
        data: data,
        createdAt: createdAt,
        retryCount: retryCount + 1,
      );

  Map<String, dynamic> toJson() => {
        'client_event_id': clientEventId,
        'match_id': matchId,
        'data': data,
        'created_at': createdAt.toIso8601String(),
        'retry_count': retryCount,
      };
}

/// 오프라인 이벤트 큐 — SharedPreferences에 영속 저장
///
/// 사용 흐름:
/// 1. 앱 시작 시 `await queue.load()` 호출
/// 2. 오프라인 이벤트 발생 시 `await queue.enqueue(event)` 호출
/// 3. 온라인 복구 시 `await queue.dequeueAll()` → batchFlushEvents 호출
class EventQueue {
  static const _key = 'pending_match_events';
  static const _deadLetterKey = 'dead_letter_events';
  static const int _maxEventRetries = 5;

  final Queue<PendingEvent> _queue = Queue();

  /// SharedPreferences에서 큐 복원
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return;

      final list = jsonDecode(raw) as List;
      _queue.clear();
      _queue.addAll(
        list.map(
          (e) => PendingEvent.fromJson(Map<String, dynamic>.from(e as Map)),
        ),
      );
      debugPrint('EventQueue: loaded ${_queue.length} pending events');
    } catch (e) {
      debugPrint('EventQueue: load error — $e');
    }
  }

  /// 이벤트를 큐에 추가하고 즉시 영속화
  Future<void> enqueue(PendingEvent event) async {
    _queue.add(event);
    await _persist();
    debugPrint('EventQueue: enqueued ${event.clientEventId}, total=${_queue.length}');
  }

  /// 큐의 모든 이벤트를 꺼내고 영속 데이터를 초기화
  ///
  /// 반환된 목록을 batchFlushEvents에 전달하고, 실패 시 다시 `enqueue`해야 합니다.
  Future<List<PendingEvent>> dequeueAll() async {
    final all = _queue.toList();
    _queue.clear();
    await _persist();
    debugPrint('EventQueue: dequeued ${all.length} events');
    return all;
  }

  /// matchId에 해당하는 이벤트만 꺼내기
  Future<List<PendingEvent>> dequeueByMatch(int matchId) async {
    final forMatch = _queue.where((e) => e.matchId == matchId).toList();
    _queue.removeWhere((e) => e.matchId == matchId);
    await _persist();
    return forMatch;
  }

  bool get isEmpty => _queue.isEmpty;
  int get length => _queue.length;

  /// matchId별 대기 이벤트 수
  int countForMatch(int matchId) =>
      _queue.where((e) => e.matchId == matchId).length;

  /// 실패한 이벤트를 큐의 앞쪽에 재삽입 (순서 보존)
  /// retryCount가 _maxEventRetries 이상인 이벤트는 dead-letter로 이동
  Future<void> requeueAll(List<PendingEvent> events) async {
    final retried = <PendingEvent>[];
    final deadLetters = <PendingEvent>[];

    for (final event in events) {
      final incremented = event.copyWithRetry();
      if (incremented.retryCount >= _maxEventRetries) {
        deadLetters.add(incremented);
      } else {
        retried.add(incremented);
      }
    }

    // dead-letter 처리
    if (deadLetters.isNotEmpty) {
      await _moveEventsToDeadLetter(deadLetters);
    }

    // 재시도 가능한 이벤트만 큐에 재삽입
    final existing = _queue.toList();
    _queue.clear();
    _queue.addAll(retried);
    _queue.addAll(existing);
    await _persist();
    debugPrint('EventQueue: requeued ${retried.length} events at front, ${deadLetters.length} moved to dead-letter');
  }

  /// clientEventId로 오프라인 큐에서 특정 이벤트 제거 (오프라인 Undo용)
  Future<bool> removeByClientEventId(String clientEventId) async {
    final before = _queue.length;
    _queue.removeWhere((e) => e.clientEventId == clientEventId);
    if (_queue.length < before) {
      await _persist();
      debugPrint('EventQueue: removed $clientEventId');
      return true;
    }
    return false;
  }

  /// dead-letter 이벤트를 SharedPreferences에 기록 (최대 20개 유지)
  Future<void> _moveEventsToDeadLetter(List<PendingEvent> events) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deadLetters = prefs.getStringList(_deadLetterKey) ?? [];
      for (final event in events) {
        debugPrint('EventQueue: DEAD_LETTER: ${event.clientEventId}, matchId=${event.matchId}, retries=${event.retryCount}');
        deadLetters.add(jsonEncode({
          'client_event_id': event.clientEventId,
          'match_id': event.matchId,
          'retry_count': event.retryCount,
          'dead_at': DateTime.now().toIso8601String(),
        }));
      }
      if (deadLetters.length > 20) {
        deadLetters.removeRange(0, deadLetters.length - 20);
      }
      await prefs.setStringList(_deadLetterKey, deadLetters);
    } catch (e) {
      debugPrint('EventQueue: dead-letter persist error — $e');
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode(_queue.map((e) => e.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('EventQueue: persist error — $e');
    }
  }
}
