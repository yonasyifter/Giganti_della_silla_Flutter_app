import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/app_constants.dart';

class TrackingState {
  final Position? position;
  final bool isTracking;
  final bool isInsidePark;
  final bool hasPermission;

  const TrackingState({
    this.position,
    this.isTracking = false,
    this.isInsidePark = false,
    this.hasPermission = false,
  });

  TrackingState copyWith({
    Position? position,
    bool? isTracking,
    bool? isInsidePark,
    bool? hasPermission,
  }) {
    return TrackingState(
      position: position ?? this.position,
      isTracking: isTracking ?? this.isTracking,
      isInsidePark: isInsidePark ?? this.isInsidePark,
      hasPermission: hasPermission ?? this.hasPermission,
    );
  }
}

class TrackingNotifier extends StateNotifier<TrackingState> {
  final LocationService _locationService;
  final ApiService _api;
  StreamSubscription? _sub;
  Timer? _pingTimer;

  TrackingNotifier(this._locationService, this._api)
      : super(const TrackingState());

  Future<void> startTracking() async {
    final hasPermission = await _locationService.requestPermissions();
    if (!hasPermission) {
      state = state.copyWith(hasPermission: false);
      return;
    }
    state = state.copyWith(hasPermission: true, isTracking: true);

    // Get initial position
    final pos = await _locationService.getCurrentPosition();
    if (pos != null) _updatePosition(pos);

    // Start streaming
    _locationService.startTracking();
    _sub = _locationService.positionStream.listen(_updatePosition);

    // Ping admin every 30 seconds when inside park
    _pingTimer = Timer.periodic(
      const Duration(seconds: AppConstants.locationUpdateIntervalSec),
      (_) => _pingAdmin(),
    );
  }

  void _updatePosition(Position pos) {
    final insidePark = _locationService.isInsidePark(pos.latitude, pos.longitude);
    state = state.copyWith(
      position: pos,
      isInsidePark: insidePark,
    );
    if (insidePark) _pingAdmin();
  }

  Future<void> _pingAdmin() async {
    final pos = state.position;
    if (pos == null || !state.isInsidePark) return;
    await _api.sendLocationPing(lat: pos.latitude, lng: pos.longitude);
  }

  void stopTracking() {
    _sub?.cancel();
    _pingTimer?.cancel();
    _locationService.stopTracking();
    state = state.copyWith(isTracking: false);
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}

final trackingProvider =
    StateNotifierProvider<TrackingNotifier, TrackingState>((ref) {
  return TrackingNotifier(LocationService(), ApiService());
});
