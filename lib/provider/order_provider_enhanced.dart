import 'package:flutter/foundation.dart';
import '../models/order_model_enhanced.dart';

/// Unified OrderProvider that supports:
/// 1. OrderDetail/Order objects from order_model_enhanced.dart
/// 2. Map-based orders (for voice commands)
/// 3. All existing functionality
/// 4. Voice checkout compatibility
class OrderProvider with ChangeNotifier {
  List<OrderDetail> _orders = [];
  bool _isLoading = false;
  String? _error;

  // ==================== GETTERS ====================

  List<OrderDetail> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get orderCount => _orders.length;
  List<OrderDetail> get recentOrders => _orders.take(10).toList();

  // Get current orders (not delivered, not cancelled, not returned)
  List<OrderDetail> get currentOrders {
    return _orders.where((order) {
      return order.status != OrderStatus.delivered &&
          order.status != OrderStatus.cancelled &&
          order.status != OrderStatus.returned;
    }).toList();
  }

  // Get past orders (delivered, cancelled, returned)
  List<OrderDetail> get pastOrders {
    return _orders.where((order) {
      return order.status == OrderStatus.delivered ||
          order.status == OrderStatus.cancelled ||
          order.status == OrderStatus.returned;
    }).toList();
  }

  // ==================== ORDER RETRIEVAL ====================

  /// Get order by ID - supports both orderId formats
  OrderDetail? getOrderById(String orderId) {
    try {
      return _orders.firstWhere((order) => order.orderId == orderId);
    } catch (e) {
      debugPrint('Order not found: $orderId');
      return null;
    }
  }

  List<OrderDetail> getOrdersByStatus(OrderStatus status) {
    return _orders.where((order) => order.status == status).toList();
  }

  List<OrderDetail> getOrdersByPaymentMethod(PaymentMethod paymentMethod) {
    return _orders
        .where((order) => order.paymentMethod == paymentMethod)
        .toList();
  }

  List<OrderDetail> getOrdersByDateRange(DateTime start, DateTime end) {
    return _orders.where((order) {
      return order.orderDate.isAfter(start) && order.orderDate.isBefore(end);
    }).toList();
  }

  // ==================== FETCH ORDERS ====================

  Future<void> fetchOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));
      _orders = _generateMockOrders();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== ADD ORDER (VOICE COMPATIBLE) ====================

  /// Add order - accepts both Order objects and Map data (for voice)
  /// This is CRITICAL for voice "Checkout with wallet" command
  void addOrder(dynamic orderData) {
    if (orderData == null) {
      debugPrint('❌ Error: Cannot add null order');
      return;
    }

    OrderDetail order;

    // Handle Order/OrderDetail objects
    if (orderData is OrderDetail || orderData is Order) {
      order = orderData as OrderDetail;
    }
    // Handle Map inputs (from voice commands)
    else if (orderData is Map<String, dynamic>) {
      order = _convertMapToOrder(orderData);
    } else {
      debugPrint('❌ Error: Invalid order data type: ${orderData.runtimeType}');
      return;
    }

    _orders.insert(0, order); // Add to beginning (newest first)
    debugPrint('✅ Order added: ${order.orderId}');
    notifyListeners();
  }

  /// Convert Map to Order (for voice commands)
  /// ✅ FIXED: Now handles CartItem objects and is more robust
  OrderDetail _convertMapToOrder(Map<String, dynamic> map) {
    final orderId = map['id'] as String? ??
        'ORD${DateTime.now().millisecondsSinceEpoch}';

    // Convert items from Map to OrderItem
    final items = (map['items'] as List?)?.map((item) {
      // Already an OrderItem
      if (item is OrderItem) return item;

      // Handle Map
      if (item is Map<String, dynamic>) {
        return OrderItem(
          productId: item['id']?.toString() ??
              item['productId']?.toString() ??
              'PROD${DateTime.now().millisecondsSinceEpoch}',
          productName: item['name']?.toString() ??
              item['productName']?.toString() ??
              'Voice Product',
          productImage: item['image']?.toString() ??
              item['imageUrl']?.toString() ??
              item['productImage']?.toString() ??
              'https://via.placeholder.com/150',
          price: (item['price'] as num?)?.toDouble() ?? 0.0,
          quantity: (item['quantity'] as int?) ?? 1,
          size: item['size']?.toString(),
          color: item['color']?.toString(),
        );
      }

      // ✅ NEW: Handle objects with toJson() method (like CartItem)
      try {
        final itemMap = (item as dynamic).toJson() as Map<String, dynamic>;
        return OrderItem(
          productId: itemMap['id']?.toString() ??
              itemMap['productId']?.toString() ??
              'PROD${DateTime.now().millisecondsSinceEpoch}',
          productName: itemMap['name']?.toString() ??
              itemMap['productName']?.toString() ??
              'Voice Product',
          productImage: itemMap['image']?.toString() ??
              itemMap['imageUrl']?.toString() ??
              itemMap['productImage']?.toString() ??
              'https://via.placeholder.com/150',
          price: (itemMap['price'] as num?)?.toDouble() ?? 0.0,
          quantity: (itemMap['quantity'] as int?) ?? 1,
          size: itemMap['size']?.toString(),
          color: itemMap['color']?.toString(),
        );
      } catch (e) {
        debugPrint('⚠️ Failed to convert item: $e, type: ${item.runtimeType}');
        debugPrint('   Item data: $item');
        // ✅ Return a fallback OrderItem instead of throwing
        return OrderItem(
          productId: 'PROD${DateTime.now().millisecondsSinceEpoch}',
          productName: 'Unknown Product',
          productImage: 'https://via.placeholder.com/150',
          price: 0.0,
          quantity: 1,
        );
      }
    }).toList() ?? [];

    // Create a default address if not provided
    final deliveryAddress = _createDefaultAddress(map);

    // Parse payment method
    final paymentMethod = _parsePaymentMethod(
        map['paymentMethod']?.toString() ?? 'Unknown'
    );

    return Order(
      orderId: orderId,
      userId: 'USER123', // Default user
      items: items,
      deliveryAddress: deliveryAddress,
      subtotal: (map['total'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (map['deliveryCharge'] as num?)?.toDouble() ?? 0.0,
      discount: 0.0,
      totalAmount: (map['finalAmount'] as num?)?.toDouble() ??
          (map['total'] as num?)?.toDouble() ??
          0.0,
      orderDate: map['timestamp'] is DateTime
          ? map['timestamp'] as DateTime
          : (map['timestamp'] != null
          ? DateTime.parse(map['timestamp'] as String)
          : DateTime.now()),
      status: _parseOrderStatus(map['status']?.toString() ?? 'placed'),
      paymentMethod: paymentMethod,
      trackingId: map['trackingNumber']?.toString() ??
          'TRK${DateTime.now().millisecondsSinceEpoch}',
      courierName: 'Standard Delivery',
    );
  }

  Address _createDefaultAddress(Map<String, dynamic> map) {
    if (map['deliveryAddress'] is Address) {
      return map['deliveryAddress'] as Address;
    }

    return Address(
      id: 'ADDR001',
      name: map['customerName']?.toString() ?? 'Customer',
      phone: map['customerPhone']?.toString() ?? '+91 0000000000',
      addressLine1: map['deliveryAddress']?.toString() ?? 'Default Address',
      addressLine2: '',
      city: 'City',
      state: 'State',
      pincode: '000000',
      isDefault: true,
    );
  }

  PaymentMethod _parsePaymentMethod(String method) {
    method = method.toLowerCase();
    if (method.contains('wallet')) return PaymentMethod.wallet;
    if (method.contains('upi')) return PaymentMethod.upi;
    if (method.contains('card')) return PaymentMethod.card;
    if (method.contains('cod') || method.contains('cash')) {
      return PaymentMethod.cod;
    }
    return PaymentMethod.cod; // Default
  }

  OrderStatus _parseOrderStatus(String status) {
    status = status.toLowerCase();
    if (status.contains('pending')) return OrderStatus.pending;
    if (status.contains('confirmed')) return OrderStatus.confirmed;
    if (status.contains('shipped')) return OrderStatus.shipped;
    if (status.contains('delivered')) return OrderStatus.delivered;
    if (status.contains('cancelled')) return OrderStatus.cancelled;
    if (status.contains('returned')) return OrderStatus.returned;
    return OrderStatus.pending; // Default
  }

  // ==================== PLACE ORDER ====================

  Future<String> placeOrder({
    required List<OrderItem> items,
    required Address deliveryAddress,
    required double subtotal,
    required double deliveryFee,
    required double discount,
    required double totalAmount,
    required PaymentMethod paymentMethod,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await Future.delayed(const Duration(seconds: 1));

      final orderId = 'ORD${DateTime.now().millisecondsSinceEpoch}';

      final newOrder = Order(
        orderId: orderId,
        userId: 'USER123',
        items: items,
        deliveryAddress: deliveryAddress,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        discount: discount,
        totalAmount: totalAmount,
        orderDate: DateTime.now(),
        status: OrderStatus.pending,
        paymentMethod: paymentMethod,
        trackingId: 'TRK${DateTime.now().millisecondsSinceEpoch}',
      );

      _orders.insert(0, newOrder);
      _isLoading = false;
      notifyListeners();

      return orderId;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // ==================== CREATE ORDER (ALTERNATIVE) ====================

  void createOrder({
    required List<Map<String, dynamic>> items,
    required double total,
    required String paymentMethod,
    String? deliveryAddress,
    String? customerName,
    String? customerPhone,
    double? deliveryCharge,
  }) {
    addOrder({
      'id': 'ORD${DateTime.now().millisecondsSinceEpoch}',
      'items': items,
      'total': total,
      'paymentMethod': paymentMethod,
      'status': 'placed',
      'timestamp': DateTime.now(),
      'deliveryAddress': deliveryAddress,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'deliveryCharge': deliveryCharge,
      'finalAmount': deliveryCharge != null ? total + deliveryCharge : total,
    });
  }

  // ==================== ORDER ACTIONS ====================

  Future<void> rateOrder({
    required String orderId,
    required double rating,
    required String review,
  }) async {
    try {
      final orderIndex = _orders.indexWhere((o) => o.orderId == orderId);
      if (orderIndex == -1) {
        throw Exception('Order not found');
      }

      if (_orders[orderIndex].status != OrderStatus.delivered) {
        throw Exception('Can only rate delivered orders');
      }

      if (_orders[orderIndex].rating != null) {
        throw Exception('Order already rated');
      }

      await Future.delayed(const Duration(milliseconds: 500));

      _orders[orderIndex] = _orders[orderIndex].copyWith(
        rating: rating,
        review: review.isEmpty ? null : review,
        ratedAt: DateTime.now(),
      );

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> cancelOrder(String orderId) async {
    try {
      final orderIndex = _orders.indexWhere((o) => o.orderId == orderId);
      if (orderIndex == -1) {
        throw Exception('Order not found');
      }

      if (!_orders[orderIndex].canCancel) {
        throw Exception('This order cannot be cancelled');
      }

      await Future.delayed(const Duration(milliseconds: 500));

      _orders[orderIndex] = _orders[orderIndex].copyWith(
        status: OrderStatus.cancelled,
      );

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  void updateOrderStatus(String orderId, dynamic newStatus) {
    final orderIndex = _orders.indexWhere((o) => o.orderId == orderId);
    if (orderIndex != -1) {
      OrderStatus status;

      if (newStatus is OrderStatus) {
        status = newStatus;
      } else if (newStatus is String) {
        status = _parseOrderStatus(newStatus);
      } else {
        debugPrint('Invalid status type');
        return;
      }

      _orders[orderIndex] = _orders[orderIndex].copyWith(
        status: status,
        deliveryDate: status == OrderStatus.delivered
            ? DateTime.now()
            : _orders[orderIndex].deliveryDate,
      );

      debugPrint('✅ Order $orderId status updated to: $status');
      notifyListeners();
    }
  }

  void completeOrder(String orderId) {
    updateOrderStatus(orderId, OrderStatus.delivered);
  }

  void shipOrder(String orderId) {
    updateOrderStatus(orderId, OrderStatus.shipped);
  }

  void processOrder(String orderId) {
    updateOrderStatus(orderId, OrderStatus.confirmed);
  }

  // ==================== ORDER MODIFICATION ====================

  void updateTrackingNumber(String orderId, String trackingNumber) {
    final orderIndex = _orders.indexWhere((o) => o.orderId == orderId);
    if (orderIndex >= 0) {
      _orders[orderIndex] = _orders[orderIndex].copyWith(
        trackingId: trackingNumber,
      );
      notifyListeners();
    }
  }

  void updateDeliveryAddress(String orderId, Address address) {
    final orderIndex = _orders.indexWhere((o) => o.orderId == orderId);
    if (orderIndex >= 0) {
      _orders[orderIndex] = _orders[orderIndex].copyWith(
        deliveryAddress: address,
      );
      notifyListeners();
    }
  }

  // ==================== ORDER DELETION ====================

  void removeOrder(String orderId) {
    final initialLength = _orders.length;
    _orders.removeWhere((order) => order.orderId == orderId);

    if (_orders.length < initialLength) {
      debugPrint('✅ Order removed: $orderId');
      notifyListeners();
    }
  }

  void clearOrders() {
    _orders = [];
    debugPrint('All orders cleared');
    notifyListeners();
  }

  void clearCompletedOrders() {
    _orders.removeWhere((order) => order.status == OrderStatus.delivered);
    debugPrint('Completed orders cleared');
    notifyListeners();
  }

  // ==================== STATISTICS ====================

  double getTotalRevenue() {
    return _orders.fold(0.0, (sum, order) => sum + order.totalAmount);
  }

  int getTotalItemsOrdered() {
    return _orders.fold(0, (sum, order) {
      return sum + order.items.fold(0, (itemSum, item) {
        return itemSum + item.quantity;
      });
    });
  }

  Map<String, int> getOrderStatusCounts() {
    final counts = <String, int>{};
    for (var order in _orders) {
      final statusStr = order.status.toString().split('.').last;
      counts[statusStr] = (counts[statusStr] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, double> getRevenueByPaymentMethod() {
    final revenue = <String, double>{};
    for (var order in _orders) {
      final methodStr = order.paymentMethod.toString().split('.').last;
      revenue[methodStr] = (revenue[methodStr] ?? 0.0) + order.totalAmount;
    }
    return revenue;
  }

  Map<String, dynamic> getMonthlyStats() {
    final now = DateTime.now();
    final thisMonthOrders = _orders.where((order) {
      return order.orderDate.year == now.year &&
          order.orderDate.month == now.month;
    }).toList();

    final revenue = thisMonthOrders.fold(
      0.0,
          (sum, order) => sum + order.totalAmount,
    );

    return {
      'orderCount': thisMonthOrders.length,
      'revenue': revenue,
      'averageOrderValue':
      thisMonthOrders.isEmpty ? 0.0 : revenue / thisMonthOrders.length,
    };
  }

  // ==================== HELPER METHODS ====================

  bool isOrderPending(String orderId) {
    final order = getOrderById(orderId);
    return order?.status == OrderStatus.pending ||
        order?.status == OrderStatus.confirmed;
  }

  bool canCancelOrder(String orderId) {
    final order = getOrderById(orderId);
    return order?.canCancel ?? false;
  }

  // ==================== CONVERSION HELPERS ====================

  List<Map<String, dynamic>> getOrdersAsMapList() {
    return _orders.map((order) => order.toJson()).toList();
  }

  Map<String, dynamic> getOrdersSummary() {
    return {
      'totalOrders': _orders.length,
      'totalRevenue': getTotalRevenue(),
      'statusCounts': getOrderStatusCounts(),
      'currentOrders': currentOrders.length,
      'pastOrders': pastOrders.length,
      'recentOrders': _orders.take(5).map((order) => order.toJson()).toList(),
    };
  }

  // ==================== SEARCH & FILTER ====================

  List<OrderDetail> searchOrders(String query) {
    query = query.toLowerCase();
    return _orders.where((order) {
      return order.orderId.toLowerCase().contains(query) ||
          order.status.toString().toLowerCase().contains(query) ||
          order.items.any((item) =>
              item.productName.toLowerCase().contains(query));
    }).toList();
  }

  // ==================== DEBUG ====================

  void printOrders() {
    debugPrint('========== ORDERS ==========');
    debugPrint('Total Orders: ${_orders.length}');
    debugPrint('Current Orders: ${currentOrders.length}');
    debugPrint('Past Orders: ${pastOrders.length}');
    debugPrint('Total Revenue: ₹${getTotalRevenue()}');
    debugPrint('Status Counts: ${getOrderStatusCounts()}');
    debugPrint('');
    debugPrint('Recent Orders:');
    for (var i = 0; i < _orders.length && i < 5; i++) {
      final order = _orders[i];
      debugPrint(
        '  ${i + 1}. ${order.orderId} - ${order.status} - ₹${order.totalAmount}',
      );
    }
    debugPrint('============================');
  }

  void printOrderDetails(String orderId) {
    final order = getOrderById(orderId);
    if (order == null) {
      debugPrint('Order not found: $orderId');
      return;
    }

    debugPrint('========== ORDER DETAILS ==========');
    debugPrint('Order ID: ${order.orderId}');
    debugPrint('Status: ${order.status}');
    debugPrint('Total: ₹${order.totalAmount}');
    debugPrint('Payment: ${order.paymentMethod}');
    debugPrint('Date: ${order.orderDate}');
    debugPrint('Items: ${order.items.length}');
    debugPrint('Tracking: ${order.trackingId}');
    debugPrint('===================================');
  }

  // ==================== MOCK DATA ====================

  List<OrderDetail> _generateMockOrders() {
    final now = DateTime.now();

    return [
      Order(
        orderId: 'ORD202502110001',
        userId: 'USER123',
        items: [
          OrderItem(
            productId: 'PROD001',
            productName: 'Women\'s Floral Print Kurti',
            productImage: 'https://images.unsplash.com/photo-1583391733956-6c78276477e2?w=400',
            price: 599.0,
            quantity: 1,
            size: 'M',
            color: 'Blue',
          ),
        ],
        deliveryAddress: Address(
          id: 'ADDR001',
          name: 'Priya Sharma',
          phone: '+91 9876543210',
          addressLine1: '123, MG Road',
          addressLine2: 'Near City Mall',
          city: 'Bangalore',
          state: 'Karnataka',
          pincode: '560001',
          isDefault: true,
        ),
        subtotal: 599.0,
        deliveryFee: 50.0,
        discount: 0.0,
        totalAmount: 649.0,
        orderDate: now.subtract(const Duration(days: 2)),
        deliveryDate: now.add(const Duration(days: 2)),
        status: OrderStatus.shipped,
        paymentMethod: PaymentMethod.upi,
        trackingId: 'TRK2025021100123',
        courierName: 'BlueDart',
      ),
      Order(
        orderId: 'ORD202502090002',
        userId: 'USER123',
        items: [
          OrderItem(
            productId: 'PROD002',
            productName: 'Men\'s Casual Shirt - Cotton',
            productImage: 'https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?w=400',
            price: 799.0,
            quantity: 2,
            size: 'L',
            color: 'White',
          ),
        ],
        deliveryAddress: Address(
          id: 'ADDR001',
          name: 'Priya Sharma',
          phone: '+91 9876543210',
          addressLine1: '123, MG Road',
          addressLine2: 'Near City Mall',
          city: 'Bangalore',
          state: 'Karnataka',
          pincode: '560001',
        ),
        subtotal: 1598.0,
        deliveryFee: 0.0,
        discount: 0.0,
        totalAmount: 1598.0,
        orderDate: now.subtract(const Duration(days: 4)),
        status: OrderStatus.confirmed,
        paymentMethod: PaymentMethod.wallet,
        trackingId: 'TRK2025020900234',
      ),
      Order(
        orderId: 'ORD202502050003',
        userId: 'USER123',
        items: [
          OrderItem(
            productId: 'PROD003',
            productName: 'Women\'s Denim Jeans - Slim Fit',
            productImage: 'https://images.unsplash.com/photo-1541099649105-f69ad21f3246?w=400',
            price: 1299.0,
            quantity: 1,
            size: '30',
            color: 'Dark Blue',
          ),
        ],
        deliveryAddress: Address(
          id: 'ADDR001',
          name: 'Priya Sharma',
          phone: '+91 9876543210',
          addressLine1: '123, MG Road',
          addressLine2: 'Near City Mall',
          city: 'Bangalore',
          state: 'Karnataka',
          pincode: '560001',
        ),
        subtotal: 1299.0,
        deliveryFee: 0.0,
        discount: 0.0,
        totalAmount: 1299.0,
        orderDate: now.subtract(const Duration(days: 8)),
        deliveryDate: now.subtract(const Duration(days: 3)),
        status: OrderStatus.delivered,
        paymentMethod: PaymentMethod.upi,
        trackingId: 'TRK2025020500345',
        courierName: 'Delhivery',
      ),
    ];
  }
}