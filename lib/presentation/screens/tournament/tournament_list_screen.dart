import 'dart:ui';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/bdr_design_system.dart';
import '../../../data/database/database.dart';
import '../../../di/providers.dart';
import '../../../domain/models/auth_models.dart';
import '../../providers/auth_provider.dart';

class TournamentListScreen extends ConsumerWidget {
  const TournamentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final authState = ref.watch(authProvider);
    final tournamentsAsync = ref.watch(myTournamentsProvider);

    return Scaffold(
      backgroundColor: DS.bg,
      appBar: AppBar(
        backgroundColor: DS.bg,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  colors: [DS.homeRed, DS.awayBlue],
                ),
              ),
              child: Center(
                child: Text('B',
                    style: DSText.bebasSmall(color: Colors.white, size: 16)),
              ),
            ),
            const SizedBox(width: 10),
            Text('내 대회',
                style: DSText.jakartaBold(color: DS.textPrimary, size: 17)),
          ],
        ),
        actions: [
          IconButton(
            icon:
                const Icon(Icons.refresh_rounded, color: DS.textSecondary, size: 22),
            tooltip: '새로고침',
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.invalidate(myTournamentsProvider);
            },
          ),
          PopupMenuButton<String>(
            icon: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: DS.glassFillMid,
                border: Border.all(color: DS.glassBorder),
              ),
              child: Center(
                child: Text(
                  (user?.displayNameOrEmail ?? '?')[0].toUpperCase(),
                  style: DSText.jakartaButton(color: DS.textPrimary, size: 13),
                ),
              ),
            ),
            tooltip: user?.displayNameOrEmail ?? '사용자',
            color: DS.elevated,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DS.radiusSm)),
            onSelected: (value) {
              if (value == 'logout') {
                _showLogoutDialog(context, ref);
              } else if (value == 'token_connect') {
                context.go('/connect');
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.displayNameOrEmail ?? '',
                        style: DSText.jakartaBold(
                            color: DS.textPrimary, size: 13)),
                    Text(user?.email ?? '',
                        style: DSText.jakartaLabel(
                            color: DS.textSecondary, size: 11)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'token_connect',
                child: Row(
                  children: [
                    const Icon(Icons.qr_code_rounded,
                        size: 18, color: DS.textSecondary),
                    const SizedBox(width: 10),
                    Text('토큰으로 연결',
                        style: DSText.jakartaBody(
                            color: DS.textPrimary, size: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout_rounded,
                        size: 18, color: DS.error),
                    const SizedBox(width: 10),
                    Text('로그아웃',
                        style:
                            DSText.jakartaBody(color: DS.error, size: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: kDebugMode && authState.isDevMode
          ? FloatingActionButton.extended(
              onPressed: () => _createDemoDataAndNavigate(context, ref),
              backgroundColor: DS.gold,
              icon: const Icon(Icons.play_arrow_rounded, color: DS.bg),
              label: Text('[DEV] 테스트',
                  style: DSText.jakartaButton(color: DS.bg, size: 12)),
            )
          : null,
      body: RefreshIndicator(
        color: DS.gold,
        backgroundColor: DS.surface,
        onRefresh: () async => ref.invalidate(myTournamentsProvider),
        child: tournamentsAsync.when(
          loading: () => Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: DS.textHint,
              strokeCap: StrokeCap.round,
            ),
          ),
          error: (error, stack) => _buildErrorView(context, ref, error),
          data: (tournaments) {
            if (tournaments.isEmpty) {
              return _buildEmptyView(context);
            }

            final recordable = tournaments
                .where((t) => t.canRecord && t.canEdit)
                .toList()
              ..sort((a, b) {
                if (a.status == 'in_progress' && b.status != 'in_progress') {
                  return -1;
                }
                if (b.status == 'in_progress' && a.status != 'in_progress') {
                  return 1;
                }
                if (a.status == 'registration_open' &&
                    b.status != 'registration_open') {
                  return -1;
                }
                if (b.status == 'registration_open' &&
                    a.status != 'registration_open') {
                  return 1;
                }
                final aDate = a.startDate ?? DateTime(2099);
                final bDate = b.startDate ?? DateTime(2099);
                return aDate.compareTo(bDate);
              });
            final others = tournaments
                .where((t) => !t.canRecord || !t.canEdit)
                .toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                if (kDebugMode && authState.isDevMode) ...[
                  _DevTestButton(
                      onTap: () =>
                          _createDemoDataAndNavigate(context, ref)),
                  const SizedBox(height: 16),
                ],
                if (recordable.isNotEmpty) ...[
                  _SectionHeader(
                    title: '기록 가능',
                    icon: Icons.sports_basketball_rounded,
                    count: recordable.length,
                    accentColor: DS.success,
                  ),
                  const SizedBox(height: 10),
                  ...List.generate(recordable.length, (i) {
                    return SlideInItem(
                      delay: Duration(milliseconds: i * 60),
                      child: _TournamentCard(
                        tournament: recordable[i],
                        enabled: true,
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                ],
                if (others.isNotEmpty) ...[
                  _SectionHeader(
                    title: '기타 대회',
                    icon: Icons.folder_outlined,
                    count: others.length,
                    accentColor: DS.textHint,
                  ),
                  const SizedBox(height: 10),
                  ...others.map((t) =>
                      _TournamentCard(tournament: t, enabled: false)),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyView(BuildContext context) {
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
            Text('등록된 대회가 없습니다',
                style: DSText.jakartaBold(color: DS.textSecondary, size: 16)),
            const SizedBox(height: 8),
            Text(
              'BDR 웹사이트에서 대회를 만들거나\n관리자로 초대받으세요.',
              style: DSText.jakartaBody(color: DS.textHint, size: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TapScaleButton(
              onTap: () => context.go('/connect'),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: DS.glassFill,
                  borderRadius: BorderRadius.circular(DS.radiusSm),
                  border: Border.all(color: DS.glassBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.qr_code_rounded,
                        color: DS.textSecondary, size: 18),
                    const SizedBox(width: 8),
                    Text('토큰으로 연결',
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

  Widget _buildErrorView(
      BuildContext context, WidgetRef ref, Object error) {
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
            Text('대회 목록을 불러올 수 없습니다',
                style: DSText.jakartaBold(color: DS.textPrimary, size: 15)),
            const SizedBox(height: 8),
            Text(
              '네트워크 연결을 확인하고 다시 시도해 주세요.',
              style: DSText.jakartaBody(color: DS.textSecondary, size: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TapScaleButton(
              onTap: () => ref.invalidate(myTournamentsProvider),
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

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DS.elevated,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DS.radiusMd)),
        title: Text('로그아웃',
            style: DSText.jakartaBold(color: DS.textPrimary, size: 16)),
        content: Text('정말 로그아웃하시겠습니까?',
            style: DSText.jakartaBody(color: DS.textSecondary, size: 14)),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(),
            child: Text('취소',
                style: DSText.jakartaButton(
                    color: DS.textSecondary, size: 13)),
          ),
          TextButton(
            onPressed: () async {
              ctx.pop();
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            child: Text('로그아웃',
                style: DSText.jakartaButton(color: DS.error, size: 13)),
          ),
        ],
      ),
    );
  }

  Future<void> _createDemoDataAndNavigate(
      BuildContext context, WidgetRef ref) async {
    final db = ref.read(databaseProvider);

    await db.tournamentDao.saveTournament(LocalTournamentsCompanion.insert(
      id: 'demo-tournament',
      name: '데모 대회',
      status: 'in_progress',
      gameRulesJson: '{"quarters": 4, "minutes_per_quarter": 10}',
      apiToken: 'demo-token',
      syncedAt: DateTime.now(),
    ));

    await db.tournamentDao.saveTeam(LocalTournamentTeamsCompanion.insert(
      id: const Value(1001),
      tournamentId: 'demo-tournament',
      teamId: 1001,
      teamName: '오렌지 팀',
      primaryColor: const Value('#F97316'),
      syncedAt: DateTime.now(),
    ));

    await db.tournamentDao.saveTeam(LocalTournamentTeamsCompanion.insert(
      id: const Value(1002),
      tournamentId: 'demo-tournament',
      teamId: 1002,
      teamName: '에메랄드 팀',
      primaryColor: const Value('#10B981'),
      syncedAt: DateTime.now(),
    ));

    for (int i = 0; i < 10; i++) {
      await db.tournamentDao.savePlayer(LocalTournamentPlayersCompanion.insert(
        id: Value(2001 + i),
        tournamentTeamId: 1001,
        userName: '홈선수${i + 1}',
        jerseyNumber: Value(i + 1),
        position: Value(i < 5 ? 'G' : 'F'),
        role: 'player',
        isStarter: Value(i < 5),
        isActive: const Value(true),
        syncedAt: DateTime.now(),
      ));
    }

    for (int i = 0; i < 10; i++) {
      await db.tournamentDao.savePlayer(LocalTournamentPlayersCompanion.insert(
        id: Value(2101 + i),
        tournamentTeamId: 1002,
        userName: '원정선수${i + 1}',
        jerseyNumber: Value(i + 11),
        position: Value(i < 5 ? 'G' : 'F'),
        role: 'player',
        isStarter: Value(i < 5),
        isActive: const Value(true),
        syncedAt: DateTime.now(),
      ));
    }

    await db.matchDao.saveMatch(LocalMatchesCompanion.insert(
      id: const Value(9001),
      localUuid: 'demo-match-001',
      tournamentId: 'demo-tournament',
      homeTeamId: 1001,
      awayTeamId: 1002,
      homeTeamName: '오렌지 팀',
      awayTeamName: '에메랄드 팀',
      roundName: const Value('1라운드'),
      status: const Value('in_progress'),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    ref.read(currentTournamentIdProvider.notifier).state = 'demo-tournament';

    if (context.mounted) {
      context.go('/recorder/matches/9001/record', extra: {
        'tournamentId': 'demo-tournament',
        'homeTeamId': 1001,
        'awayTeamId': 1002,
        'homeTeamName': '오렌지 팀',
        'awayTeamName': '에메랄드 팀',
      });
    }
  }
}

// ─── Subwidgets ────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.count,
    required this.accentColor,
  });

  final String title;
  final IconData icon;
  final int count;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: accentColor),
        const SizedBox(width: 8),
        Text(title,
            style: DSText.jakartaLabel(color: DS.textSecondary, size: 12)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '$count',
            style: DSText.jakartaLabel(color: accentColor, size: 10),
          ),
        ),
      ],
    );
  }
}

class _TournamentCard extends StatelessWidget {
  const _TournamentCard({
    required this.tournament,
    this.enabled = true,
  });

  final MyTournamentInfo tournament;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isLive = tournament.status == 'in_progress';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TapScaleButton(
        onTap: enabled
            ? () {
                HapticFeedback.lightImpact();
                context.go(
                  '/confirm/${tournament.id}',
                  extra: tournament.apiToken,
                );
              }
            : null,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DS.radiusSm),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: enabled ? DS.glassFillMid : DS.glassFill,
                borderRadius: BorderRadius.circular(DS.radiusSm),
                border: Border.all(
                  color: isLive
                      ? DS.success.withValues(alpha: 0.4)
                      : DS.glassBorder,
                ),
                boxShadow: isLive
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
                  // Top row: badges
                  Row(
                    children: [
                      _StatusBadge(
                          status: tournament.status,
                          text: tournament.statusText),
                      const SizedBox(width: 6),
                      _RoleBadge(
                          role: tournament.role, text: tournament.roleText),
                      if (isLive) ...[
                        const SizedBox(width: 6),
                        const PulsingDot(color: DS.success, size: 6),
                      ],
                      const Spacer(),
                      if (enabled)
                        const Icon(Icons.chevron_right_rounded,
                            color: DS.textHint, size: 20),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Tournament name
                  Text(
                    tournament.name,
                    style: DSText.jakartaBold(
                      color: enabled ? DS.textPrimary : DS.textSecondary,
                      size: 15,
                    ),
                  ),
                  if (tournament.seriesName != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      tournament.seriesName!,
                      style: DSText.jakartaBody(
                          color: DS.textHint, size: 12),
                    ),
                  ],
                  const SizedBox(height: 12),

                  // Info chips
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      if (tournament.startDate != null)
                        _InfoChip(
                          icon: Icons.calendar_today_rounded,
                          text: DateFormat('yyyy.MM.dd')
                              .format(tournament.startDate!),
                        ),
                      if (tournament.venueName != null)
                        _InfoChip(
                          icon: Icons.location_on_outlined,
                          text: tournament.venueName!,
                        ),
                      _InfoChip(
                        icon: Icons.groups_outlined,
                        text: '${tournament.teamCount}팀',
                      ),
                      _InfoChip(
                        icon: Icons.sports_score_outlined,
                        text: '${tournament.matchCount}경기',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.text});
  final String status;
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'in_progress' => DS.success,
      'registration_open' || 'registration_closed' => DS.awayBlue,
      'completed' => DS.textSecondary,
      'cancelled' => DS.error,
      _ => DS.gold,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(DS.radiusXs),
      ),
      child: Text(text,
          style: DSText.jakartaLabel(color: color, size: 10)),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role, required this.text});
  final String role;
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = switch (role) {
      'organizer' || 'owner' => DS.gold,
      'admin' => DS.awayBlue,
      _ => DS.textHint,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(DS.radiusXs),
      ),
      child: Text(text,
          style: DSText.jakartaLabel(color: color, size: 10)),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: DS.textHint),
        const SizedBox(width: 4),
        Text(text,
            style: DSText.jakartaBody(color: DS.textSecondary, size: 11)),
      ],
    );
  }
}

class _DevTestButton extends StatelessWidget {
  const _DevTestButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TapScaleButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: DS.gold.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(DS.radiusSm),
          border: Border.all(color: DS.gold.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_arrow_rounded, color: DS.gold, size: 20),
            const SizedBox(width: 8),
            Text('[DEV] 기록 화면 테스트',
                style: DSText.jakartaButton(color: DS.gold, size: 14)),
          ],
        ),
      ),
    );
  }
}
