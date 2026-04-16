# HikeSilla — Smart Hiking App for Parco Nazionale della Silla

A Flutter mobile application for visitors of the **Parco Nazionale della Silla** (Calabria, Italy). It provides real-time trail navigation, Firebase-fetched trail data with polyline maps, AI-powered trail recommendations, live weather/sensor data, and emergency SOS.

---

## Features

### Trail Map (Enhanced)
- **Firebase-fetched trails** — all trails are loaded from the Firestore `trails` collection in real time
- **Trail polylines** — each trail is drawn as a coloured route on the OpenStreetMap base layer, colour-coded by difficulty (green = easy, yellow = moderate, red = hard)
- **Start/End markers** — the active trail shows a green play marker at the start and a flag at the end
- **Trail selection** — tap any trail marker to preview it; tap "Start Trail" to activate it
- **Trail progress tracking** — live GPS position is compared against the trail polyline to calculate and display % completion
- **Fit to bounds** — tapping "My Trail" or the progress strip fits the map camera to the active trail's bounding box
- **Layer switcher** — toggle between Trails, Weather sensors, and Hiker-only views
- **Offline fallback** — if Firestore is unavailable, built-in seed trails with approximate polyline coordinates are used

### Trails List Screen
- Full-screen trail browser with difficulty filter chips (All / Easy / Moderate / Hard)
- Recommended trail banner (based on user preferences via AI recommendation logic)
- Active trail progress banner with "View on Map" shortcut
- Trail detail bottom sheet with stats, highlights, and "Start Trail" / "View on Map" buttons
- Trail selection is persisted to Firestore `user_trail_selections` collection (mirrors web-app)

### Firebase Data Structure

#### `trails` collection (read by mobile app)
```json
{
  "id":          "silent_giant",
  "name":        "The Silent Giant Path",
  "difficulty":  "easy",
  "environment": "quiet",
  "interest":    "history",
  "description": "...",
  "distance":    "2.5 km",
  "duration":    "45 min",
  "elevation":   "50 m",
  "features":    ["Ancient Pines", "Historical Markers"],
  "latitude":    39.358,
  "longitude":   16.228,
  "coords": [
    { "lat": 39.358, "lng": 16.228 },
    { "lat": 39.359, "lng": 16.231 }
  ]
}
```

#### `user_trail_selections` collection (written by mobile app)
```json
{
  "userId":     "<firebase_uid>",
  "trailId":    "silentGiant",
  "trailName":  "The Silent Giant Path",
  "selectedAt": "2025-01-01T10:00:00.000Z",
  "createdAt":  "<server_timestamp>"
}
```

### AI Trail Recommendation
Mirrors the `TRAIL_RECOMMENDATIONS` logic from the web-app (`constants.js`):
- User sets preferences (difficulty, noise preference, interest)
- App derives a recommendation key: `{difficulty}_{environment}_{interest}`
- Key is looked up in the recommendation table to find the best matching trail

---

## Project Structure

```
lib/
├── core/
│   ├── constants/       app_colors.dart, app_constants.dart
│   ├── l10n/            app_localizations.dart (5 languages)
│   ├── services/        router_service.dart, api_service.dart, location_service.dart
│   └── theme/           app_theme.dart
└── features/
    ├── auth/            login, register, forgot password, splash
    ├── chatbot/         AI chatbot screen
    ├── emergency/       SOS screen
    ├── home/            home screen with quick actions
    ├── map/
    │   ├── providers/
    │   │   ├── trail_recommender_provider.dart   (Firebase trail fetching + AI recommendation)
    │   │   └── trail_selection_provider.dart     (active trail + progress tracking)
    │   └── screens/
    │       ├── map_screen.dart                   (map with polylines + trail preview)
    │       └── trails_list_screen.dart           (full trail browser)
    ├── preferences/     user preferences (difficulty, noise, interest)
    ├── settings/        language & app settings
    ├── tracking/        GPS tracking provider
    └── weather/         weather/sensor data provider
```

---

## Setup

### Prerequisites
- Flutter 3.22+
- Firebase project with Firestore and Authentication enabled
- `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) in place

### Firebase Firestore Security Rules
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /trails/{trailId} {
      allow read: if request.auth != null;
    }
    match /userPreferences/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
    match /user_trail_selections/{docId} {
      allow create: if request.auth != null;
      allow read: if request.auth != null;
    }
  }
}
```

### Running
```bash
flutter pub get
flutter run
```

---

## Web-App Alignment

This mobile app is the **visitor/user-side companion** to the [smart-park-iot](https://github.com/jhenals/smart-park-iot) web-app.

| Web-App Feature | Mobile App Feature |
|---|---|
| Trail polylines from `coords` field | `TrailModel.coords` → `PolylineLayer` |
| `TRAIL_RECOMMENDATIONS` lookup | `_trailRecommendations` map in provider |
| `user_trail_selections` Firestore writes | `TrailSelectionNotifier.selectTrail()` |
| `calculateTrailProgress()` in JS | `TrailSelectionNotifier.updateProgress()` |
| Trail difficulty colour coding | `_difficultyColor()` in map/list screens |
| Start/End markers on active trail | `MarkerLayer` with play/flag icons |

---

## Credits
- **Park**: Parco Nazionale della Silla, Calabria, Italy
- **Map tiles**: OpenStreetMap contributors
- **Map package**: [flutter_map](https://pub.dev/packages/flutter_map)
- **Backend**: FastAPI + Firebase + InfluxDB (smart-park-iot)
