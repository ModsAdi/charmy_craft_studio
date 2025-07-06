import 'package:charmy_craft_studio/models/order.dart' as my_order;
import 'package:charmy_craft_studio/state/user_provider.dart';
import 'package:charmy_craft_studio/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class CreatorOrderDetailsScreen extends ConsumerStatefulWidget {
  final my_order.Order order;
  const CreatorOrderDetailsScreen({super.key, required this.order});

  @override
  ConsumerState<CreatorOrderDetailsScreen> createState() =>
      _CreatorOrderDetailsScreenState();
}

class _CreatorOrderDetailsScreenState
    extends ConsumerState<CreatorOrderDetailsScreen> {
  // Existing state
  late String _currentStatus;
  DateTime? _deliveryDate;
  bool _advancePaid = false;
  bool _isLoading = false;

  // Shipping details state
  String? _deliveryMode;
  late final TextEditingController _otherDeliveryModeController;
  late final TextEditingController _trackingLinkController;
  late final TextEditingController _specialNoteController;
  late final TextEditingController _waybillController;
  late final TextEditingController _referenceController;
  late final TextEditingController _awbController;
  late final TextEditingController _orderIdController;
  late final TextEditingController _lrnController;
  late final TextEditingController _consignmentController;

  final List<String> _deliveryOptions = ['DTDC', 'Delhivery', 'Blue Dart', 'India Post', 'Other'];

  @override
  void initState() {
    super.initState();
    final order = widget.order;
    _currentStatus = order.status;
    _deliveryDate = order.approximateDeliveryDate;
    _advancePaid = order.advancePaid;

    // Initialize controllers with existing data
    _deliveryMode = _deliveryOptions.contains(order.deliveryMode) ? order.deliveryMode : 'Other';
    _otherDeliveryModeController = TextEditingController(text: _deliveryOptions.contains(order.deliveryMode) ? '' : order.deliveryMode);
    _trackingLinkController = TextEditingController(text: order.trackingLink);
    _specialNoteController = TextEditingController(text: order.specialNote);
    _waybillController = TextEditingController(text: order.trackingDetails?['Waybill']);
    _referenceController = TextEditingController(text: order.trackingDetails?['Reference Number']);
    _awbController = TextEditingController(text: order.trackingDetails?['AWB']);
    _orderIdController = TextEditingController(text: order.trackingDetails?['Courier Order ID']);
    _lrnController = TextEditingController(text: order.trackingDetails?['LRN']);
    _consignmentController = TextEditingController(text: order.trackingDetails?['Consignment Number']);
  }

  @override
  void dispose() {
    _otherDeliveryModeController.dispose();
    _trackingLinkController.dispose();
    _specialNoteController.dispose();
    _waybillController.dispose();
    _referenceController.dispose();
    _awbController.dispose();
    _orderIdController.dispose();
    _lrnController.dispose();
    _consignmentController.dispose();
    super.dispose();
  }

  Future<void> _updateOrder() async {
    setState(() => _isLoading = true);
    try {
      final trackingDetails = {
        'Waybill': _waybillController.text.trim(),
        'Reference Number': _referenceController.text.trim(),
        'AWB': _awbController.text.trim(),
        'Courier Order ID': _orderIdController.text.trim(),
        'LRN': _lrnController.text.trim(),
        'Consignment Number': _consignmentController.text.trim(),
      };
      trackingDetails.removeWhere((key, value) => value == null || value.isEmpty);

      final dataToUpdate = {
        'status': _currentStatus,
        'approximateDeliveryDate': _deliveryDate != null ? Timestamp.fromDate(_deliveryDate!) : null,
        'advancePaid': _advancePaid,
        'deliveryMode': _deliveryMode == 'Other' ? _otherDeliveryModeController.text.trim() : _deliveryMode,
        'trackingLink': _trackingLinkController.text.trim(),
        'specialNote': _specialNoteController.text.trim(),
        'trackingDetails': trackingDetails,
      };

      await ref.read(firestoreServiceProvider).updateOrder(widget.order.id, dataToUpdate);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order updated!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // ++ FIXED: Themed Date Picker Function ++
  Future<void> _selectDeliveryDate(BuildContext context) async {
    final theme = Theme.of(context);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _deliveryDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.colorScheme.secondary,
              onPrimary: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.secondary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      setState(() => _deliveryDate = pickedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${widget.order.id.substring(0, 6)}...'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCustomerInfo(),
          const Divider(height: 32),
          _buildOrderItems(),
          const Divider(height: 32),
          _buildManagementTools(),
          const Divider(height: 32),
          _buildShipmentDetailsCard(),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _updateOrder,
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16)),
            child: _isLoading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white,))
                : const Text('Save Changes'),
          )
        ],
      ),
    );
  }

  Widget _buildCustomerInfo() {
    final userAsync = ref.watch(artistDetailsProvider(widget.order.userId));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer Details', style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            userAsync.when(
              loading: () => const Text('Loading...'),
              error: (err, stack) => Text('Name: ${widget.order.userName} (Could not fetch latest)'),
              data: (user) => Text('Name: ${user?.displayName ?? widget.order.userName}'),
            ),
            Text('Email: ${widget.order.userEmail}'),
            Text('Placed on: ${DateFormat.yMMMd().format(widget.order.orderPlacementDate)}'),
          ],
        ),
      ),
    );
  }

  // ++ FIXED: Item image overlapping bug by setting a fixed width ++
  Widget _buildOrderItems() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Items', style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold)),
        ...widget.order.items.map((item) => ListTile(
          leading: SizedBox(
            width: 50,
            child: item.imageUrl.isNotEmpty ? Image.network(item.imageUrl, width: 40, fit: BoxFit.cover,) : const Icon(Icons.image_not_supported),
          ),
          title: Text(item.title),
          trailing: Text('₹${item.price.toStringAsFixed(0)} x ${item.quantity}'),
        )),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Text('Total: ₹${widget.order.totalValue.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ],
    );
  }

  Widget _buildManagementTools() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Update Status', style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: _currentStatus,
              isExpanded: true,
              items: ['Pending', 'Confirmed', 'Shipped', 'Delivered']
                  .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _currentStatus = value);
                }
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Approximate Delivery Date'),
              subtitle: Text(_deliveryDate == null ? 'Not Set' : DateFormat.yMMMd().format(_deliveryDate!)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDeliveryDate(context),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Advance Payment Received'),
              value: _advancePaid,
              onChanged: (value) => setState(() => _advancePaid = value),
            ),
          ],
        ),
      ),
    );
  }

  // ++ UPDATED: Shipment details section with new fields ++
  Widget _buildShipmentDetailsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Shipment Details', style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _deliveryMode,
              items: _deliveryOptions.map((mode) => DropdownMenuItem(value: mode, child: Text(mode))).toList(),
              onChanged: (value) => setState(() => _deliveryMode = value),
              decoration: const InputDecoration(
                  labelText: 'Delivery Mode',
                  border: OutlineInputBorder()
              ),
            ),
            if (_deliveryMode == 'Other')
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: TextField(
                  controller: _otherDeliveryModeController,
                  decoration: const InputDecoration(labelText: 'Enter Courier Name', border: OutlineInputBorder()),
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _trackingLinkController,
              decoration: const InputDecoration(labelText: 'Tracking Link (URL)', border: OutlineInputBorder()),
              keyboardType: TextInputType.url,
            ),
            ExpansionTile(
              title: const Text('Tracking Numbers (Optional)'),
              tilePadding: EdgeInsets.zero,
              children: [
                _buildTrackingField(_waybillController, 'Waybill'),
                _buildTrackingField(_referenceController, 'Reference Number'),
                _buildTrackingField(_awbController, 'AWB'),
                _buildTrackingField(_orderIdController, 'Courier Order ID'),
                _buildTrackingField(_lrnController, 'LRN'),
                _buildTrackingField(_consignmentController, 'Consignment Number'),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _specialNoteController,
              decoration: const InputDecoration(
                labelText: 'Special Note (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.copy_outlined, size: 20),
              onPressed: () {
                if(controller.text.isNotEmpty) {
                  Clipboard.setData(ClipboardData(text: controller.text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard!'), duration: Duration(seconds: 1)),
                  );
                }
              },
            )
        ),
      ),
    );
  }
}