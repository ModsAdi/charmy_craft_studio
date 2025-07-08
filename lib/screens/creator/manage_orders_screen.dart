// lib/screens/creator/manage_orders_screen.dart

import 'package:charmy_craft_studio/models/order.dart';
import 'package:charmy_craft_studio/screens/creator/fulfilled_orders_screen.dart';
import 'package:charmy_craft_studio/screens/creator/order_details_screen.dart';
import 'package:charmy_craft_studio/services/firestore_service.dart';
import 'package:charmy_craft_studio/state/orders_provider.dart';
import 'package:charmy_craft_studio/state/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// Provider to hold the state of the filter
final statusFilterProvider = StateProvider<String>((ref) => 'All');

class ManageOrdersScreen extends ConsumerWidget {
  const ManageOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(allOrdersProvider);
    final selectedStatus = ref.watch(statusFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Orders',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_outlined),
            tooltip: 'View Fulfilled Orders',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const FulfilledOrdersScreen(),
              ));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(context, ref),
          Expanded(
            child: ordersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (orders) {
                final filteredOrders = orders
                    .where((order) => selectedStatus == 'All' || order.status == selectedStatus)
                    .toList();

                if (filteredOrders.isEmpty) {
                  return const Center(child: Text('No orders match the filter.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: filteredOrders.length,
                  itemBuilder: (context, index) {
                    final order = filteredOrders[index];
                    return _buildOrderCard(context, order, ref);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, WidgetRef ref) {
    const statuses = ['All', 'Pending', 'Confirmed', 'Shipped', 'Delivered'];
    final selectedStatus = ref.watch(statusFilterProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: statuses.map((status) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: FilterChip(
                label: Text(status),
                selected: selectedStatus == status,
                onSelected: (isSelected) {
                  if (isSelected) {
                    ref.read(statusFilterProvider.notifier).state = status;
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order, WidgetRef ref) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(artistDetailsProvider(order.userId));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          ListTile(
            title: userAsync.when(
              loading: () => const Text('Loading...', style: TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
              error: (err, stack) => Text(order.userName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
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
          // ++ NEW: Conditional "Fulfill" button ++
          if (order.status == 'Delivered')
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0, right: 8.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                  label: const Text('Fulfill Order', style: TextStyle(color: Colors.green)),
                  onPressed: () {
                    ref.read(firestoreServiceProvider).fulfillOrder(order.id);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order marked as fulfilled!')));
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}