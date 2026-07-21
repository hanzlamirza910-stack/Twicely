import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/cart_manager.dart';
import '../../../../core/widgets/package_image_carousel.dart';
import 'shopping_cart_screen.dart';
import 'package_detail_screen.dart';
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

    final List<String> allImages = [];
    if (apiPkg['images'] != null && (apiPkg['images'] as List).isNotEmpty) {
      for (var img in apiPkg['images'] as List) {
        if (img is Map && img['url'] != null && img['url'].toString().isNotEmpty) {
          allImages.add(img['url'].toString());
        } else if (img is String && img.isNotEmpty) {
          allImages.add(img);
        }
      }
    }
    if (allImages.isEmpty && imageUrl.isNotEmpty) {
      allImages.add(imageUrl);
    }

    final double priceVal = (apiPkg['price'] is num)
        ? (apiPkg['price'] as num).toDouble()
        : double.tryParse(apiPkg['price']?.toString() ?? '') ?? 0.0;

    final double original = double.tryParse(apiPkg['original_purchase_price']?.toString() ?? '') ??
                            double.tryParse(apiPkg['original_price']?.toString() ?? '') ??
                            priceVal;
    final double resale = double.tryParse(apiPkg['resale_price']?.toString() ?? '') ??
                          double.tryParse(apiPkg['discounted_price']?.toString() ?? '') ??
                          priceVal;

    String? discountBadge;
    if (original > 0 && resale < original) {
      final pct = ((original - resale) / original * 100).round();
      if (pct > 0) discountBadge = '$pct% OFF';
    }

    String category = 'General';
    if (apiPkg['category'] != null) {
      if (apiPkg['category'] is Map) {
        category = apiPkg['category']['name']?.toString() ?? 'General';
      } else {
        category = apiPkg['category'].toString();
      }
    }

    final colors = _getCategoryColors(category);

    final merchantIdVal = int.tryParse(apiPkg['merchant_id']?.toString() ?? '');
    String merchantName = 'Twicely Merchant';
    String merchantLogo = '';
    if (merchantIdVal != null && ApiService.merchantsCache.containsKey(merchantIdVal)) {
      final m = ApiService.merchantsCache[merchantIdVal]!;
      merchantName = m['business_name']?.toString() ?? 'Twicely Merchant';
      merchantLogo = ApiService.getMerchantLogo(merchantIdVal, m['logo_url']?.toString());
    } else if (apiPkg['merchant'] is Map && apiPkg['merchant']['name'] != null) {
      merchantName = apiPkg['merchant']['name'].toString();
      merchantLogo = ApiService.getMerchantLogo(merchantIdVal, apiPkg['merchant']['logo']?.toString());
    } else if (apiPkg['merchant_name'] != null) {
      merchantName = apiPkg['merchant_name'].toString();
      merchantLogo = ApiService.getMerchantLogo(merchantIdVal, '');
    }

    // Build the dynamic tag path (e.g. category > subcategory)
    final secondarySlug = apiPkg['secondary_category']?.toString() ?? '';
    final subcatLabel = secondarySlug.isNotEmpty ? secondarySlug.replaceAll('-', ' ') : '';
    final tag = subcatLabel.isNotEmpty ? '$category > $subcatLabel' : category;

    return {
      'id': apiPkg['id']?.toString() ?? '',
      'title': apiPkg['title'] ?? 'Package Listing',
      'category': category,
      'price': priceVal,
      'imageUrl': imageUrl,
      'allImages': allImages,
      'pillColor': colors['bg'],
      'pillTextColor': colors['text'],
      'originalPrice': 'S\$${original.toStringAsFixed(2)}',
      'resalePrice': 'S\$${resale.toStringAsFixed(2)}',
      'originalPriceVal': original,
      'resalePriceVal': resale,
      'discountBadge': discountBadge,
      'hasHeart': true,
      'merchant_id': merchantIdVal,
      'merchantName': merchantName,
      'merchantLogo': merchantLogo,
      'merchant': merchantName,
      'tag': tag,
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
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      shadowColor: Colors.black12,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'Wishlist',
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          fontFamily: 'Recoleta Alt',
          fontSize: 18,
        ),
      ),
      centerTitle: true,
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
              flex: 46,
              child: Stack(
                children: [
                  PackageImageCarousel(
                    images: item['allImages'] != null ? List<String>.from(item['allImages'] as Iterable) : [item['imageUrl'] as String],
                    fallbackImage: 'assets/images/package_spa.jpg',
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => PackageDetailScreen(package: item),
                        ),
                      );
                    },
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
                          color: Colors.red,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Details Section
            Expanded(
              flex: 54,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCategoryRichText(item['tag'] as String? ?? item['category'] as String? ?? 'General'),
                    const SizedBox(height: 3),
                    Text(
                      item['title'] as String,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 12,
                      child: (item['originalPriceVal'] != null &&
                              item['resalePriceVal'] != null &&
                              (item['originalPriceVal'] as double) > (item['resalePriceVal'] as double))
                          ? Text(
                              item['originalPrice'] as String,
                              style: const TextStyle(
                                fontSize: 9,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: Color(0xFF9E9E9E),
                                color: Color(0xFF9E9E9E),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 2),
                    SizedBox(
                      height: 18,
                      child: Text(
                        item['resalePrice'] as String,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF273DB7),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        _buildMerchantAvatar(
                          item['merchantName'] as String? ?? item['merchant'] as String? ?? 'Twicely',
                          item['merchantLogo'] as String? ?? '',
                          radius: 7,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            item['merchantName'] as String? ?? item['merchant'] as String? ?? 'Twicely',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.black.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
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
          fontSize: 9,
          fontWeight: FontWeight.bold,
          fontFamily: 'Recoleta Alt',
        ),
        children: spans,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildMerchantAvatar(String? name, String? logoUrl, {double radius = 12}) {
    final displayName = (name != null && name.trim().isNotEmpty) ? name.trim() : 'Twicely';
    final hasLogo = logoUrl != null && logoUrl.isNotEmpty;
    final initial = displayName[0].toUpperCase();
    const colors = [
      Color(0xFF4A6FA5),
      Color(0xFF3D8B5E),
      Color(0xFF7B5EA7),
      Color(0xFF5B8DB8),
      Color(0xFF8B6E3C),
      Color(0xFF4A7C59),
    ];
    final Color avatarColor = hasLogo
        ? Colors.grey.shade100
        : (displayName.toLowerCase() == 'twicely'
            ? const Color(0xFF273DB7)
            : colors[displayName.hashCode.abs() % colors.length]);
    return CircleAvatar(
      radius: radius,
      backgroundColor: avatarColor,
      backgroundImage: hasLogo ? NetworkImage(logoUrl) : null,
      child: !hasLogo
          ? Text(
              initial,
              style: TextStyle(
                fontSize: radius * 0.9,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            )
          : null,
    );
  }
}
