import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/session_manager.dart';
import '../../../../core/widgets/custom_snackbar.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profileData;

  const EditProfileScreen({
    super.key,
    required this.profileData,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late String _email;
  
  late String _initialName;
  late String _initialPhone;

  final ImagePicker _picker = ImagePicker();
  String? _localImagePath;
  final bool _isUploadingAvatar = false;
  bool _isSaving = false;
  final int _avatarCacheBuster = 0;

  @override
  void initState() {
    super.initState();
    _initialName = widget.profileData['name']?.toString() ??
        widget.profileData['display_name']?.toString() ??
        SessionManager.userName ??
        '';
    _initialPhone = widget.profileData['phone_number']?.toString() ??
        widget.profileData['phone']?.toString() ??
        '';
    _email = widget.profileData['email']?.toString() ?? SessionManager.userEmail ?? '';

    _nameController = TextEditingController(text: _initialName);
    _phoneController = TextEditingController(text: _initialPhone);

    _nameController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  bool get _hasChanges {
    if (_localImagePath != null) return true;
    return _nameController.text.trim() != _initialName.trim() ||
        _phoneController.text.trim() != _initialPhone.trim();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _getAvatarUrl() {
    final data = widget.profileData;
    String rawUrl = '';
    if (data['avatar_url'] != null && data['avatar_url'].toString().isNotEmpty) {
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
    }

    if (rawUrl.isEmpty) return '';

    if (rawUrl.startsWith('/')) {
      try {
        final uri = Uri.parse(ApiService.baseUrl);
        final hostUrl = '${uri.scheme}://${uri.host}';
        rawUrl = '$hostUrl$rawUrl';
      } catch (_) {
        rawUrl = 'https://staging.twicely.sg$rawUrl';
      }
    }

    if (_avatarCacheBuster > 0) {
      final separator = rawUrl.contains('?') ? '&' : '?';
      rawUrl = '$rawUrl${separator}cb=$_avatarCacheBuster';
    }

    return rawUrl;
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
                'Select Image Source',
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
                      _localImagePath = picked.path;
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
                      _localImagePath = picked.path;
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
        style: const TextStyle(
          color: Colors.white,
          fontSize: 36,
          fontWeight: FontWeight.bold,
          fontFamily: 'Recoleta Alt',
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      CustomSnackBar.show(context, message: 'Full Name is required.', type: SnackBarType.error);
      return;
    }

    setState(() => _isSaving = true);

    bool success = true;
    if (_localImagePath != null) {
      final uploadRes = await ApiService.uploadUserAvatar(_localImagePath!);
      if (uploadRes['success'] != true) {
        success = false;
        if (mounted) {
          CustomSnackBar.show(
            context,
            message: uploadRes['message'] ?? 'Image upload failed',
            type: SnackBarType.error,
          );
        }
      }
    }

    if (success) {
      final res = await ApiService.updateUserMe({
        'name': name,
        'phone': phone,
      });

      if (!mounted) return;
      final isSuccess = res['success'] == true || res.containsKey('id') || res.containsKey('email');
      if (isSuccess) {
        CustomSnackBar.show(
          context,
          message: 'Profile updated successfully!',
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
    final avatarUrl = _getAvatarUrl();
    final nameVal = _nameController.text.trim();
    final initials = nameVal.split(' ').where((w) => w.isNotEmpty).take(2).map((w) => w[0].toUpperCase()).join();

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
          'Edit Profile',
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
            // Profile Avatar Picker
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFF27B6E).withValues(alpha: 0.4), width: 2.5),
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
                      child: _isUploadingAvatar
                          ? const Center(
                              child: SizedBox(
                                width: 26,
                                height: 26,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
                              ),
                            )
                          : _localImagePath != null
                              ? Image.file(
                                  File(_localImagePath!),
                                  fit: BoxFit.cover,
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
                    bottom: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: _showImageSourceSheet,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF27B6E),
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
                  'Change Profile Picture',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Form Card
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
                    controller: _nameController,
                    style: const TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'Full Name *',
                      labelStyle: TextStyle(color: AppColors.primary.withValues(alpha: 0.6)),
                      prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 20),
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
                    controller: _phoneController,
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
              onPressed: (_hasChanges && !_isSaving) ? _saveProfile : null,
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
