// ─── Event Definitions ────────────────────────────────────────────────────────
// Shared constants and event type definitions for the recorder.

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// 샷클락 없이도 기록 가능한 이벤트 (파울/교체/타임아웃)
const shotClockExemptTypes = {
  'foul_personal', 'foul_technical', 'foul_unsportsmanlike',
  'sub', 'timeout',
};

/// 상단 대형 버튼으로 표시할 득점 이벤트
const scoreEventTypes = {'2pt', '3pt', '1pt'};

class EventDef {
  const EventDef(this.type, this.label, this.icon, this.color, {this.value});
  final String type;
  final String label;
  final IconData icon;
  final Color color;
  final int? value;
}

const eventDefs = [
  EventDef('2pt', '2점', Icons.sports_basketball, AppTheme.primaryColor, value: 2),
  EventDef('3pt', '3점', Icons.sports_basketball, AppTheme.secondaryColor, value: 3),
  EventDef('1pt', '자유투', Icons.circle_outlined, AppTheme.emeraldGreen, value: 1),
  // 슛 실패 이벤트 (점수 변동 없음)
  EventDef('2pt_miss', '2점 실패', Icons.sports_basketball, AppTheme.primaryColor),
  EventDef('3pt_miss', '3점 실패', Icons.sports_basketball, AppTheme.secondaryColor),
  EventDef('1pt_miss', '자유투 실패', Icons.circle_outlined, AppTheme.emeraldGreen),
  EventDef('rebound_off', '공격 리바운드', Icons.arrow_upward, Color(0xFF8B5CF6)),
  EventDef('rebound_def', '수비 리바운드', Icons.arrow_downward, Color(0xFF6366F1)),
  EventDef('rebound_team', '팀 리바운드', Icons.group, Color(0xFF7C3AED)),
  EventDef('assist', '어시스트', Icons.handshake, Color(0xFF0EA5E9)),
  EventDef('steal', '스틸', Icons.flash_on, AppTheme.warningColor),
  EventDef('block', '블록', Icons.back_hand, Color(0xFFEC4899)),
  EventDef('turnover', '턴오버', Icons.swap_horiz, AppTheme.errorColor),
  EventDef('foul_personal', '개인 파울', Icons.warning, Color(0xFFEF4444)),
  EventDef('foul_technical', '기술 파울', Icons.gavel, Color(0xFFDC2626)),
  EventDef('foul_unsportsmanlike', '비신사적 파울', Icons.front_hand, Color(0xFF8B5CF6)),
  EventDef('sub', '교체', Icons.swap_vert, Color(0xFF10B981)),
  EventDef('timeout', '타임아웃', Icons.timer_off, Color(0xFFF59E0B)),
];

/// 슛 실패 이벤트 타입
const shotMissTypes = {'2pt_miss', '3pt_miss', '1pt_miss'};

/// 파울 이벤트 타입 (개인파울 카운트)
const personalFoulTypes = {'foul_personal', 'foul_offensive', 'foul_unsportsmanlike'};

/// T+U 파울 (2개 합산 시 퇴장)
const techUnsportFoulTypes = {'foul_technical', 'foul_unsportsmanlike'};
