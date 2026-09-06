import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/session_manager.dart';
import '../../../../core/widgets/app_search_bar.dart';
import '../../../../core/widgets/shimmer_effect.dart';


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


  List<Map<String, dynamic>> get _filtered {
    return _sales.where((s) {
      final q = _searchQuery.toLowerCase();
      if (q.isNotEmpty) {
        final num = (s['order_number'] ?? '').toString().toLowerCase();
        final buyer = (s['customer_name'] ?? s['buyer_name'] ?? '').toString().toLowerCase();
        final email = (s['customer_email'] ?? '').toString().toLowerCase();
        final pkgs = (s['package_names'] as List?)?.join(' ').toLowerCase() ?? '';
        if (!num.contains(q) && !buyer.contains(q) && !pkgs.contains(q) && !email.contains(q)) return false;
      }
      if (_selectedPill != 'All') {
        final cat = _getCategory(s);
        if (cat != _selectedPill) return false;
      }
      return true;
    }).toList();
  }

  /// Categorise a sale the same way the website does:
  /// Pending  → payment not yet paid / order pending
  /// On Hold  → order is on_hold / is_on_hold == true
  /// Redeemed → redeemed_at is set OR status == completed
  /// Cancelled → status == cancelled
  String _getCategory(Map<String, dynamic> s) {
    final st = (s['status'] ?? '').toString().toLowerCase();
    final ps = (s['payment_status'] ?? '').toString().toLowerCase();
    if (st == 'cancelled') return 'Cancelled';
    if (s['redeemed_at'] != null || st == 'completed') return 'Redeemed';
    if (st == 'on_hold' || s['is_on_hold'] == true) return 'On Hold';
    if (ps == 'paid' || st == 'processing') return 'Pending';
    return 'Pending'; // default
  }

  int _countFor(String pill) {
    if (pill == 'All') return _sales.length;
    return _sales.where((s) => _getCategory(s) == pill).length;
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
                ? ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 4,
                    itemBuilder: (context, index) => Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          ShimmerEffect(width: 140, height: 14, borderRadius: BorderRadius.all(Radius.circular(4))),
                          ShimmerEffect(width: 200, height: 10, borderRadius: BorderRadius.all(Radius.circular(4))),
                          Row(
                            children: [
                              ShimmerEffect(width: 60, height: 20, borderRadius: BorderRadius.all(Radius.circular(10))),
                              SizedBox(width: 8),
                              ShimmerEffect(width: 70, height: 20, borderRadius: BorderRadius.all(Radius.circular(10))),
                            ],
                          ),
                          SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ShimmerEffect(width: 100, height: 12, borderRadius: BorderRadius.all(Radius.circular(4))),
                              ShimmerEffect(width: 60, height: 16, borderRadius: BorderRadius.all(Radius.circular(4))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                : filtered.isEmpty
                    ? _buildEmpty()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _SaleCardWidget(
                          sale: filtered[i],
                          fmt: _fmt,
                          isMerchant: _isMerchantMode,
                        ),
                      ),
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
    const pills = ['All', 'Pending', 'On Hold', 'Redeemed', 'Cancelled'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: pills.map((p) {
            final sel = _selectedPill == p;
            final count = _countFor(p);
            return GestureDetector(
              onTap: () => setState(() => _selectedPill = p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: sel ? AppColors.primary : const Color(0xFFF4F5F7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: sel ? AppColors.primary : Colors.black.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      p,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: sel ? Colors.white : AppColors.primary.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: sel
                            ? Colors.white.withValues(alpha: 0.22)
                            : AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: sel ? Colors.white : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmpty() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.sell_rounded, size: 56, color: AppColors.primary.withValues(alpha: 0.15)),
    const SizedBox(height: 12),
    Text('No sales yet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
        color: AppColors.primary.withValues(alpha: 0.4))),
  ]));
}

// ── Expandable Sale Card Widget (Matching MyOrdersScreen design) ─────────────────

class _SaleCardWidget extends StatefulWidget {
  final Map<String, dynamic> sale;
  final String Function(String?) fmt;
  final bool isMerchant;

  const _SaleCardWidget({
    required this.sale,
    required this.fmt,
    required this.isMerchant,
  });

  @override
  State<_SaleCardWidget> createState() => _SaleCardWidgetState();
}

class _SaleCardWidgetState extends State<_SaleCardWidget> {
  bool _isExpanded = false;

  String _capStr(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sale = widget.sale;
    final orderNum = sale['order_number']?.toString() ?? '#${sale['id']}';
    final dateTime = widget.fmt(sale['created_at']?.toString());
    final buyer = sale['customer_name']?.toString() ?? sale['buyer_name']?.toString() ?? 'Buyer';
    final buyerEmail = sale['customer_email']?.toString() ?? '';
    final pkgCount = (sale['package_count'] as num?)?.toInt() ??
        (sale['package_names'] as List?)?.length ?? 1;

    final pkgList = (sale['package_names'] as List?)
        ?.map((p) => p.toString())
        .where((name) => name.isNotEmpty)
        .toList();
    final pkgNames = (pkgList != null && pkgList.isNotEmpty)
        ? pkgList.join(', ')
        : (sale['package_title']?.toString() ?? sale['title']?.toString() ?? 'Package');

    final total = double.tryParse(sale['total']?.toString() ?? sale['subtotal']?.toString() ?? '0') ?? 0.0;
    final sellerAmt = double.tryParse(sale['seller_amount']?.toString() ?? sale['total']?.toString() ?? '0') ?? total;

    final payStatus = (sale['payment_status'] ?? '').toString().toLowerCase();
    final ordStatus = (sale['status'] ?? '').toString().toLowerCase();



    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Header Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #$orderNum',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 11,
                            color: AppColors.primary.withValues(alpha: 0.4),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              [if (dateTime.isNotEmpty) dateTime, if (pkgNames.isNotEmpty) pkgNames].join(' · '),
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.primary.withValues(alpha: 0.5),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.04),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Status Badges Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatusPill(
                    label: payStatus == 'paid' ? '✓ Paid' : (payStatus == 'refunded' ? '↺ Refunded' : '✓ Paid'),
                    bgColor: payStatus == 'refunded' ? const Color(0xFFF3F4F6) : const Color(0xFFDCFCE7),
                    textColor: payStatus == 'refunded' ? const Color(0xFF4B5563) : const Color(0xFF15803D),
                  ),
                  const SizedBox(width: 6),
                  if (ordStatus == 'completed')
                    _buildStatusPill(
                      label: '✓ Completed',
                      bgColor: const Color(0xFFDCFCE7),
                      textColor: const Color(0xFF15803D),
                    )
                  else if (ordStatus == 'cancelled')
                    _buildStatusPill(
                      label: '✕ Cancelled',
                      bgColor: const Color(0xFFFEE2E2),
                      textColor: const Color(0xFFDC2626),
                    )
                  else
                    _buildStatusPill(
                      label: '⏱ On Hold',
                      bgColor: const Color(0xFFFEF3C7),
                      textColor: const Color(0xFFB45309),
                    ),
                ],
              ),
            ),

            if (!_isExpanded) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: Colors.black12),
              ),
              // Collapsed Summary Row
              Row(
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    size: 14,
                    color: AppColors.primary.withValues(alpha: 0.45),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Buyer: $buyer',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary.withValues(alpha: 0.7),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 13,
                    color: AppColors.primary.withValues(alpha: 0.45),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$pkgCount pkg',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '\$ ${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF273DB7),
                    ),
                  ),
                ],
              ),
            ],

            // Expanded Content
            if (_isExpanded) ...[
              const SizedBox(height: 16),

              // Card 1: Order Details
              _buildSectionCard(
                title: 'Order Details',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('ORDER NUMBER', orderNum),
                    const SizedBox(height: 10),
                    _buildDetailRow('BUYER', buyer),
                    if (buyerEmail.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _buildDetailRow('EMAIL', buyerEmail),
                    ],
                    const SizedBox(height: 10),
                    _buildDetailRow('PURCHASE', dateTime.isNotEmpty ? dateTime : '—'),
                    if ((sale['redeemed_at'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _buildDetailRow('REDEEMED AT', widget.fmt(sale['redeemed_at']?.toString())),
                    ],
                    if ((sale['cancellation_reason'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _buildDetailRow(
                        'CANCELLATION REASON',
                        _capStr(sale['cancellation_reason'].toString().replaceAll('_', ' ')),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Card 2: Payment Details
              _buildSectionCard(
                title: 'Payment Details',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TOTAL AMOUNT',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: AppColors.primary.withValues(alpha: 0.45),
                          ),
                        ),
                        Text(
                          'S\$${total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    if (!widget.isMerchant && sellerAmt > 0 && sellerAmt != total) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'YOUR EARNINGS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: AppColors.primary.withValues(alpha: 0.45),
                            ),
                          ),
                          Text(
                            'S\$${sellerAmt.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    _buildDetailRow('PAYMENT STATUS', payStatus.isEmpty ? 'Paid' : _capStr(payStatus)),
                    const SizedBox(height: 10),
                    _buildDetailRow('ORDER STATUS', ordStatus.isEmpty ? 'Pending' : _capStr(ordStatus.replaceAll('_', ' '))),
                  ],
                ),
              ),
            ],

          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill({
    required String label,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: AppColors.primary.withValues(alpha: 0.45),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}
