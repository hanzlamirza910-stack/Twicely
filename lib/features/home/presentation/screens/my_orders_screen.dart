import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatusFilter = 'All';

  // Mock Orders Data matching the mockup exactly
  final List<Map<String, dynamic>> _orders = [
    {
      'id': 'TWC-20260226-00028',
      'date': 'Feb 26, 2026',
      'time': '03:49 AM',
      'title': '5 Golf Sessions At Orchid Country Club (Zaman)',
      'seller': 'Muhammad Anwar',
      'price': 800.00,
      'packagesCount': 1,
      'statuses': ['Refunded', 'Cancelled'],
      'icon': Icons.golf_course_rounded,
      'iconBg': Color(0xFFE0F2FE),
      'iconColor': Color(0xFF0369A1),
    },
    {
      'id': 'TWC-20260305-00034',
      'date': 'Mar 5, 2026',
      'time': '12:54 PM',
      'title': 'Rejuran Salmon Injection - Full Face',
      'seller': 'Test Minn',
      'price': 750.00,
      'packagesCount': 1,
      'statuses': ['Paid', 'Redeemed'],
      'icon': Icons.spa_rounded,
      'iconBg': Color(0xFFFCE7F3),
      'iconColor': Color(0xFFBE185D),
    },
    {
      'id': 'TWC-20260305-00033',
      'date': 'Mar 5, 2026',
      'time': '12:46 PM',
      'title': 'Guided "Anger Yoga" + Cold Towel Reset',
      'seller': 'Test Minn',
      'price': 5000.00,
      'packagesCount': 1,
      'statuses': ['Cancelled'],
      'icon': Icons.self_improvement_rounded,
      'iconBg': Color(0xFFFEF9C3),
      'iconColor': Color(0xFFA16207),
    },
  ];

  List<Map<String, dynamic>> get _filteredOrders {
    return _orders.where((order) {
      // 1. Search Query Filter
      final query = _searchQuery.toLowerCase();
      final matchesSearch = order['id'].toString().toLowerCase().contains(query) ||
          order['title'].toString().toLowerCase().contains(query) ||
          order['seller'].toString().toLowerCase().contains(query);

      if (!matchesSearch) return false;

      // 2. Status Filter
      if (_selectedStatusFilter != 'All') {
        final List<String> statuses = List<String>.from(order['statuses']);
        final hasMatchingStatus = statuses.any((status) => status.toLowerCase() == _selectedStatusFilter.toLowerCase());
        if (!hasMatchingStatus) return false;
      }

      return true;
    }).toList();
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: AppColors.bgLight,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Filter Orders by Status',
              style: TextStyle(
                fontFamily: 'Recoleta Alt',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['All', 'Paid', 'Redeemed', 'Refunded', 'Cancelled'].map((status) {
                final isSelected = _selectedStatusFilter == status;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedStatusFilter = status;
                    });
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : AppColors.primary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.receipt_long_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text(
              'Order Receipt',
              style: TextStyle(
                fontFamily: 'Recoleta Alt',
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order ID: #${order['id']}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Placed on ${order['date']} at ${order['time']}',
              style: const TextStyle(color: Colors.black45, fontSize: 12),
            ),
            const Divider(height: 24),
            Text(
              order['title'] as String,
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Seller: ${order['seller']}',
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Quantity', style: TextStyle(color: Colors.black54, fontSize: 13)),
                Text('${order['packagesCount']} Package', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Payment Method', style: TextStyle(color: Colors.black54, fontSize: 13)),
                const Text('Credit Card (Visa)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Amount', style: TextStyle(color: Colors.black54, fontSize: 13)),
                Text('\$${(order['price'] as double).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary, fontSize: 15)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTag(String status) {
    Color bg;
    Color text;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'refunded':
        bg = const Color(0xFFF3F4F6); // Grey
        text = const Color(0xFF4B5563);
        icon = Icons.replay_rounded;
        break;
      case 'cancelled':
        bg = const Color(0xFFFEE2E2); // Red
        text = const Color(0xFFDC2626);
        icon = Icons.cancel_outlined;
        break;
      case 'paid':
        bg = const Color(0xFFDCFCE7); // Green
        text = const Color(0xFF16A34A);
        icon = Icons.check_circle_outline_rounded;
        break;
      case 'redeemed':
        bg = const Color(0xFFDBEAFE); // Blue
        text = const Color(0xFF2563EB);
        icon = Icons.confirmation_number_outlined;
        break;
      default:
        bg = const Color(0xFFF3F4F6);
        text = const Color(0xFF4B5563);
        icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: text),
          const SizedBox(width: 3),
          Text(
            status.toLowerCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: text,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredOrders;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
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
            onPressed: () {},
          ),
          Container(
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
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Header Row
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'John Smith!',
                  style: TextStyle(
                    fontFamily: 'Recoleta Alt',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Saturday, May 23, 2026',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              'My Orders',
              style: TextStyle(
                fontFamily: 'Recoleta Alt',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'View your purchase history',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 16),

            // Search Bar & Filter Row
            Row(
              children: [
                Expanded(
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
                      style: const TextStyle(fontSize: 13, color: AppColors.primary),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search by order, seller, or package...',
                        hintStyle: TextStyle(color: AppColors.primary.withValues(alpha: 0.4), fontSize: 13),
                        prefixIcon: const Icon(Icons.search, color: AppColors.primary, size: 20),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _showFilterOptions,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      color: _selectedStatusFilter != 'All' ? const Color(0xFF3B82F6) : AppColors.primary,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Order History List
            filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40.0),
                      child: Column(
                        children: [
                          Icon(Icons.shopping_bag_outlined, size: 48, color: AppColors.primary.withValues(alpha: 0.2)),
                          const SizedBox(height: 12),
                          Text(
                            'No orders found',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final order = filtered[index];
                      final statuses = List<String>.from(order['statuses']);

                      return GestureDetector(
                        onTap: () => _showOrderDetails(order),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.04)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Order ID and Statuses
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Order #${order['id']}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  Wrap(
                                    spacing: 4,
                                    children: statuses.map((st) => _buildStatusTag(st)).toList(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Date & Time Row
                              Row(
                                children: [
                                  Icon(Icons.calendar_month_outlined, size: 14, color: AppColors.primary.withValues(alpha: 0.4)),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${order['date']}, ${order['time']}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.primary.withValues(alpha: 0.4),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12.0),
                                child: Divider(height: 1, color: Colors.black12),
                              ),

                              // Package Item Details
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: order['iconBg'] as Color,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      order['icon'] as IconData,
                                      color: order['iconColor'] as Color,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          order['title'] as String,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Seller: ${order['seller']}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.primary.withValues(alpha: 0.4),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Footer Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.inbox_outlined, size: 14, color: AppColors.primary.withValues(alpha: 0.4)),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${order['packagesCount']} Package',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.primary.withValues(alpha: 0.4),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '\$${(order['price'] as double).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
