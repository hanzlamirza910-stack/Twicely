import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/session_manager.dart';
import '../../../../core/widgets/custom_snackbar.dart';

class PayoutScreen extends StatefulWidget {
  final bool? isMerchant;
  const PayoutScreen({super.key, this.isMerchant});

  @override
  State<PayoutScreen> createState() => _PayoutScreenState();
}

class _PayoutScreenState extends State<PayoutScreen> {
  // Method selection: 'paynow' | 'bank_transfer'
  String _selectedMethod = 'paynow';
  bool _isSaving = false;
  bool _isLoading = true;

  // PayNow fields
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _nricController = TextEditingController();

  // Bank Transfer fields
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _accountHolderController = TextEditingController();

  // History
  bool _isLoadingHistory = true;
  List<Map<String, dynamic>> _history = [];
  double _availableBalance = 0.0;
  String _currency = 'SGD';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _nricController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountHolderController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    await Future.wait([_loadSettings(), _loadHistory(), _loadWallet()]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadSettings() async {
    try {
      final res = await ApiService.getPayoutSettings();
      if (!mounted) return;
      if (res['success'] == true && res['data'] != null) {
        final data = res['data'] as Map;
        setState(() {
          final method = data['payout_method']?.toString() ?? 'paynow';
          _selectedMethod = (method == 'bank_transfer') ? 'bank_transfer' : 'paynow';
          _mobileController.text = data['paynow_mobile']?.toString() ?? '';
          _nricController.text = data['paynow_nric']?.toString() ?? '';
          _bankNameController.text = data['bank_name']?.toString() ?? '';
          _accountNumberController.text = data['account_number']?.toString() ?? '';
          _accountHolderController.text = data['account_holder']?.toString() ?? '';
        });
      }
    } catch (_) {}
  }

  bool get _isMerchantMode => widget.isMerchant ?? SessionManager.isMerchant;

  Future<void> _loadWallet() async {
    try {
      final isMerchant = _isMerchantMode;
      final res = isMerchant
          ? await ApiService.getMerchantWallet()
          : await ApiService.getWallet();
      if (!mounted) return;
      if (res['success'] == true && res['data'] != null) {
        final data = res['data'] as Map;
        final rawBal = double.tryParse(data['available_balance']?.toString() ?? '0') ?? 0.0;
        setState(() {
          _availableBalance = isMerchant ? rawBal / 100.0 : rawBal;
          _currency = data['currency']?.toString() ?? 'SGD';
        });
      }
    } catch (_) {}
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final res = await ApiService.getUserPayoutRequests(perPage: 50);
      if (!mounted) return;
      if (res['success'] == true && res['data'] != null) {
        setState(() {
          _history = (res['data'] as List<dynamic>)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingHistory = false);
  }

  Future<void> _saveChanges() async {
    // Basic validation
    if (_selectedMethod == 'paynow') {
      if (_mobileController.text.trim().isEmpty) {
        CustomSnackBar.show(context, message: 'Please enter your mobile number.', type: SnackBarType.warning);
        return;
      }
      if (_nricController.text.trim().isEmpty) {
        CustomSnackBar.show(context, message: 'Please enter your NRIC/FIN.', type: SnackBarType.warning);
        return;
      }
    } else {
      if (_bankNameController.text.trim().isEmpty) {
        CustomSnackBar.show(context, message: 'Please enter your bank name.', type: SnackBarType.warning);
        return;
      }
      if (_accountNumberController.text.trim().isEmpty) {
        CustomSnackBar.show(context, message: 'Please enter your account number.', type: SnackBarType.warning);
        return;
      }
      if (_accountHolderController.text.trim().isEmpty) {
        CustomSnackBar.show(context, message: 'Please enter your account holder name.', type: SnackBarType.warning);
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      final payload = {
        'payout_method': _selectedMethod,
        if (_selectedMethod == 'paynow') ...{
          'paynow_mobile': _mobileController.text.trim(),
          'paynow_nric': _nricController.text.trim(),
        },
        if (_selectedMethod == 'bank_transfer') ...{
          'bank_name': _bankNameController.text.trim(),
          'account_number': _accountNumberController.text.trim(),
          'account_holder': _accountHolderController.text.trim(),
        },
      };
      final res = await ApiService.updatePayoutSettings(payload);
      if (!mounted) return;
      CustomSnackBar.show(
        context,
        message: res['success'] == true ? 'Payout settings saved!' : (res['message'] ?? 'Failed to save settings.'),
        type: res['success'] == true ? SnackBarType.success : SnackBarType.error,
      );
    } catch (e) {
      if (!mounted) return;
      CustomSnackBar.show(context, message: 'Error saving settings.', type: SnackBarType.error);
    }
    if (mounted) setState(() => _isSaving = false);
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
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Payout Methods',
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
            onPressed: _loadAll,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)))
          : RefreshIndicator(
              onRefresh: _loadAll,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Verified Merchant Alert (From Website) ──────────────
                    if (_isMerchantMode) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F0), // light red/pink alert background
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFFA39E)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: Color(0xFFCF1322), size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Verified merchants do not have payout methods access.',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFFCF1322),
                                  fontFamily: 'Recoleta Alt',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Balance Card ───────────────────────────────────────
                    _buildBalanceCard(),
                    const SizedBox(height: 24),

                    // ── Payout Method Settings ─────────────────────────────
                    _buildSettingsCard(),
                    const SizedBox(height: 24),

                    // ── History Section ────────────────────────────────────
                    _buildHistorySection(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight, width: 1.0),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Available Balance',
                    style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                const SizedBox(height: 6),
                Text('$_currency ${_availableBalance.toStringAsFixed(2)}',
                    style: const TextStyle(color: AppColors.primary, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.bgLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payout Methods',
            style: TextStyle(
              fontFamily: 'Recoleta Alt',
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose your preferred payout method and configure the details',
            style: TextStyle(fontSize: 12, color: AppColors.primary.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 20),

          const Text(
            'Preferred Payout Method',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 0.2),
          ),
          const SizedBox(height: 12),

          // ── PayNow Option ──────────────────────────────────────────────
          _buildMethodOption(
            value: 'paynow',
            icon: Icons.phone_android_rounded,
            iconColor: const Color(0xFF22C55E),
            iconBg: const Color(0xFFE8F5E9),
            title: 'PayNow',
            subtitle: 'Instant transfers via PayNow using your mobile number or NRIC/FIN',
          ),
          const SizedBox(height: 10),

          // ── Bank Transfer Option ───────────────────────────────────────
          _buildMethodOption(
            value: 'bank_transfer',
            icon: Icons.account_balance_rounded,
            iconColor: const Color(0xFF6366F1),
            iconBg: const Color(0xFFEEF2FF),
            title: 'Direct Bank Transfer',
            subtitle: 'Manual bank transfer to your account (processed by admin)',
          ),
          const SizedBox(height: 20),

          // ── Dynamic Fields ─────────────────────────────────────────────
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: _selectedMethod == 'paynow'
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: _buildPayNowFields(),
            secondChild: _buildBankTransferFields(),
          ),

          const SizedBox(height: 24),

          // ── Save Button ────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveChanges,
              icon: _isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded, size: 18),
              label: Text(_isSaving ? 'Saving...' : 'Save Changes',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodOption({
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.04) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.black.withValues(alpha: 0.08),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            // Radio dot
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.black26,
                  width: isSelected ? 2 : 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: isSelected
                  ? Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // Icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? AppColors.primary : const Color(0xFF1A1A2E),
                      )),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(fontSize: 11, color: Colors.black.withValues(alpha: 0.45), height: 1.3)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayNowFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('PayNow Details'),
        const SizedBox(height: 14),
        _buildInputField(
          controller: _mobileController,
          label: 'Mobile Number',
          placeholder: 'e.g., +65 9123 4567',
          helper: 'Your Singapore mobile number linked to PayNow',
          icon: Icons.phone_rounded,
          keyboardType: TextInputType.phone,
          required: true,
        ),
        const SizedBox(height: 14),
        _buildInputField(
          controller: _nricController,
          label: 'NRIC/FIN',
          placeholder: 'e.g., S1234567A',
          helper: 'Your Singapore NRIC or FIN number',
          icon: Icons.badge_rounded,
          keyboardType: TextInputType.text,
          required: true,
        ),
      ],
    );
  }

  Widget _buildBankTransferFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Bank Account Details'),
        const SizedBox(height: 14),
        _buildInputField(
          controller: _bankNameController,
          label: 'Bank Name',
          placeholder: 'e.g., DBS, OCBC, UOB',
          helper: 'Your bank\'s full name',
          icon: Icons.account_balance_rounded,
          keyboardType: TextInputType.text,
          required: true,
        ),
        const SizedBox(height: 14),
        _buildInputField(
          controller: _accountNumberController,
          label: 'Account Number',
          placeholder: 'e.g., 123-456-789',
          helper: 'Your bank account number',
          icon: Icons.credit_card_rounded,
          keyboardType: TextInputType.number,
          required: true,
        ),
        const SizedBox(height: 14),
        _buildInputField(
          controller: _accountHolderController,
          label: 'Account Holder Name',
          placeholder: 'e.g., John Tan',
          helper: 'Full name as printed on your bank account',
          icon: Icons.person_rounded,
          keyboardType: TextInputType.name,
          required: true,
        ),
      ],
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
        fontFamily: 'Recoleta Alt',
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String placeholder,
    required String helper,
    required IconData icon,
    required TextInputType keyboardType,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
            children: required
                ? const [TextSpan(text: ' *', style: TextStyle(color: Color(0xFFEF4444)))]
                : [],
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14, color: AppColors.primary),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(color: AppColors.primary.withValues(alpha: 0.3), fontSize: 13),
            prefixIcon: Icon(icon, color: AppColors.primary.withValues(alpha: 0.5), size: 18),
            filled: true,
            fillColor: const Color(0xFFF8F9FC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(helper, style: TextStyle(fontSize: 11, color: AppColors.primary.withValues(alpha: 0.4))),
      ],
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Payout History',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary, fontFamily: 'Recoleta Alt'),
            ),
            if (!_isLoadingHistory)
              GestureDetector(
                onTap: _loadHistory,
                child: Text('Refresh', style: TextStyle(fontSize: 12, color: AppColors.primary.withValues(alpha: 0.5))),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (_isLoadingHistory)
          const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)))
        else if (_history.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            ),
            child: Column(
              children: [
                Icon(Icons.inbox_rounded, size: 40, color: AppColors.primary.withValues(alpha: 0.12)),
                const SizedBox(height: 10),
                Text('No payout requests yet',
                    style: TextStyle(fontSize: 13, color: AppColors.primary.withValues(alpha: 0.35), fontWeight: FontWeight.w500)),
              ],
            ),
          )
        else
          ...(_history.map((req) => _buildHistoryCard(req)).toList()),
      ],
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> req) {
    final status = (req['status'] ?? 'pending').toString();
    final amount = double.tryParse(req['amount']?.toString() ?? '0') ?? 0.0;
    final rawMethod = (req['payout_method'] ?? 'paynow').toString();
    final methodLabel = rawMethod == 'bank_transfer' ? 'Bank Transfer' : 'PayNow';
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
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _statusColor(status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.account_balance_wallet_rounded, color: _statusColor(status), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Payout via $methodLabel',
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
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.primary)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor(status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(status.toUpperCase(),
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: _statusColor(status))),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
