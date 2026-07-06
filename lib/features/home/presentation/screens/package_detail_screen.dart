import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/cart_manager.dart';
import '../../../../core/utils/session_manager.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../chat/presentation/screens/conversations_screen.dart';
import 'shopping_cart_screen.dart';

class PackageDetailScreen extends StatefulWidget {
  final Map<String, dynamic> package;

  const PackageDetailScreen({super.key, required this.package});

  @override
  State<PackageDetailScreen> createState() => _PackageDetailScreenState();
}

class _PackageDetailScreenState extends State<PackageDetailScreen> {
  bool _isFavorited = false;

  @override
  void initState() {
    super.initState();
    _isFavorited = widget.package['hasHeart'] == true;
  }

  bool _checkAuthWithPrompt({required String title, required String message}) {
    if (!SessionManager.isLoggedIn) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            title,
            style: const TextStyle(fontFamily: 'Recoleta Alt', fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.black45)),
            ),
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
                backgroundColor: const Color(0xFFFBBD03),
                foregroundColor: AppColors.primary,
                minimumSize: const Size(0, 40),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Login', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return false;
    }
    return true;
  }

  double _parsePrice(String priceStr) {
    // Remove SGD, S$, $, commas, spaces
    final clean = priceStr.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(clean) ?? 0.0;
  }

  void _handleBuyNow() {
    if (_checkAuthWithPrompt(
      title: 'Login Required',
      message: 'Please login to complete your package purchase.',
    )) {
      CartManager().addItem({
        'imageUrl': widget.package['imageUrl'] ?? widget.package['image'] ?? 'assets/images/package_spa.jpg',
        'title': widget.package['title'] ?? 'Selected Package',
        'subtitle': widget.package['tag'] ?? 'Wellness Class',
        'price': _parsePrice(widget.package['resalePrice'] ?? widget.package['price'] ?? '0.00'),
      });

      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const ShoppingCartScreen()),
      );
    }
  }

  void _handleChat() {
    if (_checkAuthWithPrompt(
      title: 'Login Required',
      message: 'Please login to chat directly with the package seller.',
    )) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const ConversationsScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.package['title'] ?? 'Package details';
    final tag = widget.package['tag'] ?? 'FOR HER • SPA & WELLNESS';
    final originalPrice = widget.package['originalPrice'] ?? 'S\$350.00';
    final resalePrice = widget.package['resalePrice'] ?? widget.package['price'] ?? 'S\$120.00';
    final imageUrl = widget.package['imageUrl'] ?? widget.package['image'] ?? 'assets/images/package_yoga.jpg';
    final discount = widget.package['discountBadge'] ?? widget.package['discount'] ?? '65% OFF';

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Package Details',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontFamily: 'Recoleta Alt',
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ShoppingCartScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Image Card with Tags & Favorites
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    imageUrl,
                    height: 240,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 240,
                      color: AppColors.primary.withValues(alpha: 0.05),
                      child: const Icon(Icons.image_outlined, color: AppColors.primary, size: 52),
                    ),
                  ),
                ),
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'ACTIVE',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ),
                ),
                Positioned(
                  top: 14,
                  right: 14,
                  child: GestureDetector(
                    onTap: () {
                      if (_checkAuthWithPrompt(
                        title: 'Login Required',
                        message: 'Please login to add packages to your wishlist.',
                      )) {
                        setState(() {
                          _isFavorited = !_isFavorited;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_isFavorited ? 'Added to Wishlist' : 'Removed from Wishlist'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isFavorited ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 2. Tags Row
            Text(
              tag.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF27B6E),
              ),
            ),
            const SizedBox(height: 8),

            // 3. Package Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontFamily: 'Recoleta Alt',
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),

            // 4. Validity Row
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  'Valid Until December 24, 2026',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 5. Price Area with original and resale discount
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  resalePrice.startsWith('S') ? resalePrice : 'S\$$resalePrice',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  originalPrice,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primary.withValues(alpha: 0.35),
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF176),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    discount,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 6. Subtitle description
            Text(
              'A premium, highly-demanded lifestyle and wellness package resold directly by its original buyer at a verified discount.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.primary.withValues(alpha: 0.7),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),

            // 7. Icon badges grid (2x2)
            Row(
              children: [
                Expanded(child: _buildBadgeCell(Icons.verified_user_outlined, 'Verified Package')),
                const SizedBox(width: 10),
                Expanded(child: _buildBadgeCell(Icons.storefront_outlined, 'Partner Merchant')),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildBadgeCell(Icons.swap_horiz_rounded, 'Transferable')),
                const SizedBox(width: 10),
                Expanded(child: _buildBadgeCell(Icons.support_agent_rounded, '24 hr Support')),
              ],
            ),
            const SizedBox(height: 24),

            // 8. Merchant Profile Card
            _buildMerchantCard(),
            const SizedBox(height: 24),

            // 9. Package Details Section
            const Text(
              'Package Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontFamily: 'Recoleta Alt',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This resold package allows you to book sessions directly with the merchant provider. Sessions can be booked dynamically within the remaining validity period. Upon checkout, the transfer ownership credentials will be sent to your registered email address automatically.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.primary.withValues(alpha: 0.6),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // 10. Similar Packages Section
            _buildSimilarPackagesSection(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  Widget _buildBadgeCell(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDE8E7), // Soft pink background matching the design
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFFA8352A)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFFA8352A),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMerchantCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Raiyu',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.check, size: 8, color: Colors.green),
                          SizedBox(width: 2),
                          Text('Verified Seller', style: TextStyle(fontSize: 8, color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Viewing seller profile...')),
                    );
                  },
                  child: const Text(
                    'View Profile',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarPackagesSection() {
    final list = [
      {
        'title': 'A Premium Weekend Yoga & Pilates Session',
        'price': 'S\$64.00',
        'image': 'assets/images/package_yoga.jpg',
        'seller': 'Kewy Yi',
      },
      {
        'title': 'Deluxe Spa Retreat Resale Pass',
        'price': 'S\$95.00',
        'image': 'assets/images/package_spa.jpg',
        'seller': 'Spa Guru',
      }
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Similar Packages',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary, fontFamily: 'Recoleta Alt'),
            ),
            Text(
              'See all',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              return Container(
                width: 180,
                margin: const EdgeInsets.only(right: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: Image.asset(item['image']!, fit: BoxFit.cover),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title']!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Seller: ${item['seller']!}',
                            style: const TextStyle(fontSize: 9, color: Colors.black38),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item['price']!,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.primary.withValues(alpha: 0.08), width: 1.2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: SafeArea(
        child: Row(
          children: [
            // Chat Outlined Button
            OutlinedButton.icon(
              onPressed: _handleChat,
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: AppColors.primary),
              label: const Text(
                'Chat',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                minimumSize: const Size(0, 48), // override default theme minimumSize
              ),
            ),
            const SizedBox(width: 14),

            // Buy Now Solid Button
            Expanded(
              child: ElevatedButton(
                onPressed: _handleBuyNow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F2E4E),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  minimumSize: const Size(0, 48), // override default theme minimumSize
                ),
                child: const Text(
                  'Buy Now',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
