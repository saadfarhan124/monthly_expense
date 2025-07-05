import 'package:flutter/services.dart';

/// Utility class for haptic feedback across the app
class HapticFeedback {
  // Private constructor to prevent instantiation
  HapticFeedback._();

  /// Light haptic feedback for subtle interactions
  static void light() {
    SystemChannels.platform.invokeMethod('HapticFeedback.lightImpact');
  }

  /// Medium haptic feedback for standard button presses
  static void medium() {
    SystemChannels.platform.invokeMethod('HapticFeedback.mediumImpact');
  }

  /// Heavy haptic feedback for important actions
  static void heavy() {
    SystemChannels.platform.invokeMethod('HapticFeedback.heavyImpact');
  }

  /// Selection haptic feedback for toggles and selections
  static void selection() {
    SystemChannels.platform.invokeMethod('HapticFeedback.selectionClick');
  }

  /// Success haptic feedback for positive actions
  static void success() {
    SystemChannels.platform.invokeMethod('HapticFeedback.notificationImpact', 'success');
  }

  /// Warning haptic feedback for caution actions
  static void warning() {
    SystemChannels.platform.invokeMethod('HapticFeedback.notificationImpact', 'warning');
  }

  /// Error haptic feedback for negative actions
  static void error() {
    SystemChannels.platform.invokeMethod('HapticFeedback.notificationImpact', 'error');
  }
} 