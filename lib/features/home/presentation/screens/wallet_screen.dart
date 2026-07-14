import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/session_manager.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _wallet = {};
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    await Future.wait([_fetchWallet(), _fetchTransactions()]);
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _fetchWallet() async {
    // Try merchant wallet first if applicable
    final isMerchant = SessionManager.isMerchant;
    final res = isMerchant
        ? await ApiService.getMerchantWallet()
        : await ApiService.getWallet();
    if (!mounted) return;
    if (res['success'] == true && res['data'] != null) {
      _wallet = Map<String, dynamic>.from(res['data'] as Map);
    }
  }

  Future<void> _fetchTransactions() async {
    final isMerchant = SessionManager.isMerchant;
    final res = isMerchant
        ? await ApiService.getMerchantTransactions(perPage: 30)
        : await ApiService.getUserTransactions(perPage: 30);
    if (!mounted) return;
    if (res['success'] == true && res['data'] != null) {
      _transactions = (res['data'] as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
  }

  Color _txnColor(String type) {
    switch (type.toLowerCase()) {
      case 'credit': case 'release': return const Color(0xFF22C55E);
      case 'debit': case 'hold': return const Color(0xFFEF4444);
      default: return AppColors.primary;
    }
  }

  IconData _txnIcon(String type) {
    switch (type.toLowerCase()) {
      case 'credit': return Icons.arrow_downward_rounded;
      case 'debit': return Icons.arrow_upward_rounded;
      case 'hold': return Icons.lock_outline_rounded;
      case 'release': return Icons.lock_open_rounded;
      default: return Icons.swap_horiz_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance = double.tryParse(_wallet['balance']?.toString() ?? '0') ?? 0.0;
    final available = double.tryParse(_wallet['available_balance']?.toString() ?? '0') ?? 0.0;
    final clearing = double.tryParse(_wallet['clearing_balance']?.toString() ?? '0') ?? 0.0;
    final currency = _wallet['currency']?.toString() ?? 'SGD';
    final payoutEnabled = _wallet['payout_enabled'] == true;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Wallet',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Recoleta Alt')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _fetchAll,
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
              onRefresh: _fetchAll,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildBalanceCard(balance, available, clearing, currency, payoutEnabled),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Transactions',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary, fontFamily: 'Recoleta Alt')),
                        Text('${_transactions.length} entries',
                            style: TextStyle(fontSize: 11, color: AppColors.primary.withValues(alpha: 0.45))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _transactions.isEmpty
                        ? _buildEmptyTxns()
                        : Column(
                            children: _transactions.map((t) => _buildTxnCard(t)).toList(),
                          ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBalanceCard(double balance, double available, double clearing, String currency, bool payoutEnabled) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1F2E4E), Color(0xFF2D4270)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1F2E4E).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total Balance', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
          const SizedBox(height: 6),
          Text('$currency ${balance.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, fontFamily: 'Recoleta Alt')),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildBalanceChip('Available', '$currency ${available.toStringAsFixed(2)}', const Color(0xFF22C55E))),
              const SizedBox(width: 12),
              Expanded(child: _buildBalanceChip('Clearing', '$currency ${clearing.toStringAsFixed(2)}', const Color(0xFFF59E0B))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                payoutEnabled ? Icons.check_circle_rounded : Icons.pause_circle_rounded,
                size: 14,
                color: payoutEnabled ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
              ),
              const SizedBox(width: 6),
              Text(
                payoutEnabled ? 'Payouts enabled' : 'Payouts not yet enabled',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10)),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTxnCard(Map<String, dynamic> txn) {
    final type = (txn['type'] ?? 'credit').toString();
    final amount = double.tryParse(txn['amount']?.toString() ?? '0') ?? 0.0;
    final desc = txn['description']?.toString() ?? type;
    final createdAt = txn['created_at']?.toString() ?? '';
    String dateStr = '';
    if (createdAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAt);
        dateStr = '${dt.day}/${dt.month}/${dt.year}';
      } catch (_) {
        dateStr = createdAt.split('T').first;
      }
    }

    final color = _txnColor(type);
    final isCredit = type == 'credit' || type == 'release';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(_txnIcon(type), color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(desc, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                if (dateStr.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(dateStr, style: TextStyle(fontSize: 10, color: AppColors.primary.withValues(alpha: 0.4))),
                ],
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '-'}S\$${amount.abs().toStringAsFixed(2)}',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTxns() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_rounded, size: 48, color: AppColors.primary.withValues(alpha: 0.15)),
            const SizedBox(height: 12),
            Text('No transactions yet',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary.withValues(alpha: 0.35))),
          ],
        ),
      ),
    );
  }
}
