import 'package:charmy_craft_studio/models/order.dart' as my_order;
import 'package:charmy_craft_studio/screens/profile/user_order_details_screen.dart';
import 'package:charmy_craft_studio/services/auth_service.dart';
import 'package:charmy_craft_studio/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// Provider to fetch the current user's orders
final myOrdersProvider = StreamProvider.autoDispose<List<my_order.Order>>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) {
    return Stream.value([]);
  }
  return ref.read(firestoreServiceProvider).getMyOrders(user.uid);
});

class MyOrdersScreen extends ConsumerWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myOrdersAsync = ref.watch(myOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('My Orders', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
      ),
      body: myOrdersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(
              child: Text('You have not placed any orders yet.'),
            );
          }
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text('Order #${order.id.substring(0, 6)}...'),
                  subtitle: Text('Placed on: ${DateFormat.yMMMd().format(order.orderPlacementDate)}'),
                  trailing: Chip(
                    label: Text(order.status),
                    backgroundColor: _getStatusColor(order.status).withOpacity(0.2),
                    labelStyle: TextStyle(color: _getStatusColor(order.status)),
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => UserOrderDetailsScreen(order: order),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Helper to color-code the status chip
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Shipped':
        return Colors.blue;
      case 'Delivered':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Confirmed':
        return Colors.purple;
    // ++ ADDED: This makes the chip red for cancelled orders ++
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}