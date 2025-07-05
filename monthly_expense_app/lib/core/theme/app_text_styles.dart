import 'package:flutter/material.dart';
import 'app_colors.dart';

/// App text styles for consistent typography
class AppTextStyles {
  // Private constructor to prevent instantiation
  AppTextStyles._();

  // Font families
  static const String _fontFamily = 'Inter';

  // Font weights
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;

  // Display styles (large headings)
  static const TextStyle displayLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 57,
    fontWeight: bold,
    color: AppColors.onBackground,
    letterSpacing: -0.25,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 45,
    fontWeight: bold,
    color: AppColors.onBackground,
    letterSpacing: 0,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 36,
    fontWeight: bold,
    color: AppColors.onBackground,
    letterSpacing: 0,
  );

  // Headline styles
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    fontWeight: bold,
    color: AppColors.onBackground,
    letterSpacing: 0,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28,
    fontWeight: semiBold,
    color: AppColors.onBackground,
    letterSpacing: 0,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: semiBold,
    color: AppColors.onBackground,
    letterSpacing: 0,
  );

  // Title styles
  static const TextStyle titleLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 22,
    fontWeight: semiBold,
    color: AppColors.onBackground,
    letterSpacing: 0,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: medium,
    color: AppColors.onBackground,
    letterSpacing: 0.15,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: medium,
    color: AppColors.onBackground,
    letterSpacing: 0.1,
  );

  // Body styles
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: regular,
    color: AppColors.onSurface,
    letterSpacing: 0.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: regular,
    color: AppColors.onSurface,
    letterSpacing: 0.25,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: regular,
    color: AppColors.onSurfaceVariant,
    letterSpacing: 0.4,
  );

  // Label styles
  static const TextStyle labelLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: medium,
    color: AppColors.onSurface,
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: medium,
    color: AppColors.onSurfaceVariant,
    letterSpacing: 0.5,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: medium,
    color: AppColors.onSurfaceVariant,
    letterSpacing: 0.5,
  );

  // Special styles for financial app
  static const TextStyle amountLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    fontWeight: bold,
    color: AppColors.onBackground,
    letterSpacing: -0.5,
  );

  static const TextStyle amountMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: semiBold,
    color: AppColors.onBackground,
    letterSpacing: -0.25,
  );

  static const TextStyle amountSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: medium,
    color: AppColors.onBackground,
    letterSpacing: 0,
  );

  // Status text styles
  static TextStyle successText = bodyMedium.copyWith(
    color: AppColors.success,
    fontWeight: medium,
  );

  static TextStyle errorText = bodyMedium.copyWith(
    color: AppColors.error,
    fontWeight: medium,
  );

  static TextStyle warningText = bodyMedium.copyWith(
    color: AppColors.warning,
    fontWeight: medium,
  );

  static TextStyle infoText = bodyMedium.copyWith(
    color: AppColors.info,
    fontWeight: medium,
  );
} 