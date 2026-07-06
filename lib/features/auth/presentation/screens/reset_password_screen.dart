import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/services/api_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? resetKey;
  final String? login;

  const ResetPasswordScreen({
    super.key,
    this.resetKey,
    this.login,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword1 = true;
  bool _obscurePassword2 = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleResetPassword() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passwords do not match'),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final result = await ApiService.resetPassword(
        key: widget.resetKey ?? 'mock_key',
        login: widget.login ?? 'mock_login',
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Password reset successfully! Please log in.'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to reset password.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header row with Back Button and Center Logo
                Row(
                  children: [
                    SizedBox(
                      width: 48,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.arrow_back, color: AppColors.primary, size: 24),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Image.asset(
                          'assets/images/logo.webp',
                          width: 110,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Text(
                            'twicely',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 50),

                // Icon in Circle (Key Symbol Representation)
                Center(
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC3CFE2).withValues(alpha: 0.3), // Soft blue circle
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.vpn_key_rounded, // Key symbol representation
                      color: AppColors.primary,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                const Text(
                  'Reset Password',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),

                // Subtitle
                const Text(
                  'Create a new, strong password for your account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondaryLight,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 36),

                // New Password Field
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 8.0, bottom: 6.0),
                    child: Text(
                      'New Password',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword1,
                  validator: Validators.validatePassword,
                  style: const TextStyle(fontSize: 15, color: AppColors.primary),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword1 ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () => setState(() => _obscurePassword1 = !_obscurePassword1),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Confirm Password Field
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 8.0, bottom: 6.0),
                    child: Text(
                      'Confirm New Password',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscurePassword2,
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Confirm password is required';
                    }
                    return null;
                  },
                  style: const TextStyle(fontSize: 15, color: AppColors.primary),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword2 ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () => setState(() => _obscurePassword2 = !_obscurePassword2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Reset Action Button
                CustomButton(
                  text: 'Reset Password',
                  isLoading: _isLoading,
                  onPressed: _handleResetPassword,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
