import 'package:charmy_craft_studio/models/order.dart';
import 'package:charmy_craft_studio/screens/creator/order_details_screen.dart';
import 'package:charmy_craft_studio/state/orders_provider.dart';
// ** FIX: Added import for the user provider **
import 'package:charmy_craft_studio/state/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ManageOrdersScreen extends ConsumerWidget {
  const ManageOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(allOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Orders', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(child: Text('No orders yet.'));
          }
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              // Pass ref to the card builder
              return _buildOrderCard(context, order, ref);
            },
          );
        },
      ),
    );
  }

  // ** FIX: This widget now accepts a WidgetRef to fetch live data **
  Widget _buildOrderCard(BuildContext context, Order order, WidgetRef ref) {
    final theme = Theme.of(context);
    // ** FIX: Watch the provider to get the latest user data for this specific order **
    final userAsync = ref.watch(artistDetailsProvider(order.userId));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: userAsync.when(
          loading: () => const Text('Loading...', style: TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
          error: (err, stack) => Text(order.userName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          // ** Display the live name from the fetched user profile **
          data: (user) => Text(user?.displayName ?? 'Unknown User', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        subtitle: Text('Total: ₹${order.totalValue.toStringAsFixed(0)} - ${DateFormat.yMMMd().format(order.orderPlacementDate)}'),
        trailing: Chip(
          label: Text(order.status),
          backgroundColor: order.status == 'Confirmed' ? Colors.green.withOpacity(0.2) : theme.colorScheme.secondary.withOpacity(0.2),
          labelStyle: TextStyle(color: order.status == 'Confirmed' ? Colors.green[800] : theme.colorScheme.secondary),
        ),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => CreatorOrderDetailsScreen(order: order),
          ));
        },
      ),
    );
  }
}