import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/notification_provider.dart';

/// Test screen to manually trigger notifications
/// Add this to test if notifications are working
class NotificationTestScreen extends StatelessWidget {
  const NotificationTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Notifications'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Initialization Status
                Card(
                  color: provider.isInitialized ? Colors.green[50] : Colors.red[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(
                          provider.isInitialized ? Icons.check_circle : Icons.error,
                          color: provider.isInitialized ? Colors.green : Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          provider.isInitialized
                              ? 'Notifications Initialized ✅'
                              : 'Not Initialized ❌',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!provider.isInitialized) ...[
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () async {
                              await provider.initialize();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Notifications initialized!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                            child: const Text('Initialize Now'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                const Text(
                  'Test Notifications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Simple Test
                _buildTestButton(
                  context,
                  icon: Icons.notifications_active,
                  label: 'Simple Test',
                  color: Colors.blue,
                  onPressed: () async {
                    await provider.showNotification(
                      title: 'Test Notification',
                      body: 'This is a test notification!',
                      type: NotificationType.generalUpdate,
                    );
                    _showSnackBar(context, 'Test notification sent!');
                  },
                ),

                const SizedBox(height: 12),

                // Order Placed
                _buildTestButton(
                  context,
                  icon: Icons.shopping_bag,
                  label: 'Order Placed',
                  color: Colors.green,
                  onPressed: () async {
                    await provider.notifyOrderPlaced('ORD${DateTime.now().millisecondsSinceEpoch}', 1499.0);
                    _showSnackBar(context, 'Order notification sent!');
                  },
                ),

                const SizedBox(height: 12),

                // Order Shipped
                _buildTestButton(
                  context,
                  icon: Icons.local_shipping,
                  label: 'Order Shipped',
                  color: Colors.purple,
                  onPressed: () async {
                    await provider.notifyOrderShipped('ORD123456', 'TRK789012');
                    _showSnackBar(context, 'Shipping notification sent!');
                  },
                ),

                const SizedBox(height: 12),

                // Order Delivered
                _buildTestButton(
                  context,
                  icon: Icons.check_circle,
                  label: 'Order Delivered',
                  color: Colors.teal,
                  onPressed: () async {
                    await provider.notifyOrderDelivered('ORD123456');
                    _showSnackBar(context, 'Delivery notification sent!');
                  },
                ),

                const SizedBox(height: 12),

                // Price Drop
                _buildTestButton(
                  context,
                  icon: Icons.trending_down,
                  label: 'Price Drop Alert',
                  color: Colors.orange,
                  onPressed: () async {
                    await provider.notifyPriceDrop(
                      'PROD123',
                      'Wireless Headphones',
                      2999.0,
                      1999.0,
                    );
                    _showSnackBar(context, 'Price drop alert sent!');
                  },
                ),

                const SizedBox(height: 12),

                // Payment Success
                _buildTestButton(
                  context,
                  icon: Icons.account_balance_wallet,
                  label: 'Payment Success',
                  color: Colors.green[700]!,
                  onPressed: () async {
                    await provider.notifyPaymentSuccess('ORD123456', 1499.0);
                    _showSnackBar(context, 'Payment notification sent!');
                  },
                ),

                const SizedBox(height: 12),

                // Cashback
                _buildTestButton(
                  context,
                  icon: Icons.card_giftcard,
                  label: 'Cashback Credited',
                  color: Colors.pink,
                  onPressed: () async {
                    await provider.notifyCashback(50.0, 'ORD123456');
                    _showSnackBar(context, 'Cashback notification sent!');
                  },
                ),

                const SizedBox(height: 12),

                // New Offer
                _buildTestButton(
                  context,
                  icon: Icons.local_offer,
                  label: 'New Offer',
                  color: Colors.amber[700]!,
                  onPressed: () async {
                    await provider.notifyNewOffer(
                      'Mega Sale!',
                      'Get up to 70% off on all products',
                    );
                    _showSnackBar(context, 'Offer notification sent!');
                  },
                ),

                const SizedBox(height: 24),

                // Notification Count
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Notifications:'),
                            Text(
                              '${provider.notifications.length}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Unread:'),
                            Text(
                              '${provider.unreadCount}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // View Notifications Button
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/notifications');
                  },
                  icon: const Icon(Icons.list),
                  label: const Text('View All Notifications'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),

                const SizedBox(height: 12),

                // Clear All Button
                if (provider.notifications.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () {
                      provider.clearAllNotifications();
                      _showSnackBar(context, 'All notifications cleared!');
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Clear All Notifications'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTestButton(
      BuildContext context, {
        required IconData icon,
        required String label,
        required Color color,
        required VoidCallback onPressed,
      }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        alignment: Alignment.centerLeft,
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green,
      ),
    );
  }
}