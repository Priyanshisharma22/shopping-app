import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../provider/cart_provider.dart';
import '../provider/address_provider.dart';
import '../provider/wallet_provider.dart';
import '../provider/order_provider.dart';
import '../models/order_model_enhanced.dart'; // Use the enhanced model
import '../widgets/floating_voice_assistant.dart'; // ADDED: Voice Assistant Widget
import 'address_management_screen.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late Razorpay _razorpay;
  String _selectedPaymentMethod = 'razorpay';
  bool _isProcessing = false;

  static const double _codFee = 0.0;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final addressProvider =
      Provider.of<AddressProvider>(context, listen: false);
      if (!addressProvider.hasAddresses) {
        addressProvider.fetchAddresses('user_123');
      }
    });
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _processOrder(response.paymentId ?? 'RAZORPAY_SUCCESS');
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() => _isProcessing = false);
    _showErrorSnackBar(
      'Payment failed: ${response.message ?? 'Unknown error'}',
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    setState(() => _isProcessing = false);
    _showInfoSnackBar('External wallet selected: ${response.walletName}');
  }

  void _openRazorpay(double amount) {
    final options = <String, dynamic>{
      'key': 'rzp_test_SEVrnSHwWttP7u',
      'amount': (amount * 100).toInt(),
      'name': 'Your Store Name',
      'description': 'Shopping Cart Payment',
      'prefill': {
        'contact': '9876543210',
        'email': 'customer@example.com',
      },
      'theme': {'color': '#9C27B0'},
      'retry': {'enabled': true, 'max_count': 2},
    };
    try {
      _razorpay.open(options);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _showErrorSnackBar('Could not open payment gateway. Please try again.');
      debugPrint('Razorpay error: $e');
    }
  }

  Future<void> _processOrder(String paymentId) async {
    if (!mounted) return;

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final addressProvider =
    Provider.of<AddressProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    final address = addressProvider.defaultAddress;
    if (address == null) {
      setState(() => _isProcessing = false);
      _showErrorSnackBar('No delivery address found. Please add one.');
      return;
    }

    // Build OrderItem list - CartItem does NOT have selectedVariant
    final orderItems = cartProvider.items.map((cartItem) {
      return OrderItem(
        productId: cartItem.product.id,
        productName: cartItem.product.name,
        productImage: cartItem.product.imageUrl,
        price: cartItem.product.price,
        quantity: cartItem.quantity,
        size: cartItem.selectedSize,
        color: cartItem.selectedColor,
        // NO variant - CartItem doesn't have this property
      );
    }).toList();

    // Build Address for order - using the enhanced model's Address class
    final deliveryAddress = Address(
      id: address.id,
      name: _getAddressName(address),
      phone: _getAddressPhone(address),
      addressLine1: address.addressLine1,
      addressLine2: address.addressLine2 ?? '',
      city: address.city,
      state: address.state,
      pincode: address.pincode,
      landmark: address.landmark,
      isDefault: address.isDefault,
    );

    // Calculate amounts
    final subtotal = cartProvider.totalMRP - cartProvider.totalSavings;
    final deliveryFee = cartProvider.deliveryCharge;
    final discount = cartProvider.totalSavings;
    final totalAmount = subtotal + deliveryFee;

    try {
      // Call placeOrder with parameters matching order_model_enhanced.dart Order class
      final orderId = await orderProvider.placeOrder(
        items: orderItems,
        deliveryAddress: deliveryAddress,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        discount: discount,
        totalAmount: totalAmount, // Added totalAmount parameter
        paymentMethod: _mapToPaymentMethod(_selectedPaymentMethod),
      );

      cartProvider.clearCart();
      if (!mounted) return;
      setState(() => _isProcessing = false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderSuccessScreen(orderId: orderId),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _showErrorSnackBar('Order failed: ${e.toString()}');
    }
  }

  PaymentMethod _mapToPaymentMethod(String method) {
    switch (method) {
      case 'razorpay':
        return PaymentMethod.card;
      case 'wallet':
        return PaymentMethod.wallet;
      case 'cod':
        return PaymentMethod.cod;
      default:
        return PaymentMethod.cod;
    }
  }

  String _getAddressName(dynamic address) {
    try {
      return address.fullName as String;
    } catch (e) {
      try {
        return address.name as String;
      } catch (e) {
        return 'Customer';
      }
    }
  }

  String _getAddressPhone(dynamic address) {
    try {
      return address.phoneNumber as String;
    } catch (e) {
      try {
        return address.phone as String;
      } catch (e) {
        return '';
      }
    }
  }

  String _getAddressLabel(dynamic address) {
    try {
      return address.label ?? 'Home';
    } catch (e) {
      return 'Home';
    }
  }

  String _getFullAddress(dynamic address) {
    try {
      final fullAddressWithLandmark = address.fullAddressWithLandmark;
      if (fullAddressWithLandmark != null &&
          fullAddressWithLandmark.isNotEmpty) {
        return fullAddressWithLandmark;
      }
    } catch (e) {
      // Continue
    }

    try {
      final fullAddress = address.fullAddress;
      if (fullAddress != null && fullAddress.isNotEmpty) {
        return fullAddress;
      }
    } catch (e) {
      // Continue
    }

    final parts = <String>[];
    try {
      parts.add(address.addressLine1);
      if (address.addressLine2 != null && address.addressLine2.isNotEmpty) {
        parts.add(address.addressLine2);
      }
      if (address.landmark != null && address.landmark.isNotEmpty) {
        parts.add(address.landmark);
      }
      parts.add(address.city);
      parts.add('${address.state} - ${address.pincode}');
    } catch (e) {
      return 'Address not available';
    }
    return parts.join(', ');
  }

  double _totalPayable(CartProvider cart) {
    double total = cart.finalAmount;
    if (_selectedPaymentMethod == 'cod') total += _codFee;
    return total;
  }

  Future<void> _handleWalletPayment() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);

    final total = _totalPayable(cartProvider);

    if (!walletProvider.hasSufficientBalance(total)) {
      final shortfall = total - walletProvider.balance;
      _showErrorSnackBar(
        'Insufficient wallet balance. You need ₹${shortfall.toStringAsFixed(0)} more.',
      );
      return;
    }

    setState(() => _isProcessing = true);

    final success = await walletProvider.processShoppingPayment(
      amount: total,
      orderId: 'ORD${DateTime.now().millisecondsSinceEpoch}',
      description: 'Shopping order payment',
    );

    if (success) {
      await _processOrder('WALLET_${DateTime.now().millisecondsSinceEpoch}');
    } else {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _showErrorSnackBar('Wallet payment failed. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final addressProvider = Provider.of<AddressProvider>(context);
    final walletProvider = Provider.of<WalletProvider>(context);
    final address = addressProvider.defaultAddress;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text(
          'Checkout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        // ADDED: Voice Assistant Button in AppBar
        actions: [
          IconButton(
            icon: const Icon(Icons.mic, color: Colors.purple),
            onPressed: () {
              Navigator.pushNamed(context, '/voiceAgent');
            },
            tooltip: 'Voice Assistant',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey[200], height: 1),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildStepIndicator(),
            const SizedBox(height: 8),

            // ADDED: Voice Checkout Helper Banner
            _buildVoiceCheckoutBanner(),

            _buildDeliveryAddressSection(address, addressProvider),
            const SizedBox(height: 8),
            _buildOrderItemsSection(cartProvider),
            const SizedBox(height: 8),
            _buildPaymentMethodSection(walletProvider),
            const SizedBox(height: 8),
            _buildPriceDetailsSection(cartProvider),
            if (cartProvider.totalSavings > 0) _buildSavingsBanner(cartProvider),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(cartProvider, address),

      // ADDED: Floating Voice Assistant Button
      floatingActionButton: const FloatingVoiceAssistant(),
    );
  }

  // ADDED: Voice Checkout Helper Banner
  Widget _buildVoiceCheckoutBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade200,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.mic,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🎤 Complete checkout with voice',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Say "Proceed with wallet" or "Pay with COD"',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _stepDot('Cart', isCompleted: true),
          _stepLine(true),
          _stepDot('Checkout', isActive: true),
          _stepLine(false),
          _stepDot('Payment'),
        ],
      ),
    );
  }

  Widget _stepDot(String label,
      {bool isCompleted = false, bool isActive = false}) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isCompleted
                ? Colors.green
                : isActive
                ? Colors.purple
                : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCompleted ? Icons.check : Icons.circle,
            size: isCompleted ? 16 : 10,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.purple : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _stepLine(bool completed) {
    return Container(
      width: 60,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      color: completed ? Colors.green : Colors.grey[300],
    );
  }

  Widget _buildDeliveryAddressSection(
      dynamic address, AddressProvider addressProvider) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.purple, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Delivery Address',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddressManagementScreen(),
                    ),
                  );
                  if (mounted) {
                    Provider.of<AddressProvider>(context, listen: false)
                        .refreshAddresses();
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.purple,
                  padding: EdgeInsets.zero,
                ),
                child: Text(
                  address == null ? 'Add' : 'Change',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (address != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.purple[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.purple[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getAddressLabel(address),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple[800],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getAddressName(address),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getFullAddress(address),
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey[800], height: 1.4),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 13, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        _getAddressPhone(address),
                        style:
                        TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AddressManagementScreen()),
              ),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.add_location_alt_outlined,
                        color: Colors.purple[300]),
                    const SizedBox(width: 12),
                    const Text(
                      'Add a delivery address',
                      style: TextStyle(
                          color: Colors.purple, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderItemsSection(CartProvider cartProvider) {
    final items = cartProvider.items;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shopping_bag_outlined,
                  color: Colors.purple, size: 20),
              const SizedBox(width: 8),
              Text(
                '${items.length} ${items.length == 1 ? 'Item' : 'Items'} in Order',
                style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
                (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.product.imageUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 56,
                        height: 56,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.product.name,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (item.selectedSize != null)
                              'Size: ${item.selectedSize}',
                            if (item.selectedColor != null)
                              'Color: ${item.selectedColor}',
                          ].join(' • '),
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'x${item.quantity}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        '₹${(item.product.price * item.quantity).toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection(WalletProvider walletProvider) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.payment, color: Colors.purple, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Payment Method',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              // ADDED: Voice payment hint
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.mic, size: 10, color: Colors.blue.shade700),
                    const SizedBox(width: 3),
                    Text(
                      'Use Voice',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPaymentTile(
            value: 'razorpay',
            icon: Icons.credit_card,
            title: 'Card / UPI / Net Banking',
            subtitle: 'Powered by Razorpay',
          ),
          const Divider(height: 1),
          _buildPaymentTile(
            value: 'wallet',
            icon: Icons.account_balance_wallet_outlined,
            title: 'Wallet Balance',
            subtitle:
            'Available: ₹${walletProvider.balance.toStringAsFixed(2)}',
            suffixWidget: walletProvider.balance <= 0
                ? Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Low Balance',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.red[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
                : null,
          ),
          const Divider(height: 1),
          _buildPaymentTile(
            value: 'cod',
            icon: Icons.money_outlined,
            title: 'Cash on Delivery',
            subtitle: _codFee > 0
                ? 'Extra ₹${_codFee.toStringAsFixed(0)} COD fee applies'
                : 'No extra charges',
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTile({
    required String value,
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? suffixWidget,
  }) {
    final isSelected = _selectedPaymentMethod == value;

    return InkWell(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple[50] : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: _selectedPaymentMethod,
              onChanged: (String? val) {
                if (val != null) {
                  setState(() => _selectedPaymentMethod = val);
                }
              },
              activeColor: Colors.purple,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.purple[100] : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.purple : Colors.grey[600],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.purple[700] : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.purple[400] : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            if (suffixWidget != null) suffixWidget,
          ],
        ),
      ),
    );
  }

  Widget _buildPriceDetailsSection(CartProvider cartProvider) {
    final codFeeApplies = _selectedPaymentMethod == 'cod' && _codFee > 0;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_outlined,
                  color: Colors.purple, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Price Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _priceRow(
              'Total MRP', '₹${cartProvider.totalMRP.toStringAsFixed(0)}'),
          if (cartProvider.totalSavings > 0) ...[
            const SizedBox(height: 10),
            _priceRow(
              'Discount',
              '- ₹${cartProvider.totalSavings.toStringAsFixed(0)}',
              valueColor: Colors.green[700],
            ),
          ],
          const SizedBox(height: 10),
          _priceRow(
            'Delivery Charges',
            cartProvider.deliveryCharge == 0
                ? 'FREE'
                : '₹${cartProvider.deliveryCharge.toStringAsFixed(0)}',
            valueColor:
            cartProvider.deliveryCharge == 0 ? Colors.green[700] : null,
          ),
          if (codFeeApplies) ...[
            const SizedBox(height: 10),
            _priceRow(
              'COD Fee',
              '₹${_codFee.toStringAsFixed(0)}',
              valueColor: Colors.orange[700],
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1),
          ),
          _priceRow(
            'Total Payable',
            '₹${_totalPayable(cartProvider).toStringAsFixed(0)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value,
      {bool isTotal = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 15 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.black : Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? (isTotal ? Colors.purple : Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildSavingsBanner(CartProvider cartProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: Colors.green[50],
      child: Row(
        children: [
          Icon(Icons.local_offer, color: Colors.green[700], size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'You are saving ₹${cartProvider.totalSavings.toStringAsFixed(0)} on this order! 🎉',
              style: TextStyle(
                color: Colors.green[800],
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(CartProvider cartProvider, dynamic address) {
    final canPay = address != null && !_isProcessing;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 13, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    'Secured by 256-bit SSL encryption',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canPay ? _onPayPressed(cartProvider) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  disabledBackgroundColor: Colors.purple.withValues(alpha: 0.4),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: _isProcessing
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock, size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      address == null
                          ? 'Add Address to Proceed'
                          : 'Pay ₹${_totalPayable(cartProvider).toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  VoidCallback _onPayPressed(CartProvider cartProvider) {
    return () {
      switch (_selectedPaymentMethod) {
        case 'razorpay':
          setState(() => _isProcessing = true);
          _openRazorpay(_totalPayable(cartProvider));
          break;
        case 'wallet':
          _handleWalletPayment();
          break;
        case 'cod':
          setState(() => _isProcessing = true);
          _processOrder('COD');
          break;
      }
    };
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}