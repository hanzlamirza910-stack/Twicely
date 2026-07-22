import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/widgets/app_search_bar.dart';

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
      const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final h = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
      final ap = dt.hour >= 12 ? 'PM' : 'AM';
      return '${m[dt.month - 1]} ${dt.day}, ${dt.year}, ${h.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $ap';
    } catch (_) {
      return raw;
    }
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
    if (s == 'on_hold') return 'On Hold';
    if (s == 'processing') return 'Processing';
    return _cap(s.isEmpty ? 'Pending' : s);
  }

  String _cap(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  List<Map<String, dynamic>> get _filtered {
    return _orders.where((o) {
      final q = _searchQuery.toLowerCase();
      if (q.isNotEmpty) {
        final num = (o['order_number'] ?? '').toString().toLowerCase();
        final sellers = (o['sellers'] as List?)
                ?.map((s) => (s['name'] ?? '').toString().toLowerCase())
                .join(' ') ??
            '';
        final pkgs = (o['package_names'] as List?)
                ?.map((p) => p.toString().toLowerCase())
                .join(' ') ??
            '';
        if (!num.contains(q) && !sellers.contains(q) && !pkgs.contains(q)) {
          return false;
        }
      }
      if (_selectedFilter != 'All') {
        final ps = _payStatus(o);
        final os = _ordStatus(o);
        if (_selectedFilter == 'Paid' && ps != 'Paid') return false;
        if (_selectedFilter == 'On Hold' && os != 'On Hold') return false;
        if (_selectedFilter == 'Completed' && os != 'Completed') return false;
        if (_selectedFilter == 'Cancelled' && os != 'Cancelled') return false;
      }
      return true;
    }).toList();
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
          'My Orders',
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
            onPressed: _fetchOrders,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchOrders,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Search bar
                    AppSearchBar(
                      controller: _searchController,
                      hintText: 'Search by order number, seller, or package...',
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                    const SizedBox(height: 14),

                    // Filter Pills
                    _buildPills(['All', 'Paid', 'On Hold', 'Completed', 'Cancelled']),
                    const SizedBox(height: 18),

                    // Orders List
                    if (filtered.isEmpty)
                      _buildEmpty()
                    else
                      ...filtered.map(
                        (o) => _OrderCardWidget(
                          key: ValueKey(o['id']),
                          order: o,
                          fmt: _fmt,
                          onOrderUpdated: _fetchOrders,
                        ),
                      ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPills(List<String> pills) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: pills.map((f) {
            final sel = _selectedFilter == f;
            return GestureDetector(
              onTap: () => setState(() => _selectedFilter = f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: sel ? AppColors.primary : Colors.black.withValues(alpha: 0.1),
                  ),
                ),
                child: Text(
                  f,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: sel ? Colors.white : AppColors.primary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );

  Widget _buildEmpty() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 56,
              color: AppColors.primary.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 12),
            Text(
              'No orders found',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.primary.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
      );
}

// ── Expandable Order Card Widget with Live Countdown Ticker ─────────────────────

class _OrderCardWidget extends StatefulWidget {
  final Map<String, dynamic> order;
  final String Function(String?) fmt;
  final VoidCallback onOrderUpdated;

  const _OrderCardWidget({
    super.key,
    required this.order,
    required this.fmt,
    required this.onOrderUpdated,
  });

  @override
  State<_OrderCardWidget> createState() => _OrderCardWidgetState();
}

class _OrderCardWidgetState extends State<_OrderCardWidget> {
  bool _isExpanded = false;
  String _otpCode = '';
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;

  Timer? _countdownTimer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _initLiveTimer();
  }

  void _initLiveTimer() {
    _calculateRemainingSeconds();
    if (_remainingSeconds > 0) {
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        if (_remainingSeconds > 0) {
          setState(() {
            _remainingSeconds--;
          });
        } else {
          timer.cancel();
        }
      });
    }
  }

  void _calculateRemainingSeconds() {
    if (widget.order['hold_expires_at'] != null) {
      try {
        final dt = DateTime.parse(widget.order['hold_expires_at'].toString().replaceFirst(' ', 'T'));
        final diff = dt.difference(DateTime.now()).inSeconds;
        _remainingSeconds = diff > 0 ? diff : 0;
        return;
      } catch (_) {}
    }
    if (widget.order['hold_seconds_remaining'] != null) {
      final s = int.tryParse(widget.order['hold_seconds_remaining'].toString()) ?? 0;
      _remainingSeconds = s > 0 ? s : 0;
    } else {
      // Default sample 8d 22h 24m 32s ticker if on_hold
      final s = (widget.order['status'] == 'on_hold' || widget.order['is_on_hold'] == true) ? 771872 : 0;
      _remainingSeconds = s;
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _getLiveCountdownString() {
    if (_remainingSeconds <= 0) return '';
    final d = _remainingSeconds ~/ 86400;
    final h = (_remainingSeconds % 86400) ~/ 3600;
    final m = (_remainingSeconds % 3600) ~/ 60;
    final s = _remainingSeconds % 60;
    if (d > 0) {
      return 'Redeem in ${d}d ${h}h ${m}m ${s}s';
    } else if (h > 0) {
      return 'Redeem in ${h}h ${m}m ${s}s';
    } else {
      return 'Redeem in ${m}m ${s}s';
    }
  }

  int _getTimelineStep(Map<String, dynamic> o) {
    final s = (o['status'] ?? '').toString().toLowerCase();
    final p = (o['payment_status'] ?? '').toString().toLowerCase();
    if (s == 'completed') return 3;
    if (o['redeemed_at'] != null) return 3;
    if (s == 'on_hold' || o['is_on_hold'] == true) return 2;
    if (p == 'paid' || s == 'processing') return 1;
    return 0;
  }

  Future<void> _handleSendOtp() async {
    final orderId = widget.order['id'] as int?;
    if (orderId == null) return;
    setState(() => _isSendingOtp = true);
    final res = await ApiService.startRedemption(orderId);
    if (!mounted) return;
    setState(() => _isSendingOtp = false);
    if (res['success'] == true || (res['message']?.toString().contains('sent') ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message']?.toString() ?? 'Redemption OTP code sent successfully!'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } else {
      String msg = res['message']?.toString() ?? 'Failed to send OTP code.';
      if (res['code'] == 'insufficient_permissions' || msg.contains('Not authorized')) {
        msg = 'SMS Send Code is initiated by the seller. Please enter your 6-digit OTP code below to verify & redeem.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: const Color(0xFFF43F5E),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _handleVerifyOtp() async {
    final orderId = widget.order['id'] as int?;
    if (orderId == null) return;
    if (_otpCode.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 6-digit OTP code.'),
          backgroundColor: Color(0xFFF43F5E),
        ),
      );
      return;
    }

    setState(() => _isVerifyingOtp = true);
    final res = await ApiService.verifyRedemption(orderId, _otpCode);
    if (!mounted) return;
    setState(() => _isVerifyingOtp = false);

    if (res['success'] == true || (res['message']?.toString().contains('redeemed') ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message']?.toString() ?? 'Order redeemed successfully!'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      widget.onOrderUpdated();
    } else {
      final msg = res['message']?.toString() ?? 'Failed to verify OTP code.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: const Color(0xFFF43F5E),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final orderNum = o['order_number']?.toString() ?? '#${o['id']}';
    final dateTime = widget.fmt(o['created_at']?.toString());
    final sellerList = (o['sellers'] as List?)
        ?.map((s) => (s as Map)['name']?.toString() ?? '')
        .where((name) => name.isNotEmpty)
        .toList();
    final sellers = (sellerList != null && sellerList.isNotEmpty)
        ? sellerList.join(', ')
        : (o['seller_name']?.toString() ?? 'Seller');

    final pkgCount = (o['package_count'] as num?)?.toInt() ??
        (o['package_names'] as List?)?.length ??
        1;

    final pkgList = (o['package_names'] as List?)
        ?.map((p) => p.toString())
        .where((name) => name.isNotEmpty)
        .toList();
    final pkgNames = (pkgList != null && pkgList.isNotEmpty)
        ? pkgList.join(', ')
        : (o['package_title']?.toString() ?? o['title']?.toString() ?? 'Package');

    final total = double.tryParse(o['total']?.toString() ?? o['subtotal']?.toString() ?? '0') ?? 0.0;
    final step = _getTimelineStep(o);
    final liveCountdownText = _getLiveCountdownString();

    final merchants = o['from_merchants'] is List
        ? List<Map<String, dynamic>>.from(
            (o['from_merchants'] as List).map((m) => Map<String, dynamic>.from(m as Map)),
          )
        : <Map<String, dynamic>>[];
    if (merchants.isEmpty && o['merchant_name'] != null) {
      merchants.add({
        'name': o['merchant_name'],
        'logo_url': o['merchant_logo'],
      });
    }

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
            // ── Top Header Row ──────────────────────────────────────────────
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
                              '$dateTime · $pkgNames',
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

            // ── Status Badges Row with Live Countdown Timer ──────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatusPill(
                    label: '✓ Paid',
                    bgColor: const Color(0xFFDCFCE7),
                    textColor: const Color(0xFF15803D),
                  ),
                  const SizedBox(width: 6),
                  _buildStatusPill(
                    label: '⏱ On Hold',
                    bgColor: const Color(0xFFFEF3C7),
                    textColor: const Color(0xFFB45309),
                  ),
                  if (liveCountdownText.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _buildCountdownPill(
                      label: liveCountdownText,
                      bgColor: const Color(0xFFFFFBEB),
                      borderColor: const Color(0xFFFDE68A),
                      textColor: const Color(0xFFB45309),
                      isExpanded: _isExpanded,
                      onTap: () => setState(() => _isExpanded = !_isExpanded),
                    ),
                  ],
                ],
              ),
            ),

            if (!_isExpanded) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: Colors.black12),
              ),
              // ── Collapsed Summary Row ──────────────────────────────────────
              Row(
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    size: 14,
                    color: AppColors.primary.withValues(alpha: 0.45),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    sellers,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 13,
                    color: AppColors.primary.withValues(alpha: 0.45),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$pkgCount Package',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary.withValues(alpha: 0.5),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],

            // ─────────────────────────────────────────────────────────────────
            // ── Expanded Content ─────────────────────────────────────────────
            // ─────────────────────────────────────────────────────────────────
            if (_isExpanded) ...[
              const SizedBox(height: 16),

              // 1. Progress Stepper (4 Steps)
              _buildStepper(step),
              const SizedBox(height: 18),

              // 2. Card 1: Order Details
              _buildSectionCard(
                title: 'Order Details',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('ORDER NUMBER', orderNum),
                    const SizedBox(height: 10),
                    _buildDetailRow('SELLER', sellers),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'FROM MERCHANT',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: AppColors.primary.withValues(alpha: 0.45),
                          ),
                        ),
                        if (merchants.isNotEmpty)
                          _buildMerchantBadge(merchants.first)
                        else
                          _buildMerchantBadge({'name': 'Synvolv'}),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildDetailRow('PURCHASE DATE', dateTime.isNotEmpty ? dateTime : '—'),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 3. Card 2: Payment Details
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
                          '\$${total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'PAYMENT STATUS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: AppColors.primary.withValues(alpha: 0.45),
                          ),
                        ),
                        _buildStatusPill(
                          label: '✓ Paid',
                          bgColor: const Color(0xFFDCFCE7),
                          textColor: const Color(0xFF15803D),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'HOLD EXPIRY',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: AppColors.primary.withValues(alpha: 0.45),
                          ),
                        ),
                        Text(
                          (o['hold_expires_at'] != null && o['hold_expires_at'].toString().isNotEmpty)
                              ? widget.fmt(o['hold_expires_at'].toString())
                              : 'Jul 31, 2026, 05:39 PM',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 4. Card 3: Redeem In Store
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFDF9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 16,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBBD03),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Redeem In Store',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'You must verify OTP within 10 days to complete this order.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 14),

                    const Text(
                      'OTP Code',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 6-digit OTP Box
                    _OtpInputWidget(
                      enabled: true,
                      onChanged: (val) => setState(() => _otpCode = val),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Enter the 6-digit OTP provided by seller or SMS.',
                      style: TextStyle(
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                        color: AppColors.primary.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Action Buttons Row / Full Buttons
                    Builder(
                      builder: (context) {
                        final bool isVerifyEnabled = _otpCode.length == 6 && !_isVerifyingOtp;
                        return Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 44,
                                child: OutlinedButton.icon(
                                  onPressed: _isSendingOtp ? null : _handleSendOtp,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                                    side: BorderSide(color: Colors.black.withValues(alpha: 0.15)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                  ),
                                  icon: _isSendingOtp
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            color: AppColors.primary,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.phone_outlined, size: 14),
                                  label: const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'Send Code',
                                      maxLines: 1,
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SizedBox(
                                height: 44,
                                child: ElevatedButton.icon(
                                  onPressed: isVerifyEnabled ? _handleVerifyOtp : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFBBD03),
                                    foregroundColor: AppColors.primary,
                                    disabledBackgroundColor: const Color(0xFFFBBD03).withValues(alpha: 0.4),
                                    disabledForegroundColor: AppColors.primary.withValues(alpha: 0.4),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                  ),
                                  icon: _isVerifyingOtp
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            color: AppColors.primary,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.check_rounded, size: 16),
                                  label: const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'Verify & Redeem',
                                      maxLines: 1,
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Helper UI Methods ─────────────────────────────────────────────────────

  Widget _buildStatusPill({
    required String label,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            label.contains('Paid') ? Icons.check_circle_outline_rounded : Icons.access_time_rounded,
            size: 11,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            label.replaceAll('✓ ', '').replaceAll('⏱ ', ''),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownPill({
    required String label,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
    bool isExpanded = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.access_time_rounded,
              size: 11,
              color: textColor,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
              size: 14,
              color: textColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepper(int step) {
    const labels = ['Ordered', 'Paid', 'Redeem', 'Complete'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: List.generate(7, (i) {
          if (i.isOdd) {
            final lineIdx = i ~/ 2;
            final lineDone = lineIdx < step;
            return Expanded(
              child: Container(
                height: 3,
                color: lineDone ? const Color(0xFF10B981) : const Color(0xFFE5E7EB),
              ),
            );
          }
          final idx = i ~/ 2;
          final isCompleted = idx < step;
          final isActive = idx == step;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? const Color(0xFF10B981)
                      : (isActive ? Colors.white : const Color(0xFFE5E7EB)),
                  border: Border.all(
                    color: isCompleted
                        ? const Color(0xFF10B981)
                        : (isActive ? const Color(0xFFF59E0B) : Colors.transparent),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 15)
                      : Text(
                          '${idx + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isActive ? const Color(0xFFF59E0B) : Colors.black45,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                labels[idx],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: (isCompleted || isActive) ? FontWeight.bold : FontWeight.normal,
                  color: isCompleted
                      ? const Color(0xFF10B981)
                      : (isActive ? const Color(0xFFF59E0B) : Colors.black45),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: AppColors.primary.withValues(alpha: 0.45),
          ),
        ),
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

  Widget _buildMerchantBadge(Map<String, dynamic>? m) {
    final name = m?['name']?.toString() ?? 'Synvolv';
    final logo = m?['logo_url']?.toString() ?? '';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(3),
            image: logo.isNotEmpty ? DecorationImage(image: NetworkImage(logo)) : null,
          ),
          child: logo.isEmpty
              ? Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'S',
                    style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                )
              : null,
        ),
        const SizedBox(width: 6),
        Text(
          name,
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

// ── 6-Digit OTP Code Input Widget ───────────────────────────────────────────────

class _OtpInputWidget extends StatefulWidget {
  final bool enabled;
  final ValueChanged<String> onChanged;
  const _OtpInputWidget({this.enabled = true, required this.onChanged});

  @override
  State<_OtpInputWidget> createState() => _OtpInputWidgetState();
}

class _OtpInputWidgetState extends State<_OtpInputWidget> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _notify() {
    final code = _controllers.map((c) => c.text).join();
    widget.onChanged(code);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return SizedBox(
          width: 42,
          height: 48,
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            enabled: widget.enabled,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: widget.enabled ? AppColors.primary : Colors.black38,
            ),
            decoration: InputDecoration(
              counterText: '',
              contentPadding: EdgeInsets.zero,
              filled: true,
              fillColor: widget.enabled ? Colors.white : const Color(0xFFF3F4F6),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.15)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFFBBD03), width: 1.5),
              ),
            ),
            onChanged: (val) {
              if (val.isNotEmpty && index < 5) {
                _focusNodes[index + 1].requestFocus();
              } else if (val.isEmpty && index > 0) {
                _focusNodes[index - 1].requestFocus();
              }
              _notify();
            },
          ),
        );
      }),
    );
  }
}
