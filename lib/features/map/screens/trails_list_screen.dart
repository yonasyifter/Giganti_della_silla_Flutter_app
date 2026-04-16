import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../preferences/providers/user_preferences_provider.dart';
import '../providers/trail_recommender_provider.dart';
import '../providers/trail_selection_provider.dart';

/// Full-screen trail browser — shows all trails fetched from Firebase.
/// Tapping a trail shows its detail sheet and allows starting it.
class TrailsListScreen extends ConsumerStatefulWidget {
  const TrailsListScreen({super.key});

  @override
  ConsumerState<TrailsListScreen> createState() => _TrailsListScreenState();
}

class _TrailsListScreenState extends ConsumerState<TrailsListScreen> {
  String _filter = 'all'; // 'all' | 'easy' | 'moderate' | 'hard'

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(preferencesProvider.notifier).load();
      final prefs = ref.read(preferencesProvider).valueOrNull;
      if (prefs != null) {
        ref.read(trailRecommenderProvider.notifier).load(prefs);
      }
    });
  }

  Color _diffColor(String diff) {
    switch (diff.toLowerCase()) {
      case 'easy':     return AppColors.easy;
      case 'moderate': return AppColors.moderate;
      case 'hard':     return AppColors.hard;
      default:         return AppColors.textSecondary;
    }
  }

  IconData _diffIcon(String diff) {
    switch (diff.toLowerCase()) {
      case 'easy':     return Icons.trending_flat;
      case 'moderate': return Icons.trending_up;
      case 'hard':     return Icons.terrain;
      default:         return Icons.terrain;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final trailState = ref.watch(trailRecommenderProvider);
    final selection = ref.watch(trailSelectionProvider);
    final recommended = trailState.recommended;

    final filtered = _filter == 'all'
        ? trailState.allTrails
        : trailState.allTrails.where((t) => t.difficulty == _filter).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: AppColors.background,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(l.trails,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 18)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.primaryDark, AppColors.background],
                  ),
                ),
              ),
            ),
          ),

          // ── Active Trail Banner ──────────────────────────────────────────
          if (selection.hasActiveTrail)
            SliverToBoxAdapter(
              child: _ActiveTrailBanner(
                trail: selection.activeTrail!,
                progress: selection.progressPercent,
                onViewMap: () => context.go('/map'),
                onClear: () => ref.read(trailSelectionProvider.notifier).clearTrail(),
              ),
            ),

          // ── Recommended Trail ────────────────────────────────────────────
          if (recommended != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome,
                            color: AppColors.accent, size: 16),
                        const SizedBox(width: 6),
                        Text(l.recommendedTrail,
                            style: const TextStyle(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _TrailCard(
                      trail: recommended,
                      isRecommended: true,
                      isActive: selection.activeTrail?.docId == recommended.docId,
                      onTap: () => _showTrailDetail(context, recommended),
                    ),
                  ],
                ),
              ),
            ),

          // ── Filter Chips ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.allTrails,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                            label: 'All',
                            isActive: _filter == 'all',
                            color: AppColors.primaryLight,
                            onTap: () => setState(() => _filter = 'all')),
                        const SizedBox(width: 8),
                        _FilterChip(
                            label: '🟢 Easy',
                            isActive: _filter == 'easy',
                            color: AppColors.easy,
                            onTap: () => setState(() => _filter = 'easy')),
                        const SizedBox(width: 8),
                        _FilterChip(
                            label: '🟡 Moderate',
                            isActive: _filter == 'moderate',
                            color: AppColors.moderate,
                            onTap: () => setState(() => _filter = 'moderate')),
                        const SizedBox(width: 8),
                        _FilterChip(
                            label: '🔴 Hard',
                            isActive: _filter == 'hard',
                            color: AppColors.hard,
                            onTap: () => setState(() => _filter = 'hard')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Loading ──────────────────────────────────────────────────────
          if (trailState.isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primaryLight),
              ),
            ),

          // ── Trail Cards ──────────────────────────────────────────────────
          if (!trailState.isLoading)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final t = filtered[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TrailCard(
                        trail: t,
                        isRecommended: false,
                        isActive: selection.activeTrail?.docId == t.docId,
                        onTap: () => _showTrailDetail(context, t),
                      ),
                    );
                  },
                  childCount: filtered.length,
                ),
              ),
            ),

          // ── Offline notice ───────────────────────────────────────────────
          if (trailState.error != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off,
                        color: AppColors.warning, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(trailState.error!,
                          style: const TextStyle(
                              color: AppColors.warning, fontSize: 11)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Trail Detail Bottom Sheet ─────────────────────────────────────────────
  void _showTrailDetail(BuildContext context, TrailModel trail) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _TrailDetailSheet(
        trail: trail,
        onStartTrail: () {
          Navigator.pop(context);
          ref.read(trailSelectionProvider.notifier).selectTrail(trail);
          // Navigate to map with trail active
          context.go('/map');
        },
        onViewMap: () {
          Navigator.pop(context);
          context.go('/map');
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TRAIL CARD
// ─────────────────────────────────────────────────────────────────────────────
class _TrailCard extends StatelessWidget {
  final TrailModel trail;
  final bool isRecommended;
  final bool isActive;
  final VoidCallback onTap;

  const _TrailCard({
    required this.trail,
    required this.isRecommended,
    required this.isActive,
    required this.onTap,
  });

  Color _diffColor(String diff) {
    switch (diff.toLowerCase()) {
      case 'easy':     return AppColors.easy;
      case 'moderate': return AppColors.moderate;
      case 'hard':     return AppColors.hard;
      default:         return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final diffColor = _diffColor(trail.difficulty);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? AppColors.primaryLight
                : isRecommended
                    ? AppColors.accent.withValues(alpha: 0.5)
                    : AppColors.surfaceLight,
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive
              ? [BoxShadow(
                  color: AppColors.primaryLight.withValues(alpha: 0.2),
                  blurRadius: 12)]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: diffColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.terrain, color: diffColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(trail.name,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: diffColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                trail.difficulty.toUpperCase(),
                                style: TextStyle(
                                    color: diffColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(trail.environmentEmoji,
                                style: const TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            Text(trail.interestEmoji,
                                style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('ACTIVE',
                          style: TextStyle(
                              color: AppColors.primaryLight,
                              fontSize: 9,
                              fontWeight: FontWeight.w700)),
                    ),
                  const Icon(Icons.chevron_right,
                      color: AppColors.textHint, size: 20),
                ],
              ),
            ),

            // Stats row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  _StatChip(Icons.straighten, trail.distance),
                  const SizedBox(width: 12),
                  _StatChip(Icons.timer_outlined, trail.duration),
                  const SizedBox(width: 12),
                  _StatChip(Icons.trending_up, trail.elevation),
                  if (trail.hasPolyline) ...[
                    const SizedBox(width: 12),
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.route, color: AppColors.primaryLight, size: 12),
                        SizedBox(width: 3),
                        Text('Map',
                            style: TextStyle(
                                color: AppColors.primaryLight, fontSize: 11)),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Description
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: Text(trail.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TRAIL DETAIL BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _TrailDetailSheet extends StatelessWidget {
  final TrailModel trail;
  final VoidCallback onStartTrail;
  final VoidCallback onViewMap;

  const _TrailDetailSheet({
    required this.trail,
    required this.onStartTrail,
    required this.onViewMap,
  });

  Color _diffColor(String diff) {
    switch (diff.toLowerCase()) {
      case 'easy':     return AppColors.easy;
      case 'moderate': return AppColors.moderate;
      case 'hard':     return AppColors.hard;
      default:         return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final diffColor = _diffColor(trail.difficulty);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      maxChildSize: 0.92,
      builder: (_, controller) => SingleChildScrollView(
        controller: controller,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                      color: AppColors.textHint,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),

              // Title + difficulty badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(trail.name,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 20)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: diffColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${trail.difficultyEmoji} ${trail.difficulty.toUpperCase()}',
                      style: TextStyle(
                          color: diffColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Stats grid
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _DetailStat(Icons.straighten, 'Distance', trail.distance),
                    _vDivider(),
                    _DetailStat(Icons.timer_outlined, 'Duration', trail.duration),
                    _vDivider(),
                    _DetailStat(Icons.trending_up, 'Elevation', trail.elevation),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Environment & Interest tags
              Row(
                children: [
                  _TagBadge(trail.environmentEmoji,
                      trail.environment == 'quiet' ? 'Quiet' : 'Bright'),
                  const SizedBox(width: 8),
                  _TagBadge(trail.interestEmoji,
                      trail.interest == 'history' ? 'History' : 'Botany'),
                  if (trail.hasPolyline) ...[
                    const SizedBox(width: 8),
                    _TagBadge('🗺️', 'Trail Map'),
                  ],
                ],
              ),

              const SizedBox(height: 16),

              // Description
              Text('About this trail',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
              const SizedBox(height: 6),
              Text(trail.description,
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.5)),

              // Features
              if (trail.features.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Highlights',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: trail.features
                      .map((f) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.primaryDark.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: AppColors.primaryLight.withValues(alpha: 0.3)),
                            ),
                            child: Text(f,
                                style: const TextStyle(
                                    color: AppColors.primaryLight,
                                    fontSize: 11)),
                          ))
                      .toList(),
                ),
              ],

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onViewMap,
                      icon: const Icon(Icons.map_outlined, size: 18),
                      label: const Text('View on Map'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryLight,
                        side: const BorderSide(color: AppColors.primaryLight),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onStartTrail,
                      icon: const Icon(Icons.play_arrow_rounded, size: 20),
                      label: const Text('Start Trail'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _vDivider() => Container(
      width: 1, height: 40, color: AppColors.surfaceLight);
}

// ─────────────────────────────────────────────────────────────────────────────
//  ACTIVE TRAIL BANNER
// ─────────────────────────────────────────────────────────────────────────────
class _ActiveTrailBanner extends StatelessWidget {
  final TrailModel trail;
  final int progress;
  final VoidCallback onViewMap;
  final VoidCallback onClear;

  const _ActiveTrailBanner({
    required this.trail,
    required this.progress,
    required this.onViewMap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_walk,
                  color: Colors.white, size: 18),
              const SizedBox(width: 6),
              const Text('Active Trail',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
              const Spacer(),
              GestureDetector(
                onTap: onViewMap,
                child: const Row(
                  children: [
                    Icon(Icons.map_outlined, color: Colors.white70, size: 14),
                    SizedBox(width: 4),
                    Text('Map',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close,
                    color: Colors.white54, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(trail.name,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15)),
          const SizedBox(height: 10),
          // Progress bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.accentLight),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text('$progress%',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HELPER WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 12),
        const SizedBox(width: 3),
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }
}

class _DetailStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailStat(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryLight, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 14)),
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 10)),
      ],
    );
  }
}

class _TagBadge extends StatelessWidget {
  final String emoji;
  final String label;
  const _TagBadge(this.emoji, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Text('$emoji $label',
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 11)),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label,
      required this.isActive,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.2) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isActive ? color : AppColors.surfaceLight),
        ),
        child: Text(label,
            style: TextStyle(
                color: isActive ? color : AppColors.textSecondary,
                fontSize: 12,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }
}
