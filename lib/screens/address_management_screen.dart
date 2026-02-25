import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/address_model.dart';
import '../provider/address_provider.dart';

class AddressManagementScreen extends StatefulWidget {
  const AddressManagementScreen({super.key});

  @override
  State<AddressManagementScreen> createState() =>
      _AddressManagementScreenState();
}

class _AddressManagementScreenState extends State<AddressManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AddressProvider>(context, listen: false)
          .fetchAddresses('user_123');
    });
  }

  // ─────────────────────────────────────────────
  //  Build
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final addressProvider = Provider.of<AddressProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Saved Addresses',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (addressProvider.hasAddresses)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  '${addressProvider.addressCount} saved',
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(addressProvider),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditBottomSheet(context),
        backgroundColor: Colors.purple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Address',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildBody(AddressProvider addressProvider) {
    // Initial loading
    if (addressProvider.isLoading && !addressProvider.hasAddresses) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.purple),
            SizedBox(height: 16),
            Text('Loading addresses...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // Error state
    if (addressProvider.hasError && !addressProvider.hasAddresses) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              addressProvider.errorMessage ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => addressProvider.refreshAddresses(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    // Empty state
    if (!addressProvider.hasAddresses) {
      return _buildEmptyState();
    }

    // List
    return RefreshIndicator(
      color: Colors.purple,
      onRefresh: () => addressProvider.refreshAddresses(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
        itemCount: addressProvider.addresses.length,
        itemBuilder: (context, index) {
          return _buildAddressCard(addressProvider.addresses[index]);
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Empty State
  // ─────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.purple[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_off_outlined,
              size: 72,
              color: Colors.purple[200],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Saved Addresses',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a delivery address for faster checkout',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddEditBottomSheet(context),
            icon: const Icon(Icons.add),
            label: const Text('Add New Address'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Address Card
  // ─────────────────────────────────────────────

  Widget _buildAddressCard(AddressModel address) {
    final addressProvider =
    Provider.of<AddressProvider>(context, listen: false);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: address.isDefault ? Colors.purple[200]! : Colors.grey[200]!,
          width: address.isDefault ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Row: label + default badge + menu ──
            Row(
              children: [
                _buildLabelBadge(address.label),
                if (address.isDefault) ...[
                  const SizedBox(width: 8),
                  _buildDefaultBadge(),
                ],
                const Spacer(),
                _buildPopupMenu(address, addressProvider),
              ],
            ),

            const SizedBox(height: 12),

            // ── Name ──
            Text(
              address.fullName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            // ── Address ──
            Text(
              address.fullAddressWithLandmark,
              style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.4),
            ),

            const SizedBox(height: 8),

            // ── Phone ──
            Row(
              children: [
                Icon(Icons.phone, size: 15, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Text(
                  address.phoneNumber,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ],
            ),

            // ── Set as default button (only if not default) ──
            if (!address.isDefault) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: () => addressProvider.setDefaultAddress(address.id),
                icon: const Icon(Icons.check_circle_outline, size: 17),
                label: const Text('Set as Default'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.purple,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLabelBadge(String label) {
    final IconData icon = label == 'Home'
        ? Icons.home_outlined
        : label == 'Work'
        ? Icons.work_outline
        : Icons.location_on_outlined;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.purple[700]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.purple[700],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 12, color: Colors.green[700]),
          const SizedBox(width: 4),
          Text(
            'Default',
            style: TextStyle(
              color: Colors.green[700],
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopupMenu(
      AddressModel address, AddressProvider addressProvider) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: Colors.grey[600]),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (value) async {
        if (value == 'edit') {
          _showAddEditBottomSheet(context, address: address);
        } else if (value == 'delete') {
          _showDeleteConfirmation(context, address);
        } else if (value == 'default') {
          await addressProvider.setDefaultAddress(address.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${address.label} set as default'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      },
      itemBuilder: (context) => [
        if (!address.isDefault)
          PopupMenuItem(
            value: 'default',
            child: _popupItem(Icons.check_circle_outline, 'Set as Default',
                Colors.purple),
          ),
        PopupMenuItem(
          value: 'edit',
          child: _popupItem(Icons.edit_outlined, 'Edit', Colors.blue[700]!),
        ),
        PopupMenuItem(
          value: 'delete',
          child: _popupItem(Icons.delete_outline, 'Delete', Colors.red[700]!),
        ),
      ],
    );
  }

  Widget _popupItem(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  Delete Confirmation
  // ─────────────────────────────────────────────

  void _showDeleteConfirmation(BuildContext context, AddressModel address) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Address'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to delete this address?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                address.fullAddress,
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              final addressProvider =
              Provider.of<AddressProvider>(context, listen: false);
              final success =
              await addressProvider.deleteAddress(address.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? '${address.label} address deleted'
                          : addressProvider.errorMessage ??
                          'Failed to delete address',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            icon: const Icon(Icons.delete, size: 18),
            label: const Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Add / Edit Bottom Sheet
  // ─────────────────────────────────────────────

  void _showAddEditBottomSheet(BuildContext context, {AddressModel? address}) {
    final isEditing = address != null;

    // Form key for validation
    final formKey = GlobalKey<FormState>();

    // Controllers
    String selectedLabel = address?.label ?? 'Home';
    final nameController =
    TextEditingController(text: address?.fullName ?? '');
    final phoneController =
    TextEditingController(text: address?.phoneNumber ?? '');
    final line1Controller =
    TextEditingController(text: address?.addressLine1 ?? '');
    final line2Controller =
    TextEditingController(text: address?.addressLine2 ?? '');
    final landmarkController =
    TextEditingController(text: address?.landmark ?? '');
    final cityController =
    TextEditingController(text: address?.city ?? '');
    final stateController =
    TextEditingController(text: address?.state ?? '');
    final pincodeController =
    TextEditingController(text: address?.pincode ?? '');
    bool isDefault = address?.isDefault ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setModalState) {
          final addressProvider =
          Provider.of<AddressProvider>(sheetContext, listen: false);

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Handle bar ──
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Title ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEditing ? 'Edit Address' : 'Add New Address',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: const Icon(Icons.close),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.grey[100],
                              padding: const EdgeInsets.all(6),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── Address Type ──
                      const Text(
                        'Address Type',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children:
                        ['Home', 'Work', 'Other'].map((label) {
                          final isSelected = selectedLabel == label;
                          final icon = label == 'Home'
                              ? Icons.home_outlined
                              : label == 'Work'
                              ? Icons.work_outline
                              : Icons.location_on_outlined;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () =>
                                  setModalState(() => selectedLabel = label),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.purple
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.purple
                                        : Colors.grey[300]!,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      icon,
                                      size: 16,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey[600],
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 20),

                      // ── Full Name ──
                      _buildFormField(
                        controller: nameController,
                        label: 'Full Name',
                        icon: Icons.person_outline,
                        validator: (v) =>
                        v == null || v.trim().isEmpty
                            ? 'Full name is required'
                            : null,
                      ),
                      const SizedBox(height: 14),

                      // ── Phone ──
                      _buildFormField(
                        controller: phoneController,
                        label: 'Phone Number',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Phone number is required';
                          }
                          if (v.trim().length < 10) {
                            return 'Enter a valid 10-digit phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // ── Address Line 1 ──
                      _buildFormField(
                        controller: line1Controller,
                        label: 'House / Flat / Block No.',
                        icon: Icons.home_outlined,
                        validator: (v) =>
                        v == null || v.trim().isEmpty
                            ? 'Address Line 1 is required'
                            : null,
                      ),
                      const SizedBox(height: 14),

                      // ── Address Line 2 ──
                      _buildFormField(
                        controller: line2Controller,
                        label: 'Apartment / Road / Area (Optional)',
                        icon: Icons.location_on_outlined,
                      ),
                      const SizedBox(height: 14),

                      // ── Landmark ──
                      _buildFormField(
                        controller: landmarkController,
                        label: 'Landmark (Optional)',
                        icon: Icons.flag_outlined,
                      ),
                      const SizedBox(height: 14),

                      // ── City & State ──
                      Row(
                        children: [
                          Expanded(
                            child: _buildFormField(
                              controller: cityController,
                              label: 'City',
                              icon: Icons.location_city_outlined,
                              validator: (v) =>
                              v == null || v.trim().isEmpty
                                  ? 'City is required'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildFormField(
                              controller: stateController,
                              label: 'State',
                              icon: Icons.map_outlined,
                              validator: (v) =>
                              v == null || v.trim().isEmpty
                                  ? 'State is required'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // ── Pincode ──
                      _buildFormField(
                        controller: pincodeController,
                        label: 'Pincode',
                        icon: Icons.pin_drop_outlined,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Pincode is required';
                          }
                          if (v.trim().length != 6) {
                            return 'Enter a valid 6-digit pincode';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // ── Default toggle ──
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.purple[50],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: CheckboxListTile(
                          value: isDefault,
                          onChanged: (v) =>
                              setModalState(() => isDefault = v ?? false),
                          title: const Text(
                            'Set as default address',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: const Text(
                            'Use this address for future orders',
                            style: TextStyle(fontSize: 12),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: Colors.purple,
                          contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Save Button ──
                      Consumer<AddressProvider>(
                        builder: (ctx, provider, _) {
                          return SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: provider.isSubmitting
                                  ? null
                                  : () async {
                                if (!formKey.currentState!.validate()) {
                                  return;
                                }

                                final newAddress = AddressModel(
                                  id: address?.id ??
                                      DateTime.now()
                                          .millisecondsSinceEpoch
                                          .toString(),
                                  userId: 'user_123',
                                  label: selectedLabel,
                                  fullName: nameController.text.trim(),
                                  phoneNumber:
                                  phoneController.text.trim(),
                                  addressLine1:
                                  line1Controller.text.trim(),
                                  addressLine2:
                                  line2Controller.text.trim(),
                                  landmark: landmarkController.text
                                      .trim()
                                      .isEmpty
                                      ? null
                                      : landmarkController.text.trim(),
                                  city: cityController.text.trim(),
                                  state: stateController.text.trim(),
                                  pincode: pincodeController.text.trim(),
                                  isDefault: isDefault,
                                  createdAt:
                                  address?.createdAt ?? DateTime.now(),
                                  updatedAt: isEditing
                                      ? DateTime.now()
                                      : null,
                                );

                                final success = isEditing
                                    ? await provider
                                    .updateAddress(newAddress)
                                    : await provider
                                    .addAddress(newAddress);

                                if (success && sheetContext.mounted) {
                                  Navigator.pop(sheetContext);
                                }

                                if (mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        success
                                            ? isEditing
                                            ? 'Address updated successfully'
                                            : 'Address added successfully'
                                            : provider.errorMessage ??
                                            'Failed to save address',
                                      ),
                                      backgroundColor: success
                                          ? Colors.green
                                          : Colors.red,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                Colors.purple.withValues(alpha: 0.5),
                                padding:
                                const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                              child: provider.isSubmitting
                                  ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                                  : Text(
                                isEditing
                                    ? 'Update Address'
                                    : 'Save Address',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Reusable Form Field
  // ─────────────────────────────────────────────

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.purple, size: 20),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.purple, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.red[400]!),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}