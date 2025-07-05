import 'package:flutter/material.dart';

/// App color palette inspired by Cursor's dark theme
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // Primary Colors (Cursor-inspired blues)
  static const Color primary = Color(0xFF6366F1); // Indigo-500
  static const Color primaryLight = Color(0xFF818CF8); // Indigo-400
  static const Color primaryDark = Color(0xFF4F46E5); // Indigo-600
  static const Color primaryContainer = Color(0xFF3730A3); // Indigo-800

  // Secondary Colors
  static const Color secondary = Color(0xFF8B5CF6); // Violet-500
  static const Color secondaryLight = Color(0xFFA78BFA); // Violet-400
  static const Color secondaryDark = Color(0xFF7C3AED); // Violet-600

  // Surface Colors (Dark theme)
  static const Color surface = Color(0xFF0F0F23); // Very dark blue-gray
  static const Color surfaceLight = Color(0xFF1A1A2E); // Slightly lighter
  static const Color surfaceDark = Color(0xFF0A0A1A); // Darker variant
  static const Color surfaceVariant = Color(0xFF1E1E3F); // Elevated surface

  // Background Colors
  static const Color background = Color(0xFF0A0A0F); // Pure dark background
  static const Color backgroundSecondary = Color(0xFF0F0F1A); // Secondary background

  // Text Colors
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFFE2E8F0); // Light gray
  static const Color onSurfaceVariant = Color(0xFF94A3B8); // Muted text
  static const Color onBackground = Color(0xFFF1F5F9); // Primary text

  // Status Colors
  static const Color success = Color(0xFF10B981); // Emerald-500
  static const Color warning = Color(0xFFF59E0B); // Amber-500
  static const Color error = Color(0xFFEF4444); // Red-500
  static const Color info = Color(0xFF3B82F6); // Blue-500

  // Border Colors
  static const Color border = Color(0xFF2D2D3F);
  static const Color borderLight = Color(0xFF3F3F5F);

  // Overlay Colors
  static const Color overlay = Color(0x80000000);
  static const Color overlayLight = Color(0x40000000);

  // Gradient Colors
  static const List<Color> primaryGradient = [
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
  ];

  static const List<Color> surfaceGradient = [
    Color(0xFF0F0F23),
    Color(0xFF1A1A2E),
  ];

  // Semantic Colors for Financial App
  static const Color income = Color(0xFF10B981); // Green for income
  static const Color expense = Color(0xFFEF4444); // Red for expenses
  static const Color neutral = Color(0xFF6B7280); // Gray for neutral amounts
} 