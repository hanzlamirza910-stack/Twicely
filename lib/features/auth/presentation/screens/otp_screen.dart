import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/session_manager.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../home/presentation/screens/merchant_dashboard.dart';
import 'reset_password_screen.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  final bool isMerchant;
  final bool isPasswordReset;

  const OtpScreen({
    super.key,
    required this.email,
    this.isMerchant = false,
    this.isPasswordReset = false,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  bool _isLoading = false;
  bool _isResending = false;

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String get _otpPurpose =>
      widget.isPasswordReset ? 'password_reset' : 'registration';

  void _verifyOtp() async {
    final code = _controllers.map((c) => c.text).join();
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the full 6-digit code'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    debugPrint('[OTP Screen] Verifying OTP: $code for email: ${widget.email}, purpose: $_otpPurpose');

    final result = await ApiService.verifyOtp(
      otpCode: code,
      email: widget.email,
      purpose: _otpPurpose,
    );

    debugPrint('[OTP Screen] Verify response: $result');

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isPasswordReset
              ? 'OTP verified! Set your new password.'
              : widget.isMerchant
                  ? 'Merchant account activated!'
                  : 'Account verified successfully!'),
          backgroundColor: AppColors.success,
        ),
      );

      if (widget.isPasswordReset) {
        // Get reset key/login from response to pass to reset-password screen
        final resetKey = result['reset_key'] as String?;
        final resetLogin = result['reset_login'] as String?;
        debugPrint('[OTP Screen] Password reset - key: $resetKey, login: $resetLogin');

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(
              resetKey: resetKey,
              login: resetLogin ?? widget.email,
            ),
          ),
        );
      } else {
        // Registration verification — try to save session from response data
        final data = result['data'] as Map<String, dynamic>?;
        if (data != null && data['access_token'] != null) {
          await SessionManager.saveSession(
            accessToken: data['access_token'] as String,
            refreshToken: data['refresh_token'] as String? ?? '',
            user: data['user'] as Map<String, dynamic>? ?? {'email': widget.email},
          );
        } else {
          // No tokens in verify response — session already set during registration
          debugPrint('[OTP Screen] No tokens in verify response — using existing session');
        }

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) =>
                  widget.isMerchant ? const MerchantDashboard() : const HomeScreen(),
            ),
            (route) => false,
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Invalid OTP code. Please try again.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _resendOtp() async {
    setState(() => _isResending = true);
    debugPrint('[OTP Screen] Resending OTP to: ${widget.email}, purpose: $_otpPurpose');

    final result = await ApiService.sendOtp(
      type: 'email',
      email: widget.email,
      purpose: _otpPurpose,
    );

    debugPrint('[OTP Screen] Resend response: $result');

    if (!mounted) return;
    setState(() => _isResending = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['success'] == true
            ? (result['message'] ?? 'New code sent to ${widget.email}')
            : (result['message'] ?? 'Failed to resend OTP. Try again.')),
        backgroundColor:
            result['success'] == true ? AppColors.success : AppColors.danger,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  SizedBox(
                    width: 48,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.arrow_back,
                          color: AppColors.primary, size: 24),
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

              // Verification Icon
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_read_outlined,
                    color: AppColors.primary,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                widget.isPasswordReset ? 'Reset Code Sent' : 'Verify Your Email',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),

              // Subtitle
              Text(
                'We\'ve sent a 6-digit verification code to\n${widget.email}\nPlease enter it below.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondaryLight,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              // OTP 6-digit Inputs Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 46,
                    height: 56,
                    child: TextFormField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      // Use number keyboard but restrict to digits via formatter
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: false,
                        decimal: false,
                      ),
                      textInputAction: index < 5
                          ? TextInputAction.next
                          : TextInputAction.done,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      // Prevent cursor blinking loop by disabling selection toolbar
                      enableInteractiveSelection: false,
                      showCursor: false,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        contentPadding: EdgeInsets.zero,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                              color: AppColors.primary.withValues(alpha: 0.4)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: AppColors.primary, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) {
                        // Only process single character changes to avoid loops
                        if (value.length > 1) {
                          _controllers[index].text = value[0];
                          _controllers[index].selection =
                              const TextSelection.collapsed(offset: 1);
                        }
                        if (value.isNotEmpty && index < 5) {
                          // Move focus using FocusScope — avoids requestFocus IME loop
                          FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
                        } else if (value.isEmpty && index > 0) {
                          FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
                        } else if (value.isNotEmpty && index == 5) {
                          // Last box filled — dismiss keyboard cleanly
                          FocusScope.of(context).unfocus();
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 40),

              // Submit Button
              CustomButton(
                text: 'Verify Code',
                isLoading: _isLoading,
                onPressed: _verifyOtp,
              ),
              const SizedBox(height: 32),

              // Resend Button
              _isResending
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : TextButton(
                      onPressed: _resendOtp,
                      child: const Text(
                        'Resend Code',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
