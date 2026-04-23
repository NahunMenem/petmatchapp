import 'package:flutter/material.dart';

class AppColors {
  // Brand
  static const Color primary = Color(0xFFFF6B35);
  static const Color primaryLight = Color(0xFFFF8C5A);
  static const Color primaryDark = Color(0xFFE5501A);

  static const Color secondary = Color(0xFFFF3B6A);
  static const Color secondaryLight = Color(0xFFFF6B8A);

  // Backgrounds
  static const Color background = Color(0xFFF1F1F3);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F0EB);

  // Text
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B6B7A);
  static const Color textHint = Color(0xFFAFAFBF);

  // Status
  static const Color success = Color(0xFF4CAF7D);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF29B6F6);

  // Match gradient
  static const LinearGradient matchGradient = LinearGradient(
    colors: [Color(0xFFFF6B35), Color(0xFFFF3B6A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Card gradient (overlay)
  static const LinearGradient cardOverlay = LinearGradient(
    colors: [Colors.transparent, Color(0xCC000000)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Like / Dislike
  static const Color likeGreen = Color(0xFF4CAF7D);
  static const Color dislikeRed = Color(0xFFFF3B6A);

  // Divider
  static const Color divider = Color(0xFFE8E4DF);

  // Premium
  static const Color gold = Color(0xFFFFB300);
  static const LinearGradient premiumGradient = LinearGradient(
    colors: [Color(0xFFFFB300), Color(0xFFFF8C00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
