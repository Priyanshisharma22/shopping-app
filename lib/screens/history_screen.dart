import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../provider/wallet_provider.dart';
import '../models/transaction_model.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  String formatAmount(double amount) {
    if (amount < 0) {
      return "- ₹${amount.abs().toStringAsFixed(2)}";
    } else {
      return "+ ₹${amount.toStringAsFixed(2)}";
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat("dd MMM yyyy, hh:mm a");

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Transaction History",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Consumer<WalletProvider>(
        builder: (context, walletProvider, child) {
          final List<TransactionModel> transactions =
              walletProvider.transactions;

          if (transactions.isEmpty) {
            return const Center(
              child: Text(
                "No Transactions Found",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final txn = transactions[index];

              final double amount = txn.amount;
              final String status = txn.status ?? 'completed';
              final bool isSuccess = status == "SUCCESS";

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: amount < 0
                          ? Colors.red.withOpacity(0.15)
                          : Colors.green.withOpacity(0.15),
                      child: Icon(
                        amount < 0 ? Icons.arrow_upward : Icons.arrow_downward,
                        color: amount < 0 ? Colors.red : Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title + Date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            txn.description,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatter.format(txn.timestamp),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Amount + Status
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatAmount(amount),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: amount < 0 ? Colors.red : Colors.green,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          status,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSuccess ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
