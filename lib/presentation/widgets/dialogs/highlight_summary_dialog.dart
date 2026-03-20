import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/game_highlight_service.dart';
import '../../../core/services/llm_summary_service.dart';

/// 하이라이트 요약 다이얼로그 표시
Future<void> showHighlightSummaryDialog({
  required BuildContext context,
  required GameHighlights highlights,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => HighlightSummaryDialog(highlights: highlights),
  );
}

/// 경기 하이라이트 AI 요약 다이얼로그
class HighlightSummaryDialog extends ConsumerStatefulWidget {
  const HighlightSummaryDialog({
    super.key,
    required this.highlights,
  });

  final GameHighlights highlights;

  @override
  ConsumerState<HighlightSummaryDialog> createState() =>
      _HighlightSummaryDialogState();
}

class _HighlightSummaryDialogState
    extends ConsumerState<HighlightSummaryDialog> {
  LLMSummaryResult? _summaryResult;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 캐시 확인
      final cache = ref.read(llmSummaryCacheProvider);
      final cached = cache[widget.highlights.matchId];

      if (cached != null) {
        setState(() {
          _summaryResult = cached;
          _isLoading = false;
        });
        return;
      }

      // LLM 요약 생성
      final service = ref.read(llmSummaryServiceProvider);
      final result = await service.generateSummary(widget.highlights);

      // 캐시에 저장
      ref.read(llmSummaryCacheProvider.notifier).cacheResult(result);

      setState(() {
        _summaryResult = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 드래그 핸들
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 헤더
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI 경기 요약',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        _summaryResult?.source == LLMSummarySource.openAI
                            ? 'GPT-4o-mini로 생성'
                            : '로컬 요약',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFF2D2D44)),

          // 콘텐츠
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 스코어 카드
                  _buildScoreCard(),

                  const SizedBox(height: 20),

                  // AI 요약
                  _buildSummarySection(),

                  const SizedBox(height: 20),

                  // 주요 하이라이트
                  _buildHighlightsSection(),

                  const SizedBox(height: 20),

                  // 공유 버튼들
                  _buildShareButtons(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard() {
    final h = widget.highlights;
    final isHomeWin = h.finalScore.home > h.finalScore.away;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2D2D44),
            const Color(0xFF1E1E32).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF3D3D5C),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // 홈팀
          Expanded(
            child: Column(
              children: [
                Text(
                  h.homeTeamName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isHomeWin ? Colors.white : Colors.grey[400],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${h.finalScore.home}',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: isHomeWin ? const Color(0xFF10B981) : Colors.grey[400],
                  ),
                ),
                if (isHomeWin)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'WIN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // VS
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'VS',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),

          // 어웨이팀
          Expanded(
            child: Column(
              children: [
                Text(
                  h.awayTeamName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: !isHomeWin ? Colors.white : Colors.grey[400],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${h.finalScore.away}',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color:
                        !isHomeWin ? const Color(0xFF10B981) : Colors.grey[400],
                  ),
                ),
                if (!isHomeWin)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'WIN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: Color(0xFF6366F1),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'AI 요약',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[400],
                ),
              ),
              const Spacer(),
              if (_summaryResult != null && !_isLoading)
                GestureDetector(
                  onTap: _loadSummary,
                  child: Icon(
                    Icons.refresh,
                    size: 16,
                    color: Colors.grey[500],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF6366F1),
                ),
              ),
            )
          else if (_error != null)
            Text(
              '요약 생성 실패: $_error',
              style: const TextStyle(color: Colors.red, fontSize: 14),
            )
          else
            Text(
              _summaryResult?.summary ?? '',
              style: const TextStyle(
                fontSize: 15,
                color: Colors.white,
                height: 1.6,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHighlightsSection() {
    final highlights = widget.highlights;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '주요 하이라이트',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[300],
          ),
        ),
        const SizedBox(height: 12),

        // 경기 흐름 통계
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildStatChip(
              icon: Icons.swap_horiz,
              label: '리드 변경',
              value: '${highlights.leadChanges}회',
            ),
            _buildStatChip(
              icon: Icons.trending_up,
              label: '최대 리드',
              value: '+${highlights.maxLead.points}점',
              subtitle: highlights.maxLead.teamName,
            ),
            if (highlights.clutchPlays.isNotEmpty)
              _buildStatChip(
                icon: Icons.local_fire_department,
                label: '클러치',
                value: '${highlights.clutchPlays.length}개',
                color: const Color(0xFFEF4444),
              ),
          ],
        ),

        // 득점 런
        if (highlights.scoringRuns.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            '주요 득점 런',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          ...highlights.scoringRuns.take(3).map((run) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        run.display,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      run.teamName,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[300],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Q${run.startQuarter}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              )),
        ],

        // 개인 하이라이트
        if (highlights.personalHighlights.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            '개인 기록',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          ...highlights.personalHighlights.map((h) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      h.type == PersonalHighlightType.tripleDouble
                          ? Icons.star
                          : h.type == PersonalHighlightType.doubleDouble
                              ? Icons.star_half
                              : Icons.person,
                      color: const Color(0xFFF59E0B),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        h.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[300],
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
    Color color = const Color(0xFF6366F1),
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[400],
                ),
              ),
              Row(
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShareButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '공유하기',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[300],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildShareButton(
                icon: Icons.copy,
                label: '텍스트 복사',
                color: const Color(0xFF6B7280),
                onTap: _copyToClipboard,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildShareButton(
                icon: Icons.share,
                label: '공유',
                color: const Color(0xFF6366F1),
                onTap: _shareText,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShareButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyToClipboard() {
    if (_summaryResult == null) return;

    final h = widget.highlights;
    final text = '''
🏀 ${h.homeTeamName} ${h.finalScore.home} - ${h.finalScore.away} ${h.awayTeamName}

${_summaryResult!.summary}

#BDR #농구
''';

    Clipboard.setData(ClipboardData(text: text));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('클립보드에 복사되었습니다'),
        duration: Duration(seconds: 2),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  void _shareText() {
    // TODO: share_plus 패키지 사용하여 시스템 공유 시트 열기
    _copyToClipboard();
  }
}
