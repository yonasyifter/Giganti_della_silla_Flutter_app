import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/constants/app_constants.dart';

enum ChatRole { user, assistant, system }

enum ChatbotStatus { idle, listening, thinking, speaking, error }

/// How the microphone was activated
enum MicMode {
  /// Auto-VAD: detects voice, listens, submits after 5 s silence
  auto,
  /// Manual: user tapped mic — keeps listening until they tap again
  manual,
}

class ChatMessage {
  final String id;
  final ChatRole role;
  final String content;
  final DateTime timestamp;
  final bool isVoice;

  ChatMessage({
    required this.role,
    required this.content,
    this.isVoice = false,
  })  : id = DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp = DateTime.now();
}

class ChatbotState {
  final List<ChatMessage> messages;
  final ChatbotStatus status;
  final bool isInsidePark;
  final bool ttsEnabled;
  final String language;
  final String? error;
  final bool isInitialized;
  /// Current mic mode (only meaningful when status == listening)
  final MicMode micMode;
  /// Live partial transcript while speaking
  final String partialText;
  /// Whether auto-VAD is globally active (watching for voice)
  final bool autoVadActive;

  const ChatbotState({
    this.messages = const [],
    this.status = ChatbotStatus.idle,
    this.isInsidePark = false,
    this.ttsEnabled = true,
    this.language = 'en',
    this.error,
    this.isInitialized = false,
    this.micMode = MicMode.auto,
    this.partialText = '',
    this.autoVadActive = false,
  });

  ChatbotState copyWith({
    List<ChatMessage>? messages,
    ChatbotStatus? status,
    bool? isInsidePark,
    bool? ttsEnabled,
    String? language,
    String? error,
    bool? isInitialized,
    MicMode? micMode,
    String? partialText,
    bool? autoVadActive,
  }) {
    return ChatbotState(
      messages: messages ?? this.messages,
      status: status ?? this.status,
      isInsidePark: isInsidePark ?? this.isInsidePark,
      ttsEnabled: ttsEnabled ?? this.ttsEnabled,
      language: language ?? this.language,
      error: error ?? this.error,
      isInitialized: isInitialized ?? this.isInitialized,
      micMode: micMode ?? this.micMode,
      partialText: partialText ?? this.partialText,
      autoVadActive: autoVadActive ?? this.autoVadActive,
    );
  }
}

class ChatbotNotifier extends StateNotifier<ChatbotState> {
  final ApiService _api;
  final LocationService _locationService;
  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();

  // ── Silence timer for auto-VAD ─────────────────────────────────────────────
  Timer? _silenceTimer;
  static const _silenceTimeout = Duration(seconds: 5);

  // ── VAD polling timer (checks mic level periodically) ────────────────────
  Timer? _vadPollTimer;

  String _lastPartial = '';
  bool _sttAvailable = false;

  ChatbotNotifier(this._api, this._locationService)
      : super(const ChatbotState());

  // ─────────────────────────────────────────────────────────────────────────
  // Init
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> initialize() async {
    if (state.isInitialized) return;

    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    // Handle TTS completion
    _tts.setCompletionHandler(() {
      if (state.status == ChatbotStatus.speaking) {
        state = state.copyWith(status: ChatbotStatus.idle);
        // Re-enable auto VAD after speaking
        if (state.autoVadActive) _startVadPolling();
      }
    });

    _sttAvailable = await _stt.initialize(
      onStatus: _onSttStatus,
      onError: (e) {
        _silenceTimer?.cancel();
        if (state.status == ChatbotStatus.listening) {
          state = state.copyWith(
              status: ChatbotStatus.idle, partialText: '');
          // Restart VAD polling in auto mode
          if (state.autoVadActive) _startVadPolling();
        }
      },
    );

    final pos = await _locationService.getCurrentPosition();
    bool insidePark = false;
    if (pos != null) {
      insidePark = _locationService.isInsidePark(pos.latitude, pos.longitude);
    }

    state = state.copyWith(
      isInsidePark: insidePark,
      isInitialized: true,
      autoVadActive: _sttAvailable, // start auto VAD if mic available
    );

    await Future.delayed(
        const Duration(milliseconds: AppConstants.chatbotGreetingDelayMs));
    _sendGreeting(insidePark);

    // Start auto VAD polling
    if (_sttAvailable) _startVadPolling();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Auto VAD — polls every 500ms to start listening when user speaks
  // ─────────────────────────────────────────────────────────────────────────
  void _startVadPolling() {
    _vadPollTimer?.cancel();
    if (!state.autoVadActive) return;
    if (state.status == ChatbotStatus.speaking ||
        state.status == ChatbotStatus.thinking ||
        state.status == ChatbotStatus.listening) return;

    _vadPollTimer = Timer(const Duration(milliseconds: 300), () async {
      // Only trigger if idle and auto mode is on
      if (!mounted) return;
      if (state.status == ChatbotStatus.idle && state.autoVadActive) {
        await _startListeningInternal(mode: MicMode.auto);
      }
    });
  }

  void _onSttStatus(String status) {
    // 'notListening' fires when STT naturally stops (end of speech)
    if (status == 'notListening' && state.status == ChatbotStatus.listening) {
      if (state.micMode == MicMode.auto) {
        // Start silence countdown
        _silenceTimer?.cancel();
        _silenceTimer = Timer(_silenceTimeout, () {
          if (state.status == ChatbotStatus.listening &&
              state.micMode == MicMode.auto) {
            _submitPartialOrStop();
          }
        });
      }
      // Manual mode: just keeps waiting, timer not started
    }

    if (status == 'listening') {
      _silenceTimer?.cancel(); // reset when speech resumes
    }
  }

  void _submitPartialOrStop() {
    final text = _lastPartial.trim();
    _lastPartial = '';
    _stt.stop();
    state = state.copyWith(partialText: '');

    if (text.isNotEmpty) {
      sendMessage(text, isVoice: true);
    } else {
      state = state.copyWith(status: ChatbotStatus.idle);
      if (state.autoVadActive) _startVadPolling();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Core listen logic
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _startListeningInternal({required MicMode mode}) async {
    if (!_sttAvailable) return;
    if (state.status == ChatbotStatus.listening ||
        state.status == ChatbotStatus.thinking ||
        state.status == ChatbotStatus.speaking) return;

    _silenceTimer?.cancel();
    _lastPartial = '';
    state = state.copyWith(
      status: ChatbotStatus.listening,
      micMode: mode,
      partialText: '',
      error: null,
    );

    final locale = _localeId();

    await _stt.listen(
      onResult: (SpeechRecognitionResult result) {
        _lastPartial = result.recognizedWords;
        state = state.copyWith(partialText: result.recognizedWords);

        if (result.finalResult && result.recognizedWords.isNotEmpty) {
          if (mode == MicMode.auto) {
            // Auto: reset silence timer — will submit after 5s quiet
            _silenceTimer?.cancel();
            _silenceTimer = Timer(_silenceTimeout, _submitPartialOrStop);
          }
          // Manual: wait for user to tap mic again — do nothing here
        }
      },
      localeId: locale,
      listenFor: const Duration(minutes: 5), // long max
      pauseFor: mode == MicMode.auto
          ? const Duration(seconds: 2) // short pause triggers onStatus notListening
          : const Duration(minutes: 5), // manual: almost never auto-pauses
      partialResults: true,
      onSoundLevelChange: (level) {
        // Sound detected — cancel silence timer while user is speaking
        if (level > -20 && state.micMode == MicMode.auto) {
          _silenceTimer?.cancel();
        }
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Public: Manual mic toggle
  // ─────────────────────────────────────────────────────────────────────────

  /// Called when user taps the mic button
  Future<void> toggleManualMic() async {
    if (state.status == ChatbotStatus.listening &&
        state.micMode == MicMode.manual) {
      // User taps again to stop → submit whatever was said
      _submitPartialOrStop();
    } else if (state.status == ChatbotStatus.listening &&
        state.micMode == MicMode.auto) {
      // Switch to manual mode (keep listening, just change mode)
      _silenceTimer?.cancel();
      state = state.copyWith(micMode: MicMode.manual);
    } else {
      // Start manual listening
      _vadPollTimer?.cancel();
      await _startListeningInternal(mode: MicMode.manual);
    }
  }

  /// Stop manual mic → submit
  Future<void> stopListening() async {
    _silenceTimer?.cancel();
    _submitPartialOrStop();
  }

  /// Legacy — kept for compatibility
  Future<void> startListening() => toggleManualMic();

  // ─────────────────────────────────────────────────────────────────────────
  // Send message
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> sendMessage(String text, {bool isVoice = false}) async {
    if (text.trim().isEmpty) return;
    _vadPollTimer?.cancel();
    _silenceTimer?.cancel();
    _addUserMessage(text.trim(), isVoice: isVoice);

    // Build history for context (last 8 messages, alternating user/assistant)
    final history = state.messages
        .where((m) => m.role == ChatRole.user || m.role == ChatRole.assistant)
        .toList()
        .reversed
        .take(8)
        .toList()
        .reversed
        .map((m) => {
              'role': m.role == ChatRole.user ? 'user' : 'assistant',
              'content': m.content,
            })
        .toList();

    try {
      final response = await _api.sendChatMessage(
        message: text.trim(),
        language: state.language,
        history: history,
      );
      final answer = response['answer'] as String? ??
          'Sorry, I could not get a response.';
      _addAssistantMessage(answer, speak: isVoice || state.ttsEnabled);
    } catch (e) {
      _addAssistantMessage(
        '⚠️ I had trouble connecting. Please check your internet connection.',
        speak: false,
      );
      // Re-enable VAD after error
      if (state.autoVadActive) _startVadPolling();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────
  String _localeId() {
    switch (state.language) {
      case 'it': return 'it_IT';
      case 'fr': return 'fr_FR';
      case 'de': return 'de_DE';
      case 'es': return 'es_ES';
      default:   return 'en_US';
    }
  }

  void _addAssistantMessage(String content, {bool speak = false}) {
    final msg = ChatMessage(role: ChatRole.assistant, content: content);
    state = state.copyWith(
      messages: [...state.messages, msg],
      status: ChatbotStatus.idle,
      partialText: '',
    );
    if (speak && state.ttsEnabled) {
      _speak(content);
    } else if (state.autoVadActive) {
      _startVadPolling();
    }
  }

  void _addUserMessage(String content, {bool isVoice = false}) {
    final msg =
        ChatMessage(role: ChatRole.user, content: content, isVoice: isVoice);
    state = state.copyWith(
      messages: [...state.messages, msg],
      status: ChatbotStatus.thinking,
      partialText: '',
    );
  }

  Future<void> _speak(String text) async {
    state = state.copyWith(status: ChatbotStatus.speaking);
    final clean = text.replaceAll(
        RegExp(r'[\u{1F000}-\u{1FFFF}]', unicode: true), '');
    await _tts.speak(clean);
    await _tts.awaitSpeakCompletion(true);
    if (state.status == ChatbotStatus.speaking) {
      state = state.copyWith(status: ChatbotStatus.idle);
      if (state.autoVadActive) _startVadPolling();
    }
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
    state = state.copyWith(status: ChatbotStatus.idle);
    if (state.autoVadActive) _startVadPolling();
  }

  void toggleTts() {
    if (state.ttsEnabled) stopSpeaking();
    state = state.copyWith(ttsEnabled: !state.ttsEnabled);
  }

  void toggleLanguage() {
    final newLang = state.language == 'en' ? 'it' : 'en';
    state = state.copyWith(language: newLang);
    _tts.setLanguage(newLang == 'it' ? 'it-IT' : 'en-US');
  }

  void toggleAutoVad() {
    final next = !state.autoVadActive;
    state = state.copyWith(autoVadActive: next);
    if (next) {
      _startVadPolling();
    } else {
      _vadPollTimer?.cancel();
      if (state.status == ChatbotStatus.listening &&
          state.micMode == MicMode.auto) {
        _silenceTimer?.cancel();
        _stt.stop();
        state = state.copyWith(status: ChatbotStatus.idle);
      }
    }
  }

  void clearChat() {
    stopSpeaking();
    _silenceTimer?.cancel();
    _vadPollTimer?.cancel();
    state = state.copyWith(
        messages: [], status: ChatbotStatus.idle, partialText: '');
    _sendGreeting(state.isInsidePark);
  }

  void _sendGreeting(bool insidePark) {
    final greeting = insidePark
        ? "🏔️ Welcome to Parco Nazionale della Silla! I'm your AI trail guide. "
            "I can see you're in the park — fantastic! "
            "What kind of hike are you looking for today?"
        : "👋 Hello, hiker! I'm your HikeSilla AI guide. "
            "Are you planning a hike at Parco della Silla soon? "
            "I can help you pick the best trail and check weather forecasts!";
    _addAssistantMessage(greeting, speak: true);
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _vadPollTimer?.cancel();
    _tts.stop();
    _stt.stop();
    super.dispose();
  }
}

final chatbotProvider =
    StateNotifierProvider<ChatbotNotifier, ChatbotState>((ref) {
  return ChatbotNotifier(ApiService(), LocationService());
});
