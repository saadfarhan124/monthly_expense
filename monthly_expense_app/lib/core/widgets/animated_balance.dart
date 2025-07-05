import 'package:flutter/material.dart';
import '../utils/animation_utils.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// A widget that displays balance with smooth counter animation
class AnimatedBalance extends StatefulWidget {
  final double balance;
  final String currency;
  final TextStyle? style;
  final bool showCurrency;
  final Duration animationDuration;
  final Curve animationCurve;

  const AnimatedBalance({
    super.key,
    required this.balance,
    required this.currency,
    this.style,
    this.showCurrency = true,
    this.animationDuration = const Duration(milliseconds: 800),
    this.animationCurve = Curves.easeOutCubic,
  });

  @override
  State<AnimatedBalance> createState() => _AnimatedBalanceState();
}

class _AnimatedBalanceState extends State<AnimatedBalance>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _balanceAnimation;
  double _previousBalance = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _balanceAnimation = AnimationUtils.createCounterAnimation(
      vsync: this,
      from: _previousBalance,
      to: widget.balance,
      duration: widget.animationDuration,
      curve: widget.animationCurve,
    );
  }

  @override
  void didUpdateWidget(AnimatedBalance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.balance != widget.balance) {
      _previousBalance = oldWidget.balance;
      _balanceAnimation = AnimationUtils.createCounterAnimation(
        vsync: this,
        from: _previousBalance,
        to: widget.balance,
        duration: widget.animationDuration,
        curve: widget.animationCurve,
      );
      _animationController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _formatBalance(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return value.toStringAsFixed(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _balanceAnimation,
      builder: (context, child) {
        final currentBalance = _balanceAnimation.value;
        final formattedBalance = _formatBalance(currentBalance);
        
        return RichText(
          text: TextSpan(
            children: [
              if (widget.showCurrency)
                TextSpan(
                  text: '${widget.currency} ',
                  style: (widget.style ?? AppTextStyles.titleLarge).copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              TextSpan(
                text: formattedBalance,
                style: (widget.style ?? AppTextStyles.titleLarge).copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 