import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/auth_provider.dart';
import '../provider/profile_provider.dart';
import '../widgets/floating_voice_assistant.dart'; // ADDED: Voice Assistant Widget

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _nameController.text = authProvider.userName ?? '';
    _emailController.text = authProvider.userEmail ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.isEmpty) {
      _showError('Name cannot be empty');
      return;
    }

    // Email validation
    if (_emailController.text.isNotEmpty) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(_emailController.text)) {
        _showError('Please enter a valid email address');
        return;
      }
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.updateProfile(
      name: _nameController.text,
      email: _emailController.text.isEmpty ? null : _emailController.text,
    );

    if (success) {
      setState(() => _isEditing = false);
      _showSuccess('Profile updated successfully');
    } else {
      _showError('Failed to update profile');
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // ADDED: Voice Assistant Button
          IconButton(
            icon: const Icon(Icons.mic, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/voiceAgent');
            },
            tooltip: 'Voice Assistant',
          ),
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Edit Profile',
            ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return SingleChildScrollView(
            child: Column(
              children: [
                // Profile Header
                Container(
                  color: Colors.purple,
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      // Profile Picture
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: Text(
                          authProvider.userName?.substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(
                            fontSize: 60,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Name
                      Text(
                        authProvider.userName ?? 'User Name',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Email
                      Text(
                        authProvider.userEmail?.isNotEmpty == true
                            ? authProvider.userEmail!
                            : 'email@example.com',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Phone
                      Text(
                        '+91 ${authProvider.userPhone ?? 'XXXXXXXXXX'}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Edit Profile Form (when editing)
                if (_isEditing)
                  _buildEditForm()
                else ...[
                  // Account Information Card
                  _buildAccountInfo(authProvider),

                  const SizedBox(height: 10),

                  // Menu Options
                  _buildMenuSection('My Activity', [
                    _MenuOption(
                      icon: Icons.shopping_bag_outlined,
                      title: 'My Orders',
                      subtitle: 'Check your order status',
                      onTap: () {
                        Navigator.pushNamed(context, '/pastOrders');
                      },
                    ),
                    _MenuOption(
                      icon: Icons.favorite_outline,
                      title: 'My Wishlist',
                      subtitle: 'Your favorite products',
                      onTap: () {
                        Navigator.pushNamed(context, '/wishlist');
                      },
                    ),
                    _MenuOption(
                      icon: Icons.shopping_cart_outlined,
                      title: 'My Cart',
                      subtitle: 'Items in your cart',
                      onTap: () {
                        Navigator.pushNamed(context, '/cart');
                      },
                    ),
                  ]),

                  _buildMenuSection('AI Features', [
                    // ADDED: Voice Shopping Option
                    _MenuOption(
                      icon: Icons.mic,
                      title: 'Voice Shopping',
                      subtitle: 'Shop with voice commands',
                      iconColor: Colors.blue,
                      onTap: () {
                        Navigator.pushNamed(context, '/voiceAgent');
                      },
                    ),
                    _MenuOption(
                      icon: Icons.psychology,
                      title: 'Smart Cart Optimizer',
                      subtitle: 'AI-powered savings & bundles',
                      iconColor: Colors.purple,
                      onTap: () {
                        Navigator.pushNamed(context, '/cartOptimizer');
                      },
                    ),
                    _MenuOption(
                      icon: Icons.support_agent,
                      title: 'AI Support',
                      subtitle: '24/7 intelligent assistance',
                      iconColor: Colors.orange,
                      onTap: () {
                        Navigator.pushNamed(context, '/support');
                      },
                    ),
                  ]),

                  _buildMenuSection('Account Settings', [
                    _MenuOption(
                      icon: Icons.location_on_outlined,
                      title: 'Saved Addresses',
                      subtitle: 'Manage your delivery addresses',
                      onTap: () {
                        Navigator.pushNamed(context, '/addresses');
                      },
                    ),
                    _MenuOption(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Wallet',
                      subtitle: 'Manage your wallet',
                      onTap: () {
                        Navigator.pushNamed(context, '/wallet');
                      },
                    ),
                    _MenuOption(
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      subtitle: 'View your notifications',
                      onTap: () {
                        Navigator.pushNamed(context, '/notifications');
                      },
                    ),
                  ]),

                  _buildMenuSection('Support', [
                    _MenuOption(
                      icon: Icons.help_outline,
                      title: 'Help & Support',
                      subtitle: 'Get help with your orders',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Help & Support coming soon'),
                          ),
                        );
                      },
                    ),
                    _MenuOption(
                      icon: Icons.info_outline,
                      title: 'About Us',
                      subtitle: 'Learn more about us',
                      onTap: () {
                        _showAboutDialog();
                      },
                    ),
                  ]),

                  const SizedBox(height: 10),

                  // Logout Button
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout),
                        label: const Text('Logout'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ],
            ),
          );
        },
      ),

      // ADDED: Floating Voice Assistant Button
      floatingActionButton: const FloatingVoiceAssistant(),
    );
  }

  Widget _buildEditForm() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Edit Profile',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() => _isEditing = false);
                    _loadUserData(); // Reset to original values
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfo(AuthProvider authProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('User ID', authProvider.userId ?? 'N/A'),
          const SizedBox(height: 8),
          _buildInfoRow(
            'Member Since',
            _getMemberSinceDate(authProvider.userId),
          ),
          const SizedBox(height: 8),
          _buildInfoRow('Account Status', 'Active', valueColor: Colors.green),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuSection(String title, List<_MenuOption> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        Container(
          color: Colors.white,
          child: Column(
            children: options.map((option) {
              return Column(
                children: [
                  ListTile(
                    leading: Icon(
                      option.icon,
                      color: option.iconColor ?? Colors.purple,
                    ),
                    title: Text(
                      option.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      option.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: option.onTap,
                  ),
                  if (option != options.last)
                    Divider(height: 1, color: Colors.grey[200]),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _getMemberSinceDate(String? userId) {
    if (userId == null) return 'Unknown';
    try {
      final timestamp = userId.split('_').last;
      final date = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Meesho Mock'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Meesho Mock App',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text('Version: 1.0.0'),
            SizedBox(height: 16),
            Text(
              'A comprehensive e-commerce application with integrated wallet functionality and AI-powered features.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              '© 2024 Meesho Mock. All rights reserved.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _MenuOption {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor; // ADDED: Optional icon color

  _MenuOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor, // ADDED: Optional parameter
  });
}