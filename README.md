# HikeSilla — Parco Nazionale della Silla Explorer

**HikeSilla** is a comprehensive, IoT-integrated Flutter mobile application designed for visitors of the Parco Nazionale della Silla (Sila National Park) in Calabria, Italy. It serves as the mobile companion to the Smart Park IoT web platform, providing hikers with real-time environmental data, AI-driven trail recommendations, and advanced safety features.

---

## 🌟 Key Features

### 🗺️ Smart Trail Mapping & Navigation
- **Interactive Map:** Built on `flutter_map` with OpenStreetMap tiles, featuring offline fallback support.
- **Dynamic Polylines:** Trails are fetched directly from Firestore and rendered as colour-coded polylines on the map.
- **Live Progress Tracking:** The app calculates your exact position along the trail polyline and displays your completion percentage in real time.

### 🤖 AI Guide & Chatbot
- **Context-Aware Assistant:** A smart chatbot that answers questions about park flora, fauna, history, and safety.
- **Multilingual Voice Support:** Features Speech-to-Text (STT) and Text-to-Speech (TTS) in 5 languages (English, Italian, French, German, Spanish).
- **Fallback Architecture:** Connects to a local FastAPI/Groq backend, with an automatic fallback to direct OpenAI API calls if the local server is unreachable.

### 🌤️ IoT Weather & Sensor Integration
- **Live Environmental Data:** Connects directly to the park's IoT sensor network (via InfluxDB/FastAPI) to display real-time metrics.
- **Comprehensive Readings:** Monitors Temperature, Humidity, Pressure, Light (lux), Noise (dB), Time-of-Flight (ToF) distance, Tilt Angle, and 3-axis Accelerometer/Vibration data.
- **AI Weather Predictions:** Displays machine-learning-based microclimate predictions directly from the sensor nodes.

### 🎯 Intelligent Trail Recommendations
- **Personalized Matching:** Users set preferences for difficulty, noise tolerance, botanical/historical interests, slope, and vibe.
- **Instant Filtering:** The app immediately cross-references preferences with the Firestore trail database to recommend the perfect hike.

### 🛡️ Safety & Tracking Tools
- **Live Hiker Tracking:** Real-time dashboard showing GPS coordinates, altitude, compass heading, speed, and distance walked.
- **Car Parking Memory:** Save your car's GPS location with a single tap, monitor your distance from it, and navigate back using Google Maps/Apple Maps.
- **SOS Emergency System:** Dedicated emergency alert system that broadcasts the hiker's exact coordinates.

### 🌗 Modern UI & Accessibility
- **Dark & Light Modes:** Full support for both themes with persistent saving via `SharedPreferences`.
- **Multilingual:** Full app localization in English, Italian, French, German, and Spanish.

---

## 🏗️ Architecture & Tech Stack

- **Framework:** Flutter (Dart)
- **State Management:** Riverpod (`flutter_riverpod`)
- **Routing:** GoRouter (`go_router`)
- **Backend / Database:** Firebase Authentication & Cloud Firestore
- **IoT / API Client:** Dio (`dio`) for REST API communication
- **Mapping:** `flutter_map` & `latlong2`
- **Sensors:** `geolocator`, `sensors_plus`, `compass`

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (v3.19+)
- Dart SDK (v3.3+)
- A Firebase project with Authentication and Firestore enabled
- (Optional) The Smart Park IoT FastAPI backend running locally or on a server

### 1. Clone the Repository
```bash
git clone https://github.com/yonasyifter/Giganti_della_silla_Flutter_app.git
cd Giganti_della_silla_Flutter_app
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Configure Environment Variables
If you are testing on a physical Android device and want to connect to your PC's local IoT backend, update the IP address in `lib/core/constants/app_constants.dart`:

```dart
// Change this to your PC's local network IP (e.g., 192.168.1.100)
static const String baseUrl = 'http://192.168.1.100:8000';
static const String weatherApiBaseUrl = baseUrl;
```

If you want the AI Guide fallback to work, ensure you provide an OpenAI API key at build time:
```bash
flutter run --dart-define=OPENAI_API_KEY=your_api_key_here
```

### 4. Firebase Setup
The project uses `firebase_options.dart`. Ensure you have run `flutterfire configure` to link the app to your specific Firebase instance.

### 5. Run the App
```bash
flutter run
```

---

## 🗄️ Firestore Database Schema

To fully utilize the map and recommendation features, your Firestore database should follow this structure:

### Collection: `trails`
```json
{
  "id": "t1",
  "name": "Sentiero dei Giganti",
  "difficulty": "Moderate",
  "distance_km": 8.2,
  "duration_mins": 180,
  "elevation_gain_m": 320,
  "description": "A stunning hike through ancient Calabrian pines.",
  "features": ["Ancient Pines", "History", "Moderate Slope"],
  "coords": [
    { "lat": 39.358, "lng": 16.228 },
    { "lat": 39.359, "lng": 16.231 }
  ]
}
```
*(Note: The `coords` array is required for the app to draw the trail polyline on the map).*

---

## 🤝 Alignment with Smart Park IoT Web-App

This mobile application is built to work seamlessly alongside the `smart-park-iot` web platform:
- **Shared Data:** Both platforms read from the exact same `trails` and `user_trail_selections` Firestore collections.
- **Shared Polyline Format:** The mobile app's map engine parses the same `{lat, lng}` coordinate arrays used by the web-app's Leaflet implementation.
- **Shared IoT Backend:** The weather screen fetches data from the same InfluxDB/FastAPI endpoints that power the web dashboard.

---

## 📄 License

This project is licensed under the MIT License.
