import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/return_refund_model.dart';
import '../provider/return_refund_provider.dart';
import '../provider/wallet_provider.dart';

class ReturnRequestScreen extends StatefulWidget {
  final String orderId;
  final String orderItemId;
  final String productId;
  final String productName;
  final String productImage;
  final double price;
  final int quantity;

  const ReturnRequestScreen({
    super.key,
    required this.orderId,
    required this.orderItemId,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.price,
    required this.quantity,
  });

  @override
  State<ReturnRequestScreen> createState() => _ReturnRequestScreenState();
}

class _ReturnRequestScreenState extends State<ReturnRequestScreen> {
  ReturnReason? selectedReason;
  RefundMethod selectedRefundMethod = RefundMethod.wallet;
  final TextEditingController commentsController = TextEditingController();
  bool isSubmitting = false;

  final List<Map<String, dynamic>> reasons = [
    {
      'reason': ReturnReason.defectiveProduct,
      'title': 'Defective Product',
      'icon': Icons.broken_image,
    },
    {
      'reason': ReturnReason.wrongItem,
      'title': 'Wrong Item Delivered',
      'icon': Icons.swap_horiz,
    },
    {
      'reason': ReturnReason.sizeMismatch,
      'title': 'Size Issue',
      'icon': Icons.straighten,
    },
    {
      'reason': ReturnReason.colorMismatch,
      'title': 'Color Mismatch',
      'icon': Icons.palette,
    },
    {
      'reason': ReturnReason.qualityIssue,
      'title': 'Quality Issue',
      'icon': Icons.star_border,
    },
    {
      'reason': ReturnReason.damagedProduct,
      'title': 'Damaged Product',
      'icon': Icons.report_problem,
    },
    {
      'reason': ReturnReason.notAsDescribed,
      'title': 'Not As Described',
      'icon': Icons.description,
    },
    {
      'reason': ReturnReason.changedMind,
      'title': 'Changed Mind',
      'icon': Icons.psychology,
    },
    {
      'reason': ReturnReason.other,
      'title': 'Other',
      'icon': Icons.more_horiz,
    },
  ];

  @override
  void dispose() {
    commentsController.dispose();
    super.dispose();
  }

  Future<void> _submitReturnRequest() async {
    if (selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a return reason'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => isSubmitting = true);

    final returnProvider =
    Provider.of<ReturnRefundProvider>(context, listen: false);

    final success = await returnProvider.createReturnRequest(
      orderId: widget.orderId,
      orderItemId: widget.orderItemId,
      productId: widget.productId,
      productName: widget.productName,
      productImage: widget.productImage,
      price: widget.price,
      quantity: widget.quantity,
      reason: selectedReason!,
      refundMethod: selectedRefundMethod,
      additionalComments: commentsController.text.trim(),
    );

    setState(() => isSubmitting = false);

    if (success && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green[600],
                  size: 60,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Return Request Submitted!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Your return request has been submitted successfully. We will process it within 24-48 hours.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Close return screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('OK'),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit return request'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final refundAmount = widget.price * widget.quantity;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Return Request'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Info
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            widget.productImage,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[200],
                                child: const Icon(Icons.image_not_supported),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.productName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Qty: ${widget.quantity}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₹${widget.price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Refund Amount
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Refund Amount',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '₹${refundAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Return Reason
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Return Reason',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...reasons.map((reasonData) {
                          final isSelected =
                              selectedReason == reasonData['reason'];
                          return InkWell(
                            onTap: () {
                              setState(() {
                                selectedReason = reasonData['reason'];
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.purple[50]
                                    : Colors.grey[50],
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.purple
                                      : Colors.grey[200]!,
                                  width: isSelected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    reasonData['icon'],
                                    color: isSelected
                                        ? Colors.purple
                                        : Colors.grey[600],
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      reasonData['title'],
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? Colors.purple[700]
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.purple,
                                      size: 24,
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Additional Comments
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Additional Comments (Optional)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: commentsController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Describe the issue in detail...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Colors.purple,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Refund Method
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Refund Method',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        RadioListTile<RefundMethod>(
                          value: RefundMethod.wallet,
                          groupValue: selectedRefundMethod,
                          onChanged: (value) {
                            setState(() {
                              selectedRefundMethod = value!;
                            });
                          },
                          title: const Row(
                            children: [
                              Icon(Icons.account_balance_wallet,
                                  color: Colors.purple),
                              SizedBox(width: 12),
                              Text('Refund to Wallet (Instant)'),
                            ],
                          ),
                          activeColor: Colors.purple,
                        ),
                        RadioListTile<RefundMethod>(
                          value: RefundMethod.originalPayment,
                          groupValue: selectedRefundMethod,
                          onChanged: (value) {
                            setState(() {
                              selectedRefundMethod = value!;
                            });
                          },
                          title: const Row(
                            children: [
                              Icon(Icons.payment, color: Colors.purple),
                              SizedBox(width: 12),
                              Text('Original Payment Method (5-7 days)'),
                            ],
                          ),
                          activeColor: Colors.purple,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Submit Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.2),
                  spreadRadius: 2,
                  blurRadius: 6,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : _submitReturnRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'Submit Return Request',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}