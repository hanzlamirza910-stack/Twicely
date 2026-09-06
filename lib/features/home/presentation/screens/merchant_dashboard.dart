import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../chat/presentation/screens/conversations_screen.dart';
import 'add_package_screen.dart';
import 'notifications_screen.dart';
import 'wallet_screen.dart';
import 'my_sales_screen.dart';

import 'wishlist_screen.dart';
import 'payout_screen.dart';
import 'stripe_account_screen.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/session_manager.dart';
import 'home_screen.dart';
import 'edit_merchant_profile_screen.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../../core/widgets/shimmer_effect.dart';


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

  String _merchantBusinessName = "";
  String _merchantBusinessType = "";
  String _merchantRegNumber = "";
  String _merchantAddress = "";
  String _merchantWebsite = "";
  String _merchantEmail = "";
  String _merchantPhone = "";
  String _merchantLogoUrl = "";

  final bool _isUploadingLogo = false;
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
    if (!SessionManager.isBizPlus) {
      _currentIndex = 1; // Default starting tab for Verified Vendor is Package Directory (index 1)
    }
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
        final uId = int.tryParse(user['id']?.toString() ?? '') ?? SessionManager.userId;
        final logo = ApiService.getMerchantLogo(uId, user['logo_url']?.toString() ?? user['logo']?.toString());
        _merchantBusinessName = user['business_name'] as String? ?? 
            user['name'] as String? ?? 
            '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
        _merchantEmail = user['email'] as String? ?? '';
        _merchantPhone = user['phone_number'] as String? ?? user['phone'] as String? ?? '';
        _merchantBusinessType = user['business_type'] as String? ?? '';
        _merchantRegNumber = user['business_registration'] as String? ?? '';
        _merchantAddress = user['business_address'] as String? ?? '';
        _merchantWebsite = user['website_link'] as String? ?? '';
        _merchantLogoUrl = logo.isNotEmpty ? logo : (user['logo'] as String? ?? user['logo_url'] as String? ?? user['avatar_url'] as String? ?? '');
      }
    }
  }

  Map<String, dynamic> _mapApiPackage(Map<String, dynamic> apiPkg) {
    String imageUrl = '';
    if (apiPkg['cover_url'] != null && apiPkg['cover_url'].toString().isNotEmpty) {
      imageUrl = apiPkg['cover_url'].toString();
    } else if (apiPkg['images'] != null && apiPkg['images'] is List && (apiPkg['images'] as List).isNotEmpty) {
      final img0 = (apiPkg['images'] as List)[0];
      if (img0 is Map) {
        imageUrl = img0['url']?.toString() ?? img0['src']?.toString() ?? img0['link']?.toString() ?? '';
      } else if (img0 != null) {
        imageUrl = img0.toString();
      }
    }
    if (imageUrl.isEmpty && apiPkg['image_url'] != null) {
      imageUrl = apiPkg['image_url'].toString();
    }
    if (imageUrl.isEmpty && apiPkg['image'] != null) {
      if (apiPkg['image'] is Map) {
        imageUrl = apiPkg['image']['url']?.toString() ?? apiPkg['image']['src']?.toString() ?? '';
      } else {
        imageUrl = apiPkg['image'].toString();
      }
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
    result['title'] = ApiService.unescapeHtml(apiPkg['title']?.toString() ?? 'Package Listing');
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
        final mId = int.tryParse(mData['id']?.toString() ?? '') ?? 0;
        final logo = ApiService.getMerchantLogo(mId, mData['logo_url']?.toString() ?? mData['logo']?.toString());
        final mTier = mData['merchant_tier']?.toString() ?? mData['tier']?.toString() ?? '';
        if (mTier.isNotEmpty) {
          SessionManager.updateMerchantTier(mTier);
        }
        setState(() {
          _merchantBusinessName = (mData['business_name']?.toString().isNotEmpty == true
                  ? mData['business_name']
                  : (mData['display_name']?.toString().isNotEmpty == true
                      ? mData['display_name']
                      : mData['name']))?.toString() ?? _merchantBusinessName;
          _merchantBusinessType = mData['business_type']?.toString() ?? _merchantBusinessType;
          _merchantRegNumber = mData['business_registration']?.toString() ?? _merchantRegNumber;
          _merchantAddress = mData['business_address']?.toString() ?? _merchantAddress;
          _merchantWebsite = mData['website_link']?.toString() ?? _merchantWebsite;
          _merchantEmail = mData['email']?.toString() ?? _merchantEmail;
          _merchantPhone = (mData['phone_number'] ?? mData['phone'])?.toString() ?? _merchantPhone;
          _merchantLogoUrl = logo.isNotEmpty ? logo : ((mData['logo_url'] ?? mData['logo'] ?? mData['avatar_url'])?.toString() ?? _merchantLogoUrl);
        });
      }

      // 2. Fetch wallet balance directly as dollars
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
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: _buildPageBody(),
          ),
        ),
      ),
      bottomNavigationBar: SizedBox(
        height: 72,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: _buildCustomBottomNavBar(),
          ),
        ),
      ),
    );
  }

  Widget _buildPageBody() {
    switch (_currentIndex) {
      case 0:
        return SessionManager.isBizPlus ? _buildHomeTab() : _buildPackagesTab();
      case 1:
        return _buildPackagesTab();
      case 3:
        return SessionManager.isBizPlus
            ? ConversationsScreen(
                onProfileTap: () {
                  setState(() {
                    _currentIndex = 4; // Go to profile
                  });
                },
              )
            : _buildPackagesTab();
      case 4:
        return _buildProfileTab();
      default:
        return _buildPackagesTab();
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
    final String revenueThisWeek = 'S\$${revNum.toStringAsFixed(2)}';
    
    final totalSold = _merchantStats['total_sold_packages'] ?? _merchantStats['sold_listings'] ?? _merchantOrders.length;
    final String totalSellPackages = totalSold.toString();
    
    final String walletBalance = 'S\$${_walletBalance.toStringAsFixed(2)}';

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
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
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
              // Add Package button — ONLY for Biz+ Merchant who can create packages
              if (SessionManager.isBizPlus) ...[
                const SizedBox(width: 12),
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
              final String priceStr = 'S\$${totalVal.toStringAsFixed(2)}';
              
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

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          
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
                    onTap: _openEditMerchantProfileScreen,
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

          // Badges — dynamic based on merchant_tier + c2c_account_status
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: SessionManager.isBizPlus ? const Color(0xFF6B21A8) : const Color(0xFF1F2E4E),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  SessionManager.isBizPlus ? 'BIZ+ MERCHANT' : 'VERIFIED MERCHANT',
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ),
              if (SessionManager.hasC2CAccess)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF27B6E),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'C2C MEMBER',
                    style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 28),

          // Option cards
          // Only show C2C switch if this merchant also has an active C2C account
          if (SessionManager.hasC2CAccess) ...[  
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
          ],
          // Options for Biz+ Merchant only (Hidden for Verified Merchant with 2 navigation items)
          if (SessionManager.isBizPlus) ...[
            const SizedBox(height: 12),
            _buildProfileOption(
              title: 'Wallet',
              subtitle: 'Balance: S\$${_walletBalance.toStringAsFixed(2)}',
              icon: Icons.account_balance_wallet_outlined,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const WalletScreen(isMerchant: true),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildProfileOption(
              title: 'My Sales',
              subtitle: '${_merchantOrders.length} sale${_merchantOrders.length != 1 ? 's' : ''}',
              icon: Icons.sell_outlined,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const MySalesScreen(isMerchant: true),
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
              title: 'Stripe Account',
              subtitle: 'Manage payment settings & payouts',
              icon: Icons.account_balance_rounded,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const StripeAccountScreen(),
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
                    builder: (context) => const PayoutScreen(isMerchant: true),
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 24),

          // Logout Action button
          OutlinedButton.icon(
            onPressed: () async {
              final navigator = Navigator.of(context);
              await ApiService.logout();
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout, size: 16, color: AppColors.primary),
            label: const Text(
              'Log Out',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
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



  Future<void> _openEditMerchantProfileScreen() async {
    final updated = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditMerchantProfileScreen(
          merchantData: {
            'business_name': _merchantBusinessName,
            'business_type': _merchantBusinessType,
            'business_registration': _merchantRegNumber,
            'business_address': _merchantAddress,
            'website_link': _merchantWebsite,
            'phone_number': _merchantPhone,
            'email': _merchantEmail,
            'logo_url': _merchantLogoUrl,
          },
        ),
      ),
    );
    if (updated == true) {
      _fetchDynamicData();
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
                    if (SessionManager.isBizPlus)
                      Expanded(child: _buildNavBarItem(0, Icons.home_rounded, 'Home')),
                    Expanded(
                      child: _buildNavBarItem(
                        1,
                        Icons.inventory_2_outlined,
                        SessionManager.isBizPlus ? 'Packages' : 'Package Directory',
                      ),
                    ),
                    if (SessionManager.isBizPlus) const SizedBox(width: 64), // Empty space for protruding center button
                    if (SessionManager.isBizPlus)
                      Expanded(child: _buildNavBarItem(3, Icons.chat_bubble_outline_rounded, 'Chat')),
                    Expanded(child: _buildNavBarItem(4, Icons.person_outline_rounded, 'Profile')),
                  ],
                ),
              ),
            ),
          ),
          // Floating Center Button (Only for Biz+ Merchant)
          if (SessionManager.isBizPlus)
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
              _fetchMerchantPackages();
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
                        _fetchMerchantPackages();
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

        // Section Title: My Packages / Package Directory
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                SessionManager.isBizPlus ? 'My Packages' : 'Package Directory',
                style: const TextStyle(
                  fontFamily: 'Recoleta Alt',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              if (!SessionManager.isBizPlus) ...[  
                const SizedBox(height: 2),
                Text(
                  'Available packages listed under your merchant brand (Read-Only).',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Packages List
        Expanded(
          child: _isLoadingPackages
              ? ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: 4,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const ShimmerEffect(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                    ),
                  ),
                )
              : list.isEmpty
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
                    return GestureDetector(
                      onTap: () => _viewPackage(pkg),
                      child: Container(
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
                                        color: Color(0xFF273DB7),
                                      ),
                                    ),
                                    Text(
                                      pkg['price'] as String,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF273DB7),
                                      ),
                                    ),
                                  ],
                                ),
                                if (!SessionManager.isBizPlus)
                                  GestureDetector(
                                    onTap: () => _viewPackage(pkg),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(Icons.remove_red_eye_outlined, size: 16, color: AppColors.primary),
                                          SizedBox(width: 6),
                                          Text(
                                            'View details',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  PopupMenuButton<String>(
                                    icon: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF4F5F7),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
                                      ),
                                      child: const Icon(Icons.more_horiz_rounded, size: 20, color: AppColors.primary),
                                    ),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    elevation: 6,
                                    color: Colors.white,
                                    onSelected: (val) {
                                      if (val == 'view') {
                                        _viewPackage(pkg);
                                      } else if (val == 'edit') {
                                        _editPackage(pkg);
                                      } else if (val == 'set_published') {
                                        _changePackageStatus(pkg, 'published');
                                      } else if (val == 'set_unpublish') {
                                        _changePackageStatus(pkg, 'unpublish');
                                      } else if (val == 'delete') {
                                        _showDeleteConfirmation(pkg);
                                      }
                                    },
                                    itemBuilder: (context) {
                                      final statusStr = (pkg['status'] as String? ?? '').toLowerCase();
                                      final isPublished = statusStr == 'published' || statusStr == 'publish';
                                      final canEdit = _canEditPackage(pkg);
                                      return [
                                        PopupMenuItem(
                                          value: 'view',
                                          child: Row(
                                            children: const [
                                              Icon(Icons.visibility_outlined, size: 16, color: AppColors.primary),
                                              SizedBox(width: 10),
                                              Text('View details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                                            ],
                                          ),
                                        ),
                                        if (canEdit) ...[
                                          PopupMenuItem(
                                            value: 'edit',
                                            child: Row(
                                              children: const [
                                                Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                                                SizedBox(width: 10),
                                                Text('Edit package', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                                              ],
                                            ),
                                          ),
                                          if (!isPublished)
                                            PopupMenuItem(
                                              value: 'set_published',
                                              child: Row(
                                                children: const [
                                                  Icon(Icons.verified_user_outlined, size: 16, color: Color(0xFF16A34A)),
                                                  SizedBox(width: 10),
                                                  Text('Publish package', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF16A34A))),
                                                ],
                                              ),
                                            )
                                          else
                                            PopupMenuItem(
                                              value: 'set_unpublish',
                                              child: Row(
                                                children: const [
                                                  Icon(Icons.remove_circle_outline_rounded, size: 16, color: Color(0xFF6B7280)),
                                                  SizedBox(width: 10),
                                                  Text('Unpublish package', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
                                                ],
                                              ),
                                            ),
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: const [
                                                Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                                                SizedBox(width: 10),
                                                Text('Delete package', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.red)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ];
                                    },
                                  ),
                              ],
                            ),
                          ],
                        ),
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

  bool _canEditPackage(Map<String, dynamic> pkg) {
    if (!SessionManager.isBizPlus) return false;
    if (pkg['is_owner'] == false) return false;
    final st = (pkg['availability_status'] ?? pkg['availabilityStatus'] ?? '').toString().toLowerCase();
    if (st == 'on_redemption' || st == 'on redemption' || st == 'expired') return false;
    return true;
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
    final title = ApiService.unescapeHtml(pkg['title']?.toString() ?? 'Package Details');
    final statusStr = (pkg['status']?.toString() ?? 'Published').toUpperCase();
    final priceVal = pkg['resale_price'] ?? pkg['price'] ?? 0.0;
    
    String expiryStr = '—';
    if (pkg['expiry_date'] != null) {
      try {
        final date = DateTime.parse(pkg['expiry_date'].toString());
        expiryStr = '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
      } catch (_) {
        expiryStr = pkg['expiry_date'].toString();
      }
    }

    final description = pkg['description'] ?? pkg['content'] ?? 'No description provided.';
    final merchantName = _merchantBusinessName.isNotEmpty ? _merchantBusinessName : (pkg['vendor_name']?.toString() ?? pkg['merchant_name']?.toString() ?? '');
    final merchantLogo = _merchantLogoUrl;
    final hasMerchantInfo = merchantName.trim().isNotEmpty;

    // Images
    List<String> images = [];
    if (pkg['cover_url'] != null && pkg['cover_url'].toString().isNotEmpty) {
      images.add(pkg['cover_url'].toString());
    }
    if (pkg['images'] is List) {
      for (var img in (pkg['images'] as List)) {
        String url = '';
        if (img is Map && img['url'] != null) {
          url = img['url'].toString();
        } else if (img is String) {
          url = img;
        }
        if (url.isNotEmpty && !images.contains(url)) images.add(url);
      }
    }
    if (images.isEmpty) images.add('assets/images/package_spa.jpg');

    final statusCol = statusStr == 'PUBLISHED' ? const Color(0xFF16A34A) : const Color(0xFFF59E0B);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.88,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(bottom: BorderSide(color: Colors.black.withValues(alpha: 0.08))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusCol.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusStr,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusCol),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Recoleta Alt',
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.primary, size: 22),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),

            // Modal Body Content (Scrollable)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Interactive Package Image Gallery Carousel (Swipeable + Clickable Thumbnails)
                    _PackageDetailGallery(images: images),
                    const SizedBox(height: 20),

                    // Description Section
                    Row(
                      children: const [
                        Icon(Icons.description_outlined, size: 16, color: Colors.black54),
                        SizedBox(width: 6),
                        Text(
                          'DESCRIPTION',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.black54),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                      ),
                      child: Text(
                        description,
                        style: const TextStyle(fontSize: 13, color: AppColors.primary, height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (hasMerchantInfo) ...[
                      Row(
                        children: const [
                          Icon(Icons.storefront_outlined, size: 16, color: Colors.black54),
                          SizedBox(width: 6),
                          Text(
                            'MERCHANT INFORMATION',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.black54),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                              backgroundImage: merchantLogo.startsWith('http') ? NetworkImage(merchantLogo) : null,
                              child: merchantLogo.isEmpty ? const Icon(Icons.storefront, color: AppColors.primary, size: 20) : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    merchantName,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _merchantAddress.isNotEmpty ? _merchantAddress : 'Verified Merchant',
                                    style: const TextStyle(fontSize: 11, color: Colors.black45, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],



                    // Details Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('CURRENT STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black45, letterSpacing: 0.5)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusCol.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(statusStr, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusCol)),
                          ),
                          const SizedBox(height: 16),

                          const Text('SELLING PRICE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black45, letterSpacing: 0.5)),
                          const SizedBox(height: 4),
                          Text('SGD $priceVal', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary)),
                          const SizedBox(height: 16),

                          const Text('EXPIRY DATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black45, letterSpacing: 0.5)),
                          const SizedBox(height: 4),
                          Text(expiryStr.isNotEmpty ? expiryStr : 'No expiry', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Modal Footer Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.08))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Need to make changes? Switch to the edit view to update package details.',
                    style: TextStyle(fontSize: 10, color: Colors.black45),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              side: const BorderSide(color: Colors.black26, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Close', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                          ),
                        ),
                      ),
                      if (_canEditPackage(pkg)) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                backgroundColor: const Color(0xFFFBBD03),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
                              ),
                              onPressed: () {
                                Navigator.pop(ctx);
                                _editPackage(pkg);
                              },
                              child: const Text('Edit package', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changePackageStatus(Map<String, dynamic> pkg, String newStatus) async {
    if (!SessionManager.isBizPlus) {
      CustomSnackBar.show(context, message: 'Verified merchants have read-only access.', type: SnackBarType.warning);
      return;
    }
    final packageId = pkg['id'] is int ? pkg['id'] : int.tryParse(pkg['id']?.toString() ?? '');
    if (packageId == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
      ),
    );

    final res = await ApiService.updatePackageStatus(packageId, newStatus);
    if (!mounted) return;
    Navigator.of(context).pop();

    if (res['success'] == true) {
      final isPub = newStatus == 'published' || newStatus == 'publish';
      final label = isPub ? 'Published' : 'Unpublished';
      CustomSnackBar.show(
        context,
        message: 'Package status updated to ${label.toUpperCase()}',
        type: SnackBarType.success,
      );
      setState(() {
        pkg['status'] = isPub ? 'PUBLISHED' : 'UNPUBLISH';
      });
      _fetchMerchantPackages();
    } else {
      final msg = res['message'] ?? 'Failed to update package status.';
      CustomSnackBar.show(
        context,
        message: msg,
        type: SnackBarType.error,
      );
    }
  }

  void _showDeleteConfirmation(Map<String, dynamic> pkg) {
    if (!SessionManager.isBizPlus) {
      CustomSnackBar.show(context, message: 'Verified merchants have read-only access.', type: SnackBarType.warning);
      return;
    }
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

class _PackageDetailGallery extends StatefulWidget {
  final List<String> images;

  const _PackageDetailGallery({required this.images});

  @override
  State<_PackageDetailGallery> createState() => _PackageDetailGalleryState();
}

class _PackageDetailGalleryState extends State<_PackageDetailGallery> {
  late final PageController _pageController;
  int _activePage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imgs = widget.images.where((i) => i.trim().isNotEmpty).toList();
    if (imgs.isEmpty) {
      imgs.add('assets/images/package_spa.jpg');
    }

    Widget buildSingleImage(String url) {
      if (url.startsWith('http')) {
        return Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: const Color(0xFFE8EFF8),
            child: const Icon(Icons.image_not_supported_rounded, color: Colors.black26, size: 32),
          ),
        );
      } else {
        return Image.asset(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: const Color(0xFFE8EFF8),
            child: const Icon(Icons.image_not_supported_rounded, color: Colors.black26, size: 32),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Image Slider (PageView)
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 210,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: imgs.length,
                  onPageChanged: (idx) {
                    setState(() => _activePage = idx);
                  },
                  itemBuilder: (context, idx) => buildSingleImage(imgs[idx]),
                ),

                // Counter Badge (Top Right e.g. 1/3)
                if (imgs.length > 1)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_activePage + 1}/${imgs.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // Dots indicator (Bottom Center)
                if (imgs.length > 1)
                  Positioned(
                    bottom: 10,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(imgs.length, (idx) {
                        final isSelected = idx == _activePage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          height: 6,
                          width: isSelected ? 16 : 6,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Clickable Thumbnails Row
        if (imgs.length > 1) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: imgs.length,
              itemBuilder: (context, idx) {
                final isSelected = idx == _activePage;
                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      idx,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 10),
                    width: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.black.withValues(alpha: 0.12),
                        width: isSelected ? 2.5 : 1.0,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          buildSingleImage(imgs[idx]),
                          if (!isSelected)
                            Container(
                              color: Colors.black.withValues(alpha: 0.25),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

