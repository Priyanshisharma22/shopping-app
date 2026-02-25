class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? originalPrice;
  final int? discount;
  final String imageUrl;
  final String? category;
  final int stock;
  final DateTime? createdAt;
  final List<String>? additionalImages;
  final double? rating;
  final int? reviewCount;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.originalPrice,
    this.discount,
    required this.imageUrl,
    this.category,
    required this.stock,
    this.createdAt,
    this.additionalImages,
    this.rating,
    this.reviewCount,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      originalPrice: json['original_price'] != null
          ? (json['original_price']).toDouble()
          : null,
      discount: json['discount'],
      imageUrl: json['image_url'] ?? '',
      category: json['category'],
      stock: json['stock'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      additionalImages: json['additional_images'] != null
          ? List<String>.from(json['additional_images'])
          : null,
      rating: json['rating'] != null ? (json['rating']).toDouble() : null,
      reviewCount: json['review_count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'original_price': originalPrice,
      'discount': discount,
      'image_url': imageUrl,
      'category': category,
      'stock': stock,
      'created_at': createdAt?.toIso8601String(),
      'additional_images': additionalImages,
      'rating': rating,
      'review_count': reviewCount,
    };
  }

  bool get isInStock => stock > 0;
  bool get hasDiscount => discount != null && discount! > 0;

  double get finalPrice {
    if (originalPrice != null && discount != null) {
      return originalPrice! * (1 - discount! / 100);
    }
    return price;
  }
}