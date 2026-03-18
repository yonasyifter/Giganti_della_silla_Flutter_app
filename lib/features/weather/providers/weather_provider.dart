import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';

class WeatherState {
  final double? temperature;
  final double? humidity;
  final double? noise;
  final double? light;
  final double? pressure;
  final String prediction;
  final double predictionConfidence;
  final bool isLoading;
  final String? error;
  final List<Map<String, dynamic>> zones;
  final List<Map<String, dynamic>> rawData;

  const WeatherState({
    this.temperature,
    this.humidity,
    this.noise,
    this.light,
    this.pressure,
    this.prediction = '—',
    this.predictionConfidence = 0,
    this.isLoading = false,
    this.error,
    this.zones = const [],
    this.rawData = const [],
  });

  String get temperatureText =>
      temperature != null ? '${temperature!.toStringAsFixed(1)}°C' : '—';

  String get conditionEmoji {
    final p = prediction.toLowerCase();
    if (p.contains('frosty')) return '🥶';
    if (p.contains('crisp')) return '🍃';
    if (p.contains('brisk')) return '💨';
    if (p.contains('moody')) return '🌩️';
    if (p.contains('overcast')) return '☁️';
    if (p.contains('serene')) return '😌';
    if (p.contains('sun')) return '☀️';
    return '🌤️';
  }

  WeatherState copyWith({
    double? temperature,
    double? humidity,
    double? noise,
    double? light,
    double? pressure,
    String? prediction,
    double? predictionConfidence,
    bool? isLoading,
    String? error,
    List<Map<String, dynamic>>? zones,
    List<Map<String, dynamic>>? rawData,
  }) {
    return WeatherState(
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      noise: noise ?? this.noise,
      light: light ?? this.light,
      pressure: pressure ?? this.pressure,
      prediction: prediction ?? this.prediction,
      predictionConfidence: predictionConfidence ?? this.predictionConfidence,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      zones: zones ?? this.zones,
      rawData: rawData ?? this.rawData,
    );
  }
}

class WeatherNotifier extends StateNotifier<WeatherState> {
  final ApiService _api;

  WeatherNotifier(this._api) : super(const WeatherState());

  Future<void> loadWeather() async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await _api.getWeatherForecast(minutes: 60);
      if (data.isEmpty) {
        state = state.copyWith(isLoading: false);
        return;
      }

      // Group by device_id and get latest per device
      final Map<dynamic, Map<String, dynamic>> deviceMap = {};
      for (final item in data) {
        final map = item as Map<String, dynamic>;
        final deviceId = map['device_id'];
        final existing = deviceMap[deviceId];
        if (existing == null) {
          deviceMap[deviceId] = map;
        } else {
          final t1 = DateTime.tryParse(map['time'] ?? '') ?? DateTime(0);
          final t2 = DateTime.tryParse(existing['time'] ?? '') ?? DateTime(0);
          if (t1.isAfter(t2)) deviceMap[deviceId] = map;
        }
      }

      final devices = deviceMap.values.toList();
      final latest = devices.isNotEmpty ? devices.last : <String, dynamic>{};

      state = state.copyWith(
        temperature: (latest['temperature'] as num?)?.toDouble(),
        humidity: (latest['humidity'] as num?)?.toDouble(),
        noise: (latest['noise'] as num?)?.toDouble(),
        light: (latest['light'] as num?)?.toDouble(),
        pressure: (latest['pressure'] as num?)?.toDouble(),
        prediction: latest['weather_prediction'] as String? ?? '—',
        predictionConfidence:
            (latest['prediction_confidence'] as num?)?.toDouble() ?? 0,
        isLoading: false,
        rawData: devices.cast<Map<String, dynamic>>(),
        zones: _buildZones(devices),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load weather data',
        temperature: 22.0,
        humidity: 55.0,
        noise: 42.0,
        light: 800.0,
        prediction: 'Mild',
        predictionConfidence: 0.75,
      );
    }
  }

  List<Map<String, dynamic>> _buildZones(List<dynamic> devices) {
    return devices.map((d) {
      final map = d as Map<String, dynamic>;
      return {
        'device_id': map['device_id'],
        'lat': map['latitude'],
        'lng': map['longitude'],
        'temperature': map['temperature'],
        'humidity': map['humidity'],
        'noise': map['noise'],
        'prediction': map['weather_prediction'] ?? '—',
      };
    }).where((z) => z['lat'] != null && z['lng'] != null).toList();
  }
}

final weatherProvider =
    StateNotifierProvider<WeatherNotifier, WeatherState>((ref) {
  return WeatherNotifier(ApiService());
});
