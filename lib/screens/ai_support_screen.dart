import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/support_agent_provider.dart';
import '../provider/auth_provider.dart';
import '../provider/order_provider.dart';
import '../provider/cart_provider.dart';
import '../widgets/chat_message_widget.dart';
import '../widgets/quick_actions_widget.dart';
import '../widgets/typing_indicator.dart';

class AISupportScreen extends StatefulWidget {
  const AISupportScreen({Key? key}) : super(key: key);

  @override
  State<AISupportScreen> createState() => _AISupportScreenState();
}

class _AISupportScreenState extends State<AISupportScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSupport();
    });
  }

  void _initializeSupport() {
    if (_isInitialized) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final supportProvider = Provider.of<SupportAgentProvider>(context, listen: false);

    // ✅ Fixed: CartItem has nested product object
    supportProvider.initialize(
      userId: authProvider.userId ?? 'guest',
      userName: authProvider.userName,
      userPhone: authProvider.userPhone,
      userEmail: authProvider.userEmail,
      recentOrders: orderProvider.orders.take(5).map((order) => {
        'id': order.orderId,
        'status': order.status,
        'total': order.totalAmount,
        'date': order.orderDate.toIso8601String(),
      }).toList(),
      cart: cartProvider.items.map((item) => {
        'productId': item.product.id,        // ✅ Access via item.product.id
        'name': item.product.name,           // ✅ Access via item.product.name
        'quantity': item.quantity,           // ✅ Direct property
        'price': item.product.price,         // ✅ Access via item.product.price
        'selectedSize': item.selectedSize,   // ✅ Optional: Include variant info
        'selectedColor': item.selectedColor, // ✅ Optional: Include variant info
      }).toList(),
    );

    _isInitialized = true;
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final supportProvider = Provider.of<SupportAgentProvider>(context, listen: false);
    supportProvider.sendMessage(message);
    _messageController.clear();

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.purple.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy, color: Colors.purple),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Support',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Always here to help 24/7',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              final supportProvider = Provider.of<SupportAgentProvider>(context, listen: false);

              if (value == 'clear') {
                supportProvider.clearChat();
              } else if (value == 'language') {
                _showLanguageDialog();
              } else if (value == 'human') {
                supportProvider.handleQuickAction('talk_to_human');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'language',
                child: Row(
                  children: [
                    Icon(Icons.language, size: 20),
                    SizedBox(width: 12),
                    Text('Change Language'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'human',
                child: Row(
                  children: [
                    Icon(Icons.support_agent, size: 20),
                    SizedBox(width: 12),
                    Text('Talk to Human'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20),
                    SizedBox(width: 12),
                    Text('Clear Chat'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick Actions
          Consumer<SupportAgentProvider>(
            builder: (context, provider, child) {
              if (provider.messages.length <= 1) {
                return const QuickActionsWidget();
              }
              return const SizedBox.shrink();
            },
          ),

          // Chat Messages
          Expanded(
            child: Consumer<SupportAgentProvider>(
              builder: (context, provider, child) {
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.messages.length + (provider.isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == provider.messages.length) {
                      return const TypingIndicator();
                    }

                    final message = provider.messages[index];
                    return ChatMessageWidget(message: message);
                  },
                );
              },
            ),
          ),

          // Input Area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: Colors.purple),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  mini: true,
                  backgroundColor: Colors.purple,
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('English'),
            _buildLanguageOption('हिंदी (Hindi)'),
            _buildLanguageOption('தமிழ் (Tamil)'),
            _buildLanguageOption('తెలుగు (Telugu)'),
            _buildLanguageOption('मराठी (Marathi)'),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String language) {
    return Consumer<SupportAgentProvider>(
      builder: (context, provider, child) {
        final isSelected = provider.currentLanguage == language.split(' ').first;
        return RadioListTile<String>(
          title: Text(language),
          value: language.split(' ').first,
          groupValue: provider.currentLanguage,
          activeColor: Colors.purple,
          onChanged: (value) {
            provider.setLanguage(value!);
            Navigator.pop(context);
          },
        );
      },
    );
  }
}