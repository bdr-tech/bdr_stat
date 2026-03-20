import 'package:flutter/material.dart';

/// 게임 푸터 - 하단 고정 버튼들
class GameFooter extends StatelessWidget {
  const GameFooter({
    super.key,
    required this.onSendTap,
    required this.onBoxScoreTap,
    required this.onSettingsTap,
  });

  final VoidCallback onSendTap;
  final VoidCallback onBoxScoreTap;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 전송하기 버튼
        _FooterButton(
          icon: Icons.send,
          label: '전송하기',
          onTap: onSendTap,
        ),
        const SizedBox(width: 12),

        // 박스스코어 버튼
        _FooterButton(
          icon: Icons.leaderboard,
          label: '박스스코어',
          onTap: onBoxScoreTap,
        ),
        const SizedBox(width: 12),

        // 설정 버튼 (아이콘만)
        _FooterIconButton(
          icon: Icons.settings,
          onTap: onSettingsTap,
        ),
      ],
    );
  }
}

/// 푸터 버튼 (아이콘 + 라벨)
class _FooterButton extends StatelessWidget {
  const _FooterButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1E293B),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF334155),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 푸터 아이콘 버튼 (아이콘만)
class _FooterIconButton extends StatelessWidget {
  const _FooterIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1E293B),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF334155),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}
