import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/widgets/custom_snackbar.dart';

class StripeAccountScreen extends StatefulWidget {
  const StripeAccountScreen({super.key});

  @override
  State<StripeAccountScreen> createState() => _StripeAccountScreenState();
}

class _StripeAccountScreenState extends State<StripeAccountScreen> {
  bool _isLoading = true;
  bool _isActionInProgress = false;
  Map<String, dynamic> _stripeAccount = {};
  Map<String, dynamic> _walletData = {};

  @override
  void initState() {
    super.initState();
    _fetchStripeDetails();
  }

  Future<void> _fetchStripeDetails() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final resList = await Future.wait([
        ApiService.getStripeAccountStatus(),
        ApiService.getPaymentsWallet(),
      ]);

      if (!mounted) return;

      final stripeRes = resList[0];
      final walletRes = resList[1];

      Map<String, dynamic> stripeData = {};
      if (stripeRes['success'] == true && stripeRes['data'] != null) {
        if (stripeRes['data'] is Map) {
          stripeData = Map<String, dynamic>.from(stripeRes['data'] as Map);
        }
      } else if (stripeRes['status'] != null) {
        stripeData = Map<String, dynamic>.from(stripeRes);
      }

      Map<String, dynamic> walletData = {};
      if (walletRes['success'] == true && walletRes['data'] != null) {
        if (walletRes['data'] is Map) {
          walletData = Map<String, dynamic>.from(walletRes['data'] as Map);
        }
      }

      setState(() {
        _stripeAccount = stripeData;
        _walletData = walletData;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleOnboardOrReconnect() async {
    setState(() => _isActionInProgress = true);
    try {
      final status = (_stripeAccount['status'] ?? '').toString().toLowerCase();
      Map<String, dynamic> res;
      if (status == 'not_started' || status.isEmpty) {
        res = await ApiService.onboardStripe('merchant');
      } else {
        res = await ApiService.reconnectStripe();
      }

      if (!mounted) return;
      setState(() => _isActionInProgress = false);

      String? url;
      if (res['success'] == true && res['data'] != null) {
        url = res['data']['url']?.toString() ?? res['data']?.toString();
      } else if (res['url'] != null) {
        url = res['url'].toString();
      }

      if (url != null && url.isNotEmpty) {
        final uri = Uri.parse(url);
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched) {
          if (mounted) {
            CustomSnackBar.show(context, message: 'Could not open Stripe URL.', type: SnackBarType.error);
          }
        }
      } else {
        CustomSnackBar.show(
          context,
          message: res['message'] ?? 'Failed to get Stripe onboarding URL.',
          type: SnackBarType.error,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isActionInProgress = false);
        CustomSnackBar.show(context, message: 'Error: $e', type: SnackBarType.error);
      }
    }
  }

  Future<void> _handleDisconnect() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Disconnect Stripe Account', style: TextStyle(fontFamily: 'Recoleta Alt', fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to remove your connected Stripe account from your Twicely wallet?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Disconnect', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isActionInProgress = true);
    try {
      final res = await ApiService.disconnectStripe();
      if (!mounted) return;
      setState(() => _isActionInProgress = false);

      if (res['success'] == true || res['disconnected'] == true) {
        CustomSnackBar.show(context, message: 'Stripe account disconnected.', type: SnackBarType.success);
        _fetchStripeDetails();
      } else {
        CustomSnackBar.show(context, message: res['message'] ?? 'Failed to disconnect Stripe.', type: SnackBarType.error);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isActionInProgress = false);
        CustomSnackBar.show(context, message: 'Error disconnecting: $e', type: SnackBarType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = (_stripeAccount['status'] ?? 'not_started').toString().toLowerCase();
    final chargesEnabled = _stripeAccount['charges_enabled'] == true;
    final payoutsEnabled = _stripeAccount['payouts_enabled'] == true;
    
    final accountId = _stripeAccount['id']?.toString() ??
        _stripeAccount['stripe_account_id']?.toString() ??
        _walletData['stripe_account_id']?.toString() ??
        '';

    final isActive = status == 'active';
    final isPending = status == 'pending';

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
          'Stripe Account',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Recoleta Alt',
            color: AppColors.primary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _fetchStripeDetails,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Subtitle Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Stripe Account',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Recoleta Alt',
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Manage your payment settings and payouts',
                            style: TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      if (isActive)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFDCFCE7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_circle_rounded, color: Color(0xFF166534), size: 20),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Status Alert Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFFF0FDF4)
                          : isPending
                              ? const Color(0xFFFFFBEB)
                              : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isActive
                            ? const Color(0xFFBBF7D0)
                            : isPending
                                ? const Color(0xFFFDE68A)
                                : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isActive
                              ? Icons.check_circle_outline_rounded
                              : isPending
                                  ? Icons.pending_actions_rounded
                                  : Icons.info_outline_rounded,
                          color: isActive
                              ? const Color(0xFF16A34A)
                              : isPending
                                  ? const Color(0xFFD97706)
                                  : Colors.black45,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isActive
                                ? 'Your Stripe account is active. You can receive payments.'
                                : isPending
                                    ? 'Your Stripe account setup is pending. Please complete onboarding.'
                                    : 'No Stripe account connected. Connect your Stripe account to receive card payments.',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? const Color(0xFF15803D)
                                  : isPending
                                      ? const Color(0xFFB45309)
                                      : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Account Details Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Charges Enabled', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black45, letterSpacing: 0.5)),
                                  const SizedBox(height: 4),
                                  Text(
                                    chargesEnabled ? 'Yes' : 'No',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: chargesEnabled ? const Color(0xFF166534) : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Payouts Enabled', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black45, letterSpacing: 0.5)),
                                  const SizedBox(height: 4),
                                  Text(
                                    payoutsEnabled ? 'Yes' : 'No',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: payoutsEnabled ? const Color(0xFF166534) : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Divider(height: 1, color: Colors.black.withValues(alpha: 0.06)),
                        const SizedBox(height: 20),

                        const Text('Account ID', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black45, letterSpacing: 0.5)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                accountId.isNotEmpty ? accountId : 'Not connected',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            if (accountId.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.black45),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: accountId));
                                  CustomSnackBar.show(context, message: 'Account ID copied to clipboard.', type: SnackBarType.info);
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Action Buttons Row
                  _isActionInProgress
                      ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)))
                      : Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFBBD03),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                ),
                                onPressed: _handleOnboardOrReconnect,
                                icon: Icon(
                                  isActive
                                      ? Icons.settings_suggest_rounded
                                      : isPending
                                          ? Icons.pending_actions_rounded
                                          : Icons.add_link_rounded,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                                label: Text(
                                  isActive
                                      ? 'Update Account'
                                      : isPending
                                          ? 'Complete Onboarding'
                                          : 'Connect Stripe Account',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            if (accountId.isNotEmpty)
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        side: const BorderSide(color: Colors.redAccent, width: 1),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                      ),
                                      onPressed: _handleDisconnect,
                                      icon: const Icon(Icons.link_off_rounded, size: 16, color: Colors.red),
                                      label: const Text('Disconnect', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    onPressed: _fetchStripeDetails,
                                    icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
                                    style: IconButton.styleFrom(
                                      backgroundColor: const Color(0xFFF3F4F6),
                                      padding: const EdgeInsets.all(12),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                  const SizedBox(height: 20),

                  // Bottom External Link
                  Center(
                    child: TextButton.icon(
                      onPressed: _handleOnboardOrReconnect,
                      icon: const Icon(Icons.open_in_new_rounded, size: 14, color: Color(0xFF2563EB)),
                      label: const Text(
                        'Manage your Stripe account →',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2563EB),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
