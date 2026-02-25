// Order Status Enum
enum OrderStatus {
  pending,
  confirmed,
  shipped,
  delivered,
  cancelled,
  returned,
}

// Order Item Model
class OrderItem {
  final String productId;
  final String productName;
  final String productImage;
  final int quantity;
  final double price;
  final String? size;
  final String? color;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.quantity,
    required this.price,
    this.size,
    this.color,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['product_id'] ?? '',
      productName: json['product_name'] ?? '',
      productImage: json['product_image'] ?? '',
      quantity: json['quantity'] ?? 1,
      price: (json['price'] ?? 0).toDouble(),
      size: json['size'],
      color: json['color'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'product_image': productImage,
      'quantity': quantity,
      'price': price,
      if (size != null) 'size': size,
      if (color != null) 'color': color,
    };
  }

  double get totalPrice => price * quantity;
}

// Address Model (simplified for compatibility)
class Address {
  final String id;
  final String userId;
  final String fullName;
  final String phoneNumber;
  final String label;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String pincode;
  final String? landmark;
  final bool isDefault;

  Address({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.phoneNumber,
    required this.label,
    required this.addressLine1,
    this.addressLine2 = '',
    required this.city,
    required this.state,
    required this.pincode,
    this.landmark,
    this.isDefault = false,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? json['userId'] ?? '',
      fullName: json['full_name'] ?? json['fullName'] ?? '',
      phoneNumber: json['phone_number'] ?? json['phoneNumber'] ?? '',
      label: json['label'] ?? 'Home',
      addressLine1: json['address_line1'] ?? json['addressLine1'] ?? '',
      addressLine2: json['address_line2'] ?? json['addressLine2'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      landmark: json['landmark'],
      isDefault: json['is_default'] ?? json['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'label': label,
      'address_line1': addressLine1,
      'address_line2': addressLine2,
      'city': city,
      'state': state,
      'pincode': pincode,
      'landmark': landmark,
      'is_default': isDefault,
    };
  }

  String get fullAddress {
    final parts = <String>[
      addressLine1,
      if (addressLine2.trim().isNotEmpty) addressLine2.trim(),
      city,
      '$state - $pincode',
    ];
    return parts.join(', ');
  }
}

// Order Detail Model
class OrderDetail {
  final String orderId;
  final String userId;
  final List<OrderItem> items;
  final double totalAmount;
  final OrderStatus status;
  final Address deliveryAddress;
  final DateTime orderDate;
  final DateTime? deliveryDate;
  final DateTime? estimatedDelivery;
  final String? trackingId;
  final String? courierName;
  final String paymentMethod;
  final double? rating;
  final String? review;

  OrderDetail({
    required this.orderId,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.deliveryAddress,
    required this.orderDate,
    this.deliveryDate,
    this.estimatedDelivery,
    this.trackingId,
    this.courierName,
    this.paymentMethod = 'UPI',
    this.rating,
    this.review,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    return OrderDetail(
      orderId: json['order_id'] ?? json['id'] ?? '',
      userId: json['user_id'] ?? '',
      items: (json['items'] as List? ?? [])
          .map((item) => OrderItem.fromJson(item))
          .toList(),
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      status: _parseOrderStatus(json['status']),
      deliveryAddress: Address.fromJson(json['delivery_address'] ?? {}),
      orderDate: json['order_date'] != null
          ? DateTime.parse(json['order_date'])
          : DateTime.now(),
      deliveryDate: json['delivery_date'] != null
          ? DateTime.parse(json['delivery_date'])
          : null,
      estimatedDelivery: json['estimated_delivery'] != null
          ? DateTime.parse(json['estimated_delivery'])
          : null,
      trackingId: json['tracking_id'],
      courierName: json['courier_name'],
      paymentMethod: json['payment_method'] ?? 'UPI',
      rating: (json['rating'] as num?)?.toDouble(),
      review: json['review'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'user_id': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'total_amount': totalAmount,
      'status': _orderStatusToString(status),
      'delivery_address': deliveryAddress.toJson(),
      'order_date': orderDate.toIso8601String(),
      'delivery_date': deliveryDate?.toIso8601String(),
      'estimated_delivery': estimatedDelivery?.toIso8601String(),
      'tracking_id': trackingId,
      'courier_name': courierName,
      'payment_method': paymentMethod,
      'rating': rating,
      'review': review,
    };
  }

  // Helper method to parse OrderStatus from string
  static OrderStatus _parseOrderStatus(dynamic status) {
    if (status == null) return OrderStatus.pending;

    final statusStr = status.toString().toLowerCase();
    switch (statusStr) {
      case 'pending':
        return OrderStatus.pending;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'shipped':
        return OrderStatus.shipped;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'returned':
        return OrderStatus.returned;
      default:
        return OrderStatus.pending;
    }
  }

  // Helper method to convert OrderStatus to string
  static String _orderStatusToString(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.confirmed:
        return 'confirmed';
      case OrderStatus.shipped:
        return 'shipped';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.cancelled:
        return 'cancelled';
      case OrderStatus.returned:
        return 'returned';
    }
  }

  // Helper getters
  int get totalItems {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  bool get isDelivered => status == OrderStatus.delivered;
  bool get isCancelled => status == OrderStatus.cancelled;
  bool get isShipped => status == OrderStatus.shipped;
  bool get isPending => status == OrderStatus.pending;
}