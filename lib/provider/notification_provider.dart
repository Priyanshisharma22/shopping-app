import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';

enum NotificationType {
  orderPlaced,
  orderConfirmed,
  orderPacked,
  orderShipped,
  orderOutForDelivery,
  orderDelivered,
  orderCancelled,
  paymentSuccess,
  paymentFailed,
  priceDropAlert,
  backInStock,
  newOffer,
  cashback,
  generalUpdate,
}

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data;
  final String? imageUrl;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.data,
    this.imageUrl,
  });

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? data,
    String? imageUrl,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'type': type.toString(),
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead,
    'data': data,
    'imageUrl': imageUrl,
  };

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: json['id'],
        title: json['title'],
        body: json['body'],
        type: NotificationType.values.firstWhere(
              (e) => e.toString() == json['type'],
          orElse: () => NotificationType.generalUpdate,
        ),
        timestamp: DateTime.parse(json['timestamp']),
        isRead: json['isRead'] ?? false,
        data: json['data'],
        imageUrl: json['imageUrl'],
      );
}

class NotificationProvider extends ChangeNotifier {
  final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  final List<NotificationModel> _notifications = [];
  bool _isInitialized = false;

  List<NotificationModel> get notifications =>
      List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  List<NotificationModel> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _requestPermissions();

    _isInitialized = true;
    // ✅ FIX: Only call notifyListeners() if widget tree is ready
    // Using addPostFrameCallback avoids calling during build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  Future<void> _requestPermissions() async {
    // iOS permissions
    await _plugin
        .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    // Android 13+ permissions
    final granted = await _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    debugPrint('🔔 Notification permission granted: $granted');
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        debugPrint('🔔 Notification tapped — navigate to: ${data['route']}');
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────
  //  CORE SHOW METHOD
  // ─────────────────────────────────────────────────────────────────

  Future<void> showNotification({
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? data,
    String? imageUrl,
  }) async {
    // ✅ FIX: Always ensure initialized before showing
    if (!_isInitialized) {
      await initialize();
    }

    // ✅ FIX: Use a unique int ID — millisecondsSinceEpoch can overflow int32
    final notificationId =
    DateTime.now().millisecondsSinceEpoch.remainder(100000);

    final notification = NotificationModel(
      id: notificationId.toString(),
      title: title,
      body: body,
      type: type,
      timestamp: DateTime.now(),
      data: data,
      imageUrl: imageUrl,
    );

    _notifications.insert(0, notification);
    notifyListeners();

    try {
      await _plugin.show(
        notificationId,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'order_channel',       // channel id
            'Order Updates',       // channel name
            channelDescription: 'Order status updates',
            importance: Importance.max,   // ✅ max not just high
            priority: Priority.max,       // ✅ max not just high
            showWhen: true,
            enableVibration: true,
            playSound: true,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(data ?? {}),
      );
      debugPrint('✅ Notification shown: $title');
    } catch (e) {
      debugPrint('❌ Failed to show notification: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────
  //  ORDER FLOW  (5 steps)
  // ─────────────────────────────────────────────────────────────────

  Future<void> notifyOrderPlaced(String orderId, double amount) async {
    await showNotification(
      title: '🎉 Order Placed Successfully!',
      body:
      'Your order #$orderId of ₹${amount.toStringAsFixed(0)} has been placed.',
      type: NotificationType.orderPlaced,
      data: {'orderId': orderId, 'route': '/orderDetail'},
    );
  }

  Future<void> notifyOrderConfirmed(String orderId) async {
    await showNotification(
      title: '✅ Order Confirmed',
      body: 'Your order #$orderId has been confirmed by the seller.',
      type: NotificationType.orderConfirmed,
      data: {'orderId': orderId, 'route': '/orderDetail'},
    );
  }

  Future<void> notifyOrderPacked(String orderId) async {
    await showNotification(
      title: '📦 Order Packed',
      body:
      'Your order #$orderId is packed and ready for courier pickup.',
      type: NotificationType.orderPacked,
      data: {'orderId': orderId, 'route': '/orderTracking'},
    );
  }

  Future<void> notifyOrderOutForDelivery(String orderId) async {
    await showNotification(
      title: '🚚 Out for Delivery',
      body: 'Your order #$orderId is on its way to you!',
      type: NotificationType.orderOutForDelivery,
      data: {'orderId': orderId, 'route': '/orderTracking'},
    );
  }

  Future<void> notifyOrderDelivered(String orderId) async {
    await showNotification(
      title: '✨ Order Delivered!',
      body:
      'Your order #$orderId has been delivered. Enjoy your purchase! 🎊',
      type: NotificationType.orderDelivered,
      data: {'orderId': orderId, 'route': '/orderDetail'},
    );
  }

  /// Fires all 5 order steps automatically with delays — useful for demo/testing
  Future<void> triggerFullOrderFlow(String orderId, double amount) async {
    await notifyOrderPlaced(orderId, amount);
    await Future.delayed(const Duration(seconds: 5));
    await notifyOrderConfirmed(orderId);
    await Future.delayed(const Duration(seconds: 10));
    await notifyOrderPacked(orderId);
    await Future.delayed(const Duration(seconds: 10));
    await notifyOrderOutForDelivery(orderId);
    await Future.delayed(const Duration(seconds: 10));
    await notifyOrderDelivered(orderId);
  }

  // ─────────────────────────────────────────────────────────────────
  //  OTHER NOTIFICATIONS
  // ─────────────────────────────────────────────────────────────────

  Future<void> notifyOrderShipped(
      String orderId, String trackingId) async {
    await showNotification(
      title: '📦 Order Shipped',
      body: 'Order #$orderId shipped. Tracking: $trackingId',
      type: NotificationType.orderShipped,
      data: {
        'orderId': orderId,
        'trackingId': trackingId,
        'route': '/orderTracking'
      },
    );
  }

  Future<void> notifyOrderCancelled(
      String orderId, String reason) async {
    await showNotification(
      title: '❌ Order Cancelled',
      body: 'Order #$orderId cancelled. $reason',
      type: NotificationType.orderCancelled,
      data: {'orderId': orderId, 'route': '/orderDetail'},
    );
  }

  Future<void> notifyPaymentSuccess(
      String orderId, double amount) async {
    await showNotification(
      title: '💰 Payment Successful',
      body:
      'Payment of ₹${amount.toStringAsFixed(0)} received for order #$orderId',
      type: NotificationType.paymentSuccess,
      data: {'orderId': orderId, 'route': '/orderDetail'},
    );
  }

  Future<void> notifyPaymentFailed(String orderId, double amount) async {
    await showNotification(
      title: '⚠️ Payment Failed',
      body:
      'Payment of ₹${amount.toStringAsFixed(0)} failed for order #$orderId',
      type: NotificationType.paymentFailed,
      data: {'orderId': orderId, 'route': '/checkout'},
    );
  }

  Future<void> notifyPriceDrop(String productId, String productName,
      double oldPrice, double newPrice) async {
    final discount = ((oldPrice - newPrice) / oldPrice * 100).round();
    await showNotification(
      title: '🔥 Price Drop Alert!',
      body:
      '$productName is now ₹${newPrice.toStringAsFixed(0)} (${discount}% off)',
      type: NotificationType.priceDropAlert,
      data: {'productId': productId, 'route': '/productDetail'},
    );
  }

  Future<void> notifyBackInStock(
      String productId, String productName) async {
    await showNotification(
      title: '🎁 Back in Stock!',
      body: '$productName is available again. Grab it fast!',
      type: NotificationType.backInStock,
      data: {'productId': productId, 'route': '/productDetail'},
    );
  }

  Future<void> notifyNewOffer(String title, String description) async {
    await showNotification(
      title: '🎊 $title',
      body: description,
      type: NotificationType.newOffer,
      data: {'route': '/shopping'},
    );
  }

  Future<void> notifyCashback(double amount, String orderId) async {
    await showNotification(
      title: '💸 Cashback Credited!',
      body:
      '₹${amount.toStringAsFixed(0)} cashback added to wallet for order #$orderId',
      type: NotificationType.cashback,
      data: {'orderId': orderId, 'route': '/wallet'},
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  MANAGEMENT
  // ─────────────────────────────────────────────────────────────────

  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    notifyListeners();
  }

  void deleteNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
    notifyListeners();
  }

  void clearAllNotifications() {
    _notifications.clear();
    notifyListeners();
  }

  List<NotificationModel> getNotificationsByType(NotificationType type) =>
      _notifications.where((n) => n.type == type).toList();
}