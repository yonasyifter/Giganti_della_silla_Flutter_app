import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/chatbot_provider.dart';
import '../widgets/voice_wave_widget.dart';
import '../widgets/chat_bubble_widget.dart';

class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({super.key});

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen>
    with TickerProviderStateMixin {
  final _scrollController = ScrollController();
  final _textController = TextEditingController();
  late AnimationController _pulseController;
  late AnimationController _listenRingController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _listenRingController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    Future.microtask(() => ref.read(chatbotProvider.notifier).initialize());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    _pulseController.dispose();
    _listenRingController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendText() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    ref.read(chatbotProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatbot = ref.watch(chatbotProvider);

    ref.listen(chatbotProvider.select((s) => s.messages.length), (_, __) {
      _scrollToBottom();
    });

    final isListening = chatbot.status == ChatbotStatus.listening;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _ChatHeader(chatbot: chatbot),

              if (chatbot.isInitialized)
                _ParkStatusBanner(isInsidePark: chatbot.isInsidePark),

              // Messages
              Expanded(
                child: chatbot.messages.isEmpty
                    ? _EmptyState(pulseController: _pulseController)
                    : Stack(
                        children: [
                          ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            itemCount: chatbot.messages.length +
                                (chatbot.status == ChatbotStatus.thinking
                                    ? 1
                                    : 0),
                            itemBuilder: (_, i) {
                              if (i == chatbot.messages.length) {
                                return const _TypingIndicator();
                              }
                              return ChatBubbleWidget(
                                  message: chatbot.messages[i]);
                            },
                          ),

                          // ── Listening overlay with partial text ────
                          if (isListening && chatbot.partialText.isNotEmpty)
                            Positioned(
                              bottom: 8, left: 16, right: 16,
                              child: _PartialTextBubble(
                                  text: chatbot.partialText,
                                  mode: chatbot.micMode),
                            ),
                        ],
                      ),
              ),

              // Voice status bar
              if (isListening || chatbot.status == ChatbotStatus.speaking)
                _VoiceStatusBar(
                  chatbot: chatbot,
                  ringController: _listenRingController,
                ),

              _InputArea(
                textController: _textController,
                chatbot: chatbot,
                onSend: _sendText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Chat Header ─────────────────────────────────────────────────────────────
class _ChatHeader extends ConsumerWidget {
  final ChatbotState chatbot;
  const _ChatHeader({required this.chatbot});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.backgroundSecondary,
        border: Border(bottom: BorderSide(color: AppColors.surfaceLight)),
      ),
      child: Row(children: [
        // AI avatar
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
                colors: [AppColors.primaryLight, AppColors.primary]),
            boxShadow: chatbot.status == ChatbotStatus.speaking
                ? [BoxShadow(
                    color: AppColors.primaryLight.withValues(alpha: 0.5),
                    blurRadius: 12, spreadRadius: 3)]
                : null,
          ),
          child: const Icon(Icons.smart_toy_rounded,
              color: Colors.white, size: 26),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Ciao',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16)),
          Row(children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _statusColor(chatbot.status)),
            ),
            const SizedBox(width: 4),
            Text(_statusText(chatbot.status),
                style: TextStyle(
                    color: _statusColor(chatbot.status), fontSize: 11)),
          ]),
        ]),
        const Spacer(),

        // ── Auto-VAD toggle ─────────────────────────────────────────
        Tooltip(
          message: chatbot.autoVadActive
              ? 'Auto-listen ON\nI detect when you speak'
              : 'Auto-listen OFF\nTap mic to speak',
          child: GestureDetector(
            onTap: () => ref.read(chatbotProvider.notifier).toggleAutoVad(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: chatbot.autoVadActive
                    ? AppColors.success.withValues(alpha: 0.15)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: chatbot.autoVadActive
                        ? AppColors.success
                        : AppColors.surfaceLight),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                  chatbot.autoVadActive
                      ? Icons.hearing_rounded
                      : Icons.hearing_disabled_rounded,
                  color: chatbot.autoVadActive
                      ? AppColors.success
                      : AppColors.textHint,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  chatbot.autoVadActive ? 'AUTO' : 'Manual',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: chatbot.autoVadActive
                          ? AppColors.success
                          : AppColors.textHint),
                ),
              ]),
            ),
          ),
        ),
        const SizedBox(width: 4),

        // Language toggle
        GestureDetector(
          onTap: () => ref.read(chatbotProvider.notifier).toggleLanguage(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surfaceLight),
            ),
            child: Text(
              chatbot.language == 'en' ? '🇬🇧 EN' : '🇮🇹 IT',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ),
        const SizedBox(width: 4),
        // TTS toggle
        IconButton(
          icon: Icon(
            chatbot.ttsEnabled ? Icons.volume_up : Icons.volume_off,
            color: chatbot.ttsEnabled
                ? AppColors.primaryLight
                : AppColors.textHint,
          ),
          onPressed: () => ref.read(chatbotProvider.notifier).toggleTts(),
        ),
        // Clear
        IconButton(
          icon: const Icon(Icons.refresh, color: AppColors.textHint),
          onPressed: () => ref.read(chatbotProvider.notifier).clearChat(),
        ),
      ]),
    );
  }

  Color _statusColor(ChatbotStatus s) {
    switch (s) {
      case ChatbotStatus.listening: return AppColors.danger;
      case ChatbotStatus.thinking:  return AppColors.warning;
      case ChatbotStatus.speaking:  return AppColors.primaryLight;
      default:                      return AppColors.success;
    }
  }

  String _statusText(ChatbotStatus s) {
    switch (s) {
      case ChatbotStatus.listening: return 'Listening...';
      case ChatbotStatus.thinking:  return 'Thinking...';
      case ChatbotStatus.speaking:  return 'Speaking...';
      default:                      return 'Ready';
    }
  }
}

// ── Park Status Banner ──────────────────────────────────────────────────────
class _ParkStatusBanner extends StatelessWidget {
  final bool isInsidePark;
  const _ParkStatusBanner({required this.isInsidePark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: isInsidePark
          ? AppColors.success.withValues(alpha: 0.1)
          : AppColors.warning.withValues(alpha: 0.1),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(
          isInsidePark ? Icons.landscape : Icons.home_outlined,
          color: isInsidePark ? AppColors.success : AppColors.warning,
          size: 14,
        ),
        const SizedBox(width: 6),
        Text(
          isInsidePark
              ? '📍 You are inside Parco della Silla'
              : '🏠 You are currently outside the park',
          style: TextStyle(
              color: isInsidePark ? AppColors.success : AppColors.warning,
              fontSize: 12,
              fontWeight: FontWeight.w500),
        ),
      ]),
    );
  }
}

// ── Partial text bubble (shown while speaking) ──────────────────────────────
class _PartialTextBubble extends StatelessWidget {
  final String text;
  final MicMode mode;
  const _PartialTextBubble({required this.text, required this.mode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: AppColors.danger.withValues(alpha: 0.3),
            blurRadius: 12)],
      ),
      child: Row(children: [
        const Icon(Icons.mic, color: Colors.white, size: 14),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ),
        if (mode == MicMode.auto)
          const Text('5s', style: TextStyle(color: Colors.white54, fontSize: 11)),
        if (mode == MicMode.manual)
          const Text('tap mic to send',
              style: TextStyle(color: Colors.white54, fontSize: 10)),
      ]),
    );
  }
}

// ── Voice Status Bar ────────────────────────────────────────────────────────
class _VoiceStatusBar extends StatelessWidget {
  final ChatbotState chatbot;
  final AnimationController ringController;
  const _VoiceStatusBar(
      {required this.chatbot, required this.ringController});

  @override
  Widget build(BuildContext context) {
    final isListening = chatbot.status == ChatbotStatus.listening;
    final isAuto = chatbot.micMode == MicMode.auto;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isListening
            ? AppColors.danger.withValues(alpha: 0.12)
            : AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isListening ? AppColors.danger : AppColors.primaryLight,
        ),
      ),
      child: Row(children: [
        // Animated ring
        SizedBox(
          width: 32, height: 32,
          child: AnimatedBuilder(
            animation: ringController,
            builder: (_, child) {
              return CustomPaint(
                painter: _RingPainter(
                  progress: ringController.value,
                  color: isListening ? AppColors.danger : AppColors.primaryLight,
                ),
                child: child,
              );
            },
            child: Center(
              child: Icon(
                isListening ? Icons.mic : Icons.volume_up,
                color: isListening ? AppColors.danger : AppColors.primaryLight,
                size: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isListening
                    ? (isAuto
                        ? '🎙️ Listening · auto-submit after 5s silence'
                        : '🎙️ Listening · tap mic to send')
                    : '🔊 Speaking...',
                style: TextStyle(
                    color: isListening
                        ? AppColors.danger
                        : AppColors.primaryLight,
                    fontWeight: FontWeight.w600,
                    fontSize: 12),
              ),
              if (isListening && chatbot.partialText.isNotEmpty)
                Text('"${chatbot.partialText}"',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        if (isListening)
          VoiceWaveWidget(
              isActive: true,
              color: isListening ? AppColors.danger : AppColors.primaryLight),
      ]),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  const _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      -pi / 2,
      2 * pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

// ── Empty State ─────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final AnimationController pulseController;
  const _EmptyState({required this.pulseController});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: pulseController,
            builder: (_, __) => Transform.scale(
              scale: 0.95 + 0.05 * pulseController.value,
              child: Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                      colors: [AppColors.primaryLight, AppColors.primary]),
                  boxShadow: [BoxShadow(
                    color: AppColors.primary.withValues(
                        alpha: 0.3 + 0.2 * pulseController.value),
                    blurRadius: 20, spreadRadius: 5,
                  )],
                ),
                child: const Icon(Icons.smart_toy_rounded,
                    color: Colors.white, size: 50),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Initializing AI Guide...',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Your trail companion is getting ready',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 24),
          const SizedBox(
            width: 32, height: 32,
            child: CircularProgressIndicator(
                color: AppColors.primaryLight, strokeWidth: 2),
          ),
        ],
      ),
    );
  }
}

// ── Typing Indicator ────────────────────────────────────────────────────────
class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                  colors: [AppColors.primaryLight, AppColors.primary])),
          child: const Icon(Icons.smart_toy_rounded,
              color: Colors.white, size: 20),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) => _Dot(delay: i * 0.2)),
          ),
        ),
      ]),
    );
  }
}

class _Dot extends StatefulWidget {
  final double delay;
  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        duration: const Duration(milliseconds: 600), vsync: this);
    _anim = Tween<double>(begin: 0, end: -6)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: (widget.delay * 1000).toInt()),
        () { if (mounted) _ctrl.repeat(reverse: true); });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _anim.value),
        child: Container(
          width: 8, height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: const BoxDecoration(
              shape: BoxShape.circle, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

// ── Input Area ──────────────────────────────────────────────────────────────
class _InputArea extends ConsumerWidget {
  final TextEditingController textController;
  final ChatbotState chatbot;
  final VoidCallback onSend;

  const _InputArea({
    required this.textController,
    required this.chatbot,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isListening = chatbot.status == ChatbotStatus.listening;
    final isThinking  = chatbot.status == ChatbotStatus.thinking;
    final isSpeaking  = chatbot.status == ChatbotStatus.speaking;
    final isManual    = chatbot.micMode == MicMode.manual;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.backgroundSecondary,
        border: Border(top: BorderSide(color: AppColors.surfaceLight)),
      ),
      child: Row(children: [
        // ── Mic button ────────────────────────────────────────────────
        GestureDetector(
          onTap: () => ref.read(chatbotProvider.notifier).toggleManualMic(),
          onLongPress: () =>
              ref.read(chatbotProvider.notifier).toggleAutoVad(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 50, height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isListening
                  ? (isManual ? AppColors.danger : AppColors.warning)
                  : AppColors.primary.withValues(alpha: 0.2),
              border: Border.all(
                color: isListening
                    ? (isManual ? AppColors.danger : AppColors.warning)
                    : AppColors.primary,
              ),
              boxShadow: isListening
                  ? [BoxShadow(
                      color: (isManual ? AppColors.danger : AppColors.warning)
                          .withValues(alpha: 0.5),
                      blurRadius: 12, spreadRadius: 4)]
                  : null,
            ),
            child: Stack(alignment: Alignment.center, children: [
              Icon(
                isListening ? Icons.mic : Icons.mic_none,
                color: isListening ? Colors.white : AppColors.primaryLight,
                size: 24,
              ),
              // Mode badge
              Positioned(
                right: 4, bottom: 4,
                child: Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: chatbot.autoVadActive
                        ? AppColors.success
                        : AppColors.textHint,
                  ),
                  child: Icon(
                    chatbot.autoVadActive ? Icons.hearing : Icons.touch_app,
                    size: 8,
                    color: Colors.white,
                  ),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(width: 12),

        // ── Text field ────────────────────────────────────────────────
        Expanded(
          child: TextField(
            controller: textController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: isListening
                  ? (isManual
                      ? '🎙️ Speaking... tap mic to send'
                      : '🎙️ Listening... 5s silence to send')
                  : isSpeaking
                      ? '🔊 AI is speaking...'
                      : 'Ask your guide anything...',
              hintStyle: TextStyle(
                  color: isListening ? AppColors.danger : AppColors.textHint,
                  fontSize: 13),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: AppColors.surfaceLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(
                    color: AppColors.primaryLight, width: 2),
              ),
            ),
            maxLines: 3,
            minLines: 1,
            onSubmitted: (_) => onSend(),
            enabled: !isListening && !isThinking && !isSpeaking,
          ),
        ),
        const SizedBox(width: 12),

        // ── Send button ───────────────────────────────────────────────
        GestureDetector(
          onTap: isThinking ? null : onSend,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 50, height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isThinking ? AppColors.surface : AppColors.primary,
            ),
            child: isThinking
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: CircularProgressIndicator(
                        color: AppColors.primaryLight, strokeWidth: 2))
                : const Icon(Icons.send_rounded,
                    color: Colors.white, size: 22),
          ),
        ),
      ]),
    );
  }
}
