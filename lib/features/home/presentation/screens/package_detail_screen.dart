import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/cart_manager.dart';
import '../../../../core/utils/session_manager.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../chat/presentation/screens/conversations_screen.dart';
import 'shopping_cart_screen.dart';
import 'seller_profile_screen.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../../core/widgets/package_image_carousel.dart';
import '../../../../core/widgets/marketplace_package_card.dart';
import '../../../../core/widgets/shimmer_effect.dart';

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
  Map<String, dynamic>? _fetchedOwner;

  @override
  void initState() {
    super.initState();
    final rawId = widget.package['id'];
    final intId = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
    _isFavorited = widget.package['hasHeart'] == true ||
        widget.package['liked'] == true ||
        (intId != null && ApiService.wishlistIdsCache.contains(intId));
    _fetchDetails();
    _fetchOwnerDetails(widget.package);
    _fetchSimilar(pkg: widget.package);
  }

  void _fetchDetails() async {
    final rawId = widget.package['id'];
    if (rawId == null) return;
    final intId = rawId is int ? rawId : int.tryParse(rawId.toString());
    if (intId == null) return;

    final bool initialFav = _isFavorited ||
        widget.package['hasHeart'] == true ||
        widget.package['liked'] == true ||
        ApiService.wishlistIdsCache.contains(intId);

    if (mounted) setState(() => _isLoading = true);
    final res = await ApiService.getPackageById(intId);
    if (res['success'] == true && res['data'] != null) {
      if (mounted) {
        final pkgData = res['data'] as Map<String, dynamic>;
        setState(() {
          _detailedPackage = pkgData;
          _isFavorited = initialFav || _detailedPackage?['liked'] == true || _detailedPackage?['hasHeart'] == true;
          _isLoading = false;
        });
        _fetchSimilar(pkg: _detailedPackage!);
        _fetchOwnerDetails(pkgData);
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchOwnerDetails(Map<String, dynamic> pkg) async {
    final ownerIdVal = int.tryParse(pkg['owner_id']?.toString() ?? '');
    final merchantIdVal = int.tryParse(pkg['merchant_id']?.toString() ?? '');
    final ownerTypeVal = pkg['owner_type']?.toString() ?? '';

    // 1. C2C User Profile Resolution
    if (ownerIdVal != null && ownerIdVal > 0 && ownerTypeVal != 'merchant') {
      if (ApiService.usersCache.containsKey(ownerIdVal)) {
        final u = ApiService.usersCache[ownerIdVal]!;
        final avatarUrls = u['avatar_urls'];
        String avatarUrl = '';
        if (avatarUrls is Map) {
          avatarUrl = avatarUrls['96']?.toString() ?? avatarUrls['48']?.toString() ?? avatarUrls['24']?.toString() ?? '';
        } else if (u['avatar'] != null) {
          avatarUrl = u['avatar'].toString();
        }
        if (mounted) {
          setState(() {
            _fetchedOwner = {
              'name': u['name']?.toString() ?? u['display_name']?.toString() ?? 'Twicely Member',
              'avatar': avatarUrl,
              'is_merchant': false,
              'owner_id': ownerIdVal,
              'merchant_id': merchantIdVal,
            };
          });
        }
        return;
      } else {
        final uRes = await ApiService.getPublicUserProfile(ownerIdVal);
        if (uRes['success'] == true && uRes['data'] != null) {
          final data = uRes['data'] as Map<String, dynamic>;
          final avatarUrls = data['avatar_urls'];
          String avatarUrl = '';
          if (avatarUrls is Map) {
            avatarUrl = avatarUrls['96']?.toString() ?? avatarUrls['48']?.toString() ?? avatarUrls['24']?.toString() ?? '';
          }
          if (mounted) {
            setState(() {
              _fetchedOwner = {
                'name': data['name']?.toString() ?? data['display_name']?.toString() ?? 'Twicely Member',
                'avatar': avatarUrl,
                'is_merchant': false,
                'owner_id': ownerIdVal,
                'merchant_id': merchantIdVal,
              };
            });
          }
          return;
        }
      }
    }

    // 2. Merchant Profile Resolution
    final targetMerchantId = (ownerTypeVal == 'merchant' ? ownerIdVal : null) ?? merchantIdVal;
    if (targetMerchantId != null && targetMerchantId > 0) {
      if (ApiService.merchantsCache.containsKey(targetMerchantId)) {
        final cached = ApiService.merchantsCache[targetMerchantId]!;
        if (mounted) {
          setState(() {
            _fetchedOwner = {
              'name': cached['business_name']?.toString() ?? 'Twicely Merchant',
              'avatar': ApiService.getMerchantLogo(targetMerchantId, cached['logo_url']?.toString()),
              'is_merchant': true,
              'merchant_id': targetMerchantId,
              'owner_id': ownerIdVal,
            };
          });
        }
        return;
      } else {
        final mRes = await ApiService.getPublicMerchantProfile(targetMerchantId);
        if (mRes['success'] == true && mRes['data'] != null) {
          final data = mRes['data'] as Map<String, dynamic>;
          ApiService.merchantsCache[targetMerchantId] = data;
          if (mounted) {
            setState(() {
              _fetchedOwner = {
                'name': data['business_name']?.toString() ?? 'Twicely Merchant',
                'avatar': ApiService.getMerchantLogo(targetMerchantId, data['logo_url']?.toString()),
                'is_merchant': true,
                'merchant_id': targetMerchantId,
                'owner_id': ownerIdVal,
              };
            });
          }
          return;
        }
      }
    }

    // 3. Fallback to resolveOwnerInfo
    final ownerInfo = ApiService.resolveOwnerInfo(pkg);
    if (mounted) {
      setState(() {
        _fetchedOwner = ownerInfo;
      });
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
      final rawList = (res['data'] as List<dynamic>)
          .where((p) => p['id']?.toString() != currentId)
          .take(6)
          .map((p) => Map<String, dynamic>.from(p as Map))
          .toList();

      // Prefetch merchant/user profile details for authentic owner information
      await ApiService.prefetchOwners(rawList);
      if (!mounted) return;

      final mapped = rawList.map((p) => _mapSimilarPkg(p)).toList();
      setState(() {
        _similarPackages = mapped;
        _loadingSimilar = false;
      });
    } else {
      if (mounted) setState(() => _loadingSimilar = false);
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

  String _buildDynamicTag(Map<String, dynamic> apiPkg, {String? selectedFilter}) {
    final List<String> mainCats = [];
    
    // Normalize filter casing if needed
    String? normalizedFilter = selectedFilter;
    if (normalizedFilter != null) {
      if (normalizedFilter.toLowerCase() == 'for her') {
        normalizedFilter = 'For Her';
      } else if (normalizedFilter.toLowerCase() == 'for him') {
        normalizedFilter = 'For Him';
      } else if (normalizedFilter.toLowerCase() == 'general') {
        normalizedFilter = 'General';
      } else if (normalizedFilter.toLowerCase() == 'biz+') {
        normalizedFilter = 'Biz+';
      }
    }

    if (normalizedFilter != null && normalizedFilter != 'All Categories' && normalizedFilter != 'All') {
      mainCats.add(normalizedFilter);
    } else {
      final int idVal = int.tryParse(apiPkg['id']?.toString() ?? '') ?? 0;
      if (idVal != 0 && ApiService.packageCategoriesCache.containsKey(idVal)) {
        final cached = List<String>.from(ApiService.packageCategoriesCache[idVal]!);
        if (cached.isNotEmpty) {
          const priority = ['For Her', 'For Him', 'Biz+', 'General'];
          cached.sort((a, b) {
            final ia = priority.indexOf(a);
            final ib = priority.indexOf(b);
            return (ia == -1 ? 99 : ia).compareTo(ib == -1 ? 99 : ib);
          });
          mainCats.add(cached.first);
        }
      }

      if (mainCats.isEmpty && apiPkg['categories'] is List) {
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

  Widget _buildCategoryRichText(String tag, {double fontSize = 8}) {
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
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          fontFamily: 'Recoleta Alt',
        ),
        children: spans,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Map<String, dynamic> _mapSimilarPkg(Map<String, dynamic> p) {
    String imageUrl = '';
    if (p['cover_url'] != null && p['cover_url'].toString().isNotEmpty) {
      imageUrl = p['cover_url'];
    } else if (p['images'] != null && (p['images'] as List).isNotEmpty) {
      imageUrl = (p['images'] as List)[0]['url']?.toString() ?? '';
    }

    final List<String> allImages = [];
    if (p['images'] != null && (p['images'] as List).isNotEmpty) {
      for (var img in p['images'] as List) {
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

    final double original = double.tryParse(p['original_purchase_price']?.toString() ?? '') ??
                            double.tryParse(p['original_price']?.toString() ?? '') ??
                            double.tryParse(p['price']?.toString() ?? '') ?? 0.0;
    final double resale = double.tryParse(p['selling_price_per_session']?.toString() ?? '') ??
                          double.tryParse(p['resale_price']?.toString() ?? '') ??
                          double.tryParse(p['discounted_price']?.toString() ?? '') ??
                          double.tryParse(p['price']?.toString() ?? '') ?? 0.0;
    String? badge;
    if (original > 0 && resale < original) {
      final pct = ((original - resale) / original * 100).round();
      if (pct > 0) { badge = '$pct% OFF'; }
    }

    final ownerInfo = ApiService.resolveOwnerInfo(p);
    final String merchantName = ownerInfo['name'] ?? 'Twicely';
    final String merchantLogo = ownerInfo['avatar'] ?? '';
    final int? activeMerchantId = ownerInfo['merchant_id'] as int?;
    final int? activeOwnerId = ownerInfo['owner_id'] as int?;

    final result = Map<String, dynamic>.from(p);
    result.addAll({
      'id': p['id'],
      'title': ApiService.unescapeHtml(p['title']?.toString() ?? 'Package'),
      'imageUrl': imageUrl.isNotEmpty ? imageUrl : 'assets/images/package_spa.jpg',
      'allImages': allImages,
      'originalPrice': 'S\$${original.toStringAsFixed(2)}',
      'resalePrice': 'S\$${resale.toStringAsFixed(2)}',
      'originalPriceVal': original,
      'resalePriceVal': resale,
      'discountBadge': badge,
      'hasHeart': p['liked'] == true,
      'tag': ApiService.unescapeHtml(_buildDynamicTag(p)),
      'merchantName': ApiService.unescapeHtml(merchantName),
      'merchant': ApiService.unescapeHtml(merchantName),
      'merchantLogo': merchantLogo,
      'merchant_id': activeMerchantId,
      'owner_id': activeOwnerId,
    });
    return result;
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
      CustomSnackBar.show(
        context,
        message: _isFavorited ? 'Added to Wishlist (Demo)' : 'Removed from Wishlist (Demo)',
        type: SnackBarType.success,
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
      CustomSnackBar.show(
        context,
        message: _isFavorited ? 'Added to Wishlist' : 'Removed from Wishlist',
        type: SnackBarType.success,
      );
    } else {
      setState(() {
        _isFavorited = !_isFavorited;
      });
      CustomSnackBar.show(
        context,
        message: 'Failed to update wishlist: ${res['message']}',
        type: SnackBarType.error,
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
        final pkg = _detailedPackage ?? widget.package;
        final title = pkg['title'] ?? 'Selected Package';
        final tag = pkg['tag'] ?? 'Wellness Class';

        String imageUrl = pkg['imageUrl'] ?? pkg['image'] ?? 'assets/images/package_spa.jpg';
        if (pkg['cover_url'] != null && pkg['cover_url'].toString().isNotEmpty) {
          imageUrl = pkg['cover_url'];
        } else if (pkg['images'] != null && (pkg['images'] as List).isNotEmpty) {
          imageUrl = pkg['images'][0]['url'] ?? imageUrl;
        }

        double parsedResale = double.tryParse(pkg['resalePriceVal']?.toString() ?? '') ?? 0.0;
        if (parsedResale == 0.0) {
          parsedResale = double.tryParse(pkg['resalePrice']?.toString().replaceAll(RegExp(r'[^\d.]'), '') ?? '') ?? 0.0;
        }
        if (parsedResale == 0.0) {
          final double? disc = double.tryParse(pkg['discounted_price']?.toString() ?? '');
          if (disc != null && disc > 0) {
            parsedResale = disc;
          }
        }
        if (parsedResale == 0.0) {
          parsedResale = double.tryParse(pkg['price']?.toString() ?? '') ?? 0.0;
        }

        CartManager().addItem({
          'id': packageId,
          'imageUrl': imageUrl,
          'title': title,
          'subtitle': tag,
          'price': parsedResale,
        });

        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const ShoppingCartScreen()),
        );
      } else {
        CustomSnackBar.show(
          context,
          message: res['message'] ?? 'Failed to add item to cart.',
          type: SnackBarType.error,
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
    final title = ApiService.unescapeHtml(pkg['title']?.toString() ?? 'Package details');
    final String tag = ApiService.unescapeHtml((pkg['tag'] ?? _buildDynamicTag(pkg)).toString()).replaceAll('•', '>');

    final double basePrice = double.tryParse(pkg['price']?.toString() ?? '') ?? 
                             double.tryParse(pkg['originalPriceVal']?.toString() ?? '') ??
                             double.tryParse(pkg['originalPrice']?.toString().replaceAll(RegExp(r'[^\d.]'), '') ?? '') ?? 0.0;
    final double discPrice = double.tryParse(pkg['discounted_price']?.toString() ?? '') ?? 0.0;
    final bool hasDiscount = discPrice > 0 && discPrice < basePrice;

    final double rawOriginal = basePrice;
    final double rawResale = hasDiscount ? discPrice : basePrice;

    final originalPrice = 'S\$${rawOriginal.toStringAsFixed(2)}';
    final resalePrice = 'S\$${rawResale.toStringAsFixed(2)}';

    String imageUrl = pkg['imageUrl'] ?? pkg['image'] ?? 'assets/images/package_yoga.jpg';
    if (pkg['cover_url'] != null && pkg['cover_url'].toString().isNotEmpty) {
      imageUrl = pkg['cover_url'];
    } else if (pkg['images'] != null && (pkg['images'] as List).isNotEmpty) {
      imageUrl = pkg['images'][0]['url'] ?? imageUrl;
    }

    final List<String> allImages = [];
    if (pkg['allImages'] != null) {
      try {
        allImages.addAll(List<String>.from(pkg['allImages'] as Iterable));
      } catch (_) {}
    }
    if (allImages.isEmpty && pkg['images'] != null && pkg['images'] is List) {
      for (var img in pkg['images']) {
        if (img is Map && img['url'] != null && img['url'].toString().isNotEmpty) {
          allImages.add(img['url'].toString());
        } else if (img is String && img.isNotEmpty) {
          allImages.add(img);
        }
      }
    }
    if (allImages.isEmpty && pkg['cover_url'] != null && pkg['cover_url'].toString().isNotEmpty) {
      allImages.add(pkg['cover_url'].toString());
    }
    if (allImages.isEmpty && pkg['imageUrl'] != null && pkg['imageUrl'].toString().isNotEmpty) {
      allImages.add(pkg['imageUrl'].toString());
    }
    if (allImages.isEmpty && pkg['image'] != null && pkg['image'].toString().isNotEmpty) {
      allImages.add(pkg['image'].toString());
    }
    if (allImages.isEmpty) {
      allImages.add(imageUrl);
    }

    String? discount;
    if (hasDiscount) {
      final int pct = ((rawOriginal - rawResale) / rawOriginal * 100).round();
      if (pct > 0) {
        discount = '$pct% OFF';
      }
    }

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
                PackageImageCarousel(
                  images: allImages,
                  fallbackImage: 'assets/images/package_yoga.jpg',
                  height: 240,
                  width: double.infinity,
                  borderRadius: BorderRadius.circular(24),
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
                        color: _isFavorited ? const Color(0xFFFF014E) : Colors.black45,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 2. Tags Row
            _buildCategoryRichText(tag, fontSize: 10),
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
                  (() {
                    final rawValidity = pkg['validity'] ?? pkg['availability_end'] ?? pkg['validity_date'] ?? pkg['valid_until'] ?? '';
                    return rawValidity.toString().isNotEmpty
                        ? 'Valid Until ${rawValidity.toString().split(' ')[0]}'
                        : 'Valid Until December 24, 2026';
                  })(),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 5. Price Area with original and resale discount + Presented By
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  resalePrice.startsWith('S') ? resalePrice : 'S\$$resalePrice',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF273DB7),
                  ),
                ),
                if (hasDiscount) ...[
                  const SizedBox(width: 12),
                  Text(
                    originalPrice,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9E9E9E),
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
                if (hasDiscount && discount != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF27B6E),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      discount,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                (() {
                  final ownerInfo = ApiService.resolveOwnerInfo(pkg);
                  final String ownerName = (_fetchedOwner?['name'] ?? ownerInfo['name'] ?? pkg['merchantName'] ?? '').toString().trim();

                  final bool isMerchantOwner = (_fetchedOwner?['is_merchant'] == true) ||
                      (ownerInfo['is_merchant'] == true) ||
                      (pkg['owner_type'] == 'merchant') ||
                      (pkg['merchant_id'] != null && int.tryParse(pkg['merchant_id'].toString()) != null && int.parse(pkg['merchant_id'].toString()) > 0) ||
                      (pkg['merchantName'] != null && pkg['merchantName'].toString().trim().isNotEmpty) ||
                      (pkg['merchant'] != null);

                  // If owner is a merchant, hide Presented By section completely
                  if (isMerchantOwner) return const SizedBox.shrink();

                  Map<String, dynamic>? presentedByMap;
                  if (pkg['presented_by'] is Map) {
                    presentedByMap = Map<String, dynamic>.from(pkg['presented_by'] as Map);
                  }
                  String presentedName = presentedByMap?['name']?.toString() ??
                      presentedByMap?['business_name']?.toString() ??
                      presentedByMap?['display_name']?.toString() ??
                      pkg['manual_vendor_name']?.toString() ?? '';
                  String presentedLogo = presentedByMap?['logo']?.toString() ??
                      presentedByMap?['logo_url']?.toString() ??
                      presentedByMap?['avatar']?.toString() ?? '';
                  int? presentedMerchantId = int.tryParse(presentedByMap?['merchant_id']?.toString() ?? '');

                  if (presentedName.isEmpty) return const SizedBox.shrink();
                  if (ownerName.isNotEmpty && presentedName.trim().toLowerCase() == ownerName.toLowerCase()) {
                    return const SizedBox.shrink();
                  }

                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => SellerProfileScreen(
                            merchantId: presentedMerchantId,
                            merchantName: presentedName,
                            merchantLogo: presentedLogo,
                          ),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Presented By',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.black.withValues(alpha: 0.4),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (presentedLogo.isNotEmpty)
                              CircleAvatar(
                                radius: 8,
                                backgroundImage: NetworkImage(presentedLogo),
                              )
                            else
                              CircleAvatar(
                                radius: 8,
                                backgroundColor: const Color(0xFF273DB7),
                                child: Text(
                                  presentedName.isNotEmpty ? presentedName[0].toUpperCase() : 'M',
                                  style: const TextStyle(fontSize: 7, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            const SizedBox(width: 4),
                            Text(
                              presentedName,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.north_east_rounded, size: 10, color: AppColors.primary),
                          ],
                        ),
                      ],
                    ),
                  );
                })(),
              ],
            ),
            const SizedBox(height: 12),

            // 6. Subtitle description
            (() {
              final String rawDescription = pkg['content'] ?? pkg['description'] ?? pkg['short_description'] ?? '';
              final String taglineText = rawDescription.isNotEmpty
                  ? (rawDescription.length > 120 ? '${rawDescription.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll(RegExp(r'\s+'), ' ').substring(0, 117).trim()}...' : rawDescription.replaceAll(RegExp(r'<[^>]*>'), ''))
                  : 'A premium, highly-demanded lifestyle and wellness package resold directly by its original buyer at a verified discount.';
              return Text(
                taglineText,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.primary.withValues(alpha: 0.7),
                  height: 1.4,
                ),
              );
            })(),
            const SizedBox(height: 22),            // 7. Icon badges grid (2x2)
            Row(
              children: [
                Expanded(
                  child: _buildBadgeCell(
                    Icons.shield_outlined,
                    'Verified Package',
                    const Color(0xFFE24B3E),
                    const Color(0xFFFDE8E7),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildBadgeCell(
                    Icons.layers_outlined,
                    'Partner Merchant',
                    const Color(0xFF1E88E5),
                    const Color(0xFFE3F2FD),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildBadgeCell(
                    Icons.headset_mic_outlined,
                    '24hr Support',
                    const Color(0xFF2E7D32),
                    const Color(0xFFE8F5E9),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildBadgeCell(
                    Icons.sync_alt_rounded,
                    'Transferable',
                    const Color(0xFF7E57C2),
                    const Color(0xFFF3E5F5),
                  ),
                ),
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
              (() {
                final String rawDescription = pkg['content'] ?? pkg['description'] ?? pkg['short_description'] ?? '';
                return rawDescription.isNotEmpty
                    ? rawDescription.replaceAll(RegExp(r'<[^>]*>'), '')
                    : 'This resold package allows you to book sessions directly with the merchant provider. Sessions can be booked dynamically within the remaining validity period. Upon checkout, the transfer ownership credentials will be sent to your registered email address automatically.';
              })(),
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

  Widget _buildBadgeCell(IconData icon, String text, Color iconColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMerchantCard() {
    final pkg = _detailedPackage ?? widget.package;

    String merchantName = 'Twicely';
    String merchantLogo = '';
    bool isRealMerchant = false;
    int? activeMerchantId;
    int? activeOwnerId;

    if (_fetchedOwner != null) {
      merchantName = _fetchedOwner!['name']?.toString() ?? 'Twicely';
      merchantLogo = _fetchedOwner!['avatar']?.toString() ?? '';
      isRealMerchant = _fetchedOwner!['is_merchant'] == true;
      activeMerchantId = int.tryParse(_fetchedOwner!['merchant_id']?.toString() ?? '');
      activeOwnerId = int.tryParse(_fetchedOwner!['owner_id']?.toString() ?? '');
    } else {
      final ownerInfo = ApiService.resolveOwnerInfo(pkg);
      merchantName = ownerInfo['name']?.toString() ?? 'Twicely';
      merchantLogo = ownerInfo['avatar']?.toString() ?? '';
      isRealMerchant = ownerInfo['is_merchant'] == true;
      activeMerchantId = int.tryParse(ownerInfo['merchant_id']?.toString() ?? '');
      activeOwnerId = int.tryParse(ownerInfo['owner_id']?.toString() ?? '');
    }

    final Widget cardContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildMerchantAvatar(merchantName, merchantLogo, radius: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sold By',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.black45,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  merchantName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'View Profile',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF273DB7),
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFF273DB7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isRealMerchant ? const Color(0xFFEFF4FF) : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isRealMerchant ? const Color(0xFF273DB7).withValues(alpha: 0.2) : const Color(0xFF2E7D32).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_rounded,
                  size: 14,
                  color: isRealMerchant ? const Color(0xFF273DB7) : const Color(0xFF2E7D32),
                ),
                const SizedBox(width: 4),
                Text(
                  isRealMerchant ? 'Verified Merchant' : 'Verified Seller',
                  style: TextStyle(
                    fontSize: 10,
                    color: isRealMerchant ? const Color(0xFF273DB7) : const Color(0xFF2E7D32),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SellerProfileScreen(
              merchantId: activeMerchantId,
              ownerId: activeOwnerId,
              merchantName: merchantName,
              merchantLogo: merchantLogo,
            ),
          ),
        );
      },
      child: cardContent,
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
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: 3,
              itemBuilder: (context, index) => const Padding(
                padding: EdgeInsets.only(right: 14.0),
                child: PackageCardSkeleton(),
              ),
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
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _similarPackages.length,
              itemBuilder: (context, index) {
                final item = _similarPackages[index];
                final hasHeart = item['hasHeart'] as bool? ?? false;

                return Container(
                  margin: const EdgeInsets.only(right: 14),
                  child: MarketplacePackageCard(
                    package: item,
                    width: 175,
                    isFavorite: hasHeart,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => PackageDetailScreen(package: item)),
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

  Color _merchantAvatarColor(String? name) {
    final displayName = (name != null && name.trim().isNotEmpty) ? name.trim() : 'Twicely';
    if (displayName.toLowerCase() == 'twicely') return const Color(0xFF273DB7);
    const colors = [
      Color(0xFF4A6FA5),
      Color(0xFF3D8B5E),
      Color(0xFF7B5EA7),
      Color(0xFF5B8DB8),
      Color(0xFF8B6E3C),
      Color(0xFF4A7C59),
    ];
    return colors[displayName.hashCode.abs() % colors.length];
  }

  Widget _buildMerchantAvatar(String? name, String? logoUrl, {double radius = 12}) {
    final displayName = (name != null && name.trim().isNotEmpty) ? name.trim() : 'Twicely';
    final hasLogo = logoUrl != null && logoUrl.isNotEmpty;
    final initial = displayName[0].toUpperCase();
    final avatarColor = hasLogo ? Colors.grey.shade100 : _merchantAvatarColor(displayName);
    return CircleAvatar(
      radius: radius,
      backgroundColor: avatarColor,
      backgroundImage: hasLogo ? NetworkImage(logoUrl) : null,
      child: hasLogo
          ? null
          : Text(
              initial,
              style: TextStyle(fontSize: radius * 0.85, color: Colors.white, fontWeight: FontWeight.bold),
            ),
    );
  }
}
