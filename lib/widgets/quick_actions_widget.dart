import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/support_agent_provider.dart';

class QuickActionsWidget extends StatelessWidget {
  const QuickActionsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickActionChip(
                context,
                icon: Icons.location_on_outlined,
                label: 'Track Order',
                action: 'track_order',
              ),
              _buildQuickActionChip(
                context,
                icon: Icons.keyboard_return,
                label: 'Return Product',
                action: 'return_product',
              ),
              _buildQuickActionChip(
                context,
                icon: Icons.payment,
                label: 'Refund Status',
                action: 'refund_status',
              ),
              _buildQuickActionChip(
                context,
                icon: Icons.error_outline,
                label: 'Payment Issue',
                action: 'payment_issue',
              ),
              _buildQuickActionChip(
                context,
                icon: Icons.support_agent,
                label: 'Talk to Human',
                action: 'talk_to_human',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionChip(
      BuildContext context, {
        required IconData icon,
        required String label,
        required String action,
      }) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: () {
        final provider = Provider.of<SupportAgentProvider>(context, listen: false);
        provider.handleQuickAction(action);
      },
      backgroundColor: Colors.purple.shade50,
      labelStyle: const TextStyle(color: Colors.purple),
    );
  }
}