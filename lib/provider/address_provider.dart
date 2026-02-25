import 'package:flutter/material.dart';
import '../models/address_model.dart';

class AddressProvider with ChangeNotifier {
  // ─────────────────────────────────────────────
  //  State
  // ─────────────────────────────────────────────

  List<AddressModel> _addresses = [];
  bool _isLoading = false;
  bool _isSubmitting = false; // separate flag for add / update / delete calls
  String? _errorMessage;
  String? _currentUserId;

  // ─────────────────────────────────────────────
  //  Getters
  // ─────────────────────────────────────────────

  List<AddressModel> get addresses => List.unmodifiable(_addresses);
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  bool get hasAddresses => _addresses.isNotEmpty;
  bool get hasError => _errorMessage != null;
  int get addressCount => _addresses.length;

  /// Returns the address marked as default.
  /// Falls back to the first address if none is marked, or null if list is empty.
  AddressModel? get defaultAddress {
    if (_addresses.isEmpty) return null;
    try {
      return _addresses.firstWhere((addr) => addr.isDefault);
    } catch (_) {
      return _addresses.first;
    }
  }

  /// Returns only addresses for a specific label (e.g. 'Home', 'Work')
  List<AddressModel> getAddressesByLabel(String label) =>
      _addresses.where((addr) => addr.label == label).toList();

  /// Returns address by its ID, or null if not found
  AddressModel? getAddressById(String id) {
    try {
      return _addresses.firstWhere((addr) => addr.id == id);
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────────────────────────
  //  Fetch
  // ─────────────────────────────────────────────

  Future<void> fetchAddresses(String userId) async {
    // Avoid redundant fetches for the same user
    if (_isLoading) return;

    _currentUserId = userId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // TODO: Replace with actual API call
      // final response = await ApiService.getAddresses(userId);
      // _addresses = response.map((e) => AddressModel.fromJson(e)).toList();
      await Future.delayed(const Duration(seconds: 1));

      _addresses = [
        AddressModel(
          id: '1',
          userId: userId,
          label: 'Home',
          fullName: 'John Doe',
          phoneNumber: '+91 9876543210',
          addressLine1: '123 Main Street',
          addressLine2: 'Apartment 4B',
          city: 'Mumbai',
          state: 'Maharashtra',
          pincode: '400001',
          isDefault: true,
          createdAt: DateTime.now(),
        ),
        AddressModel(
          id: '2',
          userId: userId,
          label: 'Work',
          fullName: 'John Doe',
          phoneNumber: '+91 9876543210',
          addressLine1: '456 Business Park',
          addressLine2: 'Tower A, Floor 5',
          city: 'Mumbai',
          state: 'Maharashtra',
          pincode: '400051',
          isDefault: false,
          createdAt: DateTime.now(),
        ),
      ];

      _errorMessage = null;
    } catch (e) {
      _errorMessage = _parseError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────
  //  Add
  // ─────────────────────────────────────────────

  Future<bool> addAddress(AddressModel address) async {
    if (_isSubmitting) return false;

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // TODO: Replace with actual API call
      // final created = await ApiService.createAddress(address.toJson());
      // final newAddress = AddressModel.fromJson(created);
      await Future.delayed(const Duration(seconds: 1));

      // If this new address is default, unset all existing defaults
      if (address.isDefault) {
        _addresses = _addresses
            .map((addr) => addr.copyWith(isDefault: false))
            .toList();
      }

      // If this is the very first address, force it as default
      final newAddress = _addresses.isEmpty
          ? address.copyWith(isDefault: true)
          : address;

      _addresses.add(newAddress);

      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────
  //  Update
  // ─────────────────────────────────────────────

  Future<bool> updateAddress(AddressModel address) async {
    if (_isSubmitting) return false;

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // TODO: Replace with actual API call
      // await ApiService.updateAddress(address.id, address.toJson());
      await Future.delayed(const Duration(seconds: 1));

      final index = _addresses.indexWhere((addr) => addr.id == address.id);
      if (index == -1) {
        _errorMessage = 'Address not found';
        return false;
      }

      // If this is now default, clear all other defaults first
      if (address.isDefault) {
        _addresses = _addresses
            .map((addr) => addr.copyWith(isDefault: false))
            .toList();
      }

      _addresses[index] = address.copyWith(updatedAt: DateTime.now());

      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────
  //  Delete
  // ─────────────────────────────────────────────

  Future<bool> deleteAddress(String addressId) async {
    if (_isSubmitting) return false;

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // TODO: Replace with actual API call
      // await ApiService.deleteAddress(addressId);
      await Future.delayed(const Duration(milliseconds: 600));

      final wasDefault =
      _addresses.any((a) => a.id == addressId && a.isDefault);

      _addresses.removeWhere((addr) => addr.id == addressId);

      // Auto-promote first address to default if we just deleted the default
      if (wasDefault && _addresses.isNotEmpty) {
        _addresses[0] = _addresses[0].copyWith(isDefault: true);
      }

      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────
  //  Set Default
  // ─────────────────────────────────────────────

  Future<bool> setDefaultAddress(String addressId) async {
    if (_isSubmitting) return false;

    // Optimistic update first — feels instant to the user
    _addresses = _addresses.map((addr) {
      return addr.copyWith(isDefault: addr.id == addressId);
    }).toList();
    notifyListeners();

    try {
      // TODO: Replace with actual API call
      // await ApiService.setDefaultAddress(addressId);
      await Future.delayed(const Duration(milliseconds: 400));
      return true;
    } catch (e) {
      // Rollback on failure
      _errorMessage = _parseError(e);
      await fetchAddresses(_currentUserId ?? '');
      return false;
    }
  }

  // ─────────────────────────────────────────────
  //  Refresh
  // ─────────────────────────────────────────────

  Future<void> refreshAddresses() async {
    if (_currentUserId == null || _currentUserId!.isEmpty) return;
    _isLoading = false; // reset so fetchAddresses guard passes
    await fetchAddresses(_currentUserId!);
  }

  // ─────────────────────────────────────────────
  //  Utility
  // ─────────────────────────────────────────────

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearAddresses() {
    _addresses = [];
    _errorMessage = null;
    _currentUserId = null;
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  //  Private Helpers
  // ─────────────────────────────────────────────

  String _parseError(Object e) {
    final msg = e.toString();
    if (msg.contains('SocketException') || msg.contains('NetworkException')) {
      return 'No internet connection. Please try again.';
    }
    if (msg.contains('TimeoutException')) {
      return 'Request timed out. Please try again.';
    }
    if (msg.contains('401') || msg.contains('Unauthorized')) {
      return 'Session expired. Please log in again.';
    }
    if (msg.contains('404')) {
      return 'Address not found.';
    }
    if (msg.contains('500')) {
      return 'Server error. Please try again later.';
    }
    return 'Something went wrong. Please try again.';
  }
}