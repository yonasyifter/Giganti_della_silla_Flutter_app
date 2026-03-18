/// User Preferences — mirrors TRAIL_PREFERENCES from constants.js
///
/// Firestore collection : "userPreferences"
/// Document ID          : Firebase Auth UID
///
/// Firestore document structure:
/// {
///   "difficulty"       : "easy" | "moderate" | "hard",
///   "noise"            : "very_quiet" | "comfortable" | "noticeable",
///   "slope"            : "steep" | "moderate" | "flat",
///   "vibe"             : "frosty" | "moody" | "brisk" |
///                        "serene_mild" | "crisp_clear" | "sun_drenched",
///   "width"            : "narrow" | "moderate" | "wide",
///   "interest"         : "history" | "botany",
///   "language"         : "en" | "it",
///   "voiceGuideEnabled": true | false,
///   "visitCount"       : number,
///   "updatedAt"        : ISO string
/// }
library;

class UserPreferences {
  final String uid;

  /// From TRAIL_PREFERENCES — maps to TRAILS.difficulty
  final String difficulty; // 'easy' | 'moderate' | 'hard'

  /// From TRAIL_PREFERENCES.noise
  final String noise; // 'very_quiet' | 'comfortable' | 'noticeable'

  /// From TRAIL_PREFERENCES.slope
  final String slope; // 'steep' | 'moderate' | 'flat'

  /// From TRAIL_PREFERENCES.vibe
  final String vibe;
  // 'frosty'|'moody'|'brisk'|'serene_mild'|'crisp_clear'|'sun_drenched'

  /// From TRAIL_PREFERENCES.width
  final String width; // 'narrow' | 'moderate' | 'wide'

  /// Primary interest — maps to TRAIL_RECOMMENDATIONS key suffix
  final String interest; // 'history' | 'botany'

  /// AI guide language
  final String language; // 'en' | 'it'

  /// Voice guide on/off
  final bool voiceGuideEnabled;

  /// Park visit counter
  final int visitCount;

  const UserPreferences({
    required this.uid,
    this.difficulty = 'moderate',
    this.noise = 'comfortable',
    this.slope = 'moderate',
    this.vibe = 'serene_mild',
    this.width = 'moderate',
    this.interest = 'history',
    this.language = 'en',
    this.voiceGuideEnabled = true,
    this.visitCount = 0,
  });

  factory UserPreferences.defaults(String uid) => UserPreferences(uid: uid);

  /// Derives "environment" used in TRAIL_RECOMMENDATIONS key:
  ///   very_quiet → 'quiet'
  ///   comfortable | noticeable → 'bright'
  String get environment => noise == 'very_quiet' ? 'quiet' : 'bright';

  /// Builds the TRAIL_RECOMMENDATIONS lookup key, e.g. "moderate_quiet_history"
  /// Matches exactly: TRAIL_RECOMMENDATIONS[difficulty_environment_interest]
  String get recommendationKey => '${difficulty}_${environment}_$interest';

  factory UserPreferences.fromFirestore(Map<String, dynamic> d, String uid) {
    return UserPreferences(
      uid: uid,
      difficulty: d['difficulty'] as String? ?? 'moderate',
      noise:      d['noise']      as String? ?? 'comfortable',
      slope:      d['slope']      as String? ?? 'moderate',
      vibe:       d['vibe']       as String? ?? 'serene_mild',
      width:      d['width']      as String? ?? 'moderate',
      interest:   d['interest']   as String? ?? 'history',
      language:   d['language']   as String? ?? 'en',
      voiceGuideEnabled: d['voiceGuideEnabled'] as bool? ?? true,
      visitCount: (d['visitCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'difficulty'       : difficulty,
    'noise'            : noise,
    'slope'            : slope,
    'vibe'             : vibe,
    'width'            : width,
    'interest'         : interest,
    'language'         : language,
    'voiceGuideEnabled': voiceGuideEnabled,
    'visitCount'       : visitCount,
    'updatedAt'        : DateTime.now().toIso8601String(),
  };

  UserPreferences copyWith({
    String? difficulty,
    String? noise,
    String? slope,
    String? vibe,
    String? width,
    String? interest,
    String? language,
    bool? voiceGuideEnabled,
    int? visitCount,
  }) {
    return UserPreferences(
      uid: uid,
      difficulty:        difficulty        ?? this.difficulty,
      noise:             noise             ?? this.noise,
      slope:             slope             ?? this.slope,
      vibe:              vibe              ?? this.vibe,
      width:             width             ?? this.width,
      interest:          interest          ?? this.interest,
      language:          language          ?? this.language,
      voiceGuideEnabled: voiceGuideEnabled ?? this.voiceGuideEnabled,
      visitCount:        visitCount        ?? this.visitCount,
    );
  }

  bool get isFirstTime => visitCount == 0;
}
