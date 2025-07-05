// lib/state/my_orders_provider.dart

import 'package:charmy_craft_studio/models/order.dart';
import 'package:charmy_craft_studio/services/auth_service.dart';
import 'package:charmy_craft_studio/services/firestore_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final myOrdersProvider = StreamProvider<List<Order>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final user = ref.watch(authStateChangesProvider).value;

  if (user != null) {
    return firestoreService.getMyOrders(user.uid);
  } else {
    return Stream.value([]); // Return an empty stream if the user is not logged in
  }
});