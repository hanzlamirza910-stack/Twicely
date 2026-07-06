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

  String _merchantBusinessName = "Rolys";
  String _merchantBusinessType = "Company";
  String _merchantRegNumber = "2324";
  String _merchantAddress = "07 lahore";
  String _merchantWebsite = "-";
  String _merchantEmail = "synvolv3@gmail.com";
  String _merchantPhone = "03030844726";

  @override
  void initState() {
    super.initState();
    _loadMerchantData();
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
      }
    }
  }

  final List<Map<String, dynamic>> _merchantPackages = [
    {
      'id': 1,
      'title': 'rejuran salmon injection',
      'category': 'Biz, For Her, Spa & Massage',
      'price': '800',
      'status': 'PUBLISHED',
      'badge': 'SOLD',
      'image': 'assets/images/package_spa.jpg',
    },
    {
      'id': 2,
      'title': 'Guided "Anger Yoga" + Cold Towel Reset (1 Session)',
      'category': 'Biz, For Her, For Him, General ...',
      'price': '5,000',
      'status': 'PUBLISHED',
      'badge': 'ACTIVE',
      'image': 'assets/images/package_yoga.jpg',
    },
  ];

  List<Map<String, dynamic>> get _filteredPackages {
    return _merchantPackages.where((pkg) {
      final matchesSearch = pkg['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          pkg['category'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      
      if (!matchesSearch) return false;
      
      if (_selectedPill == 'Published') {
        return pkg['status'] == 'PUBLISHED';
      } else if (_selectedPill == 'Pending') {
        return pkg['status'] == 'PENDING';
      }
      
      return true;
    }).toList();
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

  Widget _buildHomeTab() {
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
          const Text(
            'Good Evening, Rolys!',
            style: TextStyle(
              fontFamily: 'Recoleta Alt',
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Sunday, Jun 7, 2026',
            style: TextStyle(
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
                  value: '2',
                  icon: Icons.inventory_2_outlined,
                  isNavy: true,
                ),
              ),
              const SizedBox(width: 14),
              // Card 2: Revenue This Week
              Expanded(
                child: _buildMetricCard(
                  title: 'Revenue This Week',
                  value: '\$0',
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
                  value: '0',
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
                  value: '\$525',
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
          _buildRecentPackageItem(
            title: 'rejuran salmon injection',
            date: 'Mar 05, 2026',
            status: 'PUBLISHED',
          ),
          const SizedBox(height: 12),
          _buildRecentPackageItem(
            title: 'Guided "Anger Yoga" + Cold Towel Reset (1 Session)',
            date: 'Mar 05, 2026',
            status: 'PUBLISHED',
          ),
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
                onPressed: () {},
                child: const Text('View all', style: TextStyle(color: Colors.black45, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildRecentSaleItem(
            title: 'rejuran salmon injection',
            date: 'Mar 05, 2026',
            amount: 'S\$750.00',
          ),
          const SizedBox(height: 12),
          _buildRecentSaleItem(
            title: 'Guided "Anger Yoga" + Cold Towel Reset (1 Session)',
            date: 'Mar 05, 2026',
            amount: 'S\$5,000.00',
          ),
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

  void _showEditProfileBottomSheet() {
    final nameCtrl = TextEditingController(text: _merchantBusinessName);
    final typeCtrl = TextEditingController(text: _merchantBusinessType);
    final regCtrl = TextEditingController(text: _merchantRegNumber);
    final addrCtrl = TextEditingController(text: _merchantAddress);
    final webCtrl = TextEditingController(text: _merchantWebsite);
    final emailCtrl = TextEditingController(text: _merchantEmail);
    final phoneCtrl = TextEditingController(text: _merchantPhone);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFFF8EA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Edit Merchant Profile',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontFamily: 'Recoleta Alt',
                  ),
                ),
                const SizedBox(height: 20),
                _buildEditField('Business Name', nameCtrl),
                _buildEditField('Business Type', typeCtrl),
                _buildEditField('Company Registration Number', regCtrl),
                _buildEditField('Business Address', addrCtrl),
                _buildEditField('Website Link', webCtrl),
                _buildEditField('Email', emailCtrl),
                _buildEditField('Phone', phoneCtrl),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _merchantBusinessName = nameCtrl.text;
                      _merchantBusinessType = typeCtrl.text;
                      _merchantRegNumber = regCtrl.text;
                      _merchantAddress = addrCtrl.text;
                      _merchantWebsite = webCtrl.text;
                      _merchantEmail = emailCtrl.text;
                      _merchantPhone = phoneCtrl.text;
                    });
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile updated successfully')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F2E4E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEditField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: const TextStyle(fontSize: 14, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    final firstLetter = _merchantBusinessName.isNotEmpty ? _merchantBusinessName[0].toUpperCase() : 'M';

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
                    color: const Color(0xFFE5ECFF),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    firstLetter,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E56B3),
                      fontFamily: 'Recoleta Alt',
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 4,
                  child: GestureDetector(
                    onTap: _showEditProfileBottomSheet,
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
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Name and Member Date
          Text(
            _merchantBusinessName,
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
              Icon(Icons.storefront_outlined, size: 14, color: Colors.black38),
              SizedBox(width: 4),
              Text(
                'Merchant Partner since 2026',
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
                  'MERCHANT PARTNER',
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
                      '4.9',
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
            title: 'Business Profile',
            subtitle: 'Edit business details & address',
            icon: Icons.business_outlined,
            onTap: _showEditProfileBottomSheet,
          ),
          const SizedBox(height: 12),
          _buildProfileOption(
            title: 'Wallet',
            subtitle: 'Balance: \$124.58',
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
            subtitle: '2 Active Listings',
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
            subtitle: '14 saved items',
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
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              style: const TextStyle(fontSize: 14, color: AppColors.primary),
              decoration: InputDecoration(
                hintText: 'Search packages...',
                hintStyle: TextStyle(color: AppColors.primary.withValues(alpha: 0.4), fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
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
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
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
                      const Expanded(
                        child: Text(
                          'Date (All time)',
                          style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Status
              Expanded(
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
                      const Expanded(
                        child: Text(
                          'Status (All)',
                          style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Sort Icon button
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
                ),
                child: const Icon(Icons.swap_vert_rounded, size: 18, color: AppColors.primary),
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
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9), // Light green
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    pkg['status'] as String,
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
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
                                  child: Image.asset(
                                    pkg['image'] as String,
                                    width: 52,
                                    height: 52,
                                    fit: BoxFit.cover,
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
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Viewing: ${pkg['title']}')),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    // Edit
                                    _buildActionButton(
                                      icon: Icons.edit_outlined,
                                      bgColor: Colors.black.withValues(alpha: 0.03),
                                      iconColor: AppColors.primary,
                                      onTap: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Edit flow for: ${pkg['title']}')),
                                        );
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
            onPressed: () {
              setState(() {
                _merchantPackages.removeWhere((p) => p['id'] == pkg['id']);
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Package deleted successfully'), backgroundColor: Colors.red),
              );
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
      onTap: () => setState(() => _currentIndex = index),
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
}
