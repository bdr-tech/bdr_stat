import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../screens/recording/models/player_with_stats.dart';

/// 등번호로 빠른 선수 검색 위젯
///
/// 키보드 숫자 입력으로 선수를 빠르게 선택할 수 있는 오버레이 위젯
class JerseyNumberSearch extends StatefulWidget {
  const JerseyNumberSearch({
    super.key,
    required this.homePlayers,
    required this.awayPlayers,
    required this.onPlayerSelected,
    required this.onDismiss,
    this.homeTeamColor,
    this.awayTeamColor,
    this.initialNumber,
  });

  final List<PlayerWithStats> homePlayers;
  final List<PlayerWithStats> awayPlayers;
  final void Function(PlayerWithStats player, bool isHome) onPlayerSelected;
  final VoidCallback onDismiss;
  final Color? homeTeamColor;
  final Color? awayTeamColor;
  final String? initialNumber;

  @override
  State<JerseyNumberSearch> createState() => _JerseyNumberSearchState();
}

class _JerseyNumberSearchState extends State<JerseyNumberSearch> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  List<_SearchResult> _results = [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNumber ?? '');
    _searchPlayers(_controller.text);

    // 자동 포커스
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _searchPlayers(String query) {
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }

    final results = <_SearchResult>[];

    // 홈팀 검색
    for (final player in widget.homePlayers) {
      final number = player.player.jerseyNumber?.toString() ?? '';
      if (number.startsWith(query)) {
        results.add(_SearchResult(player: player, isHome: true));
      }
    }

    // 원정팀 검색
    for (final player in widget.awayPlayers) {
      final number = player.player.jerseyNumber?.toString() ?? '';
      if (number.startsWith(query)) {
        results.add(_SearchResult(player: player, isHome: false));
      }
    }

    // 정확한 매칭을 우선 정렬
    results.sort((a, b) {
      final aNumber = a.player.player.jerseyNumber?.toString() ?? '';
      final bNumber = b.player.player.jerseyNumber?.toString() ?? '';
      final aExact = aNumber == query;
      final bExact = bNumber == query;
      if (aExact && !bExact) return -1;
      if (!aExact && bExact) return 1;
      return aNumber.compareTo(bNumber);
    });

    setState(() => _results = results);

    // 정확히 일치하는 선수가 1명이면 자동 선택
    if (results.length == 1) {
      final exactMatch = results.first;
      final number = exactMatch.player.player.jerseyNumber?.toString() ?? '';
      if (number == query) {
        _selectPlayer(exactMatch);
      }
    }
  }

  void _selectPlayer(_SearchResult result) {
    HapticFeedback.selectionClick();
    widget.onPlayerSelected(result.player, result.isHome);
  }

  void _handleKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        widget.onDismiss();
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (_results.isNotEmpty) {
          _selectPlayer(_results.first);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeColor = widget.homeTeamColor ?? AppTheme.homeTeamColor;
    final awayColor = widget.awayTeamColor ?? AppTheme.awayTeamColor;

    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: _handleKey,
      child: GestureDetector(
        onTap: widget.onDismiss,
        child: Container(
          color: Colors.black54,
          child: Center(
            child: GestureDetector(
              onTap: () {}, // 내부 탭 이벤트 전파 방지
              child: Container(
                width: 320,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 제목
                    Row(
                      children: [
                        const Icon(Icons.search, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          '등번호로 선수 검색',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: widget.onDismiss,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 입력 필드
                    TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: '#',
                        hintStyle: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).hintColor,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                      onChanged: _searchPlayers,
                      onSubmitted: (_) {
                        if (_results.isNotEmpty) {
                          _selectPlayer(_results.first);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // 검색 결과
                    if (_results.isEmpty && _controller.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          '선수를 찾을 수 없습니다',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                      )
                    else if (_results.isNotEmpty)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _results.length,
                          itemBuilder: (context, index) {
                            final result = _results[index];
                            final player = result.player;
                            final color = result.isHome ? homeColor : awayColor;

                            return InkWell(
                              onTap: () => _selectPlayer(result),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    left: BorderSide(
                                      color: color,
                                      width: 4,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // 등번호
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${player.player.jerseyNumber ?? '-'}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // 이름
                                    Expanded(
                                      child: Text(
                                        player.player.userName,
                                        style: Theme.of(context).textTheme.bodyLarge,
                                      ),
                                    ),
                                    // 팀 표시
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        result.isHome ? '홈' : '원정',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: color,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    // 힌트
                    const SizedBox(height: 12),
                    Text(
                      '숫자 입력 후 Enter 또는 선수 탭',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchResult {
  final PlayerWithStats player;
  final bool isHome;

  _SearchResult({required this.player, required this.isHome});
}
