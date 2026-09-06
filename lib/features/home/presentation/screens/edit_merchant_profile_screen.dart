import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/session_manager.dart';
import '../../../../core/widgets/custom_snackbar.dart';

class EditMerchantProfileScreen extends StatefulWidget {
  final Map<String, dynamic> merchantData;

  const EditMerchantProfileScreen({
    super.key,
    required this.merchantData,
  });

  @override
  State<EditMerchantProfileScreen> createState() => _EditMerchantProfileScreenState();
}

class _EditMerchantProfileScreenState extends State<EditMerchantProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _typeCtrl;
  late TextEditingController _regCtrl;
  late TextEditingController _addrCtrl;
  late TextEditingController _webCtrl;
  late TextEditingController _phoneCtrl;
  late String _email;

  late String _initialName;
  late String _initialType;
  late String _initialReg;
  late String _initialAddr;
  late String _initialWeb;
  late String _initialPhone;

  final ImagePicker _picker = ImagePicker();
  String? _localLogoPath;
  final bool _isUploadingLogo = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final d = widget.merchantData;
    _initialName = d['business_name']?.toString() ?? d['name']?.toString() ?? '';
    _initialType = d['business_type']?.toString() ?? d['type']?.toString() ?? '';
    _initialReg = d['business_registration']?.toString() ?? d['registration_number']?.toString() ?? '';
    _initialAddr = d['business_address']?.toString() ?? d['address']?.toString() ?? '';
    _initialWeb = d['website_link']?.toString() ?? d['website']?.toString() ?? '';
    _initialPhone = d['phone_number']?.toString() ?? d['phone']?.toString() ?? '';
    _email = d['email']?.toString() ?? SessionManager.userEmail ?? '';

    _nameCtrl = TextEditingController(text: _initialName);
    _typeCtrl = TextEditingController(text: _initialType);
    _regCtrl = TextEditingController(text: _initialReg);
    _addrCtrl = TextEditingController(text: _initialAddr);
    _webCtrl = TextEditingController(text: _initialWeb);
    _phoneCtrl = TextEditingController(text: _initialPhone);

    _nameCtrl.addListener(_onFieldChanged);
    _typeCtrl.addListener(_onFieldChanged);
    _regCtrl.addListener(_onFieldChanged);
    _addrCtrl.addListener(_onFieldChanged);
    _webCtrl.addListener(_onFieldChanged);
    _phoneCtrl.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  bool get _hasChanges {
    if (_localLogoPath != null) return true;
    return _nameCtrl.text.trim() != _initialName.trim() ||
        _typeCtrl.text.trim() != _initialType.trim() ||
        _regCtrl.text.trim() != _initialReg.trim() ||
        _addrCtrl.text.trim() != _initialAddr.trim() ||
        _webCtrl.text.trim() != _initialWeb.trim() ||
        _phoneCtrl.text.trim() != _initialPhone.trim();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _typeCtrl.dispose();
    _regCtrl.dispose();
    _addrCtrl.dispose();
    _webCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  String _getLogoUrl() {
    final d = widget.merchantData;
    if (d['logo_url'] != null && d['logo_url'].toString().isNotEmpty) {
      return d['logo_url'].toString();
    }
    if (d['logo'] != null && d['logo'].toString().isNotEmpty) {
      return d['logo'].toString();
    }
    return '';
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Select Logo Source',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontFamily: 'Recoleta Alt',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                title: const Text('Camera', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final XFile? picked = await _picker.pickImage(source: ImageSource.camera);
                  if (picked != null) {
                    setState(() {
                      _localLogoPath = picked.path;
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: const Text('Gallery', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
                  if (picked != null) {
                    setState(() {
                      _localLogoPath = picked.path;
                    });
                  }
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDefaultLogo(String initials) {
    return Container(
      color: const Color(0xFFF1F5F9),
      alignment: Alignment.center,
      child: Text(
        initials.isEmpty ? 'M' : initials,
        style: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
          fontFamily: 'Recoleta Alt',
        ),
      ),
    );
  }

  Future<void> _saveMerchantProfile() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      CustomSnackBar.show(context, message: 'Business Name is required.', type: SnackBarType.error);
      return;
    }

    setState(() => _isSaving = true);

    bool uploadSuccess = true;
    if (_localLogoPath != null) {
      final uploadRes = await ApiService.uploadMerchantLogo(_localLogoPath!);
      if (uploadRes['success'] != true) {
        uploadSuccess = false;
        if (mounted) {
          CustomSnackBar.show(
            context,
            message: uploadRes['message'] ?? 'Logo upload failed',
            type: SnackBarType.error,
          );
        }
      }
    }

    if (uploadSuccess) {
      final res = await ApiService.updateMerchantMe({
        'business_name': name,
        'business_type': _typeCtrl.text.trim(),
        'business_registration': _regCtrl.text.trim(),
        'business_address': _addrCtrl.text.trim(),
        'website_link': _webCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
      });

      if (!mounted) return;
      if (res['success'] == true) {
        CustomSnackBar.show(
          context,
          message: 'Merchant profile updated successfully!',
          type: SnackBarType.success,
        );
        Navigator.of(context).pop(true);
      } else {
        CustomSnackBar.show(
          context,
          message: res['message'] ?? 'Update failed',
          type: SnackBarType.error,
        );
      }
    }

    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final logoUrl = _getLogoUrl();
    final nameVal = _nameCtrl.text.trim();
    final initials = nameVal.isNotEmpty ? nameVal[0].toUpperCase() : 'M';

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Business Profile',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontFamily: 'Recoleta Alt',
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo Picker
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.borderLight, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(52),
                      child: _isUploadingLogo
                          ? const Center(
                              child: SizedBox(
                                width: 26,
                                height: 26,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
                              ),
                            )
                          : _localLogoPath != null
                              ? Image.file(
                                  File(_localLogoPath!),
                                  fit: BoxFit.cover,
                                )
                              : logoUrl.isNotEmpty
                                  ? Image.network(
                                      logoUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => _buildDefaultLogo(initials),
                                    )
                                  : _buildDefaultLogo(initials),
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: _showImageSourceSheet,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: _showImageSourceSheet,
                child: const Text(
                  'Change Business Logo',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Form Fields Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _nameCtrl,
                    style: const TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'Business Name *',
                      labelStyle: TextStyle(color: AppColors.primary.withValues(alpha: 0.6)),
                      prefixIcon: const Icon(Icons.storefront_outlined, color: AppColors.primary, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _typeCtrl,
                    style: const TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'Business Type *',
                      labelStyle: TextStyle(color: AppColors.primary.withValues(alpha: 0.6)),
                      prefixIcon: const Icon(Icons.category_outlined, color: AppColors.primary, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _regCtrl,
                    style: const TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'Company Registration Number',
                      labelStyle: TextStyle(color: AppColors.primary.withValues(alpha: 0.6)),
                      prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.primary, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _addrCtrl,
                    style: const TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'Business Address',
                      labelStyle: TextStyle(color: AppColors.primary.withValues(alpha: 0.6)),
                      prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _webCtrl,
                    style: const TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'Website Link',
                      labelStyle: TextStyle(color: AppColors.primary.withValues(alpha: 0.6)),
                      prefixIcon: const Icon(Icons.language_outlined, color: AppColors.primary, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: TextEditingController(text: _email),
                    readOnly: true,
                    style: TextStyle(fontSize: 14, color: AppColors.primary.withValues(alpha: 0.5)),
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      labelStyle: TextStyle(color: AppColors.primary.withValues(alpha: 0.6)),
                      prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary.withValues(alpha: 0.5), size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      helperText: 'Email address cannot be changed.',
                      helperStyle: const TextStyle(color: Colors.black38, fontSize: 11),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.1)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      labelStyle: TextStyle(color: AppColors.primary.withValues(alpha: 0.6)),
                      prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.primary, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            ElevatedButton(
              onPressed: (_hasChanges && !_isSaving) ? _saveMerchantProfile : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFBBD03),
                disabledBackgroundColor: Colors.grey.shade300,
                foregroundColor: Colors.black,
                disabledForegroundColor: Colors.grey.shade600,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
                    )
                  : const Text(
                      'Save Changes',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
