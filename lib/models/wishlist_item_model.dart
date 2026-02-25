class WishlistItem {
  final String id;
  final String userId;
  final String productId;
  final String productName;
  final String productImage;
  final double price;
  final String? category;
  final DateTime addedAt;

  WishlistItem({
    required this.id,
    required this.userId,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.price,
    this.category,
    required this.addedAt,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      productId: json['product_id'] ?? '',
      productName: json['product_name'] ?? '',
      productImage: json['product_image'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      category: json['category'],
      addedAt: json['added_at'] != null
          ? DateTime.parse(json['added_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'product_id': productId,
      'product_name': productName,
      'product_image': productImage,
      'price': price,
      'category': category,
      'added_at': addedAt.toIso8601String(),
    };
  }
}