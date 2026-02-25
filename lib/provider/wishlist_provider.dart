import 'package:flutter/material.dart';
import '../models/wishlist_item_model.dart';

class WishlistProvider with ChangeNotifier {
  List<WishlistItem> _wishlistItems = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<WishlistItem> get wishlistItems => _wishlistItems;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get wishlistCount => _wishlistItems.length;

  // Check if product is in wishlist
  bool isInWishlist(String productId) {
    return _wishlistItems.any((item) => item.productId == productId);
  }

  // Fetch wishlist items
  Future<void> fetchWishlist(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(seconds: 1));

      // Mock data
      _wishlistItems = [
        WishlistItem(
          id: '1',
          userId: userId,
          productId: 'p1',
          productName: 'Floral Summer Dress',
          productImage: 'https://via.placeholder.com/200',
          price: 599.0,
          category: 'Dresses',
          addedAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        WishlistItem(
          id: '2',
          userId: userId,
          productId: 'p2',
          productName: 'Cotton Kurti Set',
          productImage: 'https://via.placeholder.com/200',
          price: 799.0,
          category: 'Ethnic Wear',
          addedAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
      ];

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add item to wishlist
  Future<bool> addToWishlist({
    required String userId,
    required String productId,
    required String productName,
    required String productImage,
    required double price,
    String? category,
  }) async {
    try {
      // Check if already in wishlist
      if (isInWishlist(productId)) {
        return false;
      }

      // TODO: Replace with actual API call
      await Future.delayed(const Duration(milliseconds: 500));

      final newItem = WishlistItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        productId: productId,
        productName: productName,
        productImage: productImage,
        price: price,
        category: category,
        addedAt: DateTime.now(),
      );

      _wishlistItems.insert(0, newItem);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Remove item from wishlist
  Future<bool> removeFromWishlist(String productId) async {
    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(milliseconds: 300));

      _wishlistItems.removeWhere((item) => item.productId == productId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Toggle wishlist (add/remove)
  Future<bool> toggleWishlist({
    required String userId,
    required String productId,
    required String productName,
    required String productImage,
    required double price,
    String? category,
  }) async {
    if (isInWishlist(productId)) {
      return await removeFromWishlist(productId);
    } else {
      return await addToWishlist(
        userId: userId,
        productId: productId,
        productName: productName,
        productImage: productImage,
        price: price,
        category: category,
      );
    }
  }

  void clearWishlist() {
    _wishlistItems = [];
    _errorMessage = null;
    notifyListeners();
  }
}