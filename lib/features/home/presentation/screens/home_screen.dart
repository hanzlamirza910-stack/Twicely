import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/session_manager.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import 'category_detail_screen.dart';
import '../../../chat/presentation/screens/conversations_screen.dart';
import 'shopping_cart_screen.dart';
import 'wallet_screen.dart';
import 'my_sales_screen.dart';
import 'my_orders_screen.dart';
import 'wishlist_screen.dart';
import 'payout_screen.dart';
import 'add_package_screen.dart';
import 'package_detail_screen.dart';
import '../../../../core/services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0; // 0: Home, 1: Search, 2: Sell, 3: Chat, 4: Profile
  String _selectedFilter = 'For her';
  String _homeSearchQuery = '';
  String _searchTabQuery = '';
  final TextEditingController _homeSearchController = TextEditingController();
  final TextEditingController _searchTabController = TextEditingController();

  String _selectedMerchant = 'All Merchants';
  String _selectedCategory = 'All Categories';
  String _selectedSort = 'Sort: Price Low to High';
  bool _isRating4Plus = false;
  String _selectedLocation = 'All Locations';

  void _showMerchantFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFFF8EA),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final merchants = ['All Merchants', 'Active Life', 'Amara Spa', 'Absolute Cycle'];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: merchants.map((m) {
              return ListTile(
                title: Text(
                  m,
                  style: TextStyle(
                    fontWeight: _selectedMerchant == m ? FontWeight.bold : FontWeight.normal,
                    color: AppColors.primary,
                  ),
                ),
                trailing: _selectedMerchant == m ? const Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () {
                  setState(() {
                    _selectedMerchant = m;
                  });
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showCategoryFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFFF8EA),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final categories = ['All Categories', 'Yoga & Pilates', 'Spa & Massage', 'Gym & Fitness', 'Beauty & Nails'];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: categories.map((c) {
              return ListTile(
                title: Text(
                  c,
                  style: TextStyle(
                    fontWeight: _selectedCategory == c ? FontWeight.bold : FontWeight.normal,
                    color: AppColors.primary,
                  ),
                ),
                trailing: _selectedCategory == c ? const Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () {
                  setState(() {
                    _selectedCategory = c;
                  });
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showSortFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFFF8EA),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final options = ['Sort: Price Low to High', 'Sort: Price High to Low'];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((o) {
              return ListTile(
                title: Text(
                  o,
                  style: TextStyle(
                    fontWeight: _selectedSort == o ? FontWeight.bold : FontWeight.normal,
                    color: AppColors.primary,
                  ),
                ),
                trailing: _selectedSort == o ? const Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () {
                  setState(() {
                    _selectedSort = o;
                  });
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showLocationFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFFF8EA),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final locations = ['All Locations', 'Central', 'East', 'West', 'North'];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: locations.map((l) {
              return ListTile(
                title: Text(
                  l,
                  style: TextStyle(
                    fontWeight: _selectedLocation == l ? FontWeight.bold : FontWeight.normal,
                    color: AppColors.primary,
                  ),
                ),
                trailing: _selectedLocation == l ? const Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () {
                  setState(() {
                    _selectedLocation = l;
                  });
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }



  bool _checkAuthWithPrompt({required String title, required String message}) {
    if (!SessionManager.isLoggedIn) {
      _showLoginPrompt(title: title, message: message);
      return false;
    }
    return true;
  }

  void _showLoginPrompt({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF8EA),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_outline_rounded,
                      color: Color(0xFFFBBD03),
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Recoleta Alt',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    ).then((_) {
                      setState(() {});
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFBBD03), // Yellow CTA color
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black54,
                    side: BorderSide(color: Colors.black.withValues(alpha: 0.1)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPackageDetails(Map<String, dynamic> pkg) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PackageDetailScreen(package: pkg),
      ),
    );
  }

  final List<Map<String, dynamic>> _allPackages = [
    {
      'imageUrl': 'assets/images/package_yoga.jpg',
      'tag': 'FOR HER • YOGA & PILATES',
      'title': 'A Premium Weekend Yoga & Pilates Pass',
      'originalPrice': 'S\$99.00',
      'resalePrice': 'S\$64.00',
      'hasHeart': true,
      'discountBadge': null,
      'category': 'For her',
    },
    {
      'imageUrl': 'assets/images/package_spa.jpg',
      'tag': 'FOR HER • SPA & MASSAGE',
      'title': 'Renewal Spa & Body Treatment at Orchard',
      'originalPrice': 'S\$350.00',
      'resalePrice': 'S\$100.00',
      'hasHeart': false,
      'discountBadge': '72% OFF',
      'category': 'For her',
    },
    {
      'imageUrl': 'assets/images/package_gym.jpg',
      'tag': 'GENERAL • GYM & FITNESS',
      'title': 'Elite Gym Access & Personal Training',
      'originalPrice': 'S\$200.00',
      'resalePrice': 'S\$150.00',
      'hasHeart': false,
      'discountBadge': '25% OFF',
      'category': 'General',
    },
    {
      'imageUrl': 'assets/images/package_spa.jpg',
      'tag': 'FOR HER • BEAUTY & NAILS',
      'title': 'Luxury Gel Manicure & Custom Nail Art',
      'originalPrice': 'S\$120.00',
      'resalePrice': 'S\$85.00',
      'hasHeart': true,
      'discountBadge': '30% OFF',
      'category': 'For her',
    },
    {
      'imageUrl': 'assets/images/package_gym.jpg',
      'tag': 'FOR HIM • GYM & FITNESS',
      'title': 'Men\'s Strength Conditioning 3-Session Trial',
      'originalPrice': 'S\$180.00',
      'resalePrice': 'S\$90.00',
      'hasHeart': false,
      'discountBadge': '50% OFF',
      'category': 'For him',
    },
    {
      'imageUrl': 'assets/images/package_spa.jpg',
      'tag': 'FOR HIM • SPA & MASSAGE',
      'title': 'Deep Tissue Massage & Aromatherapy for Men',
      'originalPrice': 'S\$210.00',
      'resalePrice': 'S\$130.00',
      'hasHeart': true,
      'discountBadge': '38% OFF',
      'category': 'For him',
    },
    {
      'imageUrl': 'assets/images/package_yoga.jpg',
      'tag': 'GENERAL • LIFESTYLE CLASSES',
      'title': 'Sustainability Craft & Clay Pottery Masterclass',
      'originalPrice': 'S\$150.00',
      'resalePrice': 'S\$125.00',
      'hasHeart': false,
      'discountBadge': '16% OFF',
      'category': 'General',
    },
    {
      'imageUrl': 'assets/images/package_yoga.jpg',
      'tag': 'BIZ+ • CORPORATE YOGA',
      'title': 'Corporate Team Bonding Yoga Pass (10 Pax)',
      'originalPrice': 'S\$800.00',
      'resalePrice': 'S\$550.00',
      'hasHeart': true,
      'discountBadge': '31% OFF',
      'category': 'Biz+',
    },
    {
      'imageUrl': 'assets/images/package_spa.jpg',
      'tag': 'BIZ+ • WELLNESS RETREAT',
      'title': 'Executive Team Wellness Day Out Voucher',
      'originalPrice': 'S\$1200.00',
      'resalePrice': 'S\$950.00',
      'hasHeart': false,
      'discountBadge': '20% OFF',
      'category': 'Biz+',
    },
  ];

  List<Map<String, dynamic>> get _filteredPackages {
    var list = _allPackages.where((pkg) => pkg['category'] == _selectedFilter).toList();
    if (_homeSearchQuery.isNotEmpty) {
      list = list
          .where((pkg) =>
              pkg['title'].toString().toLowerCase().contains(_homeSearchQuery.toLowerCase()) ||
              pkg['tag'].toString().toLowerCase().contains(_homeSearchQuery.toLowerCase()))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: _buildPageBody(),
      ),
      bottomNavigationBar: _buildCustomBottomNavBar(),
    );
  }

  Widget _buildPageBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildSearchTab();
      case 3:
        return _buildChatTab();
      case 4:
        return _buildProfileTab();
      default:
        return _buildHomeTab();
    }
  }

  // --- HOME TAB (Figma Design Layout) ---
  Widget _buildHomeTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Image.asset(
                  'assets/images/logo.webp',
                  height: 38,
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
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded, color: AppColors.primary, size: 26),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notifications screen coming soon!')),
                    );
                  },
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 26),
                  onPressed: () {
                    if (_checkAuthWithPrompt(
                      title: 'Please Login',
                      message: 'Please login to access your shopping cart.',
                    )) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ShoppingCartScreen(),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    if (_checkAuthWithPrompt(
                      title: 'Please Login',
                      message: 'Please login to view and edit your profile details.',
                    )) {
                      setState(() => _currentIndex = 4);
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
                    alignment: Alignment.center,
                    child: const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 20),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 2. Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextFormField(
                controller: _homeSearchController,
                style: const TextStyle(fontSize: 14, color: AppColors.primary),
                onChanged: (val) {
                  setState(() {
                    _homeSearchQuery = val;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search packages, categories...',
                  hintStyle: TextStyle(color: AppColors.primary.withValues(alpha: 0.4)),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
                  suffixIcon: _homeSearchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            setState(() {
                              _homeSearchController.clear();
                              _homeSearchQuery = '';
                            });
                          },
                          child: const Icon(Icons.cancel_rounded, color: AppColors.primary, size: 20),
                        )
                      : Icon(Icons.cancel_outlined, color: AppColors.primary.withValues(alpha: 0.4), size: 20),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 3. Hero Banner Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    // Background Image
                    Image.asset(
                      'assets/images/hero_banner.jpg',
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF7E84F7), Color(0xFF4C52C2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                    // Dark overlay for readability
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.45),
                            Colors.black.withValues(alpha: 0.15),
                          ],
                          begin: Alignment.bottomLeft,
                          end: Alignment.topRight,
                        ),
                      ),
                    ),
                    // Banner Content Text
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't let good\ntimes go to\nwaste.",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "The smart resale marketplace for unused\nand partially used lifestyle packages.",
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Salmon CTA button
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF27B6E), // Bright salmon pink
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text(
                                  'Start exploring now',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 12),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // 4. Popular Categories
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Popular categories',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'See all',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Categories horizontal layout
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                _buildCategoryItem('Yoga &\nPilates', Icons.favorite_rounded, const Color(0xFFFDE8E7), const Color(0xFFA8352A), 'Yoga & Pilates'),
                const SizedBox(width: 14),
                _buildCategoryItem('Spa &\nMassage', Icons.opacity_rounded, const Color(0xFFE8EFFF), const Color(0xFF005FAF), 'Spa & Massage'),
                const SizedBox(width: 14),
                _buildCategoryItem('Hair &\nNails', Icons.content_cut_rounded, const Color(0xFFFFF8D4), const Color(0xFF8B6B00), 'Beauty & Nails'),
                const SizedBox(width: 14),
                _buildCategoryItem('Gym &\nFitness', Icons.fitness_center_rounded, const Color(0xFFE8F8E9), const Color(0xFF1B6A26), 'Gym & Fitness'),
                const SizedBox(width: 14),
                _buildCategoryItem('Lifestyle\nClasses', Icons.palette_rounded, const Color(0xFFFFF0E0), const Color(0xFFD66000), 'Lifestyle Classes'),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // 5. Shop Popular Packages Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Shop popular packages',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Browse what our community is lovin'",
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'See all',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Horizontal Filter Chips (For her, For him, General, Biz+)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                _buildFilterChip('For her'),
                const SizedBox(width: 8),
                _buildFilterChip('For him'),
                const SizedBox(width: 8),
                _buildFilterChip('General'),
                const SizedBox(width: 8),
                _buildFilterChip('Biz+'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Horizontal Packages Scroller
          SizedBox(
            height: 270,
            child: _filteredPackages.isEmpty
                ? const Center(
                    child: Text(
                      'No packages available in this category.',
                      style: TextStyle(color: Colors.black38, fontSize: 13),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    itemCount: _filteredPackages.length,
                    itemBuilder: (context, index) {
                      final pkg = _filteredPackages[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 14.0),
                        child: _buildPackageCard(
                          imageUrl: pkg['imageUrl'] as String,
                          tag: pkg['tag'] as String,
                          title: pkg['title'] as String,
                          originalPrice: pkg['originalPrice'] as String,
                          resalePrice: pkg['resalePrice'] as String,
                          hasHeart: pkg['hasHeart'] as bool,
                          discountBadge: pkg['discountBadge'] as String?,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(String title, IconData icon, Color bgColor, Color iconColor, String originalName) {
    return GestureDetector(
      onTap: () {
        String imagePath = 'assets/images/cat_yoga.png';
        if (originalName == 'Spa & Massage') imagePath = 'assets/images/cat_spa.png';
        if (originalName == 'Beauty & Nails' || originalName == 'Hair & Nails') imagePath = 'assets/images/cat_nails.png';
        if (originalName == 'Gym & Fitness') imagePath = 'assets/images/cat_gym.png';
        if (originalName == 'Lifestyle Classes') imagePath = 'assets/images/cat_lifestyle.png';

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CategoryDetailScreen(
              categoryName: originalName,
              categoryIcon: imagePath,
            ),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String text) {
    final isSelected = _selectedFilter == text;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF27B6E) : Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? const Color(0xFFF27B6E) : AppColors.primary.withValues(alpha: 0.05),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildPackageCard({
    required String imageUrl,
    required String tag,
    required String title,
    required String originalPrice,
    required String resalePrice,
    bool hasHeart = false,
    String? discountBadge,
  }) {
    return GestureDetector(
      onTap: () {
        _showPackageDetails({
          'imageUrl': imageUrl,
          'tag': tag,
          'title': title,
          'originalPrice': originalPrice,
          'resalePrice': resalePrice,
          'hasHeart': hasHeart,
          'discountBadge': discountBadge,
        });
      },
      child: Container(
      width: 175,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image top header
          SizedBox(
            height: 120,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  imageUrl.startsWith('assets/')
                      ? Image.asset(
                          imageUrl,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: AppColors.primary.withValues(alpha: 0.05),
                            child: const Icon(Icons.image_outlined, color: AppColors.primary),
                          ),
                        )
                      : Image.network(
                          imageUrl,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: AppColors.primary.withValues(alpha: 0.05),
                            child: const Icon(Icons.image_outlined, color: AppColors.primary),
                          ),
                        ),
                  // Heart top right button
                  if (hasHeart)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.favorite_rounded, color: Color(0xFFB3261E), size: 16),
                      ),
                    ),
                  // Discount badge
                  if (discountBadge != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF176), // Bright soft yellow
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          discountBadge,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Content metadata
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tag,
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF27B6E),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                // Strikethrough original and resale price
                Text(
                  originalPrice,
                  style: TextStyle(
                    fontSize: 10,
                    decoration: TextDecoration.lineThrough,
                    color: AppColors.primary.withValues(alpha: 0.35),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  resalePrice,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  // --- SECONDARY TABS SIMULATION ---
  Widget _buildSearchTab() {
    final filtered = _searchTabFilteredPackages;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header Row
        Padding(
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notifications screen coming soon!')),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 26),
                    onPressed: () {
                      if (_checkAuthWithPrompt(
                        title: 'Please Login',
                        message: 'Please login to access your shopping cart.',
                      )) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ShoppingCartScreen(),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      if (_checkAuthWithPrompt(
                        title: 'Please Login',
                        message: 'Please login to view and edit your profile details.',
                      )) {
                        setState(() => _currentIndex = 4);
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
                      alignment: Alignment.center,
                      child: const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Scrollable Body containing everything
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Search Input Box
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchTabController,
                      onChanged: (val) {
                        setState(() {
                          _searchTabQuery = val;
                        });
                      },
                      style: const TextStyle(fontSize: 14, color: AppColors.primary),
                      decoration: InputDecoration(
                        hintText: 'Search packages...',
                        hintStyle: TextStyle(color: AppColors.primary.withValues(alpha: 0.4), fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                        suffixIcon: _searchTabQuery.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _searchTabController.clear();
                                    _searchTabQuery = '';
                                  });
                                },
                                child: const Icon(Icons.cancel_rounded, color: AppColors.primary, size: 20),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Filters dropdown row: All Merchants, All Categories
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: [
                      // Merchants Dropdown
                      Expanded(
                        child: GestureDetector(
                          onTap: _showMerchantFilter,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _selectedMerchant,
                                    style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.primary),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Categories Dropdown
                      Expanded(
                        child: GestureDetector(
                          onTap: _showCategoryFilter,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _selectedCategory,
                                    style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.primary),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Horizontally Scrollable Pills Row (Sort, Rating, Location)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: [
                      // Sort Pill
                      GestureDetector(
                        onTap: _showSortFilter,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF1F2E4E)),
                          ),
                          child: Text(
                            _selectedSort,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1F2E4E)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Rating Pill
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isRating4Plus = !_isRating4Plus;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _isRating4Plus ? const Color(0xFF1F2E4E) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _isRating4Plus ? const Color(0xFF1F2E4E) : AppColors.primary.withValues(alpha: 0.15)),
                          ),
                          child: Text(
                            'Rating 4.0+',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _isRating4Plus ? Colors.white : AppColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Location Pill
                      GestureDetector(
                        onTap: _showLocationFilter,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedLocation != 'All Locations' ? const Color(0xFF1F2E4E) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _selectedLocation != 'All Locations' ? const Color(0xFF1F2E4E) : AppColors.primary.withValues(alpha: 0.15)),
                          ),
                          child: Text(
                            _selectedLocation,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _selectedLocation != 'All Locations' ? Colors.white : AppColors.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Results Count text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    '${filtered.length} Results Found',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Section: Shop popular packages
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Shop popular packages',
                            style: TextStyle(
                              fontFamily: 'Recoleta Alt',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Browse what our community is lovin'",
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.primary.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'See all',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Horizontal popular packages list
                SizedBox(
                  height: 260,
                  child: filtered.isEmpty
                      ? const Center(
                          child: Text(
                            'No matching packages found',
                            style: TextStyle(color: Colors.black38, fontSize: 13),
                          ),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final pkg = filtered[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 14.0),
                              child: _buildPackageCard(
                                imageUrl: pkg['imageUrl'] as String,
                                tag: pkg['tag'] as String,
                                title: pkg['title'] as String,
                                originalPrice: pkg['originalPrice'] as String,
                                resalePrice: pkg['resalePrice'] as String,
                                hasHeart: pkg['hasHeart'] as bool,
                                discountBadge: pkg['discountBadge'] as String?,
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 28),

                // Section: RECENTLY VIEWED
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    'RECENTLY VIEWED',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: Colors.black45,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Two columns grid of recently viewed
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildPackageCard(
                          imageUrl: 'assets/images/package_yoga.jpg',
                          tag: 'FOR HER • YOGA & PILATES',
                          title: 'Guided "Anger Yoga" + Cold Towel Reset (1 Session)',
                          originalPrice: 'S\$6,500.00',
                          resalePrice: 'S\$5,000.00',
                          hasHeart: false,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildPackageCard(
                          imageUrl: 'assets/images/package_yoga.jpg',
                          tag: 'FOR HER • YOGA & PILATES',
                          title: 'Beer Yoga Class at Marina Bay',
                          originalPrice: 'S\$1,500.00',
                          resalePrice: 'S\$1,120.00',
                          hasHeart: false,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ],
    );
  }

  double _parsePrice(String priceStr) {
    final clean = priceStr.replaceAll(r'S$', '').replaceAll(r'$', '').trim();
    return double.tryParse(clean) ?? 0.0;
  }

  List<Map<String, dynamic>> get _searchTabFilteredPackages {
    List<Map<String, dynamic>> res = List.from(_allPackages);

    if (_searchTabQuery.isNotEmpty) {
      res = res.where((pkg) =>
          pkg['title'].toString().toLowerCase().contains(_searchTabQuery.toLowerCase()) ||
          pkg['tag'].toString().toLowerCase().contains(_searchTabQuery.toLowerCase()) ||
          pkg['category'].toString().toLowerCase().contains(_searchTabQuery.toLowerCase())).toList();
    }

    if (_selectedMerchant != 'All Merchants') {
      if (_selectedMerchant == 'Active Life') {
        res = res.where((pkg) => pkg['tag'].toString().contains('GYM')).toList();
      } else if (_selectedMerchant == 'Amara Spa') {
        res = res.where((pkg) => pkg['tag'].toString().contains('SPA')).toList();
      } else if (_selectedMerchant == 'Absolute Cycle') {
        res = res.where((pkg) => pkg['tag'].toString().contains('YOGA')).toList();
      }
    }

    if (_selectedCategory != 'All Categories') {
      if (_selectedCategory == 'Yoga & Pilates') {
        res = res.where((pkg) => pkg['tag'].toString().contains('YOGA')).toList();
      } else if (_selectedCategory == 'Spa & Massage') {
        res = res.where((pkg) => pkg['tag'].toString().contains('SPA')).toList();
      } else if (_selectedCategory == 'Gym & Fitness') {
        res = res.where((pkg) => pkg['tag'].toString().contains('GYM')).toList();
      } else if (_selectedCategory == 'Beauty & Nails') {
        res = res.where((pkg) => pkg['tag'].toString().contains('BEAUTY')).toList();
      }
    }

    if (_isRating4Plus) {
      res = res.where((pkg) => pkg['hasHeart'] == true || pkg['discountBadge'] != null).toList();
    }

    if (_selectedSort == 'Sort: Price Low to High') {
      res.sort((a, b) => _parsePrice(a['resalePrice'] as String).compareTo(_parsePrice(b['resalePrice'] as String)));
    } else if (_selectedSort == 'Sort: Price High to Low') {
      res.sort((a, b) => _parsePrice(b['resalePrice'] as String).compareTo(_parsePrice(a['resalePrice'] as String)));
    }

    return res;
  }

  Widget _buildChatTab() {
    return ConversationsScreen(
      onProfileTap: () {
        setState(() {
          _currentIndex = 4; // Navigate to Profile
        });
      },
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          // Profile image & edit pencil badge
          Center(
            child: Stack(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFF27B6E).withValues(alpha: 0.2), width: 2),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/avatar_sarah.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1F2E4E),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Name and Member Date
          Text(
            SessionManager.userName ?? 'Twicely Member',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Recoleta Alt',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.account_circle_outlined, size: 14, color: Colors.black38),
              SizedBox(width: 4),
              Text(
                'Member since 2024',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Badges row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2E4E),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'CONCIERGE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: const [
                    Text(
                      '5.0',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.star, size: 10, color: AppColors.primary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Option cards
          _buildProfileOption(
            title: 'Wallet',
            subtitle: 'Balance: \$124.58',
            icon: Icons.account_balance_wallet_outlined,
            onTap: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const WalletScreen(),
                ),
              );
              if (result is int) {
                setState(() => _currentIndex = result);
              }
            },
          ),
          const SizedBox(height: 12),
          _buildProfileOption(
            title: 'My Sales',
            subtitle: '2 Active Listings',
            icon: Icons.sell_outlined,
            onTap: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const MySalesScreen(),
                ),
              );
              if (result is int) {
                setState(() => _currentIndex = result);
              }
            },
          ),
          const SizedBox(height: 12),
          _buildProfileOption(
            title: 'My Orders',
            subtitle: 'Track your purchases',
            icon: Icons.shopping_bag_outlined,
            onTap: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const MyOrdersScreen(),
                ),
              );
              if (result is int) {
                setState(() => _currentIndex = result);
              }
            },
          ),
          const SizedBox(height: 12),
          _buildProfileOption(
            title: 'Wishlist',
            subtitle: '14 saved items',
            icon: Icons.favorite_outline_rounded,
            onTap: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const WishlistScreen(),
                ),
              );
              if (result is int) {
                setState(() => _currentIndex = result);
              }
            },
          ),
          const SizedBox(height: 12),
          _buildProfileOption(
            title: 'Payout Methods',
            subtitle: 'Manage bank accounts',
            icon: Icons.payment_outlined,
            onTap: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PayoutScreen(),
                ),
              );
              if (result is int) {
                setState(() => _currentIndex = result);
              }
            },
          ),
          const SizedBox(height: 12),
          _buildProfileOption(
            title: 'Settings',
            subtitle: 'Notifications, Privacy',
            icon: Icons.settings_outlined,
            onTap: () {},
          ),
          const SizedBox(height: 24),

          // Logout Action button
          OutlinedButton.icon(
            onPressed: () async {
              final navigator = Navigator.of(context);
              await ApiService.logout();
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout, size: 16, color: AppColors.primary),
            label: const Text(
              'Log Out',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: const Color(0xFFFFFDF9),
              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.08)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProfileOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.04),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 18,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black38,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.black26,
          size: 20,
        ),
        onTap: onTap,
      ),
    );
  }

  // --- CUSTOM BOTTOM NAVIGATION BAR ---
  Widget _buildCustomBottomNavBar() {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Navigation Icons
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(child: _buildNavBarItem(0, Icons.home_rounded, 'Home')),
                    Expanded(child: _buildNavBarItem(1, Icons.search_rounded, 'Search')),
                    const SizedBox(width: 64), // Empty space for protruding center button
                    Expanded(child: _buildNavBarItem(3, Icons.chat_bubble_outline_rounded, 'Chat')),
                    Expanded(child: _buildNavBarItem(4, Icons.person_outline_rounded, 'Profile')),
                  ],
                ),
              ),
            ),
          ),
          // Floating Center Button
          Positioned(
            top: -24,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  if (_checkAuthWithPrompt(
                    title: 'Please Login',
                    message: 'Please login to list and sell your lifestyle packages.',
                  )) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AddPackageScreen(),
                      ),
                    );
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F2E4E),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1F2E4E).withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Sell',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2E4E),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavBarItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final activeColor = const Color(0xFF1F2E4E);
    final inactiveColor = const Color(0xFF1F2E4E).withValues(alpha: 0.4);

    return GestureDetector(
      onTap: () {
        if (index == 3) {
          if (!_checkAuthWithPrompt(
            title: 'Please Login',
            message: 'Please login to chat with seller',
          )) {
            return;
          }
        } else if (index == 4) {
          if (!_checkAuthWithPrompt(
            title: 'Please Login',
            message: 'Please login to view and edit your profile details.',
          )) {
            return;
          }
        }
        setState(() => _currentIndex = index);
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
