import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transaction_model.dart';

class ApiService {
  static const String baseUrl = 'https://api.example.com'; // Replace with actual API URL

  // Fetch transactions from API
  static Future<List<TransactionModel>> fetchTransactions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/transactions'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => TransactionModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load transactions');
      }
    } catch (e) {
      // Return dummy data if API fails
      return _getDummyTransactions();
    }
  }

  // Get dummy transactions for testing
  static List<TransactionModel> _getDummyTransactions() {
    return List.generate(10, (index) {
      final id = index + 1;
      final isCredit = id % 2 == 0;

      return TransactionModel(
        id: 'TXN00$id',
        type: isCredit ? 'credit' : 'debit',
        amount: (100 + (id * 50)).toDouble(),
        description: isCredit
            ? 'Received from user${id % 10}@upi'
            : 'Payment to merchant${id % 5}@upi',
        timestamp: DateTime.now().subtract(Duration(days: id)),
        reference: isCredit ? 'user${id % 10}@upi' : 'merchant${id % 5}@upi',
        status: 'completed',
      );
    });
  }

  // Fetch specific transaction details
  static Future<TransactionModel?> fetchTransactionById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/transactions/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return TransactionModel.fromJson(jsonDecode(response.body));
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Send money via API
  static Future<bool> sendMoney({
    required String receiverUpiId,
    required double amount,
    String? description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/transactions/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'receiverUpiId': receiverUpiId,
          'amount': amount,
          'description': description ?? 'Payment to $receiverUpiId',
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Get transaction history with filters
  static Future<List<TransactionModel>> getTransactionHistory({
    String? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, String>{};

      if (type != null) queryParams['type'] = type;
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }

      final uri = Uri.parse('$baseUrl/transactions/history')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => TransactionModel.fromJson(json)).toList();
      } else {
        return _getFilteredDummyTransactions(type: type);
      }
    } catch (e) {
      return _getFilteredDummyTransactions(type: type);
    }
  }

  // Get filtered dummy transactions
  static List<TransactionModel> _getFilteredDummyTransactions({String? type}) {
    final allTransactions = _getDummyTransactions();

    if (type != null) {
      return allTransactions.where((t) => t.type == type).toList();
    }

    return allTransactions;
  }

  // Add money to wallet
  static Future<bool> addMoney({
    required double amount,
    String? reference,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/wallet/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': amount,
          'reference': reference ?? 'BANK_TRANSFER',
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Get wallet balance
  static Future<double?> getWalletBalance() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/wallet/balance'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['balance'] as num).toDouble();
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Process shopping payment
  static Future<bool> processPayment({
    required double amount,
    required String orderId,
    String? description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/transactions/payment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': amount,
          'orderId': orderId,
          'description': description ?? 'Shopping Order #$orderId',
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}