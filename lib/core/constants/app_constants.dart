class AppConstants {
  // ── FastAPI backend (weather sensors + AI chatbot) ────────────────────────
  // NOTE: Replace with your PC's local network IP when running on a real device.
  // Find your IP: `ipconfig` (Windows) or `ifconfig` (Mac/Linux)
  // Example: static const String baseUrl = 'http://192.168.1.100:8000';
  static const String baseUrl = 'http://localhost:8000';
  static const String wsBaseUrl = 'ws://localhost:8000';

  // ── Weather IoT API ───────────────────────────────────────────────────────
  // Same host as baseUrl. Override this constant with your LAN IP when testing
  // on a physical Android device so the phone can reach the Docker container:
  //   static const String weatherApiBaseUrl = 'http://192.168.1.100:8000';
  static const String weatherApiBaseUrl = baseUrl;

  // Sensor measurement name used in the InfluxDB query
  static const String weatherMeasurement = 'Sensor_S6000U_data2';

  // Weather / sensor endpoints (FastAPI + InfluxDB)
  static const String weatherForecastEndpoint = '/api/weather/forecast/';

  // Chatbot endpoints (Groq RAG — same as admin web)
  static const String chatEndpoint = '/api/rag/chat';
  static const String ttsEndpoint = '/api/rag/tts';

  // Hiker-specific endpoints (add to FastAPI backend)
  static const String locationPingEndpoint = '/api/location/ping';
  static const String sosAlertEndpoint = '/api/alerts/sos';
  static const String calendarScheduleEndpoint = '/api/calendar/schedule';

  // WebSocket
  static const String locationWsEndpoint = '/ws/location';

  // Parco Nazionale della Silla — bounding box
  static const double parkCenterLat = 39.85;
  static const double parkCenterLng = 16.55;
  static const double parkRadiusKm = 20.0;
  static const double parkNorthLat = 39.95;
  static const double parkSouthLat = 39.70;
  static const double parkEastLng  = 16.70;
  static const double parkWestLng  = 16.35;

  // GPS update interval (seconds)
  static const int locationUpdateIntervalSec = 30;

  // Chatbot
  static const int chatbotGreetingDelayMs = 1500;
  static const String defaultLanguage = 'en';

  // Firestore collections
  static const String firestoreUsersCollection = 'userPreferences';
  static const String firestoreTrailsCollection = 'trails';

  // Notification channels
  static const String sosChannelId = 'sos_channel';
  static const String sosChannelName = 'SOS Alerts';
  static const String weatherChannelId = 'weather_channel';
  static const String weatherChannelName = 'Weather Updates';

  // App info
  static const String appName = 'HikeSilla';
  static const String appTagline = 'Parco Nazionale della Silla';

  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String usernameKey = 'username';
}
