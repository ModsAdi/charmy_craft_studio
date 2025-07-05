import 'package:charmy_craft_studio/models/order.dart' as my_order;
// ** FIX: Added import for the user provider **
import 'package:charmy_craft_studio/state/user_provider.dart';
import 'package:charmy_craft_studio/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
  late String _currentStatus;
  DateTime? _deliveryDate;
  bool _advancePaid = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.order.status;
    _deliveryDate = widget.order.approximateDeliveryDate;
    _advancePaid = widget.order.advancePaid;
  }

  Future<void> _updateOrder() async {
    setState(() => _isLoading = true);
    try {
      final dataToUpdate = {
        'status': _currentStatus,
        'approximateDeliveryDate': _deliveryDate != null ? Timestamp.fromDate(_deliveryDate!) : null,
        'advancePaid': _advancePaid,
      };
      await ref
          .read(firestoreServiceProvider)
          .updateOrder(widget.order.id, dataToUpdate);
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
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _updateOrder,
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16)),
            child: _isLoading
                ? const CircularProgressIndicator()
                : const Text('Save Changes'),
          )
        ],
      ),
    );
  }

  // ** FIX: This widget now fetches the live user name **
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

  Widget _buildOrderItems() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Items', style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold)),
        ...widget.order.items.map((item) => ListTile(
          leading: CircleAvatar(backgroundImage: NetworkImage(item.imageUrl)),
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
              onTap: () async {
                final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _deliveryDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)));
                if(pickedDate != null) {
                  setState(() => _deliveryDate = pickedDate);
                }
              },
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
}