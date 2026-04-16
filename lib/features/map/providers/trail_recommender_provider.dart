import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../preferences/models/user_preferences_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  TRAIL MODEL  —  mirrors the TRAILS constant in constants.js
//
//  Firestore collection : "trails"
//  Document ID          : trail key  e.g. "silentGiant"
//
//  Expected Firestore fields (same names as constants.js TRAILS objects):
//    id          String   e.g. "silent_giant"
//    name        String
//    difficulty  String   'easy' | 'moderate' | 'hard'
//    environment String   'quiet' | 'bright'
//    interest    String   'history' | 'botany'
//    description String
//    distance    String   e.g. "2.5 km"
//    duration    String   e.g. "45 min"
//    elevation   String   e.g. "50 m"
//    features    Array<String>
//    latitude    number   (optional, for map marker / trail start)
//    longitude   number   (optional, for map marker / trail start)
//    coords      Array<{lat: number, lng: number}>  (optional, trail polyline)
// ─────────────────────────────────────────────────────────────────────────────
class TrailModel {
  final String docId;       // Firestore document ID  e.g. "silentGiant"
  final String id;          // trail id field          e.g. "silent_giant"
  final String name;
  final String difficulty;  // 'easy' | 'moderate' | 'hard'
  final String environment; // 'quiet' | 'bright'
  final String interest;    // 'history' | 'botany'
  final String description;
  final String distance;    // "2.5 km"
  final String duration;    // "45 min"
  final String elevation;   // "50 m"
  final List<String> features;
  final double latitude;
  final double longitude;
  /// Trail polyline coordinates fetched from Firestore `coords` field.
  /// Each element is a {lat, lng} map — same structure as the web-app.
  /// Empty list means no polyline stored yet (marker-only mode).
  final List<LatLng> coords;

  const TrailModel({
    required this.docId,
    required this.id,
    required this.name,
    required this.difficulty,
    required this.environment,
    required this.interest,
    required this.description,
    required this.distance,
    required this.duration,
    required this.elevation,
    required this.features,
    this.latitude  = 39.3551,
    this.longitude = 16.2232,
    this.coords    = const [],
  });

  /// Whether this trail has a drawable polyline stored in Firestore.
  bool get hasPolyline => coords.length >= 2;

  factory TrailModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    // ── Parse coords array  [{lat, lng}, ...] ──────────────────────────────
    final rawCoords = d['coords'] as List?;
    final List<LatLng> parsedCoords = [];
    if (rawCoords != null) {
      for (final pt in rawCoords) {
        if (pt is Map) {
          final lat = (pt['lat'] ?? pt['latitude']);
          final lng = (pt['lng'] ?? pt['longitude']);
          if (lat != null && lng != null) {
            parsedCoords.add(LatLng(
              (lat as num).toDouble(),
              (lng as num).toDouble(),
            ));
          }
        }
      }
    }

    // Fallback centre lat/lng — use first coord point if available
    final fallbackLat = parsedCoords.isNotEmpty
        ? parsedCoords.first.latitude
        : (d['latitude'] as num?)?.toDouble() ?? 39.3551;
    final fallbackLng = parsedCoords.isNotEmpty
        ? parsedCoords.first.longitude
        : (d['longitude'] as num?)?.toDouble() ?? 16.2232;

    return TrailModel(
      docId:       doc.id,
      id:          d['id']          as String? ?? doc.id,
      name:        d['name']        as String? ?? '',
      difficulty:  d['difficulty']  as String? ?? 'moderate',
      environment: d['environment'] as String? ?? 'bright',
      interest:    d['interest']    as String? ?? 'history',
      description: d['description'] as String? ?? '',
      distance:    d['distance']    as String? ?? '',
      duration:    d['duration']    as String? ?? '',
      elevation:   d['elevation']   as String? ?? '',
      features:    List<String>.from(d['features'] as List? ?? []),
      latitude:    fallbackLat,
      longitude:   fallbackLng,
      coords:      parsedCoords,
    );
  }

  // ── Difficulty display helpers ──────────────────────────────────────────
  String get difficultyEmoji {
    switch (difficulty) {
      case 'easy':     return '🟢';
      case 'moderate': return '🟡';
      case 'hard':     return '🔴';
      default:         return '⚪';
    }
  }

  String get environmentEmoji => environment == 'quiet' ? '🌲' : '☀️';

  String get interestEmoji => interest == 'history' ? '🏛️' : '🌿';
}

// ─────────────────────────────────────────────────────────────────────────────
//  TRAIL RECOMMENDATIONS  —  mirrors TRAIL_RECOMMENDATIONS in constants.js
//
//  Key format:  "{difficulty}_{environment}_{interest}"
//  e.g.         "moderate_quiet_history"  →  "ancientForest"
// ─────────────────────────────────────────────────────────────────────────────
const _trailRecommendations = {
  'easy_quiet_history':    'silentGiant',
  'easy_quiet_botany':     'silentGiant',
  'easy_bright_history':   'sunlitGlade',
  'easy_bright_botany':    'sunlitGlade',
  'moderate_quiet_history':'ancientForest',
  'moderate_quiet_botany': 'ancientForest',
  'moderate_bright_history':'mainParkLoop',
  'moderate_bright_botany': 'mainParkLoop',
  'hard_quiet_history':    'deepSilaRidge',
  'hard_quiet_botany':     'deepSilaRidge',
  'hard_bright_history':   'peakOfGiants',
  'hard_bright_botany':    'peakOfGiants',
};

// ─────────────────────────────────────────────────────────────────────────────
//  SEED TRAILS  —  mirrors TRAILS constant in constants.js exactly
//  Used as fallback when Firestore 'trails' collection is empty.
//  Seed trails include approximate polyline coords for the Sila park area.
// ─────────────────────────────────────────────────────────────────────────────
const List<TrailModel> _seedTrails = [
  TrailModel(
    docId: 'silentGiant', id: 'silent_giant',
    name: 'The Silent Giant Path',
    difficulty: 'easy', environment: 'quiet', interest: 'history',
    description: 'A peaceful walk among ancient pine giants with minimal elevation gain.',
    distance: '2.5 km', duration: '45 min', elevation: '50 m',
    features: ['Ancient Pines', 'Historical Markers', 'Wheelchair Accessible'],
    latitude: 39.358, longitude: 16.228,
    coords: [
      LatLng(39.358, 16.228), LatLng(39.3585, 16.2295), LatLng(39.359, 16.231),
      LatLng(39.3595, 16.2325), LatLng(39.360, 16.234), LatLng(39.3605, 16.235),
    ],
  ),
  TrailModel(
    docId: 'sunlitGlade', id: 'sunlit_glade',
    name: 'The Sunlit Glade',
    difficulty: 'easy', environment: 'bright', interest: 'botany',
    description: 'Open meadows with abundant wildflowers and excellent birding opportunities.',
    distance: '3 km', duration: '1 hour', elevation: '30 m',
    features: ['Wildflowers', 'Bird Watching', 'Photography Spots'],
    latitude: 39.362, longitude: 16.235,
    coords: [
      LatLng(39.362, 16.235), LatLng(39.3625, 16.237), LatLng(39.363, 16.239),
      LatLng(39.3635, 16.241), LatLng(39.364, 16.243), LatLng(39.3645, 16.245),
      LatLng(39.365, 16.247),
    ],
  ),
  TrailModel(
    docId: 'ancientForest', id: 'ancient_forest',
    name: 'Ancient Forest Loop',
    difficulty: 'moderate', environment: 'quiet', interest: 'history',
    description: 'Immerse yourself in old-growth forest with centuries-old trees.',
    distance: '5 km', duration: '2 hours', elevation: '150 m',
    features: ['Old Growth Forest', 'Scenic Viewpoints', 'Wildlife Habitat'],
    latitude: 39.370, longitude: 16.218,
    coords: [
      LatLng(39.370, 16.218), LatLng(39.371, 16.220), LatLng(39.372, 16.222),
      LatLng(39.373, 16.224), LatLng(39.374, 16.222), LatLng(39.373, 16.220),
      LatLng(39.372, 16.218), LatLng(39.371, 16.218), LatLng(39.370, 16.218),
    ],
  ),
  TrailModel(
    docId: 'deepSilaRidge', id: 'deep_sila_ridge',
    name: 'Deep Sila Ridge',
    difficulty: 'hard', environment: 'quiet', interest: 'botany',
    description: 'Challenging ridge hike through dense forest with diverse ecosystems.',
    distance: '8 km', duration: '3.5 hours', elevation: '400 m',
    features: ['Panoramic Views', 'Diverse Ecosystems', 'Adventure Trail'],
    latitude: 39.375, longitude: 16.245,
    coords: [
      LatLng(39.375, 16.245), LatLng(39.376, 16.248), LatLng(39.377, 16.251),
      LatLng(39.378, 16.254), LatLng(39.379, 16.257), LatLng(39.380, 16.260),
      LatLng(39.381, 16.263), LatLng(39.382, 16.266), LatLng(39.383, 16.269),
    ],
  ),
  TrailModel(
    docId: 'peakOfGiants', id: 'peak_of_giants',
    name: 'Peak of the Giants',
    difficulty: 'hard', environment: 'bright', interest: 'history',
    description: 'Summit hike offering breathtaking views of Sila National Park.',
    distance: '10 km', duration: '4 hours', elevation: '600 m',
    features: ['Summit Views', 'Historic Sites', 'Photo Opportunities'],
    latitude: 39.380, longitude: 16.255,
    coords: [
      LatLng(39.380, 16.255), LatLng(39.381, 16.258), LatLng(39.382, 16.261),
      LatLng(39.383, 16.264), LatLng(39.384, 16.267), LatLng(39.385, 16.270),
      LatLng(39.386, 16.273), LatLng(39.387, 16.276), LatLng(39.388, 16.279),
      LatLng(39.389, 16.282),
    ],
  ),
  TrailModel(
    docId: 'mainParkLoop', id: 'main_park_loop',
    name: 'Main Park Loop',
    difficulty: 'moderate', environment: 'bright', interest: 'botany',
    description: 'The classic Sila experience with varied terrain and scenery.',
    distance: '6 km', duration: '2.5 hours', elevation: '200 m',
    features: ['Varied Terrain', 'Family Friendly', 'Interpretive Signs'],
    latitude: 39.355, longitude: 16.225,
    coords: [
      LatLng(39.355, 16.225), LatLng(39.356, 16.228), LatLng(39.357, 16.231),
      LatLng(39.358, 16.234), LatLng(39.359, 16.237), LatLng(39.360, 16.234),
      LatLng(39.359, 16.231), LatLng(39.358, 16.228), LatLng(39.357, 16.225),
      LatLng(39.356, 16.225), LatLng(39.355, 16.225),
    ],
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
//  STATE
// ─────────────────────────────────────────────────────────────────────────────
class TrailRecommenderState {
  final List<TrailModel> allTrails;
  final TrailModel? recommended;   // The ONE recommended trail for this user
  final bool isLoading;
  final String? error;

  const TrailRecommenderState({
    this.allTrails  = const [],
    this.recommended,
    this.isLoading  = false,
    this.error,
  });

  TrailRecommenderState copyWith({
    List<TrailModel>? allTrails,
    TrailModel? recommended,
    bool? isLoading,
    String? error,
  }) {
    return TrailRecommenderState(
      allTrails:   allTrails   ?? this.allTrails,
      recommended: recommended ?? this.recommended,
      isLoading:   isLoading   ?? this.isLoading,
      error:       error       ?? this.error,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  NOTIFIER
// ─────────────────────────────────────────────────────────────────────────────
class TrailRecommenderNotifier extends StateNotifier<TrailRecommenderState> {
  TrailRecommenderNotifier() : super(const TrailRecommenderState());

  final _db = FirebaseFirestore.instance;

  /// Load trails from Firestore and apply TRAIL_RECOMMENDATIONS logic.
  /// Falls back to seed data (mirrors constants.js TRAILS) if offline/empty.
  Future<void> load(UserPreferences prefs) async {
    state = state.copyWith(isLoading: true, error: null);

    List<TrailModel> trails;
    bool usedSeed = false;
    try {
      final snapshot = await _db.collection('trails').get();
      if (snapshot.docs.isNotEmpty) {
        trails = snapshot.docs.map(TrailModel.fromFirestore).toList();
      } else {
        trails = _seedTrails;
        usedSeed = true;
      }
    } catch (_) {
      trails = _seedTrails;
      usedSeed = true;
    }

    // ── Apply TRAIL_RECOMMENDATIONS lookup (same logic as constants.js) ──
    final key = prefs.recommendationKey; // e.g. "moderate_quiet_history"
    final recommendedDocId = _trailRecommendations[key]; // e.g. "ancientForest"

    TrailModel? recommended;
    if (recommendedDocId != null) {
      try {
        recommended = trails.firstWhere((t) => t.docId == recommendedDocId);
      } catch (_) {
        recommended = trails.isNotEmpty ? trails.first : null;
      }
    } else {
      recommended = trails.isNotEmpty ? trails.first : null;
    }

    state = state.copyWith(
      allTrails:   trails,
      recommended: recommended,
      isLoading:   false,
      error: usedSeed ? 'Showing built-in trails (Firestore offline)' : null,
    );
  }
}

final trailRecommenderProvider =
    StateNotifierProvider<TrailRecommenderNotifier, TrailRecommenderState>(
        (ref) => TrailRecommenderNotifier());
