import 'package:flutter/material.dart';

/// Utility class for common animations across the app
class AnimationUtils {
  // Private constructor to prevent instantiation
  AnimationUtils._();

  /// Creates a smooth counter animation for balance changes
  static Animation<double> createCounterAnimation({
    required TickerProvider vsync,
    required double from,
    required double to,
    Duration duration = const Duration(milliseconds: 800),
    Curve curve = Curves.easeOutCubic,
  }) {
    return Tween<double>(
      begin: from,
      end: to,
    ).animate(CurvedAnimation(
      parent: AnimationController(
        duration: duration,
        vsync: vsync,
      )..forward(),
      curve: curve,
    ));
  }

  /// Creates a pulse animation for important elements
  static Animation<double> createPulseAnimation({
    required TickerProvider vsync,
    Duration duration = const Duration(milliseconds: 600),
  }) {
    return Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: AnimationController(
        duration: duration,
        vsync: vsync,
      )..repeat(reverse: true),
      curve: Curves.easeInOut,
    ));
  }

  /// Creates a slide animation for page transitions
  static Animation<Offset> createSlideAnimation({
    required TickerProvider vsync,
    Offset begin = const Offset(0, 0.3),
    Offset end = Offset.zero,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOutCubic,
  }) {
    return Tween<Offset>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: AnimationController(
        duration: duration,
        vsync: vsync,
      )..forward(),
      curve: curve,
    ));
  }

  /// Creates a fade animation
  static Animation<double> createFadeAnimation({
    required TickerProvider vsync,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: AnimationController(
        duration: duration,
        vsync: vsync,
      )..forward(),
      curve: curve,
    ));
  }

  /// Creates a scale animation for button presses
  static Animation<double> createScaleAnimation({
    required TickerProvider vsync,
    Duration duration = const Duration(milliseconds: 150),
    Curve curve = Curves.easeInOut,
  }) {
    return Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: AnimationController(
        duration: duration,
        vsync: vsync,
      )..forward(),
      curve: curve,
    ));
  }
} 