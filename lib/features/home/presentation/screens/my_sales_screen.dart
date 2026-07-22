import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/session_manager.dart';
import 'sale_detail_screen.dart';

import '../../../../core/widgets/app_search_bar.dart';

class MySalesScreen extends StatefulWidget {
  final bool? isMerchant;
  const MySalesScreen({super.key, this.isMerchant});

  @override
  State<MySalesScreen> createState() => _MySalesScreenState();
}

class _MySalesScreenState extends State<MySalesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _sales = [];
  String _selectedPill = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  bool get _isMerchantMode => widget.isMerchant ?? SessionManager.isMerchant;

  @override
  void initState() {
    super.initState();
    _fetchSales();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchSales() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final res = _isMerchantMode
        ? await ApiService.getMerchantOrders(perPage: 50)
        : await ApiService.getMySales(perPage: 50);
    if (!mounted) return;
    if (res['success'] == true && res['data'] is List) {
      setState(() {
        _sales = (res['data'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _fmt(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw.replaceFirst(' ', 'T'));
      const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      final h = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
      final ap = dt.hour >= 12 ? 'PM' : 'AM';
      return '${m[dt.month-1]} ${dt.day}, ${dt.year}, ${h.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')} $ap';
    } catch (_) { return raw; }
  }

  double _parseAmt(dynamic v) => double.tryParse(v?.toString() ?? '0') ?? 0.0;

  String _payStatus(Map<String, dynamic> s) {
    final p = (s['payment_status'] ?? '').toString().toLowerCase();
    if (p == 'paid') return 'Paid';
    if (p == 'refunded') return 'Refunded';
    return _cap(p.isEmpty ? 'Pending' : p);
  }

  String _ordStatus(Map<String, dynamic> s) {
    final st = (s['status'] ?? '').toString().toLowerCase();
    if (st == 'completed') return 'Completed';
    if (st == 'cancelled') return 'Cancelled';
    if (st == 'processing') return 'Processing';
    return _cap(st.isEmpty ? 'Pending' : st);
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'paid': case 'completed': return const Color(0xFF16A34A);
      case 'refunded': return const Color(0xFF6B7280);
      case 'cancelled': return const Color(0xFFDC2626);
      default: return const Color(0xFFF59E0B);
    }
  }

  String _cap(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  List<Map<String, dynamic>> get _filtered {
    return _sales.where((s) {
      final q = _searchQuery.toLowerCase();
      if (q.isNotEmpty) {
        final num = (s['order_number'] ?? '').toString().toLowerCase();
        final buyer = (s['customer_name'] ?? '').toString().toLowerCase();
        final pkgs = (s['package_names'] as List?)?.join(' ').toLowerCase() ?? '';
        if (!num.contains(q) && !buyer.contains(q) && !pkgs.contains(q)) return false;
      }
      if (_selectedPill != 'All') {
        final ps = _payStatus(s);
        final os = _ordStatus(s);
        if (ps != _selectedPill && os != _selectedPill) return false;
      }
      return true;
    }).toList();
  }

  void _showSaleDetail(Map<String, dynamic> sale) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SaleDetailScreen(
          sale: sale,
          isMerchant: _isMerchantMode,
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        scrolledUnderElevation: 0.5, shadowColor: Colors.black12,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
            onPressed: () => Navigator.of(context).pop()),
        title: const Text('My Sales',
            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold,
                fontFamily: 'Recoleta Alt', fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
              onPressed: _fetchSales),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchSales,
        color: AppColors.primary,
        child: Column(children: [
          // Unified Top Panel for Search, Stats, and Filter Pills
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
                // Stats Banner
                if (!_isLoading) _buildStatsBanner(),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: AppSearchBar(
                    controller: _searchController,
                    hintText: 'Search by order, buyer, package...',
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),

                // Filter Pills
                _buildFilterPills(),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)))
                : filtered.isEmpty
                    ? _buildEmpty()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _buildSaleCard(filtered[i])),
          ),
        ]),
      ),
    );
  }

  Widget _buildStatsBanner() {
    final total = _sales.length;
    final completed = _sales.where((s) =>
        ['completed','paid','processing'].contains(
            (s['status'] ?? '').toString().toLowerCase())).length;
    final earnings = _sales
        .where((s) => ['completed','paid','processing'].contains(
            (s['status'] ?? '').toString().toLowerCase()))
        .fold<double>(0, (sum, s) => sum + _parseAmt(s['seller_amount'] ?? s['total']));

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(children: [
        _stat('Total', '$total', Icons.receipt_long_rounded),
        const SizedBox(width: 8),
        _stat('Completed', '$completed', Icons.check_circle_rounded),
        const SizedBox(width: 8),
        _stat('Earnings', 'S\$${earnings.toStringAsFixed(0)}',
            Icons.account_balance_wallet_rounded),
      ]),
    );
  }

  Widget _stat(String label, String value, IconData icon) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight)),
      child: Column(children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(color: AppColors.primary,
            fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: AppColors.primary.withValues(alpha: 0.5),
            fontSize: 9), textAlign: TextAlign.center),
      ]),
    ),
  );

  Widget _buildFilterPills() {
    const pills = ['All','Paid','Completed','Refunded','Cancelled'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: pills.map((p) {
          final sel = _selectedPill == p;
          return GestureDetector(
            onTap: () => setState(() => _selectedPill = p),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: sel ? AppColors.primary : const Color(0xFFF4F5F7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: sel ? AppColors.primary : Colors.black.withValues(alpha: 0.06)),
              ),
              child: Text(p, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                  color: sel ? Colors.white : AppColors.primary.withValues(alpha: 0.7))),
            ),
          );
        }).toList()),
      ),
    );
  }

  Widget _buildEmpty() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.sell_rounded, size: 56, color: AppColors.primary.withValues(alpha: 0.15)),
    const SizedBox(height: 12),
    Text('No sales yet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
        color: AppColors.primary.withValues(alpha: 0.4))),
  ]));

  // ── Compact sale card (tap → bottom sheet) ───────────────────────────────

  Widget _buildSaleCard(Map<String, dynamic> sale) {
    final orderNum = sale['order_number']?.toString() ?? '#${sale['id']}';
    final dateTime = _fmt(sale['created_at']?.toString());
    final buyer = sale['customer_name']?.toString() ?? 'Customer';
    final pkgCount = (sale['package_count'] as num?)?.toInt() ??
        (sale['package_names'] as List?)?.length ?? 1;
    final total = _parseAmt(sale['total']);
    final ps = _payStatus(sale);
    final os = _ordStatus(sale);
    final firstPkg = (sale['package_names'] as List?)?.isNotEmpty == true
        ? (sale['package_names'] as List).first.toString() : '';

    final badges = ps == os ? [ps] : [ps, os];

    return GestureDetector(
      onTap: () => _showSaleDetail(sale),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Header
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Order #$orderNum', style: const TextStyle(fontSize: 13,
                  fontWeight: FontWeight.bold, color: AppColors.primary)),
              if (dateTime.isNotEmpty || firstPkg.isNotEmpty) ...[
                const SizedBox(height: 3),
                Row(children: [
                  Icon(Icons.calendar_today_outlined, size: 10,
                      color: AppColors.primary.withValues(alpha: 0.4)),
                  const SizedBox(width: 4),
                  Expanded(child: Text(
                    [if (dateTime.isNotEmpty) dateTime,
                     if (firstPkg.isNotEmpty) firstPkg].join(' · '),
                    style: TextStyle(fontSize: 10,
                        color: AppColors.primary.withValues(alpha: 0.45)),
                    overflow: TextOverflow.ellipsis, maxLines: 1)),
                ]),
              ],
            ])),
            Wrap(spacing: 4, children: badges.map((b) => _badgeWidget(b, _statusColor(b))).toList()),
          ]),
          const SizedBox(height: 10),
          // Buyer + count + amount
          Row(children: [
            Icon(Icons.person_outline_rounded, size: 13,
                color: AppColors.primary.withValues(alpha: 0.4)),
            const SizedBox(width: 4),
            Expanded(child: Text('Buyer: $buyer', style: TextStyle(fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primary.withValues(alpha: 0.65)),
                overflow: TextOverflow.ellipsis)),
            Icon(Icons.inventory_2_outlined, size: 12,
                color: AppColors.primary.withValues(alpha: 0.4)),
            const SizedBox(width: 3),
            Text('$pkgCount pkg', style: TextStyle(fontSize: 10,
                color: AppColors.primary.withValues(alpha: 0.5))),
            const SizedBox(width: 10),
            Text('\$ ${total.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900,
                    color: Color(0xFF273DB7))),
          ]),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            Text('Tap for details', style: TextStyle(fontSize: 10,
                color: AppColors.primary.withValues(alpha: 0.3),
                fontStyle: FontStyle.italic)),
            const SizedBox(width: 3),
            Icon(Icons.keyboard_arrow_up_rounded, size: 13,
                color: AppColors.primary.withValues(alpha: 0.3)),
          ]),
        ]),
      ),
    );
  }

  Widget _badgeWidget(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.circle, size: 6, color: color),
      const SizedBox(width: 3),
      Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
    ]),
  );
}


