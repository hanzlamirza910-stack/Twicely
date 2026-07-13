import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/cart_manager.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/widgets/custom_snackbar.dart';

class CheckoutScreen extends StatefulWidget {
  final double totalAmount;
  const CheckoutScreen({super.key, required this.totalAmount});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _postcodeController = TextEditingController();
  final TextEditingController _cardController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvcController = TextEditingController();

  String _selectedCountry = 'Singapore';
  String _selectedPhoneCode = '+65';
  bool _isProcessing = false;

  final List<Map<String, String>> _countryCodesList = [
    {'code': '+65', 'name': 'Singapore', 'flag': '🇸🇬'},
    {'code': '+60', 'name': 'Malaysia', 'flag': '🇲🇾'},
    {'code': '+62', 'name': 'Indonesia', 'flag': '🇮🇩'},
    {'code': '+66', 'name': 'Thailand', 'flag': '🇹🇭'},
    {'code': '+91', 'name': 'India', 'flag': '🇮🇳'},
    {'code': '+61', 'name': 'Australia', 'flag': '🇦🇺'},
    {'code': '+44', 'name': 'United Kingdom', 'flag': '🇬🇧'},
    {'code': '+1', 'name': 'United States', 'flag': '🇺🇸'},
    {'code': '+92', 'name': 'Pakistan', 'flag': '🇵🇰'},
    {'code': '+852', 'name': 'Hong Kong', 'flag': '🇭🇰'},
    {'code': '+63', 'name': 'Philippines', 'flag': '🇵🇭'},
    {'code': '+84', 'name': 'Vietnam', 'flag': '🇻🇳'},
  ];

  final List<String> _countriesList = [
    'Singapore',
    'Malaysia',
    'Indonesia',
    'Thailand',
    'Australia',
    'India',
    'Hong Kong',
    'Philippines',
    'Vietnam',
    'United Kingdom',
    'United States',
    'Pakistan',
  ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postcodeController.dispose();
    _cardController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    super.dispose();
  }

  void _autofillCard() {
    setState(() {
      _cardController.text = '4111 2222 3333 4444';
      _expiryController.text = '12 / 28';
      _cvcController.text = '123';
      _firstNameController.text = 'Alex';
      _lastNameController.text = 'Tan';
      _emailController.text = 'alex.tan@gmail.com';
      _phoneController.text = '9123 4567';
      _addressController.text = '12 Marina Boulevard';
      _cityController.text = 'Singapore';
      _stateController.text = 'SG';
      _postcodeController.text = '018982';
    });
    CustomSnackBar.show(
      context,
      message: 'Form autofilled for demo testing!',
      type: SnackBarType.success,
    );
  }

  void _handlePayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    final orderData = {
      'billing': {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': '$_selectedPhoneCode ${_phoneController.text.trim()}',
        'address_1': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'postcode': _postcodeController.text.trim(),
        'country': _selectedCountry,
      },
      'payment_method': 'stripe',
    };

    final orderRes = await ApiService.placeOrder(orderData);

    if (!orderRes['success']) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        CustomSnackBar.show(
          context,
          message: orderRes['message'] ?? 'Failed to place order.',
          type: SnackBarType.error,
        );
      }
      return;
    }

    final rawOrderId = orderRes['order_id'] ?? orderRes['id'] ?? orderRes['data']?['order_id'] ?? orderRes['data']?['id'];
    if (rawOrderId == null) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        CustomSnackBar.show(
          context,
          message: 'Order placed but failed to retrieve order ID.',
          type: SnackBarType.error,
        );
      }
      return;
    }

    final int orderId = int.tryParse(rawOrderId.toString()) ?? 0;

    // Create payment intent
    final intentRes = await ApiService.createStripePaymentIntent(orderId);
    if (!intentRes['success']) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        CustomSnackBar.show(
          context,
          message: intentRes['message'] ?? 'Failed to create payment intent.',
          type: SnackBarType.error,
        );
      }
      return;
    }

    final clientSecret = intentRes['client_secret'] ?? intentRes['data']?['client_secret'];
    debugPrint('Stripe client secret retrieved: $clientSecret');

    // Simulate Stripe payment processing delay
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    setState(() {
      _isProcessing = false;
    });

    // Clear Cart on successful payment
    CartManager().clear();

    // Show success modal dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF4CAF50),
                    size: 48,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Payment Successful!',
                  style: TextStyle(
                    fontFamily: 'Recoleta Alt',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Order #$orderId has been processed successfully. A confirmation email has been sent.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primary.withValues(alpha: 0.6),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () {
                    // Navigate back to the very first route (Home)
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Return to Home',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
        title: const Text(
          'Checkout',
          style: TextStyle(
            fontFamily: 'Recoleta Alt',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                // Step Indicator Row
                _buildStepIndicator(),
                const SizedBox(height: 16),

                // Form sections
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      children: [
                        // General Information Section
                        _buildSectionCard(
                          title: 'General Information',
                          subtitle: 'Enter your contact details for the booking.',
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInputField(
                                    label: 'First Name',
                                    hint: 'First Name',
                                    controller: _firstNameController,
                                    validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildInputField(
                                    label: 'Last Name',
                                    hint: 'Last Name',
                                    controller: _lastNameController,
                                    validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildInputField(
                              label: 'Email',
                              hint: 'Enter Email',
                              controller: _emailController,
                              isRequired: true,
                              keyboardType: TextInputType.emailAddress,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Email is required';
                                if (!val.contains('@')) return 'Invalid email';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            // Mobile Phone field with flag/arrow dropdown
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'Mobile Number',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '*',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.danger),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Country Dropdown Circle/Oval representation
                                    Container(
                                      height: 48,
                                      padding: const EdgeInsets.only(left: 14, right: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _selectedPhoneCode,
                                          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.primary),
                                          style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.bold),
                                          onChanged: (String? val) {
                                            if (val != null) {
                                              setState(() => _selectedPhoneCode = val);
                                            }
                                          },
                                          items: _countryCodesList.map((map) {
                                            return DropdownMenuItem<String>(
                                              value: map['code'],
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(map['flag']!, style: const TextStyle(fontSize: 14)),
                                                  const SizedBox(width: 4),
                                                  Text(map['code']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    // Actual Input
                                    Expanded(
                                      child: TextFormField(
                                        controller: _phoneController,
                                        keyboardType: TextInputType.phone,
                                        validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                                        style: const TextStyle(fontSize: 13, color: AppColors.primary),
                                        decoration: InputDecoration(
                                          hintText: 'XXXXXX XXXX',
                                          hintStyle: TextStyle(color: AppColors.primary.withValues(alpha: 0.35)),
                                          fillColor: Colors.white,
                                          filled: true,
                                          isDense: true,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(24),
                                            borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.15)),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(24),
                                            borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.15)),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(24),
                                            borderSide: const BorderSide(color: AppColors.primary),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Billing Address Section
                        _buildSectionCard(
                          title: 'Billing Address',
                          children: [
                            _buildInputField(
                              label: 'Street Address',
                              hint: 'Enter Street Address',
                              controller: _addressController,
                              validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                // Country Selector
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Country',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        height: 48,
                                        padding: const EdgeInsets.symmetric(horizontal: 14),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(24),
                                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: _selectedCountry,
                                            isExpanded: true,
                                            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.primary),
                                            style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.normal),
                                            onChanged: (String? val) {
                                              if (val != null) {
                                                setState(() => _selectedCountry = val);
                                              }
                                            },
                                            items: _countriesList
                                                .map<DropdownMenuItem<String>>((String value) {
                                              return DropdownMenuItem<String>(
                                                value: value,
                                                child: Text(value),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildInputField(
                                    label: 'Town/City',
                                    hint: 'Enter Town/City',
                                    controller: _cityController,
                                    validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInputField(
                                    label: 'State',
                                    hint: 'Enter State',
                                    controller: _stateController,
                                    validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildInputField(
                                    label: 'Postcode',
                                    hint: 'Enter Postcode',
                                    controller: _postcodeController,
                                    validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Payment Information Section
                        _buildSectionCard(
                          title: 'Payment Information',
                          subtitle: 'Transactions are secure and encrypted.',
                          children: [
                            // Card number with Autofill badge
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          'Card Number',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '*',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.danger),
                                        ),
                                      ],
                                    ),
                                    GestureDetector(
                                      onTap: _autofillCard,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'AUTOFILL',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _cardController,
                                  keyboardType: TextInputType.number,
                                  validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                                  style: const TextStyle(fontSize: 13, color: AppColors.primary),
                                  decoration: InputDecoration(
                                    hintText: '1234 1234 1234 1234',
                                    hintStyle: TextStyle(color: AppColors.primary.withValues(alpha: 0.35)),
                                    fillColor: Colors.white,
                                    filled: true,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.15)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.15)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      borderSide: const BorderSide(color: AppColors.primary),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInputField(
                                    label: 'Expiry Date',
                                    hint: 'MM / YY',
                                    controller: _expiryController,
                                    isRequired: true,
                                    validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildInputField(
                                    label: 'CVC/CVV',
                                    hint: 'CVC',
                                    controller: _cvcController,
                                    isRequired: true,
                                    keyboardType: TextInputType.number,
                                    validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // Bottom Payment Row
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Price',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary.withValues(alpha: 0.5),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'S\$${widget.totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Subtotal: S\$${widget.totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 10, color: Colors.black54),
                              ),
                              const Text(
                                'Delivery: S\$0.00',
                                style: TextStyle(fontSize: 10, color: Colors.black54),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _handlePayment,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Make Payment - S\$${widget.totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStepCircle('1', isSelected: true),
              _buildStepLine(isActive: true),
              _buildStepCircle('2', isSelected: true, useNavy: true),
              _buildStepLine(isActive: false),
              _buildStepCircle('3', isSelected: false),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStepLabel('Info', color: const Color(0xFFF43F5E), isBold: true),
              const SizedBox(width: 80),
              _buildStepLabel('Payment', color: AppColors.primary, isBold: true),
              const SizedBox(width: 80),
              _buildStepLabel('Review', color: Colors.black38),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepLabel(String text, {required Color color, bool isBold = false}) {
    return SizedBox(
      width: 24,
      height: 16,
      child: OverflowBox(
        maxWidth: 80,
        maxHeight: 16,
        alignment: Alignment.center,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildStepCircle(String number, {required bool isSelected, bool useNavy = false}) {
    Color bgColor = Colors.grey.shade300;
    Color textColor = Colors.black45;
    if (isSelected) {
      bgColor = useNavy ? AppColors.primary : const Color(0xFFF43F5E);
      textColor = Colors.white;
    }
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        number,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildStepLine({required bool isActive}) {
    return Container(
      width: 80,
      height: 2,
      color: isActive ? AppColors.primary : Colors.grey.shade300,
    );
  }

  Widget _buildSectionCard({
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
          ],
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.danger),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontSize: 13, color: AppColors.primary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.primary.withValues(alpha: 0.35)),
            fillColor: Colors.white,
            filled: true,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.15)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.15)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}
