import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/session_manager.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import 'category_detail_screen.dart';
import '../../../chat/presentation/screens/conversations_screen.dart';
import 'shopping_cart_screen.dart';
import 'wallet_screen.dart';
import 'my_sales_screen.dart';
import 'my_orders_screen.dart';
import 'wishlist_screen.dart';
import 'payout_screen.dart';
import 'my_listings_screen.dart';
import 'add_package_screen.dart';
import 'package_detail_screen.dart';
import 'edit_profile_screen.dart';
import 'notifications_screen.dart';
import 'packages_list_screen.dart';
import '../../../../core/services/api_service.dart';
import 'merchant_dashboard.dart';
import '../../../../core/widgets/package_image_carousel.dart';
import '../../../../core/widgets/shimmer_effect.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0; // 0: Home, 1: Search, 2: Sell, 3: Chat, 4: Profile
  String _selectedFilter = 'For her';
  String _homeSearchQuery = '';
  String _searchTabQuery = '';
  final TextEditingController _homeSearchController = TextEditingController();
  final TextEditingController _searchTabController = TextEditingController();

  bool _isLoadingPackages = false;
  List<Map<String, dynamic>> _apiPackages = [];
  final List<Map<String, dynamic>> _recentlyViewedPackages = [];

  // Profile data loaded from API
  Map<String, dynamic> _profileData = {};
  bool _isLoadingProfile = false;
  double _walletBalance = 0.0;
  int _wishlistCount = 0;
  int _salesCount = 0;
  int _ordersCount = 0;
  int _packagesCount = 0;
  final bool _isUploadingAvatar = false;
  final int _avatarCacheBuster = 0;

  String _getAvatarUrl(Map<String, dynamic> data) {
    final uId = int.tryParse(data['id']?.toString() ?? '') ?? SessionManager.userId;
    final merchantLogo = ApiService.getMerchantLogo(uId, data['logo_url']?.toString() ?? data['logo']?.toString());
    if (merchantLogo.isNotEmpty) return merchantLogo;

    String rawUrl = (data['logo_url'] ?? data['logo'])?.toString() ?? '';
    if (rawUrl.isEmpty && data['avatar_url'] != null && data['avatar_url'].toString().isNotEmpty) {
      rawUrl = data['avatar_url'].toString();
    } else if (data['avatar_urls'] != null) {
      final avatarUrls = data['avatar_urls'];
      if (avatarUrls is Map) {
        rawUrl = avatarUrls['96']?.toString() ?? avatarUrls['48']?.toString() ?? avatarUrls['24']?.toString() ?? '';
      } else if (avatarUrls != null && avatarUrls.toString().isNotEmpty) {
        rawUrl = avatarUrls.toString();
      }
    } else if (data['avatar'] != null) {
      final avatar = data['avatar'];
      if (avatar is Map) {
        rawUrl = avatar['url']?.toString() ?? avatar['96']?.toString() ?? avatar['48']?.toString() ?? avatar['24']?.toString() ?? '';
      } else if (avatar != null && avatar.toString().isNotEmpty) {
        rawUrl = avatar.toString();
      }
    } else if (data['photo'] != null && data['photo'].toString().isNotEmpty) {
      rawUrl = data['photo'].toString();
    } else if (data['profile_photo'] != null && data['profile_photo'].toString().isNotEmpty) {
      rawUrl = data['profile_photo'].toString();
    } else if (data['profile_image'] != null && data['profile_image'].toString().isNotEmpty) {
      rawUrl = data['profile_image'].toString();
    }

    if (rawUrl.isEmpty) return '';

    // If it is a relative path, prepend the WordPress base domain
    if (rawUrl.startsWith('/')) {
      try {
        final uri = Uri.parse(ApiService.baseUrl);
        final hostUrl = '${uri.scheme}://${uri.host}';
        rawUrl = '$hostUrl$rawUrl';
      } catch (_) {
        rawUrl = 'https://staging.twicely.sg$rawUrl';
      }
    }

    // Append cache buster if set
    if (_avatarCacheBuster > 0) {
      final separator = rawUrl.contains('?') ? '&' : '?';
      rawUrl = '$rawUrl${separator}cb=$_avatarCacheBuster';
    }

    return rawUrl;
  }

  // Maps display filter label → API category slug
  static const Map<String, String?> _filterToSlug = {
    'For her': 'for-her',
    'For him': 'for-him',
    'General': 'general',
    'Biz+': 'biz',
  };

  void _addToRecentlyViewed(Map<String, dynamic> pkg) {
    setState(() {
      _recentlyViewedPackages.removeWhere((item) => item['id'] == pkg['id']);
      _recentlyViewedPackages.insert(0, pkg);
      if (_recentlyViewedPackages.length > 4) {
        _recentlyViewedPackages.removeLast();
      }
    });
  }

  List<Map<String, dynamic>> get _displayRecentlyViewed {
    return _recentlyViewedPackages;
  }

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

  @override
  void initState() {
    super.initState();
    _fetchPackages(filter: _selectedFilter);
    _loadProfile();
    _fetchSearchTabPackages();
  }

  @override
  void dispose() {
    _homeSearchController.dispose();
    _searchTabController.dispose();
    super.dispose();
  }


  Future<void> _loadProfile() async {
    if (!mounted) return;
    if (!SessionManager.isLoggedIn) {
      setState(() {
        _isLoadingProfile = false;
      });
      return;
    }
    if (_profileData.isEmpty) {
      setState(() => _isLoadingProfile = true);
    }
    // Load user profile — use setState so phone_number and all fields update the UI
    final profileRes = await ApiService.getUserMe();
    if (!mounted) return;
    if (profileRes['success'] == true && profileRes['data'] != null) {
      setState(() {
        _profileData = Map<String, dynamic>.from(profileRes['data'] as Map);
      });
    } else if (profileRes.containsKey('id') || profileRes.containsKey('email')) {
      setState(() {
        _profileData = Map<String, dynamic>.from(profileRes);
      });
    }
    // API always returns wallet balance as integer CENTS (balance: 525 = SGD 5.25)
    // This applies to BOTH /payments/wallet and /merchants/me/wallet endpoints
    final isMerchantWallet = SessionManager.isMerchant;
    final walletRes = isMerchantWallet
        ? await ApiService.getMerchantWallet()
        : await ApiService.getWallet();
    if (!mounted) return;
    if (walletRes['success'] == true && walletRes['data'] != null) {
      final wd = walletRes['data'] as Map;
      final rawBalance = double.tryParse(wd['balance']?.toString() ?? '0') ?? 0.0;
      _walletBalance = rawBalance;
    } else if (walletRes.containsKey('balance')) {
      final rawBalance = double.tryParse(walletRes['balance']?.toString() ?? '0') ?? 0.0;
      _walletBalance = rawBalance;
    }
    // Load wishlist count
    final wishRes = await ApiService.getUserWishlist(perPage: 1);
    if (!mounted) return;
    if (wishRes['success'] == true) {
      _wishlistCount = (wishRes['meta']?['total'] ?? (wishRes['data'] as List?)?.length ?? 0) as int;
    }
    // For merchant users, also load /merchants/me to get business details
    if (SessionManager.isMerchant) {
      final merchantRes = await ApiService.getMerchantMe();
      if (!mounted) return;
      if (merchantRes['success'] == true && merchantRes['data'] != null) {
        final mData = Map<String, dynamic>.from(merchantRes['data'] as Map);
        setState(() {
          // Merge merchant fields — phone_number from merchants/me takes priority
          _profileData = {..._profileData, ...mData};
        });
      }
    }
    // Load sales count
    final isMerchant = SessionManager.isMerchant;
    final salesRes = isMerchant
        ? await ApiService.getMerchantOrders(perPage: 1)
        : await ApiService.getMySales(perPage: 1);
    if (!mounted) return;
    if (salesRes['success'] == true) {
      _salesCount = (salesRes['meta']?['total'] ?? (salesRes['data'] as List?)?.length ?? 0) as int;
    }
    // Load orders count
    final ordersRes = await ApiService.getMyOrders(perPage: 1);
    if (!mounted) return;
    if (ordersRes['success'] == true) {
      _ordersCount = (ordersRes['meta']?['total'] ?? (ordersRes['data'] as List?)?.length ?? 0) as int;
    }

    // Load listed packages count
    final pkgsRes = isMerchant
        ? await ApiService.getMerchantPackages(perPage: 1)
        : await ApiService.getUserPackages(perPage: 1);
    if (!mounted) return;
    if (pkgsRes['success'] == true) {
      _packagesCount = (pkgsRes['meta']?['total'] ?? (pkgsRes['data'] as List?)?.length ?? 0) as int;
    }

    if (mounted) setState(() => _isLoadingProfile = false);
  }

  Future<void> _fetchPackages({String? filter}) async {
    if (mounted) setState(() => _isLoadingPackages = true);
    try {
      final slug = _filterToSlug[filter ?? _selectedFilter];
      final res = await ApiService.getPackages(
        perPage: 20,
        category: slug,
      );
      if (res['success'] == true && res['data'] != null) {
        final List<dynamic> pkgs = res['data'];
        await ApiService.prefetchOwners(pkgs);
        if (mounted) {
          setState(() {
            _apiPackages = pkgs
                .map((p) {
                  try {
                    return _mapApiPackage(p as Map<String, dynamic>, selectedFilter: _selectedFilter);
                  } catch (e) {
                    debugPrint('Error mapping package: $e');
                    return null;
                  }
                })
                .where((p) => p != null)
                .cast<Map<String, dynamic>>()
                .toList();
            _isLoadingPackages = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingPackages = false);
      }
    } catch (e) {
      debugPrint('Error fetching packages: $e');
      if (mounted) setState(() => _isLoadingPackages = false);
    }
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

    if (normalizedFilter != null && normalizedFilter != 'All') {
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

  String _getPkgTrueCategory(Map<String, dynamic> apiPkg) {
    final int idVal = int.tryParse(apiPkg['id']?.toString() ?? '') ?? 0;
    if (idVal != 0 && ApiService.packageCategoriesCache.containsKey(idVal)) {
      final cached = ApiService.packageCategoriesCache[idVal]!;
      if (cached.isNotEmpty) {
        return cached.first;
      }
    }
    return _determineFilterCategory(apiPkg);
  }

  Map<String, dynamic> _mapApiPackage(Map<String, dynamic> apiPkg, {String? selectedFilter}) {
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

    final String category = (selectedFilter != null && selectedFilter != 'All Categories' && selectedFilter != 'All')
        ? selectedFilter
        : _getPkgTrueCategory(apiPkg);
    String tag = _buildDynamicTag(apiPkg, selectedFilter: selectedFilter);

    final secondarySlug = apiPkg['secondary_category']?.toString() ?? '';
    final subcatLabel = _subcatLabels[secondarySlug] ?? '';

    final ownerInfo = ApiService.resolveOwnerInfo(apiPkg);
    final String merchantName = ownerInfo['name'] ?? 'Twicely';
    final String merchantLogo = ownerInfo['avatar'] ?? '';
    final bool isMerchantOwner = ownerInfo['is_merchant'] == true;
    final int? activeMerchantId = ownerInfo['merchant_id'] as int?;
    final int? activeOwnerId = ownerInfo['owner_id'] as int?;

    int likesCount = int.tryParse(apiPkg['likes_count']?.toString() ?? '') ??
                     (apiPkg['likes'] != null ? int.tryParse(apiPkg['likes'].toString()) : null) ??
                     (apiPkg['id'] != null ? (apiPkg['id'].hashCode % 5) : 0);
    if ((apiPkg['liked'] == true || apiPkg['hasHeart'] == true) && likesCount == 0) {
      likesCount = 1;
    }

    final String cleanTitle = ApiService.unescapeHtml(apiPkg['title']?.toString() ?? 'Package Listing');
    final String cleanDescription = ApiService.unescapeHtml(apiPkg['description']?.toString() ?? '');
    final String cleanMerchantName = ApiService.unescapeHtml(merchantName);
    final String cleanCategory = ApiService.unescapeHtml(category);
    final String cleanTag = ApiService.unescapeHtml(tag);

    return {
      'id': apiPkg['id'],
      'imageUrl': imageUrl,
      'allImages': allImages,
      'tag': cleanTag,
      'title': cleanTitle,
      'originalPrice': 'S\$${originalPrice.toStringAsFixed(2)}',
      'resalePrice': 'S\$${resalePrice.toStringAsFixed(2)}',
      'originalPriceVal': originalPrice,
      'resalePriceVal': resalePrice,
      'hasHeart': apiPkg['liked'] == true || apiPkg['hasHeart'] == true,
      'discountBadge': discountBadge,
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
      'merchant_id': activeMerchantId,
      'owner_id': activeOwnerId,
      'isMerchantOwner': isMerchantOwner,
      'secondaryCategory': secondarySlug,
      'secondaryCategoryLabel': subcatLabel,
      'likesCount': likesCount,
    };
  }

  String _selectedMerchant = 'All Merchants';
  String _selectedCategory = 'All Categories';
  String? _selectedSubcat; // null means "All Types"
  String _selectedSort = 'Sort: Price Low to High';

  List<Map<String, dynamic>> _searchTabPackages = [];
  bool _isLoadingSearchTab = false;

  static const Map<String, String> _subcatLabels = {
    'yoga-pilates': 'Yoga & Pilates',
    'spa-massage': 'Spa & Massage',
    'beauty-nails': 'Beauty & Nails',
    'gym-fitness': 'Gym & Fitness',
    'lifestyle-classes': 'Lifestyle Classes',
  };

  List<String> get _availableMerchants {
    final Set<String> set = {'All Merchants'};
    for (final p in _apiPackages) {
      if (p['merchantName'] != null) {
        set.add(p['merchantName'].toString());
      }
    }
    for (final p in _searchTabPackages) {
      if (p['merchantName'] != null) {
        set.add(p['merchantName'].toString());
      }
    }
    return set.toList();
  }

  Future<void> _fetchSearchTabPackages() async {
    if (!mounted) return;
    setState(() => _isLoadingSearchTab = true);

    try {
      String? categorySlug;
      if (_selectedCategory == 'For her' || _selectedCategory == 'For Her') {
        categorySlug = 'for-her';
      } else if (_selectedCategory == 'For him' || _selectedCategory == 'For Him') {
        categorySlug = 'for-him';
      } else if (_selectedCategory == 'General') {
        categorySlug = 'general';
      } else if (_selectedCategory == 'Biz+') {
        categorySlug = 'biz';
      }

      final res = await ApiService.getPackages(
        perPage: 100,
        search: _searchTabQuery.isNotEmpty ? _searchTabQuery : null,
        category: categorySlug,
      );

      if (!mounted) return;
      if (res['success'] == true && res['data'] != null) {
        final List<dynamic> raw = res['data'];
        setState(() {
          _searchTabPackages = raw
              .map((p) {
                try {
                  return _mapApiPackage(p as Map<String, dynamic>, selectedFilter: _selectedCategory);
                } catch (e) {
                  debugPrint('Error mapping search tab package: $e');
                  return null;
                }
              })
              .where((p) => p != null)
              .cast<Map<String, dynamic>>()
              .toList();
          _isLoadingSearchTab = false;
        });
      } else {
        setState(() => _isLoadingSearchTab = false);
      }
    } catch (e) {
      debugPrint('Error fetching search tab packages: $e');
      if (mounted) setState(() => _isLoadingSearchTab = false);
    }
  }

  void _showMerchantFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFFF8EA),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final merchants = _availableMerchants;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: merchants.map((m) {
                    return ListTile(
                      title: Text(
                        m,
                        style: TextStyle(
                          fontWeight: _selectedMerchant == m ? FontWeight.bold : FontWeight.normal,
                          color: AppColors.primary,
                        ),
                      ),
                      trailing: _selectedMerchant == m ? const Icon(Icons.check, color: AppColors.primary) : null,
                      onTap: () {
                        setState(() {
                          _selectedMerchant = m;
                        });
                        Navigator.of(context).pop();
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCategoryFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFFF8EA),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final categories = ['All Categories', 'For her', 'For him', 'General', 'Biz+'];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: categories.map((c) {
              return ListTile(
                title: Text(
                  c,
                  style: TextStyle(
                    fontWeight: _selectedCategory == c ? FontWeight.bold : FontWeight.normal,
                    color: AppColors.primary,
                  ),
                ),
                trailing: _selectedCategory == c ? const Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () {
                  setState(() {
                    _selectedCategory = c;
                  });
                  _fetchSearchTabPackages();
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showSubcatFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFFF8EA),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final subcats = [
          {'slug': null, 'label': 'All Types'},
          {'slug': 'yoga-pilates', 'label': 'Yoga & Pilates'},
          {'slug': 'spa-massage', 'label': 'Spa & Massage'},
          {'slug': 'beauty-nails', 'label': 'Beauty & Nails'},
          {'slug': 'gym-fitness', 'label': 'Gym & Fitness'},
          {'slug': 'lifestyle-classes', 'label': 'Lifestyle Classes'},
        ];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: subcats.map((sc) {
              final label = sc['label'] ?? '';
              final slug = sc['slug'];
              final isSelected = _selectedSubcat == slug;
              return ListTile(
                title: Text(
                  label,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: AppColors.primary,
                  ),
                ),
                trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () {
                  setState(() {
                    _selectedSubcat = slug;
                  });
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showSortFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFFF8EA),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final options = ['Sort: Price Low to High', 'Sort: Price High to Low'];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((o) {
              return ListTile(
                title: Text(
                  o,
                  style: TextStyle(
                    fontWeight: _selectedSort == o ? FontWeight.bold : FontWeight.normal,
                    color: AppColors.primary,
                  ),
                ),
                trailing: _selectedSort == o ? const Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () {
                  setState(() {
                    _selectedSort = o;
                  });
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }



  bool _checkAuthWithPrompt({required String title, required String message}) {
    if (!SessionManager.isLoggedIn) {
      _showLoginPrompt(title: title, message: message);
      return false;
    }
    return true;
  }

  void _showLoginPrompt({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF8EA),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_outline_rounded,
                      color: Color(0xFFFBBD03),
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Recoleta Alt',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
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
                    backgroundColor: const Color(0xFFFBBD03), // Yellow CTA color
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black54,
                    side: BorderSide(color: Colors.black.withValues(alpha: 0.1)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPackageDetails(Map<String, dynamic> pkg) {
    _addToRecentlyViewed(pkg);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PackageDetailScreen(package: pkg),
      ),
    );
  }



  List<Map<String, dynamic>> get _filteredPackages {
    // API already returns the correct category — just apply optional search filter
    var list = _apiPackages.isNotEmpty ? List<Map<String, dynamic>>.from(_apiPackages) : <Map<String, dynamic>>[];
    if (_homeSearchQuery.isNotEmpty) {
      list = list
          .where((pkg) =>
              pkg['title'].toString().toLowerCase().contains(_homeSearchQuery.toLowerCase()) ||
              pkg['tag'].toString().toLowerCase().contains(_homeSearchQuery.toLowerCase()))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: _buildPageBody(),
      ),
      bottomNavigationBar: _buildCustomBottomNavBar(),
    );
  }

  Widget _buildPageBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildSearchTab();
      case 3:
        return _buildChatTab();
      case 4:
        return _buildProfileTab();
      default:
        return _buildHomeTab();
    }
  }

  // --- HOME TAB (Figma Design Layout) ---
  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: () => _fetchPackages(filter: _selectedFilter),
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Image.asset(
                  'assets/images/logo.webp',
                  height: 38,
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
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded, color: AppColors.primary, size: 26),
                  onPressed: () {
                    if (_checkAuthWithPrompt(
                      title: 'Please Login',
                      message: 'Please login to access notifications.',
                    )) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 26),
                  onPressed: () {
                    if (_checkAuthWithPrompt(
                      title: 'Please Login',
                      message: 'Please login to access your shopping cart.',
                    )) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ShoppingCartScreen(),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    if (SessionManager.isLoggedIn) {
                      setState(() => _currentIndex = 4);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    }
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.1), width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 20),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 2. Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: TextFormField(
              controller: _homeSearchController,
              style: const TextStyle(fontSize: 14, color: AppColors.primary),
              onChanged: (val) {
                setState(() {
                  _homeSearchQuery = val;
                });
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Search packages, categories...',
                hintStyle: TextStyle(color: AppColors.primary.withValues(alpha: 0.4)),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
                suffixIcon: _homeSearchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          setState(() {
                            _homeSearchController.clear();
                            _homeSearchQuery = '';
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
          const SizedBox(height: 20),

          // 3. Hero Banner Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    // Background Image
                    Image.asset(
                      'assets/images/hero_banner.jpg',
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF7E84F7), Color(0xFF4C52C2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                    // Dark overlay for readability
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.45),
                            Colors.black.withValues(alpha: 0.15),
                          ],
                          begin: Alignment.bottomLeft,
                          end: Alignment.topRight,
                        ),
                      ),
                    ),
                    // Banner Content Text
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't let good\ntimes go to\nwaste.",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "The smart resale marketplace for unused\nand partially used lifestyle packages.",
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Salmon CTA button
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => const PackagesListScreen(),
                              ));
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF27B6E),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text(
                                    'Start exploring now',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 12),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // 4. Popular Categories
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Popular categories',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const PackagesListScreen(),
                    ));
                  },
                  child: const Text(
                    'See all',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Categories horizontal layout
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                _buildCategoryItem('Yoga &\nPilates', Icons.favorite_rounded, const Color(0xFFFDE8E7), const Color(0xFFA8352A), 'Yoga & Pilates'),
                const SizedBox(width: 14),
                _buildCategoryItem('Spa &\nMassage', Icons.opacity_rounded, const Color(0xFFE8EFFF), const Color(0xFF005FAF), 'Spa & Massage'),
                const SizedBox(width: 14),
                _buildCategoryItem('Hair &\nNails', Icons.content_cut_rounded, const Color(0xFFFFF8D4), const Color(0xFF8B6B00), 'Beauty & Nails'),
                const SizedBox(width: 14),
                _buildCategoryItem('Gym &\nFitness', Icons.fitness_center_rounded, const Color(0xFFE8F8E9), const Color(0xFF1B6A26), 'Gym & Fitness'),
                const SizedBox(width: 14),
                _buildCategoryItem('Lifestyle\nClasses', Icons.palette_rounded, const Color(0xFFFFF0E0), const Color(0xFFD66000), 'Lifestyle Classes'),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // 5. Shop Popular Packages Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Shop popular packages',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Browse what our community is lovin'",
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const PackagesListScreen(),
                    ));
                  },
                  child: const Text(
                    'See all',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Horizontal Filter Chips (For her, For him, General, Biz+)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                _buildFilterChip('For her'),
                const SizedBox(width: 8),
                _buildFilterChip('For him'),
                const SizedBox(width: 8),
                _buildFilterChip('General'),
                const SizedBox(width: 8),
                _buildFilterChip('Biz+'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Horizontal Packages Scroller
          SizedBox(
            height: 220,
            child: _isLoadingPackages
                ? ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    itemCount: 4,
                    itemBuilder: (context, index) => const Padding(
                      padding: EdgeInsets.only(right: 14.0),
                      child: PackageCardSkeleton(),
                    ),
                  )
                : _filteredPackages.isEmpty
                    ? const Center(
                        child: Text(
                          'No packages available in this category.',
                          style: TextStyle(color: Colors.black38, fontSize: 13),
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        itemCount: _filteredPackages.length,
                        itemBuilder: (context, index) {
                          final pkg = _filteredPackages[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 14.0),
                            child: _buildPackageCard(
                              id: pkg['id'],
                              imageUrl: pkg['imageUrl'] as String,
                              tag: pkg['tag'] as String,
                              title: pkg['title'] as String,
                              originalPrice: pkg['originalPrice'] as String,
                              resalePrice: pkg['resalePrice'] as String,
                              hasHeart: pkg['hasHeart'] as bool,
                              discountBadge: pkg['discountBadge'] as String?,
                              originalPriceVal: pkg['originalPriceVal'] as double?,
                              resalePriceVal: pkg['resalePriceVal'] as double?,
                              merchantName: pkg['merchantName'] as String?,
                              merchantLogo: pkg['merchantLogo'] as String?,
                              likesCount: pkg['likesCount'] as int?,
                              merchantId: pkg['merchant_id'],
                              allImages: pkg['allImages'] != null ? List<String>.from(pkg['allImages'] as Iterable) : null,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildCategoryItem(String title, IconData icon, Color bgColor, Color iconColor, String originalName) {
    return GestureDetector(
      onTap: () {
        String imagePath = 'assets/images/cat_yoga.png';
        if (originalName == 'Spa & Massage') imagePath = 'assets/images/cat_spa.png';
        if (originalName == 'Beauty & Nails' || originalName == 'Hair & Nails') imagePath = 'assets/images/cat_nails.png';
        if (originalName == 'Gym & Fitness') imagePath = 'assets/images/cat_gym.png';
        if (originalName == 'Lifestyle Classes') imagePath = 'assets/images/cat_lifestyle.png';

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CategoryDetailScreen(
              categoryName: originalName,
              categoryIcon: imagePath,
            ),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String text) {
    final isSelected = _selectedFilter == text;
    return GestureDetector(
      onTap: () {
        if (_selectedFilter == text) return;
        setState(() => _selectedFilter = text);
        _fetchPackages(filter: text);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF776AD) : const Color(0xFFFFF9F9),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.transparent,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF232D52),
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

  Widget _buildPackageCard({
    required String imageUrl,
    required String tag,
    required String title,
    required String originalPrice,
    required String resalePrice,
    bool hasHeart = false,
    String? discountBadge,
    dynamic id,
    double? originalPriceVal,
    double? resalePriceVal,
    String? merchantName,
    String? merchantLogo,
    int? likesCount,
    dynamic merchantId,
    List<String>? allImages,
  }) {
    final bool isDiscounted = originalPriceVal != null && resalePriceVal != null && originalPriceVal > resalePriceVal;
    return GestureDetector(
      onTap: () {
        _showPackageDetails({
          'id': id,
          'imageUrl': imageUrl,
          'allImages': allImages ?? [imageUrl],
          'tag': tag,
          'title': title,
          'originalPrice': originalPrice,
          'resalePrice': resalePrice,
          'hasHeart': hasHeart,
          'discountBadge': isDiscounted ? discountBadge : null,
          'originalPriceVal': originalPriceVal,
          'resalePriceVal': resalePriceVal,
          'merchantName': merchantName,
          'merchantLogo': merchantLogo,
          'merchant_id': merchantId,
        });
      },
      child: Container(
        width: 175,
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
            // Image top header
            Expanded(
              flex: 46,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14.5)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PackageImageCarousel(
                      images: allImages ?? [imageUrl],
                      fallbackImage: 'assets/images/package_spa.jpg',
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(14.5)),
                      onTap: () {
                        _showPackageDetails({
                          'id': id,
                          'imageUrl': imageUrl,
                          'allImages': allImages ?? [imageUrl],
                          'tag': tag,
                          'title': title,
                          'originalPrice': originalPrice,
                          'resalePrice': resalePrice,
                          'hasHeart': hasHeart,
                          'discountBadge': isDiscounted ? discountBadge : null,
                          'originalPriceVal': originalPriceVal,
                          'resalePriceVal': resalePriceVal,
                          'merchantName': merchantName,
                          'merchantLogo': merchantLogo,
                          'merchant_id': merchantId,
                        });
                      },
                    ),
                    // Heart top right button
                    if (hasHeart)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.favorite_rounded, color: Color(0xFFFBBD03), size: 16),
                        ),
                      ),
                    // Discount badge
                    if (isDiscounted && discountBadge != null)
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
            // Content metadata
            Expanded(
              flex: 54,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCategoryRichText(tag),
                    const SizedBox(height: 3),
                    SizedBox(
                      height: 32,
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E),
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 12,
                      child: isDiscounted
                          ? Text(
                              originalPrice,
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
                        resalePrice,
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
                        _buildMerchantAvatar(merchantName, merchantLogo, radius: 7),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            (merchantName != null && merchantName.trim().isNotEmpty) ? merchantName.trim() : 'Twicely',
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
                          hasHeart ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                          size: 11,
                          color: hasHeart ? const Color(0xFFFBBD03) : Colors.black38,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${likesCount ?? 0}',
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Builds a merchant avatar: logo image if available, otherwise initials
  // with a consistent color derived from the merchant name hash.
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
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return ShimmerEffect.circular(size: radius * 2);
            },
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

  Widget _buildSearchTab() {
    final filtered = _searchTabFilteredPackages;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header Row
        Padding(
          padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset(
                'assets/images/logo.webp',
                height: 38,
                fit: BoxFit.contain,
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded, color: AppColors.primary, size: 26),
                    onPressed: () {
                      if (_checkAuthWithPrompt(
                        title: 'Please Login',
                        message: 'Please login to access notifications.',
                      )) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const NotificationsScreen(),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 26),
                    onPressed: () {
                      if (_checkAuthWithPrompt(
                        title: 'Please Login',
                        message: 'Please login to access your shopping cart.',
                      )) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ShoppingCartScreen(),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      if (SessionManager.isLoggedIn) {
                        setState(() => _currentIndex = 4);
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      }
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1), width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Scrollable Body containing everything
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title and description
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Search Packages',
                        style: TextStyle(
                          fontFamily: 'Recoleta Alt',
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Browse and select packages by category or merchant',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Search Input Box
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: TextField(
                    controller: _searchTabController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (val) {
                      setState(() {
                        _searchTabQuery = val;
                      });
                      _fetchSearchTabPackages();
                    },
                    onChanged: (val) {
                      setState(() {
                        _searchTabQuery = val;
                      });
                      if (val.isEmpty) {
                        _fetchSearchTabPackages();
                      }
                    },
                    style: const TextStyle(fontSize: 14, color: AppColors.primary),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Search by package name...',
                      hintStyle: TextStyle(color: AppColors.primary.withValues(alpha: 0.4), fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                      suffixIcon: _searchTabQuery.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                setState(() {
                                  _searchTabController.clear();
                                  _searchTabQuery = '';
                                });
                                _fetchSearchTabPackages();
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
                const SizedBox(height: 20),

                // Dashed filter options (Merchant, Primary Category, Secondary Category)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildFilterPill(
                              label: 'Merchant',
                              selectedValue: _selectedMerchant,
                              prefixIcon: Icons.storefront_outlined,
                              onTap: _showMerchantFilter,
                              onClear: () {
                                setState(() {
                                  _selectedMerchant = 'All Merchants';
                                });
                                _fetchSearchTabPackages();
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildFilterPill(
                              label: 'Category',
                              selectedValue: _selectedCategory,
                              prefixIcon: Icons.category_outlined,
                              onTap: _showCategoryFilter,
                              onClear: () {
                                setState(() {
                                  _selectedCategory = 'All Categories';
                                });
                                _fetchSearchTabPackages();
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildFilterPill(
                              label: 'Subcategory',
                              selectedValue: _selectedSubcat != null ? _subcatLabels[_selectedSubcat!] : null,
                              prefixIcon: Icons.layers_outlined,
                              onTap: _showSubcatFilter,
                              onClear: () {
                                setState(() {
                                  _selectedSubcat = null;
                                });
                                _fetchSearchTabPackages();
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Results Count text and Sort button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isLoadingSearchTab ? 'Searching...' : '${filtered.length} Results Found',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      GestureDetector(
                        onTap: _showSortFilter,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.sort_rounded, size: 14, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                _selectedSort.replaceAll('Sort: ', ''),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                              const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Vertical Grid of package search results
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: _isLoadingSearchTab
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40.0),
                            child: CircularProgressIndicator(color: AppColors.primary),
                          ),
                        )
                      : filtered.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 40.0),
                                child: Text(
                                  'No matching packages found',
                                  style: TextStyle(color: Colors.black38, fontSize: 13),
                                ),
                              ),
                            )
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                childAspectRatio: 0.84,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final pkg = filtered[index];
                                return _buildPackageCard(
                                  id: pkg['id'],
                                  imageUrl: pkg['imageUrl'] as String,
                                  tag: pkg['tag'] as String,
                                  title: pkg['title'] as String,
                                  originalPrice: pkg['originalPrice'] as String,
                                  resalePrice: pkg['resalePrice'] as String,
                                  hasHeart: pkg['hasHeart'] as bool,
                                  discountBadge: pkg['discountBadge'] as String?,
                                  originalPriceVal: pkg['originalPriceVal'] as double?,
                                  resalePriceVal: pkg['resalePriceVal'] as double?,
                                  merchantName: pkg['merchantName'] as String?,
                                  merchantLogo: pkg['merchantLogo'] as String?,
                                  likesCount: pkg['likesCount'] as int?,
                                  merchantId: pkg['merchant_id'],
                                  allImages: pkg['allImages'] != null ? List<String>.from(pkg['allImages'] as Iterable) : null,
                                );
                              },
                            ),
                ),
                const SizedBox(height: 28),

                // Section: RECENTLY VIEWED
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    'RECENTLY VIEWED',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: Colors.black45,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Two columns grid of recently viewed
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Builder(
                    builder: (context) {
                      final items = _displayRecentlyViewed;
                      if (items.isEmpty) return const SizedBox.shrink();
                      return SizedBox(
                        height: 220,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: List.generate(items.length.clamp(0, 2), (index) {
                            final pkg = items[index];
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: index == 0 && items.length > 1 ? 14.0 : 0.0,
                                ),
                                child: _buildPackageCard(
                                  id: pkg['id'],
                                  imageUrl: pkg['imageUrl'] as String,
                                  tag: pkg['tag'] as String,
                                  title: pkg['title'] as String,
                                  originalPrice: pkg['originalPrice'] as String,
                                  resalePrice: pkg['resalePrice'] as String,
                                  hasHeart: pkg['hasHeart'] as bool? ?? false,
                                  discountBadge: pkg['discountBadge'] as String?,
                                  originalPriceVal: pkg['originalPriceVal'] as double?,
                                  resalePriceVal: pkg['resalePriceVal'] as double?,
                                  merchantName: pkg['merchantName'] as String?,
                                  merchantLogo: pkg['merchantLogo'] as String?,
                                  likesCount: pkg['likesCount'] as int?,
                                  merchantId: pkg['merchant_id'],
                                  allImages: pkg['allImages'] != null ? List<String>.from(pkg['allImages'] as Iterable) : null,
                                ),
                              ),
                            );
                          }),
                        ),
                      );
                    }
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ],
    );
  }

  double _parsePrice(String priceStr) {
    final clean = priceStr.replaceAll(r'S$', '').replaceAll(r'$', '').trim();
    return double.tryParse(clean) ?? 0.0;
  }

  List<Map<String, dynamic>> get _searchTabFilteredPackages {
    final baseList = _searchTabPackages;
    List<Map<String, dynamic>> res = List.from(baseList);

    if (_searchTabQuery.isNotEmpty) {
      res = res.where((pkg) =>
          pkg['title'].toString().toLowerCase().contains(_searchTabQuery.toLowerCase()) ||
          pkg['tag'].toString().toLowerCase().contains(_searchTabQuery.toLowerCase()) ||
          pkg['category'].toString().toLowerCase().contains(_searchTabQuery.toLowerCase())).toList();
    }

    if (_selectedMerchant != 'All Merchants') {
      res = res.where((pkg) {
        final mName = pkg['merchantName']?.toString() ?? '';
        final mObjName = (pkg['merchant'] is Map) ? (pkg['merchant']['name']?.toString() ?? '') : '';
        return mName.toLowerCase() == _selectedMerchant.toLowerCase() ||
               mObjName.toLowerCase() == _selectedMerchant.toLowerCase();
      }).toList();
    }

    if (_selectedCategory != 'All Categories') {
      res = res.where((pkg) {
        final int idVal = int.tryParse(pkg['id']?.toString() ?? '') ?? 0;
        if (idVal != 0 && ApiService.packageCategoriesCache.containsKey(idVal)) {
          final cached = ApiService.packageCategoriesCache[idVal]!;
          final normalizedSelected = _selectedCategory.toLowerCase().replaceAll(' ', '');
          for (final c in cached) {
            if (c.toLowerCase().replaceAll(' ', '') == normalizedSelected) {
              return true;
            }
          }
        }
        final cat = pkg['category']?.toString() ?? '';
        return cat.toLowerCase() == _selectedCategory.toLowerCase();
      }).toList();
    }

    if (_selectedSubcat != null) {
      res = res.where((pkg) {
        final sub = pkg['secondaryCategory']?.toString() ?? '';
        return sub.toLowerCase() == _selectedSubcat!.toLowerCase();
      }).toList();
    }

    if (_selectedSort == 'Sort: Price Low to High' || _selectedSort == 'Price: Low to High') {
      res.sort((a, b) => _parsePrice(a['resalePrice'] as String).compareTo(_parsePrice(b['resalePrice'] as String)));
    } else if (_selectedSort == 'Sort: Price High to Low' || _selectedSort == 'Price: High to Low') {
      res.sort((a, b) => _parsePrice(b['resalePrice'] as String).compareTo(_parsePrice(a['resalePrice'] as String)));
    }

    return res;
  }

  Widget _buildChatTab() {
    return ConversationsScreen(
      onProfileTap: () {
        setState(() {
          _currentIndex = 4; // Navigate to Profile
        });
      },
    );
  }

  Widget _buildProfileTab() {
    final nameFallback = '${_profileData['first_name'] ?? ''} ${_profileData['last_name'] ?? ''}'.trim();
    final name = (_profileData['name']?.toString().isNotEmpty == true
            ? _profileData['name']!.toString()
            : nameFallback.isNotEmpty ? nameFallback : null)
        ?? SessionManager.userName ?? 'Twicely Member';
    final email = _profileData['email']?.toString() ?? SessionManager.userEmail ?? '';
    final phone = _profileData['phone_number']?.toString() ?? _profileData['phone']?.toString() ?? '';
    final verified = _profileData['verification_status']?.toString() == 'verified';
    final isMerchant = SessionManager.isMerchant;
    final initials = name.split(' ').where((w) => w.isNotEmpty).take(2).map((w) => w[0].toUpperCase()).join();
    final avatarUrl = _getAvatarUrl(_profileData);

    return RefreshIndicator(
      onRefresh: _loadProfile,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            // Avatar
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFF27B6E).withValues(alpha: 0.3), width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(48),
                      child: _isUploadingAvatar
                          ? const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                              ),
                            )
                          : avatarUrl.isNotEmpty
                              ? Image.network(
                                  avatarUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _buildDefaultAvatarCircle(initials),
                                )
                              : _buildDefaultAvatarCircle(initials),
                    ),
                  ),
                  Positioned(
                    bottom: 0, right: 4,
                    child: GestureDetector(
                      onTap: () async {
                        final updated = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EditProfileScreen(profileData: _profileData),
                          ),
                        );
                        if (updated == true) {
                          _loadProfile();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: Color(0xFFF27B6E), shape: BoxShape.circle),
                        child: const Icon(Icons.edit, color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Name
            _isLoadingProfile
              ? const Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary))))
              : Text(
                  name.isEmpty ? 'Twicely Member' : name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: 'Recoleta Alt', fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
            const SizedBox(height: 4),
            if (email.isNotEmpty)
              Text(email, textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: AppColors.primary.withValues(alpha: 0.5))),
            if (phone.isNotEmpty) ...[const SizedBox(height: 2),
              Text(phone, textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: AppColors.primary.withValues(alpha: 0.4))),
            ],
            const SizedBox(height: 10),

            // Badges
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isMerchant ? const Color(0xFF1F2E4E) : const Color(0xFFF27B6E),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isMerchant ? 'MERCHANT' : 'C2C MEMBER',
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  ),
                ),
                if (verified) ...[const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFF22C55E).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                    child: Row(children: const [
                      Icon(Icons.verified_rounded, size: 11, color: Color(0xFF22C55E)),
                      SizedBox(width: 3),
                      Text('VERIFIED', style: TextStyle(color: Color(0xFF22C55E), fontSize: 9, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 28),

            // Option cards with real data
            if (isMerchant) ...[
              _buildProfileOption(
                title: 'Switch to Merchant Dashboard',
                subtitle: 'Manage packages & sales',
                icon: Icons.storefront_outlined,
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const MerchantDashboard()),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
            _buildProfileOption(
              title: 'Wallet',
              subtitle: _isLoadingProfile ? 'Loading...' : 'Balance: SGD ${_walletBalance.toStringAsFixed(2)}',
              icon: Icons.account_balance_wallet_outlined,
              onTap: () async {
                await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => WalletScreen(isMerchant: isMerchant),
                ));
                _loadProfile();
              },
            ),
            _buildProfileOption(
              title: 'My Listings',
              subtitle: _isLoadingProfile ? 'Loading...' : '$_packagesCount listed package${_packagesCount != 1 ? 's' : ''}',
              icon: Icons.inventory_2_outlined,
              onTap: () async {
                await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => MyListingsScreen(isMerchant: isMerchant),
                ));
                _loadProfile();
              },
            ),
            const SizedBox(height: 12),
            _buildProfileOption(
              title: 'My Sales',
              subtitle: _isLoadingProfile ? 'Loading...' : '$_salesCount sale${_salesCount != 1 ? 's' : ''}',
              icon: Icons.sell_outlined,
              onTap: () async {
                await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => MySalesScreen(isMerchant: isMerchant),
                ));
                _loadProfile();
              },
            ),
            const SizedBox(height: 12),
            _buildProfileOption(
              title: 'My Orders',
              subtitle: _isLoadingProfile ? 'Loading...' : '$_ordersCount order${_ordersCount != 1 ? 's' : ''}',
              icon: Icons.shopping_bag_outlined,
              onTap: () async {
                await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyOrdersScreen()));
                _loadProfile();
              },
            ),
            const SizedBox(height: 12),
            _buildProfileOption(
              title: 'Wishlist',
              subtitle: _isLoadingProfile ? 'Loading...' : '$_wishlistCount saved item${_wishlistCount != 1 ? 's' : ''}',
              icon: Icons.favorite_outline_rounded,
              onTap: () async {
                await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WishlistScreen()));
                _loadProfile();
              },
            ),
            const SizedBox(height: 12),
            _buildProfileOption(
              title: 'Payout Methods',
              subtitle: 'Manage withdrawals',
              icon: Icons.payment_outlined,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => PayoutScreen(isMerchant: isMerchant),
              )),
            ),
            const SizedBox(height: 24),

            // Logout
            OutlinedButton.icon(
              onPressed: () async {
                final navigator = Navigator.of(context);
                await ApiService.logout();
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout, size: 16, color: AppColors.primary),
              label: const Text('Log Out',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.08)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatarCircle(String initials) {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF1F2E4E), Color(0xFF2D4270)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials.isEmpty ? 'T' : initials,
        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'Recoleta Alt'),
      ),
    );
  }





  Widget _buildProfileOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.04),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 18,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black38,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.black26,
          size: 20,
        ),
        onTap: onTap,
      ),
    );
  }

  // --- CUSTOM BOTTOM NAVIGATION BAR ---
  Widget _buildCustomBottomNavBar() {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Nav items row
          Positioned.fill(
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavBarItem(0, Icons.home_rounded, 'Home'),
                  _buildNavBarItem(1, Icons.search_rounded, 'Search'),
                  // Gap for center Sell button
                  const SizedBox(width: 72),
                  _buildNavBarItem(3, Icons.chat_bubble_outline_rounded, 'Chat'),
                  _buildNavBarItem(4, Icons.person_outline_rounded, 'Profile'),
                ],
              ),
            ),
          ),
          // Floating Sell button (center)
          Positioned(
            top: -22,
            left: 0,
            right: 0,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (_checkAuthWithPrompt(
                      title: 'Please Login',
                      message: 'Please login to list and sell your lifestyle packages.',
                    )) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AddPackageScreen(),
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F2E4E),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1F2E4E).withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Sell',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1F2E4E)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavBarItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    const activeColor = Color(0xFF1F2E4E);
    final inactiveColor = const Color(0xFF1F2E4E).withValues(alpha: 0.38);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (index == 3) {
              // Chat: show login dialog if not logged in
              if (!SessionManager.isLoggedIn) {
                _showLoginPrompt(
                  title: 'Please Login',
                  message: 'Please login to chat with sellers.',
                );
                return;
              }
            } else if (index == 4) {
              // Profile: navigate directly to login screen if not logged in
              if (!SessionManager.isLoggedIn) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
                return;
              }
            }
            setState(() => _currentIndex = index);
          },
          // opaque covers full area, not just icon pixels
          customBorder: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          child: SizedBox(
            height: 72,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    icon,
                    key: ValueKey(isSelected),
                    color: isSelected ? activeColor : inactiveColor,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? activeColor : inactiveColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPill({
    required String label,
    required String? selectedValue,
    required IconData prefixIcon,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    final hasValue = selectedValue != null && selectedValue != 'All Merchants' && selectedValue != 'All Categories' && selectedValue != 'All Types';
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(prefixIcon, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                hasValue ? selectedValue : label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 4),
              if (hasValue)
                GestureDetector(
                  onTap: () {
                    onClear();
                  },
                  child: const Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                )
              else
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dashLength;
  final double borderRadius;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.gap = 3.0,
    this.dashLength = 5.0,
    this.borderRadius = 20.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final Path path = Path()..addRRect(rrect);
    final Path dashedPath = Path();

    double distance = 0.0;
    for (final PathMetric metric in path.computeMetrics()) {
      while (distance < metric.length) {
        final double len = dashLength;
        if (distance + len > metric.length) {
          dashedPath.addPath(
            metric.extractPath(distance, metric.length),
            Offset.zero,
          );
        } else {
          dashedPath.addPath(
            metric.extractPath(distance, distance + len),
            Offset.zero,
          );
        }
        distance += len + gap;
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.borderRadius != borderRadius;
  }
}
