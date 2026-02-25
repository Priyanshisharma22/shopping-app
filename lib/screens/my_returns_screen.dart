import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/return_refund_model.dart';
import '../provider/return_refund_provider.dart';
import 'return_status_screen.dart';

class MyReturnsScreen extends StatefulWidget {
  const MyReturnsScreen({super.key});

  @override
  State<MyReturnsScreen> createState() => _MyReturnsScreenState();
}

class _MyReturnsScreenState extends State<MyReturnsScreen> {
  String selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReturnRefundProvider>(context, listen: false)
          .fetchReturnRequests('user_123');
    });
  }

  List<ReturnRequest> _getFilteredReturns(List<ReturnRequest> returns) {
    switch (selectedFilter) {
      case 'pending':
        return returns
            .where((r) => r.status == ReturnStatus.pending)
            .toList();
      case 'approved':
        return returns
            .where((r) => r.status == ReturnStatus.approved)
            .toList();
      case 'completed':
        return returns
            .where((r) => r.status == ReturnStatus.refundCompleted)
            .toList();
      case 'rejected':
        return returns
            .where((r) => r.status == ReturnStatus.rejected)
            .toList();
      default:
        return returns;
    }
  }

  @override
  Widget build(BuildContext context) {
    final returnProvider = Provider.of<ReturnRefundProvider>(context);
    final filteredReturns = _getFilteredReturns(returnProvider.returnRequests);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Returns'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', 'all', returnProvider.returnRequests.length),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'Pending',
                    'pending',
                    returnProvider.returnRequests
                        .where((r) => r.status == ReturnStatus.pending)
                        .length,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'Approved',
                    'approved',
                    returnProvider.returnRequests
                        .where((r) => r.status == ReturnStatus.approved)
                        .length,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'Completed',
                    'completed',
                    returnProvider.returnRequests
                        .where((r) => r.status == ReturnStatus.refundCompleted)
                        .length,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'Rejected',
                    'rejected',
                    returnProvider.returnRequests
                        .where((r) => r.status == ReturnStatus.rejected)
                        .length,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Returns List
          Expanded(
            child: returnProvider.isLoading && filteredReturns.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filteredReturns.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: filteredReturns.length,
              itemBuilder: (context, index) {
                final returnRequest = filteredReturns[index];
                return _buildReturnCard(returnRequest);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = selectedFilter == value;
    return FilterChip(
      label: Text('$label${count > 0 ? ' ($count)' : ''}'),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          selectedFilter = value;
        });
      },
      selectedColor: Colors.purple[100],
      checkmarkColor: Colors.purple[700],
      labelStyle: TextStyle(
        color: isSelected ? Colors.purple[700] : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;

    switch (selectedFilter) {
      case 'pending':
        message = 'No pending returns';
        icon = Icons.hourglass_empty;
        break;
      case 'approved':
        message = 'No approved returns';
        icon = Icons.check_circle_outline;
        break;
      case 'completed':
        message = 'No completed returns';
        icon = Icons.done_all;
        break;
      case 'rejected':
        message = 'No rejected returns';
        icon = Icons.cancel_outlined;
        break;
      default:
        message = 'No return requests yet';
        icon = Icons.keyboard_return;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 100,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          if (selectedFilter == 'all')
            Text(
              'All your return requests will appear here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReturnCard(ReturnRequest returnRequest) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReturnStatusScreen(
                returnId: returnRequest.id,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Badge & Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(returnRequest.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(returnRequest.status),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(returnRequest.status),
                          size: 14,
                          color: _getStatusColor(returnRequest.status),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          returnRequest.statusText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(returnRequest.status),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatDate(returnRequest.requestedAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Product Info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      returnRequest.productImage,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 70,
                          height: 70,
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
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Qty: ${returnRequest.quantity}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Refund: ₹${returnRequest.refundAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Return Reason
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Reason: ${returnRequest.reasonText}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Action Button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReturnStatusScreen(
                            returnId: returnRequest.id,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('View Details'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.purple,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(ReturnStatus status) {
    switch (status) {
      case ReturnStatus.pending:
        return Colors.orange;
      case ReturnStatus.approved:
        return Colors.blue;
      case ReturnStatus.rejected:
        return Colors.red;
      case ReturnStatus.pickedUp:
        return Colors.indigo;
      case ReturnStatus.refundInitiated:
        return Colors.purple;
      case ReturnStatus.refundCompleted:
        return Colors.green;
      case ReturnStatus.cancelled:
        return Colors.grey;
    }
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}