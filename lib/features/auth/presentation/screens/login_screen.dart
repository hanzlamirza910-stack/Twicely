import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../home/presentation/screens/merchant_dashboard.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import '../../../../core/services/api_service.dart';
import 'singpass_webview_screen.dart';
import '../../../../core/widgets/custom_snackbar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isMerchant = false;
  bool _isSingPassLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      final email = _emailController.text.trim();
      debugPrint('[Login] Attempting login for: $email, merchant toggle: $_isMerchant');

      final result = await ApiService.login(
        email,
        _passwordController.text,
      );

      debugPrint('[Login] Login result: $result');

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      if (result['success'] == true) {
        final user = result['user'] as Map<String, dynamic>;
        final isUserMerchant = user['is_merchant'] as bool? ?? false;
        final isUserC2C = user['is_user'] as bool? ?? false;

        debugPrint('[Login] User roles: is_merchant=$isUserMerchant, is_user=$isUserC2C');
        debugPrint('[Login] User name: ${user['name']}, email: ${user['email']}');

        // If user selected Merchant tab but account has no merchant role — warn
        if (_isMerchant && !isUserMerchant) {
          CustomSnackBar.show(
            context,
            message: 'This account does not have merchant access. Logging in as Buyer.',
            type: SnackBarType.warning,
          );
        }

        // Route by actual server role — merchant wins if account has both
        final goToMerchant = _isMerchant && isUserMerchant;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => goToMerchant
                ? const MerchantDashboard()
                : const HomeScreen(),
          ),
        );
      } else {
        CustomSnackBar.show(
          context,
          message: result['message'] ?? 'Login failed. Please try again.',
          type: SnackBarType.error,
        );
      }
    }
  }

  void _handleSingPassLogin() async {
    if (_isSingPassLoading || _isLoading) return;
    setState(() {
      _isSingPassLoading = true;
    });

    try {
      // 1. Initialize Singpass flow via API
      final initRes = await ApiService.initSingpass(userType: 'user', mode: 'login');
      if (!mounted) return;

      if (initRes['success'] != true) {
        setState(() {
          _isSingPassLoading = false;
        });
        CustomSnackBar.show(
          context,
          message: initRes['message'] ?? 'Singpass initialization failed',
          type: SnackBarType.error,
        );
        return;
      }

      final authUrl = initRes['authorization_url'] as String;

      // 2. Open WebView to allow user to log in on official Singpass
      final result = await Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute(
          builder: (context) => SingpassWebViewScreen(authorizationUrl: authUrl),
        ),
      );

      if (!mounted) return;

      if (result == null || result['code'] == null || result['state'] == null) {
        setState(() {
          _isSingPassLoading = false;
        });
        CustomSnackBar.show(
          context,
          message: 'Singpass authentication cancelled',
          type: SnackBarType.warning,
        );
        return;
      }

      // 3. Callback to server to get JWT session
      final callbackRes = await ApiService.callbackSingpass(
        code: result['code'] as String,
        state: result['state'] as String,
      );

      if (!mounted) return;
      setState(() {
        _isSingPassLoading = false;
      });

      if (callbackRes['success'] == true) {
        final user = callbackRes['user'] as Map<String, dynamic>? ?? {};
        final isUserMerchant = user['is_merchant'] as bool? ?? false;
        final goToMerchant = _isMerchant && isUserMerchant;

        CustomSnackBar.show(
          context,
          message: 'Authenticated successfully via Singpass',
          type: SnackBarType.success,
        );

        // Route to Home or Merchant Dashboard
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => goToMerchant
                ? const MerchantDashboard()
                : const HomeScreen(),
          ),
          (route) => false,
        );
      } else {
        CustomSnackBar.show(
          context,
          message: callbackRes['message'] ?? 'Singpass login failed',
          type: SnackBarType.error,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSingPassLoading = false;
        });
        CustomSnackBar.show(
          context,
          message: 'An error occurred during Singpass login: $e',
          type: SnackBarType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: FractionallySizedBox(
                          widthFactor: 0.45,
                          child: Image.asset(
                            'assets/images/logo.webp',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Text(
                              'twicely',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Small horizontal accent/divider line under logo
                      Center(
                        child: Container(
                          width: 48,
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Header Texts
                      const Text(
                        'Welcome back!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Your sustainable treasure hunt continues.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondaryLight,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildRoleButton('Buyer Account', !_isMerchant, () => setState(() => _isMerchant = false)),
                          const SizedBox(width: 12),
                          _buildRoleButton('Merchant Account', _isMerchant, () => setState(() => _isMerchant = true)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Email Address Field
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(left: 8.0, bottom: 6.0),
                          child: Text(
                            'Email Address',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      TextFormField(
                        controller: _emailController,
                        validator: Validators.validateEmail,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(fontSize: 15, color: AppColors.primary),
                        decoration: InputDecoration(
                          hintText: 'hello@example.com',
                          prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary, size: 20),
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

                      // Password Field
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(left: 8.0, bottom: 6.0),
                          child: Text(
                            'Password',
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
                        obscureText: _obscurePassword,
                        validator: Validators.validatePassword,
                        style: const TextStyle(fontSize: 15, color: AppColors.primary),
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 20,
                              color: AppColors.textMuted,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
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

                      // Forgot Password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                            );
                          },
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Submit Button
                      CustomButton(
                        text: 'Login',
                        isLoading: _isLoading,
                        onPressed: _handleLogin,
                      ),
                      const SizedBox(height: 24),

                      // OR Divider
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              thickness: 1,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      GestureDetector(
                        onTap: _isSingPassLoading ? null : _handleSingPassLogin,
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/singpass_logo.png',
                                height: 18,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(width: 12),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: Text(
                                  _isSingPassLoading
                                      ? 'Connecting to SingPass...'
                                      : 'Login with SingPass',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),

                        // Toggle Navigation to Sign Up
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Don't have an account?",
                              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (context) => const SignupScreen()),
                                );
                              },
                              child: const Text(
                                'Sign up',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

  Widget _buildRoleButton(String title, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1F2E4E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF1F2E4E) : AppColors.primary.withValues(alpha: 0.12),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1F2E4E).withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.primary,
          ),
        ),
      ),
    );
  }
}
