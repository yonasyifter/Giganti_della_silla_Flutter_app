import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../map/providers/trail_recommender_provider.dart';
import '../../map/providers/trail_selection_provider.dart';
import '../providers/user_preferences_provider.dart';

/// Full-screen trail picker shown immediately after saving preferences.
/// Displays all trails that match the user's saved preferences as rich cards.
/// Tapping a card selects the trail and opens the map.
class RecommendedTrailsScreen extends ConsumerWidget {
  const RecommendedTrailsScreen({super.key});

  Color _diffColor(String diff) {
    switch (diff.toLowerCase()) {
      case 'easy':     return AppColors.easy;
      case 'moderate': return AppColors.moderate;
      case 'hard':     return AppColors.hard;
      default:         return AppColors.expert;
    }
  }

  List<TrailModel> _matchingTrails(
      List<TrailModel> all, String difficulty, String noise, String interest) {
    final env = noise == 'very_quiet' ? 'quiet' : 'bright';
    final exact = all
        .where((t) =>
            t.difficulty == difficulty &&
            t.environment == env &&
            t.interest == interest)
        .toList();
    if (exact.isNotEmpty) return exact;
    final byDiff = all.where((t) => t.difficulty == difficulty).toList();
    if (byDiff.isNotEmpty) return byDiff;
    return all;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trailsState = ref.watch(trailRecommenderProvider);
    final prefsAsync  = ref.watch(preferencesProvider);
    final prefs       = prefsAsync.valueOrNull;

    final matched = prefs == null
        ? trailsState.allTrails
        : _matchingTrails(
            trailsState.allTrails,
            prefs.difficulty,
            prefs.noise,
            prefs.interest,
          );

    final env         = prefs == null ? 'bright' : (prefs.noise == 'very_quiet' ? 'quiet' : 'bright');
    final previewKey  = prefs == null ? '—' : '${prefs.difficulty}_${env}_${prefs.interest}';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(children: [
                  // Back button — use go() not pop() since we arrived via go()
                  GestureDetector(
                    onTap: () => context.go('/preferences'),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.surfaceLight),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new,
                          color: AppColors.textPrimary, size: 16),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Trails For You',
                            style: Theme.of(context).textTheme.headlineMedium),
                        Text('Based on your preferences · $previewKey',
                            style: const TextStyle(
                                color: AppColors.textHint, fontSize: 11)),
                      ],
                    ),
                  ),
                  // Trail count badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.primaryLight
                              .withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      '${matched.length} trail${matched.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.w700,
                          fontSize: 13),
                    ),
                  ),
                ]),
              ),

              // ── Preference summary chips ───────────────────────────────────
              if (prefs != null) ...[
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(children: [
                    _PrefChip(
                        icon: Icons.terrain,
                        label: prefs.difficulty.toUpperCase()),
                    const SizedBox(width: 8),
                    _PrefChip(
                        icon: Icons.volume_down,
                        label: prefs.noise.replaceAll('_', ' ')),
                    const SizedBox(width: 8),
                    _PrefChip(
                        icon: Icons.interests,
                        label: prefs.interest),
                    const SizedBox(width: 8),
                    _PrefChip(
                        icon: Icons.show_chart,
                        label: prefs.slope),
                    const SizedBox(width: 8),
                    _PrefChip(
                        icon: Icons.straighten,
                        label: prefs.width),
                  ]),
                ),
              ],

              const SizedBox(height: 12),

              // ── Instruction banner ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.35)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.touch_app,
                        color: AppColors.accent, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                          'Select a trail below to open it on the map and start your hike.',
                          style: TextStyle(
                              color: AppColors.accentLight,
                              fontSize: 12)),
                    ),
                  ]),
                ),
              ),

              const SizedBox(height: 12),

              // ── Trail cards list ──────────────────────────────────────────
              Expanded(
                child: trailsState.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primaryLight))
                    : matched.isEmpty
                        ? _EmptyState(onBack: () => context.go('/preferences'))
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            itemCount: matched.length,
                            itemBuilder: (ctx, i) => _TrailCard(
                              trail: matched[i],
                              diffColor: _diffColor(matched[i].difficulty),
                              isRecommended: trailsState.recommended?.docId ==
                                  matched[i].docId,
                              onTap: () {
                                ref
                                    .read(trailSelectionProvider.notifier)
                                    .selectTrail(matched[i]);
                                context.go('/map');
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Preference chip ───────────────────────────────────────────────────────────

class _PrefChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _PrefChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: AppColors.primaryLight, size: 13),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

// ── Trail Card ────────────────────────────────────────────────────────────────

class _TrailCard extends StatelessWidget {
  final TrailModel trail;
  final Color diffColor;
  final bool isRecommended;
  final VoidCallback onTap;

  const _TrailCard({
    required this.trail,
    required this.diffColor,
    required this.isRecommended,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.surface,
              AppColors.surfaceLight.withValues(alpha: 0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isRecommended
                ? AppColors.primaryLight.withValues(alpha: 0.7)
                : AppColors.surfaceLight,
            width: isRecommended ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top banner ──────────────────────────────────────────────────
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: diffColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(children: [
                // Difficulty icon circle
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: diffColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: diffColor.withValues(alpha: 0.5), width: 2),
                  ),
                  child: Center(
                    child: Text(trail.difficultyEmoji,
                        style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Recommended badge
                      if (isRecommended) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star_rounded,
                                    color: AppColors.primaryLight,
                                    size: 11),
                                SizedBox(width: 3),
                                Text('Best Match',
                                    style: TextStyle(
                                        color: AppColors.primaryLight,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700)),
                              ]),
                        ),
                      ],
                      Text(trail.name,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      const SizedBox(height: 4),
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: diffColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(trail.difficulty.toUpperCase(),
                              style: TextStyle(
                                  color: diffColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                            '${trail.environmentEmoji} ${trail.environment}  '
                            '${trail.interestEmoji} ${trail.interest}',
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11)),
                      ]),
                    ],
                  ),
                ),
                // Arrow
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_forward_ios_rounded,
                      color: AppColors.primaryLight, size: 16),
                ),
              ]),
            ),

            // ── Body ────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  Text(trail.description,
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.5)),
                  const SizedBox(height: 14),

                  // Stats row
                  Row(children: [
                    _StatBox(
                        icon: Icons.straighten,
                        label: 'Distance',
                        value: trail.distance),
                    const SizedBox(width: 8),
                    _StatBox(
                        icon: Icons.timer_outlined,
                        label: 'Duration',
                        value: trail.duration),
                    const SizedBox(width: 8),
                    _StatBox(
                        icon: Icons.trending_up,
                        label: 'Elevation',
                        value: trail.elevation),
                  ]),
                  const SizedBox(height: 14),

                  // Feature tags
                  if (trail.features.isNotEmpty) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: trail.features
                          .map((f) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: AppColors.primaryLight
                                          .withValues(alpha: 0.25)),
                                ),
                                child: Text(f,
                                    style: const TextStyle(
                                        color: AppColors.primaryLight,
                                        fontSize: 11)),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Route availability + CTA button
                  Row(children: [
                    if (trail.hasPolyline) ...[
                      const Icon(Icons.route,
                          color: AppColors.easy, size: 14),
                      const SizedBox(width: 4),
                      const Text('Route on map',
                          style: TextStyle(
                              color: AppColors.easy, fontSize: 11)),
                      const Spacer(),
                    ] else
                      const Spacer(),
                    // Start button
                    ElevatedButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.play_arrow_rounded,
                          size: 18, color: Colors.white),
                      label: const Text('Start Hike',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat Box ──────────────────────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatBox(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Column(children: [
          Icon(icon, color: AppColors.primaryLight, size: 16),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textHint, fontSize: 9)),
        ]),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onBack;
  const _EmptyState({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.hiking,
                color: AppColors.textHint, size: 64),
            const SizedBox(height: 16),
            const Text('No trails match your preferences yet.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text(
                'Try adjusting your difficulty, noise, or interest settings.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.tune, size: 18),
              label: const Text('Adjust Preferences'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
