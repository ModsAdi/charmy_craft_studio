// lib/state/orders_provider.dart

import 'package:charmy_craft_studio/models/order.dart';
import 'package:charmy_craft_studio/services/firestore_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final allOrdersProvider = StreamProvider<List<Order>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getAllOrders();
});