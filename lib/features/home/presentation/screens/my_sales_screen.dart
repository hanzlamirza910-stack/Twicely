import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';

class MySalesScreen extends StatefulWidget {
  const MySalesScreen({super.key});

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

  Future<void> _fetchSales() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final res = await ApiService.getMySales(perPage: 50);
    if (!mounted) return;
    if (res['success'] == true && res['data'] != null) {
      setState(() {
        _sales = (res['data'] as List<dynamic>)
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
    return _sales.where((s) {
      final status = (s['status'] ?? '').toString().toLowerCase();
      return status == _selectedPill.toLowerCase();
    }).toList();
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed': return const Color(0xFF22C55E);
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
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('My Sales',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Recoleta Alt')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
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
    final total = _sales.length;
    final completed = _sales.where((s) => (s['status'] ?? '').toString().toLowerCase() == 'completed').length;
    final pending = _sales.where((s) => (s['status'] ?? '').toString().toLowerCase() == 'pending').length;
    final totalEarnings = _sales
        .where((s) => (s['status'] ?? '').toString().toLowerCase() == 'completed')
        .fold<double>(0, (sum, s) => sum + (double.tryParse(s['seller_amount']?.toString() ?? s['total']?.toString() ?? '0') ?? 0));

    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        children: [
          _buildStat('Total Sales', '$total', Icons.receipt_long_rounded),
          const SizedBox(width: 12),
          _buildStat('Completed', '$completed', Icons.check_circle_rounded),
          const SizedBox(width: 12),
          _buildStat('Pending', '$pending', Icons.schedule_rounded),
          const SizedBox(width: 12),
          _buildStat('Earnings', 'S\$${totalEarnings.toStringAsFixed(0)}', Icons.account_balance_wallet_rounded),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 8), textAlign: TextAlign.center),
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
    final status = (sale['status'] ?? 'pending').toString();
    final orderNum = sale['order_number']?.toString() ?? '#${sale['id']}';
    final total = double.tryParse(sale['total']?.toString() ?? '0') ?? 0.0;
    final sellerAmt = double.tryParse(sale['seller_amount']?.toString() ?? '0') ?? total;
    final buyer = sale['customer_name']?.toString() ?? 'Customer';
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
