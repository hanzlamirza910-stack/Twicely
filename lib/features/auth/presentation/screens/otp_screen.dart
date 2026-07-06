import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/session_manager.dart';
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
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  final List<TextEditingController> _controllers = List.generate(4, (_) => TextEditingController());
  bool _isLoading = false;

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

  void _verifyOtp() async {
    final code = _controllers.map((c) => c.text).join();
    if (code.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the full 4-digit code'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate OTP server check
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      // Show success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isPasswordReset
              ? 'OTP Verified successfully!'
              : widget.isMerchant
                  ? 'Merchant Account activated successfully!'
                  : 'Account verified successfully!'),
          backgroundColor: AppColors.success,
        ),
      );

      // Route based on destination
      if (widget.isPasswordReset) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ResetPasswordScreen()),
        );
      } else {
        await SessionManager.saveSession(
          accessToken: 'otp_mock_token',
          refreshToken: 'otp_mock_refresh',
          user: {
            'id': 8888,
            'email': widget.email,
            'name': widget.isMerchant ? 'Twicely Merchant' : 'Twicely Member',
            'is_merchant': widget.isMerchant,
            'is_user': !widget.isMerchant,
          },
        );
        if (mounted && context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => widget.isMerchant
                  ? const MerchantDashboard()
                  : const HomeScreen(),
            ),
            (route) => false,
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
              const Text(
                'Verify Your Email',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),

              // Subtitle
              Text(
                'We have sent a verification code to\n${widget.email}.\nPlease enter the 4-digit code below.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondaryLight,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              // OTP Digits Inputs Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (index) {
                  return SizedBox(
                    width: 60,
                    height: 60,
                    child: TextFormField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        contentPadding: EdgeInsets.zero,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 3) {
                          _focusNodes[index + 1].requestFocus();
                        } else if (value.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                        if (codeEnteredFully()) {
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

              // Resend code timer mock
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('New verification code sent!')),
                  );
                },
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

  bool codeEnteredFully() {
    return _controllers.every((c) => c.text.isNotEmpty);
  }
}
