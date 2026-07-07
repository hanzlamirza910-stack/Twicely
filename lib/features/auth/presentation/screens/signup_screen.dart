import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/services/api_service.dart';
import 'singpass_login_screen.dart';
import 'otp_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  // Shared fields
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Merchant-only fields
  final _businessNameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isMerchantSignup = false; // toggle between Buyer and Merchant signup

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _businessNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleSignup() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      final email = _emailController.text.trim();

      if (_isMerchantSignup) {
        // ── Merchant Registration ──
        debugPrint('[Signup] Registering MERCHANT: $email, business: ${_businessNameController.text.trim()}');

        final result = await ApiService.registerMerchant(
          email: email,
          password: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
          businessName: _businessNameController.text.trim(),
          phone: _phoneController.text.trim(),
          firstName: _nameController.text.trim().split(' ').first,
          lastName: _nameController.text.trim().split(' ').length > 1
              ? _nameController.text.trim().split(' ').sublist(1).join(' ')
              : null,
        );

        debugPrint('[Signup] Merchant registration response: $result');

        if (!mounted) return;
        setState(() => _isLoading = false);

        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Merchant account created! Please verify your email.'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => OtpScreen(
                email: email,
                isMerchant: true,
                isPasswordReset: false,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Merchant registration failed. Please try again.'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      } else {
        // ── Buyer/User Registration ──
        debugPrint('[Signup] Registering USER: $email');

        final result = await ApiService.registerUser(
          name: _nameController.text.trim(),
          email: email,
          password: _passwordController.text,
        );

        debugPrint('[Signup] Registration response: $result');

        if (!mounted) return;
        setState(() => _isLoading = false);

        if (result['success'] == true) {
          debugPrint('[Signup] Success. Sending OTP for registration to: $email');
          await ApiService.sendOtp(
            type: 'email',
            email: email,
            purpose: 'registration',
          );

          if (!mounted) return;

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => OtpScreen(
                email: email,
                isMerchant: false,
                isPasswordReset: false,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Registration failed. Please try again.'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  void _handleSingPassSignup() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SingPassLoginScreen(),
      ),
    );
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
                const SizedBox(height: 24),

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
                const SizedBox(height: 20),

                // ── Account Type Toggle ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTypeButton('Buyer Account', !_isMerchantSignup,
                        () => setState(() => _isMerchantSignup = false)),
                    const SizedBox(width: 12),
                    _buildTypeButton('Merchant Account', _isMerchantSignup,
                        () => setState(() => _isMerchantSignup = true)),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Full Name ──
                _fieldLabel(_isMerchantSignup ? 'Full Name' : 'Name'),
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

                // ── Business Name (Merchant only) ──
                if (_isMerchantSignup) ...[
                  _fieldLabel('Business Name'),
                  TextFormField(
                    controller: _businessNameController,
                    validator: (val) => _isMerchantSignup
                        ? Validators.validateRequired(val, 'Business Name')
                        : null,
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(fontSize: 15, color: AppColors.primary),
                    decoration: _inputDecoration(
                      hint: 'e.g. Amara Spa & Wellness',
                      icon: Icons.business_outlined,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Phone (Merchant only) ──
                  _fieldLabel('Phone Number'),
                  TextFormField(
                    controller: _phoneController,
                    validator: (val) => _isMerchantSignup
                        ? Validators.validateRequired(val, 'Phone')
                        : null,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(fontSize: 15, color: AppColors.primary),
                    decoration: _inputDecoration(
                      hint: '+65 8888 8888',
                      icon: Icons.phone_outlined,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

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
                    hint: 'Min 8 characters',
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
                  text: _isMerchantSignup ? 'Create Merchant Account' : 'Register',
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

                // ── Already have an account? ──
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
      ),
    );
  }

  // ── Account type tab button ──
  Widget _buildTypeButton(String title, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.primary,
          ),
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
