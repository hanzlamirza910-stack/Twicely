import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/session_manager.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../home/presentation/screens/home_screen.dart';
import 'otp_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool _isSingpassLoading = false;
  String _singpassLoadingMessage = '';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSignup() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 1200));

      if (mounted) {
        setState(() => _isLoading = false);

        // Navigate to OTP verification
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => OtpScreen(
              email: _emailController.text,
              isMerchant: false,
            ),
          ),
        );
      }
    }
  }

  void _handleSingPassSignup() async {
    setState(() {
      _isSingpassLoading = true;
      _singpassLoadingMessage = 'Connecting to Singpass...';
    });

    await Future.delayed(const Duration(milliseconds: 750));
    if (!mounted) return;
    setState(() => _singpassLoadingMessage = 'Verifying digital identity...');

    await Future.delayed(const Duration(milliseconds: 850));
    if (!mounted) return;
    setState(() => _singpassLoadingMessage = 'Authorizing access to Twicely...');

    await Future.delayed(const Duration(milliseconds: 750));
    if (!mounted) return;
    setState(() => _singpassLoadingMessage = 'Creating your account...');

    await Future.delayed(const Duration(milliseconds: 650));

    if (mounted) {
      setState(() => _isSingpassLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registered successfully via SingPass'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );

      SessionManager.login('singpass@user.sg', name: 'Singpass User');

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Header Row — back button + centred logo
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
                              errorBuilder: (_, __, ___) => const Text(
                                'twicely',
                                style: TextStyle(
                                  fontSize: 22,
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
                    const SizedBox(height: 28),

                    // Title
                    const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Join Twicely to buy & resell unused lifestyle passes.',
                      style: TextStyle(
                        color: AppColors.textSecondaryLight,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Name ──
                    _fieldLabel('Name'),
                    TextFormField(
                      controller: _nameController,
                      validator: (val) => Validators.validateRequired(val, 'Name'),
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(fontSize: 15, color: AppColors.primary),
                      decoration: _inputDecoration(
                        hint: 'Enter your full name',
                        icon: Icons.person_outline_rounded,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Email ──
                    _fieldLabel('Email'),
                    TextFormField(
                      controller: _emailController,
                      validator: Validators.validateEmail,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(fontSize: 15, color: AppColors.primary),
                      decoration: _inputDecoration(
                        hint: 'Enter your email',
                        icon: Icons.email_outlined,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Password ──
                    _fieldLabel('Password'),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      validator: Validators.validatePassword,
                      style: const TextStyle(fontSize: 15, color: AppColors.primary),
                      decoration: _inputDecoration(
                        hint: 'Enter password (min 8 characters)',
                        icon: Icons.lock_outline_rounded,
                        suffix: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Confirm Password ──
                    _fieldLabel('Confirm Password'),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Please confirm your password';
                        if (val != _passwordController.text) return 'Passwords do not match';
                        return null;
                      },
                      style: const TextStyle(fontSize: 15, color: AppColors.primary),
                      decoration: _inputDecoration(
                        hint: 'Confirm password',
                        icon: Icons.lock_outline_rounded,
                        suffix: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () => setState(
                              () => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Register Button ──
                    CustomButton(
                      text: 'Register',
                      isLoading: _isLoading,
                      onPressed: _handleSignup,
                    ),
                    const SizedBox(height: 24),

                    // ── OR Divider ──
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            thickness: 1,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
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

                    // ── Sign Up with SingPass ──
                    GestureDetector(
                      onTap: _handleSingPassSignup,
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25), width: 1.2),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE31A22),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'sp',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Sign Up with SingPass',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Already have an account? Sign in ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account?',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Sign in',
                            style: TextStyle(
                              color: AppColors.accent,
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

            // ── SingPass loading overlay ──
            if (_isSingpassLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.55),
                child: Center(
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE31A22),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'sp',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Color(0xFFE31A22)),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _singpassLoadingMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.7), fontSize: 14),
      prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
}
