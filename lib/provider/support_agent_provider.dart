import 'package:flutter/foundation.dart';
import '../models/support_message.dart';

class SupportAgentProvider extends ChangeNotifier {
  final List<SupportMessage> _messages = [];
  bool _isTyping = false;
  String _currentLanguage = 'English';

  // User context
  String? _userId;
  String? _userName;
  String? _userPhone;
  String? _userEmail;
  List<Map<String, dynamic>> _recentOrders = [];
  List<Map<String, dynamic>> _cart = [];

  List<SupportMessage> get messages => _messages;
  bool get isTyping => _isTyping;
  String get currentLanguage => _currentLanguage;

  // Initialize with user context
  void initialize({
    required String userId,
    String? userName,
    String? userPhone,
    String? userEmail,
    List<Map<String, dynamic>>? recentOrders,
    List<Map<String, dynamic>>? cart,
  }) {
    _userId = userId;
    _userName = userName;
    _userPhone = userPhone;
    _userEmail = userEmail;
    _recentOrders = recentOrders ?? [];
    _cart = cart ?? [];

    // Add welcome message
    if (_messages.isEmpty) {
      _addWelcomeMessage();
    }
  }

  void _addWelcomeMessage() {
    final greeting = _userName != null
        ? 'Hi $_userName! I\'m your Meesho AI Assistant.'
        : 'Hi! I\'m your Meesho AI Assistant.';

    final welcomeMessage = SupportMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: '''$greeting

I can help you with:
📦 Order tracking & updates
💰 Returns & refunds
💳 Payment issues
❓ Product questions
🛍️ Shopping assistance

How can I help you today?''',
      isUser: false,
      timestamp: DateTime.now(),
    );

    _messages.add(welcomeMessage);
    notifyListeners();
  }

  void sendMessage(String text) {
    if (text.trim().isEmpty) return;

    // Add user message
    final userMessage = SupportMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    _messages.add(userMessage);
    notifyListeners();

    // Show typing indicator
    _isTyping = true;
    notifyListeners();

    // Generate AI response
    Future.delayed(const Duration(milliseconds: 1500), () {
      try {
        final response = _generateResponse(text);
        _addAIMessage(response);
      } catch (e) {
        _addAIMessage(
          'I apologize, but I\'m having trouble processing your request right now. '
              'Please try again in a moment, or type "human" to connect with our support team.',
        );
      } finally {
        _isTyping = false;
        notifyListeners();
      }
    });
  }

  String _generateResponse(String userMessage) {
    final message = userMessage.toLowerCase().trim();

    // Order tracking
    if (message.contains('order') || message.contains('track') || message.contains('delivery')) {
      if (_recentOrders.isEmpty) {
        return 'I don\'t see any recent orders in your account. If you\'ve placed an order recently, it might take a few minutes to appear in our system.\n\nWould you like to:\n• Browse products\n• Check order history\n• Contact support';
      }

      final latestOrder = _recentOrders.first;
      return 'I can help you track your order!\n\n'
          'Your latest order (${latestOrder['id']}) is currently: ${latestOrder['status']}\n'
          'Order total: ₹${latestOrder['total']}\n\n'
          'Would you like more details about this order?';
    }

    // Cart queries
    if (message.contains('cart') || message.contains('basket')) {
      if (_cart.isEmpty) {
        return 'Your cart is currently empty. 🛒\n\nWould you like me to:\n• Help you find products\n• Show trending items\n• Apply discount codes';
      }

      return 'You have ${_cart.length} item(s) in your cart:\n\n' +
          _cart.map((item) => '• ${item['name']} (Qty: ${item['quantity']})').join('\n') +
          '\n\nReady to checkout?';
    }

    // Returns & refunds
    if (message.contains('return') || message.contains('refund') || message.contains('exchange')) {
      return 'I can help you with returns and refunds! 💰\n\n'
          'Our return policy:\n'
          '• 7-day return window\n'
          '• Free pickup\n'
          '• Full refund or exchange\n\n'
          'Do you want to:\n'
          '1. Return a recent order\n'
          '2. Check refund status\n'
          '3. Learn about our policy';
    }

    // Payment issues
    if (message.contains('payment') || message.contains('pay') || message.contains('failed')) {
      return 'I understand you\'re having payment issues. Let me help! 💳\n\n'
          'Common solutions:\n'
          '• Check your internet connection\n'
          '• Verify card details\n'
          '• Try a different payment method\n'
          '• Clear app cache\n\n'
          'If the issue persists, I can connect you with our payment support team.';
    }

    // Product questions
    if (message.contains('size') || message.contains('color') || message.contains('material') ||
        message.contains('available') || message.contains('stock')) {
      return 'I\'d be happy to help with product information! 👗\n\n'
          'Please share:\n'
          '• Product name or link\n'
          '• What you\'d like to know (size, color, material, etc.)\n\n'
          'I\'ll provide detailed information right away!';
    }

    // Greetings
    if (message.contains('hello') || message.contains('hi') || message.contains('hey')) {
      return 'Hello! 👋 How can I assist you today?\n\n'
          'I can help with:\n'
          '• Order tracking\n'
          '• Returns & refunds\n'
          '• Product queries\n'
          '• Shopping assistance';
    }

    // Talk to human
    if (message.contains('human') || message.contains('agent') || message.contains('representative')) {
      return 'I\'ll connect you with our support team right away! 🙋\n\n'
          'A human agent will respond within 2-3 minutes.\n'
          'Reference ID: ${DateTime.now().millisecondsSinceEpoch}\n\n'
          'While you wait, feel free to ask me anything!';
    }

    // Language request
    if (message.contains('hindi') || message.contains('हिंदी')) {
      return 'नमस्ते! मैं आपकी मदद के लिए यहां हूं। 🙏\n\n'
          'मैं आपकी मदद कर सकता हूं:\n'
          '• ऑर्डर ट्रैकिंग\n'
          '• रिटर्न और रिफंड\n'
          '• प्रोडक्ट की जानकारी\n'
          '• शॉपिंग सहायता\n\n'
          'आपको किस चीज में मदद चाहिए?';
    }

    // Default response
    return 'I\'m here to help! I can assist you with:\n\n'
        '📦 **Order Tracking** - Check your delivery status\n'
        '💰 **Returns & Refunds** - Process returns easily\n'
        '💳 **Payment Help** - Resolve payment issues\n'
        '❓ **Product Info** - Size, color, availability\n'
        '🛍️ **Shopping Help** - Find what you need\n\n'
        'What would you like help with today?';
  }

  void _addAIMessage(String text) {
    final aiMessage = SupportMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text,
      isUser: false,
      timestamp: DateTime.now(),
    );

    _messages.add(aiMessage);
    _isTyping = false;
    notifyListeners();
  }

  void handleQuickAction(String action) {
    switch (action) {
      case 'track_order':
        sendMessage('Track my order');
        break;
      case 'check_refund':
        sendMessage('Check my refund status');
        break;
      case 'product_help':
        sendMessage('I need help with a product');
        break;
      case 'talk_to_human':
        sendMessage('I want to talk to a human agent');
        break;
      case 'payment_issue':
        sendMessage('I have a payment issue');
        break;
      default:
        sendMessage(action);
    }
  }

  void setLanguage(String language) {
    _currentLanguage = language;

    // Send confirmation message in selected language
    String confirmationMessage;
    switch (language) {
      case 'Hindi':
        confirmationMessage = 'भाषा हिंदी में बदल गई है। मैं आपकी कैसे मदद कर सकता हूं?';
        break;
      case 'Tamil':
        confirmationMessage = 'மொழி தமிழுக்கு மாற்றப்பட்டது. நான் உங்களுக்கு எவ்வாறு உதவ முடியும்?';
        break;
      case 'Telugu':
        confirmationMessage = 'భాష తెలుగుకు మార్చబడింది. నేను మీకు ఎలా సహాయం చేయగలను?';
        break;
      case 'Marathi':
        confirmationMessage = 'भाषा मराठीत बदलली. मी तुम्हाला कशी मदत करू शकतो?';
        break;
      default:
        confirmationMessage = 'Language changed to English. How can I help you?';
    }

    _addAIMessage(confirmationMessage);
  }

  void clearChat() {
    _messages.clear();
    _addWelcomeMessage();
  }
}