import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../provider/notification_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey[200], height: 1),
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              if (provider.unreadCount > 0) {
                return TextButton(
                  onPressed: () {
                    provider.markAllAsRead();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All notifications marked as read'),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text('Mark all read'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear_all') {
                _showClearAllDialog(
                    context, context.read<NotificationProvider>());
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20),
                    SizedBox(width: 12),
                    Text('Clear all'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (provider.notifications.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(seconds: 1));
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: provider.notifications.length,
              itemBuilder: (context, index) {
                final notification = provider.notifications[index];
                return _buildNotificationCard(
                    context, notification, provider);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(
      BuildContext context,
      NotificationModel notification,
      NotificationProvider provider,
      ) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        provider.deleteNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notification deleted'),
            action: SnackBarAction(label: 'Undo', onPressed: () {}),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: InkWell(
        onTap: () {
          provider.markAsRead(notification.id);
          _handleNotificationTap(context, notification);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: notification.isRead
                ? Colors.white
                : Colors.purple.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: notification.isRead
                  ? Colors.grey[200]!
                  : Colors.purple.withOpacity(0.2),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Coloured icon badge
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getNotificationColor(notification.type)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    color: _getNotificationColor(notification.type),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: notification.isRead
                                    ? FontWeight.w600
                                    : FontWeight.bold,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.purple,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification.body,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Status pill for order notifications
                      if (_isOrderType(notification.type))
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _getNotificationColor(notification.type)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getStatusLabel(notification.type),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color:
                              _getNotificationColor(notification.type),
                            ),
                          ),
                        ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            _getTimeAgo(notification.timestamp),
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'No Notifications',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // ─── helpers ───────────────────────────────────────────────────

  bool _isOrderType(NotificationType type) {
    const orderTypes = {
      NotificationType.orderPlaced,
      NotificationType.orderConfirmed,
      NotificationType.orderPacked,
      NotificationType.orderShipped,
      NotificationType.orderOutForDelivery,
      NotificationType.orderDelivered,
      NotificationType.orderCancelled,
    };
    return orderTypes.contains(type);
  }

  String _getStatusLabel(NotificationType type) {
    switch (type) {
      case NotificationType.orderPlaced:
        return 'Order Placed';
      case NotificationType.orderConfirmed:
        return 'Confirmed';
      case NotificationType.orderPacked:
        return 'Packed';
      case NotificationType.orderShipped:
        return 'Shipped';
      case NotificationType.orderOutForDelivery:
        return 'Out for Delivery';
      case NotificationType.orderDelivered:
        return 'Delivered';
      case NotificationType.orderCancelled:
        return 'Cancelled';
      default:
        return '';
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.orderPlaced:
        return Icons.shopping_bag_outlined;
      case NotificationType.orderConfirmed:
        return Icons.thumb_up_alt_outlined;
      case NotificationType.orderPacked:
        return Icons.inventory_2_outlined;
      case NotificationType.orderShipped:
        return Icons.local_shipping_outlined;
      case NotificationType.orderOutForDelivery:
        return Icons.directions_bike_outlined;
      case NotificationType.orderDelivered:
        return Icons.check_circle_outline;
      case NotificationType.orderCancelled:
        return Icons.cancel_outlined;
      case NotificationType.paymentSuccess:
        return Icons.account_balance_wallet_outlined;
      case NotificationType.paymentFailed:
        return Icons.error_outline;
      case NotificationType.priceDropAlert:
        return Icons.trending_down;
      case NotificationType.backInStock:
        return Icons.inventory_2_outlined;
      case NotificationType.newOffer:
        return Icons.local_offer_outlined;
      case NotificationType.cashback:
        return Icons.card_giftcard;
      case NotificationType.generalUpdate:
        return Icons.notifications_outlined;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.orderPlaced:
        return Colors.blue;
      case NotificationType.orderConfirmed:
        return Colors.indigo;
      case NotificationType.orderPacked:
        return Colors.cyan[700]!;
      case NotificationType.orderShipped:
        return Colors.purple;
      case NotificationType.orderOutForDelivery:
        return Colors.orange;
      case NotificationType.orderDelivered:
        return Colors.green;
      case NotificationType.orderCancelled:
        return Colors.red;
      case NotificationType.paymentSuccess:
      case NotificationType.cashback:
        return Colors.green;
      case NotificationType.paymentFailed:
        return Colors.red;
      case NotificationType.priceDropAlert:
      case NotificationType.newOffer:
        return Colors.orange;
      case NotificationType.backInStock:
        return Colors.teal;
      case NotificationType.generalUpdate:
        return Colors.grey;
    }
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return DateFormat('dd MMM').format(timestamp);
  }

  void _handleNotificationTap(
      BuildContext context, NotificationModel notification) {
    if (notification.data == null) return;
    final route = notification.data!['route'];
    if (route == null) return;

    switch (route) {
      case '/orderDetail':
        final orderId = notification.data!['orderId'];
        if (orderId != null) {
          Navigator.pushNamed(context, route, arguments: orderId);
        }
        break;
      case '/orderTracking':
        final orderId = notification.data!['orderId'];
        if (orderId != null) {
          Navigator.pushNamed(context, route, arguments: orderId);
        }
        break;
      case '/productDetail':
        final productId = notification.data!['productId'];
        if (productId != null) {
          Navigator.pushNamed(context, route, arguments: productId);
        }
        break;
      default:
        Navigator.pushNamed(context, route);
    }
  }

  void _showClearAllDialog(
      BuildContext context, NotificationProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text(
          'Are you sure you want to clear all notifications? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.clearAllNotifications();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All notifications cleared'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}