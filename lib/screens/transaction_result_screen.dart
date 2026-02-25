import 'package:flutter/material.dart';

class TransactionResultScreen extends StatelessWidget {
  final String receiverUpiId;
  final double amount;
  final bool success;

  const TransactionResultScreen({
    super.key,
    required this.receiverUpiId,
    required this.amount,
    required this.success,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Transaction Result"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                success ? Icons.check_circle : Icons.cancel,
                size: 90,
                color: success ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 20),

              Text(
                success ? "Payment Successful" : "Payment Failed",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                "₹${amount.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 20),
              ),

              const SizedBox(height: 8),

              Text(
                "Paid to: $receiverUpiId",
                style: const TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    success ? Colors.green : Colors.red,
                    padding:
                    const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text("Back to Wallet"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}