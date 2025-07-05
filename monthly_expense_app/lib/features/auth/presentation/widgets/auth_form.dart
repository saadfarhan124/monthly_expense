import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/custom_button.dart';
import 'auth_text_field.dart';

class AuthForm extends StatefulWidget {
  final bool isLogin;
  final VoidCallback? onToggleMode;
  final Future<void> Function(String email, String password) onSubmit;
  final bool isLoading;

  const AuthForm({
    super.key,
    required this.isLogin,
    this.onToggleMode,
    required this.onSubmit,
    this.isLoading = false,
  });

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (!widget.isLogin) {
      if (value == null || value.isEmpty) {
        return 'Please confirm your password';
      }
      if (value != _passwordController.text) {
        return 'Passwords do not match';
      }
    }
    return null;
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit(_emailController.text, _passwordController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceVariant.withAlpha(80),
            AppColors.surfaceVariant.withAlpha(40),
          ],
        ),
        border: Border.all(
          color: AppColors.border.withAlpha(150),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.overlay,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: AppSpacing.paddingXl,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                widget.isLogin ? 'Welcome Back' : 'Create Account',
                style: AppTextStyles.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                widget.isLogin
                    ? 'Sign in to continue tracking your expenses'
                    : 'Join us to start managing your finances',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Email Field
              AuthTextField(
                label: 'Email',
                hint: 'Enter your email',
                controller: _emailController,
                validator: _validateEmail,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Password Field
              AuthTextField(
                label: 'Password',
                hint: 'Enter your password',
                controller: _passwordController,
                validator: _validatePassword,
                isPassword: true,
                prefixIcon: Icons.lock_outlined,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Confirm Password Field (Signup only)
              if (!widget.isLogin) ...[
                AuthTextField(
                  label: 'Confirm Password',
                  hint: 'Confirm your password',
                  controller: _confirmPasswordController,
                  validator: _validateConfirmPassword,
                  isPassword: true,
                  prefixIcon: Icons.lock_outlined,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              // Submit Button
              CustomButton(
                text: widget.isLogin ? 'Sign In' : 'Sign Up',
                onPressed: _handleSubmit,
                isLoading: widget.isLoading,
                icon: widget.isLogin ? Icons.login : Icons.person_add,
              ),
              const SizedBox(height: AppSpacing.xl),

              // Toggle Mode
              if (widget.onToggleMode != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.isLogin
                          ? "Don't have an account? "
                          : 'Already have an account? ',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    TextButton(
                      onPressed: widget.onToggleMode,
                      child: Text(
                        widget.isLogin ? 'Sign Up' : 'Sign In',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
} 