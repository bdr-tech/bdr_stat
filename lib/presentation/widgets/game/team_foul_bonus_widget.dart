import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// 팀 파울 & 보너스 상태 위젯
class TeamFoulBonusWidget extends StatelessWidget {
  const TeamFoulBonusWidget({
    super.key,
    required this.teamName,
    required this.fouls,
    required this.isHome,
    this.maxFouls = 5,
    this.compact = false,
  });

  final String teamName;
  final int fouls;
  final bool isHome;
  final int maxFouls;
  final bool compact;

  bool get isInBonus => fouls >= maxFouls;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompact();
    }
    return _buildFull();
  }

  Widget _buildCompact() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isInBonus ? AppTheme.warningColor.withValues(alpha: 0.2) : AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(6),
        border: isInBonus
            ? Border.all(color: AppTheme.warningColor, width: 1)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '파울 $fouls',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isInBonus ? AppTheme.warningColor : AppTheme.textSecondary,
            ),
          ),
          if (isInBonus) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: AppTheme.warningColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'BONUS',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFull() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isInBonus ? AppTheme.warningColor.withValues(alpha: 0.1) : AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isInBonus ? AppTheme.warningColor : AppTheme.borderColor,
          width: isInBonus ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 팀 이름
          Text(
            teamName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isHome ? AppTheme.homeTeamColor : AppTheme.awayTeamColor,
            ),
          ),
          const SizedBox(height: 8),

          // 파울 카운트
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(maxFouls, (index) {
              final isFilled = index < fouls;
              return Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFilled ? _getFoulColor(index) : Colors.transparent,
                  border: Border.all(
                    color: isFilled ? _getFoulColor(index) : AppTheme.borderColor,
                    width: 1.5,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),

          // 보너스 상태
          if (isInBonus)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.warningColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'BONUS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            )
          else
            Text(
              '파울 $fouls/$maxFouls',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  Color _getFoulColor(int index) {
    if (index >= 4) {
      return AppTheme.errorColor; // 5파울 빨강
    } else if (index >= 3) {
      return AppTheme.warningColor; // 4파울 경고 노랑
    }
    return AppTheme.textSecondary;
  }
}

/// 타임아웃 남은 횟수 위젯
class TimeoutRemainingWidget extends StatelessWidget {
  const TimeoutRemainingWidget({
    super.key,
    required this.remaining,
    required this.isHome,
    this.maxTimeouts = 4,
    this.compact = false,
  });

  final int remaining;
  final bool isHome;
  final int maxTimeouts;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompact();
    }
    return _buildFull();
  }

  Widget _buildCompact() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(
            '$remaining',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: remaining == 0 ? AppTheme.errorColor : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFull() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'T/O',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(maxTimeouts, (index) {
              final isAvailable = index < remaining;
              return Container(
                width: 8,
                height: 16,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: isAvailable
                      ? (isHome ? AppTheme.homeTeamColor : AppTheme.awayTeamColor)
                      : AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(
                    color: isHome ? AppTheme.homeTeamColor : AppTheme.awayTeamColor,
                    width: 1,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// 선수 파울 표시 위젯 (⚫⚪⚪⚪⚪)
class PlayerFoulIndicator extends StatelessWidget {
  const PlayerFoulIndicator({
    super.key,
    required this.fouls,
    this.maxFouls = 5,
  });

  final int fouls;
  final int maxFouls;

  bool get isFouledOut => fouls >= maxFouls;
  bool get isWarning => fouls == maxFouls - 1; // 4파울 경고

  @override
  Widget build(BuildContext context) {
    if (fouls == 0) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxFouls, (index) {
        final isFilled = index < fouls;
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? _getDotColor(index) : Colors.transparent,
            border: Border.all(
              color: isFilled ? _getDotColor(index) : AppTheme.borderColor,
              width: 1,
            ),
          ),
        );
      }),
    );
  }

  Color _getDotColor(int index) {
    if (index >= maxFouls - 1) {
      return AppTheme.errorColor; // 5파울 빨강
    } else if (index >= maxFouls - 2) {
      return AppTheme.warningColor; // 4파울 노랑
    }
    return AppTheme.textSecondary;
  }
}

/// 팀 파울 관리자 (쿼터별)
class TeamFoulManager {
  TeamFoulManager({this.bonusThreshold = 5});

  final int bonusThreshold;

  // {1: 3, 2: 2, 3: 0, 4: 0} 형태로 쿼터별 파울 저장
  final Map<int, int> _homeFouls = {};
  final Map<int, int> _awayFouls = {};

  int getFouls(int quarter, bool isHome) {
    final fouls = isHome ? _homeFouls : _awayFouls;
    return fouls[quarter] ?? 0;
  }

  void addFoul(int quarter, bool isHome) {
    final fouls = isHome ? _homeFouls : _awayFouls;
    fouls[quarter] = (fouls[quarter] ?? 0) + 1;
  }

  void removeFoul(int quarter, bool isHome) {
    final fouls = isHome ? _homeFouls : _awayFouls;
    final current = fouls[quarter] ?? 0;
    if (current > 0) {
      fouls[quarter] = current - 1;
    }
  }

  bool isInBonus(int quarter, bool isHome) {
    return getFouls(quarter, isHome) >= bonusThreshold;
  }

  void resetForQuarter(int quarter) {
    _homeFouls[quarter] = 0;
    _awayFouls[quarter] = 0;
  }

  void setFouls(int quarter, bool isHome, int count) {
    final fouls = isHome ? _homeFouls : _awayFouls;
    fouls[quarter] = count;
  }

  Map<String, dynamic> toJson() {
    return {
      'home': Map.fromEntries(
        _homeFouls.entries.map((e) => MapEntry('q${e.key}', e.value)),
      ),
      'away': Map.fromEntries(
        _awayFouls.entries.map((e) => MapEntry('q${e.key}', e.value)),
      ),
    };
  }

  void fromJson(Map<String, dynamic> json) {
    _homeFouls.clear();
    _awayFouls.clear();

    final homeJson = json['home'] as Map<String, dynamic>? ?? {};
    final awayJson = json['away'] as Map<String, dynamic>? ?? {};

    for (final entry in homeJson.entries) {
      final quarter = int.tryParse(entry.key.replaceFirst('q', ''));
      if (quarter != null) {
        _homeFouls[quarter] = entry.value as int;
      }
    }

    for (final entry in awayJson.entries) {
      final quarter = int.tryParse(entry.key.replaceFirst('q', ''));
      if (quarter != null) {
        _awayFouls[quarter] = entry.value as int;
      }
    }
  }
}
