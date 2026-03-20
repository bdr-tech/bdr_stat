/// 시간 관련 유틸리티
class TimeUtils {
  TimeUtils._();

  /// 초를 MM:SS 형식으로 변환
  static String formatGameClock(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// 별칭 - formatGameClock
  static String formatClock(int seconds) => formatGameClock(seconds);

  /// 초를 M:SS 형식으로 변환 (샷클락용)
  static String formatShotClock(int seconds) {
    if (seconds >= 60) {
      final minutes = seconds ~/ 60;
      final secs = seconds % 60;
      return '$minutes:${secs.toString().padLeft(2, '0')}';
    }
    return seconds.toString();
  }

  /// 분을 시:분 형식으로 변환 (출전 시간용)
  static String formatMinutesPlayed(int minutes) {
    if (minutes < 60) {
      return '$minutes분';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '$hours시간 $mins분';
  }

  /// MM:SS 형식을 초로 변환
  static int parseGameClock(String clock) {
    final parts = clock.split(':');
    if (parts.length != 2) return 0;
    final minutes = int.tryParse(parts[0]) ?? 0;
    final seconds = int.tryParse(parts[1]) ?? 0;
    return minutes * 60 + seconds;
  }

  /// 쿼터 이름 반환
  static String getQuarterName(int quarter) {
    if (quarter <= 4) {
      return '${quarter}Q';
    }
    return 'OT${quarter - 4}';
  }

  /// 쿼터 전체 이름 반환
  static String getQuarterFullName(int quarter) {
    if (quarter <= 4) {
      return '$quarter쿼터';
    }
    return '연장 ${quarter - 4}';
  }
}
