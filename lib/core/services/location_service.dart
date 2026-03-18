import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import '../constants/app_constants.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamController<Position>? _positionController;
  StreamSubscription<Position>? _positionSubscription;

  Stream<Position> get positionStream =>
      _positionController?.stream ?? const Stream.empty();

  Future<bool> requestPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  Future<Position?> getCurrentPosition() async {
    final hasPermission = await requestPermissions();
    if (!hasPermission) return null;
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      return null;
    }
  }

  void startTracking() {
    _positionController ??= StreamController<Position>.broadcast();

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
      timeLimit: Duration(seconds: AppConstants.locationUpdateIntervalSec),
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (position) => _positionController?.add(position),
      onError: (_) {},
    );
  }

  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  /// Check if a given lat/lng is within the park boundaries
  bool isInsidePark(double lat, double lng) {
    return lat >= AppConstants.parkSouthLat &&
        lat <= AppConstants.parkNorthLat &&
        lng >= AppConstants.parkWestLng &&
        lng <= AppConstants.parkEastLng;
  }

  /// Distance in km between two coordinates (Haversine)
  double distanceKm(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLng = _deg2rad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180);

  void dispose() {
    stopTracking();
    _positionController?.close();
    _positionController = null;
  }
}
