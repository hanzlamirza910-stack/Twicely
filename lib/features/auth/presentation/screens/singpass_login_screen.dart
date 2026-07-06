import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../home/presentation/screens/home_screen.dart';

class SingPassLoginScreen extends StatefulWidget {
  const SingPassLoginScreen({super.key});

  @override
  State<SingPassLoginScreen> createState() => _SingPassLoginScreenState();
}

class _SingPassLoginScreenState extends State<SingPassLoginScreen> {
  final _singpassIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showPasswordLogin = false;

  @override
  void dispose() {
    _singpassIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _loadingMessage = 'Connecting to Singpass...';

  void _handleSingPassLogin() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Connecting to Singpass...';
    });

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _loadingMessage = 'Verifying digital identity...';
    });

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() {
      _loadingMessage = 'Authorizing access to Twicely...';
    });

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _loadingMessage = 'Signing in to your account...';
    });

    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      // Show mock success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authenticated successfully via SingPass'),
          backgroundColor: AppColors.success,
        ),
      );

      // Route to Home
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Red dot/logo for SingPass
            Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                color: Color(0xFFE31A22), // SingPass official red
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'singpass',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w900,
                fontSize: 20,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31A22)),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _loadingMessage,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  // Singpass Logo Header
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE31A22).withValues(alpha: 0.06),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.fingerprint_rounded,
                        color: Color(0xFFE31A22),
                        size: 64,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Log in with Singpass Mobile',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'The quick and secure way to verify your identity and log in to Twicely.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Official Singpass App Login CTA Button
                  ElevatedButton(
                    onPressed: _handleSingPassLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE31A22), // SingPass Red
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 1,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.phone_iphone_rounded, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Log in with Singpass App',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Alternative Collapsible Login ID Option
                  Center(
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _showPasswordLogin = !_showPasswordLogin;
                        });
                      },
                      child: Text(
                        _showPasswordLogin
                            ? 'Hide Singpass ID & Password Login'
                            : 'Log in with Singpass ID & Password',
                        style: const TextStyle(
                          color: Color(0xFFE31A22),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  if (_showPasswordLogin) ...[
                    const SizedBox(height: 20),
                    // Singpass ID Field
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: 8.0, bottom: 6.0),
                        child: Text(
                          'Singpass ID (NRIC or FIN)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    TextFormField(
                      controller: _singpassIdController,
                      style: const TextStyle(fontSize: 15, color: Colors.black87),
                      decoration: InputDecoration(
                        hintText: 'e.g. S1234567A',
                        prefixIcon: const Icon(Icons.person_outline_rounded, color: Colors.black54),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(color: Colors.black38),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(color: Colors.black26),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(color: Color(0xFFE31A22), width: 1.5),
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
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      style: const TextStyle(fontSize: 15, color: Colors.black87),
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.black54),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(color: Colors.black38),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(color: Colors.black26),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(color: Color(0xFFE31A22), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _handleSingPassLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE31A22),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Submit Login',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],

                  const SizedBox(height: 48),
                  // Security info footer
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.security_rounded, color: Colors.green, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Singpass protects your personal data. Twicely will only access authorized data fields with your consent.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
