import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/session_manager.dart';
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
  final TextEditingController _newKeyPointController = TextEditingController();
  bool _isAddingKeyPoint = false;
  String _primaryCategory = '';
  String _secondaryCategory = '';
  String _packageStatus = 'draft'; // draft | pending | published

  bool _isCustomMerchant = false;
  final TextEditingController _customMerchantController = TextEditingController();
  final TextEditingController _manualOutletController = TextEditingController();
  bool _isTransferApprovalConfirmed = false;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _originalPriceController = TextEditingController();
  final TextEditingController _sellingPriceController = TextEditingController();
  final TextEditingController _discountedPriceController = TextEditingController();
  final TextEditingController _sessionsToSellController = TextEditingController();
  final TextEditingController _totalSessionsController = TextEditingController();

  final TextEditingController _validityDaysController = TextEditingController(text: '365');
  final TextEditingController _remainingDaysController = TextEditingController(text: '180');
  String _selectedCurrency = 'SGD';
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 365));

  // Dynamic Data Loading State
  List<Map<String, dynamic>> _apiMerchants = [];
  List<Map<String, dynamic>> _apiCategories = [];
  List<Map<String, dynamic>> _primaryCategories = [];
  List<Map<String, dynamic>> _secondaryCategories = [];
  bool _isLoadingData = false;



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



  @override
  void initState() {
    super.initState();
    _loadMerchantsAndCategories();
    if (widget.packageToEdit != null) {
      _populateFormFromPackage(widget.packageToEdit!);
      final pkgId = int.tryParse(widget.packageToEdit!['id']?.toString() ?? '');
      if (pkgId != null && pkgId > 0) {
        _fetchFullPackageDetails(pkgId);
      }
    }
  }

  Future<void> _fetchFullPackageDetails(int packageId) async {
    try {
      final res = await ApiService.getPackageById(packageId);
      if (!mounted) return;
      if (res['success'] == true && res['data'] is Map<String, dynamic>) {
        final fullPkg = res['data'] as Map<String, dynamic>;
        setState(() {
          _populateFormFromPackage(fullPkg);
        });
      }
    } catch (e) {
      debugPrint('[DEBUG] Error fetching full package details: $e');
    }
  }

  void _populateFormFromPackage(Map<String, dynamic> pkg) {
    if (pkg['title'] != null && pkg['title'].toString().isNotEmpty) {
      _titleController.text = ApiService.unescapeHtml(pkg['title'].toString());
    }
    final shortDesc = pkg['short_description']?.toString() ?? pkg['excerpt']?.toString();
    if (shortDesc != null && shortDesc.isNotEmpty) _shortDescriptionController.text = ApiService.unescapeHtml(shortDesc);

    final desc = pkg['content']?.toString() ?? pkg['description']?.toString() ?? pkg['details']?.toString();
    if (desc != null && desc.isNotEmpty) _descriptionController.text = ApiService.unescapeHtml(desc);

    final st = pkg['status']?.toString().toLowerCase();
    if (st != null && st.isNotEmpty) {
      _packageStatus = st == 'published' || st == 'publish' ? 'published'
          : st == 'pending' || st == 'in_review' ? 'pending'
          : 'draft';
    }

    final origPrice = pkg['original_purchase_price'] ?? pkg['original_price'] ?? pkg['originalPrice'];
    final resPrice = pkg['selling_price_per_session'] ?? pkg['price'] ?? pkg['resale_price'] ?? pkg['resalePrice'];
    final discPrice = pkg['discounted_price'] ?? pkg['discountPrice'];

    if (origPrice != null) _originalPriceController.text = origPrice.toString();
    if (resPrice != null) _sellingPriceController.text = resPrice.toString();
    if (discPrice != null) _discountedPriceController.text = discPrice.toString();

    if (pkg['sessions_to_sell'] != null) _sessionsToSellController.text = pkg['sessions_to_sell'].toString();
    if (pkg['total_sessions'] != null) _totalSessionsController.text = pkg['total_sessions'].toString();
    if (pkg['total_validity_days'] != null || pkg['validity_days'] != null) {
      _validityDaysController.text = (pkg['total_validity_days'] ?? pkg['validity_days']).toString();
    }
    if (pkg['remaining_validity_days'] != null || pkg['remaining_days'] != null) {
      _remainingDaysController.text = (pkg['remaining_validity_days'] ?? pkg['remaining_days']).toString();
    }

    final expStr = pkg['availability_end']?.toString() ?? pkg['expiry_date']?.toString();
    if (expStr != null && expStr.isNotEmpty) {
      try {
        final parsed = DateTime.tryParse(expStr);
        if (parsed != null) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final parsedOnly = DateTime(parsed.year, parsed.month, parsed.day);
          _expiryDate = parsedOnly.isBefore(today) ? today : parsedOnly;
        }
      } catch (_) {}
    }

    // Key points
    if (pkg['key_points'] != null) {
      _keyPoints.clear();
      if (pkg['key_points'] is List) {
        for (var item in (pkg['key_points'] as List)) {
          final s = item?.toString().trim() ?? '';
          if (s.isNotEmpty && !_keyPoints.contains(s)) {
            _keyPoints.add(s);
          }
        }
      } else if (pkg['key_points'] is String) {
        final str = pkg['key_points'] as String;
        if (str.startsWith('[')) {
          try {
            final decoded = json.decode(str) as List;
            for (var item in decoded) {
              final s = item?.toString().trim() ?? '';
              if (s.isNotEmpty && !_keyPoints.contains(s)) _keyPoints.add(s);
            }
          } catch (_) {}
        } else {
          final lines = str.split(RegExp(r'[\n,]'));
          for (var l in lines) {
            final s = l.trim();
            if (s.isNotEmpty && !_keyPoints.contains(s)) _keyPoints.add(s);
          }
        }
      }
    }

    // Vendor / Merchant handling
    final vendorMode = pkg['vendor_mode']?.toString().toLowerCase();
    final manualVendorName = pkg['manual_vendor_name']?.toString() ?? pkg['custom_merchant']?.toString();
    final manualOutlet = pkg['manual_outlet']?.toString() ?? pkg['manual_vendor_outlet']?.toString() ?? pkg['outlet']?.toString() ?? pkg['location']?.toString();

    if (vendorMode == 'manual' || (manualVendorName != null && manualVendorName.isNotEmpty)) {
      _isCustomMerchant = true;
      _selectedMerchant = 'Not in the list';
      if (manualVendorName != null) _customMerchantController.text = manualVendorName;
      if (manualOutlet != null) _manualOutletController.text = manualOutlet;
    } else {
      if (pkg['presented_by'] is Map) {
        final pb = pkg['presented_by'] as Map;
        _selectedMerchant = pb['name']?.toString() ?? pb['business_name']?.toString() ?? _selectedMerchant;
      } else if (pkg['merchant_name'] != null && pkg['merchant_name'].toString().isNotEmpty) {
        _selectedMerchant = pkg['merchant_name'].toString();
      } else if (pkg['merchant'] is Map) {
        _selectedMerchant = pkg['merchant']['name']?.toString() ?? pkg['merchant']['business_name']?.toString() ?? _selectedMerchant;
      } else if (pkg['merchant'] is String && pkg['merchant'].toString().isNotEmpty) {
        _selectedMerchant = pkg['merchant'].toString();
      }
    }

    if (pkg['transfer_approval'] == true || pkg['transfer_permission'] == true) {
      _isTransferApprovalConfirmed = true;
    }

    // Primary & Secondary Category
    if (pkg['primary_category'] != null && pkg['primary_category'].toString().isNotEmpty) {
      _primaryCategory = pkg['primary_category'].toString();
    } else if (pkg['category'] != null) {
      if (pkg['category'] is Map) {
        _primaryCategory = pkg['category']['slug']?.toString() ?? _primaryCategory;
      } else if (pkg['category'].toString().isNotEmpty) {
        _primaryCategory = pkg['category'].toString();
      }
    }

    if (pkg['secondary_category'] != null && pkg['secondary_category'].toString().isNotEmpty) {
      if (pkg['secondary_category'] is Map) {
        _secondaryCategory = pkg['secondary_category']['slug']?.toString() ?? _secondaryCategory;
      } else {
        _secondaryCategory = pkg['secondary_category'].toString();
      }
    }

    if (pkg['categories'] != null && pkg['categories'] is List) {
      for (var cat in (pkg['categories'] as List)) {
        if (cat is Map) {
          final slug = cat['slug']?.toString() ?? '';
          if (['for-her', 'for-him', 'general', 'biz'].contains(slug)) {
            _primaryCategory = slug;
          } else if (['yoga-pilates', 'spa-massage', 'beauty-nails', 'gym-fitness', 'lifestyle-classes'].contains(slug)) {
            _secondaryCategory = slug;
          }
        } else if (cat is String) {
          if (['for-her', 'for-him', 'general', 'biz'].contains(cat)) {
            _primaryCategory = cat;
          } else if (['yoga-pilates', 'spa-massage', 'beauty-nails', 'gym-fitness', 'lifestyle-classes'].contains(cat)) {
            _secondaryCategory = cat;
          }
        }
      }
    }

    // Gallery images
    if ((pkg['images'] != null && pkg['images'] is List && (pkg['images'] as List).isNotEmpty) ||
        (pkg['cover_url'] != null && pkg['cover_url'].toString().isNotEmpty)) {
      _galleryImages.clear();
      if (pkg['images'] is List) {
        for (var img in (pkg['images'] as List)) {
          if (img is Map && img['url'] != null) {
            _galleryImages.add(img['url'].toString());
          } else if (img is String && img.isNotEmpty) {
            _galleryImages.add(img);
          }
        }
      }
      if (_galleryImages.isEmpty && pkg['cover_url'] != null && pkg['cover_url'].toString().isNotEmpty) {
        _galleryImages.add(pkg['cover_url'].toString());
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

      // Deduplicate loaded merchants by business name or name (case-insensitive trim)
      final Set<String> seenNames = {};
      final List<Map<String, dynamic>> uniqueMerchants = [];

      // If logged in user is a merchant, include their dynamic profile at top of list
      if (SessionManager.isMerchant) {
        final myUser = SessionManager.userData;
        final myName = (myUser?['business_name']?.toString() ?? myUser?['name']?.toString() ?? SessionManager.userName ?? '').trim();
        if (myName.isNotEmpty) {
          seenNames.add(myName.toLowerCase());
          uniqueMerchants.add({
            'id': SessionManager.userId,
            'business_name': myName,
            'name': myName,
            'logo_url': myUser?['logo_url'] ?? myUser?['logo'],
          });
        }
      }

      for (final merchant in loadedMerchants) {
        final name = (merchant['business_name']?.toString() ?? merchant['name']?.toString() ?? '').trim().toLowerCase();
        if (name.isNotEmpty && !seenNames.contains(name)) {
          seenNames.add(name);
          uniqueMerchants.add(merchant);
        }
      }

      List<Map<String, dynamic>> loadedCategories = [];
      if (categoryRes['success'] == true && categoryRes['data'] != null) {
        final List<dynamic> list = categoryRes['data'];
        loadedCategories = list.map((item) {
          final map = Map<String, dynamic>.from(item);
          if (map['name'] != null) {
            map['name'] = map['name']
                .toString()
                .replaceAll('&amp;', '&')
                .replaceAll('\u0026amp;', '&');
          }
          return map;
        }).toList();
      }

      setState(() {
        _apiMerchants = uniqueMerchants;
        _apiCategories = loadedCategories;
        _isLoadingData = false;

        // If we are editing, map merchant_id to merchant name if _selectedMerchant is empty
        if (widget.packageToEdit != null && (_selectedMerchant.isEmpty || _selectedMerchant == 'null')) {
          final editPkg = widget.packageToEdit!;
          final editMerchantId = editPkg['merchant_id'] is int
              ? editPkg['merchant_id']
              : int.tryParse(editPkg['merchant_id']?.toString() ?? '');
          if (editMerchantId != null) {
            final matchedMerchant = uniqueMerchants.firstWhere(
              (m) => (m['id'] is int ? m['id'] : int.tryParse(m['id']?.toString() ?? '')) == editMerchantId,
              orElse: () => <String, dynamic>{},
            );
            if (matchedMerchant.isNotEmpty) {
              _selectedMerchant = matchedMerchant['business_name']?.toString() ?? matchedMerchant['name']?.toString() ?? '';
              debugPrint('[DEBUG] Mapped merchant_id $editMerchantId to merchant name: $_selectedMerchant');
            }
          }
        }

        // Detect if the selected merchant is custom (not in uniqueMerchants and not in fallback)
        if (_selectedMerchant.isNotEmpty && _selectedMerchant != 'null') {
          final existsInApi = uniqueMerchants.any((m) =>
              (m['business_name']?.toString() == _selectedMerchant ||
               m['name']?.toString() == _selectedMerchant));
          if (!existsInApi) {
            _isCustomMerchant = true;
            _customMerchantController.text = _selectedMerchant;
            debugPrint('[DEBUG] Detected custom merchant: $_selectedMerchant');
          }
        }
        
        // Populate primary/secondary lists based on slugs (Biz+ is restricted to Merchants only)
        final isMerchantUser = SessionManager.isMerchant;
        _primaryCategories = _apiCategories.where((cat) {
          final slug = cat['slug']?.toString() ?? '';
          return slug == 'for-her' || slug == 'for-him' || slug == 'general' || (isMerchantUser && slug == 'biz');
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



  Widget _buildMerchantDropdownItem(Map<String, dynamic> merchant) {
    final name = merchant['business_name']?.toString() ?? merchant['name']?.toString() ?? '';
    final String? logoUrl = merchant['logo_url']?.toString() ?? merchant['logo']?.toString();

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
        ClipOval(
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: logoUrl == null || logoUrl.isEmpty ? avatarColor : Colors.white,
              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            ),
            child: logoUrl != null && logoUrl.isNotEmpty
                ? Image.network(
                    logoUrl,
                    width: 32,
                    height: 32,
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
    _newKeyPointController.dispose();
    _customMerchantController.dispose();
    _manualOutletController.dispose();
    _originalPriceController.dispose();
    _sellingPriceController.dispose();
    _discountedPriceController.dispose();
    _sessionsToSellController.dispose();
    _totalSessionsController.dispose();
    _validityDaysController.dispose();
    _remainingDaysController.dispose();
    super.dispose();
  }

  // Dynamic calculations for C2C price & resale cap according to API spec
  double get _calculatedTotalSellingPrice {
    final sellingPricePerSession = double.tryParse(_sellingPriceController.text) ?? 0.0;
    final sessionsToSell = double.tryParse(_sessionsToSellController.text) ?? 0.0;
    final totalSessions = double.tryParse(_totalSessionsController.text) ?? 0.0;

    if (sessionsToSell > 0 && totalSessions > 0) {
      return sessionsToSell * sellingPricePerSession;
    }
    return sellingPricePerSession;
  }

  double? get _maxAllowedResalePrice {
    final origPrice = double.tryParse(_originalPriceController.text) ?? 0.0;
    if (origPrice <= 0) return null;

    final sessionsToSell = double.tryParse(_sessionsToSellController.text) ?? 0.0;
    final totalSessions = double.tryParse(_totalSessionsController.text) ?? 0.0;
    final totalValidity = double.tryParse(_validityDaysController.text) ?? 0.0;
    final remainingValidity = double.tryParse(_remainingDaysController.text) ?? 0.0;

    double? unitsCap;
    if (sessionsToSell > 0 && totalSessions > 0) {
      unitsCap = (origPrice * sessionsToSell / totalSessions).floorToDouble();
    }

    double? timeCap;
    if (totalValidity > 0 && remainingValidity > 0) {
      timeCap = (origPrice * remainingValidity / totalValidity).floorToDouble();
    }

    if (unitsCap != null && timeCap != null) {
      return math.min(unitsCap, timeCap);
    } else if (unitsCap != null) {
      return unitsCap;
    } else if (timeCap != null) {
      return timeCap;
    }
    return null;
  }

  void _nextStep() {
    if (_currentStep == 1) {
      if (!SessionManager.isMerchant) {
        if (_isCustomMerchant) {
          if (_customMerchantController.text.trim().isEmpty) {
            _showToast('Merchant name is required', type: SnackBarType.warning);
            return;
          }
          if (_receiptFileName.isEmpty) {
            _showToast('Please upload clearance evidence file', type: SnackBarType.warning);
            return;
          }
          if (!_isTransferApprovalConfirmed) {
            _showToast('Please confirm transfer approval details for manual clearance', type: SnackBarType.warning);
            return;
          }
        } else {
          if (_selectedMerchant.isEmpty) {
            _showToast('Please select a merchant', type: SnackBarType.warning);
            return;
          }
        }
      }
      if (_titleController.text.trim().isEmpty) {
        _showToast('Package title is required', type: SnackBarType.warning);
        return;
      }
      if (_descriptionController.text.trim().isEmpty) {
        _showToast('Package description is required', type: SnackBarType.warning);
        return;
      }
      if (_primaryCategory.isEmpty) {
        _showToast('Please select a category', type: SnackBarType.warning);
        return;
      }
      setState(() => _currentStep = 2);
    } else if (_currentStep == 2) {
      if (_sellingPriceController.text.isEmpty) {
        _showToast('Please enter the selling price per session', type: SnackBarType.warning);
        return;
      }
      final maxCap = _maxAllowedResalePrice;
      if (maxCap != null && _calculatedTotalSellingPrice > maxCap) {
        _showToast(
          'Total selling price (\$${_calculatedTotalSellingPrice.toStringAsFixed(2)}) exceeds maximum allowed resale price of ${maxCap.toInt()} SGD',
          type: SnackBarType.warning,
        );
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
      _showToast(SessionManager.isMerchant ? 'Please enter the price' : 'Please enter the selling price', type: SnackBarType.warning);
      return;
    }

    if (!SessionManager.isMerchant && _receiptFileName.isEmpty) {
      _showToast('Please upload clearance evidence / submission receipt', type: SnackBarType.warning);
      return;
    }

    // Build categories list from primary + secondary slugs
    final List<String> categoryList = [];
    if (_primaryCategory.isNotEmpty) categoryList.add(_primaryCategory);
    if (_secondaryCategory.isNotEmpty) categoryList.add(_secondaryCategory);

    double totalSellingPrice = 0.0;
    double sellingPricePerSession = 0.0;
    double discountedPrice = 0.0;

    if (SessionManager.isMerchant) {
      totalSellingPrice = double.tryParse(sellingPriceStr) ?? 0.0;
      final discStr = _discountedPriceController.text.trim();
      discountedPrice = discStr.isNotEmpty ? (double.tryParse(discStr) ?? totalSellingPrice) : totalSellingPrice;
    } else {
      sellingPricePerSession = double.tryParse(sellingPriceStr) ?? 0.0;
      totalSellingPrice = _calculatedTotalSellingPrice;
      discountedPrice = totalSellingPrice;

      final maxCap = _maxAllowedResalePrice;
      if (maxCap != null && totalSellingPrice > maxCap) {
        _showToast(
          'Total selling price (\$${totalSellingPrice.toStringAsFixed(2)}) exceeds maximum allowed resale price of ${maxCap.toInt()} SGD',
          type: SnackBarType.warning,
        );
        return;
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
      ),
    );

    // Build payload using correct API field names
    final payload = <String, dynamic>{
      'package_title': _titleController.text.trim(),
      'short_description': _shortDescriptionController.text.trim(),
      'package_price': totalSellingPrice,
      'price': totalSellingPrice,
      'discounted_price': discountedPrice,
      'currency': 'SGD',
      'availability_end': '${_expiryDate.year}-${_expiryDate.month.toString().padLeft(2,'0')}-${_expiryDate.day.toString().padLeft(2,'0')}',
      'key_points': _keyPoints,
      'status': _packageStatus,
    };

    // Optional fields — only include when non-empty
    if (_descriptionController.text.trim().isNotEmpty) {
      payload['content'] = _descriptionController.text.trim();
    }
    if (categoryList.isNotEmpty) {
      payload['categories'] = categoryList;
    }
    if (_secondaryCategory.isNotEmpty) {
      payload['secondary_category'] = _secondaryCategory;
    }

    if (!SessionManager.isMerchant) {
      payload['selling_price_per_session'] = sellingPricePerSession;
      if (originalPriceStr.isNotEmpty) {
        payload['original_purchase_price'] = double.tryParse(originalPriceStr) ?? 0.0;
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
    }
    // Resolve vendor_mode and merchant_id / manual fields
    if (_isCustomMerchant) {
      payload['vendor_mode'] = 'manual';
      payload['manual_vendor_name'] = _customMerchantController.text.trim();
      if (_manualOutletController.text.trim().isNotEmpty) {
        payload['manual_vendor_outlet'] = _manualOutletController.text.trim();
      }
    } else {
      payload['vendor_mode'] = 'self';
      final matchedMerchant = _apiMerchants.firstWhere(
        (m) => m['business_name']?.toString() == _selectedMerchant || m['name']?.toString() == _selectedMerchant,
        orElse: () => <String, dynamic>{},
      );
      if (matchedMerchant.isNotEmpty && matchedMerchant['id'] != null) {
        payload['merchant_id'] = matchedMerchant['id'] is int
            ? matchedMerchant['id']
            : int.tryParse(matchedMerchant['id'].toString());
      }
    }

    final isEditing = widget.packageToEdit != null;
    final res = isEditing
        ? await ApiService.updatePackage(
            widget.packageToEdit!['id'] is int ? widget.packageToEdit!['id'] : int.parse(widget.packageToEdit!['id'].toString()),
            payload,
          )
        : await ApiService.createPackage(payload);

    if (res['success'] == true) {
      final createdPkg = res['data'] ?? {};
      int? packageId;
      if (isEditing) {
        packageId = widget.packageToEdit!['id'] is int ? widget.packageToEdit!['id'] : int.tryParse(widget.packageToEdit!['id'].toString());
      } else {
        packageId = createdPkg['id'] is int ? createdPkg['id'] : int.tryParse(createdPkg['id']?.toString() ?? '');
      }

      // Check for local file paths
      final localPaths = _galleryImages.where((path) => !path.startsWith('http') && !path.startsWith('assets/')).toList();
      if (packageId != null && localPaths.isNotEmpty) {
        debugPrint('[DEBUG] Uploading package images: $localPaths');
        await ApiService.uploadPackageImages(packageId, localPaths);
      }
    }

    if (!mounted) return;
    Navigator.of(context).pop(); // pop spinner

    if (res['success'] == true) {
      final createdPkg = res['data'] ?? {};
      final localPkg = _mapApiPackageForLocal(createdPkg, sellingPriceStr);

      if (isEditing) {
        if (widget.onPackageUpdated != null) {
          widget.onPackageUpdated!(localPkg);
        }
        Navigator.of(context).pop(true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            CustomSnackBar.show(
              context,
              message: 'Package updated successfully',
              type: SnackBarType.success,
            );
          }
        });
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
    } else if (_galleryImages.isNotEmpty) {
      imageUrl = _galleryImages[0];
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
    result['title'] = ApiService.unescapeHtml(apiPkg['title']?.toString() ?? _titleController.text);
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
      stepTitle = 'Package Information';
      progress = 0.33;
    } else if (_currentStep == 2) {
      stepTitle = 'Pricing & Validity';
      progress = 0.66;
    } else {
      stepTitle = 'Media Uploads';
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

  // --- MERCHANT SECTION & STEPS BUILDERS ---
  Widget _buildMerchantSection() {
    if (SessionManager.isMerchant) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Merchant'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Text(
                  (SessionManager.userName ?? '').isNotEmpty ? SessionManager.userName! : 'Merchant Account',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Container(
      padding: _isCustomMerchant ? const EdgeInsets.all(18) : EdgeInsets.zero,
      decoration: _isCustomMerchant
          ? BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row: Title & Toggle link
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isCustomMerchant ? 'Merchant not listed' : 'Select Merchant *',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isCustomMerchant = !_isCustomMerchant;
                    if (!_isCustomMerchant) {
                      _customMerchantController.clear();
                      _manualOutletController.clear();
                      _selectedMerchant = '';
                      _isTransferApprovalConfirmed = false;
                    } else {
                      _selectedMerchant = _customMerchantController.text.trim();
                    }
                  });
                },
                child: Text(
                  _isCustomMerchant ? 'Select from verified list' : 'Not in the list',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFBBD03),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (_isCustomMerchant) ...[
            // Merchant Name *
            _buildLabel('Merchant Name *'),
            Container(
              decoration: BoxDecoration(
                color: AppColors.bgLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
              ),
              child: TextFormField(
                controller: _customMerchantController,
                style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500),
                onChanged: (val) {
                  setState(() {
                    _selectedMerchant = val.trim();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Enter merchant name',
                  hintStyle: TextStyle(color: AppColors.primary.withValues(alpha: 0.35), fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Outlet
            _buildLabel('Outlet'),
            Container(
              decoration: BoxDecoration(
                color: AppColors.bgLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
              ),
              child: TextFormField(
                controller: _manualOutletController,
                style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: 'e.g. Plaza Singapura',
                  hintStyle: TextStyle(color: AppColors.primary.withValues(alpha: 0.35), fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Clearance Evidence *
            _buildLabel('Clearance Evidence *'),
            _buildUploadDottedBox(
              icon: Icons.upload_file_rounded,
              label: _receiptFileName.isEmpty ? 'Upload evidence file' : _receiptFileName,
              onTap: () async {
                try {
                  final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
                  if (file != null) {
                    setState(() {
                      _receiptFileName = file.name;
                    });
                    _showToast('Evidence file attached', type: SnackBarType.success);
                  }
                } catch (e) {
                  _showToast('Failed to pick file: $e', type: SnackBarType.error);
                }
              },
            ),
            const SizedBox(height: 14),

            // Confirmation Checkbox
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _isTransferApprovalConfirmed,
                    activeColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: (val) {
                      setState(() {
                        _isTransferApprovalConfirmed = val ?? false;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'I confirm that transfer approval details are accurate for manual clearance.',
                    style: TextStyle(fontSize: 11, color: AppColors.primary, height: 1.3),
                  ),
                ),
              ],
            ),
          ] else ...[
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
                  value: _apiMerchants.any((m) => (m['business_name'] == _selectedMerchant || m['name'] == _selectedMerchant))
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
                  items: _apiMerchants.map((merchant) {
                          final name = merchant['business_name']?.toString() ?? merchant['name']?.toString() ?? '';
                          return DropdownMenuItem<String>(
                            value: name,
                            child: _buildMerchantDropdownItem(merchant),
                          );
                        }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedMerchant = val ?? '');
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildMerchantSection(),
        const SizedBox(height: 24),
        
        // Title Input
        _buildSectionHeader('Package Title *'),
        _buildInputField(
          controller: _titleController,
          hintText: 'Enter a descriptive title',
          maxLines: 1,
        ),
        const SizedBox(height: 20),

        if (SessionManager.isMerchant) ...[
          // Short Description Input for Merchants
          _buildSectionHeader('Short Description'),
          _buildInputField(
            controller: _shortDescriptionController,
            hintText: 'Brief summary (shown in listing cards)...',
            maxLines: 2,
          ),
          const SizedBox(height: 20),
        ],

        // Package Description Input (Required *)
        _buildSectionHeader('Package Description *'),
        _buildInputField(
          controller: _descriptionController,
          hintText: 'Describe your package, inclusions, highlights, etc.',
          maxLines: 5,
        ),
        const SizedBox(height: 24),

        // Key Points (0/5)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader("Key Points (What's Included)"),
            Text(
              "${_keyPoints.length}/5",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // List of added key points
        if (_keyPoints.isNotEmpty) ...[
          Column(
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
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF1F2E4E), size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        pt,
                        style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _keyPoints.removeAt(idx)),
                      child: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],

        // Input field or Add button
        if (_isAddingKeyPoint) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                  ),
                  child: TextFormField(
                    controller: _newKeyPointController,
                    autofocus: true,
                    style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500),
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (val) => _addKeyPointInline(),
                    decoration: InputDecoration(
                      hintText: 'e.g., 1-Hour massage session...',
                      hintStyle: TextStyle(color: AppColors.primary.withValues(alpha: 0.35), fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: _addKeyPointInline,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2E4E),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1F2E4E).withValues(alpha: 0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () {
                  setState(() {
                    _newKeyPointController.clear();
                    _isAddingKeyPoint = false;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.close_rounded, color: Colors.red, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ] else if (_keyPoints.length < 5) ...[
          GestureDetector(
            onTap: () {
              setState(() {
                _isAddingKeyPoint = true;
              });
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 14, color: Colors.black.withValues(alpha: 0.6)),
                  const SizedBox(width: 6),
                  const Text(
                    'Add Key Point',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2E4E),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],

        // Subtitle
        Text(
          "Add up to 5 key points highlighting what's included in your package.",
          style: TextStyle(
            fontSize: 11,
            color: Colors.black.withValues(alpha: 0.45),
            fontWeight: FontWeight.w400,
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
              value: (_primaryCategories.any((c) => c['slug'] == _primaryCategory) || (SessionManager.isMerchant ? _primaryFallback : _primaryFallback.where((c) => c['slug'] != 'biz')).any((c) => c['slug'] == _primaryCategory))
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
                  : (SessionManager.isMerchant ? _primaryFallback : _primaryFallback.where((c) => c['slug'] != 'biz').toList()).map((c) {
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

  void _addKeyPointInline() {
    final text = _newKeyPointController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _isAddingKeyPoint = false;
      });
      return;
    }
    if (_keyPoints.length >= 5) {
      _showToast('Maximum 5 key points allowed', type: SnackBarType.warning);
      return;
    }
    setState(() {
      _keyPoints.add(text);
      _newKeyPointController.clear();
      _isAddingKeyPoint = false;
    });
  }

  Widget _buildStep2() {
    if (SessionManager.isMerchant) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Pricing Card for Merchants
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
                _buildLabel('Price *'),
                _buildPriceInputField(
                  controller: _sellingPriceController,
                  onChanged: (val) => setState(() {}),
                ),
                const SizedBox(height: 16),
                _buildLabel('Discounted Price'),
                _buildPriceInputField(
                  controller: _discountedPriceController,
                  hint: '0.00 (Optional)',
                  onChanged: (val) => setState(() {}),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Validity Card for Merchants
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
                _buildLabel('Expiry Date *'),
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
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Pricing Card
        _buildSectionHeader('Pricing'),
        Text(
          "Set your price and let buyers know what they're getting.",
          style: TextStyle(
            fontSize: 11,
            color: Colors.black.withValues(alpha: 0.45),
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 12),
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
              _buildLabel('Original Purchase Price *'),
              _buildPriceInputField(
                controller: _originalPriceController,
                onChanged: (val) => setState(() {}),
              ),
              const SizedBox(height: 16),
              _buildLabel('Selling Price Per Session *'),
              _buildPriceInputField(
                controller: _sellingPriceController,
                onChanged: (val) => setState(() {}),
              ),
              const SizedBox(height: 20),

              // Sessions & Validity Sub-Card (Optional)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.bgLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'SESSIONS & VALIDITY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: AppColors.primary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'OPTIONAL',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
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
                                hint: '0',
                                onChanged: (val) => setState(() {}),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Total Sessions'),
                              _buildPriceInputField(
                                controller: _totalSessionsController,
                                isCurrency: false,
                                hint: '0',
                                onChanged: (val) => setState(() {}),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Total Validity Days'),
                              _buildPriceInputField(
                                controller: _validityDaysController,
                                isCurrency: false,
                                hint: 'e.g. 365',
                                onChanged: (val) => setState(() {}),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Remaining Validity Days'),
                              _buildPriceInputField(
                                controller: _remainingDaysController,
                                isCurrency: false,
                                hint: 'e.g. 120',
                                onChanged: (val) {
                                  final days = int.tryParse(val) ?? 0;
                                  final now = DateTime.now();
                                  final today = DateTime(now.year, now.month, now.day);
                                  setState(() {
                                    _expiryDate = today.add(Duration(days: days));
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Total Selling Price Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F5), // Light pinkish background matching web
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFDE8E8)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TOTAL SELLING PRICE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: Color(0xFFE11D48),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Sessions to Sell × Selling Price Per Session',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.black.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_calculatedTotalSellingPrice.toStringAsFixed(2)} $_selectedCurrency',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),

              // Max Resale Price Limit Notice (Website Parity)
              if (_maxAllowedResalePrice != null || (double.tryParse(_originalPriceController.text) ?? 0) > 0) ...[
                const SizedBox(height: 12),
                (() {
                  final capVal = _maxAllowedResalePrice ?? (double.tryParse(_originalPriceController.text) ?? 0.0);
                  final isExceeded = capVal > 0 && _calculatedTotalSellingPrice > capVal;
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isExceeded ? Colors.red.shade50 : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isExceeded ? Colors.red.shade200 : const Color(0xFFBFDBFE),
                      ),
                    ),
                    child: Text(
                      'Your maximum resale price is ${capVal.toInt()} $_selectedCurrency.',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isExceeded ? Colors.red.shade700 : const Color(0xFF1E40AF),
                      ),
                    ),
                  );
                })(),
              ],

              const SizedBox(height: 16),
              _buildLabel('Currency'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.bgLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedCurrency,
                    style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.bold),
                    items: const [
                      DropdownMenuItem(value: 'SGD', child: Text('SGD')),
                      DropdownMenuItem(value: 'USD', child: Text('USD')),
                      DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                      DropdownMenuItem(value: 'GBP', child: Text('GBP')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedCurrency = val;
                        });
                      }
                    },
                  ),
                ),
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
              const SizedBox(height: 6),
              Text(
                'Optional — leave blank if there is no fixed expiry.',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ),
        if (SessionManager.isMerchant) ...[
          const SizedBox(height: 24),
          // Status Dropdown for Merchants only
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
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
          onTap: () async {
            if (_galleryImages.length >= 5) {
              _showToast('Maximum 5 images allowed', type: SnackBarType.warning);
              return;
            }
            try {
              final List<XFile> pickedImages = await _picker.pickMultiImage();
              if (pickedImages.isNotEmpty) {
                setState(() {
                  for (var image in pickedImages) {
                    if (_galleryImages.length < 5) {
                      _galleryImages.add(image.path);
                    } else {
                      break;
                    }
                  }
                });
                _showToast('${pickedImages.length} image(s) selected', type: SnackBarType.success);
              }
            } catch (e) {
              _showToast('Failed to pick images: $e', type: SnackBarType.error);
            }
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
                    image: _galleryImages[index].startsWith('http')
                        ? NetworkImage(_galleryImages[index]) as ImageProvider
                        : _galleryImages[index].startsWith('assets/')
                            ? AssetImage(_galleryImages[index])
                            : FileImage(File(_galleryImages[index])),
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
          onTap: () async {
            try {
              final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
              if (file != null) {
                setState(() {
                  _receiptFileName = file.name;
                });
                _showToast('Receipt selected successfully', type: SnackBarType.success);
              }
            } catch (e) {
              _showToast('Failed to pick receipt: $e', type: SnackBarType.error);
            }
          },
        ),
      ],
    );
  }
  void _showDatePicker() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initialDate = _expiryDate.isBefore(today) ? today : _expiryDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 3650)),
      selectableDayPredicate: (DateTime day) {
        final d = DateTime(day.year, day.month, day.day);
        return !d.isBefore(today);
      },
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final diff = picked.difference(today).inDays;
      setState(() {
        _expiryDate = picked;
        _remainingDaysController.text = (diff >= 0 ? diff : 0).toString();
      });
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
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          prefixIcon: isCurrency
              ? const Padding(
                  padding: EdgeInsets.only(left: 14.0, right: 8.0),
                  child: Text('\$', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
                )
              : null,
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.primary.withValues(alpha: 0.35), fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
