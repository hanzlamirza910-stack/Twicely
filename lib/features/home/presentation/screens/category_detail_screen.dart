import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/widgets/package_image_carousel.dart';
import '../../../../core/widgets/shimmer_effect.dart';
import 'package_detail_screen.dart';

class CategoryDetailScreen extends StatefulWidget {
  final String categoryName;
  final String categoryIcon;
  final IconData? categoryIconData;
  final Color? categoryBgColor;
  final Color? categoryIconColor;

  const CategoryDetailScreen({
    super.key,
    required this.categoryName,
    this.categoryIcon = '',
    this.categoryIconData,
    this.categoryBgColor,
    this.categoryIconColor,
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _apiPackages = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCategoryPackages();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategoryPackages() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    final res = await ApiService.getPackages(category: widget.categoryName);
    if (res['success'] == true && res['data'] != null) {
      final List<dynamic> pkgs = res['data'];
      await ApiService.prefetchOwners(pkgs);
      if (mounted) {
        setState(() {
          _apiPackages = pkgs.map((p) => _mapApiPackage(p as Map<String, dynamic>)).toList();
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  static const Map<String, String> _subcatLabels = {
    'yoga-pilates': 'Yoga & Pilates',
    'spa-massage': 'Spa & Massage',
    'beauty-nails': 'Beauty & Nails',
    'gym-fitness': 'Gym & Fitness',
    'lifestyle-classes': 'Lifestyle Classes',
  };

  String _determineFilterCategory(Map<String, dynamic> apiPkg) {
    final title = (apiPkg['title'] ?? '').toString().toLowerCase();
    final description = (apiPkg['description'] ?? '').toString().toLowerCase();
    
    final categoryPart = apiPkg['category'];
    final secondaryPart = apiPkg['secondary_category'];
    String combinedCat = '';
    
    if (categoryPart != null) {
      if (categoryPart is Map) {
        combinedCat += ' ${categoryPart['name']?.toString() ?? ''}';
      } else {
        combinedCat += ' ${categoryPart.toString()}';
      }
    }
    if (secondaryPart != null) {
      combinedCat += ' ${secondaryPart.toString()}';
    }
    
    final catLower = combinedCat.toLowerCase();

    if (title.contains('corporate') || 
        title.contains('team bonding') || 
        title.contains('business') || 
        description.contains('corporate') || 
        catLower.contains('biz') || 
        catLower.contains('corporate')) {
      return 'Biz+';
    }

    if (title.contains('men') || 
        title.contains('him') || 
        title.contains('grooming for men') || 
        description.contains('for men') || 
        description.contains('for him')) {
      return 'For him';
    }

    if (catLower.contains('beauty') || 
        catLower.contains('nails') || 
        catLower.contains('spa') || 
        catLower.contains('massage') || 
        catLower.contains('yoga') || 
        catLower.contains('pilates') || 
        catLower.contains('her') || 
        title.contains('her') || 
        title.contains('women') || 
        title.contains('yoga') || 
        title.contains('pilates') || 
        title.contains('spa') || 
        title.contains('massage') || 
        description.contains('for women') || 
        description.contains('for her')) {
      return 'For her';
    }

    return 'General';
  }

  String _buildDynamicTag(Map<String, dynamic> apiPkg) {
    final List<String> mainCats = [];
    if (apiPkg['categories'] is List) {
      for (final cat in apiPkg['categories']) {
        if (cat is Map) {
          final slug = (cat['slug']?.toString() ?? '').toLowerCase();
          if (slug.contains('her') || slug.contains('women')) {
            if (!mainCats.contains('For Her')) mainCats.add('For Her');
          } else if (slug.contains('him') || slug.contains('men')) {
            if (!mainCats.contains('For Him')) mainCats.add('For Him');
          } else if (slug.contains('biz') || slug.contains('corporate')) {
            if (!mainCats.contains('Biz+')) mainCats.add('Biz+');
          } else if (slug.contains('general')) {
            if (!mainCats.contains('General')) mainCats.add('General');
          }
        }
      }
    }
    
    if (mainCats.isEmpty) {
      mainCats.add(_determineFilterCategory(apiPkg));
    }

    final secondarySlug = apiPkg['secondary_category']?.toString() ?? '';
    String subcatLabel = _subcatLabels[secondarySlug] ?? '';

    if (subcatLabel.isEmpty && apiPkg['categories'] is List) {
      for (final cat in apiPkg['categories']) {
        if (cat is Map) {
          final name = (cat['name']?.toString() ?? '').replaceAll('&amp;', '&');
          final slug = (cat['slug']?.toString() ?? '').toLowerCase();
          if (!slug.contains('her') && !slug.contains('women') &&
              !slug.contains('him') && !slug.contains('men') &&
              !slug.contains('biz') && !slug.contains('corporate') &&
              !slug.contains('general')) {
            subcatLabel = name;
            break;
          }
        }
      }
    }

    if (subcatLabel.isNotEmpty) {
      return '${mainCats.join(' > ')} > $subcatLabel';
    } else {
      return mainCats.join(' > ');
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

    final double basePrice = double.tryParse(apiPkg['price']?.toString() ?? '') ?? 0.0;
    final double discPrice = double.tryParse(apiPkg['discounted_price']?.toString() ?? '') ?? 0.0;
    final bool hasDiscount = discPrice > 0 && discPrice < basePrice;

    final double originalPrice = basePrice;
    final double resalePrice = hasDiscount ? discPrice : basePrice;

    String? discountBadge;
    if (hasDiscount) {
      final discountPct = ((originalPrice - resalePrice) / originalPrice * 100).round();
      if (discountPct > 0) {
        discountBadge = '$discountPct% OFF';
      }
    }

    String category = widget.categoryName;
    if (apiPkg['category'] != null) {
      if (apiPkg['category'] is Map) {
        category = apiPkg['category']['name']?.toString() ?? widget.categoryName;
      } else {
        category = apiPkg['category'].toString();
      }
    }

    String tag = _buildDynamicTag(apiPkg);

    final ownerInfo = ApiService.resolveOwnerInfo(apiPkg);
    final String merchantName = ownerInfo['name'] ?? 'Twicely';
    final String merchantLogo = ownerInfo['avatar'] ?? '';

    final String cleanTitle = ApiService.unescapeHtml(apiPkg['title']?.toString() ?? 'Package Listing');
    final String cleanDescription = ApiService.unescapeHtml(apiPkg['description']?.toString() ?? '');
    final String cleanMerchantName = ApiService.unescapeHtml(merchantName);
    final String cleanCategory = ApiService.unescapeHtml(category);
    final String cleanTag = ApiService.unescapeHtml(tag);

    return {
      'id': apiPkg['id'],
      'imageUrl': imageUrl,
      'image': imageUrl,
      'allImages': allImages,
      'tag': cleanTag,
      'title': cleanTitle,
      'originalPrice': 'S\$${originalPrice.toStringAsFixed(2)}',
      'resalePrice': 'S\$${resalePrice.toStringAsFixed(2)}',
      'originalPriceVal': originalPrice,
      'resalePriceVal': resalePrice,
      'price': 'S\$${resalePrice.toStringAsFixed(2)}',
      'hasHeart': apiPkg['liked'] == true || apiPkg['hasHeart'] == true,
      'discountBadge': discountBadge,
      'discount': discountBadge,
      'category': cleanCategory,
      'description': cleanDescription,
      'validity': apiPkg['validity_date'] ?? apiPkg['valid_until'] ?? '',
      'merchant': {
        'name': cleanMerchantName,
        'logo': merchantLogo,
        'logo_url': merchantLogo,
      },
      'merchantName': cleanMerchantName,
      'merchantLogo': merchantLogo,
      'merchant_id': ownerInfo['merchant_id'],
      'likesCount': apiPkg['likes_count'] ?? apiPkg['likesCount'] ?? (apiPkg['liked'] == true ? 1 : 0),
    };
  }

  List<Map<String, dynamic>> get _displayPackages {
    final baseList = _apiPackages;
    if (_searchQuery.isEmpty) return baseList;
    return baseList.where((pkg) =>
      pkg['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
      pkg['tag'].toString().toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final displayList = _displayPackages;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8EA),
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.categoryName,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontFamily: 'Recoleta Alt',
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchCategoryPackages,
          color: AppColors.primary,
          child: Column(
            children: [
              // Category info header banner
              Container(
                color: const Color(0xFFFFF8EA),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: widget.categoryBgColor ?? Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: widget.categoryIconData != null
                          ? Icon(
                              widget.categoryIconData,
                              color: widget.categoryIconColor ?? AppColors.primary,
                              size: 26,
                            )
                          : (widget.categoryIcon.isNotEmpty
                              ? ClipOval(
                                  child: Image.asset(widget.categoryIcon, fit: BoxFit.contain),
                                )
                              : const Icon(Icons.category_rounded, color: AppColors.primary, size: 26)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Explore ${widget.categoryName}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Verified resale deals from our trusted community.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),

              // Search Bar inside category
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  style: const TextStyle(fontSize: 14, color: AppColors.primary),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Search within ${widget.categoryName}...',
                    hintStyle: TextStyle(color: AppColors.primary.withValues(alpha: 0.4), fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: Color(0xFF273DB7), width: 1.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: Color(0xFF273DB7), width: 1.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: Color(0xFF273DB7), width: 1.5),
                    ),
                  ),
                ),
              ),

              // Deals List
              Expanded(
                child: _isLoading
                    ? ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 4,
                        itemBuilder: (context, index) => Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          height: 120,
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
                          child: Row(
                            children: [
                              const ShimmerEffect(
                                width: 120,
                                height: 120,
                                borderRadius: BorderRadius.horizontal(left: Radius.circular(15)),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: const [
                                      ShimmerEffect(width: 80, height: 10, borderRadius: BorderRadius.all(Radius.circular(4))),
                                      ShimmerEffect(width: 150, height: 14, borderRadius: BorderRadius.all(Radius.circular(4))),
                                      ShimmerEffect(width: 60, height: 14, borderRadius: BorderRadius.all(Radius.circular(4))),
                                      ShimmerEffect(width: 80, height: 10, borderRadius: BorderRadius.all(Radius.circular(4))),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : displayList.isEmpty
                        ? const Center(
                            child: Text(
                              'No packages found.',
                              style: TextStyle(color: Colors.black38, fontSize: 13),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: displayList.length,
                            itemBuilder: (context, index) {
                              final pkg = displayList[index];
                              final String img = pkg['imageUrl'] ?? pkg['image'] ?? 'assets/images/package_spa.jpg';
                              return GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => PackageDetailScreen(package: pkg),
                                    ),
                                  );
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 16),
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
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Package Image
                                        PackageImageCarousel(
                                          images: pkg['allImages'] != null ? List<String>.from(pkg['allImages'] as Iterable) : [img],
                                          fallbackImage: 'assets/images/package_spa.jpg',
                                          width: 90,
                                          height: 90,
                                          borderRadius: BorderRadius.circular(12),
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) => PackageDetailScreen(package: pkg),
                                              ),
                                            );
                                          },
                                        ),
                                        const SizedBox(width: 14),
                                        // Content details
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  _buildCategoryRichText((pkg['tag'] as String)),
                                                  if (pkg['originalPriceVal'] != null && pkg['resalePriceVal'] != null && (pkg['originalPriceVal'] as double) > (pkg['resalePriceVal'] as double) && (pkg['discount'] != null || pkg['discountBadge'] != null))
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFF27B6E),
                                                        borderRadius: BorderRadius.circular(20),
                                                      ),
                                                      child: Text(
                                                        (pkg['discount'] ?? pkg['discountBadge']) as String,
                                                        style: const TextStyle(
                                                          fontSize: 8,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                pkg['title'] as String,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF1A1A2E),
                                                  height: 1.35,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  if (pkg['originalPriceVal'] != null && pkg['resalePriceVal'] != null && (pkg['originalPriceVal'] as double) > (pkg['resalePriceVal'] as double)) ...[
                                                    Text(
                                                      pkg['originalPrice'] as String,
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color: Color(0xFF9E9E9E),
                                                        decoration: TextDecoration.lineThrough,
                                                        decorationColor: Color(0xFF9E9E9E),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                  ],
                                                  Text(
                                                    pkg['resalePrice'] as String,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w900,
                                                      color: Color(0xFF273DB7),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  _buildMerchantAvatar(
                                                    pkg['merchantName'] as String?,
                                                    pkg['merchantLogo'] as String?,
                                                    radius: 7,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      (pkg['merchantName'] != null && (pkg['merchantName'] as String).trim().isNotEmpty)
                                                          ? (pkg['merchantName'] as String).trim()
                                                          : 'Twicely',
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
                                                  Icon(
                                                    pkg['hasHeart'] == true ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                                                    size: 11,
                                                    color: pkg['hasHeart'] == true ? const Color(0xFFFBBD03) : Colors.black38,
                                                  ),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    '${pkg['likesCount'] ?? 0}',
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      color: Colors.black.withValues(alpha: 0.6),
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
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
    final Color avatarColor = displayName.toLowerCase() == 'twicely'
        ? const Color(0xFF273DB7)
        : colors[displayName.hashCode.abs() % colors.length];

    if (hasLogo) {
      return ClipOval(
        child: SizedBox(
          width: radius * 2,
          height: radius * 2,
          child: Image.network(
            logoUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: avatarColor,
              alignment: Alignment.center,
              child: Text(
                initial,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: radius * 0.85,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: avatarColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.85,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
