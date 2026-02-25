import 'package:flutter/material.dart';
import '../models/return_refund_model.dart';

class ReturnRefundProvider with ChangeNotifier {
  List<ReturnRequest> _returnRequests = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ReturnRequest> get returnRequests => _returnRequests;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Get returns for a specific order
  List<ReturnRequest> getReturnsForOrder(String orderId) {
    return _returnRequests
        .where((request) => request.orderId == orderId)
        .toList();
  }

  // Get return by ID
  ReturnRequest? getReturnById(String returnId) {
    try {
      return _returnRequests.firstWhere((request) => request.id == returnId);
    } catch (e) {
      return null;
    }
  }

  // Check if an order item has a return request
  bool hasReturnRequest(String orderItemId) {
    return _returnRequests.any((request) => request.orderItemId == orderItemId);
  }

  // Fetch all return requests
  Future<void> fetchReturnRequests(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(seconds: 1));

      // Mock data for demonstration
      _returnRequests = [];

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a new return request
  Future<bool> createReturnRequest({
    required String orderId,
    required String orderItemId,
    required String productId,
    required String productName,
    required String productImage,
    required double price,
    required int quantity,
    required ReturnReason reason,
    required RefundMethod refundMethod,
    String? additionalComments,
    List<String> images = const [],
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(seconds: 1));

      final returnRequest = ReturnRequest(
        id: 'RET${DateTime.now().millisecondsSinceEpoch}',
        orderId: orderId,
        orderItemId: orderItemId,
        userId: 'user_123', // Get from auth
        productId: productId,
        productName: productName,
        productImage: productImage,
        price: price,
        quantity: quantity,
        reason: reason,
        additionalComments: additionalComments,
        images: images,
        status: ReturnStatus.pending,
        refundMethod: refundMethod,
        refundAmount: price * quantity,
        requestedAt: DateTime.now(),
      );

      _returnRequests.add(returnRequest);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update return status (for admin or system)
  Future<bool> updateReturnStatus({
    required String returnId,
    required ReturnStatus newStatus,
    String? rejectionReason,
    String? trackingId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final index = _returnRequests.indexWhere((r) => r.id == returnId);
      if (index == -1) {
        throw Exception('Return request not found');
      }

      final updatedRequest = _returnRequests[index].copyWith(
        status: newStatus,
        rejectionReason: rejectionReason,
        trackingId: trackingId,
        approvedAt: newStatus == ReturnStatus.approved ? DateTime.now() : null,
        pickedUpAt: newStatus == ReturnStatus.pickedUp ? DateTime.now() : null,
        refundedAt:
        newStatus == ReturnStatus.refundCompleted ? DateTime.now() : null,
      );

      _returnRequests[index] = updatedRequest;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Cancel return request
  Future<bool> cancelReturnRequest(String returnId) async {
    return await updateReturnStatus(
      returnId: returnId,
      newStatus: ReturnStatus.cancelled,
    );
  }

  // Process refund
  Future<bool> processRefund(String returnId) async {
    try {
      final returnRequest = getReturnById(returnId);
      if (returnRequest == null) return false;

      // Update status to refund initiated
      await updateReturnStatus(
        returnId: returnId,
        newStatus: ReturnStatus.refundInitiated,
      );

      // TODO: Actual refund processing via payment gateway or wallet
      await Future.delayed(const Duration(seconds: 2));

      // Update status to refund completed
      await updateReturnStatus(
        returnId: returnId,
        newStatus: ReturnStatus.refundCompleted,
      );

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearReturns() {
    _returnRequests = [];
    _errorMessage = null;
    notifyListeners();
  }
}