// lib/screens/creator/create_order_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:charmy_craft_studio/models/order.dart';
import 'package:charmy_craft_studio/models/product.dart';
import 'package:charmy_craft_studio/services/firestore_service.dart';
import 'package:charmy_craft_studio/state/create_order_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class CreateOrderScreen extends ConsumerStatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  ConsumerState<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends ConsumerState<CreateOrderScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _whatsappMessageController = TextEditingController();
  DateTime? _deliveryDate;
  bool _advancePaid = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _whatsappMessageController.dispose();
    super.dispose();
  }

  void _createOrder() {
    final orderState = ref.read(createOrderProvider);
    if (orderState.foundUser == null || orderState.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please find a customer and add items first.')));
      return;
    }

    final totalValue = orderState.items
        .fold<double>(0, (sum, item) => sum + (item.price * item.quantity));

    // ++ FINAL FIX: Using a String for the status to match your Order model ++
    final newOrder = Order(
      id: const Uuid().v4(),
      userId: orderState.foundUser!.uid,
      userName: orderState.foundUser!.displayName ?? 'N/A',
      userEmail: orderState.foundUser!.email,
      items: orderState.items,
      totalValue: totalValue,
      orderPlacementDate: DateTime.now(),
      approximateDeliveryDate: _deliveryDate,
      status: 'Pending', // <-- Correctly uses a String
      advancePaid: _advancePaid,
    );

    ref.read(firestoreServiceProvider).createOrder(newOrder).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order created successfully!')));
      ref.read(createOrderProvider.notifier).reset();
      _emailController.clear();
      _whatsappMessageController.clear();
      Navigator.pop(context);
    }).catchError((error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $error')));
    });
  }

  Future<void> _selectDeliveryDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _deliveryDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _deliveryDate) {
      setState(() {
        _deliveryDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(createOrderProvider);
    final notifier = ref.read(createOrderProvider.notifier);
    final totalValue = orderState.items
        .fold<double>(0, (sum, item) => sum + (item.price * item.quantity));

    ref.listen<CreateOrderState>(createOrderProvider, (previous, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(next.errorMessage!), backgroundColor: Colors.red));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Create New Order',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              notifier.reset();
              _emailController.clear();
              _whatsappMessageController.clear();
            },
            tooltip: 'Clear Form',
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Manual Entry', icon: Icon(Icons.edit_note)),
            Tab(text: 'Paste from WhatsApp', icon: Icon(Icons.paste)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildManualEntryView(context, orderState, notifier),
                _buildPasteFromWhatsAppView(context, orderState, notifier),
              ],
            ),
          ),
          if (orderState.items.isNotEmpty)
            _buildCheckoutBar(context, totalValue, _createOrder),
        ],
      ),
    );
  }

  Widget _buildPasteFromWhatsAppView(BuildContext context,
      CreateOrderState orderState, CreateOrderNotifier notifier) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _whatsappMessageController,
          decoration: const InputDecoration(
            labelText: 'Paste WhatsApp message here',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
            hintText: 'Hello, I’d like to place an order...',
          ),
          maxLines: 10,
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon: const Icon(Icons.sync),
          label: const Text('Parse and Fill Order'),
          onPressed: orderState.isLoading
              ? null
              : () {
            FocusScope.of(context).unfocus();
            if (_whatsappMessageController.text.isNotEmpty) {
              notifier
                  .parseAndFillOrder(_whatsappMessageController.text);
            }
          },
        ),
        const Divider(height: 32),
        if (orderState.isLoading)
          const Center(child: CircularProgressIndicator()),
        if (orderState.foundUser != null) ...[
          _buildSectionCard(
            context,
            step: '✓',
            title: 'Customer Found',
            child: _buildCustomerChip(orderState),
          ),
        ],
        if (orderState.items.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildSectionCard(
            context,
            step: '✓',
            title: 'Products Added',
            child: _buildItemsList(orderState, notifier),
          ),
        ],
      ],
    );
  }

  Widget _buildManualEntryView(BuildContext context,
      CreateOrderState orderState, CreateOrderNotifier notifier) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSectionCard(
          context,
          step: '1',
          title: 'Find Customer',
          child: orderState.foundUser == null
              ? _buildEmailSearch(context, orderState, notifier)
              : _buildCustomerChip(orderState),
        ),
        if (orderState.foundUser != null)
          _buildSectionCard(
            context,
            step: '2',
            title: 'Add Products',
            child: Column(
              children: [
                _buildProductAutocomplete(context, notifier),
                const SizedBox(height: 8),
                _buildItemsList(orderState, notifier),
              ],
            ),
          ),
        if (orderState.foundUser != null && orderState.items.isNotEmpty)
          _buildSectionCard(
            context,
            step: '3',
            title: 'Finalize Details',
            child: _buildFinalDetails(),
          ),
      ],
    );
  }

  Widget _buildEmailSearch(BuildContext context, CreateOrderState orderState,
      CreateOrderNotifier notifier) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _emailController,
            decoration: const InputDecoration(
                labelText: 'Customer Email', border: OutlineInputBorder()),
            keyboardType: TextInputType.emailAddress,
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          icon: const Icon(Icons.search),
          onPressed: orderState.isLoading
              ? null
              : () {
            FocusScope.of(context).unfocus();
            notifier.findUserByEmail(_emailController.text.trim());
          },
          style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary),
        ),
      ],
    );
  }

  Widget _buildCustomerChip(CreateOrderState orderState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.green),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(orderState.foundUser!.displayName ?? 'N/A',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(orderState.foundUser!.email),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => ref.read(createOrderProvider.notifier).reset(),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildProductAutocomplete(
      BuildContext context, CreateOrderNotifier notifier) {
    return Autocomplete<Product>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text == '') {
          return const Iterable<Product>.empty();
        }
        return ref
            .read(firestoreServiceProvider)
            .searchProductsByTitle(textEditingValue.text);
      },
      displayStringForOption: (Product option) => option.title,
      onSelected: (Product selection) {
        notifier.addProductById(selection.id);
        FocusScope.of(context).unfocus();
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          onSubmitted: (_) => onFieldSubmitted(),
          decoration: InputDecoration(
            labelText: 'Start typing product title...',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => controller.clear(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildItemsList(
      CreateOrderState orderState, CreateOrderNotifier notifier) {
    if (orderState.items.isEmpty) return const SizedBox.shrink();
    return Column(
      children: orderState.items
          .map((item) => Card(
        elevation: 0,
        color: Colors.grey.shade100,
        child: ListTile(
          leading: CachedNetworkImage(
              imageUrl: item.imageUrl,
              width: 40,
              errorWidget: (c, u, e) =>
              const Icon(Icons.hide_image)),
          title: Text(item.title, overflow: TextOverflow.ellipsis),
          subtitle: Text('₹${item.price.toStringAsFixed(0)}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () => notifier.updateItemQuantity(
                    item.productId, item.quantity - 1),
                splashRadius: 20,
              ),
              Text(item.quantity.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => notifier.updateItemQuantity(
                    item.productId, item.quantity + 1),
                splashRadius: 20,
              ),
            ],
          ),
        ),
      ))
          .toList(),
    );
  }

  Widget _buildFinalDetails() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.calendar_today_outlined),
          title: const Text('Approximate Delivery Date'),
          subtitle: Text(_deliveryDate == null
              ? 'Not Set'
              : DateFormat.yMMMd().format(_deliveryDate!)),
          onTap: () => _selectDeliveryDate(context),
        ),
        SwitchListTile(
          title: const Text('Advance Payment Received'),
          secondary: const Icon(Icons.payment_outlined),
          value: _advancePaid,
          onChanged: (value) => setState(() => _advancePaid = value),
        ),
      ],
    );
  }

  Widget _buildSectionCard(BuildContext context,
      {required String step, required String title, required Widget child}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  child: Text(step,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Text(title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutBar(
      BuildContext context, double total, VoidCallback onCreateOrder) {
    return Container(
      padding: const EdgeInsets.all(16.0)
          .copyWith(bottom: MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Value',
                  style: TextStyle(color: Colors.grey.shade600)),
              Text('₹${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            onPressed: onCreateOrder,
            child: const Text('Create Order'),
          ),
        ],
      ),
    );
  }
}