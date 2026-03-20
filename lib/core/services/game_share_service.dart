import 'dart:convert';

import 'package:flutter/foundation.dart';

/// 경기 공유 데이터 모델
class GameShareData {
  final int matchId;
  final int? serverId; // 서버 TournamentMatch.id (동기화 후)
  final String localUuid;
  final String homeTeamName;
  final String awayTeamName;
  final int homeScore;
  final int awayScore;
  final int currentQuarter;
  final int gameClockSeconds;
  final String status;
  final DateTime timestamp;

  GameShareData({
    required this.matchId,
    this.serverId,
    required this.localUuid,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.homeScore,
    required this.awayScore,
    required this.currentQuarter,
    required this.gameClockSeconds,
    required this.status,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// 서버에 동기화된 경기인지 여부
  bool get isSynced => serverId != null;

  /// 점수 표시 문자열
  String get scoreDisplay => '$homeScore : $awayScore';

  /// 쿼터 표시 문자열
  String get quarterDisplay {
    if (status == 'finished') return 'Final';
    if (status == 'halftime') return 'Half';
    if (currentQuarter > 4) return 'OT${currentQuarter - 4}';
    return 'Q$currentQuarter';
  }

  /// 게임 클럭 표시 문자열
  String get clockDisplay {
    if (status == 'finished' || status == 'halftime') return '';
    final minutes = gameClockSeconds ~/ 60;
    final seconds = gameClockSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// 경기 상태 텍스트
  String get statusText {
    switch (status) {
      case 'scheduled':
        return '예정';
      case 'warmup':
        return '워밍업';
      case 'live':
        return 'LIVE';
      case 'halftime':
        return '하프타임';
      case 'finished':
        return '종료';
      default:
        return status;
    }
  }

  /// JSON 직렬화
  Map<String, dynamic> toJson() => {
        'matchId': matchId,
        'localUuid': localUuid,
        'home': homeTeamName,
        'away': awayTeamName,
        'homeScore': homeScore,
        'awayScore': awayScore,
        'quarter': currentQuarter,
        'clock': gameClockSeconds,
        'status': status,
        'ts': timestamp.millisecondsSinceEpoch,
      };

  /// JSON 역직렬화
  factory GameShareData.fromJson(Map<String, dynamic> json) => GameShareData(
        matchId: json['matchId'] as int,
        localUuid: json['localUuid'] as String,
        homeTeamName: json['home'] as String,
        awayTeamName: json['away'] as String,
        homeScore: json['homeScore'] as int,
        awayScore: json['awayScore'] as int,
        currentQuarter: json['quarter'] as int,
        gameClockSeconds: json['clock'] as int,
        status: json['status'] as String,
        timestamp: DateTime.fromMillisecondsSinceEpoch(json['ts'] as int),
      );

  /// Base64 인코딩된 공유 데이터
  String toBase64() => base64Encode(utf8.encode(jsonEncode(toJson())));

  /// Base64에서 복원
  static GameShareData fromBase64(String encoded) {
    final json = jsonDecode(utf8.decode(base64Decode(encoded)));
    return GameShareData.fromJson(json as Map<String, dynamic>);
  }
}

/// 경기 공유 서비스
class GameShareService {
  static final GameShareService instance = GameShareService._();

  GameShareService._();

  /// 공유 URL 호스트 (mybdr 서버)
  static const String _defaultHost = 'mybdr.kr';

  /// 현재 설정된 호스트
  String _host = _defaultHost;

  /// 호스트 설정 (개발 환경 오버라이드용)
  void setHost(String host) {
    _host = host;
  }

  /// 경기 공유 URL 생성
  ///
  /// 서버 동기화된 경기: https://mybdr.kr/live/{serverId}
  /// 미동기화 경기: null (공유 불가)
  String? generateShareUrl(GameShareData data) {
    if (data.serverId == null) return null;
    return 'https://$_host/live/${data.serverId}';
  }

  /// QR 코드용 URL 생성
  ///
  /// 서버 ID 기반 → mybdr 라이브 박스스코어 페이지
  String? generateQrUrl(GameShareData data) {
    if (data.serverId == null) return null;
    return 'https://$_host/live/${data.serverId}';
  }

  /// 간단한 공유 URL (serverId 기반)
  String? generateSimpleUrl(int? serverId) {
    if (serverId == null) return null;
    return 'https://$_host/live/$serverId';
  }

  /// 딥링크 URL 생성 (앱에서 열기용)
  String generateDeepLinkUrl(GameShareData data) {
    return 'bdr://live/${data.localUuid}';
  }

  /// 공유 텍스트 생성
  String generateShareText(GameShareData data) {
    final buffer = StringBuffer();
    buffer.writeln('🏀 ${data.homeTeamName} vs ${data.awayTeamName}');
    buffer.writeln('${data.scoreDisplay} (${data.quarterDisplay})');
    buffer.writeln();
    final url = generateShareUrl(data);
    if (url != null) {
      buffer.writeln('실시간 박스스코어: $url');
    } else {
      buffer.writeln('(경기 동기화 후 링크가 생성됩니다)');
    }
    return buffer.toString();
  }

  /// 경기 요약 카드 텍스트 생성
  String generateSummaryCard(GameShareData data) {
    final buffer = StringBuffer();
    buffer.writeln('┌─────────────────────────────┐');
    buffer.writeln('│   🏀 BDR Live Score         │');
    buffer.writeln('├─────────────────────────────┤');
    buffer.writeln('│  ${data.homeTeamName.padRight(10)} ${data.homeScore.toString().padLeft(3)}  │');
    buffer.writeln('│  ${data.awayTeamName.padRight(10)} ${data.awayScore.toString().padLeft(3)}  │');
    buffer.writeln('├─────────────────────────────┤');
    buffer.writeln('│  ${data.quarterDisplay.padRight(5)} ${data.clockDisplay.padLeft(6)}        │');
    buffer.writeln('└─────────────────────────────┘');
    return buffer.toString();
  }

  /// URL에서 UUID 추출
  String? extractUuidFromUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    final segments = uri.pathSegments;
    if (segments.length >= 2 && segments[0] == 'live') {
      return segments[1];
    }
    return null;
  }

  /// URL에서 공유 데이터 추출 (가능한 경우)
  GameShareData? extractDataFromUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    final encodedData = uri.queryParameters['d'];
    if (encodedData == null) return null;

    try {
      return GameShareData.fromBase64(encodedData);
    } catch (e) {
      debugPrint('Failed to decode share data: $e');
      return null;
    }
  }
}
