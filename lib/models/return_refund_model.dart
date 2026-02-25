enum ReturnStatus {
  pending,
  approved,
  rejected,
  pickedUp,
  refundInitiated,
  refundCompleted,
  cancelled
}

enum RefundMethod {
  wallet,
  originalPayment,
  bankTransfer
}

enum ReturnReason {
  defectiveProduct,
  wrongItem,
  sizeMismatch,
  colorMismatch,
  qualityIssue,
  damagedProduct,
  notAsDescribed,
  changedMind,
  other
}

class ReturnRequest {
  final String id;
  final String orderId;
  final String orderItemId;
  final String userId;
  final String productId;
  final String productName;
  final String productImage;
  final double price;
  final int quantity;
  final ReturnReason reason;
  final String? additionalComments;
  final List<String> images; // User uploaded images
  final ReturnStatus status;
  final RefundMethod refundMethod;
  final double refundAmount;
  final DateTime requestedAt;
  final DateTime? approvedAt;
  final DateTime? pickedUpAt;
  final DateTime? refundedAt;
  final String? rejectionReason;
  final String? trackingId;

  ReturnRequest({
    required this.id,
    required this.orderId,
    required this.orderItemId,
    required this.userId,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.price,
    required this.quantity,
    required this.reason,
    this.additionalComments,
    this.images = const [],
    required this.status,
    required this.refundMethod,
    required this.refundAmount,
    required this.requestedAt,
    this.approvedAt,
    this.pickedUpAt,
    this.refundedAt,
    this.rejectionReason,
    this.trackingId,
  });

  String get statusText {
    switch (status) {
      case ReturnStatus.pending:
        return 'Return Pending';
      case ReturnStatus.approved:
        return 'Return Approved';
      case ReturnStatus.rejected:
        return 'Return Rejected';
      case ReturnStatus.pickedUp:
        return 'Product Picked Up';
      case ReturnStatus.refundInitiated:
        return 'Refund Initiated';
      case ReturnStatus.refundCompleted:
        return 'Refund Completed';
      case ReturnStatus.cancelled:
        return 'Return Cancelled';
    }
  }

  String get reasonText {
    switch (reason) {
      case ReturnReason.defectiveProduct:
        return 'Defective Product';
      case ReturnReason.wrongItem:
        return 'Wrong Item Delivered';
      case ReturnReason.sizeMismatch:
        return 'Size Issue';
      case ReturnReason.colorMismatch:
        return 'Color Mismatch';
      case ReturnReason.qualityIssue:
        return 'Quality Issue';
      case ReturnReason.damagedProduct:
        return 'Damaged Product';
      case ReturnReason.notAsDescribed:
        return 'Not As Described';
      case ReturnReason.changedMind:
        return 'Changed Mind';
      case ReturnReason.other:
        return 'Other';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'orderItemId': orderItemId,
      'userId': userId,
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'price': price,
      'quantity': quantity,
      'reason': reason.toString(),
      'additionalComments': additionalComments,
      'images': images,
      'status': status.toString(),
      'refundMethod': refundMethod.toString(),
      'refundAmount': refundAmount,
      'requestedAt': requestedAt.toIso8601String(),
      'approvedAt': approvedAt?.toIso8601String(),
      'pickedUpAt': pickedUpAt?.toIso8601String(),
      'refundedAt': refundedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
      'trackingId': trackingId,
    };
  }

  factory ReturnRequest.fromJson(Map<String, dynamic> json) {
    return ReturnRequest(
      id: json['id'],
      orderId: json['orderId'],
      orderItemId: json['orderItemId'],
      userId: json['userId'],
      productId: json['productId'],
      productName: json['productName'],
      productImage: json['productImage'],
      price: json['price'],
      quantity: json['quantity'],
      reason: ReturnReason.values.firstWhere(
            (e) => e.toString() == json['reason'],
      ),
      additionalComments: json['additionalComments'],
      images: List<String>.from(json['images'] ?? []),
      status: ReturnStatus.values.firstWhere(
            (e) => e.toString() == json['status'],
      ),
      refundMethod: RefundMethod.values.firstWhere(
            (e) => e.toString() == json['refundMethod'],
      ),
      refundAmount: json['refundAmount'],
      requestedAt: DateTime.parse(json['requestedAt']),
      approvedAt: json['approvedAt'] != null
          ? DateTime.parse(json['approvedAt'])
          : null,
      pickedUpAt: json['pickedUpAt'] != null
          ? DateTime.parse(json['pickedUpAt'])
          : null,
      refundedAt: json['refundedAt'] != null
          ? DateTime.parse(json['refundedAt'])
          : null,
      rejectionReason: json['rejectionReason'],
      trackingId: json['trackingId'],
    );
  }

  ReturnRequest copyWith({
    String? id,
    String? orderId,
    String? orderItemId,
    String? userId,
    String? productId,
    String? productName,
    String? productImage,
    double? price,
    int? quantity,
    ReturnReason? reason,
    String? additionalComments,
    List<String>? images,
    ReturnStatus? status,
    RefundMethod? refundMethod,
    double? refundAmount,
    DateTime? requestedAt,
    DateTime? approvedAt,
    DateTime? pickedUpAt,
    DateTime? refundedAt,
    String? rejectionReason,
    String? trackingId,
  }) {
    return ReturnRequest(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      orderItemId: orderItemId ?? this.orderItemId,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      reason: reason ?? this.reason,
      additionalComments: additionalComments ?? this.additionalComments,
      images: images ?? this.images,
      status: status ?? this.status,
      refundMethod: refundMethod ?? this.refundMethod,
      refundAmount: refundAmount ?? this.refundAmount,
      requestedAt: requestedAt ?? this.requestedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
      refundedAt: refundedAt ?? this.refundedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      trackingId: trackingId ?? this.trackingId,
    );
  }
}