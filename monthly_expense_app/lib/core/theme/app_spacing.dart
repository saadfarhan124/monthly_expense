import 'package:flutter/material.dart';

/// App spacing system for consistent layout
class AppSpacing {
  // Private constructor to prevent instantiation
  AppSpacing._();

  // Base spacing unit (4px)
  static const double _baseUnit = 4.0;

  // Spacing values
  static const double xs = _baseUnit; // 4px
  static const double sm = _baseUnit * 2; // 8px
  static const double md = _baseUnit * 3; // 12px
  static const double lg = _baseUnit * 4; // 16px
  static const double xl = _baseUnit * 6; // 24px
  static const double xxl = _baseUnit * 8; // 32px
  static const double xxxl = _baseUnit * 12; // 48px

  // Border radius values
  static const double radiusXs = _baseUnit; // 4px
  static const double radiusSm = _baseUnit * 1.5; // 6px
  static const double radiusMd = _baseUnit * 2; // 8px
  static const double radiusLg = _baseUnit * 3; // 12px
  static const double radiusXl = _baseUnit * 4; // 16px
  static const double radiusFull = 999.0; // Full rounded

  // Elevation values
  static const double elevationXs = 1.0;
  static const double elevationSm = 2.0;
  static const double elevationMd = 4.0;
  static const double elevationLg = 8.0;
  static const double elevationXl = 16.0;

  // Padding and margin helpers
  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);

  static const EdgeInsets marginXs = EdgeInsets.all(xs);
  static const EdgeInsets marginSm = EdgeInsets.all(sm);
  static const EdgeInsets marginMd = EdgeInsets.all(md);
  static const EdgeInsets marginLg = EdgeInsets.all(lg);
  static const EdgeInsets marginXl = EdgeInsets.all(xl);

  // Horizontal and vertical spacing
  static const EdgeInsets paddingHorizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets paddingHorizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets paddingHorizontalLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets paddingHorizontalXl = EdgeInsets.symmetric(horizontal: xl);

  static const EdgeInsets paddingVerticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets paddingVerticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets paddingVerticalLg = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets paddingVerticalXl = EdgeInsets.symmetric(vertical: xl);
} 