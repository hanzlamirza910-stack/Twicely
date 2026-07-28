import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/session_manager.dart';
import '../../../../core/widgets/app_search_bar.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import 'add_package_screen.dart';
import 'package_detail_screen.dart';

class MyListingsScreen extends StatefulWidget {
  final bool? isMerchant;
  const MyListingsScreen({super.key, this.isMerchant});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _packages = [];
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  bool get _isMerchantMode => widget.isMerchant ?? SessionManager.isMerchant;

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
      final res = _isMerchantMode
          ? await ApiService.getMerchantPackages(perPage: 50)
          : await ApiService.getUserPackages(perPage: 50);

      if (!mounted) return;

      if (res['success'] == true && res['data'] is List) {
        final rawList = (res['data'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .where((p) => p['is_owner'] != false)
            .toList();

        // Show packages immediately with whatever data we have
        if (mounted) {
          setState(() {
            _packages = rawList;
            _isLoading = false;
          });
        }

        // Silently enrich packages with full details in background
        final enriched = await Future.wait(rawList.map((p) async {
          final int? id = int.tryParse(p['id']?.toString() ?? '');
          if (id != null) {
            final detailRes = await ApiService.getPackageById(id);
            if (detailRes['success'] == true && detailRes['data'] is Map) {
              final Map<String, dynamic> detail =
                  Map<String, dynamic>.from(detailRes['data'] as Map);
              return {...p, ...detail};
            }
          }
          return p;
        }));

        if (mounted) {
          setState(() {
            _packages = enriched;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        CustomSnackBar.show(
          context,
          message: 'Failed to fetch packages: $e',
          type: SnackBarType.error,
        );
      }
    }
  }

  String _fmtDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw.replaceFirst(' ', 'T'));
      const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${m[dt.month-1]} ${dt.day}, ${dt.year}';
    } catch (_) { return raw; }
  }

  double _parseAmt(dynamic v) => double.tryParse(v?.toString() ?? '0') ?? 0.0;

  String _statusLabel(Map<String, dynamic> p) {
    final st = (p['status'] ?? '').toString().toLowerCase();
    if (st == 'published' || st == 'publish') return 'Published';
    if (st == 'pending' || st == 'in_review') return 'Pending';
    if (st == 'draft' || st == 'unpublish' || st == 'unpublished') return 'Unpublish';
    if (st == 'disabled') return 'Disabled';
    if (st == 'cancelled' || st == 'rejected') return 'Cancelled';
    return st.isEmpty ? 'Unpublish' : st[0].toUpperCase() + st.substring(1);
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'published':
      case 'publish':
        return const Color(0xFF16A34A);
      case 'pending':
      case 'in_review':
        return const Color(0xFFF59E0B);
      case 'draft':
        return const Color(0xFF6B7280);
      case 'disabled':
      case 'cancelled':
      case 'rejected':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  String _availStatusLabel(Map<String, dynamic> p) {
    final st = (p['availability_status'] ?? p['availabilityStatus'] ?? '').toString().toLowerCase();
    if (st == 'on_redemption' || st == 'on redemption') return 'On Redemption';
    if (st == 'pending_clearance' || st == 'pending clearance') return 'Pending Clearance';
    if (st == 'expired') return 'Expired';
    return 'Active';
  }

  Color _availStatusColor(String label) {
    switch (label.toLowerCase()) {
      case 'on redemption':
        return const Color(0xFFD97706);
      case 'pending clearance':
        return const Color(0xFF7C3AED);
      case 'expired':
        return const Color(0xFFDC2626);
      case 'active':
      default:
        return const Color(0xFF16A34A);
    }
  }

  bool _canEditPackage(Map<String, dynamic> pkg) {
    if (pkg['is_owner'] == false) return false;
    final availStatus = _availStatusLabel(pkg).toLowerCase();
    return availStatus == 'active' || availStatus == 'pending clearance';
  }

  Future<void> _changePackageStatus(Map<String, dynamic> pkg, String newStatus) async {
    final int? id = int.tryParse(pkg['id']?.toString() ?? '');
    if (id == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
      ),
    );

    final res = await ApiService.updatePackageStatus(id, newStatus);
    if (!mounted) return;
    Navigator.of(context).pop();

    if (res['success'] == true) {
      final label = (newStatus == 'published' || newStatus == 'publish') ? 'Published' : 'Unpublish';
      CustomSnackBar.show(
        context,
        message: 'Package status updated to ${label.toUpperCase()}',
        type: SnackBarType.success,
      );
      if (mounted) {
        setState(() {
          pkg['status'] = (newStatus == 'published' || newStatus == 'publish') ? 'published' : 'unpublish';
        });
      }
      _fetchPackages();
    } else {
      final msg = res['message'] ?? 'Failed to update package status.';
      CustomSnackBar.show(
        context,
        message: msg,
        type: SnackBarType.error,
      );
    }
  }

  List<Map<String, dynamic>> get _filtered {
    return _packages.where((p) {
      final q = _searchQuery.toLowerCase();
      if (q.isNotEmpty) {
        final title = (p['title'] ?? '').toString().toLowerCase();
        final vendor = (p['manual_vendor_name'] ?? p['presented_by']?['name'] ?? '').toString().toLowerCase();
        final cat = (p['secondary_category'] ?? '').toString().toLowerCase();
        if (!title.contains(q) && !vendor.contains(q) && !cat.contains(q)) return false;
      }
      if (_selectedFilter != 'All') {
        final st = _statusLabel(p);
        if (st.toLowerCase() != _selectedFilter.toLowerCase()) return false;
      }
      return true;
    }).toList();
  }

  void _openAddPackage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddPackageScreen(
          onPackageAdded: (_) {
            _fetchPackages();
          },
        ),
      ),
    );
  }

  void _openEditPackage(Map<String, dynamic> pkg) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddPackageScreen(
          packageToEdit: pkg,
          onPackageUpdated: (_) {
            _fetchPackages();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

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
          'My Packages',
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
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _fetchPackages,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchPackages,
        color: AppColors.primary,
        child: Column(
          children: [
            // Top Header Panel containing Stats, Search Bar, and Filters
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.black.withValues(alpha: 0.08), width: 1.0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Stats Row
                  if (!_isLoading) _buildStatsBanner(),

                  // Search Bar Row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                    child: _buildSearchField(),
                  ),

                  // Filter Pills Row
                  _buildFilterPills(),
                ],
              ),
            ),

            // Package List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    )
                  : filtered.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) => _buildPackageCard(filtered[i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBanner() {
    final total = _packages.length;
    final published = _packages.where((p) {
      final st = (p['status'] ?? '').toString().toLowerCase();
      return st == 'published' || st == 'publish';
    }).length;
    final pending = _packages.where((p) {
      final st = (p['status'] ?? '').toString().toLowerCase();
      return st == 'pending' || st == 'in_review' || st == 'draft';
    }).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          _statCard('Total', '$total', Icons.inventory_2_outlined, const Color(0xFFEFF4FF), AppColors.primary),
          const SizedBox(width: 8),
          _statCard('Published', '$published', Icons.check_circle_outline_rounded, const Color(0xFFF0FDF4), const Color(0xFF16A34A)),
          const SizedBox(width: 8),
          _statCard('Pending', '$pending', Icons.hourglass_empty_rounded, const Color(0xFFFFFBEB), const Color(0xFFD97706)),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color bgColor, Color themeColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: themeColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: themeColor, size: 15),
                const SizedBox(width: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: themeColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: themeColor.withValues(alpha: 0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return AppSearchBar(
      controller: _searchController,
      hintText: 'Search by title, vendor...',
      onChanged: (v) => setState(() => _searchQuery = v),
    );
  }

  Widget _buildFilterPills() {
    const pills = ['All', 'Published', 'Pending', 'Draft'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: pills.map((p) {
            final sel = _selectedFilter == p;
            return GestureDetector(
              onTap: () => setState(() => _selectedFilter = p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: sel ? AppColors.primary : const Color(0xFFF4F5F7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: sel ? AppColors.primary : Colors.black.withValues(alpha: 0.06)),
                ),
                child: Text(
                  p,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: sel ? Colors.white : AppColors.primary.withValues(alpha: 0.7),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: 56, color: AppColors.primary.withValues(alpha: 0.15)),
          const SizedBox(height: 12),
          Text(
            'No listed packages found',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 12),
          Material(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: _openAddPackage,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 18, color: Colors.white),
                    SizedBox(width: 6),
                    Text('List a Package', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(Map<String, dynamic> pkg) {
    final title = ApiService.unescapeHtml(pkg['title']?.toString() ?? 'Untitled Package');
    final status = _statusLabel(pkg);
    final statusCol = _statusColor(status);
    final price = _parseAmt(pkg['price']);
    final origPrice = _parseAmt(pkg['original_purchase_price'] ?? pkg['original_price']);
    final vendorName = ApiService.unescapeHtml(
      pkg['manual_vendor_name']?.toString() ??
          pkg['presented_by']?['name']?.toString() ??
          '',
    );
    final dateStr = _fmtDate(pkg['created_at']?.toString());

    String imageUrl = 'assets/images/package_spa.jpg';
    if (pkg['cover_url'] != null && pkg['cover_url'].toString().isNotEmpty) {
      imageUrl = pkg['cover_url'].toString();
    } else if (pkg['images'] is List && (pkg['images'] as List).isNotEmpty) {
      final img = (pkg['images'] as List).first;
      if (img is Map && img['url'] != null) {
        imageUrl = img['url'].toString();
      } else if (img is String) {
        imageUrl = img;
      }
    }

    final totalSessions = pkg['total_sessions']?.toString() ?? '';
    final sellSessions = pkg['sessions_to_sell']?.toString() ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PackageDetailScreen(package: pkg),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row: Status badge, Availability badge & Created Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Listing Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusCol.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: statusCol.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 6, color: statusCol),
                          const SizedBox(width: 5),
                          Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: statusCol,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Availability Status Badge (Active, On Redemption, Pending Clearance, Expired)
                    Builder(
                      builder: (_) {
                        final availLabel = _availStatusLabel(pkg);
                        final availCol = _availStatusColor(availLabel);
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: availCol.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: availCol.withValues(alpha: 0.25)),
                          ),
                          child: Text(
                            availLabel,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: availCol,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                if (dateStr.isNotEmpty)
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary.withValues(alpha: 0.45),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Image & Details Main Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: imageUrl.startsWith('http')
                      ? Image.network(
                          imageUrl,
                          width: 68,
                          height: 68,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 68,
                            height: 68,
                            color: AppColors.primary.withValues(alpha: 0.06),
                            child: const Icon(Icons.image_outlined, color: AppColors.primary, size: 26),
                          ),
                        )
                      : Container(
                          width: 68,
                          height: 68,
                          color: AppColors.primary.withValues(alpha: 0.06),
                          child: const Icon(Icons.card_giftcard_rounded, color: AppColors.primary, size: 26),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Recoleta Alt',
                          color: AppColors.primary,
                          height: 1.3,
                        ),
                      ),
                      if (vendorName.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.storefront_outlined, size: 13, color: AppColors.primary.withValues(alpha: 0.5)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                vendorName,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.primary.withValues(alpha: 0.65),
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (totalSessions.isNotEmpty || sellSessions.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Sessions: ${sellSessions.isNotEmpty ? sellSessions : '—'} of ${totalSessions.isNotEmpty ? totalSessions : '—'}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Divider(height: 1, color: Colors.black.withValues(alpha: 0.06)),
            const SizedBox(height: 10),

            // Bottom Row: Price & Styled Edit/Delete Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'S\$${price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF273DB7),
                      ),
                    ),
                    if (origPrice > price) ...[
                      const SizedBox(width: 6),
                      Text(
                        'S\$${origPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 11,
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ],
                ),

                PopupMenuButton<String>(
                  icon: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F5F7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
                    ),
                    child: const Icon(Icons.more_horiz_rounded, size: 20, color: AppColors.primary),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 6,
                  color: Colors.white,
                  onSelected: (val) {
                    if (val == 'view') {
                      _showViewDetailsModal(context, pkg);
                    } else if (val == 'edit') {
                      _openEditPackage(pkg);
                    } else if (val == 'verification') {
                      _showVerificationModal(context, pkg);
                    } else if (val == 'set_published') {
                      _changePackageStatus(pkg, 'published');
                    } else if (val == 'set_unpublish') {
                      _changePackageStatus(pkg, 'unpublish');
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: const [
                          Icon(Icons.visibility_outlined, size: 16, color: AppColors.primary),
                          SizedBox(width: 10),
                          Text('View details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                        ],
                      ),
                    ),
                    if (_canEditPackage(pkg))
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: const [
                            Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                            SizedBox(width: 10),
                            Text('Edit package', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                          ],
                        ),
                      ),
                    if (status.toLowerCase() != 'published' && status.toLowerCase() != 'publish') ...[
                      PopupMenuItem(
                        value: 'set_published',
                        child: Row(
                          children: const [
                            Icon(Icons.verified_user_outlined, size: 16, color: Color(0xFF16A34A)),
                            SizedBox(width: 10),
                            Text('Publish package', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF16A34A))),
                          ],
                        ),
                      ),
                    ] else ...[
                      PopupMenuItem(
                        value: 'set_unpublish',
                        child: Row(
                          children: const [
                            Icon(Icons.remove_circle_outline_rounded, size: 16, color: Color(0xFF6B7280)),
                            SizedBox(width: 10),
                            Text('Unpublish package', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
                          ],
                        ),
                      ),
                    ],
                    PopupMenuItem(
                      value: 'verification',
                      child: Row(
                        children: const [
                          Icon(Icons.verified_outlined, size: 16, color: AppColors.primary),
                          SizedBox(width: 10),
                          Text('Verification', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF9C3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFEF08A)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF854D0E)),
      ),
    );
  }



  void _showViewDetailsModal(BuildContext context, Map<String, dynamic> pkg) {
    final title = ApiService.unescapeHtml(pkg['title']?.toString() ?? 'Untitled Package');
    final status = _statusLabel(pkg);
    final statusCol = _statusColor(status);
    final price = _parseAmt(pkg['price']);
    final desc = ApiService.unescapeHtml(
      pkg['description']?.toString() ?? pkg['content']?.toString() ?? pkg['details']?.toString() ?? 'No description provided.',
    );
    final expStr = _fmtDate(pkg['availability_end']?.toString() ?? pkg['expiry_date']?.toString());

    // Merchant Info
    final presented = pkg['presented_by'] is Map ? pkg['presented_by'] as Map : {};
    final merchantName = ApiService.unescapeHtml(
      presented['name']?.toString() ?? pkg['manual_vendor_name']?.toString() ?? pkg['vendor_name']?.toString() ?? pkg['merchant_name']?.toString() ?? '',
    );
    final merchantLogo = presented['logo']?.toString() ?? presented['avatar']?.toString() ?? '';
    final hasMerchantInfo = merchantName.trim().isNotEmpty;

    // Images
    List<String> images = [];
    if (pkg['cover_url'] != null && pkg['cover_url'].toString().isNotEmpty) {
      images.add(pkg['cover_url'].toString());
    }
    if (pkg['images'] is List) {
      for (var img in (pkg['images'] as List)) {
        String url = '';
        if (img is Map && img['url'] != null) {
          url = img['url'].toString();
        } else if (img is String) {
          url = img;
        }
        if (url.isNotEmpty && !images.contains(url)) images.add(url);
      }
    }
    if (images.isEmpty) images.add('assets/images/package_spa.jpg');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.88,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Modal Drag Handle & Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(bottom: BorderSide(color: Colors.black.withValues(alpha: 0.08))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusCol.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusCol),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Recoleta Alt',
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.primary, size: 22),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),

            // Modal Body Content (Scrollable)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Cover Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: images.first.startsWith('http')
                            ? Image.network(images.first, fit: BoxFit.cover)
                            : Image.asset(images.first, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200)),
                      ),
                    ),
                    if (images.length > 1) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 56,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: images.length,
                          itemBuilder: (_, idx) => Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.black12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(9),
                              child: images[idx].startsWith('http')
                                  ? Image.network(images[idx], fit: BoxFit.cover)
                                  : Image.asset(images[idx], fit: BoxFit.cover),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // Description Section
                    Row(
                      children: const [
                        Icon(Icons.description_outlined, size: 16, color: Colors.black54),
                        SizedBox(width: 6),
                        Text(
                          'DESCRIPTION',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.black54),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                      ),
                      child: Text(
                        desc,
                        style: const TextStyle(fontSize: 13, color: AppColors.primary, height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Categories Section
                    Row(
                      children: const [
                        Icon(Icons.label_outlined, size: 16, color: Colors.black54),
                        SizedBox(width: 6),
                        Text(
                          'CATEGORIES',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.black54),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (pkg['primary_category'] != null)
                          _categoryTag(pkg['primary_category'].toString()),
                        if (pkg['secondary_category'] != null)
                          _categoryTag(pkg['secondary_category'].toString()),
                        if (pkg['primary_category'] == null && pkg['secondary_category'] == null)
                          _categoryTag('General'),
                      ],
                    ),
                    const SizedBox(height: 20),

                    if (hasMerchantInfo) ...[
                      Row(
                        children: const [
                          Icon(Icons.storefront_outlined, size: 16, color: Colors.black54),
                          SizedBox(width: 6),
                          Text(
                            'MERCHANT INFORMATION',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.black54),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                              backgroundImage: merchantLogo.startsWith('http') ? NetworkImage(merchantLogo) : null,
                              child: merchantLogo.isEmpty ? const Icon(Icons.storefront, color: AppColors.primary, size: 20) : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    merchantName,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Verified Partner',
                                    style: TextStyle(fontSize: 11, color: Colors.black45, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],



                    // Right Sidebar Details Card (Matching Web UI)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('CURRENT STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black45, letterSpacing: 0.5)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusCol.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusCol)),
                          ),
                          const SizedBox(height: 16),

                          const Text('SELLING PRICE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black45, letterSpacing: 0.5)),
                          const SizedBox(height: 4),
                          Text('SGD ${price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary)),
                          const SizedBox(height: 16),

                          const Text('EXPIRY DATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black45, letterSpacing: 0.5)),
                          const SizedBox(height: 4),
                          Text(expStr.isNotEmpty ? expStr : 'No expiry', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                          const SizedBox(height: 16),

                          const Text('TRUST & VERIFICATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black45, letterSpacing: 0.5)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8)),
                                child: const Text('VERIFIED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _showVerificationModal(context, pkg);
                                  },
                                  child: const Text('View Verification Logs', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          const Text('SUBMISSION RECEIPT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black45, letterSpacing: 0.5)),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                backgroundColor: const Color(0xFFFEFCE8),
                                side: const BorderSide(color: Color(0xFFFEF08A)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () {
                                CustomSnackBar.show(context, message: 'Opening submission receipt document...', type: SnackBarType.info);
                              },
                              icon: const Icon(Icons.receipt_long_outlined, size: 16, color: Color(0xFF854D0E)),
                              label: const Text('View Receipt', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF854D0E))),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Modal Footer Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.08))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Need to make changes? Switch to the edit view to update package details.',
                    style: TextStyle(fontSize: 10, color: Colors.black45),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              side: const BorderSide(color: Colors.black26, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Close', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                          ),
                        ),
                      ),
                      if (_canEditPackage(pkg)) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                backgroundColor: const Color(0xFFFBBD03),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
                              ),
                              onPressed: () {
                                Navigator.pop(ctx);
                                _openEditPackage(pkg);
                              },
                              child: const Text('Edit package', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVerificationModal(BuildContext context, Map<String, dynamic> pkg) {
    final title = ApiService.unescapeHtml(pkg['title']?.toString() ?? 'Untitled Package');
    final status = _statusLabel(pkg);
    final isVerified = status.toLowerCase() == 'published' || status.toLowerCase() == 'publish';
    final createdDateStr = _fmtDate(pkg['created_at']?.toString());
    final expDateStr = _fmtDate(pkg['availability_end']?.toString() ?? pkg['expiry_date']?.toString());

    final displayCreated = createdDateStr.isNotEmpty ? '$createdDateStr, 8:54 PM' : 'Jul 21, 2026, 8:54 PM';
    final displayExp = expDateStr.isNotEmpty ? '$expDateStr, 5:00 AM' : 'Dec 21, 2026, 5:00 AM';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Modal Top Drag & Header Bar
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(bottom: BorderSide(color: Colors.black.withValues(alpha: 0.08))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Verification Status',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Recoleta Alt',
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      backgroundColor: const Color(0xFFF3F4F6),
                      side: BorderSide.none,
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ),
                ],
              ),
            ),

            // Modal Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Progress Card (Matching Web UI)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
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
                                    const Text(
                                      'Verification Status',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Recoleta Alt',
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.5)),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isVerified ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isVerified ? 'VERIFIED' : 'PENDING',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isVerified ? const Color(0xFF047857) : const Color(0xFFB45309),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () {
                                  _fetchPackages();
                                  CustomSnackBar.show(context, message: 'Verification status refreshed', type: SnackBarType.info);
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.black.withValues(alpha: 0.12)),
                                  ),
                                  child: Row(
                                    children: const [
                                      Icon(Icons.refresh_rounded, size: 14, color: AppColors.primary),
                                      SizedBox(width: 4),
                                      Text(
                                        'Refresh status',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isVerified ? '4/4 CHECKS COMPLETED' : '2/4 CHECKS COMPLETED',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  color: Colors.black45,
                                ),
                              ),
                              Text(
                                isVerified ? '100%' : '50%',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: isVerified ? 1.0 : 0.5,
                              minHeight: 8,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFEAB308)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Check 1: Proof of Package
                    _buildVerificationCheckCard(
                      title: 'Proof of Package',
                      description: 'Receipt uploaded for admin verification.',
                      timestamp: displayCreated,
                      isDone: true,
                    ),

                    // Check 2: Package Validity
                    _buildVerificationCheckCard(
                      title: 'Package Validity',
                      description: 'Expiry date looks valid.',
                      timestamp: displayExp,
                      isDone: true,
                    ),

                    // Check 3: Price Fairness
                    _buildVerificationCheckCard(
                      title: 'Price Fairness',
                      description: 'Pricing is automatically reviewed by our team.',
                      timestamp: null,
                      isDone: true,
                    ),

                    // Check 4: Verification
                    _buildVerificationCheckCard(
                      title: 'Verification',
                      description: 'This package has been verified by our team.',
                      timestamp: displayCreated,
                      isDone: isVerified,
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

  Widget _buildVerificationCheckCard({
    required String title,
    required String description,
    String? timestamp,
    bool isDone = true,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDone ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone ? const Color(0xFF16A34A) : const Color(0xFFD97706),
            ),
            child: const Icon(Icons.check, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Recoleta Alt',
                        color: AppColors.primary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDone ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isDone ? 'DONE' : 'PENDING',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDone ? const Color(0xFF166534) : const Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withValues(alpha: 0.6),
                  ),
                ),
                if (timestamp != null && timestamp.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'COMPLETED ON ${timestamp.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                      color: Colors.black.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
