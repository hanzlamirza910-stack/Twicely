import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../home/presentation/screens/home_screen.dart';

import '../../../../core/utils/session_manager.dart';
import '../../../home/presentation/screens/merchant_dashboard.dart';

import 'package:package_info_plus/package_info_plus.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  String _appVersion = '1.0.2+4';

  Future<void> _loadVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
      });
    } catch (e) {
      debugPrint('[Splash] Error loading version: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    // Transition based on auth state after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Widget nextScreen;
        if (!SessionManager.isLoggedIn) {
          // Not logged in — go to HomeScreen (browse without account)
          nextScreen = const HomeScreen();
        } else if (SessionManager.isMerchant) {
          nextScreen = const MerchantDashboard();
        } else {
          nextScreen = const HomeScreen();
        }

        debugPrint('[Splash] isLoggedIn=${SessionManager.isLoggedIn}, isMerchant=${SessionManager.isMerchant}, userName=${SessionManager.userName}');

        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: FadeTransition(
                opacity: _animation,
                child: FractionallySizedBox(
                  widthFactor: 0.42,
                  child: Image.asset(
                    'assets/images/logo.webp',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Text(
                        'twicely',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          letterSpacing: -1,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // App version display
            Align(
              alignment: const Alignment(0, 0.85),
              child: Text(
                'version: $_appVersion',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
