import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'shopping_cart_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  // Mock wishlist data matching the figma screenshot exactly
  final List<Map<String, dynamic>> _wishlistItems = [
    {
      'id': '1',
      'title': 'Zen Retreat Pass',
      'description': 'Full day access + Massage',
      'category': 'Wellness',
      'price': 120.00,
      'imageUrl': 'assets/images/package_spa.jpg',
      'pillColor': const Color(0xFFE8F5E9), // light green
      'pillTextColor': const Color(0xFF2E7D32),
    },
    {
      'id': '2',
      'title': 'Vibrant Dinner Date',
      'description': '3-Course for 2 + Wine',
      'category': 'Dining',
      'price': 85.00,
      'imageUrl': 'assets/images/package_yoga.jpg',
      'pillColor': const Color(0xFFFFFDE7), // light yellow
      'pillTextColor': const Color(0xFFF57F17),
    },
    {
      'id': '3',
      'title': 'Analog Vinyl Set',
      'description': 'Curated Jazz Selection',
      'category': 'Lifestyle',
      'price': 45.00,
      'imageUrl': 'assets/images/package_gym.jpg',
      'pillColor': const Color(0xFFE3F2FD), // light blue
      'pillTextColor': const Color(0xFF0D47A1),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildCustomBottomNavBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Image.asset(
        'assets/images/logo.webp',
        height: 34,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Text(
          'twicely',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
      centerTitle: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded, color: AppColors.primary, size: 26),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No new notifications')),
            );
          },
        ),
        GestureDetector(
          onTap: () {
            // Pop to Profile
            Navigator.of(context).pop(4);
          },
          child: Container(
            margin: const EdgeInsets.only(right: 16, left: 4),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.1),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Screen Header Title & Subtitle
          const Text(
            'My Wishlist',
            style: TextStyle(
              fontFamily: 'Recoleta Alt',
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Saved lifestyle experiences & packages',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),

          // Grid of Wishlist Items
          _wishlistItems.isEmpty
              ? _buildEmptyState()
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.76,
                  ),
                  itemCount: _wishlistItems.length,
                  itemBuilder: (context, index) {
                    final item = _wishlistItems[index];
                    return _buildWishlistItemCard(item);
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_outline_rounded,
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your Wishlist is Empty',
              style: TextStyle(
                fontFamily: 'Recoleta Alt',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap the heart icon on any experience card\nto save it here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWishlistItemCard(Map<String, dynamic> item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image Section with Floating Heart and Category Pill
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: Image.asset(
                      item['imageUrl'] as String,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        child: const Icon(Icons.image, color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
                // Category Pill floating on top of image
                Positioned(
                  left: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: item['pillColor'] as Color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item['category'] as String,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: item['pillTextColor'] as Color,
                      ),
                    ),
                  ),
                ),
                // Floating Heart Icon Button (Active Wishlist)
                Positioned(
                  right: 8,
                  top: 8,
                  child: GestureDetector(
                    onTap: () {
                      final removedItem = item;
                      final removedIndex = _wishlistItems.indexOf(item);
                      setState(() {
                        _wishlistItems.removeAt(removedIndex);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Removed "${removedItem['title']}" from Wishlist'),
                          action: SnackBarAction(
                            label: 'UNDO',
                            textColor: const Color(0xFFFBBD03),
                            onPressed: () {
                              setState(() {
                                _wishlistItems.insert(removedIndex, removedItem);
                              });
                            },
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Color(0xFF1F2E4E), // Active navy heart
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Details Section
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item['description'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.primary.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${(item['price'] as double).toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                    // Shopping Bag/Cart Icon Button
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added "${item['title']}" to cart!'),
                            backgroundColor: AppColors.success,
                            action: SnackBarAction(
                              label: 'VIEW CART',
                              textColor: Colors.white,
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const ShoppingCartScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
                        ),
                        child: const Icon(
                          Icons.shopping_bag_outlined,
                          color: AppColors.primary,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EA),
        border: Border(
          top: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.08),
            width: 1.2,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavBarItem(0, Icons.home_rounded, 'Home'),
            _buildNavBarItem(1, Icons.search_rounded, 'Search'),
            // Sell Button
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop(2); // return to home with index 2
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1F2E4E),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.add, color: Colors.white, size: 24),
                  ),
                ],
              ),
            ),
            _buildNavBarItem(3, Icons.chat_bubble_outline_rounded, 'Chat'),
            _buildNavBarItem(4, Icons.person_rounded, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavBarItem(int index, IconData icon, String label) {
    final isSelected = index == 4; // Since we came from Profile, show Profile as active/selected
    final activeColor = const Color(0xFF1F2E4E);
    final inactiveColor = const Color(0xFF1F2E4E).withValues(alpha: 0.4);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop(index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? activeColor : inactiveColor,
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? activeColor : inactiveColor,
            ),
          ),
        ],
      ),
    );
  }
}
