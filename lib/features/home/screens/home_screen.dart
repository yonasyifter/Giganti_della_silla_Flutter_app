import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../../tracking/providers/tracking_provider.dart';
import '../../weather/providers/weather_provider.dart';
import '../../preferences/providers/user_preferences_provider.dart';
import '../../map/providers/trail_recommender_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      ref.read(trackingProvider.notifier).startTracking();
      ref.read(weatherProvider.notifier).loadWeather();
      await ref.read(preferencesProvider.notifier).load();
      final prefs = ref.read(preferencesProvider).valueOrNull;
      if (prefs != null) ref.read(trailRecommenderProvider.notifier).load(prefs);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final auth = ref.watch(authProvider);
    final tracking = ref.watch(trackingProvider);
    final weather = ref.watch(weatherProvider);
    final trails = ref.watch(trailRecommenderProvider);

    ref.listen(preferencesProvider, (_, next) {
      final prefs = next.valueOrNull;
      if (prefs != null) ref.read(trailRecommenderProvider.notifier).load(prefs);
    });

    // Avatar initial: prefer displayName, fall back to email prefix, then '?'
    final displayName = auth.user?.displayName ?? '';
    final email = auth.user?.email ?? '';
    final _nameForInitial = displayName.isNotEmpty
        ? displayName
        : (email.contains('@') ? email.split('@').first : '');
    final initial = _nameForInitial.isNotEmpty
        ? _nameForInitial.substring(0, 1).toUpperCase()
        : '?';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header row ────────────────────────────────────────
                Row(children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${l.hello}, ${displayName.isNotEmpty ? displayName : "Hiker"} 👋',
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 4),
                      Text(l.parkName,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.primaryLight)),
                    ],
                  ),
                  const Spacer(),
                  // ── Profile circle ─────────────────────────────────
                  GestureDetector(
                    onTap: () => _showProfileSheet(context, ref, l, displayName, initial),
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surface,
                        border: Border.all(color: AppColors.primaryLight, width: 2),
                      ),
                      child: Center(
                        child: Text(initial,
                            style: const TextStyle(
                                color: AppColors.primaryLight,
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 24),

                _ParkStatusCard(tracking: tracking, l: l),
                const SizedBox(height: 20),
                _WeatherSummaryCard(weather: weather, l: l),
                const SizedBox(height: 20),

                Text(l.quickActions, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                _QuickActionsGrid(l: l),
                const SizedBox(height: 24),

                // Recommendations header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(l.recommendedTrail,
                          style: Theme.of(context).textTheme.titleLarge),
                      Row(children: [
                        const Icon(Icons.local_fire_department,
                            color: Color(0xFFFF6F00), size: 12),
                        const SizedBox(width: 4),
                        Text(l.fromFirestore,
                            style: const TextStyle(
                                color: AppColors.textHint, fontSize: 10)),
                      ]),
                    ]),
                    TextButton(
                      onPressed: () => context.go('/map'),
                      child: Text(l.allTrails,
                          style: const TextStyle(color: AppColors.primaryLight)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _RecommendedTrails(state: trails, l: l),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showProfileSheet(BuildContext context, WidgetRef ref,
      AppLocalizations l, String displayName, String initial) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Consumer(
        builder: (ctx, ref, _) {
          final auth = ref.watch(authProvider);
          final prefs = ref.watch(preferencesProvider).valueOrNull;
          return Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.textHint,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 24),
              
                  // Avatar
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.primary,
                    child: Text(initial,
                        style: const TextStyle(
                            fontSize: 28,
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 10),
                  Text(auth.user?.displayName ?? '',
                      style: Theme.of(ctx).textTheme.headlineSmall),
                  Text(auth.user?.email ?? '',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                  if (prefs != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${prefs.difficulty.toUpperCase()} · '
                      '${prefs.visitCount} park visit${prefs.visitCount == 1 ? "" : "s"}',
                      style: const TextStyle(
                          color: AppColors.primaryLight, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Divider(color: AppColors.surfaceLight),
              
                  // ── Settings ──────────────────────────────────────────
                  ListTile(
                    leading: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.settings_outlined,
                          color: AppColors.info, size: 18),
                    ),
                    title: Text(l.settings,
                        style: const TextStyle(color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500)),
                    subtitle: Text(l.settingsSubtitle,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11)),
                    trailing: const Icon(Icons.chevron_right,
                        color: AppColors.textHint, size: 20),
                    onTap: () {
                      Navigator.pop(ctx);
                      context.go('/settings');
                    },
                  ),
              
                  // ── Preferences ───────────────────────────────────────
                  ListTile(
                    leading: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.tune,
                          color: AppColors.primaryLight, size: 18),
                    ),
                    title: Text(l.hikerPreferences,
                        style: const TextStyle(color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500)),
                    subtitle: Text(l.prefsSubtitle,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11)),
                    trailing: const Icon(Icons.chevron_right,
                        color: AppColors.textHint, size: 20),
                    onTap: () {
                      Navigator.pop(ctx);
                      context.go('/preferences');
                    },
                  ),
              
                  // ── Logout ────────────────────────────────────────────
                  ListTile(
                    leading: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.logout,
                          color: AppColors.danger, size: 18),
                    ),
                    title: Text(l.logout,
                        style: const TextStyle(color: AppColors.danger,
                            fontWeight: FontWeight.w500)),
                    subtitle: Text(l.logoutSubtitle,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11)),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) context.go('/login');
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Park Status Card ────────────────────────────────────────────────────────
class _ParkStatusCard extends StatelessWidget {
  final dynamic tracking;
  final AppLocalizations l;
  const _ParkStatusCard({required this.tracking, required this.l});

  @override
  Widget build(BuildContext context) {
    final inside = tracking.isInsidePark as bool;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: inside
              ? [AppColors.primaryDark, AppColors.primary]
              : [AppColors.backgroundSecondary, AppColors.surface],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
            color: (inside ? AppColors.primary : Colors.black)
                .withValues(alpha: 0.3),
            blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _StatusPill(inside: inside, l: l),
            const Spacer(),
            const Icon(Icons.landscape, color: Colors.white54, size: 28),
          ]),
          const SizedBox(height: 14),
          Text(inside ? l.youAreHiking : l.readyToHike,
              style: const TextStyle(
                  color: Colors.white, fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(inside ? l.locationShared : l.talkToGuide,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          if (tracking.position != null) ...[
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.location_on, color: Colors.white54, size: 14),
              const SizedBox(width: 4),
              Text(
                '${tracking.position!.latitude.toStringAsFixed(4)}, '
                '${tracking.position!.longitude.toStringAsFixed(4)}',
                style: const TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ]),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool inside;
  final AppLocalizations l;
  const _StatusPill({required this.inside, required this.l});

  @override
  Widget build(BuildContext context) {
    final color = inside ? AppColors.success : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 6),
        Text(inside ? l.insidePark : l.outsidePark,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ── Weather Summary ─────────────────────────────────────────────────────────
class _WeatherSummaryCard extends StatelessWidget {
  final dynamic weather;
  final AppLocalizations l;
  const _WeatherSummaryCard({required this.weather, required this.l});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.liveConditions,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11)),
          const SizedBox(height: 6),
          Row(children: [
            Text(weather.temperatureText,
                style: const TextStyle(
                    color: Colors.white, fontSize: 30,
                    fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Text(weather.conditionEmoji,
                style: const TextStyle(fontSize: 30)),
          ]),
          Text(weather.prediction,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
        ]),
        const Spacer(),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          _Chip(Icons.water_drop,
              '${weather.humidity?.toStringAsFixed(0) ?? '—'}%'),
          const SizedBox(height: 6),
          _Chip(Icons.volume_up,
              '${weather.noise?.toStringAsFixed(0) ?? '—'}dB'),
          const SizedBox(height: 6),
          _Chip(Icons.wb_sunny,
              '${weather.light?.toStringAsFixed(0) ?? '—'}'),
        ]),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: AppColors.textSecondary, size: 13),
      const SizedBox(width: 4),
      Text(label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
    ]);
  }
}

// ── Quick Actions ───────────────────────────────────────────────────────────
class _QuickActionsGrid extends StatelessWidget {
  final AppLocalizations l;
  const _QuickActionsGrid({required this.l});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _Action(Icons.map_rounded, l.navMap, AppColors.primary,
          () => context.go('/map')),
      _Action(Icons.terrain, l.trails, AppColors.easy,
          () => context.push('/trails')),
      _Action(Icons.smart_toy_rounded, l.navAI, AppColors.accent,
          () => context.go('/chatbot')),
      _Action(Icons.cloud_rounded, l.navWeather, AppColors.info,
          () => context.go('/weather')),
      _Action(Icons.sos_rounded, l.emergency, AppColors.danger,
          () => context.push('/sos')),
    ];
    return GridView.count(
      crossAxisCount: 5,
      crossAxisSpacing: 12,
      // Give each cell more height than width so the icon + label fit
      childAspectRatio: 0.78,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: actions,
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _Action(this.icon, this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 10),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Recommended Trails ──────────────────────────────────────────────────────
class _RecommendedTrails extends StatelessWidget {
  final TrailRecommenderState state;
  final AppLocalizations l;
  const _RecommendedTrails({required this.state, required this.l});

  Color _diffColor(String diff) {
    switch (diff.toLowerCase()) {
      case 'easy':     return AppColors.easy;
      case 'moderate': return AppColors.moderate;
      case 'hard':     return AppColors.hard;
      default:         return AppColors.expert;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primaryLight));
    }
    if (state.error != null && state.allTrails.isEmpty) {
      return Text('${l.error}: ${state.error}',
          style: const TextStyle(color: AppColors.danger, fontSize: 12));
    }
    final t = state.recommended;
    if (t == null) {
      return Text(l.noData,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12));
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: _diffColor(t.difficulty).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.terrain, color: _diffColor(t.difficulty), size: 24),
        ),
        title: Text(t.name,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${t.difficulty.toUpperCase()} · ${t.distance} · ${t.duration}',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11),
            ),
            const SizedBox(height: 4),
            Text(t.description,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.textHint, fontSize: 10)),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios,
            color: AppColors.textHint, size: 14),
        onTap: () => context.push('/trails'),
      ),
    );
  }
}
