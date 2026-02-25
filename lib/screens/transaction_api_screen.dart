import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../services/api_service.dart';

class TransactionApiScreen extends StatefulWidget {
  const TransactionApiScreen({super.key});

  @override
  State<TransactionApiScreen> createState() => _TransactionApiScreenState();
}

class _TransactionApiScreenState extends State<TransactionApiScreen> {
  late Future<List<TransactionModel>> futureTransactions;
  bool useMockData = true; // Toggle this to use mock data or real API

  @override
  void initState() {
    super.initState();
    futureTransactions = _loadTransactions();
  }

  // Load transactions based on mode
  Future<List<TransactionModel>> _loadTransactions() {
    // ApiService methods are static, so we call them directly
    return ApiService.fetchTransactions();
  }

  // Refresh function
  Future<void> refreshTransactions() async {
    setState(() {
      futureTransactions = _loadTransactions();
    });
  }

  // Toggle between mock and real API
  void toggleDataSource() {
    setState(() {
      useMockData = !useMockData;
      futureTransactions = _loadTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          "Transactions (API)",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          // Data source toggle
          IconButton(
            icon: Icon(useMockData ? Icons.cloud_off : Icons.cloud),
            tooltip: useMockData ? 'Using Mock Data' : 'Using API Data',
            onPressed: () {
              toggleDataSource();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    useMockData
                        ? 'Switched to Mock Data'
                        : 'Switched to API Data',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: refreshTransactions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: useMockData ? Colors.orange[50] : Colors.blue[50],
            child: Row(
              children: [
                Icon(
                  useMockData ? Icons.info_outline : Icons.cloud_done,
                  size: 20,
                  color: useMockData ? Colors.orange[700] : Colors.blue[700],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    useMockData
                        ? 'Showing mock transaction data'
                        : 'Fetching from API',
                    style: TextStyle(
                      fontSize: 13,
                      color: useMockData ? Colors.orange[900] : Colors.blue[900],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Transaction list
          Expanded(
            child: FutureBuilder<List<TransactionModel>>(
              future: futureTransactions,
              builder: (context, snapshot) {
                // Loading state
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          color: Colors.purple,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading transactions...',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Error state
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Error Loading Transactions",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "${snapshot.error}",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: refreshTransactions,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: toggleDataSource,
                            icon: const Icon(Icons.swap_horiz),
                            label: Text(
                              useMockData
                                  ? 'Try API Data'
                                  : 'Use Mock Data',
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Empty state
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No transactions found",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Your transaction history will appear here",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: refreshTransactions,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final transactions = snapshot.data!;

                // Success state - show transactions
                return RefreshIndicator(
                  onRefresh: refreshTransactions,
                  color: Colors.purple,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final t = transactions[index];
                      final bool isCredit = t.type == 'credit';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isCredit
                                  ? Colors.green[50]
                                  : Colors.red[50],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isCredit
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              color: isCredit ? Colors.green : Colors.red,
                            ),
                          ),
                          title: Text(
                            t.description,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                _formatDateTime(t.timestamp),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (t.reference != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Ref: ${t.reference}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(t.status)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  t.status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: _getStatusColor(t.status),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: Text(
                            "${isCredit ? "+" : "-"}₹${t.amount.toStringAsFixed(2)}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isCredit ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Format datetime for display
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today ${_formatTime(dateTime)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${_formatTime(dateTime)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Get status color
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}