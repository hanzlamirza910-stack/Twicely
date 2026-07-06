import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  double _availableBalance = 0.00;
  double _withdrawnToDate = 0.00;
  final double _clearingBalance = 0.00;
  final int _clearingPaymentsCount = 0;

  final List<Map<String, dynamic>> _transactions = [
    {
      'title': 'Sales Credit: Luxury Watch Box',
      'subtitle': 'May 21, 2026 • Order #99212',
      'amount': 45.00,
      'isCredit': true,
      'icon': Icons.shopping_bag_outlined,
      'iconBg': Color(0xFFE0F2FE),
      'iconColor': Color(0xFF0284C7),
    },
    {
      'title': 'Bank Withdrawal',
      'subtitle': 'May 18, 2026 • DBS ****1234',
      'amount': -150.00,
      'isCredit': false,
      'icon': Icons.account_balance_rounded,
      'iconBg': Color(0xFFFCE7F3),
      'iconColor': Color(0xFFDB2777),
    },
  ];

  void _simulateSale() {
    setState(() {
      _availableBalance += 100.00;
      _transactions.insert(0, {
        'title': 'Sales Credit: Yoga Class Resale',
        'subtitle': 'Today • Order #99503',
        'amount': 100.00,
        'isCredit': true,
        'icon': Icons.shopping_bag_outlined,
        'iconBg': const Color(0xFFE0F2FE),
        'iconColor': const Color(0xFF0284C7),
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Simulated Sale! +SGD 100.00 added to your balance.'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _handleWithdraw() {
    if (_availableBalance < 10.00) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: AppColors.danger),
              SizedBox(width: 8),
              Text(
                'Withdrawal Failed',
                style: TextStyle(
                  fontFamily: 'Recoleta Alt',
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          content: Text(
            'Minimum withdrawal amount is SGD 10.00.\n\nYour current available balance is SGD ${_availableBalance.toStringAsFixed(2)}.\n\nTip: Tap the "Simulate Sale" button at the bottom of the screen to add test funds!',
            style: const TextStyle(color: AppColors.primary, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else {
      final withdrawAmount = _availableBalance;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                title: const Text(
                  'Confirm Withdrawal',
                  style: TextStyle(
                    fontFamily: 'Recoleta Alt',
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                content: Text(
                  'Are you sure you want to withdraw SGD ${withdrawAmount.toStringAsFixed(2)} to your connected bank account (DBS ****1234)?',
                  style: const TextStyle(color: AppColors.primary, fontSize: 14),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel', style: TextStyle(color: Colors.black45)),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _executeWithdrawal(withdrawAmount);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('Withdraw', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              );
            },
          );
        },
      );
    }
  }

  void _executeWithdrawal(double amount) {
    // Show spinner overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
      ),
    );

    Future.delayed(const Duration(seconds: 1, milliseconds: 500), () {
      if (!mounted) return;
      Navigator.of(context).pop(); // dismiss spinner

      setState(() {
        _availableBalance = 0.00;
        _withdrawnToDate += amount;
        _transactions.insert(0, {
          'title': 'Bank Withdrawal',
          'subtitle': 'Today • DBS ****1234',
          'amount': -amount,
          'isCredit': false,
          'icon': Icons.account_balance_rounded,
          'iconBg': const Color(0xFFFCE7F3),
          'iconColor': const Color(0xFFDB2777),
        });
      });

      // Show success dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFD1FAE5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 48),
              ),
              const SizedBox(height: 20),
              const Text(
                'Withdrawal Requested',
                style: TextStyle(
                  fontFamily: 'Recoleta Alt',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your withdrawal request of SGD ${amount.toStringAsFixed(2)} has been submitted. Funds will arrive in your account within 1-3 business days.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.primary.withValues(alpha: 0.7), fontSize: 13),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                ),
                child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _showHelpFaq() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      backgroundColor: AppColors.bgLight,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Wallet Help & FAQ',
              style: TextStyle(
                fontFamily: 'Recoleta Alt',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'How do withdrawals work?',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14),
            ),
            const SizedBox(height: 4),
            const Text(
              'Once you sell a package, the buyer\'s payment clears in 7 days to protect against disputes. Cleared funds can be withdrawn to your bank instantly.',
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 16),
            const Text(
              'Are there transfer fees?',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14),
            ),
            const SizedBox(height: 4),
            const Text(
              'Twicely charges 0% withdrawal fees. The amount you see is the exact amount that will clear to your bank.',
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Image.asset(
          'assets/images/logo.webp',
          height: 34,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Text(
            'twicely',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: AppColors.primary, size: 26),
            onPressed: () {},
          ),
          Container(
            margin: const EdgeInsets.only(right: 16, left: 4),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.1),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 18),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Header Row with Help Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'John Smith',
                        style: TextStyle(
                          fontFamily: 'Recoleta Alt',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Saturday, May 23, 2026',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _showHelpFaq,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.help_outline_rounded, size: 14, color: AppColors.primary),
                        SizedBox(width: 4),
                        Text(
                          'Help & FAQ',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Available Balance Card (Blue Card)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Available Balance',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'SGD ${_availableBalance.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Balance available for use',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Divider(color: Colors.white10, height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'WITHDRAWN TO DATE:',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'SGD ${_withdrawnToDate.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '*Minimum withdrawal amount is SGD 10.00',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Payments Being Cleared Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.05)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(
                        'Payments Being Cleared',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: AppColors.primary.withValues(alpha: 0.4),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Anticipated funds from recent sales',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.primary.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'SGD ${_clearingBalance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$_clearingPaymentsCount payments',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary.withValues(alpha: 0.4),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Withdrawal history is empty.')),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide.none,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.05),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text(
                            'Withdraw History',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _handleWithdraw,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _availableBalance >= 10.00
                                ? const Color(0xFFD9F99D) // Light lime green active
                                : const Color(0xFFE2E8F0), // Grey disabled
                            foregroundColor: _availableBalance >= 10.00
                                ? const Color(0xFF3F6212) // Dark green text
                                : Colors.black38,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text(
                            'Withdraw Now',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Recent Transactions Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontFamily: 'Recoleta Alt',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Transactions search and sorting coming soon!')),
                    );
                  },
                  child: const Text(
                    'See All',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Transactions list
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _transactions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final tx = _transactions[index];
                final isCredit = tx['isCredit'] as bool;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.04)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: tx['iconBg'] as Color,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          tx['icon'] as IconData,
                          color: tx['iconColor'] as Color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx['title'] as String,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tx['subtitle'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.primary.withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${isCredit ? '+' : ''}SGD ${(tx['amount'] as double).abs().toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: isCredit ? const Color(0xFF10B981) : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Empty state footer
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.04),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.receipt_long_outlined,
                    color: AppColors.primary.withValues(alpha: 0.3),
                    size: 20,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No more transactions found',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Keep selling to build your balance!',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // DEMO SIMULATION BUTTON (Outlined)
            OutlinedButton.icon(
              onPressed: _simulateSale,
              icon: const Icon(Icons.bolt, size: 16, color: AppColors.accent),
              label: const Text(
                'Simulate Sale (+SGD 100.00)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.accent, width: 1.5),
                backgroundColor: AppColors.accent.withValues(alpha: 0.05),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
