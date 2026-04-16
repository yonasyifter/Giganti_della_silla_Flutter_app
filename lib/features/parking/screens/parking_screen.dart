import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../tracking/providers/tracking_provider.dart';

// ── Parking state ─────────────────────────────────────────────────────────────
class ParkingState {
  final double? carLat;
  final double? carLng;
  final DateTime? savedAt;
  final bool isSaving;

  const ParkingState({
    this.carLat,
    this.carLng,
    this.savedAt,
    this.isSaving = false,
  });

  bool get hasCar => carLat != null && carLng != null;

  ParkingState copyWith({
    double? carLat,
    double? carLng,
    DateTime? savedAt,
    bool? isSaving,
    bool clearCar = false,
  }) {
    return ParkingState(
      carLat: clearCar ? null : (carLat ?? this.carLat),
      carLng: clearCar ? null : (carLng ?? this.carLng),
      savedAt: clearCar ? null : (savedAt ?? this.savedAt),
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

// ── Parking provider ──────────────────────────────────────────────────────────
class ParkingNotifier extends StateNotifier<ParkingState> {
  static const _latKey = 'parking_lat';
  static const _lngKey = 'parking_lng';
  static const _timeKey = 'parking_time';

  ParkingNotifier() : super(const ParkingState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_latKey);
    final lng = prefs.getDouble(_lngKey);
    final timeStr = prefs.getString(_timeKey);
    if (lat != null && lng != null) {
      state = state.copyWith(
        carLat: lat,
        carLng: lng,
        savedAt: timeStr != null ? DateTime.tryParse(timeStr) : null,
      );
    }
  }

  Future<void> saveParkingSpot(double lat, double lng) async {
    state = state.copyWith(isSaving: true);
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_latKey, lat);
    await prefs.setDouble(_lngKey, lng);
    await prefs.setString(_timeKey, now.toIso8601String());
    state = ParkingState(carLat: lat, carLng: lng, savedAt: now);
  }

  Future<void> clearParkingSpot() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_latKey);
    await prefs.remove(_lngKey);
    await prefs.remove(_timeKey);
    state = const ParkingState();
  }
}

final parkingProvider =
    StateNotifierProvider<ParkingNotifier, ParkingState>((_) => ParkingNotifier());

// ── Screen ────────────────────────────────────────────────────────────────────
class ParkingScreen extends ConsumerStatefulWidget {
  const ParkingScreen({super.key});

  @override
  ConsumerState<ParkingScreen> createState() => _ParkingScreenState();
}

class _ParkingScreenState extends ConsumerState<ParkingScreen> {
  final MapController _mapController = MapController();
  bool _mapReady = false;

  @override
  Widget build(BuildContext context) {
    final parking = ref.watch(parkingProvider);
    final tracking = ref.watch(trackingProvider);
    final myPos = tracking.position;

    // Calculate distance to car
    double? distanceToCarM;
    if (parking.hasCar && myPos != null) {
      distanceToCarM = Geolocator.distanceBetween(
        myPos.latitude, myPos.longitude,
        parking.carLat!, parking.carLng!,
      );
    }

    final carLatLng = parking.hasCar
        ? LatLng(parking.carLat!, parking.carLng!)
        : null;
    final myLatLng = myPos != null
        ? LatLng(myPos.latitude, myPos.longitude)
        : null;

    // Default to park center if no GPS
    final mapCenter = carLatLng ??
        myLatLng ??
        const LatLng(39.358, 16.228);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ────────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                decoration: const BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  border: Border(
                      bottom: BorderSide(color: AppColors.surfaceLight)),
                ),
                child: Row(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFF5722).withValues(alpha: 0.15),
                      border: Border.all(
                          color: const Color(0xFFFF5722).withValues(alpha: 0.4)),
                    ),
                    child: const Icon(Icons.local_parking_rounded,
                        color: Color(0xFFFF5722), size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Parking Monitor',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                    Text('Track your car location',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 11)),
                  ]),
                  const Spacer(),
                  if (parking.hasCar)
                    GestureDetector(
                      onTap: () => _confirmClear(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.danger.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                          Icon(Icons.delete_outline,
                              color: AppColors.danger, size: 14),
                          SizedBox(width: 4),
                          Text('Clear',
                              style: TextStyle(
                                  color: AppColors.danger, fontSize: 11)),
                        ]),
                      ),
                    ),
                ]),
              ),

              // ── Map ───────────────────────────────────────────────────────
              Expanded(
                flex: 5,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: mapCenter,
                        initialZoom: 16,
                        onMapReady: () {
                          setState(() => _mapReady = true);
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.hikesilla.app',
                        ),
                        // Line from user to car
                        if (myLatLng != null && carLatLng != null)
                          PolylineLayer(polylines: [
                            Polyline(
                              points: [myLatLng, carLatLng],
                              color: const Color(0xFFFF5722).withValues(alpha: 0.7),
                              strokeWidth: 2.5,
                              isDotted: true,
                            ),
                          ]),
                        MarkerLayer(markers: [
                          // Car marker
                          if (carLatLng != null)
                            Marker(
                              point: carLatLng,
                              width: 48,
                              height: 48,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 36, height: 36,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFFFF5722),
                                    ),
                                    child: const Icon(Icons.directions_car,
                                        color: Colors.white, size: 20),
                                  ),
                                  Container(
                                    width: 2, height: 8,
                                    color: const Color(0xFFFF5722),
                                  ),
                                ],
                              ),
                            ),
                          // User marker
                          if (myLatLng != null)
                            Marker(
                              point: myLatLng,
                              width: 24,
                              height: 24,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primaryLight,
                                  border: Border.all(
                                      color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryLight
                                          .withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ]),
                      ],
                    ),
                    // Fit bounds button
                    if (_mapReady && carLatLng != null && myLatLng != null)
                      Positioned(
                        top: 10, right: 10,
                        child: GestureDetector(
                          onTap: () => _fitBounds(myLatLng, carLatLng),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 4)
                              ],
                            ),
                            child: const Icon(Icons.fit_screen_rounded,
                                color: AppColors.textPrimary, size: 20),
                          ),
                        ),
                      ),
                    // No GPS overlay
                    if (myPos == null)
                      Positioned(
                        top: 10, left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                            Icon(Icons.gps_off_rounded,
                                color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text('GPS unavailable',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 11)),
                          ]),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Bottom panel ──────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  border: Border(top: BorderSide(color: AppColors.surfaceLight)),
                ),
                child: parking.hasCar
                    ? _CarSavedPanel(
                        parking: parking,
                        distanceM: distanceToCarM,
                        onNavigate: () => _navigateToCar(parking),
                      )
                    : _SaveCarPanel(
                        myPos: myPos,
                        isSaving: parking.isSaving,
                        onSave: () => _saveParking(myPos),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _fitBounds(LatLng a, LatLng b) {
    if (!_mapReady) return;
    final bounds = LatLngBounds(a, b);
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)),
    );
  }

  Future<void> _saveParking(dynamic myPos) async {
    if (myPos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GPS not available. Enable location and try again.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    await ref
        .read(parkingProvider.notifier)
        .saveParkingSpot(myPos.latitude, myPos.longitude);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(children: [
            Icon(Icons.local_parking_rounded, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text('Parking spot saved!'),
          ]),
          backgroundColor: Color(0xFFFF5722),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _navigateToCar(ParkingState parking) async {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=${parking.carLat},${parking.carLng}&travelmode=walking';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Clear Parking Spot?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
            'This will remove your saved car location.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(parkingProvider.notifier).clearParkingSpot();
    }
  }
}

// ── Save car panel ────────────────────────────────────────────────────────────
class _SaveCarPanel extends StatelessWidget {
  final dynamic myPos;
  final bool isSaving;
  final VoidCallback onSave;
  const _SaveCarPanel(
      {required this.myPos, required this.isSaving, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Row(children: [
          Icon(Icons.info_outline_rounded,
              color: AppColors.textSecondary, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'No parking spot saved. Park your car and tap the button below to mark its location.',
              style:
                  TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
        ]),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: myPos == null || isSaving ? null : onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5722),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            icon: isSaving
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.local_parking_rounded, size: 20),
            label: Text(
              isSaving ? 'Saving…' : 'Save Parking Spot Here',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Car saved panel ───────────────────────────────────────────────────────────
class _CarSavedPanel extends StatelessWidget {
  final ParkingState parking;
  final double? distanceM;
  final VoidCallback onNavigate;
  const _CarSavedPanel(
      {required this.parking,
      required this.distanceM,
      required this.onNavigate});

  String _formatDistance(double? m) {
    if (m == null) return '—';
    if (m < 1000) return '${m.toStringAsFixed(0)} m away';
    return '${(m / 1000).toStringAsFixed(2)} km away';
  }

  String _formatTime(DateTime? t) {
    if (t == null) return '—';
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Info row
        Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFF5722).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.directions_car,
                color: Color(0xFFFF5722), size: 20),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              _formatDistance(distanceM),
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15),
            ),
            Text(
              'Saved ${_formatTime(parking.savedAt)}',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11),
            ),
          ]),
          const Spacer(),
          // Coordinates badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.surfaceLight),
            ),
            child: Text(
              '${parking.carLat!.toStringAsFixed(4)},\n${parking.carLng!.toStringAsFixed(4)}',
              style: const TextStyle(
                  color: AppColors.textHint, fontSize: 9),
              textAlign: TextAlign.center,
            ),
          ),
        ]),
        const SizedBox(height: 14),
        // Navigate button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onNavigate,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.navigation_rounded, size: 20),
            label: const Text('Navigate to Car',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ),
      ],
    );
  }
}
