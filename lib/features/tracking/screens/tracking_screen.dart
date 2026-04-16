import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/tracking_provider.dart';
import '../../map/providers/trail_selection_provider.dart';

// ── Tracking screen ───────────────────────────────────────────────────────────
class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({super.key});

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _elapsedTimer;
  DateTime? _sessionStart;
  int _elapsedSeconds = 0;
  double _totalDistance = 0;
  Position? _lastPos;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _sessionStart = DateTime.now();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _elapsedTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatSpeed(double? mps) {
    if (mps == null || mps < 0) return '0.0';
    return (mps * 3.6).toStringAsFixed(1); // m/s → km/h
  }

  String _compassDir(double? heading) {
    if (heading == null) return '—';
    const dirs = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final idx = ((heading + 22.5) / 45).floor() % 8;
    return dirs[idx];
  }

  void _updateDistance(Position? pos) {
    if (pos == null) return;
    if (_lastPos != null) {
      final d = Geolocator.distanceBetween(
        _lastPos!.latitude, _lastPos!.longitude,
        pos.latitude, pos.longitude,
      );
      if (d > 2) {
        // ignore GPS jitter < 2m
        _totalDistance += d;
        _lastPos = pos;
      }
    } else {
      _lastPos = pos;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tracking = ref.watch(trackingProvider);
    final trailSel = ref.watch(trailSelectionProvider);
    _updateDistance(tracking.position);

    final pos = tracking.position;
    final speed = pos?.speed;
    final altitude = pos?.altitude;
    final heading = pos?.heading;
    final accuracy = pos?.accuracy;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ─────────────────────────────────────────────────
                Row(children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (_, __) => Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: tracking.isTracking
                            ? AppColors.success
                                .withValues(alpha: 0.2 + 0.1 * _pulseController.value)
                            : AppColors.surface,
                        border: Border.all(
                          color: tracking.isTracking
                              ? AppColors.success
                              : AppColors.surfaceLight,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.directions_walk_rounded,
                        color: tracking.isTracking
                            ? AppColors.success
                            : AppColors.textHint,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Hiker Tracking',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                    Text(
                      tracking.isTracking
                          ? tracking.isInsidePark
                              ? '🟢 Inside Park — sharing location'
                              : '🟡 Outside Park'
                          : '⚫ Tracking off',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ]),
                  const Spacer(),
                  // Session timer
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.surfaceLight),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.timer_outlined,
                          color: AppColors.primaryLight, size: 14),
                      const SizedBox(width: 4),
                      Text(_formatDuration(_elapsedSeconds),
                          style: const TextStyle(
                              color: AppColors.primaryLight,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 20),

                // ── GPS Position card ───────────────────────────────────────
                _SectionTitle('GPS Position'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: _cardDeco(),
                  child: pos == null
                      ? const _NoDataRow('Waiting for GPS signal…')
                      : Column(children: [
                          Row(children: [
                            _StatBox(
                              icon: Icons.location_on_rounded,
                              color: AppColors.primaryLight,
                              label: 'Latitude',
                              value: pos.latitude.toStringAsFixed(6),
                              unit: '°',
                            ),
                            const SizedBox(width: 10),
                            _StatBox(
                              icon: Icons.location_on_outlined,
                              color: AppColors.primaryLight,
                              label: 'Longitude',
                              value: pos.longitude.toStringAsFixed(6),
                              unit: '°',
                            ),
                          ]),
                          const SizedBox(height: 10),
                          Row(children: [
                            _StatBox(
                              icon: Icons.height_rounded,
                              color: AppColors.info,
                              label: 'Altitude',
                              value: (altitude ?? 0).toStringAsFixed(1),
                              unit: 'm',
                            ),
                            const SizedBox(width: 10),
                            _StatBox(
                              icon: Icons.gps_fixed_rounded,
                              color: AppColors.success,
                              label: 'Accuracy',
                              value: '±${(accuracy ?? 0).toStringAsFixed(0)}',
                              unit: 'm',
                            ),
                          ]),
                        ]),
                ),
                const SizedBox(height: 16),

                // ── Motion card ─────────────────────────────────────────────
                _SectionTitle('Motion'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: _cardDeco(),
                  child: Row(children: [
                    _StatBox(
                      icon: Icons.speed_rounded,
                      color: AppColors.warning,
                      label: 'Speed',
                      value: _formatSpeed(speed),
                      unit: 'km/h',
                    ),
                    const SizedBox(width: 10),
                    _StatBox(
                      icon: Icons.explore_rounded,
                      color: AppColors.accent,
                      label: 'Heading',
                      value: heading != null
                          ? '${heading.toStringAsFixed(0)}° ${_compassDir(heading)}'
                          : '—',
                      unit: '',
                    ),
                    const SizedBox(width: 10),
                    _StatBox(
                      icon: Icons.straighten_rounded,
                      color: AppColors.easy,
                      label: 'Distance',
                      value: _totalDistance < 1000
                          ? _totalDistance.toStringAsFixed(0)
                          : (_totalDistance / 1000).toStringAsFixed(2),
                      unit: _totalDistance < 1000 ? 'm' : 'km',
                    ),
                  ]),
                ),
                const SizedBox(height: 16),

                // ── Trail progress card ─────────────────────────────────────
                if (trailSel.activeTrail != null) ...[
                  _SectionTitle('Active Trail'),
                  const SizedBox(height: 8),
                  _TrailProgressCard(trailSel: trailSel),
                  const SizedBox(height: 16),
                ],

                // ── Phone sensors card ──────────────────────────────────────
                _SectionTitle('Phone Sensors'),
                const SizedBox(height: 8),
                _PhoneSensorsCard(pos: pos),
                const SizedBox(height: 16),

                // ── Wearable hint card ──────────────────────────────────────
                _SectionTitle('Wearable Devices'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: _cardDeco(),
                  child: Row(children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.watch_rounded,
                          color: AppColors.accent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('Wear OS / Apple Watch',
                            style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                        SizedBox(height: 4),
                        Text(
                          'Heart rate, SpO₂, and step data from paired '
                          'wearables will appear here automatically when '
                          'a Wear OS or Apple Watch is connected via '
                          'Bluetooth.',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 11),
                        ),
                      ]),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),

                // ── Safety note ─────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.info.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppColors.info, size: 18),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Your location is shared with park rangers every '
                        '30 seconds while you are inside the park. '
                        'This helps ensure your safety during hikes.',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDeco() => BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      );
}

// ── Section title ─────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 14));
}

// ── No data row ───────────────────────────────────────────────────────────────
class _NoDataRow extends StatelessWidget {
  final String message;
  const _NoDataRow(this.message);

  @override
  Widget build(BuildContext context) => Row(children: [
        const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                color: AppColors.primaryLight, strokeWidth: 2)),
        const SizedBox(width: 10),
        Text(message,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12)),
      ]);
}

// ── Stat box ──────────────────────────────────────────────────────────────────
class _StatBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String unit;
  const _StatBox({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textHint, fontSize: 10)),
            ]),
            const SizedBox(height: 6),
            Text(
              unit.isEmpty ? value : '$value $unit',
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Trail progress card ───────────────────────────────────────────────────────
class _TrailProgressCard extends StatelessWidget {
  final TrailSelectionState trailSel;
  const _TrailProgressCard({required this.trailSel});

  @override
  Widget build(BuildContext context) {
    final trail = trailSel.activeTrail!;
    final progress = trailSel.progressPercent;

    Color diffColor;
    switch (trail.difficulty.toLowerCase()) {
      case 'easy':
        diffColor = AppColors.easy;
        break;
      case 'moderate':
        diffColor = AppColors.moderate;
        break;
      case 'hard':
        diffColor = AppColors.hard;
        break;
      default:
        diffColor = AppColors.expert;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: diffColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: diffColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.terrain, color: diffColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(trail.name,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                Text(
                    '${trail.difficulty.toUpperCase()} · ${trail.distance} · ${trail.duration}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 10)),
              ]),
            ),
            Text('${progress.toStringAsFixed(0)}%',
                style: TextStyle(
                    color: diffColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
          ]),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress / 100,
              backgroundColor: diffColor.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(diffColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.flag_outlined,
                color: AppColors.textHint, size: 12),
            const SizedBox(width: 4),
            Text('Start',
                style: const TextStyle(
                    color: AppColors.textHint, fontSize: 10)),
            const Spacer(),
            Text('${progress.toStringAsFixed(1)}% complete',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 10)),
            const Spacer(),
            const Icon(Icons.flag_rounded,
                color: AppColors.success, size: 12),
            const SizedBox(width: 4),
            Text('End',
                style: const TextStyle(
                    color: AppColors.textHint, fontSize: 10)),
          ]),
        ],
      ),
    );
  }
}

// ── Phone sensors card ────────────────────────────────────────────────────────
class _PhoneSensorsCard extends StatefulWidget {
  final Position? pos;
  const _PhoneSensorsCard({this.pos});

  @override
  State<_PhoneSensorsCard> createState() => _PhoneSensorsCardState();
}

class _PhoneSensorsCardState extends State<_PhoneSensorsCard> {
  // Simulated step counter (real implementation requires sensors_plus package)
  int _steps = 0;
  Timer? _stepTimer;

  @override
  void initState() {
    super.initState();
    // Simulate step increments based on speed — replace with sensors_plus when available
    _stepTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (widget.pos != null && (widget.pos!.speed) > 0.5) {
        setState(() => _steps += (widget.pos!.speed * 1.2).round());
      }
    });
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    super.dispose();
  }

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
        children: [
          Row(children: [
            _SensorTile(
              icon: Icons.directions_walk_rounded,
              color: AppColors.easy,
              label: 'Steps',
              value: _steps.toString(),
            ),
            const SizedBox(width: 10),
            _SensorTile(
              icon: Icons.battery_std_rounded,
              color: _batteryColor(),
              label: 'Battery',
              value: '—',
              note: 'via battery_plus',
            ),
            const SizedBox(width: 10),
            _SensorTile(
              icon: Icons.thermostat_rounded,
              color: AppColors.warning,
              label: 'Temp',
              value: '—',
              note: 'via sensors_plus',
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _SensorTile(
              icon: Icons.favorite_rounded,
              color: AppColors.danger,
              label: 'Heart Rate',
              value: '—',
              note: 'wearable',
            ),
            const SizedBox(width: 10),
            _SensorTile(
              icon: Icons.air_rounded,
              color: AppColors.info,
              label: 'SpO₂',
              value: '—',
              note: 'wearable',
            ),
            const SizedBox(width: 10),
            _SensorTile(
              icon: Icons.compress_rounded,
              color: AppColors.accent,
              label: 'Pressure',
              value: widget.pos != null ? '—' : '—',
              note: 'barometer',
            ),
          ]),
        ],
      ),
    );
  }

  Color _batteryColor() {
    // Placeholder — replace with battery_plus
    return AppColors.success;
  }
}

class _SensorTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String? note;
  const _SensorTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textHint, fontSize: 9)),
            if (note != null)
              Text(note!,
                  style: const TextStyle(
                      color: AppColors.textHint, fontSize: 8),
                  textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
