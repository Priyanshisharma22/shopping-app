import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/support_agent_provider.dart';
import '../provider/auth_provider.dart';
import '../provider/cart_provider.dart';
import '../provider/order_provider.dart';

/// Add this screen temporarily to test AI Support
/// Route: '/test-support'
class TestAISupportScreen extends StatelessWidget {
  const TestAISupportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test AI Support'),
        backgroundColor: Colors.purple,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Status Card
          _buildStatusCard(context),

          const SizedBox(height: 20),

          // Test Buttons
          _buildTestButton(
            context,
            icon: Icons.support_agent,
            title: 'Open AI Support',
            subtitle: 'Navigate to support screen',
            color: Colors.purple,
            onTap: () => Navigator.pushNamed(context, '/support'),
          ),

          const SizedBox(height: 12),

          _buildTestButton(
            context,
            icon: Icons.check_circle,
            title: 'Check Provider',
            subtitle: 'Verify SupportAgentProvider is registered',
            color: Colors.blue,
            onTap: () => _checkProvider(context),
          ),

          const SizedBox(height: 12),

          _buildTestButton(
            context,
            icon: Icons.message,
            title: 'Send Test Message',
            subtitle: 'Send a test message to AI',
            color: Colors.green,
            onTap: () => _sendTestMessage(context),
          ),

          const SizedBox(height: 12),

          _buildTestButton(
            context,
            icon: Icons.info,
            title: 'Check User Context',
            subtitle: 'View user data being sent to AI',
            color: Colors.orange,
            onTap: () => _checkUserContext(context),
          ),

          const SizedBox(height: 20),

          // Info Card
          _buildInfoCard(),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.smart_toy,
              size: 60,
              color: Colors.purple,
            ),
            const SizedBox(height: 12),
            const Text(
              'AI Support Agent',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Consumer<SupportAgentProvider>(
              builder: (context, provider, child) {
                return Text(
                  'Status: ${provider.messages.isEmpty ? "Not initialized" : "Active"}',
                  style: TextStyle(
                    color: provider.messages.isEmpty ? Colors.orange : Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required Color color,
        required VoidCallback onTap,
      }) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Testing Tips',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTip('1. First check if provider is registered'),
            _buildTip('2. Try sending a test message'),
            _buildTip('3. Open the full support screen'),
            _buildTip('4. Test with: "Hello", "Track order", "Cart"'),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  void _checkProvider(BuildContext context) {
    try {
      final provider = Provider.of<SupportAgentProvider>(
        context,
        listen: false,
      );

      _showSuccessDialog(
        context,
        'Provider Check',
        '✅ SupportAgentProvider is registered!\n\n'
            'Messages: ${provider.messages.length}\n'
            'Language: ${provider.currentLanguage}\n'
            'Typing: ${provider.isTyping}',
      );
    } catch (e) {
      _showErrorDialog(
        context,
        'Provider Error',
        '❌ Provider not found!\n\n'
            'Error: $e\n\n'
            'Make sure SupportAgentProvider is added to MultiProvider in main.dart',
      );
    }
  }

  void _sendTestMessage(BuildContext context) {
    try {
      final provider = Provider.of<SupportAgentProvider>(
        context,
        listen: false,
      );

      provider.sendMessage('Test message: Hello AI!');

      _showSuccessDialog(
        context,
        'Message Sent',
        '✅ Test message sent successfully!\n\n'
            'Navigate to AI Support screen to see the response.',
      );

      // Auto-navigate after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushNamed(context, '/support');
      });
    } catch (e) {
      _showErrorDialog(
        context,
        'Send Error',
        '❌ Failed to send message!\n\nError: $e',
      );
    }
  }

  void _checkUserContext(BuildContext context) {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);

      final info = '''
✅ User Context Available:

👤 User Info:
  • ID: ${authProvider.userId ?? 'Not logged in'}
  • Name: ${authProvider.userName ?? 'N/A'}
  • Phone: ${authProvider.userPhone ?? 'N/A'}

🛒 Cart:
  • Items: ${cartProvider.items.length}
  • Total: ₹${cartProvider.totalAmount.toStringAsFixed(2)}

📦 Orders:
  • Total Orders: ${orderProvider.orders.length}
  • Recent Orders: ${orderProvider.orders.take(3).length}

This data will be sent to AI Support for context-aware responses.
      ''';

      _showSuccessDialog(context, 'User Context', info);
    } catch (e) {
      _showErrorDialog(
        context,
        'Context Error',
        '❌ Error reading user context!\n\nError: $e',
      );
    }
  }

  void _showSuccessDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}