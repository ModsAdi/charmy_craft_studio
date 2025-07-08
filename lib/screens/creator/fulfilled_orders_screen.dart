// lib/screens/creator/fulfilled_orders_screen.dart

import 'package:charmy_craft_studio/models/order.dart';
import 'package:charmy_craft_studio/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// Provider to fetch only fulfilled orders
final fulfilledOrdersProvider = StreamProvider.autoDispose<List<Order>>((ref) {
  return ref.watch(firestoreServiceProvider).getFulfilledOrders();
});

class FulfilledOrdersScreen extends ConsumerWidget {
  const FulfilledOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fulfilledOrdersAsync = ref.watch(fulfilledOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Fulfilled Orders',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
      ),
      body: fulfilledOrdersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(child: Text('No fulfilled orders yet.'));
          }
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text(order.userName),
                  subtitle: Text(
                      'Total: ₹${order.totalValue.toStringAsFixed(0)} - ${DateFormat.yMMMd().format(order.orderPlacementDate)}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}