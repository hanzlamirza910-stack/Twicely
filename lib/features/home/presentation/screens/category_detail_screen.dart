import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';
import 'package_detail_screen.dart';

class CategoryDetailScreen extends StatefulWidget {
  final String categoryName;
  final String categoryIcon;

  const CategoryDetailScreen({
    super.key,
    required this.categoryName,
    required this.categoryIcon,
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

  Map<String, dynamic> _mapApiPackage(Map<String, dynamic> apiPkg) {
    String imageUrl = 'assets/images/package_spa.jpg';
    if (apiPkg['cover_url'] != null && apiPkg['cover_url'].toString().isNotEmpty) {
      imageUrl = apiPkg['cover_url'];
    } else if (apiPkg['images'] != null && (apiPkg['images'] as List).isNotEmpty) {
      imageUrl = apiPkg['images'][0]['url'] ?? 'assets/images/package_spa.jpg';
    }

    final double originalPrice = double.tryParse(apiPkg['original_price']?.toString() ?? '') ?? 
                                 double.tryParse(apiPkg['price']?.toString() ?? '') ?? 0.0;
    final double resalePrice = double.tryParse(apiPkg['resale_price']?.toString() ?? '') ?? 
                               double.tryParse(apiPkg['price']?.toString() ?? '') ?? 0.0;

    String? discountBadge;
    if (originalPrice > 0 && resalePrice < originalPrice) {
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

    String tag = '${category.toUpperCase()} • ACTIVE';
    if (apiPkg['location'] != null) {
      tag = '${category.toUpperCase()} • ${apiPkg['location'].toString().toUpperCase()}';
    }

    return {
      'id': apiPkg['id'],
      'imageUrl': imageUrl,
      'image': imageUrl,
      'tag': tag,
      'title': apiPkg['title'] ?? 'Package Listing',
      'originalPrice': 'S\$${originalPrice.toStringAsFixed(2)}',
      'resalePrice': 'S\$${resalePrice.toStringAsFixed(2)}',
      'price': 'S\$${resalePrice.toStringAsFixed(2)}',
      'hasHeart': apiPkg['liked'] == true || apiPkg['hasHeart'] == true,
      'discountBadge': discountBadge,
      'discount': discountBadge ?? '0% OFF',
      'category': category,
      'description': apiPkg['description'] ?? '',
      'validity': apiPkg['validity_date'] ?? apiPkg['valid_until'] ?? '',
      'merchant': apiPkg['merchant'] ?? {},
    };
  }

  List<Map<String, dynamic>> get _displayPackages {
    final baseList = _apiPackages.isNotEmpty ? _apiPackages : _fallbackPackages;
    if (_searchQuery.isEmpty) return baseList;
    return baseList.where((pkg) =>
      pkg['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
      pkg['tag'].toString().toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  List<Map<String, dynamic>> get _fallbackPackages {
    return [
      {
        'id': 101,
        'title': 'Premium 5-Session Pass for ${widget.categoryName}',
        'originalPrice': 'S\$250.00',
        'resalePrice': 'S\$120.00',
        'price': 'S\$120.00',
        'discount': '52% OFF',
        'discountBadge': '52% OFF',
        'tag': 'FOR HER • ${widget.categoryName}',
        'image': 'assets/images/package_yoga.jpg',
        'imageUrl': 'assets/images/package_yoga.jpg',
        'category': widget.categoryName,
      },
      {
        'id': 102,
        'title': 'Introductory Session Package (${widget.categoryName})',
        'originalPrice': 'S\$80.00',
        'resalePrice': 'S\$45.00',
        'price': 'S\$45.00',
        'discount': '43% OFF',
        'discountBadge': '43% OFF',
        'tag': 'GENERAL • ${widget.categoryName}',
        'image': 'assets/images/package_spa.jpg',
        'imageUrl': 'assets/images/package_spa.jpg',
        'category': widget.categoryName,
      },
      {
        'id': 103,
        'title': 'Weekend Special Pass (${widget.categoryName})',
        'originalPrice': 'S\$150.00',
        'resalePrice': 'S\$90.00',
        'price': 'S\$90.00',
        'discount': '40% OFF',
        'discountBadge': '40% OFF',
        'tag': 'FOR HIM • ${widget.categoryName}',
        'image': 'assets/images/package_gym.jpg',
        'imageUrl': 'assets/images/package_gym.jpg',
        'category': widget.categoryName,
      },
    ];
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
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Image.asset(widget.categoryIcon, fit: BoxFit.contain),
                      ),
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
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search within ${widget.categoryName}...',
                      hintStyle: TextStyle(color: AppColors.primary.withValues(alpha: 0.4), fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                  ),
                ),
              ),

              // Deals List
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
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
                                child: Card(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 1,
                                  shadowColor: Colors.black.withValues(alpha: 0.1),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Package Image
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: img.startsWith('assets/')
                                              ? Image.asset(
                                                  img,
                                                  width: 90,
                                                  height: 90,
                                                  fit: BoxFit.cover,
                                                )
                                              : Image.network(
                                                  img,
                                                  width: 90,
                                                  height: 90,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) => Container(
                                                    width: 90,
                                                    height: 90,
                                                    color: AppColors.primary.withValues(alpha: 0.05),
                                                    child: const Icon(Icons.image, color: AppColors.primary),
                                                  ),
                                                ),
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
                                                  Text(
                                                    (pkg['tag'] as String).toUpperCase(),
                                                    style: const TextStyle(
                                                      fontSize: 8,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFFF27B6E),
                                                    ),
                                                  ),
                                                  if (pkg['discount'] != null || pkg['discountBadge'] != null)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFFFF176),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        (pkg['discount'] ?? pkg['discountBadge']) as String,
                                                        style: const TextStyle(
                                                          fontSize: 8,
                                                          fontWeight: FontWeight.bold,
                                                          color: AppColors.primary,
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
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Row(
                                                children: [
                                                  Text(
                                                    pkg['originalPrice'] as String,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.black38,
                                                      decoration: TextDecoration.lineThrough,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    pkg['resalePrice'] as String,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w900,
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                                ],
                                              )
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
}
