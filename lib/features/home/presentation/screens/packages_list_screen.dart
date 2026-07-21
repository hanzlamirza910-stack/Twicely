import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/widgets/package_image_carousel.dart';
import 'package_detail_screen.dart';

class PackagesListScreen extends StatefulWidget {
  final String? initialFilter;
  const PackagesListScreen({super.key, this.initialFilter});

  @override
  State<PackagesListScreen> createState() => _PackagesListScreenState();
}

// Maps display label → API category slug
const Map<String, String?> _filterSlugMap = {
  'All': null,
  'For Her': 'for-her',
  'For Him': 'for-him',
  'General': 'general',
  'Biz+': 'biz',
};

// Maps secondary_category slug → display label
const Map<String, String> _subcatLabels = {
  'yoga-pilates': 'Yoga & Pilates',
  'spa-massage': 'Spa & Massage',
  'beauty-nails': 'Beauty & Nails',
  'gym-fitness': 'Gym & Fitness',
  'lifestyle-classes': 'Lifestyle Classes',
};

class _PackagesListScreenState extends State<PackagesListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';
  String _selectedSort = 'Newest';
  String? _selectedSubcat;

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  List<Map<String, dynamic>> _packages = [];

  // Category counts fetched from API
  final Map<String, int> _categoryCounts = {
    'All': 0,
    'For Her': 0,
    'For Him': 0,
    'General': 0,
    'Biz+': 0,
  };

  final ScrollController _scrollController = ScrollController();

  final List<String> _filters = ['All', 'For Her', 'For Him', 'General', 'Biz+'];
  final List<String> _sorts = ['Newest', 'Price: Low to High', 'Price: High to Low', 'Discount'];

  final List<Map<String, dynamic>> _subcategories = [
    {'slug': 'yoga-pilates', 'label': 'Yoga & Pilates', 'icon': Icons.self_improvement_rounded},
    {'slug': 'spa-massage', 'label': 'Spa & Massage', 'icon': Icons.spa_rounded},
    {'slug': 'beauty-nails', 'label': 'Beauty & Nails', 'icon': Icons.face_retouching_natural},
    {'slug': 'gym-fitness', 'label': 'Gym & Fitness', 'icon': Icons.fitness_center_rounded},
    {'slug': 'lifestyle-classes', 'label': 'Lifestyle Classes', 'icon': Icons.school_rounded},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialFilter != null && _filterSlugMap.containsKey(widget.initialFilter)) {
      _selectedFilter = widget.initialFilter!;
    }
    _loadCategories();
    _fetchPackages(reset: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      if (!_isLoadingMore && _hasMore) {
        _loadMore();
      }
    }
  }

  Future<void> _loadCategories() async {
    final res = await ApiService.getPackageCategories();
    if (res['success'] == true && res['data'] != null) {
      final cats = res['data'] as List<dynamic>;
      if (!mounted) return;
      setState(() {
        int total = 0;
        for (final c in cats) {
          final slug = c['slug']?.toString() ?? '';
          final count = (c['count'] as num?)?.toInt() ?? 0;
          if (slug == 'for-her') { _categoryCounts['For Her'] = count; }
          else if (slug == 'for-him') { _categoryCounts['For Him'] = count; }
          else if (slug == 'general') { _categoryCounts['General'] = count; }
          else if (slug == 'biz') { _categoryCounts['Biz+'] = count; }
          // Only count gender/type categories toward All
          if (['for-her', 'for-him', 'general', 'biz'].contains(slug)) {
            total += count;
          }
        }
        _categoryCounts['All'] = total;
      });
    }
  }

  Future<void> _fetchPackages({bool reset = false}) async {
    if (!mounted) return;
    if (reset) {
      setState(() {
        _isLoading = true;
        _page = 1;
        _hasMore = true;
        _packages = [];
      });
    }

    final categorySlug = _filterSlugMap[_selectedFilter];
    final res = await ApiService.getPackages(
      page: _page,
      perPage: 50,
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
      category: categorySlug,
    );

    if (!mounted) return;
    if (res['success'] == true && res['data'] != null) {
      final List<dynamic> raw = res['data'];
      await ApiService.prefetchOwners(raw);
      final mapped = raw.map((p) => _mapPkg(p as Map<String, dynamic>, selectedFilter: _selectedFilter)).toList();
      setState(() {
        if (reset) {
          _packages = mapped;
        } else {
          _packages.addAll(mapped);
        }
        _isLoading = false;
        _isLoadingMore = false;
        _hasMore = mapped.length >= 50;
      });
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (!mounted || _isLoadingMore || !_hasMore) return;
    setState(() {
      _isLoadingMore = true;
      _page++;
    });
    await _fetchPackages();
  }

  void _onFilterChanged(String filter) {
    if (_selectedFilter == filter) return;
    setState(() {
      _selectedFilter = filter;
      _selectedSubcat = null;
    });
    _fetchPackages(reset: true);
  }

  void _onSearchSubmit(String val) {
    setState(() => _searchQuery = val);
    _fetchPackages(reset: true);
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

  String _buildDynamicTag(Map<String, dynamic> apiPkg, {String? selectedFilter}) {
    final List<String> mainCats = [];
    
    if (selectedFilter != null && selectedFilter != 'All') {
      mainCats.add(selectedFilter);
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

  Map<String, dynamic> _mapPkg(Map<String, dynamic> p, {String? selectedFilter}) {
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
    final subcatLabel = _subcatLabels[secondarySlug] ?? '';

    final ownerInfo = ApiService.resolveOwnerInfo(p);
    final String merchantName = ownerInfo['name'] ?? 'Twicely';
    final String merchantLogo = ownerInfo['avatar'] ?? '';

    int likesCount = int.tryParse(p['likes_count']?.toString() ?? '') ??
                     (p['likes'] != null ? int.tryParse(p['likes'].toString()) : null) ??
                     (p['id'] != null ? (p['id'].hashCode % 5) : 0);
    if (p['liked'] == true && likesCount == 0) {
      likesCount = 1;
    }

    return {
      'id': p['id'],
      'title': p['title'] ?? 'Package',
      'imageUrl': imageUrl,
      'allImages': allImages,
      'originalPrice': originalPrice,
      'resalePrice': resalePrice,
      'discountBadge': discountBadge,
      'subcategorySlug': secondarySlug,
      'subcategoryLabel': subcatLabel,
      'merchant': merchantName,
      'merchantLogo': merchantLogo,
      'currency': p['currency'] ?? 'SGD',
      'description': p['description'] ?? '',
      'validity': p['validity_date'] ?? p['valid_until'] ?? '',
      'hasHeart': p['liked'] == true,
      'likesCount': likesCount,
      'merchant_id': ownerInfo['merchant_id'],
      'owner_id': p['owner_id'],
      'owner_type': p['owner_type'],
      'category': (selectedFilter != null && selectedFilter != 'All Categories' && selectedFilter != 'All')
          ? selectedFilter
          : _getPkgTrueCategory(p),
      'tag': _buildDynamicTag(p, selectedFilter: selectedFilter),
    };
  }

  List<Map<String, dynamic>> get _displayPackages {
    var list = _packages.where((p) {
      final matchSubcat = _selectedSubcat == null || p['subcategorySlug'] == _selectedSubcat;
      return matchSubcat;
    }).toList();

    if (_selectedSort == 'Price: Low to High') {
      list.sort((a, b) => (a['resalePrice'] as double).compareTo(b['resalePrice'] as double));
    } else if (_selectedSort == 'Price: High to Low') {
      list.sort((a, b) => (b['resalePrice'] as double).compareTo(a['resalePrice'] as double));
    } else if (_selectedSort == 'Discount') {
      list.sort((a, b) {
        final aD = a['discountBadge'] != null ? int.tryParse((a['discountBadge'] as String).replaceAll('% OFF', '')) ?? 0 : 0;
        final bD = b['discountBadge'] != null ? int.tryParse((b['discountBadge'] as String).replaceAll('% OFF', '')) ?? 0 : 0;
        return bD.compareTo(aD);
      });
    }
    return list;
  }

  void _openPackage(Map<String, dynamic> pkg) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PackageDetailScreen(package: {
        'id': pkg['id'],
        'imageUrl': (pkg['imageUrl'] as String).isNotEmpty ? pkg['imageUrl'] : 'assets/images/package_spa.jpg',
        'allImages': pkg['allImages'] != null ? List<String>.from(pkg['allImages'] as Iterable) : null,
        'tag': pkg['tag'] ?? '${(pkg['category'] ?? _selectedFilter).toUpperCase()} > ${pkg['subcategoryLabel']}',
        'title': pkg['title'],
        'originalPrice': 'S\$${(pkg['originalPrice'] as double).toStringAsFixed(2)}',
        'resalePrice': 'S\$${(pkg['resalePrice'] as double).toStringAsFixed(2)}',
        'hasHeart': pkg['hasHeart'],
        'discountBadge': pkg['discountBadge'],
        'category': pkg['category'],
        'description': pkg['description'],
        'validity': pkg['validity'],
        'merchant_id': pkg['merchant_id'],
        'owner_id': pkg['owner_id'],
        'owner_type': pkg['owner_type'],
        'merchant': {'name': pkg['merchant']},
      }),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final displayed = _displayPackages;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // HEADER
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppColors.bgLight,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Container(
                color: AppColors.bgLight,
                padding: const EdgeInsets.fromLTRB(20, 68, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      'Ready to find your\nnext experience?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        height: 1.3,
                        fontFamily: 'Recoleta Alt',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Deals for him. Deals for her. Or just anyone, really. One toggle away.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // SEARCH BAR
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.bgLight,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 13, color: AppColors.primary),
                textInputAction: TextInputAction.search,
                onSubmitted: _onSearchSubmit,
                onChanged: (v) {
                  setState(() => _searchQuery = v);
                  if (v.isEmpty) { _fetchPackages(reset: true); }
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Search packages, merchants...',
                  hintStyle: TextStyle(color: AppColors.primary.withValues(alpha: 0.35), fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.primary),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                            _fetchPackages(reset: true);
                          },
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
          ),

          // GENDER FILTER CHIPS (server-side)
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.bgLight,
              padding: const EdgeInsets.only(top: 14),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: _filters.map((f) {
                    final isSelected = _selectedFilter == f;
                    final count = _categoryCounts[f] ?? 0;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => _onFilterChanged(f),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: isSelected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.12)),
                            boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))] : [],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(f, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : AppColors.primary)),
                              if (count > 0) ...[
                                const SizedBox(width: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.white.withValues(alpha: 0.25) : AppColors.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text('$count', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppColors.primary)),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          // SUBCATEGORY CHIPS (client-side refinement)
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.bgLight,
              padding: const EdgeInsets.only(top: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _buildSubcatChip(null, 'All Types', Icons.apps_rounded),
                    ..._subcategories.map((sc) => _buildSubcatChip(sc['slug'] as String, sc['label'] as String, sc['icon'] as IconData)),
                  ],
                ),
              ),
            ),
          ),

          // SORT + COUNT ROW
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isLoading ? 'Loading...' : '${displayed.length} packages found',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary.withValues(alpha: 0.5)),
                  ),
                  GestureDetector(
                    onTap: _showSortSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
                      child: Row(
                        children: [
                          const Icon(Icons.sort_rounded, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(_selectedSort, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
                          const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // GRID
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary))),
            )
          else if (displayed.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_off_rounded, size: 56, color: AppColors.primary.withValues(alpha: 0.15)),
                    const SizedBox(height: 12),
                    Text('No packages found', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary.withValues(alpha: 0.4))),
                    const SizedBox(height: 4),
                    Text('Try a different filter or search term', style: TextStyle(fontSize: 12, color: AppColors.primary.withValues(alpha: 0.3))),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    if (i >= displayed.length) {
                      return _isLoadingMore
                          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)))
                          : const SizedBox.shrink();
                    }
                    return _buildPkgCard(displayed[i]);
                  },
                  childCount: displayed.length + (_isLoadingMore ? 1 : 0),
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.70,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubcatChip(String? slug, String label, IconData icon) {
    final isSelected = _selectedSubcat == slug;
    return GestureDetector(
      onTap: () => setState(() => _selectedSubcat = isSelected ? null : slug),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.accent : Colors.black12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: isSelected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.5)),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isSelected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.6))),
          ],
        ),
      ),
    );
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: AppColors.bgLight,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Sort By', style: TextStyle(fontFamily: 'Recoleta Alt', fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 16),
            ..._sorts.map((s) => ListTile(
              dense: true,
              title: Text(s, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary, fontSize: 14)),
              trailing: _selectedSort == s ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
              onTap: () {
                setState(() => _selectedSort = s);
                Navigator.pop(context);
              },
            )),
            const SizedBox(height: 8),
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

  Widget _buildPkgCard(Map<String, dynamic> pkg) {
    final originalPrice = pkg['originalPrice'] as double;
    final resalePrice = pkg['resalePrice'] as double;
    final discount = pkg['discountBadge'] as String?;
    final imageUrl = pkg['imageUrl'] as String;
    final subcatLabel = pkg['subcategoryLabel'] as String;

    final String mainCategory = _selectedFilter == 'All' ? (pkg['category'] ?? 'General') : _selectedFilter;
    final String tagString = pkg['tag'] ?? (subcatLabel.isNotEmpty ? '$mainCategory > $subcatLabel' : mainCategory);

    return GestureDetector(
      onTap: () => _openPackage(pkg),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.08), width: 1.0),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // IMAGE
            Expanded(
              flex: 46,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14.5)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PackageImageCarousel(
                      images: pkg['allImages'] != null ? List<String>.from(pkg['allImages'] as Iterable) : [imageUrl],
                      fallbackImage: 'assets/images/package_spa.jpg',
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(14.5)),
                      onTap: () => _openPackage(pkg),
                    ),
                    if (discount != null)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF27B6E),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            discount,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // CONTENT
            Expanded(
              flex: 54,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCategoryRichText(tagString),
                    const SizedBox(height: 3),
                    SizedBox(
                      height: 32,
                      child: Text(
                        pkg['title'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E), height: 1.3),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 12,
                      child: (originalPrice > resalePrice)
                          ? Text(
                              'S\$${originalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 9, color: Color(0xFF9E9E9E), decoration: TextDecoration.lineThrough, decorationColor: Color(0xFF9E9E9E)),
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 2),
                    SizedBox(
                      height: 18,
                      child: Text(
                        'S\$${resalePrice.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF273DB7), letterSpacing: -0.2),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        _buildMerchantAvatar(pkg['merchant']?.toString(), pkg['merchantLogo']?.toString(), radius: 7),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            pkg['merchant'] ?? 'Twicely',
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Builds a merchant avatar: logo image if available, otherwise initials with
  // a consistent color derived from the merchant name hash (no pink/bright colors).
  Widget _buildMerchantAvatar(String? name, String? logoUrl, {double radius = 12}) {
    final hasLogo = logoUrl != null && logoUrl.isNotEmpty;
    final initial = (name != null && name.isNotEmpty) ? name[0].toUpperCase() : 'T';
    // Fixed brand color for Twicely, deterministic neutral palette for real merchants
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
        : (name?.toLowerCase() == 'twicely'
            ? const Color(0xFF273DB7)
            : colors[(name?.hashCode.abs() ?? 0) % colors.length]);
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
