import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/return_refund_model.dart';
import '../provider/return_refund_provider.dart';

class ReturnStatusScreen extends StatelessWidget {
  final String returnId;

  const ReturnStatusScreen({
    super.key,
    required this.returnId,
  });

  @override
  Widget build(BuildContext context) {
    final returnProvider = Provider.of<ReturnRefundProvider>(context);
    final returnRequest = returnProvider.getReturnById(returnId);

    if (returnRequest == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Return Status'),
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Return request not found'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Return Status'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple, Colors.purple.shade300],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getStatusIcon(returnRequest.status),
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              returnRequest.statusText,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Return ID: ${returnRequest.id}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Product Info
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      returnRequest.productImage,
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
                          returnRequest.productName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Qty: ${returnRequest.quantity}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Return Timeline
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Return Timeline',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTimelineItem(
                    'Return Requested',
                    returnRequest.requestedAt,
                    true,
                    Icons.receipt_long,
                    isFirst: true,
                  ),
                  if (returnRequest.approvedAt != null)
                    _buildTimelineItem(
                      'Return Approved',
                      returnRequest.approvedAt!,
                      true,
                      Icons.check_circle,
                    ),
                  if (returnRequest.pickedUpAt != null)
                    _buildTimelineItem(
                      'Product Picked Up',
                      returnRequest.pickedUpAt!,
                      true,
                      Icons.local_shipping,
                    ),
                  if (returnRequest.status == ReturnStatus.refundInitiated)
                    _buildTimelineItem(
                      'Refund Initiated',
                      DateTime.now(),
                      true,
                      Icons.account_balance_wallet,
                    ),
                  if (returnRequest.refundedAt != null)
                    _buildTimelineItem(
                      'Refund Completed',
                      returnRequest.refundedAt!,
                      true,
                      Icons.done_all,
                      isLast: true,
                    ),
                  if (returnRequest.status == ReturnStatus.pending)
                    _buildTimelineItem(
                      'Pending Approval',
                      null,
                      false,
                      Icons.hourglass_empty,
                      isLast: true,
                    ),
                  if (returnRequest.status == ReturnStatus.rejected)
                    _buildTimelineItem(
                      'Return Rejected',
                      DateTime.now(),
                      true,
                      Icons.cancel,
                      isLast: true,
                      isRejected: true,
                    ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Return Details
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Return Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('Reason', returnRequest.reasonText),
                  _buildDetailRow(
                    'Refund Amount',
                    '₹${returnRequest.refundAmount.toStringAsFixed(0)}',
                  ),
                  _buildDetailRow(
                    'Refund Method',
                    returnRequest.refundMethod == RefundMethod.wallet
                        ? 'Wallet'
                        : 'Original Payment',
                  ),
                  if (returnRequest.trackingId != null)
                    _buildDetailRow('Tracking ID', returnRequest.trackingId!),
                  if (returnRequest.rejectionReason != null)
                    _buildDetailRow(
                      'Rejection Reason',
                      returnRequest.rejectionReason!,
                    ),
                  if (returnRequest.additionalComments != null &&
                      returnRequest.additionalComments!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Comments',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            returnRequest.additionalComments!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons
            if (returnRequest.status == ReturnStatus.pending)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      _showCancelDialog(context, returnRequest.id);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Cancel Return Request',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
      String title,
      DateTime? dateTime,
      bool isCompleted,
      IconData icon, {
        bool isFirst = false,
        bool isLast = false,
        bool isRejected = false,
      }) {
    final color = isRejected
        ? Colors.red
        : isCompleted
        ? Colors.green
        : Colors.grey;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            if (!isFirst)
              Container(
                width: 2,
                height: 20,
                color: isCompleted ? Colors.green : Colors.grey[300],
              ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted ? color : Colors.grey[100],
                shape: BoxShape.circle,
                border: Border.all(
                  color: color,
                  width: 2,
                ),
              ),
              child: Icon(
                icon,
                size: 16,
                color: isCompleted ? Colors.white : Colors.grey,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? Colors.green : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              top: 4,
              bottom: isLast ? 0 : 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isCompleted ? Colors.black87 : Colors.grey[600],
                  ),
                ),
                if (dateTime != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(ReturnStatus status) {
    switch (status) {
      case ReturnStatus.pending:
        return Icons.hourglass_empty;
      case ReturnStatus.approved:
        return Icons.check_circle;
      case ReturnStatus.rejected:
        return Icons.cancel;
      case ReturnStatus.pickedUp:
        return Icons.local_shipping;
      case ReturnStatus.refundInitiated:
        return Icons.account_balance_wallet;
      case ReturnStatus.refundCompleted:
        return Icons.done_all;
      case ReturnStatus.cancelled:
        return Icons.block;
    }
  }

  void _showCancelDialog(BuildContext context, String returnId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Return Request'),
        content:
        const Text('Are you sure you want to cancel this return request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              final returnProvider =
              Provider.of<ReturnRefundProvider>(context, listen: false);
              await returnProvider.cancelReturnRequest(returnId);
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
            const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}