import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../providers/weather_provider.dart';

class WeatherScreen extends ConsumerStatefulWidget {
  const WeatherScreen({super.key});

  @override
  ConsumerState<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends ConsumerState<WeatherScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(weatherProvider.notifier).loadWeather());
  }

  @override
  Widget build(BuildContext context) {
    final weather = ref.watch(weatherProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: weather.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryLight))
              : RefreshIndicator(
                  onRefresh: () => ref.read(weatherProvider.notifier).loadWeather(),
                  color: AppColors.primaryLight,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Text(AppLocalizations.of(context).weatherTitle,
                                style: Theme.of(context).textTheme.headlineLarge),
                            const Spacer(),
                            IconButton(
                              onPressed: () => ref.read(weatherProvider.notifier).loadWeather(),
                              icon: const Icon(Icons.refresh, color: AppColors.primaryLight),
                            ),
                          
                        ),
                        Text(AppLocalizations.of(context).parkName,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        if (weather.isOffline) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                            ),
                            child: Row(children: [
                              const Icon(Icons.wifi_off, color: AppColors.warning, size: 16),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'IoT API offline — showing demo data. Set weatherApiBaseUrl to your PC LAN IP.',
                                  style: TextStyle(color: AppColors.warning, fontSize: 11),
                                ),
                              ),
                            ]),
                          ),
                        ],
                        const SizedBox(height: 24),

                        // Main weather card
                        _MainWeatherCard(weather: weather),
                        const SizedBox(height: 20),

                        // Metrics grid
                        Text(AppLocalizations.of(context).parkConditions, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 12),
                        _MetricsGrid(weather: weather),
                        const SizedBox(height: 20),

                        // Sensor zones
                        if (weather.history.isNotEmpty) ...[
                          Text('IoT Sensor History', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 12),
                          _SensorHistoryCard(reading: weather.history.first),
                          const SizedBox(height: 20),
                        ],

                        // Weather tips
                        const SizedBox(height: 8),
                        _WeatherTips(prediction: weather.prediction),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _MainWeatherCard extends StatelessWidget {
  final WeatherState weather;
  const _MainWeatherCard({required this.weather});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    weather.conditionEmoji,
                    style: const TextStyle(fontSize: 60),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    weather.temperatureText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      weather.prediction,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(weather.predictionConfidence * 100).toStringAsFixed(0)}% confidence',
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _QuickStat('💧', 'Humidity', '${weather.humidity?.toStringAsFixed(0) ?? '—'}%'),
              _QuickStat('🔊', 'Noise', '${weather.noise?.toStringAsFixed(0) ?? '—'}dB'),
              _QuickStat('☀️', 'Light', weather.light?.toStringAsFixed(0) ?? '—'),
              _QuickStat('📊', 'Pressure',
                  '${((weather.pressure ?? 0) / 1000).toStringAsFixed(1)}kPa'),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  const _QuickStat(this.emoji, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  final WeatherState weather;
  const _MetricsGrid({required this.weather});

  @override
  Widget build(BuildContext context) {
    final r = weather.latest;
    final metrics = [
      _Metric('Temperature', weather.temperatureText, Icons.thermostat, AppColors.warning),
      _Metric('Humidity', '\${weather.humidity?.toStringAsFixed(1) ?? '--'}%', Icons.water_drop, AppColors.info),
      _Metric('Noise', '\${weather.noise?.toStringAsFixed(0) ?? '--'} dB', Icons.volume_up, AppColors.accent),
      _Metric('Light', '\${weather.light?.toStringAsFixed(0) ?? '--'} lux', Icons.wb_sunny, AppColors.warning),
      _Metric('Pressure', '\${weather.pressure?.toStringAsFixed(1) ?? '--'} hPa', Icons.compress, AppColors.primaryLight),
      _Metric('Forecast', weather.prediction, Icons.cloud, AppColors.info),
      _Metric('Distance (ToF)', '\${r?.tof.toStringAsFixed(1) ?? '--'} mm', Icons.straighten, AppColors.easy),
      _Metric('Tilt Angle', '\${r?.angle.toStringAsFixed(1) ?? '--'}°', Icons.rotate_90_degrees_ccw, AppColors.moderate),
      _Metric('Acc X', '\${r?.accX.toStringAsFixed(3) ?? '--'} g', Icons.swap_horiz, AppColors.hard),
      _Metric('Acc Y', '\${r?.accY.toStringAsFixed(3) ?? '--'} g', Icons.swap_vert, AppColors.hard),
      _Metric('Acc Z', '\${r?.accZ.toStringAsFixed(3) ?? '--'} g', Icons.height, AppColors.hard),
      _Metric('Vibr X', '\${r?.vibrAccX.toStringAsFixed(3) ?? '--'} g', Icons.vibration, AppColors.danger),
    ];

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      children: metrics.map((m) => _MetricCard(metric: m)).toList(),
    );
  }
}

class _Metric {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  _Metric(this.label, this.value, this.icon, this.color);
}

class _MetricCard extends StatelessWidget {
  final _Metric metric;
  const _MetricCard({required this.metric});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(metric.icon, color: metric.color, size: 22),
            const SizedBox(height: 8),
            Text(metric.value,
                style: TextStyle(color: metric.color, fontSize: 18, fontWeight: FontWeight.bold),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(metric.label,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _SensorHistoryCard extends StatelessWidget {
  final SensorReading reading;
  const _SensorHistoryCard({required this.reading});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.sensors, color: AppColors.primaryLight, size: 18),
            const SizedBox(width: 8),
            Text('Device ${reading.deviceId}',
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
            const Spacer(),
            Text(
              '${reading.time.hour.toString().padLeft(2, '0')}:'
              '${reading.time.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(color: AppColors.textHint, fontSize: 12),
            ),
          ]),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _SensorChip('🌡️ ${reading.temperature.toStringAsFixed(1)}°C'),
              _SensorChip('💧 ${reading.humidity.toStringAsFixed(0)}%'),
              _SensorChip('🔊 ${reading.noise.toStringAsFixed(0)} dB'),
              _SensorChip('☀️ ${reading.light.toStringAsFixed(0)} lux'),
              _SensorChip('📏 ToF ${reading.tof.toStringAsFixed(0)} mm'),
              _SensorChip('📐 ${reading.angle.toStringAsFixed(1)}°'),
              _SensorChip('📳 Vib ${reading.vibrAccX.toStringAsFixed(2)}g'),
              _SensorChip('🌤️ ${reading.weatherPrediction}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SensorChip extends StatelessWidget {
  final String label;
  const _SensorChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: const TextStyle(
              color: AppColors.textPrimary, fontSize: 11)),
    );
  }
}


class _WeatherTips extends StatelessWidget {
  final String prediction;
  const _WeatherTips({required this.prediction});

  String get _tip {
    final p = prediction.toLowerCase();
    if (p.contains('frosty') || p.contains('crisp')) return '🧤 Dress warmly — temperatures are low. Gloves and an extra layer recommended.';
    if (p.contains('moody') || p.contains('overcast')) return '🌧️ Possible rain — carry a waterproof jacket and be careful on slippery trails.';
    if (p.contains('brisk')) return '💨 Windy conditions — secure your gear and avoid exposed ridge walks.';
    if (p.contains('sun')) return '☀️ Sun-drenched conditions — bring sunscreen, sunglasses, and extra water.';
    return '🥾 Good hiking conditions. Stay on marked trails and tell someone your route.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.tips_and_updates, color: AppColors.accent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(_tip,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
