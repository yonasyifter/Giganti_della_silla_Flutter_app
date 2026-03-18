import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../weather/providers/weather_provider.dart';

class LandingScreen extends ConsumerStatefulWidget {
  const LandingScreen({super.key});

  @override
  ConsumerState<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends ConsumerState<LandingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  // Park image placeholders (gradient scenes representing park zones)
  final List<_ParkScene> _scenes = const [
    _ParkScene(
      title: 'Ancient Beech Forests',
      subtitle: 'UNESCO protected woodland',
      color1: Color(0xFF1B4332),
      color2: Color(0xFF2D6A4F),
      icon: Icons.forest,
    ),
    _ParkScene(
      title: 'Lago Arvo',
      subtitle: 'Crystal mountain lake, 1278m',
      color1: Color(0xFF0D3B6E),
      color2: Color(0xFF1A5276),
      icon: Icons.water,
    ),
    _ParkScene(
      title: 'Giants of Sila',
      subtitle: 'Centuries-old pine trees',
      color1: Color(0xFF4A235A),
      color2: Color(0xFF2D6A4F),
      icon: Icons.park,
    ),
    _ParkScene(
      title: 'Wildlife Sanctuary',
      subtitle: 'Wolves, deer & golden eagles',
      color1: Color(0xFF7D6608),
      color2: Color(0xFF1B4332),
      icon: Icons.pets,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) {
        final next = (_currentPage + 1) % _scenes.length;
        _pageController.animateToPage(next,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut);
      }
    });
    // Load weather/sensor data
    Future.microtask(() => ref.read(weatherProvider.notifier).loadWeather());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final weather = ref.watch(weatherProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Top App Bar with Login / Sign Up ──────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.primaryDark,
            elevation: 0,
            title: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                        colors: [AppColors.primaryLight, AppColors.primary]),
                  ),
                  child: const Icon(Icons.landscape_rounded,
                      size: 18, color: Colors.white),
                ),
                const SizedBox(width: 10),
                const Text('HikeSilla',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
                const Spacer(),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Login',
                    style: TextStyle(
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.w600)),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12, left: 4),
                child: ElevatedButton(
                  onPressed: () => context.go('/register'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  child: const Text('Sign Up',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero Image Carousel ──────────────────────────────────
                SizedBox(
                  height: 260,
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        onPageChanged: (i) =>
                            setState(() => _currentPage = i),
                        itemCount: _scenes.length,
                        itemBuilder: (_, i) => _SceneCard(scene: _scenes[i]),
                      ),
                      // Dots indicator
                      Positioned(
                        bottom: 14,
                        left: 0, right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_scenes.length, (i) =>
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: _currentPage == i ? 20 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _currentPage == i
                                    ? AppColors.primaryLight
                                    : Colors.white38,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Welcome Banner ───────────────────────────────────────
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryDark, AppColors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome to Parco Nazionale della Sila 🌲',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      Text(
                        'Covering 73,695 hectares in Calabria, Italy, the Sila National Park '
                        'is one of Europe\'s last great wilderness areas. Home to ancient beech '
                        'forests, glacial lakes, and diverse wildlife — a UNESCO World Heritage site.',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.6),
                      ),
                      SizedBox(height: 16),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: [
                          _StatChip(icon: Icons.terrain, label: '73,695 ha'),
                          _StatChip(icon: Icons.height, label: '1,929m peak'),
                          _StatChip(icon: Icons.route, label: '150+ trails'),
                          _StatChip(icon: Icons.star, label: 'UNESCO 🌍'),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── IoT Sensor Data ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.sensors,
                          color: AppColors.primaryLight, size: 18),
                      const SizedBox(width: 8),
                      const Text('Live Park Conditions',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      const Spacer(),
                      if (weather.isLoading)
                        const SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryLight),
                        )
                      else
                        GestureDetector(
                          onTap: () =>
                              ref.read(weatherProvider.notifier).loadWeather(),
                          child: const Icon(Icons.refresh,
                              color: AppColors.textSecondary, size: 18),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                if (weather.isLoading)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primaryLight),
                    ),
                  )
                else if (weather.rawData.isEmpty)
                  _NoStationBanner()
                else
                  _SensorGrid(weather: weather),

                // ── Map Section ──────────────────────────────────────────
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(Icons.map, color: AppColors.primaryLight, size: 18),
                      SizedBox(width: 8),
                      Text('Park Location',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1B4332), Color(0xFF0D3B6E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Simplified map representation
                      CustomPaint(
                        size: const Size(double.infinity, 180),
                        painter: _MapPainter(),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.9),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.5),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.location_on,
                                  color: Colors.white, size: 28),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Calabria, Italy  39.36°N, 16.55°E',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 10, right: 10,
                        child: GestureDetector(
                          onTap: () => context.go('/map'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.open_in_full,
                                    color: Colors.white, size: 12),
                                SizedBox(width: 4),
                                Text('Full Map',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 11)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── CTA ──────────────────────────────────────────────────
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.surfaceLight),
                  ),
                  child: Column(
                    children: [
                      const Text('Start Your Adventure',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text(
                          'Create an account to get AI trail recommendations, '
                          'live sensor data, and emergency SOS.',
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              height: 1.5),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => context.go('/login'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primaryLight,
                                side: const BorderSide(
                                    color: AppColors.primaryLight),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Login'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => context.go('/register'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Sign Up Free'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Scene Card ─────────────────────────────────────────────────────────────
class _SceneCard extends StatelessWidget {
  final _ParkScene scene;
  const _SceneCard({required this.scene});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scene.color1, scene.color2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: CustomPaint(painter: _ForestPatternPainter()),
          ),
          // Content
          Positioned(
            bottom: 36, left: 20, right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(scene.icon, color: Colors.white70, size: 36),
                const SizedBox(height: 8),
                Text(scene.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                Text(scene.subtitle,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── No Station Banner ──────────────────────────────────────────────────────
class _NoStationBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: const Row(
        children: [
          Icon(Icons.sensors_off, color: AppColors.textSecondary, size: 32),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No Sub-station Now',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                SizedBox(height: 4),
                Text(
                    'IoT sensors are offline or no data available. '
                    'Check back later for live park conditions.',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sensor Grid ────────────────────────────────────────────────────────────
class _SensorGrid extends StatelessWidget {
  final WeatherState weather;
  const _SensorGrid({required this.weather});

  @override
  Widget build(BuildContext context) {
    // Show all devices if multiple, else show the single one
    final devices = weather.rawData.isNotEmpty
        ? weather.rawData
        : [<String, dynamic>{}];

    return Column(
      children: devices.map((device) {
        final id = device['device_id'] ?? 'Station';
        final temp = (device['temperature'] as num?)?.toDouble();
        final hum = (device['humidity'] as num?)?.toDouble();
        final pres = (device['pressure'] as num?)?.toDouble();
        final noise = (device['noise'] as num?)?.toDouble();

        return Container(
          margin:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.sensors,
                            color: AppColors.primaryLight, size: 14),
                        const SizedBox(width: 4),
                        Text(id.toString(),
                            style: const TextStyle(
                                color: AppColors.primaryLight,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.circle,
                      color: AppColors.success, size: 8),
                  const SizedBox(width: 4),
                  const Text('Live',
                      style: TextStyle(
                          color: AppColors.success, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _SensorTile(
                      icon: Icons.thermostat,
                      label: 'Temperature',
                      value: temp != null
                          ? '${temp.toStringAsFixed(1)}°C'
                          : '—',
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SensorTile(
                      icon: Icons.water_drop,
                      label: 'Humidity',
                      value: hum != null
                          ? '${hum.toStringAsFixed(0)}%'
                          : '—',
                      color: AppColors.info,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SensorTile(
                      icon: Icons.compress,
                      label: 'Pressure',
                      value: pres != null
                          ? '${pres.toStringAsFixed(0)} hPa'
                          : '—',
                      color: AppColors.primaryLight,
                    ),
                  ),
                ],
              ),
              if (noise != null) ...[
                const SizedBox(height: 10),
                _SensorTile(
                  icon: Icons.volume_up,
                  label: 'Noise Level',
                  value: '${noise.toStringAsFixed(0)} dB',
                  color: AppColors.accent,
                  wide: true,
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _SensorTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool wide;

  const _SensorTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(wide ? 12 : 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: wide
          ? Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            color: color.withValues(alpha: 0.8),
                            fontSize: 10)),
                    Text(value,
                        style: TextStyle(
                            color: color,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            )
          : Column(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(height: 6),
                Text(value,
                    style: TextStyle(
                        color: color,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(label,
                    style: TextStyle(
                        color: color.withValues(alpha: 0.7),
                        fontSize: 10),
                    textAlign: TextAlign.center),
              ],
            ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primaryLight, size: 13),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}

// ── Data classes ────────────────────────────────────────────────────────────
class _ParkScene {
  final String title;
  final String subtitle;
  final Color color1;
  final Color color2;
  final IconData icon;
  const _ParkScene({
    required this.title,
    required this.subtitle,
    required this.color1,
    required this.color2,
    required this.icon,
  });
}

// ── Custom painters ─────────────────────────────────────────────────────────
class _ForestPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.04);
    for (int i = 0; i < 8; i++) {
      for (int j = 0; j < 5; j++) {
        final x = i * size.width / 7;
        final y = j * size.height / 4;
        final path = Path()
          ..moveTo(x, y + 20)
          ..lineTo(x - 12, y + 40)
          ..lineTo(x + 12, y + 40)
          ..close();
        canvas.drawPath(path, paint);
        final path2 = Path()
          ..moveTo(x, y)
          ..lineTo(x - 16, y + 28)
          ..lineTo(x + 16, y + 28)
          ..close();
        canvas.drawPath(path2, paint);
      }
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    // Grid lines
    for (int i = 1; i < 6; i++) {
      canvas.drawLine(Offset(0, size.height * i / 6),
          Offset(size.width, size.height * i / 6), paint);
      canvas.drawLine(Offset(size.width * i / 6, 0),
          Offset(size.width * i / 6, size.height), paint);
    }
    // Trail line
    final trailPaint = Paint()
      ..color = AppColors.primaryLight.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * 0.1, size.height * 0.7)
      ..quadraticBezierTo(size.width * 0.3, size.height * 0.3,
          size.width * 0.5, size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.7, size.height * 0.7,
          size.width * 0.9, size.height * 0.3);
    canvas.drawPath(path, trailPaint);
  }
  @override
  bool shouldRepaint(_) => false;
}
