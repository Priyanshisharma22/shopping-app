import 'package:flutter/foundation.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  // ==================== GETTERS ====================

  List<CartItem> get items => _items;

  int get itemCount => _items.length;

  int get totalQuantity {
    return _items.fold(0, (sum, item) => sum + item.quantity);
  }

  double get totalAmount {
    return _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  // Alias for voice assistant compatibility
  double get totalPrice => totalAmount;

  double get totalMRP {
    return _items.fold(
      0.0,
          (sum, item) => sum + (item.product.price * item.quantity),
    );
  }

  double get totalSavings {
    if (_items.isEmpty) return 0.0;

    return _items.fold(
      0.0,
          (sum, item) {
        if (item.product.originalPrice != null) {
          return sum +
              ((item.product.originalPrice! - item.product.price) *
                  item.quantity);
        }
        return sum;
      },
    );
  }

  double get deliveryCharge {
    // Free delivery above ₹500
    return totalAmount >= 500 ? 0.0 : 40.0;
  }

  double get finalAmount {
    return totalAmount + deliveryCharge;
  }

  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;

  // ==================== ADD TO CART (ENHANCED FOR VOICE) ====================

  void addToCart(dynamic product, {String? size, String? color, int quantity = 1}) {
    Product productObj;

    // Handle both Product objects and Map inputs (for voice assistant)
    if (product is Product) {
      productObj = product;
    } else if (product is Map<String, dynamic>) {
      // Convert Map to Product object (for voice assistant compatibility)
      productObj = Product(
        id: product['id']?.toString() ?? 'voice_${DateTime.now().millisecondsSinceEpoch}',
        name: product['name']?.toString() ?? 'Voice Product',
        description: product['description']?.toString() ?? 'Added via voice',
        price: (product['price'] as num?)?.toDouble() ?? 0.0,
        imageUrl: product['image']?.toString() ?? product['imageUrl']?.toString() ?? 'https://via.placeholder.com/150',
        stock: product['stock'] as int? ?? 100,
        category: product['category']?.toString(),
        originalPrice: (product['originalPrice'] as num?)?.toDouble(),
        discount: (product['discount'] as num?)?.toDouble()?.toInt(),
      );
    } else {
      debugPrint('Error: Invalid product type');
      return;
    }

    // Check if product already exists with same size and color
    final existingIndex = _items.indexWhere((item) =>
    item.product.id == productObj.id &&
        item.selectedSize == size &&
        item.selectedColor == color);

    if (existingIndex != -1) {
      // Product exists, increase quantity
      _items[existingIndex] = CartItem(
        product: _items[existingIndex].product,
        quantity: _items[existingIndex].quantity + quantity,
        selectedSize: _items[existingIndex].selectedSize,
        selectedColor: _items[existingIndex].selectedColor,
      );
      debugPrint('Updated quantity for ${productObj.name}: ${_items[existingIndex].quantity}');
    } else {
      // Add new product to cart
      _items.add(CartItem(
        product: productObj,
        quantity: quantity,
        selectedSize: size,
        selectedColor: color,
      ));
      debugPrint('Added ${productObj.name} to cart');
    }
    notifyListeners();
  }

  // ==================== REMOVE FROM CART ====================

  void removeFromCart(String productId, {String? size, String? color}) {
    final initialLength = _items.length;
    _items.removeWhere((item) =>
    item.product.id == productId &&
        item.selectedSize == size &&
        item.selectedColor == color);

    if (_items.length < initialLength) {
      debugPrint('Removed product $productId from cart');
      notifyListeners();
    }
  }

  void removeAt(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      debugPrint('Removed item at index $index');
      notifyListeners();
    }
  }

  // ==================== UPDATE QUANTITY ====================

  void updateQuantity(String productId, int quantity,
      {String? size, String? color}) {
    final index = _items.indexWhere((item) =>
    item.product.id == productId &&
        item.selectedSize == size &&
        item.selectedColor == color);

    if (index != -1) {
      if (quantity > 0) {
        _items[index] = CartItem(
          product: _items[index].product,
          quantity: quantity,
          selectedSize: _items[index].selectedSize,
          selectedColor: _items[index].selectedColor,
        );
        debugPrint('Updated quantity for ${_items[index].product.name}: $quantity');
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void incrementQuantity(String productId, {String? size, String? color}) {
    final index = _items.indexWhere((item) =>
    item.product.id == productId &&
        item.selectedSize == size &&
        item.selectedColor == color);

    if (index != -1) {
      _items[index] = CartItem(
        product: _items[index].product,
        quantity: _items[index].quantity + 1,
        selectedSize: _items[index].selectedSize,
        selectedColor: _items[index].selectedColor,
      );
      notifyListeners();
    }
  }

  void decrementQuantity(String productId, {String? size, String? color}) {
    final index = _items.indexWhere((item) =>
    item.product.id == productId &&
        item.selectedSize == size &&
        item.selectedColor == color);

    if (index != -1) {
      if (_items[index].quantity > 1) {
        _items[index] = CartItem(
          product: _items[index].product,
          quantity: _items[index].quantity - 1,
          selectedSize: _items[index].selectedSize,
          selectedColor: _items[index].selectedColor,
        );
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  // ==================== CLEAR CART ====================

  void clearCart() {
    _items.clear();
    debugPrint('Cart cleared');
    notifyListeners();
  }

  // ==================== UTILITY METHODS ====================

  bool isInCart(String productId, {String? size, String? color}) {
    return _items.any((item) =>
    item.product.id == productId &&
        item.selectedSize == size &&
        item.selectedColor == color);
  }

  int getProductQuantity(String productId, {String? size, String? color}) {
    final item = _items.firstWhere(
          (item) =>
      item.product.id == productId &&
          item.selectedSize == size &&
          item.selectedColor == color,
      orElse: () => CartItem(
        product: Product(
          id: '',
          name: '',
          description: '',
          price: 0,
          imageUrl: '',
          stock: 0,
        ),
        quantity: 0,
      ),
    );
    return item.quantity;
  }

  int getTotalProductQuantity(String productId) {
    return _items
        .where((item) => item.product.id == productId)
        .fold(0, (sum, item) => sum + item.quantity);
  }

  CartItem? getCartItem(String productId, {String? size, String? color}) {
    try {
      return _items.firstWhere(
            (item) =>
        item.product.id == productId &&
            item.selectedSize == size &&
            item.selectedColor == color,
      );
    } catch (e) {
      return null;
    }
  }

  // Get all cart items for a specific product (different sizes/colors)
  List<CartItem> getProductCartItems(String productId) {
    return _items.where((item) => item.product.id == productId).toList();
  }

  // ==================== VOICE ASSISTANT HELPERS ====================

  // Get cart summary as Map (for voice assistant compatibility)
  Map<String, dynamic> getCartSummary() {
    return {
      'items': _items.map((item) => {
        'id': item.product.id,
        'name': item.product.name,
        'price': item.product.price,
        'quantity': item.quantity,
        'image': item.product.imageUrl,
        'size': item.selectedSize,
        'color': item.selectedColor,
      }).toList(),
      'itemCount': itemCount,
      'totalQuantity': totalQuantity,
      'totalPrice': totalPrice,
      'totalAmount': totalAmount,
      'deliveryCharge': deliveryCharge,
      'finalAmount': finalAmount,
      'timestamp': DateTime.now().toString(),
    };
  }

  // Get items as List<Map> (for voice assistant compatibility)
  List<Map<String, dynamic>> getItemsAsMapList() {
    return _items.map((item) => {
      'id': item.product.id,
      'name': item.product.name,
      'price': item.product.price,
      'quantity': item.quantity,
      'image': item.product.imageUrl,
      'category': item.product.category,
      'size': item.selectedSize,
      'color': item.selectedColor,
      'total': item.totalPrice,
    }).toList();
  }

  // ==================== DEBUG ====================

  void printCart() {
    debugPrint('========== CART CONTENTS ==========');
    debugPrint('Total Items: $itemCount');
    debugPrint('Total Quantity: $totalQuantity');
    debugPrint('Total Price: ₹$totalPrice');
    debugPrint('Delivery Charge: ₹$deliveryCharge');
    debugPrint('Final Amount: ₹$finalAmount');
    debugPrint('Items:');
    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      debugPrint(
          '  ${i + 1}. ${item.product.name} - Qty: ${item.quantity} - Price: ₹${item.product.price} - Total: ₹${item.totalPrice}');
      if (item.selectedSize != null) debugPrint('     Size: ${item.selectedSize}');
      if (item.selectedColor != null) debugPrint('     Color: ${item.selectedColor}');
    }
    debugPrint('===================================');
  }
}