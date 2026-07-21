import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/session_manager.dart';
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
            .toList();

        // Enrich packages with full details from /packages/:id if necessary
        final enriched = await Future.wait(rawList.map((p) async {
          final int? id = int.tryParse(p['id']?.toString() ?? '');
          if (id != null) {
            final detailRes = await ApiService.getPackageById(id);
            if (detailRes['success'] == true && detailRes['data'] is Map) {
              final Map<String, dynamic> detail = Map<String, dynamic>.from(detailRes['data'] as Map);
              return {...p, ...detail};
            }
          }
          return p;
        }));

        if (mounted) {
          setState(() {
            _packages = enriched;
            _isLoading = false;
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
    if (st == 'draft') return 'Draft';
    if (st == 'cancelled' || st == 'rejected') return 'Cancelled';
    return st.isEmpty ? 'Pending' : st[0].toUpperCase() + st.substring(1);
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
      case 'cancelled':
      case 'rejected':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF3B82F6);
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

  Future<void> _deletePackage(Map<String, dynamic> pkg) async {
    final id = int.tryParse(pkg['id']?.toString() ?? '');
    if (id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_forever_rounded,
                  color: Color(0xFFDC2626),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Delete Package Listing',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Recoleta Alt',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Are you sure you want to delete "${pkg['title'] ?? 'this package'}"? This action cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                        backgroundColor: Colors.grey.shade100,
                      ),
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        backgroundColor: const Color(0xFFDC2626),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text(
                        'Delete',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
      ),
    );

    try {
      final res = await ApiService.deletePackage(id);
      if (!mounted) return;
      Navigator.of(context).pop(); // dismiss loading

      if (res['success'] == true) {
        CustomSnackBar.show(context, message: 'Package deleted successfully', type: SnackBarType.success);
        _fetchPackages();
      } else {
        CustomSnackBar.show(context, message: res['message'] ?? 'Failed to delete package', type: SnackBarType.error);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      CustomSnackBar.show(context, message: 'Error: $e', type: SnackBarType.error);
    }
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
          'My Listings',
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

                  // Search Bar & Add Button Row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                    child: Row(
                      children: [
                        Expanded(child: _buildSearchField()),
                        const SizedBox(width: 10),
                        Material(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: _openAddPackage,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_rounded, size: 18, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    'Add',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
          _statCard('Total Listings', '$total', Icons.inventory_2_outlined, const Color(0xFFEFF4FF), AppColors.primary),
          const SizedBox(width: 8),
          _statCard('Published', '$published', Icons.check_circle_outline_rounded, const Color(0xFFF0FDF4), const Color(0xFF16A34A)),
          const SizedBox(width: 8),
          _statCard('Pending/Draft', '$pending', Icons.hourglass_empty_rounded, const Color(0xFFFFFBEB), const Color(0xFFD97706)),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color bgColor, Color themeColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: themeColor.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: themeColor, size: 16),
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
            Text(
              label,
              style: TextStyle(
                color: themeColor.withValues(alpha: 0.8),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F5F7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(fontSize: 13, color: AppColors.primary),
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          hintText: 'Search by title, vendor...',
          hintStyle: TextStyle(color: AppColors.primary.withValues(alpha: 0.4), fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 19),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 17, color: AppColors.primary),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
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
    final title = pkg['title']?.toString() ?? 'Untitled Package';
    final status = _statusLabel(pkg);
    final statusCol = _statusColor(status);
    final price = _parseAmt(pkg['price']);
    final origPrice = _parseAmt(pkg['original_purchase_price'] ?? pkg['original_price']);
    final vendorName = pkg['manual_vendor_name']?.toString() ??
        pkg['presented_by']?['name']?.toString() ??
        '';
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
            // Header Row: Status badge & Created Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusCol.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (origPrice > price)
                      Text(
                        'S\$${origPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 11,
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    Text(
                      'S\$ ${price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF273DB7),
                      ),
                    ),
                  ],
                ),

                Row(
                  children: [
                    InkWell(
                      onTap: () => _openEditPackage(pkg),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF4FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF273DB7)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _deletePackage(pkg),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
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
}
