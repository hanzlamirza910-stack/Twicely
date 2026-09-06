import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/session_manager.dart';
import 'package_image_carousel.dart';

/// A dedicated package card for Search, Popular, and See All screens.
/// Enforces consistent alignment:
/// Line 1: Category Tag (Category > Subcategory)
/// Line 2 & 3: Title (up to 2 lines max with '...', auto-truncating on small screens to fit)
/// Line 4: Discounted Original Price (or empty placeholder space if not discounted)
/// Line 5: Real Resale Price
/// Line 6: Footer (Merchant Avatar + Name + Heart & Likes)
class SearchPackageCard extends StatelessWidget {
  final Map<String, dynamic> package;
  final VoidCallback? onTap;
  final bool isFavorite;

  const SearchPackageCard({
    super.key,
    required this.package,
    this.onTap,
    this.isFavorite = false,
  });

  double _parsePrice(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    final str = val.toString().replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(str) ?? 0.0;
  }

  String _formatPrice(double val) => 'S\$${val.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final title = ApiService.unescapeHtml(
      package['title']?.toString() ?? package['name']?.toString() ?? 'Untitled Package',
    );

    // Category tag
    final cat = ApiService.unescapeHtml(
      package['primary_category']?.toString() ?? package['category']?.toString() ?? '',
    );
    final subCat = ApiService.unescapeHtml(
      package['secondary_category']?.toString() ??
          package['subcategory']?.toString() ??
          package['subcategoryLabel']?.toString() ??
          '',
    );
    String categoryTag = package['tag']?.toString() ?? '';
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
    final double origPrice = _parsePrice(
      package['original_purchase_price'] ??
          package['original_price'] ??
          package['originalPriceVal'] ??
          package['originalPrice'],
    );
    final double resalePrice = _parsePrice(
      package['selling_price_per_session'] ??
          package['resale_price'] ??
          package['price'] ??
          package['resalePriceVal'] ??
          package['resalePrice'],
    );
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
    final merchantLogo = package['merchantLogo']?.toString() ??
        presented['logo']?.toString() ??
        presented['avatar']?.toString();

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
        if (img is Map && img['url'] != null) {
          url = img['url'].toString();
        } else if (img is String) {
          url = img;
        }
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

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Top Cover Image Section (Flex 50) ──
          Expanded(
            flex: 50,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14.5)),
                  child: PackageImageCarousel(
                    images: images,
                    fallbackImage: 'assets/images/package_spa.jpg',
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14.5)),
                    showThumbnails: false,
                    onTap: onTap,
                  ),
                ),
                // Discount badge
                if (isDiscounted && discountBadge != null && discountBadge.isNotEmpty)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF27B6E),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        discountBadge,
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Content Metadata Section (Flex 50) ──
          Expanded(
            flex: 50,
            child: GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bool isSmallDeviceHeight = constraints.maxHeight > 0 && constraints.maxHeight < 105;
                  final int maxTitleLines = isSmallDeviceHeight ? 1 : 2;

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Line 1: Category & Subcategory Tag
                            _buildCategoryTag(categoryTag),
                            const SizedBox(height: 1),

                            // Line 2 & 3: Title (fixed 30px container height for 100% card alignment)
                            SizedBox(
                              height: isSmallDeviceHeight ? 16.0 : 30.0,
                              child: Text(
                                title,
                                maxLines: maxTitleLines,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A2E),
                                  fontFamily: 'Recoleta Alt',
                                  height: 1.15,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),

                            // Line 4 & 5: Pricing Layout (fixed 14px discount slot for 100% card alignment)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  height: 14.0,
                                  child: isDiscounted
                                      ? Text(
                                          _formatPrice(origPrice),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 9,
                                            decoration: TextDecoration.lineThrough,
                                            decorationColor: Color(0xFF9E9E9E),
                                            color: Color(0xFF9E9E9E),
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                                const SizedBox(height: 1),
                                // Line 5: Real Resale Price
                                Text(
                                  _formatPrice(resalePrice),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF273DB7),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Line 6: Footer row (Merchant Avatar + Name + Heart & Likes)
                        Row(
                          children: [
                            _buildAvatar(merchantName, merchantLogo),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                merchantName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 8.5,
                                  color: Colors.black.withValues(alpha: 0.6),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            const SizedBox(width: 2),
                            StatefulBuilder(
                              builder: (context, setCardState) {
                                final pkgId = int.tryParse(package['id']?.toString() ?? '');
                                final bool isFav = isFavorite ||
                                    package['hasHeart'] == true ||
                                    package['liked'] == true ||
                                    (pkgId != null && ApiService.wishlistIdsCache.contains(pkgId));
                                int likes = int.tryParse(
                                      package['likesCount']?.toString() ??
                                          package['likes_count']?.toString() ??
                                          package['likes']?.toString() ??
                                          '0',
                                    ) ??
                                    0;
                                if (isFav && likes == 0) likes = 1;
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: () async {
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
                                          if (likes > 0) likes--;
                                          package['likesCount'] = likes;
                                        } else {
                                          ApiService.wishlistIdsCache.add(pkgId);
                                          package['hasHeart'] = true;
                                          package['liked'] = true;
                                          likes++;
                                          package['likesCount'] = likes;
                                        }
                                        setCardState(() {});
                                        if (isFav) {
                                          await ApiService.unlikePackage(pkgId);
                                        } else {
                                          await ApiService.likePackage(pkgId);
                                        }
                                      },
                                      child: Icon(
                                        isFav ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                                        size: 12,
                                        color: isFav ? const Color(0xFFFF014E) : Colors.black38,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '$likes',
                                      style: TextStyle(
                                        fontSize: 8.5,
                                        color: Colors.black.withValues(alpha: 0.6),
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
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTag(String tag) {
    if (tag.isEmpty) tag = 'General';
    final parts = tag.contains('>') ? tag.split('>') : tag.split('•');
    final List<InlineSpan> spans = [];
    for (int i = 0; i < parts.length; i++) {
      final part = parts[i].trim();
      Color color = const Color(0xFF111111);
      if (i == 0) {
        color = const Color(0xFFFF014E);
      } else if (i < parts.length - 1) {
        color = const Color(0xFF0691D7);
      }
      spans.add(TextSpan(text: part, style: TextStyle(color: color)));
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

  Widget _buildAvatar(String? name, String? logoUrl) {
    final displayName = (name != null && name.trim().isNotEmpty) ? name.trim() : 'Twicely';
    final hasLogo = logoUrl != null && logoUrl.isNotEmpty && logoUrl.startsWith('http');
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'T';
    const colors = [
      Color(0xFF4A6FA5), Color(0xFF3D8B5E), Color(0xFF7B5EA7),
      Color(0xFFC06C84), Color(0xFFD97706), Color(0xFF2563EB),
    ];
    final color = colors[displayName.hashCode.abs() % colors.length];
    return Container(
      width: 13,
      height: 13,
      decoration: BoxDecoration(
        color: hasLogo ? Colors.transparent : color,
        shape: BoxShape.circle,
        image: hasLogo
            ? DecorationImage(image: NetworkImage(logoUrl), fit: BoxFit.cover)
            : null,
      ),
      alignment: Alignment.center,
      child: !hasLogo
          ? Text(initial,
              style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold))
          : null,
    );
  }
}
