import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/session_manager.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/shopping_cart_screen.dart';

class HomeHeader extends StatelessWidget {
  final Map<String, dynamic> profileData;
  final VoidCallback? onProfileTap;

  const HomeHeader({
    super.key,
    required this.profileData,
    this.onProfileTap,
  });

  String _getAvatarUrl(Map<String, dynamic> p) {
    if (p['avatar'] != null && p['avatar'].toString().isNotEmpty) return p['avatar'].toString();
    if (p['avatar_url'] != null && p['avatar_url'].toString().isNotEmpty) return p['avatar_url'].toString();
    if (p['profile_image'] != null && p['profile_image'].toString().isNotEmpty) return p['profile_image'].toString();
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = _getAvatarUrl(profileData);

    return Padding(
      padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(
            'assets/images/logo.webp',
            height: 38,
            fit: BoxFit.contain,
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: AppColors.primary, size: 26),
                onPressed: () {
                  if (SessionManager.isLoggedIn) {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                    );
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  }
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 26),
                onPressed: () {
                  if (SessionManager.isLoggedIn) {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ShoppingCartScreen()),
                    );
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  }
                },
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  if (SessionManager.isLoggedIn) {
                    onProfileTap?.call();
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  }
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.1), width: 1.5),
                  ),
                  clipBehavior: Clip.antiAlias,
                  alignment: Alignment.center,
                  child: avatarUrl.isNotEmpty
                      ? Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 20),
                        )
                      : const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
