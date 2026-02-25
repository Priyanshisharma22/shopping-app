// Order Status Enum - COMPLETE
enum OrderStatus {
  pending,
  confirmed,
  shipped,
  outForDelivery,  // Added
  delivered,
  cancelled,
  returned,
  refunded,  // Added
}

// Payment Method Enum
enum PaymentMethod {
  cod,
  upi,
  card,
  netbanking,
  wallet,
}

// Order Item Model
class OrderItem {
  final String productId;
  final String productName;
  final String productImage;
  final double price;
  final int quantity;
  final String? size;
  final String? color;
  final String? variant;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.price,
    required this.quantity,
    this.size,
    this.color,
    this.variant,
  });

  double get totalPrice => price * quantity;

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'price': price,
      'quantity': quantity,
      'size': size,
      'color': color,
      'variant': variant,
    };
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'] ?? json['product_id'] ?? '',
      productName: json['productName'] ?? json['product_name'] ?? '',
      productImage: json['productImage'] ?? json['product_image'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 1,
      size: json['size'],
      color: json['color'],
      variant: json['variant'],
    );
  }

  OrderItem copyWith({
    String? productId,
    String? productName,
    String? productImage,
    double? price,
    int? quantity,
    String? size,
    String? color,
    String? variant,
  }) {
    return OrderItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      size: size ?? this.size,
      color: color ?? this.color,
      variant: variant ?? this.variant,
    );
  }
}

// Address Model - FIXED property names
class Address {
  final String id;
  final String name;  // For compatibility with Order class
  final String phone;  // For compatibility with Order class
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String pincode;
  final String? landmark;
  final bool isDefault;

  // Compatibility getters
  String get fullName => name;
  String get phoneNumber => phone;

  Address({
    required this.id,
    required this.name,
    required this.phone,
    required this.addressLine1,
    this.addressLine2 = '',
    required this.city,
    required this.state,
    required this.pincode,
    this.landmark,
    this.isDefault = false,
  });

  String get fullAddress {
    final parts = <String>[
      addressLine1,
      if (addressLine2.trim().isNotEmpty) addressLine2.trim(),
      if (landmark != null && landmark!.trim().isNotEmpty) landmark!.trim(),
      city,
      '$state - $pincode',
    ];
    return parts.join(', ');
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'state': state,
      'pincode': pincode,
      'landmark': landmark,
      'isDefault': isDefault,
    };
  }

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] ?? '',
      name: json['name'] ?? json['fullName'] ?? '',
      phone: json['phone'] ?? json['phoneNumber'] ?? '',
      addressLine1: json['addressLine1'] ?? json['address_line1'] ?? '',
      addressLine2: json['addressLine2'] ?? json['address_line2'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      landmark: json['landmark'],
      isDefault: json['isDefault'] ?? json['is_default'] ?? false,
    );
  }

  Address copyWith({
    String? id,
    String? name,
    String? phone,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? pincode,
    String? landmark,
    bool? isDefault,
  }) {
    return Address(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      landmark: landmark ?? this.landmark,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

// Main Order Model - THIS IS THE CLASS YOUR PROVIDER USES
class Order {
  final String orderId;
  final String userId;
  final List<OrderItem> items;
  final Address deliveryAddress;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double totalAmount;
  final DateTime orderDate;
  final DateTime? deliveryDate;
  final OrderStatus status;
  final PaymentMethod paymentMethod;
  final String? trackingId;
  final String? courierName;

  // Rating fields
  final double? rating;
  final String? review;
  final DateTime? ratedAt;
  final List<String>? reviewImages;

  Order({
    required this.orderId,
    required this.userId,
    required this.items,
    required this.deliveryAddress,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.totalAmount,
    required this.orderDate,
    this.deliveryDate,
    required this.status,
    required this.paymentMethod,
    this.trackingId,
    this.courierName,
    this.rating,
    this.review,
    this.ratedAt,
    this.reviewImages,
  });

  // Helper methods
  bool get canRate => status == OrderStatus.delivered && rating == null;
  bool get isRated => rating != null && rating! > 0;
  bool get canCancel =>
      status == OrderStatus.pending || status == OrderStatus.confirmed;
  bool get canReturn =>
      status == OrderStatus.delivered &&
          deliveryDate != null &&
          DateTime.now().difference(deliveryDate!).inDays <= 7;

  int get totalItems {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'userId': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'deliveryAddress': deliveryAddress.toJson(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'discount': discount,
      'totalAmount': totalAmount,
      'orderDate': orderDate.toIso8601String(),
      'deliveryDate': deliveryDate?.toIso8601String(),
      'status': status.toString().split('.').last,
      'paymentMethod': paymentMethod.toString().split('.').last,
      'trackingId': trackingId,
      'courierName': courierName,
      'rating': rating,
      'review': review,
      'ratedAt': ratedAt?.toIso8601String(),
      'reviewImages': reviewImages,
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderId: json['orderId'] ?? json['order_id'] ?? '',
      userId: json['userId'] ?? json['user_id'] ?? '',
      items: (json['items'] as List?)
          ?.map((item) => OrderItem.fromJson(item))
          .toList() ??
          [],
      deliveryAddress: Address.fromJson(
        json['deliveryAddress'] ?? json['delivery_address'] ?? {},
      ),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      deliveryFee: (json['deliveryFee'] ?? json['delivery_fee'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? json['total_amount'] ?? 0).toDouble(),
      orderDate: json['orderDate'] != null
          ? DateTime.parse(json['orderDate'])
          : json['order_date'] != null
          ? DateTime.parse(json['order_date'])
          : DateTime.now(),
      deliveryDate: json['deliveryDate'] != null
          ? DateTime.parse(json['deliveryDate'])
          : json['delivery_date'] != null
          ? DateTime.parse(json['delivery_date'])
          : null,
      status: _parseOrderStatus(json['status']),
      paymentMethod: _parsePaymentMethod(json['paymentMethod'] ?? json['payment_method']),
      trackingId: json['trackingId'] ?? json['tracking_id'],
      courierName: json['courierName'] ?? json['courier_name'],
      rating: (json['rating'] as num?)?.toDouble(),
      review: json['review'],
      ratedAt: json['ratedAt'] != null
          ? DateTime.parse(json['ratedAt'])
          : json['rated_at'] != null
          ? DateTime.parse(json['rated_at'])
          : null,
      reviewImages: json['reviewImages'] != null
          ? List<String>.from(json['reviewImages'])
          : json['review_images'] != null
          ? List<String>.from(json['review_images'])
          : null,
    );
  }

  static OrderStatus _parseOrderStatus(dynamic status) {
    if (status == null) return OrderStatus.pending;

    if (status is OrderStatus) return status;

    final statusStr = status.toString().toLowerCase().replaceAll('_', '');
    try {
      return OrderStatus.values.firstWhere(
            (e) => e.toString().split('.').last.toLowerCase().replaceAll('_', '') == statusStr,
        orElse: () => OrderStatus.pending,
      );
    } catch (e) {
      return OrderStatus.pending;
    }
  }

  static PaymentMethod _parsePaymentMethod(dynamic method) {
    if (method == null) return PaymentMethod.cod;

    if (method is PaymentMethod) return method;

    final methodStr = method.toString().toLowerCase();
    try {
      return PaymentMethod.values.firstWhere(
            (e) => e.toString().split('.').last.toLowerCase() == methodStr,
        orElse: () => PaymentMethod.cod,
      );
    } catch (e) {
      return PaymentMethod.cod;
    }
  }

  Order copyWith({
    String? orderId,
    String? userId,
    List<OrderItem>? items,
    Address? deliveryAddress,
    double? subtotal,
    double? deliveryFee,
    double? discount,
    double? totalAmount,
    DateTime? orderDate,
    DateTime? deliveryDate,
    OrderStatus? status,
    PaymentMethod? paymentMethod,
    String? trackingId,
    String? courierName,
    double? rating,
    String? review,
    DateTime? ratedAt,
    List<String>? reviewImages,
  }) {
    return Order(
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      discount: discount ?? this.discount,
      totalAmount: totalAmount ?? this.totalAmount,
      orderDate: orderDate ?? this.orderDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      trackingId: trackingId ?? this.trackingId,
      courierName: courierName ?? this.courierName,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      ratedAt: ratedAt ?? this.ratedAt,
      reviewImages: reviewImages ?? this.reviewImages,
    );
  }
}

// Alias OrderDetail to Order for compatibility with past_orders_screen.dart
typedef OrderDetail = Order;

// Extension for status display
extension OrderStatusExtension on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Order Placed';
      case OrderStatus.confirmed:
        return 'Order Confirmed';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.returned:
        return 'Returned';
      case OrderStatus.refunded:
        return 'Refunded';
    }
  }

  String get description {
    switch (this) {
      case OrderStatus.pending:
        return 'Your order has been placed successfully';
      case OrderStatus.confirmed:
        return 'Seller is preparing your order';
      case OrderStatus.shipped:
        return 'Your order is on the way';
      case OrderStatus.outForDelivery:
        return 'Your order is out for delivery';
      case OrderStatus.delivered:
        return 'Your order has been delivered';
      case OrderStatus.cancelled:
        return 'Your order has been cancelled';
      case OrderStatus.returned:
        return 'Your order has been returned';
      case OrderStatus.refunded:
        return 'Your order has been refunded';
    }
  }
}

// Extension for payment method display
extension PaymentMethodExtension on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.cod:
        return 'Cash on Delivery';
      case PaymentMethod.upi:
        return 'UPI Payment';
      case PaymentMethod.card:
        return 'Card Payment';
      case PaymentMethod.netbanking:
        return 'Net Banking';
      case PaymentMethod.wallet:
        return 'Wallet';
    }
  }
}