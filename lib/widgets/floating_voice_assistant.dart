import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/voice_agent_provider.dart';
import '../provider/cart_provider.dart';
import '../provider/wallet_provider.dart';
import '../provider/order_provider.dart';
import '../provider/address_provider.dart';

class FloatingVoiceAssistant extends StatefulWidget {
  final VoidCallback? onCommandExecuted;

  const FloatingVoiceAssistant({
    super.key,
    this.onCommandExecuted,
  });

  @override
  State<FloatingVoiceAssistant> createState() => _FloatingVoiceAssistantState();
}

class _FloatingVoiceAssistantState extends State<FloatingVoiceAssistant>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final voiceAgent =
      Provider.of<VoiceAgentProvider>(context, listen: false);

      voiceAgent.onCommandReady = (command) {
        debugPrint('📲 FloatingVoice: onCommandReady fired with: "$command"');
        if (mounted) _processCommand(context, command);
      };

      debugPrint('✅ Callback registered in FloatingVoiceAssistant');
    });
  }

  @override
  void dispose() {
    try {
      final voiceAgent =
      Provider.of<VoiceAgentProvider>(context, listen: false);
      voiceAgent.onCommandReady = null;
    } catch (_) {}
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }
  Future<void> _handleButtonPress(BuildContext context) async {
    final voiceAgent = Provider.of<VoiceAgentProvider>(context, listen: false);

    if (!_isExpanded) _toggleExpanded();

    if (voiceAgent.isListening) {
      debugPrint('🛑 Stopping microphone');
      await voiceAgent.stopListening();
    } else {
      debugPrint('🎤 Starting microphone');

      // ✅ CRITICAL: Longer delay for audio cleanup
      await voiceAgent.stop();
      await Future.delayed(const Duration(milliseconds: 1500)); // ← INCREASED!

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎤 Starting... Please wait'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.orange,
          ),
        );
      }

      // Small delay before starting
      await Future.delayed(const Duration(milliseconds: 500));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎤 Listening now - Speak!'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.green,
          ),
        );
      }

      await voiceAgent.startListening();
    }
  }

  Future<void> _processCommand(BuildContext context, String rawCommand) async {
    final voiceAgent = Provider.of<VoiceAgentProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final addressProvider =
    Provider.of<AddressProvider>(context, listen: false);

    final command = rawCommand.toLowerCase().trim();
    debugPrint('🔍 Processing command: "$command"');

    try {
      // ADD TO CART
      if (voiceAgent.isAddToCartCommand(command)) {
        await _handleAddToCart(context, command, voiceAgent, cartProvider);
        voiceAgent.markCommandHandled();
        widget.onCommandExecuted?.call();
        return;
      }

      // CHECKOUT
      if (_isCheckoutCommand(command)) {
        await _handleCheckout(context, command, voiceAgent, cartProvider,
            walletProvider, orderProvider, addressProvider);
        voiceAgent.markCommandHandled();
        widget.onCommandExecuted?.call();
        return;
      }

      // VIEW CART
      if (voiceAgent.isViewCartCommand(command)) {
        await voiceAgent.speak('Opening your cart');
        if (context.mounted) Navigator.pushNamed(context, '/cart');
        voiceAgent.markCommandHandled();
        widget.onCommandExecuted?.call();
        return;
      }

      // REMOVE FROM CART
      if (voiceAgent.isRemoveFromCartCommand(command)) {
        final productName = voiceAgent.parseRemoveProductName(command);
        if (productName.isNotEmpty) {
          await voiceAgent.speak('Removing $productName from cart');
        } else {
          await voiceAgent.speak('Please specify which item to remove');
        }
        voiceAgent.markCommandHandled();
        widget.onCommandExecuted?.call();
        return;
      }

      // UNKNOWN
      debugPrint('❌ Unknown command: "$command"');
      await voiceAgent.speak(
          'I did not understand. Try saying: add red dress to cart, or proceed with cash on delivery');
      voiceAgent.markCommandHandled();
      widget.onCommandExecuted?.call();

    } catch (e, stack) {
      debugPrint('❌ Error processing command: $e');
      debugPrint('Stack: $stack');
      voiceAgent.markCommandHandled();
      if (context.mounted) {
        _showSnackBar(context, 'Error processing command', Colors.red);
      }
    }
  }

  bool _isCheckoutCommand(String command) {
    return command.contains('checkout') ||
        command.contains('proceed') ||
        command.contains('place order') ||
        command.contains('complete order') ||
        command.contains('pay with') ||
        command.contains('payment');
  }

  Future<void> _handleAddToCart(
      BuildContext context,
      String command,
      VoiceAgentProvider voiceAgent,
      CartProvider cartProvider,
      ) async {
    final productName = voiceAgent.parseProductName(command);

    debugPrint('🛍️ Extracted product name: "$productName"');

    if (productName.isEmpty) {
      await voiceAgent.speak('Please say the product name');
      return;
    }

    cartProvider.addToCart({
      'id': 'prod_${DateTime.now().millisecondsSinceEpoch}',
      'name': productName,
      'price': 499.0,
      'image': 'https://via.placeholder.com/150',
      'category': 'Fashion',
    }, quantity: 1);

    await voiceAgent.speak('$productName added to cart');

    if (context.mounted) {
      _showSnackBar(context, '✅ $productName added to cart', Colors.green);
    }

    debugPrint('✅ Added $productName to cart');
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
    debugPrint('🛒 Checkout command: "$command"');

    if (cartProvider.items.isEmpty) {
      await voiceAgent.speak('Your cart is empty. Please add items first');
      if (context.mounted) {
        _showSnackBar(context, 'Cart is empty', Colors.orange);
      }
      return;
    }

    if (!addressProvider.hasAddresses) {
      await voiceAgent.speak('Please add a delivery address first');
      if (context.mounted) {
        Navigator.pushNamed(context, '/addresses');
      }
      return;
    }

    final paymentMethod = voiceAgent.parsePaymentMethod(command);
    debugPrint('💳 Detected payment method: $paymentMethod');

    if (paymentMethod == null) {
      await voiceAgent.speak('Opening checkout');
      if (context.mounted) {
        Navigator.pushNamed(context, '/checkout');
      }
      return;
    }

    await _processPayment(context, paymentMethod, voiceAgent, cartProvider,
        walletProvider, orderProvider);
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
    final methodName = voiceAgent.getPaymentMethodName(paymentMethod);

    debugPrint('💰 Processing payment: $methodName for ₹$total');

    if (paymentMethod == PaymentMethod.card ||
        paymentMethod == PaymentMethod.upi) {
      await voiceAgent.speak('Opening checkout for $methodName payment');
      if (context.mounted) {
        Navigator.pushNamed(context, '/checkout');
      }
      return;
    }

    if (paymentMethod == PaymentMethod.wallet) {
      if (walletProvider.balance < total) {
        await voiceAgent.speak('Insufficient wallet balance');
        if (context.mounted) {
          _showSnackBar(context, 'Insufficient wallet balance', Colors.red);
        }
        return;
      }
      walletProvider.deductBalance(total);
    }

    final orderId = 'ORD${DateTime.now().millisecondsSinceEpoch}';

    orderProvider.addOrder({
      'id': orderId,
      'items': List.from(cartProvider.items),
      'total': total,
      'paymentMethod': methodName,
      'status': 'placed',
      'timestamp': DateTime.now(),
    });

    cartProvider.clearCart();

    await voiceAgent.speak('Order placed successfully with $methodName');

    if (context.mounted) {
      _showSnackBar(
          context, '🎉 Order placed successfully!', Colors.green);
      Navigator.pushReplacementNamed(context, '/orderSuccess',
          arguments: orderId);
    }

    debugPrint('✅ Order placed: $orderId with $methodName');
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ));
  }

  Widget _hint(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(Icons.arrow_right, size: 13, color: Colors.blue.shade700),
          const SizedBox(width: 3),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 10, color: Colors.blue.shade900),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VoiceAgentProvider>(
      builder: (context, voiceAgent, child) {
        final isListening = voiceAgent.isListening;
        final isProcessing = voiceAgent.state == VoiceAgentState.processing;
        final isSpeaking = voiceAgent.state == VoiceAgentState.speaking;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (_isExpanded)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                width: 280,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isListening
                              ? Icons.mic
                              : isProcessing
                              ? Icons.psychology
                              : isSpeaking
                              ? Icons.volume_up
                              : Icons.mic_none,
                          color: isListening
                              ? Colors.red
                              : isProcessing
                              ? Colors.orange
                              : isSpeaking
                              ? Colors.blue
                              : Colors.purple,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isListening
                                ? '🎤 Listening...'
                                : isProcessing
                                ? '⚙️ Processing...'
                                : isSpeaking
                                ? '🔊 Speaking...'
                                : 'Tap mic to speak',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isListening ? Colors.red : Colors.purple,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _toggleExpanded();
                            if (voiceAgent.isListening) {
                              voiceAgent.stopListening();
                            }
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),

                    if (voiceAgent.recognizedText.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.purple.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.hearing,
                                    size: 13, color: Colors.purple.shade700),
                                const SizedBox(width: 4),
                                Text(
                                  'You said:',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '"${voiceAgent.recognizedText}"',
                              style: const TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '💡 Try saying:',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _hint('Proceed with cash on delivery'),

                          _hint('Pay with UPI'),
                          _hint('Place order with card'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            FloatingActionButton(
              heroTag: 'voiceAssistant',
              onPressed: () => _handleButtonPress(context),
              backgroundColor: isListening
                  ? Colors.red
                  : isProcessing
                  ? Colors.orange
                  : isSpeaking
                  ? Colors.blue
                  : Colors.purple,
              elevation: 6,
              child: Icon(
                isListening
                    ? Icons.mic
                    : isProcessing
                    ? Icons.hourglass_top
                    : isSpeaking
                    ? Icons.volume_up
                    : Icons.mic_none,
                size: 28,
                color: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }
}