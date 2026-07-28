import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/session_manager.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import 'stripe_account_screen.dart';

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

  String _stripeStatus = 'not_started';

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    await Future.wait([_loadSettings(), _loadWallet(), _loadStripeStatus()]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadStripeStatus() async {
    if (!_isMerchantMode) return;
    try {
      final res = await ApiService.getStripeAccountStatus();
      if (!mounted) return;
      final st = (res['status'] ?? res['data']?['status'] ?? 'not_started').toString();
      setState(() {
        _stripeStatus = st;
      });
    } catch (_) {}
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
          _availableBalance = rawBal;
          _currency = data['currency']?.toString() ?? 'SGD';
        });
      }
    } catch (_) {}
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
                    const SizedBox(height: 20),
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

          // Preferred Payout Method Options
          if (_isMerchantMode) ...[
            // ── Stripe Option (Merchant Only) ───────────────────────────────────────
            _buildMethodOption(
              value: 'stripe',
              icon: Icons.credit_card_rounded,
              iconColor: const Color(0xFF635BFF),
              iconBg: const Color(0xFFF2F0FF),
              title: 'Stripe Account',
              subtitle: 'Automatic transfers to your connected Stripe account',
              badge: Row(
                children: [
                  Icon(
                    _stripeStatus == 'active'
                        ? Icons.check_circle_outline_rounded
                        : _stripeStatus == 'pending'
                            ? Icons.pending_actions_rounded
                            : Icons.info_outline_rounded,
                    size: 13,
                    color: _stripeStatus == 'active'
                        ? const Color(0xFF16A34A)
                        : _stripeStatus == 'pending'
                            ? const Color(0xFFD97706)
                            : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _stripeStatus == 'active'
                        ? 'Status: Active'
                        : _stripeStatus == 'pending'
                            ? 'Status: Pending'
                            : 'Status: Not Connected',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _stripeStatus == 'active'
                          ? const Color(0xFF16A34A)
                          : _stripeStatus == 'pending'
                              ? const Color(0xFFD97706)
                              : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

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
          if (_selectedMethod == 'paynow') _buildPayNowFields(),
          if (_selectedMethod == 'bank_transfer') _buildBankTransferFields(),
          if (_selectedMethod == 'stripe' && _isMerchantMode) _buildStripeFields(),

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
    Widget? badge,
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
                  if (badge != null) ...[
                    const SizedBox(height: 4),
                    badge,
                  ],
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

  Widget _buildStripeFields() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.credit_card_rounded, color: Color(0xFF635BFF), size: 20),
              SizedBox(width: 8),
              Text(
                'Stripe Connect Status',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Manage your Stripe connected account status, onboarding, charges, and payouts directly.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: Color(0xFF635BFF), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const StripeAccountScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.open_in_new_rounded, size: 16, color: Color(0xFF635BFF)),
              label: const Text(
                'Open Stripe Account Settings',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF635BFF)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
