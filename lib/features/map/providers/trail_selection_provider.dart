import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'trail_recommender_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  TRAIL SELECTION STATE
//  Manages the currently "active" trail the hiker has chosen to follow,
//  mirroring the selectedTrailId / localStorage logic in the web-app.
// ─────────────────────────────────────────────────────────────────────────────
class TrailSelectionState {
  /// The trail the user has tapped "Start Trail" on.
  final TrailModel? activeTrail;

  /// Progress along the active trail (0–100 %).
  /// Computed from the hiker's GPS position vs the trail polyline.
  final int progressPercent;

  /// Whether we are currently saving the selection to Firestore.
  final bool isSaving;

  const TrailSelectionState({
    this.activeTrail,
    this.progressPercent = 0,
    this.isSaving = false,
  });

  bool get hasActiveTrail => activeTrail != null;

  TrailSelectionState copyWith({
    TrailModel? activeTrail,
    bool clearTrail = false,
    int? progressPercent,
    bool? isSaving,
  }) {
    return TrailSelectionState(
      activeTrail:     clearTrail ? null : (activeTrail ?? this.activeTrail),
      progressPercent: progressPercent ?? this.progressPercent,
      isSaving:        isSaving ?? this.isSaving,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  NOTIFIER
// ─────────────────────────────────────────────────────────────────────────────
class TrailSelectionNotifier extends StateNotifier<TrailSelectionState> {
  TrailSelectionNotifier() : super(const TrailSelectionState());

  final _db  = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ── Select / Start a trail ───────────────────────────────────────────────
  Future<void> selectTrail(TrailModel trail) async {
    state = state.copyWith(
      activeTrail: trail,
      progressPercent: 0,
      isSaving: true,
    );

    // Persist to Firestore — mirrors web-app user_trail_selections collection
    try {
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        await _db.collection('user_trail_selections').add({
          'userId':    uid,
          'trailId':   trail.docId,
          'trailName': trail.name,
          'selectedAt': DateTime.now().toIso8601String(),
          'createdAt':  FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {
      // Non-fatal — selection still active locally
    }

    state = state.copyWith(isSaving: false);
  }

  // ── Clear active trail ───────────────────────────────────────────────────
  void clearTrail() {
    state = state.copyWith(clearTrail: true, progressPercent: 0);
  }

  // ── Update progress based on hiker GPS position ──────────────────────────
  /// Mirrors calculateTrailProgress() in user-location.js:
  /// Finds the nearest polyline point to the hiker and returns
  /// its index as a percentage of the total trail length.
  void updateProgress(double userLat, double userLng) {
    final trail = state.activeTrail;
    if (trail == null || !trail.hasPolyline) return;

    final coords = trail.coords;
    int nearestIndex = 0;
    double minDist = double.infinity;

    for (int i = 0; i < coords.length; i++) {
      final d = _haversineMeters(
        userLat, userLng,
        coords[i].latitude, coords[i].longitude,
      );
      if (d < minDist) {
        minDist = d;
        nearestIndex = i;
      }
    }

    final pct = ((nearestIndex / (coords.length - 1)) * 100).round();
    if (pct != state.progressPercent) {
      state = state.copyWith(progressPercent: pct);
    }
  }

  // ── Haversine distance in metres ─────────────────────────────────────────
  double _haversineMeters(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0;
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) *
            sin(dLng / 2) * sin(dLng / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _rad(double deg) => deg * pi / 180;
}

final trailSelectionProvider =
    StateNotifierProvider<TrailSelectionNotifier, TrailSelectionState>(
        (ref) => TrailSelectionNotifier());
