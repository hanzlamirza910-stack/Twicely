import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';

class PayoutScreen extends StatefulWidget {
  const PayoutScreen({super.key});

  @override
  State<PayoutScreen> createState() => _PayoutScreenState();
}

class _PayoutScreenState extends State<PayoutScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Payout requests
  bool _isLoadingRequests = true;
  List<Map<String, dynamic>> _requests = [];

  // Wallet
  bool _isLoadingWallet = true;
  double _availableBalance = 0.0;
  String _currency = 'SGD';

  // Settings form
  String _selectedSchedule = 'weekly';
  String _selectedMethod = 'stripe';
  bool _isSavingSettings = false;
  bool _isRequestingPayout = false;
  final TextEditingController _amountController = TextEditingController();

  final List<String> _schedules = ['weekly', 'monthly'];
  final List<String> _methods = ['stripe'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _fetchAll() async {
    await Future.wait([_fetchWallet(), _fetchRequests()]);
  }

  Future<void> _fetchWallet() async {
    setState(() => _isLoadingWallet = true);
    final res = await ApiService.getWallet();
    if (!mounted) return;
    if (res['success'] == true && res['data'] != null) {
      final data = res['data'] as Map;
      setState(() {
        _availableBalance = double.tryParse(data['available_balance']?.toString() ?? '0') ?? 0.0;
        _currency = data['currency']?.toString() ?? 'SGD';
        _selectedSchedule = data['payout_schedule']?.toString() ?? 'weekly';
        _isLoadingWallet = false;
      });
    } else {
      setState(() => _isLoadingWallet = false);
    }
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoadingRequests = true);
    final res = await ApiService.getUserPayoutRequests(perPage: 50);
    if (!mounted) return;
    if (res['success'] == true && res['data'] != null) {
      setState(() {
        _requests = (res['data'] as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _isLoadingRequests = false;
      });
    } else {
      setState(() => _isLoadingRequests = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSavingSettings = true);
    final res = await ApiService.updatePayoutSettings(_selectedMethod, _selectedSchedule);
    if (!mounted) return;
    setState(() => _isSavingSettings = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(res['success'] == true ? 'Payout settings saved!' : res['message'] ?? 'Failed to save'),
      backgroundColor: res['success'] == true ? const Color(0xFF22C55E) : Colors.red,
    ));
  }

  Future<void> _requestPayout() async {
    final amtText = _amountController.text.trim();
    final amount = double.tryParse(amtText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid amount')));
      return;
    }
    if (amount > _availableBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Amount exceeds available balance')));
      return;
    }
    setState(() => _isRequestingPayout = true);
    final res = await ApiService.createUserPayoutRequest(amount, method: _selectedMethod);
    if (!mounted) return;
    setState(() => _isRequestingPayout = false);
    if (res['success'] == true) {
      _amountController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payout request submitted!'), backgroundColor: Color(0xFF22C55E)));
      _fetchRequests();
      _fetchWallet();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Failed to request payout'), backgroundColor: Colors.red));
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved': case 'paid': return const Color(0xFF22C55E);
      case 'pending': return const Color(0xFFF59E0B);
      case 'rejected': return const Color(0xFFEF4444);
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
        title: const Text('Payout Methods',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Recoleta Alt')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _fetchAll,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: const [
            Tab(text: 'Request Payout'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRequestTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildRequestTab() {
    return RefreshIndicator(
      onRefresh: _fetchAll,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Balance card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1F2E4E), Color(0xFF2D4270)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: _isLoadingWallet
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Available Balance',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                        const SizedBox(height: 4),
                        Text('$_currency ${_availableBalance.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                      ],
                    ),
            ),

            const SizedBox(height: 24),

            // Request form
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Request Withdrawal',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary, fontFamily: 'Recoleta Alt')),
                  const SizedBox(height: 16),

                  // Amount field
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 14, color: AppColors.primary),
                    decoration: InputDecoration(
                      labelText: 'Amount ($_currency)',
                      labelStyle: TextStyle(color: AppColors.primary.withValues(alpha: 0.6), fontSize: 13),
                      prefixIcon: const Icon(Icons.attach_money_rounded, color: AppColors.primary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                      suffixText: 'Max: ${_availableBalance.toStringAsFixed(2)}',
                      suffixStyle: TextStyle(color: AppColors.primary.withValues(alpha: 0.45), fontSize: 11),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Payout method
                  const Text('Payout Method', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  const SizedBox(height: 8),
                  RadioGroup<String>(
                    groupValue: _selectedMethod,
                    onChanged: (v) => setState(() => _selectedMethod = v ?? ''),
                    child: Column(
                      children: _methods.map((m) => RadioListTile<String>(
                            value: m,
                            title: Text(m.toUpperCase(),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                            activeColor: AppColors.primary,
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          )).toList(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Payout schedule
                  const Text('Payout Schedule', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  const SizedBox(height: 8),
                  RadioGroup<String>(
                    groupValue: _selectedSchedule,
                    onChanged: (v) => setState(() => _selectedSchedule = v ?? ''),
                    child: Column(
                      children: _schedules.map((s) => RadioListTile<String>(
                            value: s,
                            title: Text(s[0].toUpperCase() + s.substring(1),
                                style: const TextStyle(fontSize: 13, color: AppColors.primary)),
                            activeColor: AppColors.primary,
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          )).toList(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Save settings button
                  OutlinedButton.icon(
                    onPressed: _isSavingSettings ? null : _saveSettings,
                    icon: _isSavingSettings
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save_rounded, size: 16),
                    label: const Text('Save Settings'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      minimumSize: const Size(double.infinity, 44),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Submit withdrawal
                  ElevatedButton.icon(
                    onPressed: _isRequestingPayout ? null : _requestPayout,
                    icon: _isRequestingPayout
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded, size: 16),
                    label: const Text('Request Payout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_isLoadingRequests) {
      return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)));
    }
    if (_requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded, size: 52, color: AppColors.primary.withValues(alpha: 0.15)),
            const SizedBox(height: 12),
            Text('No payout requests yet',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary.withValues(alpha: 0.35))),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchRequests,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _requests.length,
        itemBuilder: (_, i) => _buildRequestCard(_requests[i]),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> req) {
    final status = (req['status'] ?? 'pending').toString();
    final amount = double.tryParse(req['amount']?.toString() ?? '0') ?? 0.0;
    final method = (req['payout_method'] ?? 'stripe').toString().toUpperCase();
    final createdAt = req['created_at']?.toString() ?? '';
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _statusColor(status).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.account_balance_wallet_rounded, color: _statusColor(status), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Payout via $method',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
                if (dateStr.isNotEmpty)
                  Text(dateStr, style: TextStyle(fontSize: 11, color: AppColors.primary.withValues(alpha: 0.4))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('S\$${amount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor(status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(status.toUpperCase(),
                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: _statusColor(status))),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
