import 'package:flutter/material.dart';

class AppColors {
  // Primary palette - forest green theme
  static const Color primary = Color(0xFF2D6A4F);
  static const Color primaryLight = Color(0xFF52B788);
  static const Color primaryDark = Color(0xFF1B4332);

  // Accent
  static const Color accent = Color(0xFFD4A843);
  static const Color accentLight = Color(0xFFF4D06F);

  // Background
  static const Color background = Color(0xFF0D1B2A);
  static const Color backgroundSecondary = Color(0xFF1A2E3E);
  static const Color surface = Color(0xFF1E3448);
  static const Color surfaceLight = Color(0xFF253D52);

  // Text
  static const Color textPrimary = Color(0xFFF0F4F8);
  static const Color textSecondary = Color(0xFF8FA8BE);
  static const Color textHint = Color(0xFF4A6B82);

  // Status colors
  static const Color success = Color(0xFF52B788);
  static const Color warning = Color(0xFFD4A843);
  static const Color danger = Color(0xFFE63946);
  static const Color info = Color(0xFF4CC9F0);

  // Trail difficulty
  static const Color easy = Color(0xFF52B788);
  static const Color moderate = Color(0xFFD4A843);
  static const Color hard = Color(0xFFE63946);
  static const Color expert = Color(0xFF9B2226);

  // Weather
  static const Color sunny = Color(0xFFFFB703);
  static const Color cloudy = Color(0xFF8FA8BE);
  static const Color rainy = Color(0xFF4CC9F0);
  static const Color stormy = Color(0xFF7B2D8B);

  // Map overlays
  static const Color trailLine = Color(0xFF52B788);
  static const Color hikersPosition = Color(0xFFFFB703);
  static const Color parkBoundary = Color(0xFF2D6A4F);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, primary, primaryLight],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [background, backgroundSecondary],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surface, surfaceLight],
  );

  // Chatbot
  static const Color chatbotBubble = Color(0xFF2D6A4F);
  static const Color userBubble = Color(0xFF1A2E3E);
  static const Color chatbotPulse = Color(0xFF52B788);
}
