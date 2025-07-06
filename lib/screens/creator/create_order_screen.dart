import 'package:cached_network_image/cached_network_image.dart';
import 'package:charmy_craft_studio/models/order.dart' as my_order;
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

class _CreateOrderScreenState extends ConsumerState<CreateOrderScreen> {
  final _emailController = TextEditingController();
  DateTime? _deliveryDate;
  bool _advancePaid = false;

  void _createOrder() {
    final orderState = ref.read(createOrderProvider);
    if (orderState.foundUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please find a user first.')));
      return;
    }
    if (orderState.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one product.')));
      return;
    }

    final totalValue = orderState.items.fold<double>(0, (sum, item) => sum + (item.price * item.quantity));

    final newOrder = my_order.Order(
      id: const Uuid().v4(),
      userId: orderState.foundUser!.uid,
      userEmail: orderState.foundUser!.email,
      userName: orderState.foundUser!.displayName ?? 'N/A',
      items: orderState.items,
      totalValue: totalValue,
      orderPlacementDate: DateTime.now(),
      approximateDeliveryDate: _deliveryDate,
      status: 'Confirmed',
      advancePaid: _advancePaid,
    );

    ref.read(firestoreServiceProvider).createOrder(newOrder).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order created successfully!'), backgroundColor: Colors.green));
      ref.read(createOrderProvider.notifier).reset();
      _emailController.clear();
      setState(() {
        _deliveryDate = null;
        _advancePaid = false;
      });
    }).catchError((err) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $err'), backgroundColor: Colors.red));
    });
  }

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
              onSurface: Colors.black87,
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
    final orderState = ref.watch(createOrderProvider);
    final notifier = ref.read(createOrderProvider.notifier);
    final theme = Theme.of(context);
    final totalValue = orderState.items.fold<double>(0, (sum, item) => sum + (item.price * item.quantity));

    ref.listen<CreateOrderState>(createOrderProvider, (previous, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.errorMessage!), backgroundColor: Colors.red));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Create New Order', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              notifier.reset();
              _emailController.clear();
            },
            tooltip: 'Clear Form',
          )
        ],
      ),
      // ++ MODIFIED: Wrapped in a Column to show the total value bar ++
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildSectionCard(
                  context,
                  step: '1',
                  title: 'Find Customer',
                  child: orderState.foundUser == null
                      ? Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(labelText: 'Customer Email', border: OutlineInputBorder()),
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        icon: const Icon(Icons.search),
                        onPressed: orderState.isLoading ? null : () {
                          FocusScope.of(context).unfocus();
                          notifier.findUserByEmail(_emailController.text.trim());
                        },
                        style: IconButton.styleFrom(backgroundColor: theme.colorScheme.secondary),
                      ),
                    ],
                  )
                      : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(orderState.foundUser!.displayName ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(orderState.foundUser!.email),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => notifier.reset(),
                        ),
                      ],
                    ),
                  ),
                ),

                if (orderState.foundUser != null)
                  _buildSectionCard(
                    context,
                    step: '2',
                    title: 'Add Products',
                    child: Column(
                      children: [
                        Autocomplete<Product>(
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text == '') {
                              return const Iterable<Product>.empty();
                            }
                            return ref.read(firestoreServiceProvider).searchProductsByTitle(textEditingValue.text);
                          },
                          displayStringForOption: (Product option) => option.title,
                          onSelected: (Product selection) {
                            notifier.addProductById(selection.id);
                            // Clear the text field by rebuilding the Autocomplete widget
                            setState(() {});
                            FocusScope.of(context).unfocus();
                          },
                          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                labelText: 'Start typing product title...',
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () { controller.clear(); },
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        ...orderState.items.map((item) => Card(
                          elevation: 0,
                          color: Colors.grey.shade100,
                          child: ListTile(
                            leading: CachedNetworkImage(imageUrl: item.imageUrl, width: 40, errorWidget: (c, u, e) => const Icon(Icons.hide_image)),
                            title: Text(item.title, overflow: TextOverflow.ellipsis),
                            subtitle: Text('₹${item.price.toStringAsFixed(0)}'),
                            // ++ MODIFIED: This is now a Row with quantity controls ++
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () => notifier.updateItemQuantity(item.productId, item.quantity - 1),
                                  splashRadius: 20,
                                ),
                                Text(item.quantity.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () => notifier.updateItemQuantity(item.productId, item.quantity + 1),
                                  splashRadius: 20,
                                ),
                              ],
                            ),
                          ),
                        )),
                      ],
                    ),
                  ),

                if (orderState.foundUser != null)
                  _buildSectionCard(
                    context,
                    step: '3',
                    title: 'Finalize Details',
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.calendar_today_outlined),
                          title: const Text('Approximate Delivery Date'),
                          subtitle: Text(_deliveryDate == null ? 'Not Set' : DateFormat.yMMMd().format(_deliveryDate!)),
                          onTap: () => _selectDeliveryDate(context),
                        ),
                        SwitchListTile(
                          title: const Text('Advance Payment Received'),
                          secondary: const Icon(Icons.payment_outlined),
                          value: _advancePaid,
                          onChanged: (value) => setState(() => _advancePaid = value),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 32),

                // Create Order Button is now inside the bottom bar
              ],
            ),
          ),
          // ++ NEW: Checkout bar at the bottom ++
          if (orderState.items.isNotEmpty)
            _buildCheckoutBar(context, totalValue, _createOrder),
        ],
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, {required String step, required String title, required Widget child}) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Colors.white,
                  child: Text(step, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }
}

// ++ NEW: Widget for the bottom bar ++
Widget _buildCheckoutBar(BuildContext context, double total, VoidCallback onCreateOrder) {
  final theme = Theme.of(context);
  return Container(
    padding: const EdgeInsets.all(16.0).copyWith(bottom: MediaQuery.of(context).padding.bottom + 8),
    decoration: BoxDecoration(
      color: theme.cardColor,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, -5),
        ),
      ],
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Total Value', style: TextStyle(color: Colors.grey)),
            Text(
              '₹${total.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.done_all),
          label: const Text('Create Order'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: Colors.white,
          ),
          onPressed: onCreateOrder,
        ),
      ],
    ),
  );
}