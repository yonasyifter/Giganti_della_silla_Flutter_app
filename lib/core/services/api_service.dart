import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late final Dio _dio;

  void init() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    // Attach Firebase ID token to every FastAPI request
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
  }
  Future<List<dynamic>> getWeatherForecast({int minutes = 60}) async {
    final response = await _dio.get(
      AppConstants.weatherForecastEndpoint,
      queryParameters: {'minutes': minutes},
    );
    return response.data as List<dynamic>;
  }

  // Location ping to admin (uses Firebase UID automatically)
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

  // Chatbot (Groq RAG)
  Future<Map<String, dynamic>> sendChatMessage({
    required String message,
    String language = 'en',
    String? deviceDataJson,
  }) async {
    final formData = FormData.fromMap({
      'user_query': message,
      'language': language,
      'device_data': ?deviceDataJson,
    });
    final response = await _dio.post(
      AppConstants.chatEndpoint,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return response.data;
  }

  // TTS
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

  // SOS
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

  // Google Calendar
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
