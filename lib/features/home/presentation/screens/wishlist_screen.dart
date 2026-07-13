import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/cart_manager.dart';
import 'shopping_cart_screen.dart';
import '../../../../core/widgets/custom_snackbar.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  bool _isLoading = true;
  List<dynamic> _wishlistItems = [];

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final res = await ApiService.getUserWishlist();
      if (mounted) {
        setState(() {
          if (res['success'] == true && res['data'] != null) {
            final List<dynamic> rawItems = res['data'];
            _wishlistItems = rawItems.map((p) => _mapApiPackage(p as Map<String, dynamic>)).toList();
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        CustomSnackBar.show(
          context,
          message: 'Failed to load wishlist: $e',
          type: SnackBarType.error,
        );
      }
    }
  }

  Map<String, Color> _getCategoryColors(String category) {
    switch (category.toLowerCase()) {
      case 'wellness':
      case 'spa-massage':
        return {
          'bg': const Color(0xFFE8F5E9),
          'text': const Color(0xFF2E7D32),
        };
      case 'dining':
        return {
          'bg': const Color(0xFFFFFDE7),
          'text': const Color(0xFFF57F17),
        };
      case 'lifestyle':
      case 'lifestyle-classes':
        return {
          'bg': const Color(0xFFE3F2FD),
          'text': const Color(0xFF0D47A1),
        };
      default:
        return {
          'bg': const Color(0xFFF3F4F6),
          'text': const Color(0xFF374151),
        };
    }
  }

  Map<String, dynamic> _mapApiPackage(Map<String, dynamic> apiPkg) {
    String imageUrl = 'assets/images/package_spa.jpg';
    if (apiPkg['cover_url'] != null && apiPkg['cover_url'].toString().isNotEmpty) {
      imageUrl = apiPkg['cover_url'];
    } else if (apiPkg['images'] != null && (apiPkg['images'] as List).isNotEmpty) {
      imageUrl = apiPkg['images'][0]['url'] ?? 'assets/images/package_spa.jpg';
    }

    final double priceVal = (apiPkg['price'] is num)
        ? (apiPkg['price'] as num).toDouble()
        : double.tryParse(apiPkg['price']?.toString() ?? '') ?? 0.0;

    String category = 'General';
    if (apiPkg['category'] != null) {
      if (apiPkg['category'] is Map) {
        category = apiPkg['category']['name']?.toString() ?? 'General';
      } else {
        category = apiPkg['category'].toString();
      }
    }

    final colors = _getCategoryColors(category);

    return {
      'id': apiPkg['id']?.toString() ?? '',
      'title': apiPkg['title'] ?? 'Package Listing',
      'description': apiPkg['description'] ?? 'No description available',
      'category': category,
      'price': priceVal,
      'imageUrl': imageUrl,
      'pillColor': colors['bg'],
      'pillTextColor': colors['text'],
    };
  }

  Future<void> _toggleWishlist(Map<String, dynamic> item) async {
    final int? pkgId = int.tryParse(item['id'].toString());
    if (pkgId == null) return;

    // Show loading spinner
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
      ),
    );

    try {
      final res = await ApiService.unlikePackage(pkgId);
      if (!mounted) return;
      Navigator.of(context).pop(); // dismiss loading
      if (res['success'] == true) {
        _loadWishlist(); // Refresh wishlist
        CustomSnackBar.show(
          context,
          message: 'Removed "${item['title']}" from Wishlist',
          type: SnackBarType.success,
        );
      } else {
        CustomSnackBar.show(
          context,
          message: res['message'] ?? 'Failed to update wishlist',
          type: SnackBarType.error,
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // dismiss loading
      CustomSnackBar.show(
        context,
        message: 'Error: $e',
        type: SnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
            )
          : RefreshIndicator(
              onRefresh: _loadWishlist,
              color: AppColors.primary,
              child: _buildBody(),
            ),
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
            CustomSnackBar.show(
              context,
              message: 'No new notifications',
              type: SnackBarType.info,
            );
          },
        ),
        GestureDetector(
          onTap: () {
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
      physics: const AlwaysScrollableScrollPhysics(),
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
                    child: item['imageUrl'].toString().startsWith('assets/')
                        ? Image.asset(
                            item['imageUrl'] as String,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: AppColors.primary.withValues(alpha: 0.05),
                              child: const Icon(Icons.image, color: AppColors.primary),
                            ),
                          )
                        : Image.network(
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
                      color: item['pillColor'] as Color? ?? const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item['category'] as String,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: item['pillTextColor'] as Color? ?? const Color(0xFF374151),
                      ),
                    ),
                  ),
                ),
                // Floating Heart Icon Button (Active Wishlist)
                Positioned(
                  right: 8,
                  top: 8,
                  child: GestureDetector(
                    onTap: () => _toggleWishlist(item),
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
                        color: Color(0xFF1F2E4E),
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
                      'SGD ${(item['price'] as double).toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                    // Shopping Bag/Cart Icon Button
                    GestureDetector(
                      onTap: () async {
                        final int? pkgId = int.tryParse(item['id'].toString());
                        if (pkgId == null) return;
                        
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(
                            child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
                          ),
                        );

                        try {
                          final res = await ApiService.addToCart(pkgId);
                          if (!mounted) return;
                          Navigator.of(context).pop(); // dismiss loading
                          if (res['success'] == true) {
                            await CartManager().syncWithBackend();
                            if (!mounted) return;
                            CustomSnackBar.show(
                              context,
                              message: 'Added "${item['title']}" to cart!',
                              type: SnackBarType.success,
                              action: SnackBarAction(
                                label: 'VIEW CART',
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const ShoppingCartScreen(),
                                    ),
                                  );
                                },
                              ),
                            );
                          } else {
                            CustomSnackBar.show(
                              context,
                              message: res['message'] ?? 'Failed to add item to cart.',
                              type: SnackBarType.error,
                            );
                          }
                        } catch (e) {
                          if (!mounted) return;
                          Navigator.of(context).pop();
                          CustomSnackBar.show(
                            context,
                            message: 'Error: $e',
                            type: SnackBarType.error,
                          );
                        }
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
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop(2);
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
    final isSelected = index == 4;
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
