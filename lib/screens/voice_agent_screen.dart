import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/voice_agent_provider.dart';
import '../provider/cart_provider.dart';
import '../provider/wallet_provider.dart';
import '../provider/order_provider.dart';
import '../provider/address_provider.dart';
import 'cart_screen.dart';
import 'checkout_screen.dart';

class VoiceAgentScreen extends StatefulWidget {
  const VoiceAgentScreen({super.key});

  @override
  State<VoiceAgentScreen> createState() => _VoiceAgentScreenState();
}

class _VoiceAgentScreenState extends State<VoiceAgentScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final voiceAgent =
      Provider.of<VoiceAgentProvider>(context, listen: false);
      voiceAgent.onCommandReady = (command) {
        debugPrint('📲 VoiceAgentScreen onCommandReady: "$command"');
        if (mounted) _processCommand(context, command);
      };
    });
  }

  @override
  void dispose() {
    try {
      final voiceAgent =
      Provider.of<VoiceAgentProvider>(context, listen: false);
      voiceAgent.onCommandReady = null;
    } catch (_) {}
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _processCommand(BuildContext context, String rawCommand) async {
    final voiceAgent      = Provider.of<VoiceAgentProvider>(context, listen: false);
    final cartProvider    = Provider.of<CartProvider>(context, listen: false);
    final walletProvider  = Provider.of<WalletProvider>(context, listen: false);
    final orderProvider   = Provider.of<OrderProvider>(context, listen: false);
    final addressProvider = Provider.of<AddressProvider>(context, listen: false);

    final command = rawCommand.toLowerCase().trim();
    debugPrint('🔍 VoiceAgentScreen processing: "$command"');

    try {
      if (_isCheckoutTrigger(command)) {
        await _handleCheckout(context, command, voiceAgent,
            cartProvider, walletProvider, orderProvider, addressProvider);
        voiceAgent.markCommandHandled();
        return;
      }

      if (voiceAgent.isAddToCartCommand(command) ||
          (command.contains('add') && command.contains('card'))) {
        await _handleAddToCart(context, command, voiceAgent, cartProvider);
        voiceAgent.markCommandHandled();
        return;
      }

      if (voiceAgent.isViewCartCommand(command)) {
        await voiceAgent.speak('Opening your cart');
        if (context.mounted) {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const CartScreen()));
        }
        voiceAgent.markCommandHandled();
        return;
      }

      if (voiceAgent.isRemoveFromCartCommand(command)) {
        final result = voiceAgent.parseCommand(command);
        final productName = result['product'] ?? '';
        if (productName.isNotEmpty) {
          await voiceAgent.speak('Removing $productName from cart');
        } else {
          await voiceAgent.speak('Please specify which item to remove.');
        }
        voiceAgent.markCommandHandled();
        return;
      }

      await voiceAgent.speak(
          'I did not understand. Try: add dress to cart, or proceed with wallet.');
      voiceAgent.markCommandHandled();
    } catch (e) {
      debugPrint('❌ Error processing command: $e');
      voiceAgent.markCommandHandled();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error processing command'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _isCheckoutTrigger(String command) {
    return command.contains('checkout') ||
        command.contains('check out') ||
        command.contains('proceed') ||
        command.contains('place order') ||
        command.contains('complete order') ||
        command.contains('pay') ||
        command.contains('payment') ||
        command.contains('cash') ||
        command.contains('cod') ||
        command.contains('wallet') ||
        command.contains('upi') ||
        command.contains('google pay') ||
        command.contains('phonepe') ||
        command.contains('paytm');
  }

  Future<void> _handleAddToCart(
      BuildContext context,
      String command,
      VoiceAgentProvider voiceAgent,
      CartProvider cartProvider,
      ) async {
    final result = voiceAgent.parseCommand(command);
    final productName = result['product'] ?? '';

    if (productName.isNotEmpty) {
      cartProvider.addToCart({
        'id': 'prod_${DateTime.now().millisecondsSinceEpoch}',
        'name': productName,
        'price': 499.0,
        'image': 'https://via.placeholder.com/150',
        'category': 'Fashion',
      }, quantity: 1);
      await voiceAgent.speak('$productName added to cart');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ $productName added to cart'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } else {
      await voiceAgent.speak('Please say the product name.');
    }
  }

  Future<void> _handleCheckout(
      BuildContext context,
      String command,
      VoiceAgentProvider voiceAgent,
      CartProvider cartProvider,
      WalletProvider walletProvider,
      OrderProvider orderProvider,
      AddressProvider addressProvider,
      ) async {
    if (cartProvider.items.isEmpty) {
      await voiceAgent.speak('Your cart is empty. Please add items first.');
      return;
    }
    if (!addressProvider.hasAddresses) {
      await voiceAgent.speak('Please add a delivery address first.');
      if (context.mounted) Navigator.pushNamed(context, '/addresses');
      return;
    }

    final result = voiceAgent.parseCommand(command);
    final paymentMethod = result['paymentMethod'];

    if (paymentMethod == null) {
      await voiceAgent.speak('Opening checkout.');
      if (context.mounted) {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CheckoutScreen()));
      }
      return;
    }

    await _processPayment(context, paymentMethod, voiceAgent,
        cartProvider, walletProvider, orderProvider);
  }

  Future<void> _processPayment(
      BuildContext context,
      PaymentMethod paymentMethod,
      VoiceAgentProvider voiceAgent,
      CartProvider cartProvider,
      WalletProvider walletProvider,
      OrderProvider orderProvider,
      ) async {
    final total = cartProvider.finalAmount;
    final name  = voiceAgent.getPaymentMethodName(paymentMethod);

    if (paymentMethod == PaymentMethod.card ||
        paymentMethod == PaymentMethod.upi) {
      await voiceAgent.speak('Opening checkout for $name payment.');
      if (context.mounted) {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CheckoutScreen()));
      }
      return;
    }

    if (paymentMethod == PaymentMethod.wallet) {
      if (walletProvider.balance < total) {
        await voiceAgent.speak('Insufficient wallet balance.');
        return;
      }
      walletProvider.deductBalance(total);
    }

    final orderId = 'ORD${DateTime.now().millisecondsSinceEpoch}';
    orderProvider.addOrder({
      'id': orderId,
      'items': List.from(cartProvider.items),
      'total': total,
      'paymentMethod': name,
      'status': 'placed',
      'timestamp': DateTime.now(),
    });
    cartProvider.clearCart();

    await voiceAgent.speak('Order placed with $name!');
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/orderSuccess',
          arguments: orderId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎤 Voice Shopping Assistant'),
        centerTitle: true,
      ),
      body: Consumer<VoiceAgentProvider>(
        builder: (context, voiceAgent, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildVoiceStatusCard(voiceAgent),
                const SizedBox(height: 24),
                _buildMicrophoneButton(voiceAgent),
                const SizedBox(height: 24),
                if (voiceAgent.recognizedText.isNotEmpty)
                  _buildRecognizedTextCard(voiceAgent),
                const SizedBox(height: 24),
                _buildCommandExamplesCard(),
                const SizedBox(height: 24),
                _buildQuickActionsCard(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildVoiceStatusCard(VoiceAgentProvider voiceAgent) {
    String statusText;
    IconData statusIcon;
    Color statusColor;

    switch (voiceAgent.state) {
      case VoiceAgentState.listening:
        statusText = 'Listening...';
        statusIcon = Icons.mic;
        statusColor = Colors.red;
        break;
      case VoiceAgentState.processing:
        statusText = 'Processing...';
        statusIcon = Icons.psychology;
        statusColor = Colors.orange;
        break;
      case VoiceAgentState.speaking:
        statusText = 'Speaking...';
        statusIcon = Icons.volume_up;
        statusColor = Colors.blue;
        break;
      default:
        statusText = 'Ready to listen';
        statusIcon = Icons.mic_none;
        statusColor = Colors.grey;
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  if (voiceAgent.lastCommand.isNotEmpty)
                    Text(
                      'Last: "${voiceAgent.lastCommand}"',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMicrophoneButton(VoiceAgentProvider voiceAgent) {
    final isListening = voiceAgent.isListening;

    return GestureDetector(
      onTap: () async {
        if (isListening) {
          await voiceAgent.stopListening();
        } else {
          debugPrint('🔧 Preparing audio for listening...');
          await voiceAgent.stop();
          await Future.delayed(const Duration(milliseconds: 100));

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎤 Listening... Speak your command'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
          await voiceAgent.startListening();
        }
      },
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: isListening ? _pulseAnimation.value : 1.0,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isListening
                      ? [Colors.red.shade400, Colors.red.shade700]
                      : [Colors.purple.shade400, Colors.purple.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isListening ? Colors.red : Colors.purple)
                        .withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                isListening ? Icons.mic : Icons.mic_none,
                size: 70,
                color: Colors.white,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecognizedTextCard(VoiceAgentProvider voiceAgent) {
    return Card(
      color: Colors.purple.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.hearing, color: Colors.purple.shade700),
                const SizedBox(width: 8),
                Text(
                  'You said:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '"${voiceAgent.recognizedText}"',
              style: const TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommandExamplesCard() {
    final examples = [
      {'icon': Icons.add_shopping_cart,     'text': 'Add red dress to cart'},
      {'icon': Icons.shopping_bag,           'text': 'Add blue jeans to cart'},
      {'icon': Icons.payment,                'text': 'Checkout with cash on delivery'},
      {'icon': Icons.account_balance_wallet, 'text': 'Proceed with wallet'},
      {'icon': Icons.credit_card,            'text': 'Complete order with card'},
      {'icon': Icons.phone_android,          'text': 'Place order with UPI'},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.tips_and_updates, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Try These Commands',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...examples.map((example) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(example['icon'] as IconData,
                      size: 20, color: Colors.purple),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      example['text'] as String,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CartScreen()),
                    ),
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text('View Cart'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const CheckoutScreen()),
                    ),
                    icon: const Icon(Icons.payment),
                    label: const Text('Checkout'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}