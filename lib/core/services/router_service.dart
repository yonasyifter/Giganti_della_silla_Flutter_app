import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/map/screens/map_screen.dart';
import '../../features/map/screens/trails_list_screen.dart';
import '../../features/weather/screens/weather_screen.dart';
import '../../features/chatbot/screens/chatbot_screen.dart';
import '../../features/emergency/screens/sos_screen.dart';
import '../../features/preferences/screens/preferences_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../shared/widgets/main_scaffold.dart';
import '../../features/auth/providers/firebase_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final firebaseInit = ref.watch(firebaseInitProvider);

  if (!firebaseInit.hasValue) {
    return GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(
            body: Center(child: CircularProgressIndicator())),
      ),
    ]);
  }

  final authNotifier = ValueNotifier<bool>(
    FirebaseAuth.instance.currentUser != null,
  );

  FirebaseAuth.instance.authStateChanges().listen((user) {
    authNotifier.value = user != null;
  });

  ref.onDispose(() => authNotifier.dispose());

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final isAuth = FirebaseAuth.instance.currentUser != null;
      final loc = state.matchedLocation;
      const publicRoutes = [
        '/login', '/register', '/splash', '/forgot-password'
      ];

      if (!isAuth && !publicRoutes.contains(loc)) return '/login';
      if (isAuth && (loc == '/login' || loc == '/register')) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash',
          builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login',
          builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register',
          builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/forgot-password',
          builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(path: '/settings',
          builder: (_, __) => const SettingsScreen()),
      ShellRoute(
        builder: (_, __, child) => MainScaffold(child: child),
        routes: [
          GoRoute(path: '/home',
              builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/map',
              builder: (_, __) => const MapScreen()),
          GoRoute(path: '/weather',
              builder: (_, __) => const WeatherScreen()),
          GoRoute(path: '/chatbot',
              builder: (_, __) => const ChatbotScreen()),
          GoRoute(path: '/preferences',
              builder: (_, __) => const PreferencesScreen()),
        ],
      ),
      GoRoute(path: '/sos',
          builder: (_, __) => const SosScreen()),
      GoRoute(path: '/trails',
          builder: (_, __) => const TrailsListScreen()),
    ],
  );
});
