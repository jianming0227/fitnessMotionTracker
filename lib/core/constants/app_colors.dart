import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Background
  static const Color background = Color(0xFF0A0E1A);
  static const Color surface = Color(0xFF131929);
  static const Color card = Color(0xFF1C2640);

  // Primary accent
  static const Color primary = Color(0xFF4F8EF7);
  static const Color primaryLight = Color(0xFF82AEFF);
  static const Color primaryDark = Color(0xFF2B5FCC);

  // Secondary accent (lime for success / active)
  static const Color secondary = Color(0xFF39E08B);
  static const Color secondaryDark = Color(0xFF1FAD63);

  // Text
  static const Color textPrimary = Color(0xFFECEFF8);
  static const Color textSecondary = Color(0xFF8A93AD);
  static const Color textMuted = Color(0xFF4A5270);

  // States
  static const Color error = Color(0xFFFF4F6B);
  static const Color warning = Color(0xFFFFB347);
  static const Color success = Color(0xFF39E08B);

  // Skeleton overlay colours
  static const Color skeletonLine = Color(0xFF4F8EF7);
  static const Color skeletonJoint = Color(0xFF39E08B);
  static const Color skeletonWarning = Color(0xFFFF4F6B);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4F8EF7), Color(0xFF39E08B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF0A0E1A), Color(0xFF131929)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
