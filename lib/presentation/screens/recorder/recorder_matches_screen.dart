import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/bdr_design_system.dart';
import '../../../di/providers.dart';

// ─── Provider ────────────────────────────────────────────────────────────────

final recorderMatchesProvider = FutureProvider<List<dynamic>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final result = await apiClient.getRecorderMatches();
  if (result.isSuccess) {
    return result.data!;
  }
  throw Exception(result.error);
});

// ─── Screen ──────────────────────────────────────────────────────────────────

class RecorderMatchesScreen extends ConsumerWidget {
  const RecorderMatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(recorderMatchesProvider);

    return Scaffold(
      backgroundColor: DS.bg,
      appBar: AppBar(
        backgroundColor: DS.bg,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.assignment_rounded, color: DS.gold, size: 20),
            const SizedBox(width: 8),
            Text('배정 경기',
                style: DSText.jakartaBold(color: DS.textPrimary, size: 17)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: DS.textSecondary, size: 22),
            tooltip: '새로고침',
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.invalidate(recorderMatchesProvider);
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: matchesAsync.when(
        data: (matches) => _MatchesList(matches: matches, ref: ref),
        loading: () => Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: DS.textHint,
            strokeCap: StrokeCap.round,
          ),
        ),
        error: (error, _) => _ErrorView(
          onRetry: () => ref.invalidate(recorderMatchesProvider),
        ),
      ),
    );
  }
}

// ─── Widgets ─────────────────────────────────────────────────────────────────

class _MatchesList extends StatelessWidget {
  const _MatchesList({required this.matches, required this.ref});

  final List<dynamic> matches;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DS.glassFill,
                  border: Border.all(color: DS.glassBorder),
                ),
                child: const Icon(
                  Icons.sports_basketball_outlined,
                  size: 36,
                  color: DS.textHint,
                ),
              ),
              const SizedBox(height: 20),
              Text('배정된 경기가 없습니다',
                  style: DSText.jakartaBold(
                      color: DS.textSecondary, size: 16)),
              const SizedBox(height: 8),
              Text(
                '예정 또는 진행 중인 경기가 나타납니다',
                style: DSText.jakartaBody(color: DS.textHint, size: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Separate in-progress and scheduled
    final castMatches = matches.cast<Map<String, dynamic>>();
    final inProgress =
        castMatches.where((m) => m['status'] == 'in_progress').toList();
    final scheduled =
        castMatches.where((m) => m['status'] == 'scheduled').toList();
    final other = castMatches
        .where((m) =>
            m['status'] != 'in_progress' && m['status'] != 'scheduled')
        .toList();

    return RefreshIndicator(
      color: DS.gold,
      backgroundColor: DS.surface,
      onRefresh: () async {
        ref.invalidate(recorderMatchesProvider);
        await Future.delayed(const Duration(milliseconds: 300));
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (inProgress.isNotEmpty) ...[
            _SectionLabel(
              text: '진행 중',
              icon: Icons.play_circle_filled_rounded,
              color: DS.success,
              count: inProgress.length,
            ),
            const SizedBox(height: 8),
            ...List.generate(inProgress.length, (i) => SlideInItem(
              delay: Duration(milliseconds: i * 80),
              child: _MatchCard(match: inProgress[i]),
            )),
            const SizedBox(height: 20),
          ],
          if (scheduled.isNotEmpty) ...[
            _SectionLabel(
              text: '예정',
              icon: Icons.schedule_rounded,
              color: DS.awayBlue,
              count: scheduled.length,
            ),
            const SizedBox(height: 8),
            ...List.generate(scheduled.length, (i) => SlideInItem(
              delay: Duration(
                  milliseconds:
                      (inProgress.length + i) * 80),
              child: _MatchCard(match: scheduled[i]),
            )),
            const SizedBox(height: 20),
          ],
          if (other.isNotEmpty) ...[
            _SectionLabel(
              text: '기타',
              icon: Icons.history_rounded,
              color: DS.textHint,
              count: other.length,
            ),
            const SizedBox(height: 8),
            ...other.map((m) => _MatchCard(match: m)),
          ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.text,
    required this.icon,
    required this.color,
    required this.count,
  });

  final String text;
  final IconData icon;
  final Color color;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(text,
            style: DSText.jakartaLabel(color: DS.textSecondary, size: 11)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child:
              Text('$count', style: DSText.jakartaLabel(color: color, size: 9)),
        ),
      ],
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match});

  final Map<String, dynamic> match;

  @override
  Widget build(BuildContext context) {
    final matchId = match['id'] as int? ?? 0;
    final tournamentId = match['tournament_id'] as String? ?? '';
    final homeTeamId = match['home_team_id'] as int? ??
        (match['home_team']?['id'] as int?) ??
        0;
    final awayTeamId = match['away_team_id'] as int? ??
        (match['away_team']?['id'] as int?) ??
        0;
    final homeTeamName = match['home_team_name'] as String? ??
        match['home_team']?['name'] as String? ??
        'HOME';
    final awayTeamName = match['away_team_name'] as String? ??
        match['away_team']?['name'] as String? ??
        'AWAY';
    final status = match['status'] as String? ?? 'scheduled';
    final scheduledAt = _parseDate(match['scheduled_at']);
    final homeScore = match['home_score'] as int?;
    final awayScore = match['away_score'] as int?;
    final roundName = match['round_name'] as String?;

    final isInProgress = status == 'in_progress';
    final isScheduled = status == 'scheduled';
    final canTap = isInProgress || isScheduled;

    void navigateToRecord() {
      if (!canTap) return;
      HapticFeedback.mediumImpact();
      context.push(
        '/recorder/matches/$matchId/record',
        extra: {
          'tournamentId': tournamentId,
          'homeTeamId': homeTeamId,
          'awayTeamId': awayTeamId,
          'homeTeamName': homeTeamName,
          'awayTeamName': awayTeamName,
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TapScaleButton(
        onTap: canTap ? navigateToRecord : null,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DS.radiusSm),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DS.glassFillMid,
                borderRadius: BorderRadius.circular(DS.radiusSm),
                border: Border.all(
                  color: isInProgress
                      ? DS.success.withValues(alpha: 0.4)
                      : DS.glassBorder,
                ),
                boxShadow: isInProgress
                    ? [
                        BoxShadow(
                          color: DS.success.withValues(alpha: 0.08),
                          blurRadius: 20,
                          spreadRadius: -2,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top: round + status + time
                  Row(
                    children: [
                      if (roundName != null) ...[
                        Text(roundName,
                            style: DSText.jakartaLabel(
                                color: DS.textHint, size: 10)),
                        Container(
                          width: 3,
                          height: 3,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: DS.textHint,
                          ),
                        ),
                      ],
                      _StatusChip(status: status),
                      if (isInProgress) ...[
                        const SizedBox(width: 6),
                        const PulsingDot(color: DS.success, size: 6),
                      ],
                      const Spacer(),
                      if (scheduledAt != null)
                        Text(
                          _formatDateTime(scheduledAt),
                          style: DSText.jakartaLabel(
                              color: DS.textHint, size: 10),
                        ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Teams + Score
                  Row(
                    children: [
                      // Home team
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: DS.homeRed.withValues(alpha: 0.15),
                                border: Border.all(
                                  color: DS.homeRed.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  homeTeamName.isNotEmpty
                                      ? homeTeamName[0]
                                      : 'H',
                                  style: DSText.bebasSmall(
                                      color: DS.homeRed, size: 18),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              homeTeamName,
                              style: DSText.jakartaBold(
                                  color: DS.textPrimary, size: 13),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Score / VS
                      Container(
                        width: 80,
                        alignment: Alignment.center,
                        child: isInProgress &&
                                homeScore != null &&
                                awayScore != null
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('$homeScore',
                                      style: DSText.bebasMedium(
                                          color: DS.homeRed, size: 28)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6),
                                    child: Text(':',
                                        style: DSText.bebasMedium(
                                            color: DS.textHint, size: 22)),
                                  ),
                                  Text('$awayScore',
                                      style: DSText.bebasMedium(
                                          color: DS.awayBlue, size: 28)),
                                ],
                              )
                            : Text(
                                'VS',
                                style: DSText.bebasSmall(
                                    color: DS.textHint, size: 18),
                              ),
                      ),

                      // Away team
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: DS.awayBlue.withValues(alpha: 0.15),
                                border: Border.all(
                                  color: DS.awayBlue.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  awayTeamName.isNotEmpty
                                      ? awayTeamName[0]
                                      : 'A',
                                  style: DSText.bebasSmall(
                                      color: DS.awayBlue, size: 18),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              awayTeamName,
                              style: DSText.jakartaBold(
                                  color: DS.textPrimary, size: 13),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Action button
                  if (canTap)
                    Container(
                      width: double.infinity,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isInProgress
                            ? DS.success.withValues(alpha: 0.15)
                            : DS.awayBlue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(DS.radiusXs),
                        border: Border.all(
                          color: isInProgress
                              ? DS.success.withValues(alpha: 0.3)
                              : DS.awayBlue.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isInProgress
                                ? Icons.sports_basketball_rounded
                                : Icons.play_arrow_rounded,
                            color: isInProgress ? DS.success : DS.awayBlue,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isInProgress ? '기록 계속' : '기록 시작',
                            style: DSText.jakartaButton(
                              color:
                                  isInProgress ? DS.success : DS.awayBlue,
                              size: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.month}/${local.day} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'in_progress' => ('진행 중', DS.success),
      'scheduled' => ('예정', DS.awayBlue),
      'completed' => ('완료', DS.textSecondary),
      'cancelled' => ('취소', DS.error),
      _ => (status, DS.textHint),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: DSText.jakartaLabel(color: color, size: 10)),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: DS.error.withValues(alpha: 0.1),
              ),
              child: const Icon(Icons.wifi_off_rounded,
                  size: 28, color: DS.error),
            ),
            const SizedBox(height: 16),
            Text('경기 목록을 불러올 수 없습니다',
                style: DSText.jakartaBold(color: DS.textPrimary, size: 15)),
            const SizedBox(height: 8),
            Text(
              '네트워크 연결을 확인하고 다시 시도해 주세요.',
              style: DSText.jakartaBody(color: DS.textSecondary, size: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TapScaleButton(
              onTap: () {
                HapticFeedback.lightImpact();
                onRetry();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: DS.glassFillMid,
                  borderRadius: BorderRadius.circular(DS.radiusSm),
                  border: Border.all(color: DS.glassBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.refresh_rounded,
                        color: DS.textSecondary, size: 18),
                    const SizedBox(width: 8),
                    Text('다시 시도',
                        style: DSText.jakartaButton(
                            color: DS.textSecondary, size: 13)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
