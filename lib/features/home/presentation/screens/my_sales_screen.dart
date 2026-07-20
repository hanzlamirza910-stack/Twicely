import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/session_manager.dart';

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

  final List<String> _pills = ['All', 'Pending', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _fetchSales();
  }

  bool get _isMerchantMode => widget.isMerchant ?? SessionManager.isMerchant;

  Future<void> _fetchSales() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final isMerchant = _isMerchantMode;
    final res = isMerchant
        ? await ApiService.getMerchantOrders(perPage: 50)
        : await ApiService.getMySales(perPage: 50);
    if (!mounted) return;
    
    final isSuccess = res['success'] == true;
    final salesData = res['data'] ?? res['sales'];

    if (isSuccess && salesData != null && salesData is List) {
      setState(() {
        _sales = salesData
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_selectedPill == 'All') return _sales;
    final target = _selectedPill.toLowerCase();
    return _sales.where((s) {
      final status = (s['status'] ?? '').toString().toLowerCase();
      if (target == 'completed') {
        return status == 'completed' || status == 'processing' || status == 'paid' || status == 'confirmed';
      }
      if (target == 'pending') {
        return status == 'pending';
      }
      if (target == 'cancelled') {
        return status == 'cancelled' || status == 'failed' || status == 'refunded';
      }
      return status == target;
    }).toList();
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed': return const Color(0xFF22C55E);
      case 'processing': return const Color(0xFF3B82F6);
      case 'paid': return const Color(0xFF22C55E);
      case 'pending': return const Color(0xFFF59E0B);
      case 'cancelled': return const Color(0xFFEF4444);
      case 'confirmed': return const Color(0xFF3B82F6);
      default: return AppColors.primary.withValues(alpha: 0.5);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text('My Sales',
            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontFamily: 'Recoleta Alt', fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _fetchSales,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchSales,
        color: AppColors.primary,
        child: Column(
          children: [
            // Stats banner
            if (!_isLoading) _buildStatsBanner(),

            // Filter pills
            _buildFilterPills(),

            // List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)))
                  : _filtered.isEmpty
                      ? _buildEmpty()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                          itemCount: _filtered.length,
                          itemBuilder: (ctx, i) => _buildSaleCard(_filtered[i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBanner() {
    final isMerchant = _isMerchantMode;
    final total = _sales.length;
    final completed = _sales.where((s) {
      final status = (s['status'] ?? '').toString().toLowerCase();
      return status == 'completed' || status == 'processing' || status == 'paid' || status == 'confirmed';
    }).length;
    final pending = _sales.where((s) {
      final status = (s['status'] ?? '').toString().toLowerCase();
      return status == 'pending';
    }).length;
    final totalEarnings = _sales
        .where((s) {
          final status = (s['status'] ?? '').toString().toLowerCase();
          return status == 'completed' || status == 'processing' || status == 'paid' || status == 'confirmed';
        })
        .fold<double>(0, (sum, s) {
          final double val = double.tryParse(s['seller_amount']?.toString() ?? s['total']?.toString() ?? '0') ?? 0;
          return sum + (isMerchant ? val / 100.0 : val);
        });

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        children: [
          _buildStat('Total Sales', '$total', Icons.receipt_long_rounded),
          const SizedBox(width: 10),
          _buildStat('Completed', '$completed', Icons.check_circle_rounded),
          const SizedBox(width: 10),
          _buildStat('Pending', '$pending', Icons.schedule_rounded),
          const SizedBox(width: 10),
          _buildStat('Earnings', 'S\$${totalEarnings.toStringAsFixed(0)}', Icons.account_balance_wallet_rounded),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight, width: 1.0),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: AppColors.primary.withValues(alpha: 0.6), fontSize: 8), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPills() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _pills.map((p) {
            final isSelected = _selectedPill == p;
            return GestureDetector(
              onTap: () => setState(() => _selectedPill = p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.bgLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? AppColors.primary : Colors.black12),
                ),
                child: Text(p,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : AppColors.primary)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSaleCard(Map<String, dynamic> sale) {
    final isMerchant = _isMerchantMode;
    final status = (sale['status'] ?? 'pending').toString();
    final orderNum = sale['order_number']?.toString() ?? '#${sale['id']}';
    
    final double rawTotal = double.tryParse(sale['total']?.toString() ?? '0') ?? 0.0;
    final double rawSellerAmt = double.tryParse(sale['seller_amount']?.toString() ?? '0') ?? rawTotal;
    
    final total = isMerchant ? rawTotal / 100.0 : rawTotal;
    final sellerAmt = isMerchant ? rawSellerAmt / 100.0 : rawSellerAmt;
    
    final buyer = sale['customer_name']?.toString() ?? sale['buyer_name']?.toString() ?? 'Customer';
    final currency = sale['currency']?.toString() ?? 'SGD';
    final createdAt = sale['created_at']?.toString() ?? '';

    String dateStr = '';
    if (createdAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAt);
        dateStr = '${dt.day}/${dt.month}/${dt.year}';
      } catch (_) {
        dateStr = createdAt.split('T').first;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(orderNum,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(status.toUpperCase(),
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: _statusColor(status))),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.person_outline_rounded, size: 14, color: AppColors.primary.withValues(alpha: 0.5)),
                const SizedBox(width: 5),
                Expanded(child: Text(buyer, style: TextStyle(fontSize: 12, color: AppColors.primary.withValues(alpha: 0.7)))),
              ],
            ),
            if (dateStr.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.primary.withValues(alpha: 0.4)),
                  const SizedBox(width: 5),
                  Text(dateStr, style: TextStyle(fontSize: 11, color: AppColors.primary.withValues(alpha: 0.4))),
                ],
              ),
            ],
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Order Total', style: TextStyle(fontSize: 10, color: AppColors.primary.withValues(alpha: 0.5))),
                  Text('$currency ${total.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                ]),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('Your Earnings', style: TextStyle(fontSize: 10, color: AppColors.primary.withValues(alpha: 0.5))),
                  Text('$currency ${sellerAmt.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF22C55E))),
                ]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sell_rounded, size: 56, color: AppColors.primary.withValues(alpha: 0.15)),
          const SizedBox(height: 12),
          Text('No sales yet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary.withValues(alpha: 0.4))),
          const SizedBox(height: 4),
          Text('Your sales will appear here once orders come in',
              style: TextStyle(fontSize: 12, color: AppColors.primary.withValues(alpha: 0.3))),
        ],
      ),
    );
  }
}
