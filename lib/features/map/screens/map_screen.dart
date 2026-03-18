import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../tracking/providers/tracking_provider.dart';
import '../../weather/providers/weather_provider.dart';
import '../../preferences/providers/user_preferences_provider.dart';
import '../providers/trail_recommender_provider.dart';


class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _mapController = MapController();
  Map<String, dynamic>? _selectedTrail;
  String _activeLayer = 'trails';

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

  Color _difficultyColor(String diff) {
    switch (diff.toLowerCase()) {
      case 'easy': return AppColors.easy;
      case 'moderate': return AppColors.moderate;
      case 'hard': return AppColors.hard;
      case 'expert': return AppColors.expert;
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tracking = ref.watch(trackingProvider);
    final weather = ref.watch(weatherProvider);
    final trailState = ref.watch(trailRecommenderProvider);
    final trails = trailState.allTrails;

    return Scaffold(
      body: Stack(
        children: [
          // Map
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
              // Base tile layer
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.hikesilla.app',
              ),

              // Park boundary overlay (approximate polygon)
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

              // Sensor weather zone markers
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

              // Trail markers
              if (_activeLayer == 'trails')
                MarkerLayer(
                  markers: trails.map((t) {
                    return Marker(
                      point: LatLng(t.latitude, t.longitude),
                      width: 44,
                      height: 44,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTrail = {
                          'name': t.name,
                          'difficulty': t.difficulty,
                          'distance': t.distance,
                          'duration': t.duration,
                          'description': t.description,
                          'id': [t.id],
                          'latitude': t.latitude,
                          'longitude': t.longitude,
                        }),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _difficultyColor(t.difficulty),
                            boxShadow: [
                              BoxShadow(
                                  color: _difficultyColor(t.difficulty).withValues(alpha: 0.5),
                                  blurRadius: 10)
                            ],
                          ),
                          child: const Icon(Icons.terrain, color: Colors.white, size: 22),
                        ),
                      ),
                    );
                  }).toList(),
                ),

              // Hiker live position
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

          // Top header
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
                  Text('Trail Map',
                      style: Theme.of(context).textTheme.headlineMedium),
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

          // Layer switcher
          Positioned(
            top: MediaQuery.of(context).padding.top + 70,
            right: 16,
            child: Column(
              children: [
                _LayerButton(
                    label: 'Trails',
                    icon: Icons.terrain,
                    isActive: _activeLayer == 'trails',
                    onTap: () => setState(() => _activeLayer = 'trails')),
                const SizedBox(height: 8),
                _LayerButton(
                    label: 'Weather',
                    icon: Icons.cloud,
                    isActive: _activeLayer == 'weather',
                    onTap: () => setState(() => _activeLayer = 'weather')),
                const SizedBox(height: 8),
                _LayerButton(
                    label: 'Hiker',
                    icon: Icons.person_pin_circle,
                    isActive: _activeLayer == 'hiker',
                    onTap: () => setState(() => _activeLayer = 'hiker')),
              ],
            ),
          ),

          // Loading
          if (trailState.isLoading)
            const Center(child: CircularProgressIndicator(color: AppColors.primaryLight)),

          // Selected trail card
          if (_selectedTrail != null)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: _TrailDetailCard(
                trail: _selectedTrail!,
                onClose: () => setState(() => _selectedTrail = null),
                diffColor: _difficultyColor(_selectedTrail!['difficulty'] as String? ?? ''),
              ),
            ),

          // Trail list bottom sheet trigger
          if (_selectedTrail == null)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _showTrailList,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primaryLight),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10)
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.list, color: AppColors.primaryLight, size: 18),
                        SizedBox(width: 8),
                        Text('View All Trails',
                            style: TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showTrailList() {
    final trails = ref.read(trailRecommenderProvider).allTrails;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, controller) => Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                  color: AppColors.textHint, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('All Trails',
                  style: Theme.of(context).textTheme.headlineSmall),
            ),
            const SizedBox(height: 12),
            
            Expanded(
              child: ListView.builder(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: trails.length,
                itemBuilder: (_, i) {
                  final t = trails[i];
                  return ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _difficultyColor(t.difficulty).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.terrain,
                          color: _difficultyColor(t.difficulty), size: 20),
                    ),
                    title: Text(t.name,
                        style: const TextStyle(color: AppColors.textPrimary)),
                    subtitle: Text(
                        '${t.difficulty} · ${t.distance}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        color: AppColors.textHint, size: 14),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _selectedTrail = {
                        'name': t.name,
                        'difficulty': t.difficulty,
                        'distance': t.distance,
                        'duration': t.duration,
                        'description': t.description,
                        'id': [t.id],
                        'latitude': t.latitude,
                        'longitude': t.longitude,
                      });
                      _mapController.move(LatLng(t.latitude, t.longitude), 14);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
            color: (isInsidePark ? AppColors.hikersPosition : AppColors.info).withValues(alpha: 0.6),
            blurRadius: 14,
            spreadRadius: 4,
          ),
        ],
      ),
      child: const Icon(Icons.person, color: Colors.white, size: 26),
    );
  }
}

class _WeatherZoneMarker extends StatelessWidget {
  final Map<String, dynamic> zone;
  const _WeatherZoneMarker({required this.zone});

  @override
  Widget build(BuildContext context) {
    final temp = (zone['temperature'] as num?)?.toStringAsFixed(1) ?? '—';
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
          const Icon(Icons.sensors, color: AppColors.primaryLight, size: 14),
          Text('$temp°C', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

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

class _LayerButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  const _LayerButton({required this.label, required this.icon, required this.isActive, required this.onTap});

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
          border: Border.all(color: isActive ? AppColors.primaryLight : AppColors.surfaceLight),
        ),
        child: Icon(icon, color: isActive ? Colors.white : AppColors.textSecondary, size: 22),
      ),
    );
  }
}

class _TrailDetailCard extends StatelessWidget {
  final Map<String, dynamic> trail;
  final VoidCallback onClose;
  final Color diffColor;

  const _TrailDetailCard({required this.trail, required this.onClose, required this.diffColor});

  @override
  Widget build(BuildContext context) {
    final tags = (trail['id'] as List?)?.cast<String>() ?? [];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceLight),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(trail['name'] as String? ?? '',
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              IconButton(onPressed: onClose, icon: const Icon(Icons.close, color: AppColors.textHint)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: diffColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(trail['difficulty'] as String? ?? '',
                    style: TextStyle(color: diffColor, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.straight, color: AppColors.textSecondary, size: 14),
              Text(' ${trail['distance'] ?? ''}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(width: 8),
              const Icon(Icons.timer, color: AppColors.textSecondary, size: 14),
              Text(' ${trail['duration'] ?? ''}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Text(trail['description'] as String? ?? '',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              children: tags.map((tag) => Chip(
                label: Text(tag, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                backgroundColor: AppColors.backgroundSecondary,
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
