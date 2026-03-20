import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/database/database.dart';

/// 파울 종류
enum FoulType {
  personal, // 일반 파울
  shooting, // 슈팅 파울 (자유투 연결)
  offensive, // 오펜시브 파울 (턴오버 연결)
  technical, // 테크니컬 파울
  unsportsmanlike, // 비신사적 파울
}

/// 파울 결과
class FoulResult {
  final FoulType type;
  final LocalTournamentPlayer? fouledPlayer; // 파울 당한 선수
  final int? freeThrowCount; // 슈팅 파울인 경우 자유투 개수
  final bool causedTurnover; // 턴오버 연결 여부

  const FoulResult({
    required this.type,
    this.fouledPlayer,
    this.freeThrowCount,
    this.causedTurnover = false,
  });

  bool get isShootingFoul => type == FoulType.shooting;
  bool get isOffensiveFoul => type == FoulType.offensive;
  bool get isTechnical => type == FoulType.technical;
  bool get isUnsportsmanlike => type == FoulType.unsportsmanlike;
}

/// 파울 종류 선택 다이얼로그
class FoulTypeDialog extends StatefulWidget {
  const FoulTypeDialog({
    super.key,
    required this.foulingPlayer,
    required this.opposingTeamPlayers,
    this.onSelect,
  });

  final LocalTournamentPlayer foulingPlayer;
  final List<LocalTournamentPlayer> opposingTeamPlayers;
  final void Function(FoulResult result)? onSelect;

  @override
  State<FoulTypeDialog> createState() => _FoulTypeDialogState();
}

class _FoulTypeDialogState extends State<FoulTypeDialog> {
  FoulType? _selectedType;
  LocalTournamentPlayer? _fouledPlayer;
  int _freeThrowCount = 2;

  bool get _needsPlayerSelection =>
      _selectedType == FoulType.shooting;

  bool get _needsFreeThrowCount =>
      _selectedType == FoulType.shooting;

  bool get _canConfirm {
    if (_selectedType == null) return false;
    if (_needsPlayerSelection && _fouledPlayer == null) return false;
    return true;
  }

  void _selectType(FoulType type) {
    setState(() {
      _selectedType = type;
      if (type != FoulType.shooting) {
        _fouledPlayer = null;
      }
    });

    // 바로 완료 가능한 타입은 즉시 완료
    if (!_needsPlayerSelection) {
      _confirm();
    }
  }

  void _selectFouledPlayer(LocalTournamentPlayer player) {
    setState(() {
      _fouledPlayer = player;
    });
  }

  void _confirm() {
    if (!_canConfirm) return;

    final result = FoulResult(
      type: _selectedType!,
      fouledPlayer: _fouledPlayer,
      freeThrowCount: _needsFreeThrowCount ? _freeThrowCount : null,
      causedTurnover: _selectedType == FoulType.offensive,
    );

    widget.onSelect?.call(result);
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                const Icon(Icons.front_hand, color: AppTheme.errorColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '파울 종류',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '#${widget.foulingPlayer.jerseyNumber ?? '-'} ${widget.foulingPlayer.userName}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 파울 종류 선택
            if (_selectedType == null || !_needsPlayerSelection) ...[
              _FoulTypeButton(
                icon: Icons.sports_basketball,
                label: '일반 파울',
                description: '기본 퍼스널 파울',
                color: AppTheme.warningColor,
                isSelected: _selectedType == FoulType.personal,
                onTap: () => _selectType(FoulType.personal),
              ),
              const SizedBox(height: 8),
              _FoulTypeButton(
                icon: Icons.sports_handball,
                label: '슈팅 파울',
                description: '상대 슛 중 파울 → 자유투',
                color: AppTheme.errorColor,
                isSelected: _selectedType == FoulType.shooting,
                onTap: () => _selectType(FoulType.shooting),
              ),
              const SizedBox(height: 8),
              _FoulTypeButton(
                icon: Icons.block,
                label: '오펜시브 파울',
                description: '공격 중 파울 → 턴오버',
                color: AppTheme.secondaryColor,
                isSelected: _selectedType == FoulType.offensive,
                onTap: () => _selectType(FoulType.offensive),
              ),
              const SizedBox(height: 8),
              _FoulTypeButton(
                icon: Icons.warning,
                label: '테크니컬 파울',
                description: '비신사적 행위',
                color: Colors.purple,
                isSelected: _selectedType == FoulType.technical,
                onTap: () => _selectType(FoulType.technical),
              ),
            ],

            // 슈팅 파울: 파울 당한 선수 선택
            if (_selectedType == FoulType.shooting) ...[
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                '파울 당한 선수',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Column(
                    children: widget.opposingTeamPlayers.map((player) {
                      final isSelected = _fouledPlayer?.id == player.id;
                      return Material(
                        color: isSelected
                            ? AppTheme.primaryColor.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: () => _selectFouledPlayer(player),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.primaryColor
                                        : AppTheme.backgroundColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '#${player.jerseyNumber ?? '-'}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: isSelected
                                          ? Colors.white
                                          : AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    player.userName,
                                    style: TextStyle(
                                      fontWeight:
                                          isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check,
                                      color: AppTheme.primaryColor, size: 20),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 자유투 개수 선택
              const Text(
                '자유투 개수',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [1, 2, 3].map((count) {
                  final isSelected = _freeThrowCount == count;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Material(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        onTap: () => setState(() => _freeThrowCount = count),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // 확인 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canConfirm ? _confirm : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('확인'),
                ),
              ),

              // 뒤로가기 버튼
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedType = null;
                    _fouledPlayer = null;
                  });
                },
                child: const Text('파울 종류 다시 선택'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 파울 종류 버튼
class _FoulTypeButton extends StatelessWidget {
  const _FoulTypeButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? color.withValues(alpha: 0.15)
          : AppTheme.backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? color : AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isSelected ? color : AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 파울 종류 다이얼로그 표시 헬퍼 함수
Future<FoulResult?> showFoulTypeDialog({
  required BuildContext context,
  required LocalTournamentPlayer foulingPlayer,
  required List<LocalTournamentPlayer> opposingTeamPlayers,
}) {
  return showDialog<FoulResult?>(
    context: context,
    builder: (context) => FoulTypeDialog(
      foulingPlayer: foulingPlayer,
      opposingTeamPlayers: opposingTeamPlayers,
    ),
  );
}
