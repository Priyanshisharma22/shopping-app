import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/transaction_model.dart';

class WalletProvider extends ChangeNotifier {
  // Wallet balance
  double _balance = 5000.0;

  // User UPI ID
  String _upiId = 'user@paytm';

  // List of transactions (using TransactionModel)
  List<TransactionModel> _transactions = [];

  // Loading state
  bool _isLoading = false;

  // ==================== GETTERS ====================

  double get balance => _balance;
  String get upiId => _upiId;
  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;

  // Alias getters for compatibility
  List<TransactionModel> get recentTransactions =>
      _transactions.take(10).toList();

  // ==================== CONSTRUCTOR ====================

  WalletProvider() {
    _loadWalletData();
  }

  // ==================== LOAD & SAVE DATA ====================

  Future<void> _loadWalletData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load balance
      _balance = prefs.getDouble('wallet_balance') ?? 5000.0;

      // Load UPI ID
      _upiId = prefs.getString('upi_id') ?? 'user@paytm';

      // Load transactions
      final transactionsJson = prefs.getString('transactions');
      if (transactionsJson != null) {
        final List<dynamic> decoded = jsonDecode(transactionsJson);
        _transactions = decoded
            .map((json) => TransactionModel.fromJson(json))
            .toList();
      } else {
        _initializeSampleTransactions();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading wallet data: $e');
      _initializeSampleTransactions();
    }
  }

  Future<void> _saveWalletData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setDouble('wallet_balance', _balance);
      await prefs.setString('upi_id', _upiId);

      final transactionsJson = jsonEncode(
        _transactions.map((t) => t.toJson()).toList(),
      );
      await prefs.setString('transactions', transactionsJson);
    } catch (e) {
      debugPrint('Error saving wallet data: $e');
    }
  }

  void _initializeSampleTransactions() {
    _transactions = [
      TransactionModel(
        id: 'TXN001',
        type: 'credit',
        amount: 5000.0,
        description: 'Initial wallet credit',
        timestamp: DateTime.now().subtract(const Duration(days: 30)),
        reference: 'INIT',
        status: 'completed',
      ),
      TransactionModel(
        id: 'TXN002',
        type: 'debit',
        amount: 500.0,
        description: 'Payment to merchant@paytm',
        timestamp: DateTime.now().subtract(const Duration(days: 15)),
        reference: 'merchant@paytm',
        status: 'completed',
      ),
      TransactionModel(
        id: 'TXN003',
        type: 'credit',
        amount: 1000.0,
        description: 'Received from friend@paytm',
        timestamp: DateTime.now().subtract(const Duration(days: 10)),
        reference: 'friend@paytm',
        status: 'completed',
      ),
    ];
    _saveWalletData();
  }

  // ==================== BALANCE OPERATIONS (VOICE COMPATIBLE) ====================

  /// Add balance to wallet
  /// Works with both voice commands and manual operations
  void addBalance(double amount, {String? description}) {
    if (amount <= 0) {
      debugPrint('Error: Amount must be positive');
      return;
    }

    _balance += amount;

    _addTransaction(
      type: 'credit',
      amount: amount,
      description: description ?? 'Money added to wallet',
    );

    _saveWalletData();
    debugPrint('✅ Added ₹$amount to wallet. New balance: ₹$_balance');
    notifyListeners();
  }

  /// Deduct balance from wallet (CRITICAL FOR VOICE CHECKOUT)
  /// This is called when user says "Checkout with wallet"
  void deductBalance(double amount, {String? description}) {
    if (amount <= 0) {
      debugPrint('Error: Amount must be positive');
      return;
    }

    if (_balance < amount) {
      debugPrint('❌ Insufficient balance. Current: ₹$_balance, Required: ₹$amount');
      throw Exception('Insufficient wallet balance');
    }

    _balance -= amount;

    _addTransaction(
      type: 'debit',
      amount: amount,
      description: description ?? 'Payment from wallet',
    );

    _saveWalletData();
    debugPrint('✅ Deducted ₹$amount from wallet. New balance: ₹$_balance');
    notifyListeners();
  }

  void setBalance(double amount) {
    if (amount < 0) {
      debugPrint('Error: Balance cannot be negative');
      return;
    }

    final oldBalance = _balance;
    _balance = amount;

    _addTransaction(
      type: amount > oldBalance ? 'credit' : 'debit',
      amount: (amount - oldBalance).abs(),
      description: 'Balance adjusted',
    );

    _saveWalletData();
    debugPrint('Balance set to ₹$_balance');
    notifyListeners();
  }

  // ==================== VALIDATION ====================

  bool hasEnoughBalance(double amount) {
    return _balance >= amount;
  }

  bool canAfford(double amount) {
    return hasEnoughBalance(amount);
  }

  bool hasSufficientBalance(double amount) {
    return hasEnoughBalance(amount);
  }

  double getAvailableBalance() {
    return _balance;
  }

  // ==================== TRANSACTION MANAGEMENT ====================

  void _addTransaction({
    required String type,
    required double amount,
    required String description,
    String? reference,
  }) {
    final transaction = TransactionModel(
      id: 'TXN${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      amount: amount,
      description: description,
      timestamp: DateTime.now(),
      reference: reference ?? (type == 'credit' ? 'CREDIT' : 'PAYMENT'),
      status: 'completed',
    );

    _transactions.insert(0, transaction);

    // Keep only last 100 transactions
    if (_transactions.length > 100) {
      _transactions.removeRange(100, _transactions.length);
    }
  }

  void addTransaction(TransactionModel transaction) {
    _transactions.insert(0, transaction);

    if (transaction.type == 'debit') {
      _balance -= transaction.amount;
    } else {
      _balance += transaction.amount;
    }

    _saveWalletData();
    notifyListeners();
  }

  void addManualTransaction({
    required String type,
    required double amount,
    required String description,
  }) {
    if (type == 'credit') {
      addBalance(amount, description: description);
    } else if (type == 'debit') {
      deductBalance(amount, description: description);
    }
  }

  // ==================== ASYNC OPERATIONS ====================

  Future<void> fetchBalance() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));
    await _loadWalletData();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchTransactions() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));
    await _loadWalletData();

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addMoney(double amount, {String? reference}) async {
    if (amount <= 0) return false;

    try {
      _isLoading = true;
      notifyListeners();

      await Future.delayed(const Duration(seconds: 1));

      _balance += amount;

      final transaction = TransactionModel(
        id: 'TXN${DateTime.now().millisecondsSinceEpoch}',
        type: 'credit',
        amount: amount,
        description: 'Money added to wallet',
        timestamp: DateTime.now(),
        reference: reference ?? 'BANK_TRANSFER',
        status: 'completed',
      );

      _transactions.insert(0, transaction);
      await _saveWalletData();

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error adding money: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendMoney(double amount, String receiverUpiId, {String? description}) async {
    if (amount <= 0 || amount > _balance) return false;

    try {
      _isLoading = true;
      notifyListeners();

      await Future.delayed(const Duration(seconds: 2));

      _balance -= amount;

      final transaction = TransactionModel(
        id: 'TXN${DateTime.now().millisecondsSinceEpoch}',
        type: 'debit',
        amount: amount,
        description: description ?? 'Payment to $receiverUpiId',
        timestamp: DateTime.now(),
        reference: receiverUpiId,
        status: 'completed',
      );

      _transactions.insert(0, transaction);
      await _saveWalletData();

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error sending money: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendMoneyNamed({
    required String receiverUpiId,
    required double amount,
    String? description,
  }) async {
    return sendMoney(amount, receiverUpiId, description: description);
  }

  /// Process shopping payment (VOICE CHECKOUT COMPATIBLE)
  /// This is the main method for voice "Checkout with wallet"
  Future<bool> processShoppingPayment({
    required double amount,
    required String orderId,
    String? description,
  }) async {
    if (amount <= 0 || amount > _balance) return false;

    try {
      _isLoading = true;
      notifyListeners();

      await Future.delayed(const Duration(seconds: 1));

      _balance -= amount;

      final transaction = TransactionModel(
        id: 'TXN${DateTime.now().millisecondsSinceEpoch}',
        type: 'debit',
        amount: amount,
        description: description ?? 'Shopping Order #$orderId',
        timestamp: DateTime.now(),
        reference: orderId,
        status: 'completed',
      );

      _transactions.insert(0, transaction);
      await _saveWalletData();

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error processing shopping payment: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> receiveMoney({
    required double amount,
    required String description,
    String? reference,
  }) async {
    if (amount <= 0) return false;

    try {
      _isLoading = true;
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 500));

      _balance += amount;

      final transaction = TransactionModel(
        id: 'TXN${DateTime.now().millisecondsSinceEpoch}',
        type: 'credit',
        amount: amount,
        description: description,
        timestamp: DateTime.now(),
        reference: reference,
        status: 'completed',
      );

      _transactions.insert(0, transaction);
      await _saveWalletData();

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error receiving money: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ==================== PAYMENT PROCESSING ====================

  bool processPayment({
    required double amount,
    String? description,
    String? orderId,
  }) {
    if (!hasEnoughBalance(amount)) {
      debugPrint('❌ Payment failed: Insufficient balance');
      return false;
    }

    deductBalance(amount, description: description ?? (orderId != null ? 'Order #$orderId' : 'Payment'));
    debugPrint('✅ Payment processed: ₹$amount');
    return true;
  }

  void refundPayment({
    required double amount,
    required String description,
  }) {
    addBalance(amount, description: description);
    debugPrint('✅ Refund processed: ₹$amount - $description');
  }

  // ==================== TRANSACTION QUERIES ====================

  List<TransactionModel> getRecentTransactions({int limit = 10, int count = 10}) {
    return _transactions.take(limit > 0 ? limit : count).toList();
  }

  List<TransactionModel> getTransactionsByType(String type) {
    return _transactions.where((t) => t.type == type).toList();
  }

  List<TransactionModel> getTransactionsByDateRange(
      DateTime start,
      DateTime end,
      ) {
    return _transactions.where((t) {
      return t.timestamp.isAfter(start) && t.timestamp.isBefore(end);
    }).toList();
  }

  TransactionModel? getTransactionById(String transactionId) {
    try {
      return _transactions.firstWhere((t) => t.id == transactionId);
    } catch (e) {
      return null;
    }
  }

  List<TransactionModel> searchTransactions(String query) {
    final lowerQuery = query.toLowerCase();
    return _transactions.where((t) {
      return t.description.toLowerCase().contains(lowerQuery) ||
          (t.reference?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  // ==================== STATISTICS ====================

  double getTotalCredit() {
    return _transactions
        .where((t) => t.type == 'credit')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getTotalDebit() {
    return _transactions
        .where((t) => t.type == 'debit')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalSpent => getTotalDebit();
  double get totalReceived => getTotalCredit();

  Map<String, double> getMonthlyStats() {
    final now = DateTime.now();
    final thisMonth = _transactions.where((t) {
      return t.timestamp.year == now.year && t.timestamp.month == now.month;
    });

    final credit = thisMonth
        .where((t) => t.type == 'credit')
        .fold(0.0, (sum, t) => sum + t.amount);

    final debit = thisMonth
        .where((t) => t.type == 'debit')
        .fold(0.0, (sum, t) => sum + t.amount);

    return {
      'credit': credit,
      'debit': debit,
      'net': credit - debit,
    };
  }

  // ==================== UPI MANAGEMENT ====================

  Future<bool> updateUpiId(String newUpiId) async {
    if (newUpiId.isEmpty || !newUpiId.contains('@')) return false;

    try {
      _upiId = newUpiId;
      await _saveWalletData();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating UPI ID: $e');
      return false;
    }
  }

  // ==================== WALLET MANAGEMENT ====================

  Future<void> clearTransactions() async {
    _transactions.clear();
    await _saveWalletData();
    debugPrint('All transactions cleared');
    notifyListeners();
  }

  Future<void> resetWallet({double initialBalance = 5000.0}) async {
    _balance = initialBalance;
    _upiId = 'user@paytm';
    _initializeSampleTransactions();
    await _saveWalletData();
    debugPrint('Wallet reset to ₹$initialBalance');
    notifyListeners();
  }

  Future<void> refreshWallet() async {
    await _loadWalletData();
  }

  // ==================== CONVERSION HELPERS ====================

  List<Map<String, dynamic>> getTransactionsAsMapList() {
    return _transactions.map((t) => t.toJson()).toList();
  }

  Map<String, dynamic> getWalletSummary() {
    return {
      'balance': _balance,
      'upiId': _upiId,
      'totalTransactions': _transactions.length,
      'totalCredit': getTotalCredit(),
      'totalDebit': getTotalDebit(),
      'recentTransactions': _transactions
          .take(5)
          .map((t) => t.toJson())
          .toList(),
    };
  }

  // ==================== DEBUG ====================

  void printWalletInfo() {
    debugPrint('========== WALLET INFO ==========');
    debugPrint('Balance: ₹$_balance');
    debugPrint('UPI ID: $_upiId');
    debugPrint('Total Transactions: ${_transactions.length}');
    debugPrint('Total Credit: ₹${getTotalCredit()}');
    debugPrint('Total Debit: ₹${getTotalDebit()}');
    debugPrint('=================================');
  }

  void printRecentTransactions({int count = 5}) {
    debugPrint('========== RECENT TRANSACTIONS ==========');
    final recent = getRecentTransactions(limit: count);
    for (var i = 0; i < recent.length; i++) {
      final t = recent[i];
      final symbol = t.type == 'credit' ? '+' : '-';
      debugPrint('${i + 1}. $symbol₹${t.amount} - ${t.description}');
      debugPrint('   Reference: ${t.reference ?? "N/A"}');
    }
    debugPrint('=========================================');
  }
}