import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/animated_button.dart';
import '../../../core/utils/haptic_feedback.dart' as app_haptic;

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  
  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Your Financial Command Center',
      subtitle: 'Track, analyze, and control your money with beautiful insights and real-time updates.',
      icon: '📊',
      gradient: [AppColors.primary, AppColors.primaryContainer],
      feature: 'Smart Dashboard',
      description: 'Get a complete overview of your finances with animated balance displays and spending analytics.',
    ),
    OnboardingPage(
      title: 'Multi-Account Management',
      subtitle: 'Manage unlimited accounts with custom icons, colors, and real-time balance tracking.',
      icon: '🏦',
      gradient: [AppColors.success, AppColors.primaryContainer],
      feature: 'Unlimited Accounts',
      description: 'Create accounts for cash, bank, credit cards, and more with currency-specific displays.',
    ),
    OnboardingPage(
      title: 'Smart Transfer System',
      subtitle: 'Transfer money between accounts with support for cross-currency transfers and exchange rates.',
      icon: '💸',
      gradient: [AppColors.warning, AppColors.primaryContainer],
      feature: 'Cross-Currency Transfers',
      description: 'Handle transfers between different currencies with real-time exchange rates and optional fees.',
    ),
    OnboardingPage(
      title: 'People & Money Tracking',
      subtitle: 'Track money you lend or borrow from people with person-specific balances and transactions.',
      icon: '👥',
      gradient: [AppColors.error, AppColors.primaryContainer],
      feature: 'Person Management',
      description: 'Keep track of personal loans, debts, and money owed with beautiful person profiles.',
    ),
    OnboardingPage(
      title: 'Budget & Analytics',
      subtitle: 'Set budgets, track spending, and get insights with category-based analytics and progress tracking.',
      icon: '📈',
      gradient: [AppColors.primary, AppColors.secondary],
      feature: 'Smart Budgeting',
      description: 'Create category-based budgets with real-time tracking and spending alerts.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    // Start animations
    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _nextPage() {
    app_haptic.HapticFeedback.light();
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    app_haptic.HapticFeedback.light();
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeOnboarding() {
    app_haptic.HapticFeedback.medium();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header with skip button
            _buildHeader(),
            
            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),
            
            // Bottom navigation
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: AppSpacing.paddingHorizontalLg,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Page indicator
          Row(
            children: List.generate(_pages.length, (index) {
              return Container(
                width: index == _currentPage ? 24 : 8,
                height: 8,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: index == _currentPage 
                      ? AppColors.primary 
                      : AppColors.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          
          // Skip button
          TextButton(
            onPressed: _completeOnboarding,
            child: Text(
              'Skip',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: AppSpacing.paddingHorizontalLg,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with gradient background
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: page.gradient,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: page.gradient[0].withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      page.icon,
                      style: const TextStyle(fontSize: 48),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              // Title
              Text(
                page.title,
                style: AppTextStyles.headlineLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // Subtitle
              Text(
                page.subtitle,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              // Feature card
              Container(
                padding: AppSpacing.paddingLg,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      page.gradient[0].withValues(alpha: 0.1),
                      page.gradient[0].withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: page.gradient[0].withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      page.feature,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: page.gradient[0],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      page.description,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.onSurfaceVariant,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Padding(
      padding: AppSpacing.paddingLg,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous button
          if (_currentPage > 0)
            TextButton.icon(
              onPressed: _previousPage,
              icon: const Icon(Icons.arrow_back_ios, size: 16),
              label: const Text('Previous'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.onSurfaceVariant,
              ),
            )
          else
            const SizedBox(width: 80),
          
          // Next/Get Started button
          AnimatedButton(
            text: _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
            icon: _currentPage == _pages.length - 1 ? Icons.rocket_launch : Icons.arrow_forward_ios,
            backgroundColor: AppColors.primary,
            hapticType: HapticFeedbackType.medium,
            onPressed: _nextPage,
          ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String subtitle;
  final String icon;
  final List<Color> gradient;
  final String feature;
  final String description;

  OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.feature,
    required this.description,
  });
} 