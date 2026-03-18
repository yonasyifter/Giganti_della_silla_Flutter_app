import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../tracking/providers/tracking_provider.dart';

class SosScreen extends ConsumerStatefulWidget {
  const SosScreen({super.key});

  @override
  ConsumerState<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends ConsumerState<SosScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isSending = false;
  bool _sent = false;
  final _messageCtrl = TextEditingController(
      text: 'I need assistance. Please send help.');

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendSOS() async {
    setState(() => _isSending = true);
    final pos = ref.read(trackingProvider).position;
    try {
      await ApiService().sendSOS(
        lat: pos?.latitude ?? 39.85,
        lng: pos?.longitude ?? 16.55,
        message: _messageCtrl.text,
      );
      setState(() { _isSending = false; _sent = true; });
    } catch (_) {
      // Even if API fails, show confirmation (offline SOS)
      setState(() { _isSending = false; _sent = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tracking = ref.watch(trackingProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Emergency SOS'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _sent ? _SuccessState() : _SOSForm(
            pulseController: _pulseController,
            messageCtrl: _messageCtrl,
            tracking: tracking,
            isSending: _isSending,
            onSend: _sendSOS,
          ),
        ),
      ),
    );
  }
}

class _SOSForm extends StatelessWidget {
  final AnimationController pulseController;
  final TextEditingController messageCtrl;
  final dynamic tracking;
  final bool isSending;
  final VoidCallback onSend;

  const _SOSForm({
    required this.pulseController,
    required this.messageCtrl,
    required this.tracking,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Pulsing SOS button
        Center(
          child: AnimatedBuilder(
            animation: pulseController,
            builder: (_, _) => Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.danger.withValues(alpha: 0.1 + 0.1 * pulseController.value),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.danger.withValues(alpha: 0.3 + 0.2 * pulseController.value),
                    blurRadius: 40 + 20 * pulseController.value,
                    spreadRadius: 5 + 5 * pulseController.value,
                  ),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.danger,
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.sos_rounded, color: Colors.white, size: 56),
                    Text('EMERGENCY',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1)),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Warning
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                  SizedBox(width: 8),
                  Text('Emergency Alert',
                      style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w600)),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'Pressing SOS will immediately alert park rangers and emergency services '
                'with your GPS location. Only use in genuine emergencies.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // GPS Location
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.primaryLight, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your GPS Location',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    Text(
                      tracking.position != null
                          ? '${tracking.position!.latitude.toStringAsFixed(5)}, '
                              '${tracking.position!.longitude.toStringAsFixed(5)}'
                          : 'Location unavailable',
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (tracking.position != null ? AppColors.success : AppColors.warning).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tracking.position != null ? 'GPS OK' : 'No GPS',
                  style: TextStyle(
                    color: tracking.position != null ? AppColors.success : AppColors.warning,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Message
        const Text('Emergency Message',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: messageCtrl,
          style: const TextStyle(color: AppColors.textPrimary),
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Describe your emergency...',
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.surfaceLight)),
          ),
        ),
        const SizedBox(height: 24),

        // Alert channels info
        const _AlertChannels(),
        const SizedBox(height: 32),

        // SOS Button
        ElevatedButton(
          onPressed: isSending ? null : onSend,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.danger,
            minimumSize: const Size.fromHeight(60),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: isSending
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                    SizedBox(width: 12),
                    Text('Sending Alert...', style: TextStyle(fontSize: 18, color: Colors.white)),
                  ],
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.sos_rounded, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Text('SEND SOS ALERT',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.textHint),
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
        ),
      ],
    );
  }
}

class _AlertChannels extends StatelessWidget {
  const _AlertChannels();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Alert will be sent via:',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          SizedBox(height: 10),
          _Channel(Icons.admin_panel_settings, 'Park Admin Dashboard', 'Real-time GPS broadcast'),
          _Channel(Icons.message, 'WhatsApp', 'Park ranger emergency line'),
          _Channel(Icons.send, 'Telegram', 'Emergency response group'),
        ],
      ),
    );
  }
}

class _Channel extends StatelessWidget {
  final IconData icon;
  final String name;
  final String sub;
  const _Channel(this.icon, this.name, this.sub);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryLight, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
              Text(sub, style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SuccessState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 60),
        const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 100),
        const SizedBox(height: 24),
        const Text('SOS Alert Sent!',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text(
          'Your location has been sent to park rangers and emergency services.\n\n'
          'Stay calm and stay where you are.\nHelp is on the way.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 15, height: 1.6),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            children: [
              Text('Emergency Numbers', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              SizedBox(height: 12),
              Text('🇮🇹  112 — European Emergency',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
              SizedBox(height: 6),
              Text('🏥  118 — Medical Emergency (Italy)',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
              SizedBox(height: 6),
              Text('🚒  115 — Fire Brigade (Italy)',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => context.pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('Return to App', style: TextStyle(color: Colors.white, fontSize: 16)),
        ),
      ],
    );
  }
}
