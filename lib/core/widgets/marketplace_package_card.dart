import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/session_manager.dart';
import 'package_image_carousel.dart';

class MarketplacePackageCard extends StatelessWidget {
  final Map<String, dynamic> package;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;
  final bool isFavorite;
  final double? width;

  const MarketplacePackageCard({
    super.key,
    required this.package,
    this.onTap,
    this.onFavoriteTap,
    this.isFavorite = false,
    this.width,
  });

  double _parsePrice(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    final str = val.toString().replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(str) ?? 0.0;
  }

  String _formatPrice(double val) {
    return 'S\$${val.toStringAsFixed(2)}';
  }

  Widget _buildMerchantAvatar(String? name, String? logoUrl) {
    final displayName = (name != null && name.trim().isNotEmpty) ? name.trim() : 'Twicely';
    final hasLogo = logoUrl != null && logoUrl.isNotEmpty && logoUrl.startsWith('http');
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'T';
    
    const colors = [
      Color(0xFF4A6FA5),
      Color(0xFF3D8B5E),
      Color(0xFF7B5EA7),
      Color(0xFFC06C84),
      Color(0xFFD97706),
      Color(0xFF2563EB),
    ];
    final color = colors[displayName.hashCode.abs() % colors.length];

    return Container(
      width: 15,
      height: 15,
      decoration: BoxDecoration(
        color: hasLogo ? Colors.transparent : color,
        shape: BoxShape.circle,
        image: hasLogo ? DecorationImage(image: NetworkImage(logoUrl), fit: BoxFit.cover) : null,
      ),
      alignment: Alignment.center,
      child: !hasLogo
          ? Text(
              initial,
              style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = ApiService.unescapeHtml(package['title']?.toString() ?? package['name']?.toString() ?? 'Untitled Package');
    
    // Category & Subcategory logic (Line 1)
    final rawTag = package['tag']?.toString() ?? '';
    final cat = ApiService.unescapeHtml(package['primary_category']?.toString() ?? package['category']?.toString() ?? '');
    final subCat = ApiService.unescapeHtml(package['secondary_category']?.toString() ?? package['subcategory']?.toString() ?? package['subcategoryLabel']?.toString() ?? '');
    
    String categoryTag = rawTag;
    if (categoryTag.isEmpty) {
      if (cat.isNotEmpty && subCat.isNotEmpty && cat.toLowerCase() != subCat.toLowerCase()) {
        categoryTag = '$cat > $subCat';
      } else if (cat.isNotEmpty) {
        categoryTag = cat;
      } else if (subCat.isNotEmpty) {
        categoryTag = subCat;
      } else {
        categoryTag = 'General';
      }
    }

    // Pricing
    final double origPrice = _parsePrice(package['original_purchase_price'] ?? package['original_price'] ?? package['originalPriceVal'] ?? package['originalPrice']);
    final double resalePrice = _parsePrice(package['selling_price_per_session'] ?? package['resale_price'] ?? package['price'] ?? package['resalePriceVal'] ?? package['resalePrice']);
    final bool isDiscounted = origPrice > resalePrice && resalePrice > 0;

    String? discountBadge = package['discountBadge']?.toString() ?? package['discount']?.toString();
    if (isDiscounted && (discountBadge == null || discountBadge.isEmpty)) {
      final pct = ((origPrice - resalePrice) / origPrice * 100).round();
      if (pct > 0) discountBadge = '$pct% OFF';
    }

    // Merchant
    final presented = package['presented_by'] is Map ? package['presented_by'] as Map : {};
    final merchantName = ApiService.unescapeHtml(
      package['merchantName']?.toString() ??
      package['merchant']?.toString() ??
      package['vendor_name']?.toString() ??
      package['manual_vendor_name']?.toString() ??
      presented['name']?.toString() ??
      'Twicely',
    );
    final merchantLogo = package['merchantLogo']?.toString() ?? presented['logo']?.toString() ?? presented['avatar']?.toString();



    // Images
    List<String> images = [];
    if (package['cover_url'] != null && package['cover_url'].toString().isNotEmpty) {
      images.add(package['cover_url'].toString());
    }
    if (package['imageUrl'] != null && package['imageUrl'].toString().isNotEmpty) {
      if (!images.contains(package['imageUrl'].toString())) images.add(package['imageUrl'].toString());
    }
    if (package['images'] is List) {
      for (var img in (package['images'] as List)) {
        String url = '';
        if (img is Map && img['url'] != null) url = img['url'].toString();
        else if (img is String) url = img;
        if (url.isNotEmpty && !images.contains(url)) images.add(url);
      }
    }
    if (package['allImages'] is List) {
      for (var img in (package['allImages'] as List)) {
        final s = img.toString();
        if (s.isNotEmpty && !images.contains(s)) images.add(s);
      }
    }
    if (images.isEmpty) images.add('assets/images/package_spa.jpg');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width ?? double.infinity,
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
            // Top Cover Image Stack (Flex 52)
            Expanded(
              flex: 52,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14.5)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PackageImageCarousel(
                      images: images,
                      fallbackImage: 'assets/images/package_spa.jpg',
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(14.5)),
                      onTap: onTap,
                    ),
                    // Discount badge
                    if (isDiscounted && discountBadge != null && discountBadge.isNotEmpty)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF27B6E),
                            borderRadius: BorderRadius.circular(20),
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
            ),

            // Content Metadata Section (Flex 48)
            Expanded(
              flex: 48,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Line 1: Category & Subcategory RichText
                        _buildCategoryRichText(categoryTag),
                        const SizedBox(height: 2),

                        // Line 2 & Line 3: Title (Recoleta Alt Font)
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2E),
                            fontFamily: 'Recoleta Alt',
                            height: 1.2,
                          ),
                        ),

                        // Line 4: Strikethrough Original Purchase Price (if discounted)
                        if (isDiscounted) ...[
                          const SizedBox(height: 2),
                          Text(
                            _formatPrice(origPrice),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 9,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: Color(0xFF9E9E9E),
                              color: Color(0xFF9E9E9E),
                            ),
                          ),
                        ],
                        const SizedBox(height: 2),

                        // Line 5: Selling / Resale Price
                        Text(
                          _formatPrice(resalePrice),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF273DB7),
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),

                    // Line 6: Footer Row (Merchant Avatar, Name, Heart/Likes)
                    Row(
                      children: [
                        _buildMerchantAvatar(merchantName, merchantLogo),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            merchantName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.black.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        const SizedBox(width: 3),
                        StatefulBuilder(
                          builder: (context, setCardState) {
                            final pkgId = int.tryParse(package['id']?.toString() ?? '');
                            final bool isFav = isFavorite ||
                                package['hasHeart'] == true ||
                                package['liked'] == true ||
                                (pkgId != null && ApiService.wishlistIdsCache.contains(pkgId));

                            int currentLikes = int.tryParse(
                                  package['likesCount']?.toString() ??
                                  package['likes_count']?.toString() ??
                                  package['likes']?.toString() ?? '0',
                                ) ?? 0;
                            if (isFav && currentLikes == 0) {
                              currentLikes = 1;
                            }

                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    if (onFavoriteTap != null) {
                                      onFavoriteTap!();
                                      setCardState(() {});
                                      return;
                                    }
                                    if (pkgId == null) return;
                                    if (!SessionManager.isLoggedIn) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Please login to manage your wishlist.')),
                                      );
                                      return;
                                    }

                                    if (isFav) {
                                      ApiService.wishlistIdsCache.remove(pkgId);
                                      package['hasHeart'] = false;
                                      package['liked'] = false;
                                      if (currentLikes > 0) currentLikes--;
                                      package['likesCount'] = currentLikes;
                                      setCardState(() {});
                                      await ApiService.unlikePackage(pkgId);
                                    } else {
                                      ApiService.wishlistIdsCache.add(pkgId);
                                      package['hasHeart'] = true;
                                      package['liked'] = true;
                                      currentLikes++;
                                      package['likesCount'] = currentLikes;
                                      setCardState(() {});
                                      await ApiService.likePackage(pkgId);
                                    }
                                  },
                                  child: Icon(
                                    isFav ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                                    size: 13,
                                    color: isFav ? const Color(0xFFFF014E) : Colors.black38,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '$currentLikes',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.black.withValues(alpha: 0.6),
                                    fontWeight: isFav ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            );
                          },
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
    if (tag.isEmpty) tag = 'General';
    final parts = tag.contains('>') ? tag.split('>') : tag.split('•');
    final List<InlineSpan> spans = [];
    for (int i = 0; i < parts.length; i++) {
      final part = parts[i].trim();
      Color textColor = const Color(0xFF111111);
      if (i == 0) {
        textColor = const Color(0xFFFF014E); // Pink category color
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
          fontSize: 9.5,
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
