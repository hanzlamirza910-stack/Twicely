import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class PayoutScreen extends StatefulWidget {
  const PayoutScreen({super.key});

  @override
  State<PayoutScreen> createState() => _PayoutScreenState();
}

class _PayoutScreenState extends State<PayoutScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedMethod = 'paynow'; // 'paynow' or 'bank'

  // PayNow text controllers
  final TextEditingController _mobileController = TextEditingController(text: '+65 9123 4567');
  final TextEditingController _nricController = TextEditingController(text: 'S1234567A');

  // Bank Transfer text controllers
  final TextEditingController _bankNameController = TextEditingController(text: 'DBS Bank');
  final TextEditingController _accountHolderController = TextEditingController(text: 'John Smith');
  final TextEditingController _accountNumberController = TextEditingController(text: '123-45678-9');

  @override
  void dispose() {
    _mobileController.dispose();
    _nricController.dispose();
    _bankNameController.dispose();
    _accountHolderController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildCustomBottomNavBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
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
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No new notifications')),
            );
          },
        ),
        GestureDetector(
          onTap: () {
            Navigator.of(context).pop(4); // pop to profile
          },
          child: Container(
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
        ),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title & Subtitle
            const Text(
              'Payout Methods',
              style: TextStyle(
                fontFamily: 'Recoleta Alt',
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Choose your preferred payout method and configure the details.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 28),

            // PREFERRED PAYOUT METHOD label
            Text(
              'PREFERRED PAYOUT METHOD',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 14),

            // Option 1: PayNow
            _buildPayoutOptionCard(
              id: 'paynow',
              title: 'PayNow',
              subtitle: 'Instant transfers via mobile or NRIC/FIN',
              icon: Icons.money_rounded,
              iconBgColor: const Color(0xFFE8F5E9),
              iconColor: const Color(0xFF2E7D32),
            ),
            const SizedBox(height: 12),

            // Option 2: Bank Transfer
            _buildPayoutOptionCard(
              id: 'bank',
              title: 'Bank Transfer',
              subtitle: 'Manual transfer (3-5 business days)',
              icon: Icons.account_balance_rounded,
              iconBgColor: const Color(0xFFFFFDE7),
              iconColor: const Color(0xFFF57F17),
            ),
            const SizedBox(height: 24),

            // Dynamic Form Section based on selected payout method
            _selectedMethod == 'paynow' ? _buildPayNowForm() : _buildBankTransferForm(),

            const SizedBox(height: 32),

            // Save Changes CTA Button
            ElevatedButton.icon(
              onPressed: _saveChanges,
              icon: const Icon(Icons.save_rounded, color: Colors.white, size: 18),
              label: const Text(
                'Save Changes',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F2E4E), // Navy blue CTA
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 0,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPayoutOptionCard({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    final isSelected = _selectedMethod == id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = id;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? const Color(0xFF1F2E4E) : AppColors.primary.withValues(alpha: 0.08),
            width: isSelected ? 1.8 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? const Color(0xFF1F2E4E).withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.01),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left Rounded Icon Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // Text Titles
            Expanded(
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
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.primary.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Radio Indicator on the right
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF1F2E4E) : AppColors.primary.withValues(alpha: 0.2),
                  width: isSelected ? 6 : 1.5,
                ),
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayNowForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info Button link
        InkWell(
          onTap: () {
            _showPayNowInfo();
          },
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF2563EB)),
                SizedBox(width: 6),
                Text(
                  'PayNow Details',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Mobile Number Field
        _buildLabel('Mobile Number *'),
        _buildTextField(
          controller: _mobileController,
          hintText: 'e.g., +65 9123 4567',
          helperText: 'Your Singapore mobile number linked to PayNow',
          keyboardType: TextInputType.phone,
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Mobile number is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 18),

        // NRIC/FIN Field
        _buildLabel('NRIC/FIN *'),
        _buildTextField(
          controller: _nricController,
          hintText: 'e.g., S1234567A',
          helperText: 'Your Singapore NRIC or FIN number',
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.characters,
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'NRIC/FIN is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildBankTransferForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info Header
        Row(
          children: const [
            Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary),
            SizedBox(width: 6),
            Text(
              'Bank Account Transfer Details',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Bank Name Field
        _buildLabel('Bank Name *'),
        _buildTextField(
          controller: _bankNameController,
          hintText: 'e.g., DBS Bank, UOB, OCBC',
          helperText: 'Enter the name of your financial institution',
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Bank name is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 18),

        // Account Holder Name Field
        _buildLabel('Account Holder Name *'),
        _buildTextField(
          controller: _accountHolderController,
          hintText: 'e.g., John Smith',
          helperText: 'Make sure this matches your bank records exactly',
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Account holder name is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 18),

        // Account Number Field
        _buildLabel('Account Number *'),
        _buildTextField(
          controller: _accountNumberController,
          hintText: 'e.g., 123-45678-9',
          helperText: 'Specify your savings or current account number',
          keyboardType: TextInputType.number,
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Account number is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 2.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required String helperText,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            validator: validator,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: AppColors.primary.withValues(alpha: 0.35),
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 6.0),
          child: Text(
            helperText,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.primary.withValues(alpha: 0.4),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  void _showPayNowInfo() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: AppColors.bgLight,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'About PayNow Payouts',
              style: TextStyle(
                fontFamily: 'Recoleta Alt',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'PayNow is a real-time instant payment service in Singapore. By linking your mobile number or NRIC/FIN, funds cleared from your successful package sales will be transferred instantly directly to your connected bank account.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColors.primary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Got it', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      // Simulate save spinner
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
        ),
      );

      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        Navigator.of(context).pop(); // pop spinner

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedMethod == 'paynow'
                  ? 'PayNow payout settings saved successfully!'
                  : 'Bank transfer details saved successfully!',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      });
    }
  }

  Widget _buildCustomBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EA),
        border: Border(
          top: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.08),
            width: 1.2,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavBarItem(0, Icons.home_rounded, 'Home'),
            _buildNavBarItem(1, Icons.search_rounded, 'Search'),
            // Sell Button
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop(2); // return to home with index 2
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1F2E4E),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.add, color: Colors.white, size: 24),
                  ),
                ],
              ),
            ),
            _buildNavBarItem(3, Icons.chat_bubble_outline_rounded, 'Chat'),
            _buildNavBarItem(4, Icons.person_rounded, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavBarItem(int index, IconData icon, String label) {
    final isSelected = index == 4; // Highlight Profile
    final activeColor = const Color(0xFF1F2E4E);
    final inactiveColor = const Color(0xFF1F2E4E).withValues(alpha: 0.4);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop(index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? activeColor : inactiveColor,
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? activeColor : inactiveColor,
            ),
          ),
        ],
      ),
    );
  }
}
