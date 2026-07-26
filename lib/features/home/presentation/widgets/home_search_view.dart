import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/session_manager.dart';
import '../../../../core/widgets/app_search_bar.dart';
import '../../../../core/widgets/marketplace_package_card.dart';
import '../../../../core/widgets/shimmer_effect.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/shopping_cart_screen.dart';

class HomeSearchView extends StatefulWidget {
  final Function(Map<String, dynamic> package) onPackageTap;
  final VoidCallback? onProfileTap;

  const HomeSearchView({
    super.key,
    required this.onPackageTap,
    this.onProfileTap,
  });

  @override
  State<HomeSearchView> createState() => _HomeSearchViewState();
}

class _HomeSearchViewState extends State<HomeSearchView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _searchPackages = [];
  bool _isLoading = false;

  String _selectedMerchant = 'All Merchants';
  String _selectedCategory = 'All Categories';
  String? _selectedSubcat;
  String _selectedSort = 'Sort: Price Low to High';

  final List<String> _categories = [
    'All Categories',
    'For Her',
    'For Him',
    'Biz+',
    'General',
  ];

  final List<String> _sortOptions = [
    'Sort: Price Low to High',
    'Sort: Price High to Low',
  ];

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
    _fetchPackages();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPackages() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      if (SessionManager.isLoggedIn) {
        await ApiService.getUserWishlist();
      }
      final res = await ApiService.getPackages(perPage: 100);
      if (!mounted) return;
      if (res['success'] == true && res['data'] != null) {
        final List<dynamic> raw = res['data'];
        await ApiService.prefetchOwners(raw);
        if (!mounted) return;
        final mapped = raw.map((p) => _mapPackage(p as Map<String, dynamic>)).toList();
        setState(() {
          _searchPackages = mapped;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _mapPackage(Map<String, dynamic> p) {
    String imageUrl = 'assets/images/package_spa.jpg';
    if (p['cover_url'] != null && p['cover_url'].toString().isNotEmpty) {
      imageUrl = p['cover_url'];
    } else if (p['images'] != null && (p['images'] as List).isNotEmpty) {
      imageUrl = (p['images'] as List)[0]['url']?.toString() ?? 'assets/images/package_spa.jpg';
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

    final double basePrice = double.tryParse(p['price']?.toString() ?? '') ?? 0.0;
    final double discPrice = double.tryParse(p['discounted_price']?.toString() ?? '') ?? 0.0;
    final bool hasDiscount = discPrice > 0 && discPrice < basePrice;
    final double originalPrice = basePrice;
    final double resalePrice = hasDiscount ? discPrice : basePrice;

    String? discountBadge;
    if (hasDiscount) {
      final pct = ((originalPrice - resalePrice) / originalPrice * 100).round();
      if (pct > 0) discountBadge = '$pct% OFF';
    }

    final ownerInfo = ApiService.resolveOwnerInfo(p);
    final String merchantName = ownerInfo['name'] ?? 'Twicely';
    final String merchantLogo = ownerInfo['avatar'] ?? '';

    return {
      'id': p['id'],
      'title': ApiService.unescapeHtml(p['title']?.toString() ?? 'Package'),
      'imageUrl': imageUrl,
      'allImages': allImages,
      'originalPrice': 'S\$${originalPrice.toStringAsFixed(2)}',
      'resalePrice': 'S\$${resalePrice.toStringAsFixed(2)}',
      'originalPriceVal': originalPrice,
      'resalePriceVal': resalePrice,
      'discountBadge': discountBadge,
      'hasHeart': p['liked'] == true || p['hasHeart'] == true || (p['id'] != null && ApiService.wishlistIdsCache.contains(int.tryParse(p['id'].toString()))),
      'liked': p['liked'] == true || p['hasHeart'] == true || (p['id'] != null && ApiService.wishlistIdsCache.contains(int.tryParse(p['id'].toString()))),
      'merchant': ApiService.unescapeHtml(merchantName),
      'merchantName': ApiService.unescapeHtml(merchantName),
      'merchantLogo': merchantLogo,
      'merchant_id': ownerInfo['merchant_id'],
      'owner_id': p['owner_id'],
      'category': p['category'] ?? 'General',
      'secondaryCategory': p['secondary_category'] ?? '',
      'tag': p['tag'] ?? 'General',
    };
  }

  double _parsePrice(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    final clean = val.toString().replaceAll(r'S$', '').replaceAll(r'$', '').trim();
    return double.tryParse(clean) ?? 0.0;
  }

  List<Map<String, dynamic>> get _filteredPackages {
    List<Map<String, dynamic>> res = List.from(_searchPackages);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      res = res.where((pkg) =>
          pkg['title'].toString().toLowerCase().contains(q) ||
          pkg['tag'].toString().toLowerCase().contains(q) ||
          pkg['category'].toString().toLowerCase().contains(q)).toList();
    }

    if (_selectedMerchant != 'All Merchants') {
      res = res.where((pkg) {
        final mName = pkg['merchantName']?.toString() ?? pkg['merchant']?.toString() ?? '';
        return mName.toLowerCase() == _selectedMerchant.toLowerCase();
      }).toList();
    }

    if (_selectedCategory != 'All Categories') {
      res = res.where((pkg) {
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

    if (_selectedSort == 'Sort: Price Low to High') {
      res.sort((a, b) => _parsePrice(a['resalePriceVal'] ?? a['resalePrice']).compareTo(_parsePrice(b['resalePriceVal'] ?? b['resalePrice'])));
    } else if (_selectedSort == 'Sort: Price High to Low') {
      res.sort((a, b) => _parsePrice(b['resalePriceVal'] ?? b['resalePrice']).compareTo(_parsePrice(a['resalePriceVal'] ?? a['resalePrice'])));
    }

    return res;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredPackages;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Bar
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
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 26),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ShoppingCartScreen()),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      if (SessionManager.isLoggedIn) {
                        widget.onProfileTap?.call();
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

        // Body
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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

                // Reusable AppSearchBar Widget
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: AppSearchBar(
                    controller: _searchController,
                    hintText: 'Search packages by name...',
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Filter Pills
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: SingleChildScrollView(
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
                            setState(() => _selectedMerchant = 'All Merchants');
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildFilterPill(
                          label: 'Category',
                          selectedValue: _selectedCategory,
                          prefixIcon: Icons.category_outlined,
                          onTap: _showCategoryFilter,
                          onClear: () {
                            setState(() => _selectedCategory = 'All Categories');
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildFilterPill(
                          label: 'Subcategory',
                          selectedValue: _selectedSubcat != null ? _subcatLabels[_selectedSubcat!] : null,
                          prefixIcon: Icons.layers_outlined,
                          onTap: _showSubcatFilter,
                          onClear: () {
                            setState(() => _selectedSubcat = null);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Header Results Count & Sort Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isLoading ? 'Searching...' : '${filtered.length} Results Found',
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

                // Results Grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: _isLoading
                      ? GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.78,
                          ),
                          itemCount: 6,
                          itemBuilder: (context, index) => const PackageCardSkeleton(),
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
                                childAspectRatio: 0.78,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final pkg = filtered[index];
                                return MarketplacePackageCard(
                                  package: pkg,
                                  isFavorite: pkg['hasHeart'] == true,
                                  onTap: () => widget.onPackageTap(pkg),
                                );
                              },
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

  Widget _buildFilterPill({
    required String label,
    String? selectedValue,
    required IconData prefixIcon,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    final isSelected = selectedValue != null && selectedValue != 'All Merchants' && selectedValue != 'All Categories';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.black.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(prefixIcon, size: 14, color: isSelected ? Colors.white : AppColors.primary),
            const SizedBox(width: 6),
            Text(
              isSelected ? selectedValue : label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.primary,
              ),
            ),
            const SizedBox(width: 4),
            if (isSelected)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
              )
            else
              Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: isSelected ? Colors.white : AppColors.primary),
          ],
        ),
      ),
    );
  }

  void _showMerchantFilter() {
    final merchants = ['All Merchants', ..._searchPackages.map((p) => p['merchantName']?.toString() ?? 'Twicely').toSet()];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Merchant', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: merchants.length,
                itemBuilder: (context, index) {
                  final m = merchants[index];
                  return ListTile(
                    title: Text(m),
                    trailing: _selectedMerchant == m ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                    onTap: () {
                      setState(() => _selectedMerchant = m);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 12),
            ..._categories.map((c) => ListTile(
                  title: Text(c),
                  trailing: _selectedCategory == c ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                  onTap: () {
                    setState(() => _selectedCategory = c);
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showSubcatFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Subcategory', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 12),
            ListTile(
              title: const Text('All Subcategories'),
              trailing: _selectedSubcat == null ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
              onTap: () {
                setState(() => _selectedSubcat = null);
                Navigator.pop(context);
              },
            ),
            ..._subcatLabels.entries.map((e) => ListTile(
                  title: Text(e.value),
                  trailing: _selectedSubcat == e.key ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                  onTap: () {
                    setState(() => _selectedSubcat = e.key);
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showSortFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sort By', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 12),
            ..._sortOptions.map((s) => ListTile(
                  title: Text(s.replaceAll('Sort: ', '')),
                  trailing: _selectedSort == s ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                  onTap: () {
                    setState(() => _selectedSort = s);
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }
}
