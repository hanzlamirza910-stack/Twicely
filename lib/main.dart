import 'package:flutter/material.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/session_manager.dart';
import 'core/services/api_service.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/splash_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SessionManager.init();
  await ApiService.initMerchantsCache();
  await ApiService.initPackageCategoriesCache();

  // Handle automatic redirects on unauthorized/expired tokens
  ApiService.onUnauthorized = () {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  };

  runApp(const TwicelyApp());
}

class TwicelyApp extends StatelessWidget {
  const TwicelyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode
          .light, // Locked to Light Mode to ensure the cream #fff8ea background is shown
      home: const SplashScreen(),
    );
  }
}
