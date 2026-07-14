import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import 'package_detail_screen.dart';

class SellerProfileScreen extends StatefulWidget {
  final int merchantId;
  final String merchantName;
  final String merchantLogo;

  const SellerProfileScreen({
    super.key,
    required this.merchantId,
    required this.merchantName,
    required this.merchantLogo,
  });

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _packages = [];
  String _displayName = '';

  static const Map<String, String> _subcatLabels = {
    'yoga-pilates': 'Yoga & Pilates',
    'spa-massage': 'Spa & Massage',
    'beauty-nails': 'Beauty & Nails',
    'gym-fitness': 'Gym & Fitness',
    'lifestyle-classes': 'Lifestyle Classes',
  };

  @override
  void initState() {
    super.initState();
    _displayName = widget.merchantName;
    _fetchSellerPackages();
  }

  Future<void> _fetchSellerPackages() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final res = await ApiService.getPackages(
      page: 1,
      perPage: 100,
      merchantId: widget.merchantId,
    );

    if (!mounted) return;

    if (res['success'] == true && res['data'] != null) {
      final rawList = res['data'] as List<dynamic>;
      setState(() {
        _packages = rawList.map((p) => _mapPkg(p as Map<String, dynamic>)).toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      CustomSnackBar.show(
        context,
        message: res['message'] ?? 'Failed to load seller packages.',
        type: SnackBarType.error,
      );
    }
  }

  Map<String, dynamic> _mapPkg(Map<String, dynamic> p) {
    String imageUrl = '';
    if (p['cover_url'] != null && p['cover_url'].toString().isNotEmpty) {
      imageUrl = p['cover_url'];
    } else if (p['images'] != null && (p['images'] as List).isNotEmpty) {
      imageUrl = (p['images'] as List)[0]['url']?.toString() ?? '';
    }

    final double basePrice = double.tryParse(p['price']?.toString() ?? '') ?? 0.0;
    final double discPrice = double.tryParse(p['discounted_price']?.toString() ?? '') ?? 0.0;
    final bool hasDiscount = discPrice > 0 && discPrice < basePrice;

    final double originalPrice = basePrice;
    final double resalePrice = hasDiscount ? discPrice : basePrice;

    String? discountBadge;
    if (hasDiscount) {
      final pct = ((originalPrice - resalePrice) / originalPrice * 100).round();
      if (pct > 0) { discountBadge = '$pct% OFF'; }
    }

    final secondarySlug = p['secondary_category']?.toString() ?? '';
    
    // Breadcrumb tag
    String parentCat = 'General';
    if (secondarySlug == 'yoga-pilates' || secondarySlug == 'spa-massage' || secondarySlug == 'beauty-nails') {
      parentCat = 'For Her';
    } else if (secondarySlug == 'gym-fitness') {
      parentCat = 'For Him';
    }
    final tag = '$parentCat > ${_subcatLabels[secondarySlug] ?? secondarySlug.replaceAll('-', ' ')}';

    return {
      'id': p['id'],
      'title': p['title'] ?? 'Package',
      'imageUrl': imageUrl.isNotEmpty ? imageUrl : 'assets/images/package_spa.jpg',
      'originalPrice': 'S\$${originalPrice.toStringAsFixed(2)}',
      'resalePrice': 'S\$${resalePrice.toStringAsFixed(2)}',
      'originalPriceVal': originalPrice,
      'resalePriceVal': resalePrice,
      'discountBadge': discountBadge,
      'tag': tag,
      'merchant': _displayName,
      'merchantLogo': widget.merchantLogo,
      'category': secondarySlug,
      'secondary_category': secondarySlug,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Seller Profile',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontFamily: 'Recoleta Alt',
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchSellerPackages,
        color: AppColors.primary,
        child: Column(
          children: [
            // 1. Seller Profile Card at Top
            _buildProfileHeaderCard(),
            const SizedBox(height: 12),
            // Header for active listings
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Row(
                children: [
                  const Text(
                    'Active Listings',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontFamily: 'Recoleta Alt',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_packages.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // 2. Grid of Listings
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    )
                  : _packages.isEmpty
                      ? _buildEmptyState()
                      : GridView.builder(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.70,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                          ),
                          itemCount: _packages.length,
                          itemBuilder: (context, index) {
                            final item = _packages[index];
                            return _buildPackageItemCard(item);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeaderCard() {
    final avatarText = _displayName.isNotEmpty ? _displayName[0].toUpperCase() : 'S';
    final hasLogo = widget.merchantLogo.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar image or initials
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFD68A84),
              shape: BoxShape.circle,
              image: hasLogo
                  ? DecorationImage(
                      image: NetworkImage(widget.merchantLogo),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            alignment: Alignment.center,
            child: (!hasLogo && widget.merchantId != 14)
                ? Text(
                    avatarText,
                    style: const TextStyle(
                      fontSize: 26,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontFamily: 'Recoleta Alt',
                  ),
                ),
                const SizedBox(height: 6),
                // Badge verified
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, size: 12, color: Color(0xFF2E7D32)),
                      SizedBox(width: 4),
                      Text(
                        'Verified Seller',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Member since April 2026',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black.withValues(alpha: 0.4),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.02),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_offer_outlined,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Active Listings',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This seller does not have any active packages for sale at the moment.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.black.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageItemCard(Map<String, dynamic> item) {
    final double originalPrice = item['originalPriceVal'] ?? 0.0;
    final double resalePrice = item['resalePriceVal'] ?? 0.0;
    final String? discountBadge = item['discountBadge'];
    final bool isDiscounted = originalPrice > resalePrice && resalePrice > 0;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PackageDetailScreen(package: item),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Stack
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: item['imageUrl'].toString().startsWith('assets/')
                        ? Image.asset(item['imageUrl'], fit: BoxFit.cover)
                        : Image.network(
                            item['imageUrl'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: AppColors.primary.withValues(alpha: 0.05),
                              child: const Icon(Icons.image_outlined, color: AppColors.primary, size: 36),
                            ),
                          ),
                  ),
                  if (discountBadge != null)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF27B6E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          discountBadge,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Details
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCategoryRichText(item['tag']?.toString() ?? ''),
                  const SizedBox(height: 6),
                  Text(
                    item['title'] ?? 'Package',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Price row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        item['resalePrice'] ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF273DB7),
                        ),
                      ),
                      if (isDiscounted) ...[
                        const SizedBox(width: 6),
                        Text(
                          item['originalPrice'] ?? '',
                          style: TextStyle(
                            fontSize: 10,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.black.withValues(alpha: 0.4),
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

  Widget _buildCategoryRichText(String tag) {
    final parts = tag.split('>');
    final List<InlineSpan> spans = [];
    for (int i = 0; i < parts.length; i++) {
      final part = parts[i].trim();
      Color textColor = const Color(0xFF111111);
      if (i == 0) {
        textColor = const Color(0xFFFF014E);
      } else if (i < parts.length - 1) {
        textColor = const Color(0xFF0691D7);
      }
      spans.add(TextSpan(text: part, style: TextStyle(color: textColor)));
      if (i < parts.length - 1) {
        spans.add(const TextSpan(text: ' > ', style: TextStyle(color: Color(0xFF111111))));
      }
    }
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          fontFamily: 'Recoleta Alt',
        ),
        children: spans,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
