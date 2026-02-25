// ═══════════════════════════════════════════════════════════════════
// ORDER MODEL ENHANCED
// Complete order management models for the e-commerce app
// ═══════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────
//  ENUMS
// ─────────────────────────────────────────────

/// Order Status - All possible states an order can be in
enum OrderStatus {
  pending,        // Order placed, awaiting confirmation
  confirmed,      // Order confirmed by seller
  processing,     // Order being processed/packed
  shipped,        // Order shipped
  outForDelivery, // Out for delivery
  delivered,      // Successfully delivered
  cancelled,      // Cancelled by user or seller
  returned,       // Return initiated
  completed,      // Order completed (final state)
}

/// Payment Method - All supported payment methods
enum PaymentMethod {
  cod,        // Cash on Delivery
  upi,        // UPI Payment
  card,       // Credit/Debit Card
  netbanking, // Net Banking
  wallet,     // Wallet
}

// ─────────────────────────────────────────────
//  DELIVERY ADDRESS MODEL
// ─────────────────────────────────────────────

class DeliveryAddress {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String pincode;
  final String landmark;
  final bool isDefault;

  DeliveryAddress({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.state,
    required this.pincode,
    this.landmark = '',
    this.isDefault = false,
  });

  /// Returns formatted full address
  String get fullAddress {
    final parts = [
      addressLine1,
      if (addressLine2.isNotEmpty) addressLine2,
      if (landmark.isNotEmpty) landmark,
      city,
      state,
      pincode,
    ];
    return parts.where((part) => part.isNotEmpty).join(', ');
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'state': state,
      'pincode': pincode,
      'landmark': landmark,
      'isDefault': isDefault,
    };
  }

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) {
    return DeliveryAddress(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      addressLine1: json['addressLine1'] ?? '',
      addressLine2: json['addressLine2'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      landmark: json['landmark'] ?? '',
      isDefault: json['isDefault'] ?? false,
    );
  }

  DeliveryAddress copyWith({
    String? id,
    String? fullName,
    String? phoneNumber,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? pincode,
    String? landmark,
    bool? isDefault,
  }) {
    return DeliveryAddress(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
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

// ─────────────────────────────────────────────
//  ORDER ITEM MODEL
// ─────────────────────────────────────────────

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

  /// Calculate total price for this item
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
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      productImage: json['productImage'] ?? '',
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

// ─────────────────────────────────────────────
//  ORDER DETAIL MODEL (Main Order Model)
// ─────────────────────────────────────────────

class OrderDetail {
  final String id;
  final String orderId;
  final String userId;
  final List<OrderItem> items;
  final DeliveryAddress deliveryAddress;
  final double totalAmount;
  final double deliveryCharge;
  final OrderStatus status;
  final PaymentMethod paymentMethod;
  final DateTime orderDate;
  final DateTime? deliveryDate;
  final DateTime? estimatedDeliveryDate;
  final String? trackingId;
  final String? courierName;

  // Rating fields
  final double? rating;
  final String? review;
  final DateTime? ratedAt;
  final List<String>? reviewImages;

  OrderDetail({
    String? id,
    required this.orderId,
    required this.userId,
    required this.items,
    required this.deliveryAddress,
    required this.totalAmount,
    this.deliveryCharge = 0.0,
    required this.status,
    required this.paymentMethod,
    required this.orderDate,
    this.deliveryDate,
    this.estimatedDeliveryDate,
    this.trackingId,
    this.courierName,
    this.rating,
    this.review,
    this.ratedAt,
    this.reviewImages,
  }) : id = id ?? orderId;

  // ─────────────────────────────────────────────
  //  Helper Methods
  // ─────────────────────────────────────────────

  /// Check if order can be rated
  bool get canRate => status == OrderStatus.delivered && rating == null;

  /// Check if order has been rated
  bool get isRated => rating != null && rating! > 0;

  /// Check if order can be cancelled
  bool get canCancel =>
      status == OrderStatus.pending || status == OrderStatus.confirmed;

  /// Check if order can be returned (within 7 days of delivery)
  bool get canReturn =>
      status == OrderStatus.delivered &&
          deliveryDate != null &&
          DateTime.now().difference(deliveryDate!).inDays <= 7;

  /// Check if order can be tracked
  bool get canTrack =>
      status != OrderStatus.cancelled &&
          status != OrderStatus.returned &&
          status != OrderStatus.delivered;

  // ─────────────────────────────────────────────
  //  JSON Serialization
  // ─────────────────────────────────────────────

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'userId': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'deliveryAddress': deliveryAddress.toJson(),
      'totalAmount': totalAmount,
      'deliveryCharge': deliveryCharge,
      'status': status.toString().split('.').last,
      'paymentMethod': paymentMethod.toString().split('.').last,
      'orderDate': orderDate.toIso8601String(),
      'deliveryDate': deliveryDate?.toIso8601String(),
      'estimatedDeliveryDate': estimatedDeliveryDate?.toIso8601String(),
      'trackingId': trackingId,
      'courierName': courierName,
      'rating': rating,
      'review': review,
      'ratedAt': ratedAt?.toIso8601String(),
      'reviewImages': reviewImages,
    };
  }

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    return OrderDetail(
      id: json['id'],
      orderId: json['orderId'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      items: (json['items'] as List?)
          ?.map((item) => OrderItem.fromJson(item))
          .toList() ??
          [],
      deliveryAddress: DeliveryAddress.fromJson(
        json['deliveryAddress'] ?? {},
      ),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      deliveryCharge: (json['deliveryCharge'] ?? 0).toDouble(),
      status: _parseOrderStatus(json['status']),
      paymentMethod: _parsePaymentMethod(json['paymentMethod']),
      orderDate: json['orderDate'] != null
          ? DateTime.parse(json['orderDate'])
          : DateTime.now(),
      deliveryDate: json['deliveryDate'] != null
          ? DateTime.parse(json['deliveryDate'])
          : null,
      estimatedDeliveryDate: json['estimatedDeliveryDate'] != null
          ? DateTime.parse(json['estimatedDeliveryDate'])
          : null,
      trackingId: json['trackingId'],
      courierName: json['courierName'],
      rating: json['rating']?.toDouble(),
      review: json['review'],
      ratedAt: json['ratedAt'] != null ? DateTime.parse(json['ratedAt']) : null,
      reviewImages: json['reviewImages'] != null
          ? List<String>.from(json['reviewImages'])
          : null,
    );
  }

  static OrderStatus _parseOrderStatus(String? status) {
    if (status == null) return OrderStatus.pending;
    try {
      return OrderStatus.values.firstWhere(
            (e) => e.toString().split('.').last == status,
        orElse: () => OrderStatus.pending,
      );
    } catch (e) {
      return OrderStatus.pending;
    }
  }

  static PaymentMethod _parsePaymentMethod(String? method) {
    if (method == null) return PaymentMethod.cod;
    try {
      return PaymentMethod.values.firstWhere(
            (e) => e.toString().split('.').last == method,
        orElse: () => PaymentMethod.cod,
      );
    } catch (e) {
      return PaymentMethod.cod;
    }
  }

  OrderDetail copyWith({
    String? id,
    String? orderId,
    String? userId,
    List<OrderItem>? items,
    DeliveryAddress? deliveryAddress,
    double? totalAmount,
    double? deliveryCharge,
    OrderStatus? status,
    PaymentMethod? paymentMethod,
    DateTime? orderDate,
    DateTime? deliveryDate,
    DateTime? estimatedDeliveryDate,
    String? trackingId,
    String? courierName,
    double? rating,
    String? review,
    DateTime? ratedAt,
    List<String>? reviewImages,
  }) {
    return OrderDetail(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      totalAmount: totalAmount ?? this.totalAmount,
      deliveryCharge: deliveryCharge ?? this.deliveryCharge,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      orderDate: orderDate ?? this.orderDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      estimatedDeliveryDate:
      estimatedDeliveryDate ?? this.estimatedDeliveryDate,
      trackingId: trackingId ?? this.trackingId,
      courierName: courierName ?? this.courierName,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      ratedAt: ratedAt ?? this.ratedAt,
      reviewImages: reviewImages ?? this.reviewImages,
    );
  }
}

// ─────────────────────────────────────────────
//  EXTENSIONS
// ─────────────────────────────────────────────

/// Extension for OrderStatus to provide display-friendly text
extension OrderStatusExtension on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Order Placed';
      case OrderStatus.confirmed:
        return 'Order Confirmed';
      case OrderStatus.processing:
        return 'Processing';
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
      case OrderStatus.completed:
        return 'Completed';
    }
  }

  String get description {
    switch (this) {
      case OrderStatus.pending:
        return 'Your order has been placed successfully';
      case OrderStatus.confirmed:
        return 'Seller is preparing your order';
      case OrderStatus.processing:
        return 'Your order is being processed';
      case OrderStatus.shipped:
        return 'Your order is on the way';
      case OrderStatus.outForDelivery:
        return 'Your order will be delivered soon';
      case OrderStatus.delivered:
        return 'Your order has been delivered';
      case OrderStatus.cancelled:
        return 'Your order has been cancelled';
      case OrderStatus.returned:
        return 'Your order has been returned';
      case OrderStatus.completed:
        return 'Order completed successfully';
    }
  }
}

/// Extension for PaymentMethod to provide display-friendly text
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