import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/order_model_enhanced.dart';  // ← CHANGED from order_item_model.dart

class OrderTrackingScreen extends StatefulWidget {
  final OrderDetail order;

  const OrderTrackingScreen({
    super.key,
    required this.order,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text(
          'Track Order',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey[200],
            height: 1,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              _shareTracking();
            },
          ),
          IconButton(
            icon: const Icon(Icons.headset_mic_outlined),
            onPressed: () {
              _showHelpBottomSheet(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Status Header with Animation
            _buildAnimatedStatusHeader(),

            const SizedBox(height: 8),

            // Tracking ID Card
            if (widget.order.trackingId != null) _buildTrackingIdCard(),

            if (widget.order.trackingId != null) const SizedBox(height: 8),

            // Expected Delivery Banner
            if (widget.order.status != OrderStatus.delivered &&
                widget.order.status != OrderStatus.cancelled)
              _buildExpectedDeliveryBanner(),

            if (widget.order.status != OrderStatus.delivered &&
                widget.order.status != OrderStatus.cancelled)
              const SizedBox(height: 8),

            // Tabs for Timeline and Map
            _buildTabSection(),

            const SizedBox(height: 8),

            // Order Items Summary
            _buildOrderItemsSummary(),

            const SizedBox(height: 8),

            // Delivery Address
            _buildDeliveryAddressCard(),

            const SizedBox(height: 8),

            // Delivery Partner Info (if shipped)
            if (widget.order.status == OrderStatus.shipped)
              _buildDeliveryPartnerCard(),

            if (widget.order.status == OrderStatus.shipped)
              const SizedBox(height: 8),

            // Important Information
            _buildImportantInfo(),

            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildAnimatedStatusHeader() {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    String statusSubtext;

    switch (widget.order.status) {
      case OrderStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        statusText = 'Order Placed';
        statusSubtext = 'Your order has been placed successfully';
        break;
      case OrderStatus.confirmed:
        statusColor = Colors.blue;
        statusIcon = Icons.check_circle_outline;
        statusText = 'Order Confirmed';
        statusSubtext = 'Seller is preparing your order';
        break;
      case OrderStatus.shipped:
        statusColor = Colors.purple;
        statusIcon = Icons.local_shipping_outlined;
        statusText = 'Out for Delivery';
        statusSubtext = 'Your package is on the way';
        break;
      case OrderStatus.outForDelivery:
        statusColor = Colors.blue;
        statusIcon = Icons.delivery_dining;
        statusText = 'Out for Delivery';
        statusSubtext = 'Your package is out for delivery';
        break;
      case OrderStatus.delivered:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Delivered Successfully';
        statusSubtext = 'Your order has been delivered';
        break;
      case OrderStatus.cancelled:
        statusColor = Colors.red;
        statusIcon = Icons.cancel_outlined;
        statusText = 'Order Cancelled';
        statusSubtext = 'Your order has been cancelled';
        break;
      case OrderStatus.returned:
        statusColor = Colors.grey;
        statusIcon = Icons.keyboard_return;
        statusText = 'Order Returned';
        statusSubtext = 'Your order has been returned';
        break;
      case OrderStatus.refunded:
        statusColor = Colors.teal;
        statusIcon = Icons.account_balance_wallet;
        statusText = 'Refunded';
        statusSubtext = 'Your refund has been processed';
        break;
    }

    return Container(
      color: statusColor.withOpacity(0.1),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            builder: (context, double value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 48),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            statusSubtext,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Order ID: ${widget.order.orderId}',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingIdCard() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.qr_code, color: Colors.purple[700], size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tracking ID',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.order.trackingId!,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 20),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: widget.order.trackingId!));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tracking ID copied to clipboard'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExpectedDeliveryBanner() {
    return Container(
      color: Colors.green.withOpacity(0.1),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.schedule, color: Colors.green[700], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Expected Delivery',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[900],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.order.deliveryDate != null
                      ? DateFormat('EEEE, dd MMMM yyyy')
                      .format(widget.order.deliveryDate!)
                      : 'Will be updated soon',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[900],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSection() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: Colors.purple,
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: Colors.purple,
            labelStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
            tabs: const [
              Tab(text: 'Timeline'),
              Tab(text: 'Map View'),
            ],
          ),
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTrackingTimeline(),
                _buildMapView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingTimeline() {
    final trackingSteps = _getTrackingSteps();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Journey',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ...trackingSteps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isLast = index == trackingSteps.length - 1;
            return _buildTimelineStep(step, isLast);
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(TrackingStep step, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: step.isCompleted ? Colors.green : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: step.isCompleted ? Colors.green : Colors.grey[400]!,
                    width: step.isCompleted ? 3 : 2,
                  ),
                ),
                child: step.isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : step.isActive
                    ? Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple,
                    shape: BoxShape.circle,
                  ),
                )
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 3,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: step.isCompleted
                          ? Colors.green
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),

          // Step content
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          step.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: step.isCompleted || step.isActive
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: step.isCompleted || step.isActive
                                ? Colors.black87
                                : Colors.grey[600],
                          ),
                        ),
                      ),
                      if (step.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Current',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple[700],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                  if (step.timestamp != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd MMM, hh:mm a')
                              .format(step.timestamp!),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (step.location != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            step.location!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    return Container(
      color: Colors.grey[200],
      child: Stack(
        children: [
          // Placeholder map
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map_outlined, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Live tracking map',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Track your delivery in real-time',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          // Map controls
          Positioned(
            bottom: 16,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoom_in',
                  onPressed: () {},
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.add, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_out',
                  onPressed: () {},
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.remove, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'my_location',
                  onPressed: () {},
                  backgroundColor: Colors.white,
                  child:
                  const Icon(Icons.my_location_outlined, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemsSummary() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${widget.order.items.length} Item${widget.order.items.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '₹${widget.order.totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.order.items.length,
              itemBuilder: (context, index) {
                final item = widget.order.items[index];
                return Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 12, bottom: 16),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[100],
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item.productImage,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.image, size: 30);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Qty: ${item.quantity}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryAddressCard() {
    // Use compatibility getters to access address fields
    final addressName = widget.order.deliveryAddress.name ??
        widget.order.deliveryAddress.fullName;
    final addressPhone = widget.order.deliveryAddress.phone ??
        widget.order.deliveryAddress.phoneNumber;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery Address',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.purple[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        addressName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.order.deliveryAddress.fullAddress,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Text(
                            addressPhone,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryPartnerCard() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery Partner',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person, color: Colors.blue[700], size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Delivery Executive',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Will be assigned soon',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.phone, color: Colors.blue[700]),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Delivery partner will be assigned soon'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportantInfo() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Important Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoTile(
            Icons.check_circle_outline,
            'Quality Check',
            'All products go through quality check before dispatch',
            Colors.green,
          ),
          const SizedBox(height: 10),
          _buildInfoTile(
            Icons.verified_user_outlined,
            'Secure Packaging',
            'Your order is packed securely to prevent damage',
            Colors.blue,
          ),
          const SizedBox(height: 10),
          _buildInfoTile(
            Icons.headset_mic_outlined,
            '24/7 Support',
            'Need help? Our support team is available 24/7',
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
      IconData icon, String title, String subtitle, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  _showHelpBottomSheet(context);
                },
                icon: const Icon(Icons.help_outline, size: 18),
                label: const Text(
                  'Need Help?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.purple,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Colors.purple),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            if (widget.order.status == OrderStatus.shipped ||
                widget.order.status == OrderStatus.outForDelivery) ...[
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showCallDeliveryDialog();
                  },
                  icon: const Icon(Icons.phone, size: 18),
                  label: const Text(
                    'Call',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<TrackingStep> _getTrackingSteps() {
    final steps = <TrackingStep>[];

    // Order Placed
    steps.add(TrackingStep(
      title: 'Order Placed',
      description: 'Your order has been placed successfully',
      timestamp: widget.order.orderDate,
      location: 'Online',
      isCompleted: true,
      isActive: widget.order.status == OrderStatus.pending,
    ));

    // Order Confirmed
    if (widget.order.status.index >= OrderStatus.confirmed.index) {
      steps.add(TrackingStep(
        title: 'Order Confirmed',
        description: 'Seller has confirmed your order',
        timestamp: widget.order.orderDate.add(const Duration(hours: 2)),
        location: 'Seller Location',
        isCompleted: true,
        isActive: widget.order.status == OrderStatus.confirmed,
      ));

      // Order Packed
      steps.add(TrackingStep(
        title: 'Order Packed',
        description: 'Your order is packed and ready to ship',
        timestamp: widget.order.orderDate.add(const Duration(hours: 6)),
        location: 'Warehouse',
        isCompleted: true,
        isActive: false,
      ));
    } else {
      steps.add(TrackingStep(
        title: 'Order Confirmation',
        description: 'Waiting for seller confirmation',
        isCompleted: false,
        isActive: false,
      ));
    }

    // Order Shipped
    if (widget.order.status.index >= OrderStatus.shipped.index) {
      steps.add(TrackingStep(
        title: 'Order Shipped',
        description: 'Your package is on the way',
        timestamp: widget.order.orderDate.add(const Duration(days: 1)),
        location: 'In Transit',
        isCompleted: true,
        isActive: widget.order.status == OrderStatus.shipped,
      ));
    } else if (widget.order.status != OrderStatus.cancelled) {
      steps.add(TrackingStep(
        title: 'Order Shipping',
        description: 'Your order will be shipped soon',
        isCompleted: false,
        isActive: false,
      ));
    }

    // Out for Delivery
    if (widget.order.status.index >= OrderStatus.outForDelivery.index) {
      steps.add(TrackingStep(
        title: 'Out for Delivery',
        description: 'Package is out for delivery',
        timestamp: widget.order.deliveryDate
            ?.subtract(const Duration(hours: 4)),
        location: widget.order.deliveryAddress.city,
        isCompleted: widget.order.status.index > OrderStatus.outForDelivery.index,
        isActive: widget.order.status == OrderStatus.outForDelivery,
      ));
    } else if (widget.order.status != OrderStatus.cancelled) {
      steps.add(TrackingStep(
        title: 'Out for Delivery',
        description: 'Package will be out for delivery soon',
        isCompleted: false,
        isActive: false,
      ));
    }

    // Delivered
    if (widget.order.status == OrderStatus.delivered) {
      steps.add(TrackingStep(
        title: 'Delivered',
        description: 'Package delivered successfully',
        timestamp: widget.order.deliveryDate,
        location: widget.order.deliveryAddress.city,
        isCompleted: true,
        isActive: false,
      ));
    } else if (widget.order.status == OrderStatus.cancelled) {
      steps.add(TrackingStep(
        title: 'Order Cancelled',
        description: 'Your order has been cancelled',
        timestamp: DateTime.now(),
        isCompleted: true,
        isActive: false,
      ));
    } else {
      steps.add(TrackingStep(
        title: 'Delivery',
        description: 'Package will be delivered soon',
        isCompleted: false,
        isActive: false,
      ));
    }

    return steps;
  }

  void _shareTracking() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sharing tracking details...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showHelpBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'How can we help you?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildHelpOption(
              Icons.chat_bubble_outline,
              'Chat with Us',
              'Get instant support',
              Colors.purple,
                  () => Navigator.pop(context),
            ),
            _buildHelpOption(
              Icons.phone_outlined,
              'Call Customer Care',
              '+91 1800-XXX-XXXX',
              Colors.blue,
                  () => Navigator.pop(context),
            ),
            _buildHelpOption(
              Icons.email_outlined,
              'Email Us',
              'support@example.com',
              Colors.orange,
                  () => Navigator.pop(context),
            ),
            _buildHelpOption(
              Icons.report_problem_outlined,
              'Report an Issue',
              'Tell us what went wrong',
              Colors.red,
                  () => Navigator.pop(context),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpOption(
      IconData icon,
      String title,
      String subtitle,
      Color color,
      VoidCallback onTap,
      ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showCallDeliveryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Call Delivery Partner'),
        content: const Text(
          'Delivery partner will be assigned once the package reaches your city. You will be able to call them at that time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class TrackingStep {
  final String title;
  final String description;
  final DateTime? timestamp;
  final String? location;
  final bool isCompleted;
  final bool isActive;

  TrackingStep({
    required this.title,
    required this.description,
    this.timestamp,
    this.location,
    required this.isCompleted,
    this.isActive = false,
  });
}