import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../chat/presentation/screens/conversations_screen.dart';
import 'add_package_screen.dart';
import 'notifications_screen.dart';
import 'wallet_screen.dart';
import 'my_sales_screen.dart';
import 'my_orders_screen.dart';
import 'wishlist_screen.dart';
import 'payout_screen.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/session_manager.dart';
import 'home_screen.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import 'package:image_picker/image_picker.dart';


class MerchantDashboard extends StatefulWidget {
  const MerchantDashboard({super.key});

  @override
  State<MerchantDashboard> createState() => _MerchantDashboardState();
}

class _MerchantDashboardState extends State<MerchantDashboard> {
  int _currentIndex = 0; // 0: Home, 1: Search, 2: Sell, 3: Chat, 4: Profile
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedPill = 'All';
  String _selectedDateFilter = 'All time';
  String _selectedSortOrder = 'Newest';

  String _merchantBusinessName = "Rolys";
  String _merchantBusinessType = "Company";
  String _merchantRegNumber = "2324";
  String _merchantAddress = "07 lahore";
  String _merchantWebsite = "-";
  String _merchantEmail = "synvolv3@gmail.com";
  String _merchantPhone = "03030844726";
  String _merchantLogoUrl = "";

  final ImagePicker _picker = ImagePicker();
  bool _isUploadingLogo = false;
  String? _localLogoPath;

  List<Map<String, dynamic>> _merchantPackages = [];
  bool _isLoadingPackages = false;

  // Dynamic Merchant statistics, wallet balance, and wishlist count
  double _walletBalance = 0.0;
  int _wishlistCount = 0;
  Map<String, dynamic> _merchantStats = {};
  List<Map<String, dynamic>> _merchantOrders = [];

  @override
  void initState() {
    super.initState();
    _loadMerchantData();
    _fetchMerchantPackages();
    _fetchDynamicData();
  }

  @override
  void dispose() {
    super.dispose();
  }


  void _loadMerchantData() {
    if (SessionManager.isLoggedIn) {
      final user = SessionManager.userData;
      if (user != null) {
        _merchantBusinessName = user['business_name'] as String? ?? 
            user['name'] as String? ?? 
            '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
        if (_merchantBusinessName.isEmpty) {
          _merchantBusinessName = "Rolys";
        }
        _merchantEmail = user['email'] as String? ?? "synvolv3@gmail.com";
        _merchantPhone = user['phone'] as String? ?? "03030844726";
        _merchantBusinessType = user['business_type'] as String? ?? "Company";
        _merchantRegNumber = user['business_registration'] as String? ?? "2324";
        _merchantAddress = user['business_address'] as String? ?? "07 lahore";
        _merchantWebsite = user['website_link'] as String? ?? "-";
        _merchantLogoUrl = user['logo'] as String? ?? user['logo_url'] as String? ?? user['avatar_url'] as String? ?? '';
      }
    }
  }

  Map<String, dynamic> _mapApiPackage(Map<String, dynamic> apiPkg) {
    String imageUrl = '';
    if (apiPkg['cover_url'] != null && apiPkg['cover_url'].toString().isNotEmpty) {
      imageUrl = apiPkg['cover_url'];
    } else if (apiPkg['images'] != null && (apiPkg['images'] as List).isNotEmpty) {
      imageUrl = apiPkg['images'][0]['url'] ?? '';
    }

    final double priceVal = double.tryParse(apiPkg['price']?.toString() ?? '') ?? 0.0;

    String category = 'General';
    if (apiPkg['category'] != null) {
      if (apiPkg['category'] is Map) {
        category = apiPkg['category']['name']?.toString() ?? 'General';
      } else {
        category = apiPkg['category'].toString();
      }
    }

    final statusStr = apiPkg['status']?.toString().toLowerCase() ?? 'published';
    final availStatus = apiPkg['availability_status']?.toString().toLowerCase() ?? '';

    final result = Map<String, dynamic>.from(apiPkg);
    result['id'] = apiPkg['id'];
    result['title'] = apiPkg['title'] ?? 'Package Listing';
    result['category'] = category;
    result['price'] = priceVal.toStringAsFixed(2);
    result['status'] = statusStr.toUpperCase();          // e.g. PUBLISHED / DRAFT / PENDING
    result['badge'] = availStatus == 'sold' ? 'SOLD' : null;  // only show if sold
    result['image'] = imageUrl;
    result['imageUrl'] = imageUrl;
    result['createdAt'] = apiPkg['date_created']?.toString() ?? apiPkg['created_at']?.toString() ?? apiPkg['date']?.toString() ?? '';
    result['is_owner'] = apiPkg['is_owner'] ?? true;
    return result;
  }

  Future<void> _fetchMerchantPackages() async {
    if (mounted) {
      setState(() {
        _isLoadingPackages = true;
      });
    }
    final res = await ApiService.getMerchantPackages();
    if (!mounted) return;
    if (res['success'] == true && res['data'] != null) {
      final List<dynamic> pkgs = res['data'];
      setState(() {
        _merchantPackages = pkgs.map((p) => _mapApiPackage(p as Map<String, dynamic>)).toList();
        _isLoadingPackages = false;
      });
    } else {
      setState(() {
        _isLoadingPackages = false;
      });
    }
  }

  Future<void> _fetchDynamicData() async {
    if (!mounted) return;

    try {
      // 1. Fetch Merchant profile details
      final profileRes = await ApiService.getMerchantMe();
      if (profileRes['success'] == true && profileRes['data'] != null) {
        final mData = profileRes['data'] as Map<String, dynamic>;
        setState(() {
          _merchantBusinessName = mData['business_name']?.toString() ?? _merchantBusinessName;
          _merchantBusinessType = mData['business_type']?.toString() ?? _merchantBusinessType;
          _merchantRegNumber = mData['business_registration']?.toString() ?? _merchantRegNumber;
          _merchantAddress = mData['business_address']?.toString() ?? _merchantAddress;
          _merchantWebsite = mData['website_link']?.toString() ?? _merchantWebsite;
          _merchantEmail = mData['email']?.toString() ?? _merchantEmail;
          _merchantPhone = mData['phone']?.toString() ?? _merchantPhone;
          _merchantLogoUrl = mData['logo']?.toString() ?? mData['logo_url']?.toString() ?? mData['avatar_url']?.toString() ?? _merchantLogoUrl;
        });
      }

      // 2. Fetch wallet balance
      final walletRes = await ApiService.getMerchantWallet();
      if (walletRes['success'] == true && walletRes['data'] != null) {
        final wData = walletRes['data'] as Map;
        setState(() {
          _walletBalance = double.tryParse(wData['balance']?.toString() ?? '0.0') ?? 0.0;
        });
      }

      // 3. Fetch stats
      final statsRes = await ApiService.getMerchantStats();
      if (statsRes['success'] == true && statsRes['data'] != null) {
        setState(() {
          _merchantStats = Map<String, dynamic>.from(statsRes['data'] as Map);
        });
      }

      // 4. Fetch Wishlist Count
      final wishlistRes = await ApiService.getUserWishlist();
      if (wishlistRes['success'] == true && wishlistRes['data'] != null) {
        final List<dynamic> list = wishlistRes['data'] as List<dynamic>? ?? [];
        setState(() {
          _wishlistCount = list.length;
        });
      }

      // 5. Fetch Merchant Orders
      final ordersRes = await ApiService.getMerchantOrders();
      if (ordersRes['success'] == true && ordersRes['data'] != null) {
        final List<dynamic> oList = ordersRes['data'] as List<dynamic>? ?? [];
        setState(() {
          _merchantOrders = oList.map((o) => Map<String, dynamic>.from(o as Map)).toList();
        });
      }
    } catch (e) {
      debugPrint('[MerchantDashboard] Error fetching dynamic data: $e');
    }
  }

  List<Map<String, dynamic>> get _filteredPackages {
    var list = _merchantPackages.where((pkg) {
      final matchesSearch = pkg['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          pkg['category'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      
      if (!matchesSearch) return false;
      
      // Status Filter
      if (_selectedPill == 'Published') {
        if (pkg['status'].toString().toUpperCase() != 'PUBLISHED') return false;
      } else if (_selectedPill == 'Pending') {
        if (pkg['status'].toString().toUpperCase() != 'PENDING') return false;
      }
      
      // Date Filter
      if (_selectedDateFilter != 'All time') {
        final dateStr = pkg['createdAt']?.toString() ?? '';
        if (dateStr.isNotEmpty) {
          try {
            final dt = DateTime.parse(dateStr);
            final difference = DateTime.now().difference(dt).inDays;
            if (_selectedDateFilter == 'This Week') {
              if (difference > 7) return false;
            } else if (_selectedDateFilter == 'This Month') {
              if (difference > 30) return false;
            }
          } catch (_) {
            return false;
          }
        } else {
          return false;
        }
      }
      
      return true;
    }).toList();

    if (_selectedSortOrder == 'Price: Low to High') {
      list.sort((a, b) {
        final double aPrice = double.tryParse(a['price']?.toString() ?? '0.0') ?? 0.0;
        final double bPrice = double.tryParse(b['price']?.toString() ?? '0.0') ?? 0.0;
        return aPrice.compareTo(bPrice);
      });
    } else if (_selectedSortOrder == 'Price: High to Low') {
      list.sort((a, b) {
        final double aPrice = double.tryParse(a['price']?.toString() ?? '0.0') ?? 0.0;
        final double bPrice = double.tryParse(b['price']?.toString() ?? '0.0') ?? 0.0;
        return bPrice.compareTo(aPrice);
      });
    } else {
      list.sort((a, b) {
        final int aId = int.tryParse(a['id']?.toString() ?? '0') ?? 0;
        final int bId = int.tryParse(b['id']?.toString() ?? '0') ?? 0;
        return bId.compareTo(aId);
      });
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
        return _buildPackagesTab();
      case 3:
        return ConversationsScreen(
          onProfileTap: () {
            setState(() {
              _currentIndex = 4; // Go to profile
            });
          },
        );
      case 4:
        return _buildProfileTab();
      default:
        return Center(
          child: Text(
            'Tab $_currentIndex under development',
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
        );
    }
  }

  String _getCurrentFormattedDate() {
    final now = DateTime.now();
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  Widget _buildHomeTab() {
    final totalPkgs = _merchantPackages.length.toString();
    final num revNum = _merchantStats['revenue_this_week'] ?? 0;
    final String revenueThisWeek = 'S\$${(revNum / 100.0).toStringAsFixed(2)}';
    
    final totalSold = _merchantStats['total_sold_packages'] ?? _merchantStats['sold_listings'] ?? _merchantOrders.length;
    final String totalSellPackages = totalSold.toString();
    
    final String walletBalance = 'S\$${(_walletBalance / 100.0).toStringAsFixed(2)}';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
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
                    icon: const Icon(Icons.notifications_none_rounded, color: AppColors.primary, size: 24),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentIndex = 4; // Go to profile
                      });
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12), width: 1.5),
                      ),
                      child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Greeting section
          Text(
            'Good Evening, $_merchantBusinessName!',
            style: const TextStyle(
              fontFamily: 'Recoleta Alt',
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getCurrentFormattedDate(),
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),

          // Buttons row
          Row(
            children: [
              // Help & FAQ
              Expanded(
                child: GestureDetector(
                  onTap: _showHelpFaq,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.20), width: 1.2),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.help_outline_rounded, size: 18, color: AppColors.primary),
                        SizedBox(width: 6),
                        Text(
                          'Help & FAQ',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Add Package
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final added = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (context) => AddPackageScreen(
                          onPackageAdded: (pkg) {
                            setState(() {
                              _merchantPackages.add(pkg);
                            });
                          },
                        ),
                      ),
                    );
                    if (added == true) {
                      setState(() {});
                    }
                  },
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBBD03), // Yellow CTA color
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add, size: 18, color: AppColors.primary),
                        SizedBox(width: 6),
                        Text(
                          'Add Package',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 2x2 Grid of Metrics Cards
          Row(
            children: [
              // Card 1: Total Packages (Navy Background)
              Expanded(
                child: _buildMetricCard(
                  title: 'Total Packages',
                  value: totalPkgs,
                  icon: Icons.inventory_2_outlined,
                  isNavy: true,
                ),
              ),
              const SizedBox(width: 14),
              // Card 2: Revenue This Week
              Expanded(
                child: _buildMetricCard(
                  title: 'Revenue This Week',
                  value: revenueThisWeek,
                  icon: Icons.attach_money_rounded,
                  iconColor: Colors.green,
                  isNavy: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Card 3: Total Sell Packages
              Expanded(
                child: _buildMetricCard(
                  title: 'Total Sell Packages',
                  value: totalSellPackages,
                  icon: Icons.shopping_bag_outlined,
                  iconColor: Colors.blueAccent,
                  isNavy: false,
                ),
              ),
              const SizedBox(width: 14),
              // Card 4: Wallet Balance
              Expanded(
                child: _buildMetricCard(
                  title: 'Wallet Balance',
                  value: walletBalance,
                  icon: Icons.account_balance_wallet_outlined,
                  iconColor: Colors.purple,
                  isNavy: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Recent Packages Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Packages',
                style: TextStyle(
                  fontFamily: 'Recoleta Alt',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _currentIndex = 1),
                child: const Text('View all', style: TextStyle(color: Colors.black45, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_isLoadingPackages)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
              ),
            )
          else if (_merchantPackages.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                'No packages listed yet.',
                style: TextStyle(color: Colors.black38, fontSize: 13, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            )
          else
            ..._merchantPackages.take(2).map((pkg) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _buildRecentPackageItem(
                    title: pkg['title'] ?? '',
                    date: 'Listed package',
                    status: pkg['status'] ?? 'PUBLISHED',
                  ),
                )),
          const SizedBox(height: 24),

          // Recent Sales Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Sales',
                style: TextStyle(
                  fontFamily: 'Recoleta Alt',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const MySalesScreen()),
                  );
                },
                child: const Text('View all', style: TextStyle(color: Colors.black45, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_merchantOrders.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                'No sales recorded yet.',
                style: TextStyle(color: Colors.black38, fontSize: 13, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            )
          else
            ..._merchantOrders.take(2).map((order) {
              final String itemsSummary = (order['items'] as List?)
                  ?.map((it) => it['package_title'] ?? '')
                  .join(', ') ?? 'Sale Package';
              final double totalVal = double.tryParse(order['total']?.toString() ?? '0.0') ?? 0.0;
              final String priceStr = 'S\$${(totalVal / 100.0).toStringAsFixed(2)}';
              
              String dateStr = 'Recent Order';
              if (order['created_at'] != null) {
                try {
                  final dt = DateTime.parse(order['created_at'].toString());
                  dateStr = '${dt.day}/${dt.month}/${dt.year}';
                } catch (_) {}
              }
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _buildRecentSaleItem(
                  title: itemsSummary,
                  date: dateStr,
                  amount: priceStr,
                ),
              );
            }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    Color? iconColor,
    required bool isNavy,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isNavy ? const Color(0xFF1F2E4E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: isNavy ? null : Border.all(color: AppColors.primary.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isNavy ? Colors.white70 : Colors.black54,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isNavy ? Colors.white.withValues(alpha: 0.12) : (iconColor ?? AppColors.primary).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: isNavy ? Colors.white : (iconColor ?? AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: isNavy ? Colors.white : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentPackageItem({
    required String title,
    required String date,
    required String status,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  date,
                  style: const TextStyle(fontSize: 11, color: Colors.black38),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9), // Light green
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSaleItem({
    required String title,
    required String date,
    required String amount,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  date,
                  style: const TextStyle(fontSize: 11, color: Colors.black38),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpFaq() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      backgroundColor: AppColors.bgLight,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Merchant Help & FAQ',
              style: TextStyle(
                fontFamily: 'Recoleta Alt',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'How do listing reviews work?',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14),
            ),
            const SizedBox(height: 4),
            const Text(
              'Once you add a package in the Sell tab, it goes into review to ensure high-quality and consistent service details. Reviews take less than 24 hours.',
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 16),
            const Text(
              'When do I receive payment payouts?',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14),
            ),
            const SizedBox(height: 4),
            const Text(
              'Payments clear 7 days after the consumer purchases your package. Once cleared, you can withdraw your balance instantly under the Wallet section.',
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    final firstLetter = _merchantBusinessName.isNotEmpty ? _merchantBusinessName[0].toUpperCase() : 'M';
    final name = _merchantBusinessName;
    final email = _merchantEmail;
    final phone = _merchantPhone;
    final type = _merchantBusinessType;
    final reg = _merchantRegNumber;
    final addr = _merchantAddress;
    final web = _merchantWebsite;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          
          // Centered Profile Avatar & Header info
          Center(
            child: Stack(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF1F2E4E).withValues(alpha: 0.3), width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(48),
                    child: _isUploadingLogo
                        ? const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                            ),
                          )
                        : _localLogoPath != null
                            ? Image.file(
                                File(_localLogoPath!),
                                fit: BoxFit.cover,
                              )
                            : _merchantLogoUrl.isNotEmpty
                                ? Image.network(
                                    _merchantLogoUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _buildDefaultLogo(firstLetter),
                                  )
                                : _buildDefaultLogo(firstLetter),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => _showEditMerchantProfileSheet(name, type, reg, addr, web, phone),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF27B6E),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, color: Colors.white, size: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Business Name
          Text(
            name.isEmpty ? 'Merchant Partner' : name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Recoleta Alt',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),

          // Email
          if (email.isNotEmpty)
            Text(
              email,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.primary.withValues(alpha: 0.5)),
            ),

          // Phone
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              phone,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.primary.withValues(alpha: 0.4)),
            ),
          ],
          const SizedBox(height: 10),

          // Badges
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
                  'MERCHANT',
                  style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 28),

          // Option cards
          _buildProfileOption(
            title: 'Switch to C2C Dashboard',
            subtitle: 'Browse packages & buy items',
            icon: Icons.swap_horiz_rounded,
            onTap: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildProfileOption(
            title: 'Business Profile',
            subtitle: 'Edit business details & address',
            icon: Icons.business_outlined,
            onTap: () => _showEditMerchantProfileSheet(name, type, reg, addr, web, phone),
          ),
          const SizedBox(height: 12),
          _buildProfileOption(
            title: 'Wallet',
            subtitle: 'Balance: S\$${(_walletBalance / 100.0).toStringAsFixed(2)}',
            icon: Icons.account_balance_wallet_outlined,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const WalletScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildProfileOption(
            title: 'My Sales',
            subtitle: '${_merchantPackages.length} Active Listings',
            icon: Icons.sell_outlined,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const MySalesScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildProfileOption(
            title: 'My Orders',
            subtitle: 'Track your purchases',
            icon: Icons.shopping_bag_outlined,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const MyOrdersScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildProfileOption(
            title: 'Wishlist',
            subtitle: '$_wishlistCount saved items',
            icon: Icons.favorite_outline_rounded,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const WishlistScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildProfileOption(
            title: 'Payout Methods',
            subtitle: 'Manage bank accounts',
            icon: Icons.payment_outlined,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PayoutScreen(),
                ),
              );
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

  Widget _buildDefaultLogo(String initials) {
    return Container(
      color: const Color(0xFFF1F5F9),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
          fontFamily: 'Recoleta Alt',
        ),
      ),
    );
  }



  void _showEditMerchantProfileSheet(
    String currentName,
    String currentType,
    String currentReg,
    String currentAddr,
    String currentWeb,
    String currentPhone,
  ) {
    final nameCtrl = TextEditingController(text: currentName);
    final typeCtrl = TextEditingController(text: currentType);
    final regCtrl = TextEditingController(text: currentReg);
    final addrCtrl = TextEditingController(text: currentAddr);
    final webCtrl = TextEditingController(text: currentWeb);
    final phoneCtrl = TextEditingController(text: currentPhone);
    final email = _merchantEmail;
    final firstLetter = currentName.isNotEmpty ? currentName[0].toUpperCase() : 'M';
    final logoUrl = _merchantLogoUrl;
    bool isSaving = false;
    String? localLogoPath;

    debugPrint('[MerchantProfileEdit] Opening Edit Business Profile bottom sheet.');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final isUploading = _isUploadingLogo;
          return Container(
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Business Profile',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary, fontFamily: 'Recoleta Alt')),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          debugPrint('[MerchantProfileEdit] Closing edit sheet via close button.');
                          Navigator.of(ctx).pop();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Logo Avatar Pick Option inside sheet
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFF9E7C9), width: 1.5),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(44),
                            child: isUploading
                                ? const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                    ),
                                  )
                                : localLogoPath != null
                                    ? Image.file(
                                        File(localLogoPath!),
                                        fit: BoxFit.cover,
                                      )
                                    : logoUrl.isNotEmpty
                                        ? Image.network(
                                            logoUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => _buildDefaultLogo(firstLetter),
                                          )
                                        : _buildDefaultLogo(firstLetter),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              _showImageSourceActionSheet(
                                context,
                                true,
                                onImagePicked: (path) {
                                  setModalState(() {
                                    localLogoPath = path;
                                  });
                                  debugPrint('[MerchantProfileEdit] Local logo selected: $path');
                                },
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        _showImageSourceActionSheet(
                          context,
                          true,
                          onImagePicked: (path) {
                            setModalState(() {
                              localLogoPath = path;
                            });
                            debugPrint('[MerchantProfileEdit] Local logo selected: $path');
                          },
                        );
                      },
                      child: const Text('Change Business Logo', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Text Fields
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(fontSize: 14, color: AppColors.primary),
                    decoration: InputDecoration(
                      labelText: 'Business Name *',
                      labelStyle: TextStyle(color: AppColors.primary.withValues(alpha: 0.6)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: typeCtrl,
                    style: const TextStyle(fontSize: 14, color: AppColors.primary),
                    decoration: InputDecoration(
                      labelText: 'Business Type *',
                      labelStyle: TextStyle(color: AppColors.primary.withValues(alpha: 0.6)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: regCtrl,
                    style: const TextStyle(fontSize: 14, color: AppColors.primary),
                    decoration: InputDecoration(
                      labelText: 'Company Registration Number',
                      labelStyle: TextStyle(color: AppColors.primary.withValues(alpha: 0.6)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addrCtrl,
                    style: const TextStyle(fontSize: 14, color: AppColors.primary),
                    decoration: InputDecoration(
                      labelText: 'Business Address',
                      labelStyle: TextStyle(color: AppColors.primary.withValues(alpha: 0.6)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: webCtrl,
                    style: const TextStyle(fontSize: 14, color: AppColors.primary),
                    decoration: InputDecoration(
                      labelText: 'Website Link',
                      labelStyle: TextStyle(color: AppColors.primary.withValues(alpha: 0.6)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: TextEditingController(text: email),
                    readOnly: true,
                    style: TextStyle(fontSize: 14, color: AppColors.primary.withValues(alpha: 0.5)),
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      labelStyle: TextStyle(color: AppColors.primary.withValues(alpha: 0.6)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      helperText: 'Email address cannot be changed.',
                      helperStyle: const TextStyle(color: Colors.black38, fontSize: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(fontSize: 14, color: AppColors.primary),
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      labelStyle: TextStyle(color: AppColors.primary.withValues(alpha: 0.6)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (nameCtrl.text.trim().isEmpty) {
                              CustomSnackBar.show(
                                context,
                                message: 'Business Name is required.',
                                type: SnackBarType.error,
                              );
                              return;
                            }
                            setModalState(() {
                              isSaving = true;
                            });
                            
                            debugPrint('[MerchantProfileEdit] Save transaction started from bottom sheet.');
                            bool uploadSuccess = true;
                            if (localLogoPath != null) {
                              debugPrint('[MerchantProfileEdit] Uploading local logo file to server: $localLogoPath');
                              final uploadRes = await ApiService.uploadMerchantLogo(localLogoPath!);
                              if (uploadRes['success'] != true) {
                                uploadSuccess = false;
                                debugPrint('[MerchantProfileEdit] Logo upload failed: ${uploadRes['message']}');
                                if (ctx.mounted) {
                                  CustomSnackBar.show(
                                    ctx,
                                    message: uploadRes['message'] ?? 'Logo upload failed',
                                    type: SnackBarType.error,
                                  );
                                }
                              } else {
                                debugPrint('[MerchantProfileEdit] Logo uploaded successfully.');
                              }
                            }

                            if (uploadSuccess) {
                              debugPrint('[MerchantProfileEdit] Updating business details: name="${nameCtrl.text.trim()}", type="${typeCtrl.text.trim()}"');
                              final res = await ApiService.updateMerchantMe({
                                'business_name': nameCtrl.text.trim(),
                                'business_type': typeCtrl.text.trim(),
                                'business_registration': regCtrl.text.trim(),
                                'business_address': addrCtrl.text.trim(),
                                'website_link': webCtrl.text.trim(),
                                'phone': phoneCtrl.text.trim(),
                              });
                              if (res['success'] == true) {
                                debugPrint('[MerchantProfileEdit] Business details saved successfully.');
                                if (mounted) {
                                  setState(() {
                                    _merchantBusinessName = nameCtrl.text.trim();
                                    _merchantBusinessType = typeCtrl.text.trim();
                                    _merchantRegNumber = regCtrl.text.trim();
                                    _merchantAddress = addrCtrl.text.trim();
                                    _merchantWebsite = webCtrl.text.trim();
                                    _merchantPhone = phoneCtrl.text.trim();
                                    _localLogoPath = localLogoPath;
                                  });
                                  _fetchDynamicData();
                                }
                                if (ctx.mounted) {
                                  Navigator.of(ctx).pop(); // Close sheet
                                  CustomSnackBar.show(
                                    context,
                                    message: 'Merchant profile updated!',
                                    type: SnackBarType.success,
                                  );
                                }
                              } else {
                                debugPrint('[MerchantProfileEdit] Business details update failed: ${res['message']}');
                                if (ctx.mounted) {
                                  CustomSnackBar.show(
                                    ctx,
                                    message: res['message'] ?? 'Update failed',
                                    type: SnackBarType.error,
                                  );
                                }
                              }
                            }
                            if (mounted) {
                              setModalState(() {
                                isSaving = false;
                              });
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFBBD03),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : const Text('Save Changes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showImageSourceActionSheet(BuildContext context, bool isMerchant, {void Function(String)? onImagePicked}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Select Image Source',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary, fontFamily: 'Recoleta Alt'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                title: const Text('Camera', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  if (onImagePicked != null) {
                    final XFile? picked = await _picker.pickImage(source: ImageSource.camera);
                    if (picked != null) {
                      onImagePicked(picked.path);
                    }
                  } else {
                    _pickAndUploadImage(ImageSource.camera, isMerchant);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: const Text('Gallery', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  if (onImagePicked != null) {
                    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
                    if (picked != null) {
                      onImagePicked(picked.path);
                    }
                  } else {
                    _pickAndUploadImage(ImageSource.gallery, isMerchant);
                  }
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadImage(ImageSource source, bool isMerchant) async {
    try {
      final XFile? picked = await _picker.pickImage(source: source);
      if (picked == null) return;

      setState(() {
        _isUploadingLogo = true;
      });

      final res = isMerchant 
          ? await ApiService.uploadMerchantLogo(picked.path)
          : await ApiService.uploadUserAvatar(picked.path);

      setState(() {
        _isUploadingLogo = false;
      });

      if (!mounted) return;

      if (res['success'] == true) {
        _fetchDynamicData();
        CustomSnackBar.show(
          context,
          message: 'Logo updated successfully!',
          type: SnackBarType.success,
        );
      } else {
        CustomSnackBar.show(
          context,
          message: res['message'] ?? 'Upload failed',
          type: SnackBarType.error,
        );
      }
    } catch (e) {
      setState(() {
        _isUploadingLogo = false;
      });
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'Failed to upload: $e',
          type: SnackBarType.error,
        );
      }
    }
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
                onTap: () async {
                  final added = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (context) => AddPackageScreen(
                        onPackageAdded: (pkg) {
                          setState(() {
                            _merchantPackages.add(pkg);
                          });
                        },
                      ),
                    ),
                  );
                  if (added == true) {
                    setState(() {});
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

  Widget _buildPackagesTab() {
    final list = _filteredPackages;
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
                    icon: const Icon(Icons.notifications_none_rounded, color: AppColors.primary, size: 24),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentIndex = 4; // Go to profile
                      });
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12), width: 1.5),
                      ),
                      child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: TextField(
            controller: _searchController,
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
            style: const TextStyle(fontSize: 14, color: AppColors.primary),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: 'Search packages...',
              hintStyle: TextStyle(color: AppColors.primary.withValues(alpha: 0.4), fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
              suffixIcon: _searchQuery.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                      child: const Icon(Icons.cancel_rounded, color: AppColors.primary, size: 20),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Filters dropdown Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: [
              // Date
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    _showFilterSheet<String>(
                      title: 'Select Date Range',
                      options: ['All time', 'This Week', 'This Month'],
                      selectedValue: _selectedDateFilter,
                      labelMapper: (val) => val,
                      onSelected: (val) {
                        setState(() {
                          _selectedDateFilter = val;
                        });
                      },
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Date ($_selectedDateFilter)',
                            style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500),
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
              // Status
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    _showFilterSheet<String>(
                      title: 'Select Package Status',
                      options: ['All', 'Published', 'Pending'],
                      selectedValue: _selectedPill,
                      labelMapper: (val) => val,
                      onSelected: (val) {
                        setState(() {
                          _selectedPill = val;
                        });
                      },
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_list_rounded, size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Status ($_selectedPill)',
                            style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500),
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
              // Sort Icon button
              GestureDetector(
                onTap: () {
                  _showFilterSheet<String>(
                    title: 'Sort Packages By',
                    options: ['Newest', 'Price: Low to High', 'Price: High to Low'],
                    selectedValue: _selectedSortOrder,
                    labelMapper: (val) => val,
                    onSelected: (val) {
                      setState(() {
                        _selectedSortOrder = val;
                      });
                    },
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _selectedSortOrder == 'Newest' ? Colors.white : AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
                  ),
                  child: Icon(
                    Icons.swap_vert_rounded,
                    size: 18,
                    color: _selectedSortOrder == 'Newest' ? AppColors.primary : Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Pill Tabs (All, Published, Pending)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: [
              _buildPillTab('All', _merchantPackages.length),
              const SizedBox(width: 8),
              _buildPillTab('Published', _merchantPackages.where((p) => p['status'] == 'PUBLISHED').length),
              const SizedBox(width: 8),
              _buildPillTab('Pending', _merchantPackages.where((p) => p['status'] == 'PENDING').length),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Section Title: My Packages
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            'My Packages',
            style: TextStyle(
              fontFamily: 'Recoleta Alt',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Packages List
        Expanded(
          child: list.isEmpty
              ? const Center(
                  child: Text(
                    'No packages found',
                    style: TextStyle(color: Colors.black38),
                  ),
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final pkg = list[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.04)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Badges top row
                            Row(
                              children: [
                                Builder(builder: (_) {
                                  final st = (pkg['status'] as String? ?? '').toUpperCase();
                                  final Color bg = st == 'PUBLISHED'
                                      ? const Color(0xFFE8F5E9)
                                      : st == 'PENDING'
                                          ? const Color(0xFFFFF8E1)
                                          : const Color(0xFFF5F5F5);
                                  final Color fg = st == 'PUBLISHED'
                                      ? Colors.green
                                      : st == 'PENDING'
                                          ? Colors.orange
                                          : Colors.black45;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
                                    child: Text(st, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: fg)),
                                  );
                                }),
                                if (pkg['badge'] != null) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: pkg['badge'] == 'SOLD' ? const Color(0xFFF3E5F5) : const Color(0xFFE0F2F1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      pkg['badge'] as String,
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: pkg['badge'] == 'SOLD' ? Colors.purple : Colors.teal,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Title & Subtitle + Thumbnail image Row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        pkg['title'] as String,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        pkg['category'] as String,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.black38,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                 ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: (pkg['image'] as String).startsWith('http')
                                      ? Image.network(
                                          pkg['image'] as String,
                                          width: 52,
                                          height: 52,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            width: 52,
                                            height: 52,
                                            color: AppColors.primary.withValues(alpha: 0.05),
                                            child: const Icon(Icons.image, color: AppColors.primary, size: 20),
                                          ),
                                        )
                                      : Container(
                                          width: 52,
                                          height: 52,
                                          color: AppColors.primary.withValues(alpha: 0.05),
                                          child: const Icon(Icons.image, color: AppColors.primary, size: 20),
                                        ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Divider
                            Divider(color: AppColors.primary.withValues(alpha: 0.06), height: 1),
                            const SizedBox(height: 12),

                            // Price & Action Buttons Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    const Text(
                                      'SGD ',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    Text(
                                      pkg['price'] as String,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    // Eye
                                    _buildActionButton(
                                      icon: Icons.visibility_outlined,
                                      bgColor: Colors.black.withValues(alpha: 0.03),
                                      iconColor: AppColors.primary,
                                      onTap: () {
                                        _viewPackage(pkg);
                                      },
                                    ),
                                    if (pkg['is_owner'] == true) ...[
                                      const SizedBox(width: 8),
                                      // Edit
                                      _buildActionButton(
                                        icon: Icons.edit_outlined,
                                        bgColor: Colors.black.withValues(alpha: 0.03),
                                        iconColor: AppColors.primary,
                                        onTap: () {
                                          _editPackage(pkg);
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      // Delete
                                      _buildActionButton(
                                        icon: Icons.delete_outline_rounded,
                                        bgColor: const Color(0xFFFFEBEE),
                                        iconColor: Colors.red,
                                        onTap: () {
                                          _showDeleteConfirmation(pkg);
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPillTab(String label, int count) {
    final isSelected = _selectedPill == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPill = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1F2E4E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF1F2E4E) : const Color(0xFF1F2E4E).withValues(alpha: 0.15),
          ),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF1F2E4E),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
    );
  }

  // Edit package flow
  void _editPackage(Map<String, dynamic> pkg) async {
    debugPrint('[DEBUG] _editPackage triggered. Payload from list: $pkg');
    final localContext = context;
    showDialog(
      context: localContext,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
      ),
    );

    final packageId = pkg['id'] is int ? pkg['id'] : int.tryParse(pkg['id']?.toString() ?? '');
    debugPrint('[DEBUG] _editPackage packageId: $packageId');
    if (packageId == null) {
      debugPrint('[DEBUG] _editPackage failed: packageId is null');
      Navigator.of(localContext).pop();
      CustomSnackBar.show(localContext, message: 'Invalid package ID.', type: SnackBarType.error);
      return;
    }

    final res = await ApiService.getPackageById(packageId);
    debugPrint('[DEBUG] ApiService.getPackageById response: $res');
    if (!localContext.mounted) {
      debugPrint('[DEBUG] _editPackage context not mounted after fetching package.');
      return;
    }
    Navigator.of(localContext).pop(); // dismiss loading spinner

    if (res['success'] == true && res['data'] != null) {
      final fullPkg = res['data'] as Map<String, dynamic>;
      debugPrint('[DEBUG] Navigating to AddPackageScreen with packageToEdit: $fullPkg');
      
      final result = await Navigator.push(
        localContext,
        MaterialPageRoute(
          builder: (context) => AddPackageScreen(
            packageToEdit: fullPkg,
            onPackageUpdated: (updatedPkg) {
              debugPrint('[DEBUG] AddPackageScreen onPackageUpdated callback triggered with: $updatedPkg');
              setState(() {
                final index = _merchantPackages.indexWhere((p) => p['id'] == updatedPkg['id']);
                if (index != -1) {
                  _merchantPackages[index] = updatedPkg;
                  debugPrint('[DEBUG] Local list package updated at index: $index');
                } else {
                  debugPrint('[DEBUG] Warning: package ID ${updatedPkg['id']} not found in local _merchantPackages list');
                }
              });
            },
          ),
        ),
      );
      debugPrint('[DEBUG] Returned from AddPackageScreen. Navigation result: $result');

      if (result == true) {
        debugPrint('[DEBUG] Refreshing package list via _fetchMerchantPackages()');
        _fetchMerchantPackages();
      }
    } else {
      debugPrint('[DEBUG] _editPackage error: Failed to fetch package details. API message: ${res['message']}');
      CustomSnackBar.show(
        localContext,
        message: res['message'] ?? 'Failed to load package details for editing.',
        type: SnackBarType.error,
      );
    }
  }

  // View package details flow
  void _viewPackage(Map<String, dynamic> pkg) async {
    debugPrint('[DEBUG] _viewPackage triggered. Payload from list: $pkg');
    final localContext = context;
    showDialog(
      context: localContext,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
      ),
    );

    final packageId = pkg['id'] is int ? pkg['id'] : int.tryParse(pkg['id']?.toString() ?? '');
    debugPrint('[DEBUG] _viewPackage packageId: $packageId');
    if (packageId == null) {
      debugPrint('[DEBUG] _viewPackage failed: packageId is null');
      Navigator.of(localContext).pop();
      CustomSnackBar.show(localContext, message: 'Invalid package ID.', type: SnackBarType.error);
      return;
    }

    final res = await ApiService.getPackageById(packageId);
    debugPrint('[DEBUG] _viewPackage ApiService.getPackageById response: $res');
    if (!localContext.mounted) {
      debugPrint('[DEBUG] _viewPackage context not mounted after fetching package.');
      return;
    }
    Navigator.of(localContext).pop(); // dismiss loading spinner

    if (res['success'] == true && res['data'] != null) {
      final fullPkg = res['data'] as Map<String, dynamic>;
      debugPrint('[DEBUG] Showing PackageDetailsDialog with fullPkg: $fullPkg');
      _showPackageDetailsDialog(fullPkg);
    } else {
      debugPrint('[DEBUG] _viewPackage error: Failed to fetch package details. API message: ${res['message']}');
      CustomSnackBar.show(
        localContext,
        message: res['message'] ?? 'Failed to load package details.',
        type: SnackBarType.error,
      );
    }
  }

  void _showPackageDetailsDialog(Map<String, dynamic> pkg) {
    final title = pkg['title'] ?? 'Package Details';
    final status = (pkg['status']?.toString() ?? 'Published').toUpperCase();
    final price = pkg['resale_price'] ?? pkg['price'] ?? 0.0;
    
    String expiryStr = '—';
    if (pkg['expiry_date'] != null) {
      try {
        final date = DateTime.parse(pkg['expiry_date'].toString());
        expiryStr = '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
      } catch (_) {
        expiryStr = pkg['expiry_date'].toString();
      }
    }

    List<String> categories = [];
    if (pkg['category'] != null) {
      if (pkg['category'] is Map) {
        categories.add(pkg['category']['name']?.toString() ?? '');
      } else {
        categories.add(pkg['category'].toString());
      }
    }
    if (pkg['secondary_category'] != null) {
      if (pkg['secondary_category'] is Map) {
        categories.add(pkg['secondary_category']['name']?.toString() ?? '');
      } else {
        categories.add(pkg['secondary_category'].toString());
      }
    }
    categories.removeWhere((c) => c.isEmpty);
    final categoriesStr = categories.isNotEmpty ? categories.join(', ') : 'General';

    final description = pkg['description'] ?? 'No description provided.';
    final location = _merchantAddress.isNotEmpty ? _merchantAddress : '—';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Recoleta Alt',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.primary),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: status == 'PUBLISHED' ? const Color(0xFFE8F5E9) : const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: status == 'PUBLISHED' ? Colors.green : Colors.amber[800],
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Status',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: status == 'PUBLISHED' ? const Color(0xFFE8F5E9) : const Color(0xFFFFF8E1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: status == 'PUBLISHED' ? Colors.green : Colors.amber[800],
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Price',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'SGD $price',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Availability',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '— → $expiryStr',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Location',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            location,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                const Text(
                  'Categories',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  categoriesStr,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'DESCRIPTION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black38,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  "Need to make changes? Switch to the edit view to update package details.",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        side: const BorderSide(color: Colors.black12),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Close', style: TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                    if (pkg['is_owner'] == true) ...[
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _editPackage(pkg);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFBBD03),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Edit package', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> pkg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Package', style: TextStyle(fontFamily: 'Recoleta Alt')),
        content: Text('Are you sure you want to delete "${pkg['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              // Show a loading spinner
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
                ),
              );
              
              final packageId = pkg['id'] is int ? pkg['id'] : int.tryParse(pkg['id']?.toString() ?? '');
              if (packageId != null) {
                final res = await ApiService.deletePackage(packageId);
                if (!context.mounted) return;
                Navigator.of(context).pop(); // pop loading spinner
                
                if (res['success'] == true) {
                  setState(() {
                    _merchantPackages.removeWhere((p) => p['id'] == pkg['id']);
                  });
                  CustomSnackBar.show(
                    context,
                    message: 'Package deleted successfully',
                    type: SnackBarType.success,
                  );
                } else {
                  CustomSnackBar.show(
                    context,
                    message: res['message'] ?? 'Failed to delete package.',
                    type: SnackBarType.error,
                  );
                }
              } else {
                if (!context.mounted) return;
                Navigator.of(context).pop(); // pop loading spinner
                CustomSnackBar.show(
                  context,
                  message: 'Invalid Package ID.',
                  type: SnackBarType.error,
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
        setState(() => _currentIndex = index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? activeColor : inactiveColor,
            size: 22,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isSelected ? activeColor : inactiveColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet<T>({
    required String title,
    required List<T> options,
    required T selectedValue,
    required String Function(T) labelMapper,
    required ValueChanged<T> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Recoleta Alt',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              ...options.map((opt) {
                final isSelected = opt == selectedValue;
                return GestureDetector(
                  onTap: () {
                    onSelected(opt);
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : Colors.grey.shade100,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          labelMapper(opt),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppColors.primary : Colors.black87,
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}
