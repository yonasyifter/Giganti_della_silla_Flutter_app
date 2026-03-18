import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';


// ── Raw Firebase Auth user stream ──────────────────────────────────────────

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

  // Lazy getter — never accessed until Firebase is confirmed initialized
  FirebaseAuth get _auth => FirebaseAuth.instance;

  /// Called from SplashScreen — maps Firebase current user → AuthState
  Future<void> checkAuth() async {
    final fbUser = _auth.currentUser;
    if (fbUser != null) {
      state = AuthState(
        user: UserModel(
          uid: fbUser.uid,
          email: fbUser.email ?? '',
          displayName: fbUser.displayName ?? fbUser.email ?? 'Hiker',

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
      final fbUser = credential.user!;
      state = AuthState(
        user: UserModel(
          uid: fbUser.uid,
          email: fbUser.email ?? '',
          displayName: fbUser.displayName ?? fbUser.email ?? 'Hiker',
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
      state = state.copyWith(isLoading: false);
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
