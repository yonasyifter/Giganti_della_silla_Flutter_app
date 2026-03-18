import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class VoiceWaveWidget extends StatefulWidget {
  final bool isActive;
  final Color color;
  final double height;

  const VoiceWaveWidget({
    super.key,
    required this.isActive,
    this.color = AppColors.primaryLight,
    this.height = 24,
  });

  @override
  State<VoiceWaveWidget> createState() => _VoiceWaveWidgetState();
}

class _VoiceWaveWidgetState extends State<VoiceWaveWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    if (widget.isActive) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(VoiceWaveWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isActive && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(5, (i) {
          final heights = [0.4, 0.7, 1.0, 0.7, 0.4];
          final phase = (i / 4.0);
          final value = widget.isActive
              ? (0.3 + 0.7 * (((_controller.value + phase) % 1.0)))
              : heights[i];
          return Container(
            width: 3,
            height: widget.height * value * heights[i],
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}
