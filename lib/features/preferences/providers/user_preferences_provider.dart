import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_preferences_model.dart';

/// Firestore collection: "userPreferences"
/// Document ID: Firebase UID
const _collection = 'userPreferences';

class PreferencesNotifier extends StateNotifier<AsyncValue<UserPreferences>> {
  PreferencesNotifier() : super(const AsyncValue.loading());

  final _db = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  /// Load from Firestore. Creates default doc if first-time user.
  Future<void> load() async {
    final uid = _uid;
    if (uid == null) return;

    state = const AsyncValue.loading();
    try {
      final doc = await _db.collection(_collection).doc(uid).get();
      if (doc.exists && doc.data() != null) {
        state = AsyncValue.data(
            UserPreferences.fromFirestore(doc.data()!, uid));
      } else {
        // First-time user — create defaults
        final defaults = UserPreferences.defaults(uid);
        await _db
            .collection(_collection)
            .doc(uid)
            .set(defaults.toFirestore());
        state = AsyncValue.data(defaults);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Persist updated preferences to Firestore
  Future<void> save(UserPreferences prefs) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _db
          .collection(_collection)
          .doc(uid)
          .set(prefs.toFirestore(), SetOptions(merge: true));
      state = AsyncValue.data(prefs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Increment visit count whenever user enters the park
  Future<void> incrementVisitCount() async {
    final current = state.valueOrNull;
    if (current == null) return;
    await save(current.copyWith(visitCount: current.visitCount + 1));
  }
}

final preferencesProvider =
    StateNotifierProvider<PreferencesNotifier, AsyncValue<UserPreferences>>(
        (ref) => PreferencesNotifier());
