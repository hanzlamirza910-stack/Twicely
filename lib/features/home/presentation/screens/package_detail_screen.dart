import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/cart_manager.dart';
import '../../../../core/utils/session_manager.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../chat/presentation/screens/conversations_screen.dart';
import 'shopping_cart_screen.dart';
import '../../../../core/services/api_service.dart';

class PackageDetailScreen extends StatefulWidget {
  final Map<String, dynamic> package;

  const PackageDetailScreen({super.key, required this.package});

  @override
  State<PackageDetailScreen> createState() => _PackageDetailScreenState();
}

class _PackageDetailScreenState extends State<PackageDetailScreen> {
  bool _isFavorited = false;
  bool _isLoading = false;
  Map<String, dynamic>? _detailedPackage;
  List<Map<String, dynamic>> _similarPackages = [];
  bool _loadingSimilar = false;

  @override
  void initState() {
    super.initState();
    _isFavorited = widget.package['hasHeart'] == true;
    _fetchDetails();
    _fetchSimilar(pkg: widget.package);
  }

  void _fetchDetails() async {
    final rawId = widget.package['id'];
    if (rawId == null) return;
    final intId = rawId is int ? rawId : int.tryParse(rawId.toString());
    if (intId == null) return;
    if (mounted) setState(() => _isLoading = true);
    final res = await ApiService.getPackageById(intId);
    if (res['success'] == true && res['data'] != null) {
      if (mounted) {
        setState(() {
          _detailedPackage = res['data'] as Map<String, dynamic>;
          _isFavorited = _detailedPackage?['liked'] == true || _detailedPackage?['hasHeart'] == true;
          _isLoading = false;
        });
        _fetchSimilar(pkg: _detailedPackage!);
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchSimilar({required Map<String, dynamic> pkg}) async {
    if (!mounted) return;
    setState(() => _loadingSimilar = true);
    final secondaryCat = (pkg['secondary_category'] ?? pkg['subcategorySlug'] ?? '').toString();
    final currentId = pkg['id']?.toString();
    final res = await ApiService.getPackages(
      page: 1,
      perPage: 10,
      category: secondaryCat.isNotEmpty ? secondaryCat : null,
    );
    if (!mounted) return;
    if (res['success'] == true && res['data'] != null) {
      final raw = (res['data'] as List<dynamic>)
          .where((p) => p['id']?.toString() != currentId)
          .take(6)
          .map((p) => _mapSimilarPkg(p as Map<String, dynamic>))
          .toList();
      setState(() {
        _similarPackages = raw;
        _loadingSimilar = false;
      });
    } else {
      if (mounted) setState(() => _loadingSimilar = false);
    }
  }

  Map<String, dynamic> _mapSimilarPkg(Map<String, dynamic> p) {
    String imageUrl = '';
    if (p['cover_url'] != null && p['cover_url'].toString().isNotEmpty) {
      imageUrl = p['cover_url'];
    } else if (p['images'] != null && (p['images'] as List).isNotEmpty) {
      imageUrl = (p['images'] as List)[0]['url']?.toString() ?? '';
    }
    final double original = double.tryParse(p['original_price']?.toString() ?? '') ??
        double.tryParse(p['price']?.toString() ?? '') ?? 0.0;
    final double resale = double.tryParse(p['resale_price']?.toString() ?? '') ??
        double.tryParse(p['discounted_price']?.toString() ?? '') ??
        double.tryParse(p['price']?.toString() ?? '') ?? 0.0;
    String? badge;
    if (original > 0 && resale < original) {
      final pct = ((original - resale) / original * 100).round();
      if (pct > 0) { badge = '$pct% OFF'; }
    }
    String merchant = 'Merchant';
    if (p['merchant'] is Map) {
      merchant = p['merchant']['name']?.toString() ?? merchant;
    } else if (p['merchant_name'] != null) {
      merchant = p['merchant_name'].toString();
    }
    return {
      'id': p['id'],
      'title': p['title'] ?? 'Package',
      'imageUrl': imageUrl.isNotEmpty ? imageUrl : 'assets/images/package_spa.jpg',
      'originalPrice': 'S\$${original.toStringAsFixed(2)}',
      'resalePrice': 'S\$${resale.toStringAsFixed(2)}',
      'discountBadge': badge,
      'hasHeart': p['liked'] == true,
      'tag': (p['secondary_category'] ?? '').toString().replaceAll('-', ' & '),
      'merchant': merchant,
      'category': p['secondary_category'] ?? '',
      'secondary_category': p['secondary_category'] ?? '',
    };
  }

  void _toggleWishlist() async {
    if (!_checkAuthWithPrompt(
      title: 'Login Required',
      message: 'Please login to add packages to your wishlist.',
    )) {
      return;
    }

    final rawId = widget.package['id'];
    if (rawId == null) {
      setState(() {
        _isFavorited = !_isFavorited;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFavorited ? 'Added to Wishlist (Demo)' : 'Removed from Wishlist (Demo)'),
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    final intId = rawId is int ? rawId : int.tryParse(rawId.toString());
    if (intId == null) return;

    setState(() {
      _isFavorited = !_isFavorited;
    });

    final res = _isFavorited
        ? await ApiService.likePackage(intId)
        : await ApiService.unlikePackage(intId);

    if (!mounted) return;

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFavorited ? 'Added to Wishlist' : 'Removed from Wishlist'),
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      setState(() {
        _isFavorited = !_isFavorited;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update wishlist: ${res['message']}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
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

  void _handleBuyNow() async {
    if (_checkAuthWithPrompt(
      title: 'Login Required',
      message: 'Please login to complete your package purchase.',
    )) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
        ),
      );

      final pkgIdVal = _detailedPackage?['id'] ?? widget.package['id'];
      final int packageId = int.tryParse(pkgIdVal?.toString() ?? '') ?? 0;

      final res = await ApiService.addToCart(packageId);

      if (!mounted) return;
      Navigator.of(context).pop(); // pop spinner

      if (res['success'] == true) {
        CartManager().addItem({
          'id': packageId,
          'imageUrl': widget.package['imageUrl'] ?? widget.package['image'] ?? 'assets/images/package_spa.jpg',
          'title': widget.package['title'] ?? 'Selected Package',
          'subtitle': widget.package['tag'] ?? 'Wellness Class',
          'price': _parsePrice(widget.package['resalePrice'] ?? widget.package['price'] ?? '0.00'),
        });

        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const ShoppingCartScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Failed to add item to cart.')),
        );
      }
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
    final pkg = _detailedPackage ?? widget.package;
    final title = pkg['title'] ?? 'Package details';
    final tag = pkg['tag'] ?? 'FOR HER • SPA & WELLNESS';

    final double rawOriginal = double.tryParse(pkg['originalPrice']?.toString().replaceAll(RegExp(r'[^\d.]'), '') ?? '') ?? 
                               double.tryParse(pkg['original_price']?.toString() ?? '') ?? 0.0;
    final double rawResale = double.tryParse(pkg['resalePrice']?.toString().replaceAll(RegExp(r'[^\d.]'), '') ?? '') ?? 
                             double.tryParse(pkg['price']?.toString() ?? '') ?? 0.0;

    final originalPrice = rawOriginal > 0 ? 'S\$${rawOriginal.toStringAsFixed(2)}' : (pkg['originalPrice'] ?? 'S\$350.00');
    final resalePrice = rawResale > 0 ? 'S\$${rawResale.toStringAsFixed(2)}' : (pkg['resalePrice'] ?? pkg['price'] ?? 'S\$120.00');

    String imageUrl = pkg['imageUrl'] ?? pkg['image'] ?? 'assets/images/package_yoga.jpg';
    if (pkg['cover_url'] != null && pkg['cover_url'].toString().isNotEmpty) {
      imageUrl = pkg['cover_url'];
    } else if (pkg['images'] != null && (pkg['images'] as List).isNotEmpty) {
      imageUrl = pkg['images'][0]['url'] ?? imageUrl;
    }

    final discount = pkg['discountBadge'] ?? pkg['discount'] ?? '65% OFF';

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
      body: _isLoading && _detailedPackage == null
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : SingleChildScrollView(
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
                  child: imageUrl.startsWith('assets/')
                      ? Image.asset(
                          imageUrl,
                          height: 240,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Image.network(
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
                    onTap: _toggleWishlist,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Similar Packages You May Like',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary, fontFamily: 'Recoleta Alt'),
        ),
        const SizedBox(height: 4),
        Text(
          'Explore more great deals that match your interests.',
          style: TextStyle(fontSize: 11, color: AppColors.primary.withValues(alpha: 0.45)),
        ),
        const SizedBox(height: 14),
        if (_loadingSimilar)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
            ),
          )
        else if (_similarPackages.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No similar packages found.',
                style: TextStyle(fontSize: 12, color: AppColors.primary.withValues(alpha: 0.4)),
              ),
            ),
          )
        else
          SizedBox(
            height: 215,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _similarPackages.length,
              itemBuilder: (context, index) {
                final item = _similarPackages[index];
                final imgUrl = item['imageUrl'] as String;
                final discount = item['discountBadge'] as String?;
                return GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => PackageDetailScreen(package: item)),
                  ),
                  child: Container(
                    width: 162,
                    margin: const EdgeInsets.only(right: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.05)),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                          child: Stack(
                            children: [
                              SizedBox(
                                height: 108,
                                child: imgUrl.startsWith('http')
                                    ? Image.network(imgUrl, fit: BoxFit.cover, width: double.infinity,
                                        errorBuilder: (_, __, ___) => Container(color: const Color(0xFFE8EFF8), child: const Icon(Icons.image_not_supported_rounded, color: Colors.black26, size: 26)))
                                    : Image.asset(imgUrl, fit: BoxFit.cover, width: double.infinity,
                                        errorBuilder: (_, __, ___) => Container(color: const Color(0xFFE8EFF8), child: const Icon(Icons.image_rounded, color: Colors.black26, size: 26))),
                              ),
                              if (discount != null)
                                Positioned(
                                  top: 8, left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(color: const Color(0xFFF27B6E), borderRadius: BorderRadius.circular(8)),
                                    child: Text(discount, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title'],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary, height: 1.3),
                                ),
                                const Spacer(),
                                Row(
                                  children: [
                                    Icon(Icons.store_rounded, size: 9, color: AppColors.primary.withValues(alpha: 0.4)),
                                    const SizedBox(width: 3),
                                    Expanded(child: Text(item['merchant'], maxLines: 1, overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 9, color: AppColors.primary.withValues(alpha: 0.4)))),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['resalePrice'],
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
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
