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

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(createOrderProvider);
    final notifier = ref.read(createOrderProvider.notifier);

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
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // User Search Section
          if (orderState.foundUser == null) ...[
            Text('Step 1: Find Customer', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Row(
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
                ),
              ],
            ),
          ] else ...[
            // Display Found User
            Card(
              color: Colors.green.shade50,
              child: ListTile(
                title: Text(orderState.foundUser!.displayName ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(orderState.foundUser!.email),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => notifier.reset(),
                ),
              ),
            ),
          ],

          const Divider(height: 32),

          if (orderState.foundUser != null) ...[
            Text('Step 2: Add Products by Title', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            // ** NEW AUTOCOMPLETE SEARCH BOX **
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
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: 'Start typing product title...',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        // This might not be needed if selection is mandatory
                        // but can be used for UID pasting.
                        onFieldSubmitted();
                      },
                    ),
                  ),
                );
              },
            ),

            ...orderState.items.map((item) => Card(
              child: ListTile(
                leading: CachedNetworkImage(imageUrl: item.imageUrl, width: 40, errorWidget: (c,u,e) => const Icon(Icons.hide_image)),
                title: Text(item.title, overflow: TextOverflow.ellipsis),
                subtitle: Text('Qty: ${item.quantity} - ₹${item.price.toStringAsFixed(0)}'),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                  onPressed: () => notifier.removeItem(item.productId),
                ),
              ),
            )),

            const Divider(height: 32),

            Text('Step 3: Finalize Details', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ListTile(
              title: const Text('Approximate Delivery Date'),
              subtitle: Text(_deliveryDate == null ? 'Not Set' : DateFormat.yMMMd().format(_deliveryDate!)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _deliveryDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)));
                if(pickedDate != null) {
                  setState(() => _deliveryDate = pickedDate);
                }
              },
            ),
            SwitchListTile(
              title: const Text('Advance Payment Received'),
              value: _advancePaid,
              onChanged: (value) => setState(() => _advancePaid = value),
            ),
          ],

          const SizedBox(height: 32),

          if (orderState.foundUser != null && orderState.items.isNotEmpty)
            ElevatedButton.icon(
              icon: const Icon(Icons.done_all),
              label: const Text('Create Order'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: _createOrder,
            ),
        ],
      ),
    );
  }
}