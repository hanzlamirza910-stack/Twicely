import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'wallet_screen.dart';

class MySalesScreen extends StatefulWidget {
  const MySalesScreen({super.key});

  @override
  State<MySalesScreen> createState() => _MySalesScreenState();
}

class _MySalesScreenState extends State<MySalesScreen> {
  String _selectedStatusDropdown = 'All Statuses';
  String _selectedPill = 'All';

  // Mock Sales Data matching the mockup exactly
  final List<Map<String, dynamic>> _salesItems = [
    {
      'id': '1',
      'title': 'Weekend Serenity Set',
      'category': 'Wellness & Spa',
      'price': 85.00,
      'status': 'PENDING',
      'imageUrl': 'assets/images/package_spa.jpg',
      'isSold': false,
    },
    {
      'id': '2',
      'title': 'Globetrotter Essentials',
      'category': 'Travel & Accessories',
      'price': 120.00,
      'status': 'COMPLETED',
      'imageUrl': 'assets/images/package_gym.jpg',
      'isSold': true,
    },
    {
      'id': '3',
      'title': 'Artisan Date Night',
      'category': 'Dining & Experience',
      'price': 145.00,
      'status': 'LIVE',
      'imageUrl': 'assets/images/package_yoga.jpg',
      'isSold': false,
    },
    {
      'id': '4',
      'title': 'Minimal Tech Bundle',
      'category': 'Work & Productivity',
      'price': 210.00,
      'status': 'PENDING',
      'imageUrl': 'assets/images/package_gym.jpg',
      'isSold': false,
    },
  ];

  List<Map<String, dynamic>> get _filteredItems {
    return _salesItems.where((item) {
      // 1. Dropdown Filter
      if (_selectedStatusDropdown == 'Pending Only' && item['status'] != 'PENDING') return false;
      if (_selectedStatusDropdown == 'Live Only' && item['status'] != 'LIVE') return false;
      if (_selectedStatusDropdown == 'Completed Only' && item['status'] != 'COMPLETED') return false;

      // 2. Pill Filter
      if (_selectedPill == 'Pending' && item['status'] != 'PENDING') return false;
      if (_selectedPill == 'Sold' && item['status'] != 'COMPLETED') return false; // In mockup, Sold items are completed
      if (_selectedPill == 'Drafts') return false; // 0 drafts in mockup

      return true;
    }).toList();
  }

  void _showItemActions(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: AppColors.bgLight,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              item['title'] as String,
              style: const TextStyle(
                fontFamily: 'Recoleta Alt',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: AppColors.primary),
              title: const Text('Edit Listing', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Edit "${item['title']}" coming soon!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility_outlined, color: AppColors.primary),
              title: const Text('View Details', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('View details for "${item['title']}"')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
              title: const Text('Delete Listing', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.of(context).pop();
                _confirmDelete(item);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Delete Listing?',
          style: TextStyle(fontFamily: 'Recoleta Alt', fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
        content: Text('Are you sure you want to permanently delete "${item['title']}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.black45)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _salesItems.removeWhere((x) => x['id'] == item['id']);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('"${item['title']}" deleted successfully.')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _addNewListing() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      backgroundColor: AppColors.bgLight,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Create New Listing',
                style: TextStyle(
                  fontFamily: 'Recoleta Alt',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Listing Title',
                  labelStyle: const TextStyle(color: AppColors.primary),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary, width: 2)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Category',
                  labelStyle: const TextStyle(color: AppColors.primary),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary, width: 2)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Price (SGD)',
                  labelStyle: const TextStyle(color: AppColors.primary),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary, width: 2)),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _salesItems.insert(0, {
                      'id': DateTime.now().toString(),
                      'title': 'New Wellness Package',
                      'category': 'Spa & Wellness',
                      'price': 99.00,
                      'status': 'PENDING',
                      'imageUrl': 'assets/images/package_spa.jpg',
                      'isSold': false,
                    });
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('New listing submitted successfully and pending approval.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                child: const Text('Submit Listing', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredItems;

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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0), // Floating above the bottom overlay card
        child: FloatingActionButton(
          onPressed: _addNewListing,
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: Colors.white, size: 24),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 10.0, bottom: 200.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title & Description
                const Text(
                  'My Sales',
                  style: TextStyle(
                    fontFamily: 'Recoleta Alt',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Track your package listings and earnings.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),

                // Status Dropdown selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.08)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedStatusDropdown,
                      icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
                      style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedStatusDropdown = newValue;
                          });
                        }
                      },
                      items: <String>['All Statuses', 'Live Only', 'Pending Only', 'Completed Only']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Horizontal pills selector row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildPill('All', 12),
                      const SizedBox(width: 8),
                      _buildPill('Pending', 4),
                      const SizedBox(width: 8),
                      _buildPill('Sold', 8),
                      const SizedBox(width: 8),
                      _buildPill('Drafts', 0),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Sales List
                filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40.0),
                          child: Column(
                            children: [
                              Icon(Icons.sell_outlined, size: 48, color: AppColors.primary.withValues(alpha: 0.2)),
                              const SizedBox(height: 12),
                              Text(
                                'No listings found',
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
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final isSold = item['isSold'] as bool;
                          final status = item['status'] as String;

                          Color tagBgColor;
                          Color tagTextColor;

                          if (status == 'PENDING') {
                            tagBgColor = const Color(0xFFFEF9C3); // light yellow
                            tagTextColor = const Color(0xFF854D0E); // dark yellow
                          } else if (status == 'COMPLETED') {
                            tagBgColor = const Color(0xFFD1FAE5); // light green
                            tagTextColor = const Color(0xFF065F46); // dark green
                          } else {
                            tagBgColor = const Color(0xFFFEE2E2); // light red/pink
                            tagTextColor = const Color(0xFF991B1B); // dark red
                          }

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.04)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.01),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Thumbnail image with possible SOLD overlay
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Container(
                                        width: 72,
                                        height: 72,
                                        color: AppColors.bgLight,
                                        child: Image.asset(
                                          item['imageUrl'] as String,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
                                              const Icon(Icons.image, color: AppColors.primary),
                                        ),
                                      ),
                                    ),
                                    if (isSold)
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.5),
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          alignment: Alignment.center,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            color: Colors.black87,
                                            child: const Text(
                                              'SOLD',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 14),

                                // Title and Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['title'] as String,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item['category'] as String,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.primary.withValues(alpha: 0.5),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Text(
                                            '\$${(item['price'] as double).toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: tagBgColor,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              status,
                                              style: TextStyle(
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                                color: tagTextColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Vertical dots actions
                                IconButton(
                                  icon: const Icon(Icons.more_vert, color: Colors.black38),
                                  onPressed: () => _showItemActions(item),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),

          // Total Earnings Overlay Card (Sticky at bottom)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.bgLight,
                border: Border(top: BorderSide(color: AppColors.primary.withValues(alpha: 0.06), width: 1.5)),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'TOTAL EARNINGS',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.wallet,
                                color: Colors.white.withValues(alpha: 0.4),
                                size: 12,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '\$1,240.50',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'From 8 successful sales this month',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const WalletScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text(
                        'Withdraw to Wallet',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
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

  Widget _buildPill(String title, int count) {
    final isSelected = _selectedPill == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPill = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          '$title ($count)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.primary,
          ),
        ),
      ),
    );
  }
}
