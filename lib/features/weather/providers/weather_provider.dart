import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// IoT Sensor Reading — mirrors the JSON schema from the Docker API
// ─────────────────────────────────────────────────────────────────────────────
class SensorReading {
  final DateTime time;
  final int deviceId;
  final double temperature;
  final double humidity;
  final double pressure;
  final double light;
  final double noise;
  final double tof;
  final double angle;
  final double accX;
  final double accY;
  final double accZ;
  final double vibrAccX;
  final double vibrAccY;
  final double vibrAccZ;
  final String weatherPrediction;
  final double predictionConfidence;
  final double? latitude;
  final double? longitude;

  const SensorReading({
    required this.time,
    required this.deviceId,
    required this.temperature,
    required this.humidity,
    required this.pressure,
    required this.light,
    required this.noise,
    required this.tof,
    required this.angle,
    required this.accX,
    required this.accY,
    required this.accZ,
    required this.vibrAccX,
    required this.vibrAccY,
    required this.vibrAccZ,
    required this.weatherPrediction,
    required this.predictionConfidence,
    this.latitude,
    this.longitude,
  });

  factory SensorReading.fromJson(Map<String, dynamic> json) {
    return SensorReading(
      time: DateTime.tryParse(json['time'] as String? ?? '') ?? DateTime.now(),
      deviceId: (json['device_id'] as num?)?.toInt() ?? 0,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      humidity: (json['humidity'] as num?)?.toDouble() ?? 0.0,
      pressure: (json['pressure'] as num?)?.toDouble() ?? 0.0,
      light: (json['light'] as num?)?.toDouble() ?? 0.0,
      noise: (json['noise'] as num?)?.toDouble() ?? 0.0,
      tof: (json['tof'] as num?)?.toDouble() ?? 0.0,
      angle: (json['angle'] as num?)?.toDouble() ?? 0.0,
      accX: (json['accX'] as num?)?.toDouble() ?? 0.0,
      accY: (json['accY'] as num?)?.toDouble() ?? 0.0,
      accZ: (json['accZ'] as num?)?.toDouble() ?? 0.0,
      vibrAccX: (json['vibrAccX'] as num?)?.toDouble() ?? 0.0,
      vibrAccY: (json['vibrAccY'] as num?)?.toDouble() ?? 0.0,
      vibrAccZ: (json['vibrAccZ'] as num?)?.toDouble() ?? 0.0,
      weatherPrediction: json['weather_prediction'] as String? ?? 'Unknown',
      predictionConfidence:
          (json['prediction_confidence'] as num?)?.toDouble() ?? 0.0,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  factory SensorReading.mock() => SensorReading(
        time: DateTime.now(),
        deviceId: 0,
        temperature: 18.5,
        humidity: 62.0,
        pressure: 1013.0,
        light: 540.0,
        noise: 38.0,
        tof: 120.0,
        angle: 2.1,
        accX: 0.01,
        accY: -0.02,
        accZ: 9.81,
        vibrAccX: 0.0,
        vibrAccY: 0.0,
        vibrAccZ: 0.0,
        weatherPrediction: 'Serene',
        predictionConfidence: 0.82,
        latitude: AppConstants.parkCenterLat,
        longitude: AppConstants.parkCenterLng,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// WeatherState
// ─────────────────────────────────────────────────────────────────────────────
class WeatherState {
  final SensorReading? latest;
  final List<SensorReading> history;
  final bool isLoading;
  final String? error;
  final bool isOffline;

  const WeatherState({
    this.latest,
    this.history = const [],
    this.isLoading = false,
    this.error,
    this.isOffline = false,
  });

  double? get temperature => latest?.temperature;
  double? get humidity => latest?.humidity;
  double? get pressure => latest?.pressure;
  double? get light => latest?.light;
  double? get noise => latest?.noise;
  String get prediction => latest?.weatherPrediction ?? 'Unknown';
  double get predictionConfidence => latest?.predictionConfidence ?? 0;

  String get temperatureText =>
      temperature != null ? '${temperature!.toStringAsFixed(1)}C' : '--';

  String get conditionEmoji {
    final p = prediction.toLowerCase();
    if (p.contains('frosty')) return '🥶';
    if (p.contains('crisp')) return '🍃';
    if (p.contains('brisk')) return '💨';
    if (p.contains('moody')) return '🌩️';
    if (p.contains('overcast')) return '☁️';
    if (p.contains('serene')) return '😌';
    if (p.contains('sun')) return '☀️';
    if (p.contains('mild')) return '🌤️';
    return '🌤️';
  }

  WeatherState copyWith({
    SensorReading? latest,
    List<SensorReading>? history,
    bool? isLoading,
    String? error,
    bool? isOffline,
  }) {
    return WeatherState(
      latest: latest ?? this.latest,
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isOffline: isOffline ?? this.isOffline,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WeatherNotifier
// ─────────────────────────────────────────────────────────────────────────────
class WeatherNotifier extends StateNotifier<WeatherState> {
  WeatherNotifier() : super(const WeatherState());

  late final Dio _weatherDio = Dio(BaseOptions(
    baseUrl: AppConstants.weatherApiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 20),
    headers: {'Content-Type': 'application/json'},
  ));

  Future<void> loadWeather({int minutes = 60}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _weatherDio.get(
        AppConstants.weatherForecastEndpoint,
        queryParameters: {
          'minutes': minutes,
          'measurement': AppConstants.weatherMeasurement,
        },
      );

      final raw = response.data;
      List<dynamic> items;
      if (raw is List) {
        items = raw;
      } else if (raw is Map && raw.containsKey('data')) {
        items = raw['data'] as List<dynamic>;
      } else {
        items = [];
      }

      if (items.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          latest: SensorReading.mock(),
          isOffline: false,
        );
        return;
      }

      final readings = items
          .whereType<Map<String, dynamic>>()
          .map((j) => SensorReading.fromJson(j))
          .toList();

      readings.sort((a, b) => b.time.compareTo(a.time));

      state = state.copyWith(
        latest: readings.first,
        history: readings,
        isLoading: false,
        isOffline: false,
        error: null,
      );
    } on DioException catch (e) {
      final isConnErr = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.receiveTimeout;
      state = state.copyWith(
        isLoading: false,
        latest: SensorReading.mock(),
        isOffline: isConnErr,
        error: isConnErr
            ? 'IoT sensor API unreachable. Showing demo data.\n'
                'Set weatherApiBaseUrl in app_constants.dart to your PC LAN IP.'
            : 'API error: ${e.response?.statusCode ?? e.message}',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        latest: SensorReading.mock(),
        isOffline: true,
        error: 'Unexpected error: $e',
      );
    }
  }
}

final weatherProvider =
    StateNotifierProvider<WeatherNotifier, WeatherState>((ref) {
  return WeatherNotifier();
});
