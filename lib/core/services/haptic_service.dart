import 'package:flutter/services.dart';

/// 햅틱 피드백 서비스
///
/// 액션 유형별로 최적화된 햅틱 피드백을 제공합니다.
/// 태블릿 환경에서 눈을 코트에 두면서도 기록 확인이 가능하도록 지원합니다.
class HapticService {
  HapticService._();

  /// 싱글톤 인스턴스
  static final HapticService instance = HapticService._();

  /// 햅틱 피드백 활성화 여부
  bool _enabled = true;

  /// 햅틱 피드백 활성화/비활성화
  void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  /// 햅틱 피드백 활성화 여부 확인
  bool get isEnabled => _enabled;

  // ============================================================
  // 슛 관련 피드백
  // ============================================================

  /// 슛 성공 (득점)
  /// - 강한 피드백으로 성공 확인
  Future<void> shotMade() async {
    if (!_enabled) return;
    await HapticFeedback.mediumImpact();
  }

  /// 슛 실패
  /// - 약한 피드백으로 실패 확인
  Future<void> shotMissed() async {
    if (!_enabled) return;
    await HapticFeedback.lightImpact();
  }

  /// 3점 슛 성공
  /// - 더 강한 피드백으로 빅 플레이 표시
  Future<void> threePointerMade() async {
    if (!_enabled) return;
    await HapticFeedback.heavyImpact();
  }

  /// 자유투 성공
  Future<void> freeThrowMade() async {
    if (!_enabled) return;
    await HapticFeedback.lightImpact();
  }

  /// 자유투 실패
  Future<void> freeThrowMissed() async {
    if (!_enabled) return;
    await HapticFeedback.selectionClick();
  }

  // ============================================================
  // 기타 액션 피드백
  // ============================================================

  /// 어시스트, 리바운드, 스틸, 블락 등 일반 스탯 기록
  Future<void> statRecorded() async {
    if (!_enabled) return;
    await HapticFeedback.selectionClick();
  }

  /// 턴오버 기록
  Future<void> turnover() async {
    if (!_enabled) return;
    await HapticFeedback.lightImpact();
  }

  /// 파울 기록
  Future<void> foulRecorded() async {
    if (!_enabled) return;
    await HapticFeedback.mediumImpact();
  }

  /// 5파울 아웃 (퇴장)
  /// - 2연속 강한 피드백으로 중요 이벤트 알림
  Future<void> fouledOut() async {
    if (!_enabled) return;
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();
  }

  // ============================================================
  // 경기 진행 피드백
  // ============================================================

  /// 쿼터 종료
  Future<void> quarterEnd() async {
    if (!_enabled) return;
    await HapticFeedback.heavyImpact();
  }

  /// 타임아웃
  Future<void> timeout() async {
    if (!_enabled) return;
    await HapticFeedback.mediumImpact();
  }

  /// 선수 교체
  Future<void> substitution() async {
    if (!_enabled) return;
    await HapticFeedback.selectionClick();
  }

  /// 실행 취소 (Undo)
  Future<void> undo() async {
    if (!_enabled) return;
    await HapticFeedback.lightImpact();
  }

  // ============================================================
  // UI 인터랙션 피드백
  // ============================================================

  /// 버튼 탭 — 짧고 굵은 피드백
  Future<void> buttonTap() async {
    if (!_enabled) return;
    await HapticFeedback.heavyImpact();
  }

  /// 메뉴 열림
  Future<void> menuOpen() async {
    if (!_enabled) return;
    await HapticFeedback.mediumImpact();
  }

  /// 스와이프 액션 완료
  Future<void> swipeAction() async {
    if (!_enabled) return;
    await HapticFeedback.mediumImpact();
  }

  /// 드래그 앤 드롭 완료
  Future<void> dragComplete() async {
    if (!_enabled) return;
    await HapticFeedback.mediumImpact();
  }

  /// 에러/경고
  Future<void> error() async {
    if (!_enabled) return;
    await HapticFeedback.vibrate();
  }

  /// 성공 알림
  Future<void> success() async {
    if (!_enabled) return;
    await HapticFeedback.mediumImpact();
  }
}
