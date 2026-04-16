import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

// ── App-level auth state ───────────────────────────────────────────────────
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  FirebaseAuth get _auth => FirebaseAuth.instance;

  /// Derives a display name: prefers Firebase displayName, then email prefix.
  /// e.g. "yonasyifter@gmail.com" → "yonasyifter"
  String _resolveDisplayName(User fbUser) {
    final name = fbUser.displayName?.trim() ?? '';
    if (name.isNotEmpty) return name;
    final email = fbUser.email ?? '';
    if (email.contains('@')) return email.split('@').first;
    return 'Hiker';
  }

  /// Called from SplashScreen — maps Firebase current user → AuthState.
  /// Reloads the user first to ensure the latest displayName is fetched.
  Future<void> checkAuth() async {
    final fbUser = _auth.currentUser;
    if (fbUser != null) {
      // Reload ensures we get the latest profile (e.g. after updateDisplayName)
      await fbUser.reload();
      final refreshed = _auth.currentUser!;
      state = AuthState(
        user: UserModel(
          uid: refreshed.uid,
          email: refreshed.email ?? '',
          displayName: _resolveDisplayName(refreshed),
        ),
      );
    }
  }

  /// Email + password sign-in via Firebase Auth
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      // Reload to ensure displayName is fresh after any prior updateDisplayName
      await credential.user!.reload();
      final fbUser = _auth.currentUser!;
      state = AuthState(
        user: UserModel(
          uid: fbUser.uid,
          email: fbUser.email ?? '',
          displayName: _resolveDisplayName(fbUser),
        ),
      );
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: _friendlyError(e.code));
      return false;
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Sign in failed. Try again.');
      return false;
    }
  }

  /// Email + password registration via Firebase Auth
  Future<bool> register(String email, String password, String displayName) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      await credential.user!.updateDisplayName(displayName.trim());
      await credential.user!.reload();
      final fbUser = _auth.currentUser!;
      // Set full AuthState so the home screen immediately shows the correct initial
      state = AuthState(
        user: UserModel(
          uid: fbUser.uid,
          email: fbUser.email ?? '',
          displayName: _resolveDisplayName(fbUser),
        ),
      );
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: _friendlyError(e.code));
      return false;
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Registration failed. Try again.');
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    state = const AuthState();
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'network-request-failed':
        return 'No internet connection.';
      default:
        return 'Authentication error ($code).';
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
