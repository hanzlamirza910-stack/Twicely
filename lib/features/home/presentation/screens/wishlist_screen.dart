import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/widgets/package_image_carousel.dart';
import '../../../../core/widgets/shimmer_effect.dart';
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
      if (!mounted) return;
      if (res['success'] == true && res['data'] != null) {
        final List<dynamic> rawItems = res['data'];
        
        // Fetch full package details for each wishlist item in parallel
        final List<Map<String, dynamic>> enrichedItems = await Future.wait(
          rawItems.map((raw) async {
            final Map<String, dynamic> itemMap = Map<String, dynamic>.from(raw as Map);
            final pkgId = int.tryParse(itemMap['package_id']?.toString() ?? itemMap['id']?.toString() ?? '');
            if (pkgId != null) {
              final detailRes = await ApiService.getPackageById(pkgId);
              if (detailRes['success'] == true && detailRes['data'] is Map) {
                final Map<String, dynamic> detail = Map<String, dynamic>.from(detailRes['data'] as Map);
                // Keep liked_at if available
                if (itemMap['liked_at'] != null) {
                  detail['liked_at'] = itemMap['liked_at'];
                }
                return detail;
              }
            }
            return itemMap;
          }),
        );

        await ApiService.prefetchOwners(enrichedItems);
        if (!mounted) return;
        final mapped = enrichedItems.map((p) => _mapApiPackage(p)).toList();
        setState(() {
          _wishlistItems = mapped;
          _isLoading = false;
        });
      } else {
        setState(() {
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
        : (double.tryParse(apiPkg['price']?.toString() ?? '') ??
           double.tryParse(apiPkg['selling_price_per_session']?.toString() ?? '') ??
           double.tryParse(apiPkg['resale_price']?.toString() ?? '') ?? 0.0);

    final double discountVal = double.tryParse(apiPkg['discounted_price']?.toString() ?? '') ?? 0.0;
    
    final double originalVal = double.tryParse(apiPkg['original_purchase_price']?.toString() ?? '') ??
                               double.tryParse(apiPkg['original_price']?.toString() ?? '') ?? 0.0;

    final double resale = (discountVal > 0 && discountVal < priceVal)
        ? discountVal
        : (priceVal > 0 ? priceVal : (originalVal > 0 ? originalVal : 0.0));

    final double original = (originalVal > resale) ? originalVal : resale;

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

    final ownerInfo = ApiService.resolveOwnerInfo(apiPkg);
    final String merchantName = ownerInfo['name'] ?? 'Twicely';
    final String merchantLogo = ownerInfo['avatar'] ?? '';
    final bool isMerchantOwner = ownerInfo['is_merchant'] == true;
    final int? activeMerchantId = ownerInfo['merchant_id'] as int?;
    final int? activeOwnerId = ownerInfo['owner_id'] as int?;

    // Build the dynamic tag path (e.g. category > subcategory)
    final secondarySlug = apiPkg['secondary_category']?.toString() ?? '';
    final subcatLabel = secondarySlug.isNotEmpty ? secondarySlug.replaceAll('-', ' ') : '';
    final tag = subcatLabel.isNotEmpty ? '$category > $subcatLabel' : category;

    final String cleanTitle = ApiService.unescapeHtml(apiPkg['title']?.toString() ?? 'Package Listing');
    final String cleanCategory = ApiService.unescapeHtml(category);
    final String cleanMerchantName = ApiService.unescapeHtml(merchantName);

    return {
      'id': apiPkg['id']?.toString() ?? '',
      'title': cleanTitle,
      'category': cleanCategory,
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
      'liked': true,
      'merchant_id': activeMerchantId,
      'owner_id': activeOwnerId,
      'isMerchantOwner': isMerchantOwner,
      'merchantName': cleanMerchantName,
      'merchantLogo': merchantLogo,
      'merchant': {
        'name': cleanMerchantName,
        'logo': merchantLogo,
        'logo_url': merchantLogo,
      },
      'tag': tag,
      'description': apiPkg['description'] ?? '',
      'validity': apiPkg['validity_date'] ?? apiPkg['valid_until'] ?? '',
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
          ? GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.70,
              ),
              itemCount: 6,
              itemBuilder: (context, index) => const PackageCardSkeleton(),
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(height: 18),

          // Grid of Wishlist Items
          _wishlistItems.isEmpty
              ? _buildEmptyState()
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.70,
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

  double _parsePrice(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
  }

  Widget _buildWishlistItemCard(Map<String, dynamic> item) {
    final title = ApiService.unescapeHtml(item['title']?.toString() ?? 'Package Listing');
    
    // Robust Price Parsing from all possible API response keys
    final double rawVal = _parsePrice(item['resalePriceVal'] ?? item['price'] ?? item['selling_price_per_session'] ?? item['resale_price'] ?? item['price_per_session']);
    final String currency = item['currency']?.toString() ?? 'SGD';
    final String currencySymbol = (currency.toUpperCase() == 'USD') ? '\$' : 'S\$';
    final String resalePriceStr = rawVal > 0 ? '$currencySymbol${rawVal.toStringAsFixed(2)}' : (item['resalePrice']?.toString() ?? '$currencySymbol${rawVal.toStringAsFixed(2)}');
    final imageUrl = item['imageUrl']?.toString() ?? 'assets/images/package_spa.jpg';
    final List<String> allImages = item['allImages'] is List ? List<String>.from(item['allImages'] as Iterable) : [imageUrl];

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PackageDetailScreen(package: item),
          ),
        );
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.08), width: 1.0),
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
            // Image Section matching Website
            Expanded(
              flex: 52,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14.5)),
                child: PackageImageCarousel(
                  images: allImages,
                  fallbackImage: 'assets/images/package_spa.jpg',
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14.5)),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => PackageDetailScreen(package: item),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Content section with Title, Price, Divider, View Button & Trash Icon
            Expanded(
              flex: 48,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2E),
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          resalePriceStr,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF273DB7),
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),

                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Divider(height: 1, color: Colors.black.withValues(alpha: 0.08)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            // Website Yellow View Button
                            Expanded(
                              child: SizedBox(
                                height: 30,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => PackageDetailScreen(package: item),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFBBD03),
                                    foregroundColor: AppColors.primary,
                                    elevation: 0,
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text(
                                    'View',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Website Red Trash Icon Button
                            InkWell(
                              onTap: () => _toggleWishlist(item),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Color(0xFFDC2626),
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
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
}
