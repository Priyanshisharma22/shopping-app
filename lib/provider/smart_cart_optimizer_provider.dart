import 'package:flutter/foundation.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';


class BundleSuggestion {
  final String id;
  final String title;
  final String description;
  final List<String> productIds;
  final List<Product> products;
  final double originalPrice;
  final double bundlePrice;
  final double savings;
  final String badge;

  BundleSuggestion({
    required this.id,
    required this.title,
    required this.description,
    required this.productIds,
    required this.products,
    required this.originalPrice,
    required this.bundlePrice,
    required this.savings,
    this.badge = 'BUNDLE DEAL',
  });

  double get savingsPercentage => (savings / originalPrice) * 100;
}

class CouponSuggestion {
  final String code;
  final String title;
  final String description;
  final double discount;
  final double minOrderValue;
  final DateTime expiryDate;
  final bool isAutoApplied;
  final String type; // 'percentage' or 'fixed'

  CouponSuggestion({
    required this.code,
    required this.title,
    required this.description,
    required this.discount,
    required this.minOrderValue,
    required this.expiryDate,
    this.isAutoApplied = false,
    this.type = 'percentage',
  });

  double calculateDiscount(double cartTotal) {
    if (cartTotal < minOrderValue) return 0;
    return type == 'percentage' ? (cartTotal * discount / 100) : discount;
  }
}

class PriceDropAlert {
  final String productId;
  final String productName;
  final String productImage;
  final double oldPrice;
  final double newPrice;
  final double dropPercentage;
  final DateTime detectedAt;

  PriceDropAlert({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.oldPrice,
    required this.newPrice,
    required this.dropPercentage,
    required this.detectedAt,
  });

  double get savings => oldPrice - newPrice;
}

class BudgetAlternative {
  final String category;
  final List<Product> alternatives;
  final double totalPrice;
  final double budgetSavings;

  BudgetAlternative({
    required this.category,
    required this.alternatives,
    required this.totalPrice,
    required this.budgetSavings,
  });
}

class SmartCartOptimizerProvider extends ChangeNotifier {
  List<CartItem> _cartItems = [];
  List<BundleSuggestion> _bundleSuggestions = [];
  List<CouponSuggestion> _availableCoupons = [];
  List<PriceDropAlert> _priceDropAlerts = [];
  CouponSuggestion? _appliedCoupon;
  Map<String, double> _priceHistory = {}; // productId -> original price
  DateTime? _lastAbandonedAt;
  bool _showAbandonedCartOffer = false;

  // Getters
  List<BundleSuggestion> get bundleSuggestions => _bundleSuggestions;
  List<CouponSuggestion> get availableCoupons => _availableCoupons;
  List<PriceDropAlert> get priceDropAlerts => _priceDropAlerts;
  CouponSuggestion? get appliedCoupon => _appliedCoupon;
  bool get showAbandonedCartOffer => _showAbandonedCartOffer;

  // Initialize with cart items
  void updateCart(List<CartItem> cartItems) {
    _cartItems = cartItems;

    // Track price changes
    _detectPriceDrops();

    // Generate smart suggestions
    _generateBundleSuggestions();
    _findBestCoupons();

    // Auto-apply best coupon
    _autoApplyBestCoupon();

    notifyListeners();
  }

  // 1. BUNDLE SUGGESTIONS
  void _generateBundleSuggestions() {
    _bundleSuggestions.clear();

    if (_cartItems.isEmpty) return;

    // Smart bundle detection based on cart items
    final bundles = <BundleSuggestion>[];

    // Bundle 1: Complete Outfit
    if (_hasClothingItems()) {
      bundles.add(_createCompleteOutfitBundle());
    }

    // Bundle 2: Tech Accessories
    if (_hasTechItems()) {
      bundles.add(_createTechAccessoriesBundle());
    }

    // Bundle 3: Complementary Items
    bundles.addAll(_createComplementaryBundles());

    _bundleSuggestions = bundles;
  }

  bool _hasClothingItems() {
    return _cartItems.any((item) {
      final category = item.product.category?.toLowerCase() ?? '';
      return category.contains('clothing') || category.contains('fashion');
    });
  }

  bool _hasTechItems() {
    return _cartItems.any((item) {
      final category = item.product.category?.toLowerCase() ?? '';
      return category.contains('electronics') || category.contains('tech');
    });
  }

  BundleSuggestion _createCompleteOutfitBundle() {
    final products = [
      Product(
        id: 'bundle_shirt',
        name: 'Classic Cotton Shirt',
        description: 'Perfect match for your outfit',
        price: 699,
        originalPrice: 999,
        imageUrl: 'https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf',
        category: 'Clothing',
        rating: 4.3,
        reviewCount: 245,
        stock: 100,
      ),
      Product(
        id: 'bundle_jeans',
        name: 'Slim Fit Jeans',
        description: 'Comfortable and stylish',
        price: 1299,
        originalPrice: 1799,
        imageUrl: 'https://images.unsplash.com/photo-1542272604-787c3835535d',
        category: 'Clothing',
        rating: 4.5,
        reviewCount: 389,
        stock: 80,
      ),
      Product(
        id: 'bundle_shoes',
        name: 'Casual Sneakers',
        description: 'Complete your look',
        price: 1499,
        originalPrice: 2499,
        imageUrl: 'https://images.unsplash.com/photo-1549298916-b41d501d3772',
        category: 'Footwear',
        rating: 4.6,
        reviewCount: 512,
        stock: 60,
      ),
    ];

    final originalPrice = products.fold<double>(
        0, (sum, p) => sum + (p.originalPrice ?? p.price));
    final bundlePrice = products.fold<double>(0, (sum, p) => sum + p.price) * 0.85; // 15% bundle discount
    final savings = originalPrice - bundlePrice;

    return BundleSuggestion(
      id: 'bundle_complete_outfit',
      title: 'Complete Your Outfit',
      description: 'Get shirt, jeans & sneakers together',
      productIds: products.map((p) => p.id).toList(),
      products: products,
      originalPrice: originalPrice,
      bundlePrice: bundlePrice,
      savings: savings,
      badge: 'OUTFIT BUNDLE',
    );
  }

  BundleSuggestion _createTechAccessoriesBundle() {
    final products = [
      Product(
        id: 'bundle_charger',
        name: 'Fast Charger 20W',
        description: 'Quick charging solution',
        price: 499,
        originalPrice: 799,
        imageUrl: 'https://images.unsplash.com/photo-1583863788434-e58a36330cf0',
        category: 'Electronics',
        rating: 4.4,
        reviewCount: 156,
        stock: 150,
      ),
      Product(
        id: 'bundle_cable',
        name: 'USB-C Cable 1m',
        description: 'Durable and fast',
        price: 199,
        originalPrice: 399,
        imageUrl: 'https://images.unsplash.com/photo-1591290619762-a47404c7fc87',
        category: 'Electronics',
        rating: 4.2,
        reviewCount: 234,
        stock: 200,
      ),
      Product(
        id: 'bundle_case',
        name: 'Protective Phone Case',
        description: 'Premium protection',
        price: 299,
        originalPrice: 599,
        imageUrl: 'https://images.unsplash.com/photo-1601784551446-20c9e07cdbdb',
        category: 'Accessories',
        rating: 4.5,
        reviewCount: 445,
        stock: 120,
      ),
    ];

    final originalPrice = products.fold<double>(
        0, (sum, p) => sum + (p.originalPrice ?? p.price));
    final bundlePrice = products.fold<double>(0, (sum, p) => sum + p.price) * 0.80; // 20% bundle discount
    final savings = originalPrice - bundlePrice;

    return BundleSuggestion(
      id: 'bundle_tech_essentials',
      title: 'Tech Essentials Pack',
      description: 'Charger, cable & case combo',
      productIds: products.map((p) => p.id).toList(),
      products: products,
      originalPrice: originalPrice,
      bundlePrice: bundlePrice,
      savings: savings,
      badge: 'TECH BUNDLE',
    );
  }

  List<BundleSuggestion> _createComplementaryBundles() {
    // Generate bundles based on frequently bought together
    return [];
  }

  // 2. COUPON FINDER
  void _findBestCoupons() {
    final cartTotal = _calculateCartTotal();

    _availableCoupons = [
      CouponSuggestion(
        code: 'SAVE10',
        title: '10% Off',
        description: 'Get 10% off on orders above ₹500',
        discount: 10,
        minOrderValue: 500,
        expiryDate: DateTime.now().add(const Duration(days: 7)),
        type: 'percentage',
      ),
      CouponSuggestion(
        code: 'SAVE200',
        title: 'Flat ₹200 Off',
        description: 'Get ₹200 off on orders above ₹1500',
        discount: 200,
        minOrderValue: 1500,
        expiryDate: DateTime.now().add(const Duration(days: 5)),
        type: 'fixed',
      ),
      CouponSuggestion(
        code: 'SAVE20',
        title: '20% Off',
        description: 'Get 20% off on orders above ₹2000',
        discount: 20,
        minOrderValue: 2000,
        expiryDate: DateTime.now().add(const Duration(days: 3)),
        type: 'percentage',
      ),
      CouponSuggestion(
        code: 'FIRSTBUY',
        title: 'First Order Special',
        description: 'Get 25% off on your first order',
        discount: 25,
        minOrderValue: 0,
        expiryDate: DateTime.now().add(const Duration(days: 30)),
        type: 'percentage',
      ),
      CouponSuggestion(
        code: 'MEGA500',
        title: 'Mega Deal',
        description: 'Get ₹500 off on orders above ₹3000',
        discount: 500,
        minOrderValue: 3000,
        expiryDate: DateTime.now().add(const Duration(days: 2)),
        type: 'fixed',
      ),
    ];

    // Filter applicable coupons
    _availableCoupons = _availableCoupons
        .where((coupon) => cartTotal >= coupon.minOrderValue)
        .toList();

    // Sort by discount amount (descending)
    _availableCoupons.sort((a, b) {
      final discountA = a.calculateDiscount(cartTotal);
      final discountB = b.calculateDiscount(cartTotal);
      return discountB.compareTo(discountA);
    });
  }

  void _autoApplyBestCoupon() {
    if (_availableCoupons.isEmpty) {
      _appliedCoupon = null;
      return;
    }

    // Auto-apply the best coupon (highest discount)
    final bestCoupon = _availableCoupons.first;
    _appliedCoupon = bestCoupon.copyWith(isAutoApplied: true);
  }

  void applyCoupon(String code) {
    final coupon = _availableCoupons.firstWhere(
          (c) => c.code == code,
      orElse: () => _availableCoupons.first,
    );

    _appliedCoupon = coupon;
    notifyListeners();
  }

  void removeCoupon() {
    _appliedCoupon = null;
    notifyListeners();
  }

  // 3. PRICE DROP ALERTS
  void _detectPriceDrops() {
    _priceDropAlerts.clear();

    for (var item in _cartItems) {
      final productId = item.product.id;
      final currentPrice = item.product.price;

      // Check if we have price history
      if (_priceHistory.containsKey(productId)) {
        final oldPrice = _priceHistory[productId]!;

        if (currentPrice < oldPrice) {
          final dropPercentage = ((oldPrice - currentPrice) / oldPrice) * 100;

          // Only alert if drop is significant (>5%)
          if (dropPercentage >= 5) {
            _priceDropAlerts.add(PriceDropAlert(
              productId: productId,
              productName: item.product.name,
              productImage: item.product.imageUrl,
              oldPrice: oldPrice,
              newPrice: currentPrice,
              dropPercentage: dropPercentage,
              detectedAt: DateTime.now(),
            ));
          }
        }
      }

      // Update price history
      _priceHistory[productId] = currentPrice;
    }
  }

  void simulatePriceDrop(String productId, double newPrice) {
    // For testing - simulate a price drop
    final item = _cartItems.firstWhere((item) => item.product.id == productId);
    final oldPrice = item.product.price;

    _priceDropAlerts.add(PriceDropAlert(
      productId: productId,
      productName: item.product.name,
      productImage: item.product.imageUrl,
      oldPrice: oldPrice,
      newPrice: newPrice,
      dropPercentage: ((oldPrice - newPrice) / oldPrice) * 100,
      detectedAt: DateTime.now(),
    ));

    notifyListeners();
  }

  void dismissPriceAlert(String productId) {
    _priceDropAlerts.removeWhere((alert) => alert.productId == productId);
    notifyListeners();
  }

  // 4. ABANDONED CART RECOVERY
  void markCartAbandoned() {
    _lastAbandonedAt = DateTime.now();

    // Show abandoned cart offer after 30 minutes
    Future.delayed(const Duration(minutes: 30), () {
      _showAbandonedCartOffer = true;
      notifyListeners();
    });
  }

  void dismissAbandonedCartOffer() {
    _showAbandonedCartOffer = false;
    notifyListeners();
  }

  CouponSuggestion? getAbandonedCartOffer() {
    if (!_showAbandonedCartOffer) return null;

    return CouponSuggestion(
      code: 'COMEBACK10',
      title: 'Welcome Back! 10% Off',
      description: 'Complete your purchase now and save 10%',
      discount: 10,
      minOrderValue: 0,
      expiryDate: DateTime.now().add(const Duration(hours: 24)),
      type: 'percentage',
    );
  }

  // 5. BUDGET OPTIMIZER
  List<BudgetAlternative> getBudgetAlternatives(double targetBudget) {
    final cartTotal = _calculateCartTotal();

    if (cartTotal <= targetBudget) {
      return []; // Already within budget
    }

    final alternatives = <BudgetAlternative>[];

    // Group items by category
    final categories = <String, List<CartItem>>{};
    for (var item in _cartItems) {
      final category = item.product.category ?? 'Other';
      categories.putIfAbsent(category, () => []).add(item);
    }

    // Find cheaper alternatives in each category
    for (var entry in categories.entries) {
      final category = entry.key;
      final items = entry.value;

      final alternativeProducts = _findCheaperAlternatives(items, targetBudget);

      if (alternativeProducts.isNotEmpty) {
        final totalPrice = alternativeProducts.fold<double>(
            0, (sum, p) => sum + p.price);
        final savings = cartTotal - totalPrice;

        alternatives.add(BudgetAlternative(
          category: category,
          alternatives: alternativeProducts,
          totalPrice: totalPrice,
          budgetSavings: savings,
        ));
      }
    }

    // Sort by maximum savings
    alternatives.sort((a, b) => b.budgetSavings.compareTo(a.budgetSavings));

    return alternatives;
  }

  List<Product> _findCheaperAlternatives(
      List<CartItem> items, double targetBudget) {
    // For each item, find a similar but cheaper alternative
    final alternatives = <Product>[];

    for (var item in items) {
      // Find cheaper products in the same category
      // This would typically query your product database
      // For now, creating mock alternatives
      final cheaper = Product(
        id: '${item.product.id}_alt',
        name: '${item.product.name} (Budget Variant)',
        description: 'Similar quality at a better price',
        price: item.product.price * 0.7, // 30% cheaper
        originalPrice: item.product.price,
        imageUrl: item.product.imageUrl,
        category: item.product.category,
        rating: (item.product.rating ?? 4.0) - 0.2,
        reviewCount: item.product.reviewCount,
        stock: item.product.stock,
      );

      alternatives.add(cheaper);
    }

    return alternatives;
  }

  // Helper methods
  double _calculateCartTotal() {
    return _cartItems.fold<double>(
      0,
          (sum, item) => sum + (item.product.price * item.quantity),
    );
  }

  double getTotalSavings() {
    double savings = 0;

    // Add coupon discount
    if (_appliedCoupon != null) {
      savings += _appliedCoupon!.calculateDiscount(_calculateCartTotal());
    }

    // Add bundle savings if applied
    // Add price drop savings
    for (var alert in _priceDropAlerts) {
      savings += alert.savings;
    }

    return savings;
  }

  String getSmartRecommendation() {
    final cartTotal = _calculateCartTotal();
    final totalSavings = getTotalSavings();

    if (_bundleSuggestions.isNotEmpty) {
      final bestBundle = _bundleSuggestions.first;
      return 'Add ${bestBundle.title} and save ₹${bestBundle.savings.toStringAsFixed(0)}!';
    }

    if (_availableCoupons.isNotEmpty && _appliedCoupon == null) {
      final bestCoupon = _availableCoupons.first;
      final discount = bestCoupon.calculateDiscount(cartTotal);
      return 'Apply ${bestCoupon.code} to save ₹${discount.toStringAsFixed(0)}!';
    }

    if (_priceDropAlerts.isNotEmpty) {
      return '${_priceDropAlerts.length} item(s) just dropped in price!';
    }

    if (totalSavings > 0) {
      return 'You\'re saving ₹${totalSavings.toStringAsFixed(0)} on this order!';
    }

    return 'Your cart is optimized for the best value!';
  }
}

// Extension for CouponSuggestion
extension CouponExtension on CouponSuggestion {
  CouponSuggestion copyWith({
    String? code,
    String? title,
    String? description,
    double? discount,
    double? minOrderValue,
    DateTime? expiryDate,
    bool? isAutoApplied,
    String? type,
  }) {
    return CouponSuggestion(
      code: code ?? this.code,
      title: title ?? this.title,
      description: description ?? this.description,
      discount: discount ?? this.discount,
      minOrderValue: minOrderValue ?? this.minOrderValue,
      expiryDate: expiryDate ?? this.expiryDate,
      isAutoApplied: isAutoApplied ?? this.isAutoApplied,
      type: type ?? this.type,
    );
  }
}