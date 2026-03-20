// ─── Substitution Sheet (§1.4) ────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import 'team_picker.dart';

class SubstitutionSheet extends StatefulWidget {
  const SubstitutionSheet({
    super.key,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.homePlayers,
    required this.awayPlayers,
    required this.onSubstitute,
  });

  final String homeTeamName;
  final String awayTeamName;
  final List<Map<String, dynamic>> homePlayers;
  final List<Map<String, dynamic>> awayPlayers;
  final void Function(
    String teamSide,
    int outId,
    String outName,
    int inId,
    String inName,
  ) onSubstitute;

  @override
  State<SubstitutionSheet> createState() => _SubstitutionSheetState();
}

class _SubstitutionSheetState extends State<SubstitutionSheet> {
  String? _teamSide;
  Map<String, dynamic>? _outPlayer;

  List<Map<String, dynamic>> get _currentPlayers =>
      _teamSide == 'home' ? widget.homePlayers : widget.awayPlayers;

  List<Map<String, dynamic>> get _starters =>
      _currentPlayers.where((p) => p['is_starter'] == true).toList();

  List<Map<String, dynamic>> get _bench =>
      _currentPlayers.where((p) => p['is_starter'] != true).toList();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (ctx, scrollController) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.textHint,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              _teamSide == null
                  ? '선수 교체 — 팀 선택'
                  : _outPlayer == null
                      ? '나가는 선수 (스타터)'
                      : '들어오는 선수 (벤치)',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            if (_teamSide != null)
              TextButton.icon(
                onPressed: () => setState(() {
                  if (_outPlayer != null) {
                    _outPlayer = null;
                  } else {
                    _teamSide = null;
                  }
                }),
                icon: const Icon(Icons.arrow_back_ios, size: 16),
                label: const Text('이전'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),

            Expanded(child: _buildContent(scrollController)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ScrollController sc) {
    if (_teamSide == null) {
      return Row(
        children: [
          Expanded(
            child: TeamButton(
              label: widget.homeTeamName,
              sublabel: 'HOME',
              color: AppTheme.primaryColor,
              onTap: () => setState(() => _teamSide = 'home'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TeamButton(
              label: widget.awayTeamName,
              sublabel: 'AWAY',
              color: AppTheme.secondaryColor,
              onTap: () => setState(() => _teamSide = 'away'),
            ),
          ),
        ],
      );
    }

    if (_outPlayer == null) {
      // 나가는 선수 = 스타터 목록
      if (_starters.isEmpty) {
        return const Center(
          child: Text('스타터 정보가 없습니다.', style: TextStyle(color: AppTheme.textSecondary)),
        );
      }
      return ListView(
        controller: sc,
        children: _starters.map((p) => _playerTile(p, isOut: true)).toList(),
      );
    }

    // 들어오는 선수 = 벤치 목록
    if (_bench.isEmpty) {
      return const Center(
        child: Text('교체 가능한 선수가 없습니다.', style: TextStyle(color: AppTheme.textSecondary)),
      );
    }
    return ListView(
      controller: sc,
      children: _bench.map((p) => _playerTile(p, isOut: false)).toList(),
    );
  }

  Widget _playerTile(Map<String, dynamic> p, {required bool isOut}) {
    final id = p['id'] as int? ?? 0;
    final name = p['name'] as String? ?? '선수';
    final number = p['jersey_number'] as int?;

    return ListTile(
      leading: CircleAvatar(
        radius: 18,
        backgroundColor:
            (isOut ? AppTheme.errorColor : AppTheme.successColor).withValues(alpha: 0.15),
        child: Text(
          number != null ? '#$number' : '',
          style: TextStyle(
            fontSize: 12,
            color: isOut ? AppTheme.errorColor : AppTheme.successColor,
          ),
        ),
      ),
      title: Text(name),
      trailing: Icon(
        isOut ? Icons.arrow_upward : Icons.arrow_downward,
        color: isOut ? AppTheme.errorColor : AppTheme.successColor,
        size: 18,
      ),
      onTap: () {
        HapticFeedback.lightImpact();
        if (isOut) {
          setState(() => _outPlayer = p);
        } else {
          // 교체 확정
          final outId = _outPlayer!['id'] as int? ?? 0;
          final outName = _outPlayer!['name'] as String? ?? '선수';
          widget.onSubstitute(_teamSide!, outId, outName, id, name);
        }
      },
    );
  }
}
