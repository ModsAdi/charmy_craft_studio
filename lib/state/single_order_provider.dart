// lib/state/single_order_provider.dart

import 'package:charmy_craft_studio/models/order.dart';
import 'package:charmy_craft_studio/services/firestore_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// This provider needs to be rebuilt when the order data changes,
// so we'll use a standard StreamProvider.
final singleOrderProvider = StreamProvider.autoDispose.family<Order, String>((ref, orderId) {
  // We need to find the specific order from the list of all orders.
  // This is less efficient than a direct doc stream, but works for now.
  // A more optimized approach would be a direct document stream in FirestoreService.
  return ref.watch(firestoreServiceProvider).getAllOrders().map(
        (orders) => orders.firstWhere((order) => order.id == orderId),
  );
});