import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late final Dio _dio;
  late final Dio _openAiDio;

  void init() {
    // ── Local FastAPI backend ────────────────────────────────────────────────
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final token = await user.getIdToken();
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) => handler.next(error),
    ));

    // ── OpenAI-compatible fallback ───────────────────────────────────────────
    _openAiDio = Dio(BaseOptions(
      baseUrl: 'https://openrouter.ai/api/v1',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
        'Authorization':
            'Bearer ${const String.fromEnvironment('OPENAI_API_KEY', defaultValue: '')}',
        'HTTP-Referer': 'https://hikesilla.app',
        'X-Title': 'HikeSilla AI Guide',
      },
    ));
  }

  // ── Weather forecast ─────────────────────────────────────────────────────
  Future<List<dynamic>> getWeatherForecast({int minutes = 60}) async {
    final response = await _dio.get(
      AppConstants.weatherForecastEndpoint,
      queryParameters: {'minutes': minutes},
    );
    return response.data as List<dynamic>;
  }

  // ── Location ping ────────────────────────────────────────────────────────
  Future<void> sendLocationPing({
    required double lat,
    required double lng,
  }) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
      await _dio.post(
        AppConstants.locationPingEndpoint,
        data: {
          'user_id': uid,
          'latitude': lat,
          'longitude': lng,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (_) {}
  }

  // ── Chatbot — tries local FastAPI first, falls back to OpenAI ────────────
  Future<Map<String, dynamic>> sendChatMessage({
    required String message,
    String language = 'en',
    String? deviceDataJson,
    List<Map<String, String>>? history,
  }) async {
    // 1. Try local FastAPI / Groq RAG backend
    try {
      final formData = FormData.fromMap({
        'user_query': message,
        'language': language,
        if (deviceDataJson != null) 'device_data': deviceDataJson,
      });
      final response = await _dio.post(
        AppConstants.chatEndpoint,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return response.data as Map<String, dynamic>;
    } catch (_) {
      // Local server unreachable — fall back to direct OpenAI call
    }

    // 2. Fallback: direct OpenAI-compatible call
    return _openAiFallback(
        message: message, language: language, history: history);
  }

  // ── OpenAI fallback implementation ───────────────────────────────────────
  Future<Map<String, dynamic>> _openAiFallback({
    required String message,
    String language = 'en',
    List<Map<String, String>>? history,
  }) async {
    final systemPrompt = _buildSystemPrompt(language);

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
      // Include recent history (last 6 messages) for context
      if (history != null) ...history.take(6),
      {'role': 'user', 'content': message},
    ];

    try {
      final response = await _openAiDio.post(
        '/chat/completions',
        data: {
          'model': 'openai/gpt-4.1-mini',
          'messages': messages,
          'max_tokens': 512,
          'temperature': 0.7,
        },
      );
      final data = response.data as Map<String, dynamic>;
      final content = data['choices']?[0]?['message']?['content'] as String? ??
          'Sorry, I could not get a response.';
      return {'answer': content};
    } catch (e) {
      // Final fallback: offline response
      return {
        'answer': _offlineResponse(message, language),
      };
    }
  }

  // ── System prompt for the AI Guide ──────────────────────────────────────
  String _buildSystemPrompt(String language) {
    const parkInfo = '''
You are an expert AI hiking guide for Parco Nazionale della Sila (Sila National Park) in Calabria, Italy.
The park covers about 73,695 hectares of the Sila plateau, featuring ancient Calabrian pine forests, 
glacial lakes (Lago Arvo, Lago Ampollino, Lago Cecita), diverse wildlife (wolves, deer, otters, eagles), 
and rich biodiversity.

Key trails in the park:
- Sentiero dei Giganti (Giants Trail): 8.2 km, moderate, through ancient Calabrian pines
- Lago Arvo Loop: 5.5 km, easy, scenic lake circuit
- Monte Botte Donato: 12 km, hard, highest peak at 1928m
- Valle del Neto: 6.8 km, moderate, river valley and waterfalls
- Bosco di Gallopane: 4.2 km, easy, ancient forest reserve

You help visitors:
1. Choose the right trail based on their fitness level and interests
2. Understand park flora (Calabrian pine, silver fir, beech, orchids) and fauna (Sila wolf, roe deer, black woodpecker)
3. Check safety conditions and weather considerations
4. Learn about the park's history and cultural heritage
5. Navigate the HikeSilla app features

Always be friendly, informative, and safety-conscious. Keep responses concise (2-4 sentences) unless detailed information is requested.
''';

    final langInstruction = switch (language) {
      'it' => 'Respond in Italian (Italiano).',
      'fr' => 'Respond in French (Français).',
      'de' => 'Respond in German (Deutsch).',
      'es' => 'Respond in Spanish (Español).',
      _ => 'Respond in English.',
    };

    return '$parkInfo\n$langInstruction';
  }

  // ── Offline response when all APIs fail ─────────────────────────────────
  String _offlineResponse(String message, String language) {
    final responses = {
      'en': '⚠️ I\'m currently offline. For trail information, check the Trails screen. '
          'For emergencies, use the SOS button. I\'ll be back online shortly!',
      'it': '⚠️ Sono attualmente offline. Per informazioni sui sentieri, controlla la schermata Sentieri. '
          'Per emergenze, usa il pulsante SOS.',
      'fr': '⚠️ Je suis actuellement hors ligne. Pour les informations sur les sentiers, '
          'consultez l\'écran Sentiers. Pour les urgences, utilisez le bouton SOS.',
      'de': '⚠️ Ich bin derzeit offline. Für Weginfo, schauen Sie auf den Wanderwege-Bildschirm. '
          'Für Notfälle nutzen Sie den SOS-Knopf.',
      'es': '⚠️ Estoy sin conexión. Para información de senderos, revisa la pantalla Senderos. '
          'Para emergencias, usa el botón SOS.',
    };
    return responses[language] ?? responses['en']!;
  }

  // ── TTS ──────────────────────────────────────────────────────────────────
  Future<List<int>> getTTS(String text, {String language = 'en'}) async {
    final formData = FormData.fromMap({'text': text, 'language': language});
    final response = await _dio.post(
      AppConstants.ttsEndpoint,
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        responseType: ResponseType.bytes,
      ),
    );
    return response.data as List<int>;
  }

  // ── SOS ──────────────────────────────────────────────────────────────────
  Future<void> sendSOS({
    required double lat,
    required double lng,
    required String message,
  }) async {
    await _dio.post(
      AppConstants.sosAlertEndpoint,
      data: {
        'latitude': lat,
        'longitude': lng,
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // ── Google Calendar ──────────────────────────────────────────────────────
  Future<void> scheduleHike({
    required String trailName,
    required DateTime dateTime,
    String? notes,
  }) async {
    await _dio.post(
      AppConstants.calendarScheduleEndpoint,
      data: {
        'trail_name': trailName,
        'scheduled_date': dateTime.toIso8601String(),
        'notes': notes,
      },
    );
  }
}
