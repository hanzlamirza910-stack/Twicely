import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/widgets/custom_snackbar.dart';

class AddPackageScreen extends StatefulWidget {
  final Map<String, dynamic>? packageToEdit;
  final Function(Map<String, dynamic>)? onPackageAdded;
  final Function(Map<String, dynamic>)? onPackageUpdated;

  const AddPackageScreen({
    super.key,
    this.packageToEdit,
    this.onPackageAdded,
    this.onPackageUpdated,
  });

  @override
  State<AddPackageScreen> createState() => _AddPackageScreenState();
}

class _AddPackageScreenState extends State<AddPackageScreen> {
  int _currentStep = 1; // 1, 2, 3
  final _formKey = GlobalKey<FormState>();

  // Form Fields State
  String _selectedMerchant = '';
  final List<String> _galleryImages = [];
  String _receiptFileName = '';
  
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _shortDescriptionController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final List<String> _keyPoints = [];
  String _primaryCategory = '';
  String _secondaryCategory = '';
  String _packageStatus = 'draft'; // draft | pending | published

  final TextEditingController _originalPriceController = TextEditingController();
  final TextEditingController _sellingPriceController = TextEditingController();
  final TextEditingController _sessionsToSellController = TextEditingController();
  final TextEditingController _totalSessionsController = TextEditingController();

  final TextEditingController _validityDaysController = TextEditingController(text: '365');
  final TextEditingController _remainingDaysController = TextEditingController(text: '180');
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 365));

  // Dynamic Data Loading State
  List<Map<String, dynamic>> _apiMerchants = [];
  List<Map<String, dynamic>> _apiCategories = [];
  List<Map<String, dynamic>> _primaryCategories = [];
  List<Map<String, dynamic>> _secondaryCategories = [];
  bool _isLoadingData = false;

  static const Map<int, String> _merchantLogoOverrides = {
    3: 'https://staging.twicely.sg/wp-content/uploads/2025/11/sysnvolv-1-150x150.png',
    13: 'https://staging.twicely.sg/wp-content/uploads/2026/03/cropped-favicon-removebg-preview-150x150.webp',
    14: 'https://staging.twicely.sg/wp-content/uploads/2026/03/images-150x150.jpeg',
  };

  static const List<Map<String, String>> _primaryFallback = [
    {'name': 'For Her', 'slug': 'for-her'},
    {'name': 'For Him', 'slug': 'for-him'},
    {'name': 'General', 'slug': 'general'},
    {'name': 'Biz+', 'slug': 'biz'},
  ];

  static const List<Map<String, String>> _secondaryFallback = [
    {'name': 'Yoga & Pilates', 'slug': 'yoga-pilates'},
    {'name': 'Spa & Massage', 'slug': 'spa-massage'},
    {'name': 'Beauty & Nails', 'slug': 'beauty-nails'},
    {'name': 'Gym & Fitness', 'slug': 'gym-fitness'},
    {'name': 'Lifestyle Classes', 'slug': 'lifestyle-classes'},
  ];

  final List<String> _fallbackMerchants = ['Synvolv', 'Tagpools', 'test test dfrnt'];

  @override
  void initState() {
    super.initState();
    _loadMerchantsAndCategories();
    if (widget.packageToEdit != null) {
      final pkg = widget.packageToEdit!;
      _titleController.text = pkg['title']?.toString() ?? '';
      _shortDescriptionController.text = pkg['short_description']?.toString() ?? '';
      _descriptionController.text = pkg['content']?.toString() ?? pkg['description']?.toString() ?? '';
      _packageStatus = pkg['status']?.toString().toLowerCase() == 'published' ? 'published'
          : pkg['status']?.toString().toLowerCase() == 'pending' ? 'pending'
          : 'draft';
      
      final origPrice = pkg['original_purchase_price'] ?? pkg['original_price'] ?? pkg['originalPrice'];
      final resPrice = pkg['resale_price'] ?? pkg['price'] ?? pkg['resalePrice'];
      
      _originalPriceController.text = origPrice?.toString() ?? '';
      _sellingPriceController.text = resPrice?.toString() ?? '';
      _sessionsToSellController.text = pkg['sessions_to_sell']?.toString() ?? '';
      _totalSessionsController.text = pkg['total_sessions']?.toString() ?? '';
      _validityDaysController.text = pkg['total_validity_days']?.toString() ?? pkg['validity_days']?.toString() ?? '365';
      _remainingDaysController.text = pkg['remaining_validity_days']?.toString() ?? pkg['remaining_days']?.toString() ?? '180';

      if (pkg['availability_end'] != null) {
        try {
          _expiryDate = DateTime.tryParse(pkg['availability_end'].toString()) ?? _expiryDate;
        } catch (_) {}
      } else if (pkg['expiry_date'] != null) {
        try {
          _expiryDate = DateTime.tryParse(pkg['expiry_date'].toString()) ?? _expiryDate;
        } catch (_) {}
      }

      if (pkg['category'] != null) {
        if (pkg['category'] is Map) {
          _primaryCategory = pkg['category']['slug']?.toString() ?? '';
        } else {
          _primaryCategory = pkg['category'].toString();
        }
      } else if (pkg['categories'] != null && pkg['categories'] is List) {
        for (var cat in pkg['categories']) {
          if (cat is Map) {
            final slug = cat['slug']?.toString() ?? '';
            if (slug == 'for-her' || slug == 'for-him' || slug == 'general' || slug == 'biz') {
              _primaryCategory = slug;
              break;
            }
          }
        }
      }
      
      if (pkg['secondary_category'] != null) {
        if (pkg['secondary_category'] is Map) {
          _secondaryCategory = pkg['secondary_category']['slug']?.toString() ?? '';
        } else {
          _secondaryCategory = pkg['secondary_category'].toString();
        }
      } else if (pkg['categories'] != null && pkg['categories'] is List) {
        for (var cat in pkg['categories']) {
          if (cat is Map) {
            final slug = cat['slug']?.toString() ?? '';
            if (slug == 'yoga-pilates' || slug == 'spa-massage' || slug == 'beauty-nails' || slug == 'gym-fitness' || slug == 'lifestyle-classes') {
              _secondaryCategory = slug;
              break;
            }
          }
        }
      }

      _selectedMerchant = pkg['merchant_name']?.toString() ?? pkg['merchant']?.toString() ?? '';

      if (pkg['key_points'] != null) {
        try {
          _keyPoints.addAll(List<String>.from(pkg['key_points'] as List));
        } catch (_) {}
      }

      if (pkg['images'] != null && pkg['images'] is List) {
        for (var img in pkg['images']) {
          if (img is Map && img['url'] != null) {
            _galleryImages.add(img['url']);
          } else if (img is String) {
            _galleryImages.add(img);
          }
        }
      } else if (pkg['cover_url'] != null) {
        _galleryImages.add(pkg['cover_url']);
      }
    }
  }

  Future<void> _loadMerchantsAndCategories() async {
    if (!mounted) return;
    setState(() => _isLoadingData = true);
    try {
      final merchantRes = await ApiService.getMerchants();
      final categoryRes = await ApiService.getPackageCategories();

      if (!mounted) return;

      List<Map<String, dynamic>> loadedMerchants = [];
      if (merchantRes['success'] == true && merchantRes['data'] != null) {
        final List<dynamic> list = merchantRes['data'];
        loadedMerchants = list
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }

      List<Map<String, dynamic>> loadedCategories = [];
      if (categoryRes['success'] == true && categoryRes['data'] != null) {
        final List<dynamic> list = categoryRes['data'];
        loadedCategories = list.map((item) => Map<String, dynamic>.from(item)).toList();
      }

      setState(() {
        _apiMerchants = loadedMerchants;
        _apiCategories = loadedCategories;
        _isLoadingData = false;

        // If we are editing, map merchant_id to merchant name if _selectedMerchant is empty
        if (widget.packageToEdit != null && (_selectedMerchant.isEmpty || _selectedMerchant == 'null')) {
          final editPkg = widget.packageToEdit!;
          final editMerchantId = editPkg['merchant_id'] is int
              ? editPkg['merchant_id']
              : int.tryParse(editPkg['merchant_id']?.toString() ?? '');
          if (editMerchantId != null) {
            final matchedMerchant = loadedMerchants.firstWhere(
              (m) => (m['id'] is int ? m['id'] : int.tryParse(m['id']?.toString() ?? '')) == editMerchantId,
              orElse: () => <String, dynamic>{},
            );
            if (matchedMerchant.isNotEmpty) {
              _selectedMerchant = matchedMerchant['business_name']?.toString() ?? matchedMerchant['name']?.toString() ?? '';
              debugPrint('[DEBUG] Mapped merchant_id $editMerchantId to merchant name: $_selectedMerchant');
            }
          }
        }
        
        // Populate primary/secondary lists based on slugs
        _primaryCategories = _apiCategories.where((cat) {
          final slug = cat['slug']?.toString() ?? '';
          return slug == 'for-her' || slug == 'for-him' || slug == 'general' || slug == 'biz';
        }).toList();

        _secondaryCategories = _apiCategories.where((cat) {
          final slug = cat['slug']?.toString() ?? '';
          return slug == 'yoga-pilates' || slug == 'spa-massage' || slug == 'beauty-nails' || slug == 'gym-fitness' || slug == 'lifestyle-classes';
        }).toList();
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  void _showCustomMerchantDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Custom Merchant',
          style: TextStyle(fontFamily: 'Recoleta Alt', fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'If your merchant is not in our partner list, type their name below to add them.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'e.g. Active Fitness Center',
                hintStyle: TextStyle(color: AppColors.primary.withValues(alpha: 0.35)),
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  final customMerchant = {
                    'id': -1,
                    'business_name': name,
                    'logo_url': '',
                  };
                  _apiMerchants.add(customMerchant);
                  _selectedMerchant = name;
                });
              }
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1F2E4E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Add & Select', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildMerchantDropdownItem(Map<String, dynamic> merchant) {
    final name = merchant['business_name']?.toString() ?? merchant['name']?.toString() ?? '';
    final id = merchant['id'] as int?;
    
    String? logoUrl = merchant['logo_url']?.toString();
    if (logoUrl == null || logoUrl.isEmpty) {
      if (id != null && _merchantLogoOverrides.containsKey(id)) {
        logoUrl = _merchantLogoOverrides[id];
      }
    }

    final initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';

    final colorsHash = name.hashCode.abs();
    final List<Color> avatarColors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFEC4899), // Pink
      const Color(0xFF10B981), // Emerald/Teal
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF3B82F6), // Blue
    ];
    final avatarColor = avatarColors[colorsHash % avatarColors.length];

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: logoUrl == null || logoUrl.isEmpty ? avatarColor : Colors.white,
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: logoUrl != null && logoUrl.isNotEmpty
                ? Image.network(
                    logoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  )
                : Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          name,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _shortDescriptionController.dispose();
    _descriptionController.dispose();
    _originalPriceController.dispose();
    _sellingPriceController.dispose();
    _sessionsToSellController.dispose();
    _totalSessionsController.dispose();
    _validityDaysController.dispose();
    _remainingDaysController.dispose();
    super.dispose();
  }

  // Dynamic calculations for summary card
  double get _calculatedTotalSellingPrice {
    final sellingPrice = double.tryParse(_sellingPriceController.text) ?? 0.0;
    final sessions = double.tryParse(_sessionsToSellController.text) ?? 1.0;
    return sellingPrice * (sessions > 0 ? sessions : 1.0);
  }

  void _nextStep() {
    if (_currentStep == 1) {
      if (_selectedMerchant.isEmpty) {
        _showToast('Please select a merchant', type: SnackBarType.warning);
        return;
      }
      setState(() => _currentStep = 2);
    } else if (_currentStep == 2) {
      if (_titleController.text.trim().isEmpty) {
        _showToast('Package title is required', type: SnackBarType.warning);
        return;
      }
      if (_primaryCategory.isEmpty) {
        _showToast('Please select a primary category', type: SnackBarType.warning);
        return;
      }
      setState(() => _currentStep = 3);
    }
  }

  void _prevStep() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _showToast(String message, {SnackBarType type = SnackBarType.info}) {
    CustomSnackBar.show(
      context,
      message: message,
      type: type,
    );
  }

  void _submitForm() async {
    final originalPriceStr = _originalPriceController.text;
    final sellingPriceStr = _sellingPriceController.text;

    if (sellingPriceStr.isEmpty) {
      _showToast('Please enter the selling price', type: SnackBarType.warning);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
      ),
    );

    // Build categories list from primary + secondary slugs
    final List<String> categoryList = [];
    if (_primaryCategory.isNotEmpty) categoryList.add(_primaryCategory);
    if (_secondaryCategory.isNotEmpty) categoryList.add(_secondaryCategory);

    // Build payload using correct API field names
    final payload = <String, dynamic>{
      'package_title': _titleController.text.trim(),
      'short_description': _shortDescriptionController.text.trim(),
      'package_price': double.tryParse(sellingPriceStr) ?? 0.0,
      'discounted_price': double.tryParse(sellingPriceStr) ?? 0.0,
      'currency': 'SGD',
      'availability_end': '${_expiryDate.year}-${_expiryDate.month.toString().padLeft(2,'0')}-${_expiryDate.day.toString().padLeft(2,'0')}',
      'key_points': _keyPoints,
      'status': _packageStatus,
    };

    // Optional fields — only include when non-empty
    if (_descriptionController.text.trim().isNotEmpty) {
      payload['content'] = _descriptionController.text.trim();
    }
    if (originalPriceStr.isNotEmpty) {
      payload['original_purchase_price'] = double.tryParse(originalPriceStr) ?? 0.0;
    }
    if (categoryList.isNotEmpty) {
      payload['categories'] = categoryList;
    }
    if (_secondaryCategory.isNotEmpty) {
      payload['secondary_category'] = _secondaryCategory;
    }
    if (_sessionsToSellController.text.isNotEmpty) {
      payload['sessions_to_sell'] = int.tryParse(_sessionsToSellController.text);
    }
    if (_totalSessionsController.text.isNotEmpty) {
      payload['total_sessions'] = int.tryParse(_totalSessionsController.text);
    }
    if (_validityDaysController.text.isNotEmpty) {
      payload['total_validity_days'] = int.tryParse(_validityDaysController.text);
    }
    if (_remainingDaysController.text.isNotEmpty) {
      payload['remaining_validity_days'] = int.tryParse(_remainingDaysController.text);
    }
    // Resolve merchant_id from name
    final matchedMerchant = _apiMerchants.firstWhere(
      (m) => m['business_name']?.toString() == _selectedMerchant || m['name']?.toString() == _selectedMerchant,
      orElse: () => <String, dynamic>{},
    );
    if (matchedMerchant.isNotEmpty && matchedMerchant['id'] != null) {
      payload['merchant_id'] = matchedMerchant['id'] is int
          ? matchedMerchant['id']
          : int.tryParse(matchedMerchant['id'].toString());
    }

    final isEditing = widget.packageToEdit != null;
    final res = isEditing
        ? await ApiService.updatePackage(
            widget.packageToEdit!['id'] is int ? widget.packageToEdit!['id'] : int.parse(widget.packageToEdit!['id'].toString()),
            payload,
          )
        : await ApiService.createPackage(payload);

    if (!mounted) return;
    Navigator.of(context).pop(); // pop spinner

    if (res['success'] == true) {
      final createdPkg = res['data'] ?? {};
      final localPkg = _mapApiPackageForLocal(createdPkg, sellingPriceStr);

      if (isEditing) {
        if (widget.onPackageUpdated != null) {
          widget.onPackageUpdated!(localPkg);
        }
        CustomSnackBar.show(
          context,
          message: 'Package updated successfully',
          type: SnackBarType.success,
        );
        Navigator.of(context).pop(true);
      } else {
        if (widget.onPackageAdded != null) {
          widget.onPackageAdded!(localPkg);
        }

        showModalBottomSheet(
          context: context,
          isDismissible: false,
          enableDrag: false,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          backgroundColor: Colors.white,
          builder: (context) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 48),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Package Submitted!',
                    style: TextStyle(
                      fontFamily: 'Recoleta Alt',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your package is currently pending admin verification. You can track its status under My Packages.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary.withValues(alpha: 0.6),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // close bottom sheet
                        Navigator.of(context).pop(true); // return true to refresh
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1F2E4E),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text(
                        'Back to Dashboard',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } else {
      _showToast('Failed to save package: ${res['message']}', type: SnackBarType.error);
    }
  }

  Map<String, dynamic> _mapApiPackageForLocal(Map<String, dynamic> apiPkg, String fallbackSellingPrice) {
    String imageUrl = 'assets/images/package_spa.jpg';
    if (apiPkg['cover_url'] != null && apiPkg['cover_url'].toString().isNotEmpty) {
      imageUrl = apiPkg['cover_url'];
    } else if (apiPkg['images'] != null && (apiPkg['images'] as List).isNotEmpty) {
      imageUrl = apiPkg['images'][0]['url'] ?? 'assets/images/package_spa.jpg';
    }

    final double priceVal = double.tryParse(apiPkg['price']?.toString() ?? '') ?? double.tryParse(fallbackSellingPrice) ?? 0.0;

    String category = 'General';
    if (apiPkg['category'] != null) {
      if (apiPkg['category'] is Map) {
        category = apiPkg['category']['name']?.toString() ?? 'General';
      } else {
        category = apiPkg['category'].toString();
      }
    }

    final result = Map<String, dynamic>.from(apiPkg);
    result['id'] = apiPkg['id'] ?? widget.packageToEdit?['id'];
    result['title'] = apiPkg['title'] ?? _titleController.text;
    result['category'] = category;
    result['price'] = priceVal.toStringAsFixed(2);
    result['status'] = (apiPkg['status']?.toString().toUpperCase() ?? 'PUBLISHED');
    result['badge'] = (apiPkg['status']?.toString().toUpperCase() ?? 'ACTIVE');
    result['image'] = imageUrl;
    result['imageUrl'] = imageUrl;
    result['createdAt'] = apiPkg['date_created']?.toString() ?? apiPkg['created_at']?.toString() ?? apiPkg['date']?.toString() ?? '';
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
        onPressed: _prevStep,
      ),
      title: Text(
        widget.packageToEdit != null ? 'Edit Package' : 'Add New Package',
        style: const TextStyle(
          color: AppColors.primary,
          fontFamily: 'Recoleta Alt',
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        if (_isLoadingData)
          const LinearProgressIndicator(
            minHeight: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            backgroundColor: Colors.transparent,
          ),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStepIndicator(),
                  const SizedBox(height: 24),
                  _buildStepContent(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    String stepTitle = '';
    double progress = 0.33;

    if (_currentStep == 1) {
      stepTitle = 'Media & Merchant';
      progress = 0.33;
    } else if (_currentStep == 2) {
      stepTitle = 'Package Information';
      progress = 0.66;
    } else {
      stepTitle = 'Finalizing Details';
      progress = 1.0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'STEP $_currentStep OF 3',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: Color(0xFF1F2E4E),
              ),
            ),
            Text(
              stepTitle,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.primary.withValues(alpha: 0.08),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1F2E4E)),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      default:
        return Container();
    }
  }

  // --- STEP 1: MEDIA & MERCHANT ---
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Merchant Label and "Not in the list"
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader('Select Merchant *'),
            GestureDetector(
              onTap: _showCustomMerchantDialog,
              child: const Text(
                'Not in the list',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFBBD03),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              key: ValueKey(_selectedMerchant),
              // ignore: deprecated_member_use
              value: (_apiMerchants.any((m) => (m['business_name'] == _selectedMerchant || m['name'] == _selectedMerchant)) || _fallbackMerchants.contains(_selectedMerchant))
                  ? (_selectedMerchant.isEmpty ? null : _selectedMerchant)
                  : null,
              hint: Text(
                _isLoadingData ? 'Loading merchants...' : 'Select a merchant...',
                style: TextStyle(color: AppColors.primary.withValues(alpha: 0.4), fontSize: 14),
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              items: _apiMerchants.isNotEmpty
                  ? _apiMerchants.map((merchant) {
                      final name = merchant['business_name']?.toString() ?? merchant['name']?.toString() ?? '';
                      return DropdownMenuItem<String>(
                        value: name,
                        child: _buildMerchantDropdownItem(merchant),
                      );
                    }).toList()
                  : _fallbackMerchants.map((name) {
                      return DropdownMenuItem<String>(
                        value: name,
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF8B5CF6),
                              ),
                              child: Center(
                                child: Text(
                                  name.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(name, style: const TextStyle(fontSize: 14, color: AppColors.primary)),
                          ],
                        ),
                      );
                    }).toList(),
              onChanged: (val) {
                setState(() => _selectedMerchant = val ?? '');
              },
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Gallery Images Card
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader('Gallery Images (${_galleryImages.length}/5)'),
            Text(
              'Upload up to 5 images (max 5MB each)',
              style: TextStyle(fontSize: 9, color: AppColors.primary.withValues(alpha: 0.4)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildUploadDottedBox(
          icon: Icons.add_photo_alternate_outlined,
          label: 'Add Image',
          onTap: () {
            if (_galleryImages.length >= 5) {
              _showToast('Maximum 5 images allowed', type: SnackBarType.warning);
              return;
            }
            // Simulate adding a mock image path
            setState(() {
              _galleryImages.add('assets/images/package_spa.jpg');
            });
            _showToast('Mock image added to gallery', type: SnackBarType.success);
          },
        ),
        if (_galleryImages.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 64,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _galleryImages.length,
              itemBuilder: (context, index) => Container(
                margin: const EdgeInsets.only(right: 10),
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  image: DecorationImage(
                    image: AssetImage(_galleryImages[index]),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _galleryImages.removeAt(index));
                    },
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(Icons.close, color: Colors.white, size: 14),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),

        // Submission Receipt Card
        _buildSectionHeader('Submission Receipt*'),
        const Text(
          'Upload a receipt or proof of purchase for admin verification.',
          style: TextStyle(fontSize: 11, color: Colors.black45),
        ),
        const SizedBox(height: 12),

        // Alert bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF3E5F5), // Light purple alert
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, size: 16, color: Colors.purple),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Receipt is required to complete your package submission.',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purple),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        _buildUploadDottedBox(
          icon: Icons.receipt_long_outlined,
          label: _receiptFileName.isEmpty ? 'Click to browse PDF, JPG or PNG' : _receiptFileName,
          onTap: () {
            setState(() {
              _receiptFileName = 'receipt_invoice_591.pdf';
            });
            _showToast('Mock receipt uploaded successfully', type: SnackBarType.success);
          },
        ),
      ],
    );
  }

  // --- STEP 2: PACKAGE INFORMATION ---
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title Input
        _buildSectionHeader('Package Title *'),
        _buildInputField(
          controller: _titleController,
          hintText: 'e.g., Luxury Wellness Weekend Retreat',
          maxLines: 1,
        ),
        const SizedBox(height: 20),

        // Short Description Input
        _buildSectionHeader('Short Description'),
        _buildInputField(
          controller: _shortDescriptionController,
          hintText: 'Brief summary (shown in listing cards)...',
          maxLines: 2,
        ),
        const SizedBox(height: 20),

        // Package Description Input
        _buildSectionHeader('Package Description'),
        _buildInputField(
          controller: _descriptionController,
          hintText: 'Describe the experience, value proposition, and unique features...',
          maxLines: 5,
        ),
        const SizedBox(height: 24),

        // Key Points (0/5)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader('Key Points (${_keyPoints.length}/5)'),
            Text(
              'Highlight what\'s included',
              style: TextStyle(fontSize: 10, color: AppColors.primary.withValues(alpha: 0.4)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _keyPoints.isEmpty
            ? Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.08)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline_rounded, size: 16, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                      'No key points added yet.',
                      style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )
            : Column(
                children: _keyPoints.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final pt = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.06)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xFF1F2E4E), size: 14),
                        const SizedBox(width: 8),
                        Expanded(child: Text(pt, style: const TextStyle(fontSize: 12))),
                        GestureDetector(
                          onTap: () => setState(() => _keyPoints.removeAt(idx)),
                          child: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _showAddKeyPointDialog,
          icon: const Icon(Icons.add, size: 16, color: Color(0xFF1F2E4E)),
          label: const Text('Add Key Point', style: TextStyle(color: Color(0xFF1F2E4E), fontWeight: FontWeight.bold)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            side: const BorderSide(color: Color(0xFF1F2E4E)),
          ),
        ),
        const SizedBox(height: 24),

        // Categories
        _buildSectionHeader('Categories'),
        // Primary
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              key: ValueKey(_primaryCategory),
              // ignore: deprecated_member_use
              value: (_primaryCategories.any((c) => c['slug'] == _primaryCategory) || _primaryFallback.any((c) => c['slug'] == _primaryCategory))
                  ? (_primaryCategory.isEmpty ? null : _primaryCategory)
                  : null,
              hint: const Text('Primary Category', style: TextStyle(fontSize: 13, color: Colors.black38)),
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              items: _primaryCategories.isNotEmpty
                  ? _primaryCategories.map((c) {
                      return DropdownMenuItem(
                        value: c['slug']?.toString(),
                        child: Text(c['name']?.toString() ?? '', style: const TextStyle(fontSize: 13)),
                      );
                    }).toList()
                  : _primaryFallback.map((c) {
                      return DropdownMenuItem(
                        value: c['slug'],
                        child: Text(c['name']!, style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
              onChanged: (val) => setState(() => _primaryCategory = val ?? ''),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Secondary
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              key: ValueKey(_secondaryCategory),
              // ignore: deprecated_member_use
              value: (_secondaryCategories.any((c) => c['slug'] == _secondaryCategory) || _secondaryFallback.any((c) => c['slug'] == _secondaryCategory))
                  ? (_secondaryCategory.isEmpty ? null : _secondaryCategory)
                  : null,
              hint: const Text('Secondary Category (Optional)', style: TextStyle(fontSize: 13, color: Colors.black38)),
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              items: _secondaryCategories.isNotEmpty
                  ? _secondaryCategories.map((c) {
                      return DropdownMenuItem(
                        value: c['slug']?.toString(),
                        child: Text(c['name']?.toString() ?? '', style: const TextStyle(fontSize: 13)),
                      );
                    }).toList()
                  : _secondaryFallback.map((c) {
                      return DropdownMenuItem(
                        value: c['slug'],
                        child: Text(c['name']!, style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
              onChanged: (val) => setState(() => _secondaryCategory = val ?? ''),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddKeyPointDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Key Point', style: TextStyle(fontFamily: 'Recoleta Alt', fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'e.g. 1-Hour massage session included'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.black45)),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _keyPoints.add(controller.text.trim());
                });
              }
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- STEP 3: FINALIZING DETAILS ---
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Pricing Card
        _buildSectionHeader('Pricing Card'),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Original Purchase Price'),
              _buildPriceInputField(controller: _originalPriceController),
              const SizedBox(height: 16),
              _buildLabel('Selling Price Per Session *'),
              _buildPriceInputField(
                controller: _sellingPriceController,
                onChanged: (val) => setState(() {}),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Sessions To Sell'),
                        _buildPriceInputField(
                          controller: _sessionsToSellController,
                          isCurrency: false,
                          hint: 'Optional',
                          onChanged: (val) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Total Sessions'),
                        _buildPriceInputField(
                          controller: _totalSessionsController,
                          isCurrency: false,
                          hint: 'Optional',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Summary Card (Dark Grey)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B), // Dark slate/grey card
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SUMMARY SECTION',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(4)),
                    child: Row(
                      children: const [
                        Text('300', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        Icon(Icons.arrow_drop_down, color: Colors.white, size: 14),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Auto-calculated value',
                style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.4)),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Selling Price',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    '\$ ${_calculatedTotalSellingPrice.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFFFBBD03)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Validity Card
        _buildSectionHeader('Validity'),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Total Validity Days'),
                        _buildPriceInputField(controller: _validityDaysController, isCurrency: false),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Remaining Days'),
                        _buildPriceInputField(controller: _remainingDaysController, isCurrency: false),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildLabel('Expiry Date'),
              GestureDetector(
                onTap: _showDatePicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.bgLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_expiryDate.month.toString().padLeft(2, '0')}/${_expiryDate.day.toString().padLeft(2, '0')}/${_expiryDate.year}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Status Dropdown
        _buildSectionHeader('Status'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _packageStatus,
              style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500),
              items: const [
                DropdownMenuItem(value: 'draft', child: Text('Draft')),
                DropdownMenuItem(value: 'pending', child: Text('Pending Review')),
                DropdownMenuItem(value: 'published', child: Text('Published')),
              ],
              onChanged: (val) => setState(() => _packageStatus = val ?? 'draft'),
            ),
          ),
        ),
      ],
    );
  }

  void _showDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  // --- GENERAL WIDGET BUILDERS ---
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColors.primary.withValues(alpha: 0.8),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required int maxLines,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: AppColors.primary.withValues(alpha: 0.35), fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildPriceInputField({
    required TextEditingController controller,
    bool isCurrency = true,
    String hint = '0.00',
    Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
        onChanged: onChanged,
        decoration: InputDecoration(
          prefixIcon: isCurrency
              ? const Padding(
                  padding: EdgeInsets.only(left: 12.0, right: 6.0, top: 12.0),
                  child: Text('\$', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                )
              : null,
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.primary.withValues(alpha: 0.35), fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildUploadDottedBox({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.12),
            style: BorderStyle.solid, // Note: Flutter standard border doesn't support dash easily, but solid matches beautifully
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: const Color(0xFF1F2E4E)),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.primary.withValues(alpha: 0.08), width: 1.2),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: SafeArea(
        child: Row(
          children: [
            // Save Draft button
            OutlinedButton.icon(
              onPressed: () {
                _showToast('Draft Saved!');
              },
              icon: const Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.primary),
              label: const Text(
                'Save Draft',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
            ),
            const SizedBox(width: 14),

            // Next Step/Submit button
            Expanded(
              child: ElevatedButton(
                onPressed: _currentStep == 3 ? _submitForm : _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F2E4E),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  minimumSize: const Size(0, 48), // override theme minimumSize
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _currentStep == 3 ? (widget.packageToEdit != null ? 'Save Changes' : 'Submit Package') : 'Next Step',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward, size: 14, color: Colors.white),
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
