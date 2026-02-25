import 'dart:async';
import 'package:flutter/material.dart';
import '../models/product_model.dart';

class SearchProvider with ChangeNotifier {
  List<Product> _searchResults = [];
  List<Product> _allProducts = [];
  bool _isLoading = false;
  String _searchQuery = '';
  Timer? _debounce;

  List<Product> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  bool get hasResults => _searchResults.isNotEmpty;

  // Initialize with all products
  void setAllProducts(List<Product> products) {
    _allProducts = products;
    notifyListeners();
  }

  // Search products by name (with debouncing)
  void searchProducts(String query) {
    _searchQuery = query;

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.isEmpty) {
      _searchResults = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  // Perform the actual search
  void _performSearch(String query) async {
    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(milliseconds: 500));

      final lowerQuery = query.toLowerCase();

      // Filter products locally (or use API)
      _searchResults = _allProducts.where((product) {
        return product.name.toLowerCase().contains(lowerQuery) ||
            (product.description?.toLowerCase().contains(lowerQuery) ?? false) ||
            (product.category?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Filter by category
  void filterByCategory(String category) {
    _searchResults = _allProducts.where((product) {
      return product.category?.toLowerCase() == category.toLowerCase();
    }).toList();

    notifyListeners();
  }

  // Filter by price range
  void filterByPriceRange(double minPrice, double maxPrice) {
    _searchResults = _searchResults.where((product) {
      return product.price >= minPrice && product.price <= maxPrice;
    }).toList();

    notifyListeners();
  }

  // Sort results
  void sortResults(String sortBy) {
    switch (sortBy) {
      case 'price_low_high':
        _searchResults.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high_low':
        _searchResults.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'name_a_z':
        _searchResults.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'name_z_a':
        _searchResults.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 'newest':
        _searchResults.sort((a, b) =>
            (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
        break;
    }

    notifyListeners();
  }

  // Clear search
  void clearSearch() {
    _searchQuery = '';
    _searchResults = [];
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}