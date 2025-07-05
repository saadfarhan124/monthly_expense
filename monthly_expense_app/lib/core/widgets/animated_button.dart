import 'package:flutter/material.dart';
import '../utils/haptic_feedback.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// A reusable animated button with haptic feedback
class AnimatedButton extends StatefulWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;
  final bool isLoading;
  final HapticFeedbackType hapticType;

  const AnimatedButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.borderRadius,
    this.padding,
    this.isLoading = false,
    this.hapticType = HapticFeedbackType.medium,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _handleTap() {
    // Provide haptic feedback based on type
    switch (widget.hapticType) {
      case HapticFeedbackType.light:
        HapticFeedback.light();
        break;
      case HapticFeedbackType.medium:
        HapticFeedback.medium();
        break;
      case HapticFeedbackType.heavy:
        HapticFeedback.heavy();
        break;
      case HapticFeedbackType.success:
        HapticFeedback.success();
        break;
      case HapticFeedbackType.warning:
        HapticFeedback.warning();
        break;
      case HapticFeedbackType.error:
        HapticFeedback.error();
        break;
    }

    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onPressed != null && !widget.isLoading ? _handleTap : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.width,
              height: widget.height ?? 48,
              decoration: BoxDecoration(
                color: widget.backgroundColor ?? AppColors.primary,
                borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
                boxShadow: _isPressed
                    ? []
                    : [
                        BoxShadow(
                          color: (widget.backgroundColor ?? AppColors.primary)
                              .withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
                  onTap: widget.onPressed != null && !widget.isLoading ? _handleTap : null,
                  child: Container(
                    padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.isLoading)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
                            ),
                          )
                        else if (widget.icon != null) ...[
                          Icon(
                            widget.icon,
                            color: widget.textColor ?? AppColors.onPrimary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.text,
                          style: AppTextStyles.labelLarge.copyWith(
                            color: widget.textColor ?? AppColors.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Enum for different types of haptic feedback
enum HapticFeedbackType {
  light,
  medium,
  heavy,
  success,
  warning,
  error,
} 