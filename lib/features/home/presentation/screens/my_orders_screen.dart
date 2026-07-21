import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/session_manager.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';
  bool _isLoading = true;
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final res = await ApiService.getMyOrders(perPage: 50);
    if (!mounted) return;
    if (res['success'] == true && res['data'] is List) {
      setState(() {
        _orders = (res['data'] as List)
            .map((o) => Map<String, dynamic>.from(o as Map))
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

  String _payStatus(Map<String, dynamic> o) {
    final p = (o['payment_status'] ?? '').toString().toLowerCase();
    if (p == 'paid') return 'Paid';
    if (p == 'refunded') return 'Refunded';
    return _cap(p.isEmpty ? 'Pending' : p);
  }

  String _ordStatus(Map<String, dynamic> o) {
    final s = (o['status'] ?? '').toString().toLowerCase();
    if (s == 'completed') return 'Completed';
    if (s == 'cancelled') return 'Cancelled';
    if (s == 'processing') return 'Processing';
    return _cap(s.isEmpty ? 'Pending' : s);
  }

  int _timelineStep(Map<String, dynamic> o) {
    final s = (o['status'] ?? '').toString().toLowerCase();
    final p = (o['payment_status'] ?? '').toString().toLowerCase();
    if (s == 'completed') return 3;
    if (o['redeemed_at'] != null) return 2;
    if (p == 'paid' || s == 'processing') return 1;
    return 0;
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

  double _parseAmt(dynamic v) => double.tryParse(v?.toString() ?? '0') ?? 0.0;

  List<Map<String, dynamic>> get _filtered {
    return _orders.where((o) {
      final q = _searchQuery.toLowerCase();
      if (q.isNotEmpty) {
        final num = (o['order_number'] ?? '').toString().toLowerCase();
        final sellers = (o['sellers'] as List?)
            ?.map((s) => (s['name'] ?? '').toString().toLowerCase()).join(' ') ?? '';
        final pkgs = (o['package_names'] as List?)
            ?.map((p) => p.toString().toLowerCase()).join(' ') ?? '';
        if (!num.contains(q) && !sellers.contains(q) && !pkgs.contains(q)) return false;
      }
      if (_selectedFilter != 'All') {
        final ps = _payStatus(o);
        final os = _ordStatus(o);
        if (ps != _selectedFilter && os != _selectedFilter) return false;
      }
      return true;
    }).toList();
  }

  // ── Bottom sheet detail ─────────────────────────────────────────────────

  void _showOrderDetail(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OrderDetailSheet(order: order, fmt: _fmt,
          timelineStep: _timelineStep(order), payStatus: _payStatus(order),
          ordStatus: _ordStatus(order), statusColor: _statusColor,
          parseAmt: _parseAmt),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────

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
        title: const Text('My Orders',
            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold,
                fontFamily: 'Recoleta Alt', fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
              onPressed: _fetchOrders),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)))
          : RefreshIndicator(
              onRefresh: _fetchOrders,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(SessionManager.userName ?? 'My Orders',
                        style: const TextStyle(fontFamily: 'Recoleta Alt',
                            fontSize: 24, fontWeight: FontWeight.bold,
                            color: AppColors.primary)),
                    const SizedBox(height: 4),
                    Text('Your purchase history',
                        style: TextStyle(fontSize: 12,
                            color: AppColors.primary.withValues(alpha: 0.45))),
                    const SizedBox(height: 16),

                    // Search
                    _buildSearch(),
                    const SizedBox(height: 12),

                    // Filter pills
                    _buildPills(['All','Paid','Completed','Refunded','Cancelled']),
                    const SizedBox(height: 20),

                    // List
                    if (filtered.isEmpty) _buildEmpty()
                    else ...filtered.map((o) => _buildOrderCard(o)),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSearch() => TextField(
    controller: _searchController,
    style: const TextStyle(fontSize: 13, color: AppColors.primary),
    onChanged: (v) => setState(() => _searchQuery = v),
    decoration: InputDecoration(
      filled: true, fillColor: Colors.white,
      hintText: 'Search by order, seller, package...',
      hintStyle: TextStyle(color: AppColors.primary.withValues(alpha: 0.35), fontSize: 13),
      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 19),
      suffixIcon: _searchQuery.isNotEmpty
          ? IconButton(icon: const Icon(Icons.close_rounded, size: 17, color: AppColors.primary),
              onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); })
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    ),
  );

  Widget _buildPills(List<String> pills) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(children: pills.map((f) {
      final sel = _selectedFilter == f;
      return GestureDetector(
        onTap: () => setState(() => _selectedFilter = f),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: sel ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: sel ? AppColors.primary : AppColors.primary.withValues(alpha: 0.1)),
          ),
          child: Text(f, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
              color: sel ? Colors.white : AppColors.primary)),
        ),
      );
    }).toList()),
  );

  Widget _buildEmpty() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 60),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.shopping_bag_outlined, size: 56, color: AppColors.primary.withValues(alpha: 0.15)),
      const SizedBox(height: 12),
      Text('No orders found', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
          color: AppColors.primary.withValues(alpha: 0.35))),
    ]),
  );

  // ── Compact order card (tap → bottom sheet) ──────────────────────────────

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderNum = order['order_number']?.toString() ?? '#${order['id']}';
    final dateTime = _fmt(order['created_at']?.toString());
    final sellers = (order['sellers'] as List?)
        ?.map((s) => (s as Map)['name']?.toString() ?? '').join(', ') ?? '—';
    final pkgCount = (order['package_count'] as num?)?.toInt() ??
        (order['package_names'] as List?)?.length ?? 1;
    final total = _parseAmt(order['total']);
    final ps = _payStatus(order);
    final os = _ordStatus(order);
    final step = _timelineStep(order);

    // Show both badges only if different
    final badges = ps == os ? [ps] : [ps, os];

    return GestureDetector(
      onTap: () => _showOrderDetail(order),
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
          // Header row
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Order #$orderNum', style: const TextStyle(fontSize: 13,
                  fontWeight: FontWeight.bold, color: AppColors.primary)),
              if (dateTime.isNotEmpty) ...[
                const SizedBox(height: 3),
                Row(children: [
                  Icon(Icons.calendar_today_outlined, size: 10,
                      color: AppColors.primary.withValues(alpha: 0.4)),
                  const SizedBox(width: 4),
                  Expanded(child: Text(dateTime, style: TextStyle(fontSize: 10,
                      color: AppColors.primary.withValues(alpha: 0.45)),
                      overflow: TextOverflow.ellipsis)),
                ]),
              ],
            ])),
            Wrap(spacing: 4, children: badges.map((b) =>
                _badge(b, _statusColor(b))).toList()),
          ]),
          const SizedBox(height: 10),
          // Compact timeline
          _miniTimeline(step),
          const SizedBox(height: 10),
          // Footer row
          Row(children: [
            Icon(Icons.person_outline_rounded, size: 13,
                color: AppColors.primary.withValues(alpha: 0.4)),
            const SizedBox(width: 4),
            Expanded(child: Text(sellers, style: TextStyle(fontSize: 11,
                color: AppColors.primary.withValues(alpha: 0.65),
                fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
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

  Widget _miniTimeline(int step) {
    const labels = ['Ordered', 'Paid', 'Redeem', 'Complete'];
    return Row(children: List.generate(7, (i) {
      if (i.isOdd) {
        return Expanded(child: Container(height: 2,
            color: (i ~/ 2) < step ? const Color(0xFF16A34A) : Colors.black12));
      }
      final idx = i ~/ 2;
      final done = idx <= step;
      return Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 20, height: 20,
            decoration: BoxDecoration(shape: BoxShape.circle,
                color: done ? const Color(0xFF16A34A) : Colors.white,
                border: Border.all(color: done ? const Color(0xFF16A34A) : Colors.black26, width: 1.5)),
            child: done ? const Icon(Icons.check_rounded, color: Colors.white, size: 11) : null),
        const SizedBox(height: 2),
        Text(labels[idx], style: TextStyle(fontSize: 7, fontWeight: FontWeight.w600,
            color: done ? const Color(0xFF16A34A) : AppColors.primary.withValues(alpha: 0.35))),
      ]);
    }));
  }

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.check_circle_outline_rounded, size: 9, color: color),
      const SizedBox(width: 3),
      Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
    ]),
  );
}

// ══ Bottom Sheet for full order detail ════════════════════════════════════════

class _OrderDetailSheet extends StatelessWidget {
  final Map<String, dynamic> order;
  final String Function(String?) fmt;
  final int timelineStep;
  final String payStatus;
  final String ordStatus;
  final Color Function(String) statusColor;
  final double Function(dynamic) parseAmt;

  const _OrderDetailSheet({
    required this.order, required this.fmt, required this.timelineStep,
    required this.payStatus, required this.ordStatus, required this.statusColor,
    required this.parseAmt,
  });

  @override
  Widget build(BuildContext context) {
    final orderNum = order['order_number']?.toString() ?? '#${order['id']}';
    final dateTime = fmt(order['created_at']?.toString());
    final sellers = (order['sellers'] as List?)
        ?.map((s) => (s as Map)['name']?.toString() ?? '').join(', ') ?? '—';
    final merchants = order['from_merchants'] is List
        ? List<Map<String, dynamic>>.from((order['from_merchants'] as List)
            .map((m) => Map<String, dynamic>.from(m as Map)))
        : <Map<String, dynamic>>[];
    final pkgCount = (order['package_count'] as num?)?.toInt() ??
        (order['package_names'] as List?)?.length ?? 1;
    final total = parseAmt(order['total']);
    final pkgNames = (order['package_names'] as List?)
        ?.map((p) => p.toString()).toList() ?? [];
    final payColor = statusColor(payStatus);
    final ordColor = statusColor(ordStatus);

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Handle bar
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.black12,
                  borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),

          // Title
          Row(children: [
            Expanded(child: Text('Order #$orderNum',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                    color: AppColors.primary, fontFamily: 'Recoleta Alt'))),
            IconButton(icon: const Icon(Icons.close_rounded, color: AppColors.primary, size: 20),
                onPressed: () => Navigator.of(context).pop()),
          ]),
          if (dateTime.isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 3),
              child: Row(children: [
                Icon(Icons.calendar_today_outlined, size: 11,
                    color: AppColors.primary.withValues(alpha: 0.4)),
                const SizedBox(width: 4),
                Text(dateTime, style: TextStyle(fontSize: 11,
                    color: AppColors.primary.withValues(alpha: 0.5))),
              ])),

          // Badges
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 4, children: [
            _badge(payStatus, payColor),
            if (ordStatus != payStatus) _badge(ordStatus, ordColor),
          ]),

          const SizedBox(height: 16),

          // Seller + package count row
          Row(children: [
            Icon(Icons.person_outline_rounded, size: 14,
                color: AppColors.primary.withValues(alpha: 0.5)),
            const SizedBox(width: 5),
            Expanded(child: Text('Seller: $sellers',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: AppColors.primary.withValues(alpha: 0.7)))),
            Icon(Icons.inventory_2_outlined, size: 13,
                color: AppColors.primary.withValues(alpha: 0.4)),
            const SizedBox(width: 3),
            Text('$pkgCount Package${pkgCount != 1 ? 's' : ''}',
                style: TextStyle(fontSize: 11,
                    color: AppColors.primary.withValues(alpha: 0.5))),
          ]),
          const SizedBox(height: 6),
          Align(alignment: Alignment.centerRight,
              child: Text('\$ ${total.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900,
                      color: Color(0xFF273DB7)))),

          const Divider(height: 24, color: Colors.black12),

          // 4-step Timeline
          _buildTimeline(timelineStep),

          const Divider(height: 24, color: Colors.black12),

          // Two-column details
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _sectionTitle('Order Details'),
              const SizedBox(height: 10),
              _lbl('ORDER NUMBER'), _val(orderNum),
              const SizedBox(height: 8),
              _lbl('SELLER'), _val(sellers),
              const SizedBox(height: 8),
              _lbl('FROM MERCHANT'),
              const SizedBox(height: 4),
              if (merchants.isEmpty) _val('—')
              else ...merchants.map((m) => _merchantChip(m)),
              const SizedBox(height: 8),
              _lbl('PURCHASE DATE'), _val(dateTime.isNotEmpty ? dateTime : '—'),
            ])),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _sectionTitle('Payment Details'),
              const SizedBox(height: 10),
              _lbl('TOTAL AMOUNT'),
              Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary)),
              const SizedBox(height: 10),
              _lbl('PAYMENT STATUS'),
              const SizedBox(height: 4),
              _badge(payStatus, payColor),
              const SizedBox(height: 8),
              _lbl('ORDER STATUS'),
              const SizedBox(height: 4),
              _badge(ordStatus, ordColor),
            ])),
          ]),

          // Package names
          if (pkgNames.isNotEmpty) ...[
            const Divider(height: 24, color: Colors.black12),
            _lbl('PACKAGES'),
            const SizedBox(height: 6),
            ...pkgNames.map((n) => Padding(padding: const EdgeInsets.only(bottom: 3),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.circle, size: 5, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(child: Text(n, style: const TextStyle(fontSize: 11,
                    color: AppColors.primary, fontWeight: FontWeight.w500))),
              ]))),
          ],
        ]),
      ),
    );
  }

  Widget _buildTimeline(int step) {
    const steps = ['Ordered', 'Paid', 'Redeem', 'Complete'];
    return Row(children: List.generate(7, (i) {
      if (i.isOdd) {
        return Expanded(child: Container(height: 2,
            color: (i ~/ 2) < step ? const Color(0xFF16A34A) : Colors.black12));
      }
      final idx = i ~/ 2;
      final done = idx <= step;
      return Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 28, height: 28,
            decoration: BoxDecoration(shape: BoxShape.circle,
                color: done ? const Color(0xFF16A34A) : Colors.white,
                border: Border.all(
                    color: done ? const Color(0xFF16A34A) : Colors.black26, width: 2)),
            child: done ? const Icon(Icons.check_rounded, color: Colors.white, size: 14) : null),
        const SizedBox(height: 4),
        Text(steps[idx], style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
            color: done ? const Color(0xFF16A34A) : AppColors.primary.withValues(alpha: 0.4))),
      ]);
    }));
  }

  Widget _merchantChip(Map<String, dynamic> m) {
    final name = m['name']?.toString() ?? '';
    final logo = m['logo_url']?.toString() ?? '';
    return Padding(padding: const EdgeInsets.only(bottom: 4),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        CircleAvatar(radius: 11,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            backgroundImage: logo.isNotEmpty ? NetworkImage(logo) : null,
            child: logo.isEmpty ? Text(name.isEmpty ? 'M' : name[0].toUpperCase(),
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold,
                    color: AppColors.primary)) : null),
        const SizedBox(width: 6),
        Flexible(child: Text(name, style: const TextStyle(fontSize: 12,
            fontWeight: FontWeight.w600, color: AppColors.primary),
            overflow: TextOverflow.ellipsis)),
      ]));
  }

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.check_circle_outline_rounded, size: 10, color: color),
      const SizedBox(width: 3),
      Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    ]),
  );

  Widget _sectionTitle(String t) => Text(t, style: const TextStyle(
      fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary));

  Widget _lbl(String t) => Text(t, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
      letterSpacing: 0.5, color: AppColors.primary.withValues(alpha: 0.45)));

  Widget _val(String t) => Padding(padding: const EdgeInsets.only(top: 2),
      child: Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
          color: AppColors.primary)));
}
