import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class SaleDetailScreen extends StatelessWidget {
  final Map<String, dynamic> sale;
  final bool isMerchant;

  const SaleDetailScreen({
    super.key,
    required this.sale,
    this.isMerchant = false,
  });

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

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid': case 'completed': return const Color(0xFF16A34A);
      case 'refunded': return const Color(0xFF6B7280);
      case 'cancelled': return const Color(0xFFDC2626);
      default: return const Color(0xFFF59E0B);
    }
  }

  String _cap(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  double _parseAmt(dynamic v) => double.tryParse(v?.toString() ?? '0') ?? 0.0;

  @override
  Widget build(BuildContext context) {
    final orderNum = sale['order_number']?.toString() ?? '#${sale['id']}';
    final dateTime = _fmt(sale['created_at']?.toString());
    final buyer = sale['customer_name']?.toString() ?? 'Customer';
    final buyerEmail = sale['customer_email']?.toString() ?? '';
    final pkgCount = (sale['package_count'] as num?)?.toInt() ??
        (sale['package_names'] as List?)?.length ?? 1;
    final total = _parseAmt(sale['total']);
    final sellerAmt = _parseAmt(sale['seller_amount'] ?? sale['total']);
    final currency = sale['currency']?.toString() ?? 'SGD';
    final pkgNames = (sale['package_names'] as List?)
        ?.map((p) => p.toString()).toList() ?? [];
    final payStatus = _payStatus(sale);
    final ordStatus = _ordStatus(sale);
    final payColor = _statusColor(payStatus);
    final ordColor = _statusColor(ordStatus);
    final holdStatus = sale['hold_status']?.toString() ?? '';
    final redeemedAt = _fmt(sale['redeemed_at']?.toString());
    final cancellationReason = sale['cancellation_reason']?.toString() ?? '';

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
        title: Text(
          'Sale Details #$orderNum',
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontFamily: 'Recoleta Alt',
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header summary card
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Order #$orderNum',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            fontFamily: 'Recoleta Alt',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Wrap(spacing: 6, children: [
                        _badge(payStatus, payColor),
                        if (ordStatus != payStatus) _badge(ordStatus, ordColor),
                      ]),
                    ],
                  ),
                  if (dateTime.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.primary.withValues(alpha: 0.45)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            dateTime,
                            style: TextStyle(fontSize: 12, color: AppColors.primary.withValues(alpha: 0.55)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const Divider(height: 24, color: Color(0xFFF1F5F9)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.person_outline_rounded, size: 16, color: AppColors.primary.withValues(alpha: 0.5)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                buyer,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'S\$${total.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF273DB7)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Details Grid Card
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Information',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 14),
                  _buildDetailRow('ORDER NUMBER', orderNum),
                  _buildDetailRow('BUYER NAME', buyer),
                  if (buyerEmail.isNotEmpty) _buildDetailRow('BUYER EMAIL', buyerEmail),
                  _buildDetailRow('PURCHASE DATE', dateTime.isNotEmpty ? dateTime : '—'),
                  if (redeemedAt.isNotEmpty) _buildDetailRow('REDEEMED AT', redeemedAt),
                  if (holdStatus.isNotEmpty) _buildDetailRow('HOLD STATUS', _cap(holdStatus)),
                  if (cancellationReason.isNotEmpty)
                    _buildDetailRow('CANCELLATION REASON', _cap(cancellationReason.replaceAll('_', ' '))),
                  const Divider(height: 24, color: Color(0xFFF1F5F9)),
                  const Text(
                    'Payment Breakdown',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 14),
                  _buildDetailRow('TOTAL AMOUNT', 'S\$${total.toStringAsFixed(2)}'),
                  if (!isMerchant && sellerAmt != total)
                    _buildDetailRow('YOUR EARNINGS', '$currency S\$${sellerAmt.toStringAsFixed(2)}'),
                  _buildDetailRow('PAYMENT STATUS', payStatus),
                  _buildDetailRow('ORDER STATUS', ordStatus),
                ],
              ),
            ),

            // Packages list card
            if (pkgNames.isNotEmpty) ...[
              const SizedBox(height: 16),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Packages ($pkgCount)',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    const SizedBox(height: 12),
                    ...pkgNames.map(
                      (n) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.06),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.inventory_2_outlined, size: 14, color: AppColors.primary),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                n,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
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
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
