import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../tracking/providers/tracking_provider.dart';
import '../../weather/providers/weather_provider.dart';
import '../../preferences/providers/user_preferences_provider.dart';
import '../providers/trail_recommender_provider.dart';
import '../providers/trail_selection_provider.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _mapController = MapController();
  TrailModel? _previewTrail;   // Trail shown in the detail card (not yet started)
  String _activeLayer = 'trails';

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      // Load preferences → then load trails from Firebase
      // Only load if not already loaded (avoid duplicate Firestore calls)
      final currentState = ref.read(trailRecommenderProvider);
      if (currentState.allTrails.isEmpty) {
        await ref.read(preferencesProvider.notifier).load();
        final prefs = ref.read(preferencesProvider).valueOrNull;
        if (prefs != null) {
          await ref.read(trailRecommenderProvider.notifier).load(prefs);
        }
      }
      // Start GPS tracking (safe to call multiple times — provider guards duplicates)
      ref.read(trackingProvider.notifier).startTracking();
    });
  }

  Color _difficultyColor(String diff) {
    switch (diff.toLowerCase()) {
      case 'easy':     return AppColors.easy;
      case 'moderate': return AppColors.moderate;
      case 'hard':     return AppColors.hard;
      case 'expert':   return AppColors.expert;
      default:         return AppColors.textSecondary;
    }
  }

  // ── Fit map to a trail's polyline bounds ──────────────────────────────────
  void _fitTrailBounds(TrailModel trail) {
    if (!trail.hasPolyline) {
      _mapController.move(LatLng(trail.latitude, trail.longitude), 14);
      return;
    }
    final lats = trail.coords.map((c) => c.latitude);
    final lngs = trail.coords.map((c) => c.longitude);
    final sw = LatLng(lats.reduce((a, b) => a < b ? a : b),
        lngs.reduce((a, b) => a < b ? a : b));
    final ne = LatLng(lats.reduce((a, b) => a > b ? a : b),
        lngs.reduce((a, b) => a > b ? a : b));
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(sw, ne),
        padding: const EdgeInsets.all(48),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l        = AppLocalizations.of(context);
    final tracking = ref.watch(trackingProvider);
    final weather  = ref.watch(weatherProvider);
    final trailState = ref.watch(trailRecommenderProvider);
    final selection  = ref.watch(trailSelectionProvider);
    final trails     = trailState.allTrails;

    // When hiker position updates, recalculate trail progress
    if (tracking.position != null && selection.hasActiveTrail) {
      Future.microtask(() {
        ref.read(trailSelectionProvider.notifier).updateProgress(
          tracking.position!.latitude,
          tracking.position!.longitude,
        );
      });
    }

    // Determine which trail to draw as the active polyline
    final activeTrail = selection.activeTrail;

    return Scaffold(
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(
                AppConstants.parkCenterLat,
                AppConstants.parkCenterLng,
              ),
              initialZoom: 12,
              minZoom: 8,
              maxZoom: 18,
            ),
            children: [
              // Base tile layer (OpenStreetMap)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.hikesilla.app',
              ),

              // Park boundary overlay
              PolygonLayer(
                polygons: [
                  Polygon(
                    points: const [
                      LatLng(AppConstants.parkNorthLat, AppConstants.parkWestLng),
                      LatLng(AppConstants.parkNorthLat, AppConstants.parkEastLng),
                      LatLng(AppConstants.parkSouthLat, AppConstants.parkEastLng),
                      LatLng(AppConstants.parkSouthLat, AppConstants.parkWestLng),
                    ],
                    color: AppColors.parkBoundary.withValues(alpha: 0.08),
                    borderColor: AppColors.parkBoundary.withValues(alpha: 0.5),
                    borderStrokeWidth: 2,
                  ),
                ],
              ),

              // ── All trail polylines (dimmed) when trails layer is active ──
              if (_activeLayer == 'trails')
                PolylineLayer(
                  polylines: trails
                      .where((t) => t.hasPolyline)
                      .map((t) {
                        final isActive = activeTrail?.docId == t.docId;
                        final isPreview = _previewTrail?.docId == t.docId;
                        return Polyline(
                          points: t.coords,
                          strokeWidth: isActive ? 6.0 : (isPreview ? 4.5 : 2.5),
                          color: isActive
                              ? _difficultyColor(t.difficulty)
                              : isPreview
                                  ? _difficultyColor(t.difficulty).withValues(alpha: 0.7)
                                  : _difficultyColor(t.difficulty).withValues(alpha: 0.3),
                          borderStrokeWidth: isActive ? 2.0 : 0,
                          borderColor: Colors.white.withValues(alpha: 0.4),
                        );
                      })
                      .toList(),
                ),

              // ── Active trail start / end markers ─────────────────────────
              if (_activeLayer == 'trails' && activeTrail != null && activeTrail.hasPolyline)
                MarkerLayer(
                  markers: [
                    // Start marker (green dot)
                    Marker(
                      point: activeTrail.coords.first,
                      width: 32,
                      height: 32,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.easy,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                                color: AppColors.easy.withValues(alpha: 0.5),
                                blurRadius: 8)
                          ],
                        ),
                        child: const Icon(Icons.play_arrow,
                            color: Colors.white, size: 16),
                      ),
                    ),
                    // End marker (flag)
                    Marker(
                      point: activeTrail.coords.last,
                      width: 32,
                      height: 32,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accent,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.5),
                                blurRadius: 8)
                          ],
                        ),
                        child: const Icon(Icons.flag,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),

              // ── Trail markers (tap to preview) ────────────────────────────
              if (_activeLayer == 'trails')
                MarkerLayer(
                  markers: trails.map((t) {
                    final isActive = activeTrail?.docId == t.docId;
                    return Marker(
                      point: LatLng(t.latitude, t.longitude),
                      width: isActive ? 52 : 44,
                      height: isActive ? 52 : 44,
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _previewTrail = t);
                          _fitTrailBounds(t);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _difficultyColor(t.difficulty),
                            border: isActive
                                ? Border.all(color: Colors.white, width: 3)
                                : null,
                            boxShadow: [
                              BoxShadow(
                                  color: _difficultyColor(t.difficulty)
                                      .withValues(alpha: 0.5),
                                  blurRadius: isActive ? 16 : 8,
                                  spreadRadius: isActive ? 2 : 0)
                            ],
                          ),
                          child: Icon(
                            isActive ? Icons.directions_walk : Icons.terrain,
                            color: Colors.white,
                            size: isActive ? 26 : 22,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

              // ── Sensor weather zone markers ───────────────────────────────
              if (_activeLayer == 'weather')
                MarkerLayer(
                  markers: weather.zones.map((z) {
                    return Marker(
                      point: LatLng(
                          (z['lat'] as num).toDouble(),
                          (z['lng'] as num).toDouble()),
                      width: 60,
                      height: 60,
                      child: _WeatherZoneMarker(zone: z),
                    );
                  }).toList(),
                ),

              // ── Hiker live position ───────────────────────────────────────
              if (tracking.position != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(tracking.position!.latitude,
                          tracking.position!.longitude),
                      width: 50,
                      height: 50,
                      child: _HikerMarker(isInsidePark: tracking.isInsidePark),
                    ),
                  ],
                ),
            ],
          ),

          // ── Top header ───────────────────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16, right: 16, bottom: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background.withValues(alpha: 0.95),
                    AppColors.background.withValues(alpha: 0),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.mapTitle,
                          style: Theme.of(context).textTheme.headlineMedium),
                      if (trailState.error != null)
                        Row(
                          children: [
                            const Icon(Icons.wifi_off,
                                color: AppColors.warning, size: 11),
                            const SizedBox(width: 4),
                            Text('Offline mode',
                                style: const TextStyle(
                                    color: AppColors.warning, fontSize: 10)),
                          ],
                        ),
                    ],
                  ),
                  const Spacer(),
                  // Center on hiker
                  if (tracking.position != null)
                    _MapButton(
                      icon: Icons.my_location,
                      onTap: () => _mapController.move(
                        LatLng(tracking.position!.latitude,
                            tracking.position!.longitude),
                        15,
                      ),
                    ),
                  const SizedBox(width: 8),
                  // Reset view
                  _MapButton(
                    icon: Icons.fit_screen,
                    onTap: () => _mapController.move(
                      const LatLng(AppConstants.parkCenterLat,
                          AppConstants.parkCenterLng),
                      12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Layer switcher ───────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 70,
            right: 16,
            child: Column(
              children: [
                _LayerButton(
                    label: 'Trails',
                    icon: Icons.terrain,
                    isActive: _activeLayer == 'trails',
                    onTap: () => setState(() {
                          _activeLayer = 'trails';
                          _previewTrail = null;
                        })),
                const SizedBox(height: 8),
                _LayerButton(
                    label: 'Weather',
                    icon: Icons.cloud,
                    isActive: _activeLayer == 'weather',
                    onTap: () => setState(() {
                          _activeLayer = 'weather';
                          _previewTrail = null;
                        })),
                const SizedBox(height: 8),
                _LayerButton(
                    label: 'Hiker',
                    icon: Icons.person_pin_circle,
                    isActive: _activeLayer == 'hiker',
                    onTap: () => setState(() {
                          _activeLayer = 'hiker';
                          _previewTrail = null;
                        })),
              ],
            ),
          ),

          // ── Loading indicator ────────────────────────────────────────────
          if (trailState.isLoading)
            const Center(
                child: CircularProgressIndicator(
                    color: AppColors.primaryLight)),

          // ── Active trail progress bar (top strip) ────────────────────────
          if (selection.hasActiveTrail)
            Positioned(
              top: MediaQuery.of(context).padding.top + 56,
              left: 16,
              right: 72,
              child: _TrailProgressStrip(
                trail: selection.activeTrail!,
                progress: selection.progressPercent,
                onFitTrail: () => _fitTrailBounds(selection.activeTrail!),
              ),
            ),

          // ── Trail preview card (when user taps a marker) ─────────────────
          if (_previewTrail != null)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: _TrailPreviewCard(
                trail: _previewTrail!,
                isActive: activeTrail?.docId == _previewTrail!.docId,
                diffColor: _difficultyColor(_previewTrail!.difficulty),
                onClose: () => setState(() => _previewTrail = null),
                onStartTrail: () {
                  ref
                      .read(trailSelectionProvider.notifier)
                      .selectTrail(_previewTrail!);
                  setState(() => _previewTrail = null);
                },
                onViewAllTrails: _showTrailList,
              ),
            ),

          // ── "View All Trails" button (when no preview) ───────────────────
          if (_previewTrail == null)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: _showTrailList,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: AppColors.primaryLight),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 10)
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.list,
                                color: AppColors.primaryLight, size: 18),
                            SizedBox(width: 8),
                            Text('View All Trails',
                                style: TextStyle(
                                    color: AppColors.primaryLight,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                    if (selection.hasActiveTrail) ...[
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => _fitTrailBounds(selection.activeTrail!),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.4),
                                  blurRadius: 10)
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.route,
                                  color: Colors.white, size: 16),
                              SizedBox(width: 6),
                              Text('My Trail',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Trail list bottom sheet ───────────────────────────────────────────────
  void _showTrailList() {
    context.push('/trails');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TRAIL PROGRESS STRIP
// ─────────────────────────────────────────────────────────────────────────────
class _TrailProgressStrip extends StatelessWidget {
  final TrailModel trail;
  final int progress;
  final VoidCallback onFitTrail;

  const _TrailProgressStrip({
    required this.trail,
    required this.progress,
    required this.onFitTrail,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onFitTrail,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.2), blurRadius: 8)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.directions_walk,
                    color: AppColors.primaryLight, size: 13),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(trail.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
                Text('$progress%',
                    style: const TextStyle(
                        color: AppColors.primaryLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress / 100,
                backgroundColor: AppColors.surfaceLight,
                valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primaryLight),
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TRAIL PREVIEW CARD  (shown when user taps a trail marker)
// ─────────────────────────────────────────────────────────────────────────────
class _TrailPreviewCard extends StatelessWidget {
  final TrailModel trail;
  final bool isActive;
  final Color diffColor;
  final VoidCallback onClose;
  final VoidCallback onStartTrail;
  final VoidCallback onViewAllTrails;

  const _TrailPreviewCard({
    required this.trail,
    required this.isActive,
    required this.diffColor,
    required this.onClose,
    required this.onStartTrail,
    required this.onViewAllTrails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isActive
                ? AppColors.primaryLight
                : AppColors.surfaceLight,
            width: isActive ? 2 : 1),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.3), blurRadius: 20)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: diffColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.terrain, color: diffColor, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trail.name,
                        style: Theme.of(context).textTheme.titleLarge),
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
                        const SizedBox(width: 8),
                        const Icon(Icons.straighten,
                            color: AppColors.textSecondary, size: 12),
                        Text(' ${trail.distance}',
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11)),
                        const SizedBox(width: 6),
                        const Icon(Icons.timer,
                            color: AppColors.textSecondary, size: 12),
                        Text(' ${trail.duration}',
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close,
                    color: AppColors.textHint, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Description
          Text(trail.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),

          // Polyline indicator
          if (trail.hasPolyline) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.route,
                    color: AppColors.primaryLight, size: 13),
                const SizedBox(width: 4),
                Text('Trail route available on map',
                    style: const TextStyle(
                        color: AppColors.primaryLight, fontSize: 11)),
              ],
            ),
          ],

          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onViewAllTrails,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.surfaceLight),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('All Trails',
                      style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: isActive ? null : onStartTrail,
                  icon: Icon(
                      isActive
                          ? Icons.check_circle_outline
                          : Icons.play_arrow_rounded,
                      size: 16),
                  label: Text(
                      isActive ? 'Active Trail' : 'Start Trail',
                      style: const TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isActive ? AppColors.surfaceLight : AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                    minimumSize: Size.zero,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HIKER MARKER
// ─────────────────────────────────────────────────────────────────────────────
class _HikerMarker extends StatelessWidget {
  final bool isInsidePark;
  const _HikerMarker({required this.isInsidePark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isInsidePark ? AppColors.hikersPosition : AppColors.info,
        boxShadow: [
          BoxShadow(
            color: (isInsidePark ? AppColors.hikersPosition : AppColors.info)
                .withValues(alpha: 0.6),
            blurRadius: 14,
            spreadRadius: 4,
          ),
        ],
      ),
      child: const Icon(Icons.person, color: Colors.white, size: 26),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  WEATHER ZONE MARKER
// ─────────────────────────────────────────────────────────────────────────────
class _WeatherZoneMarker extends StatelessWidget {
  final Map<String, dynamic> zone;
  const _WeatherZoneMarker({required this.zone});

  @override
  Widget build(BuildContext context) {
    final temp =
        (zone['temperature'] as num?)?.toStringAsFixed(1) ?? '—';
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary),
      ),
      padding: const EdgeInsets.all(4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sensors,
              color: AppColors.primaryLight, size: 14),
          Text('$temp°C',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  MAP BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MapButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Icon(icon, color: AppColors.primaryLight, size: 20),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  LAYER BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class _LayerButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  const _LayerButton(
      {required this.label,
      required this.icon,
      required this.isActive,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isActive
                  ? AppColors.primaryLight
                  : AppColors.surfaceLight),
        ),
        child: Icon(icon,
            color: isActive ? Colors.white : AppColors.textSecondary,
            size: 22),
      ),
    );
  }
}
