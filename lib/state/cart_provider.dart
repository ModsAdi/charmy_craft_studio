import 'package:charmy_craft_studio/models/cart_item.dart';
import 'package:charmy_craft_studio/services/auth_service.dart';
import 'package:charmy_craft_studio/services/firestore_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// This provider streams the user's cart directly from Firestore.
// It automatically updates whenever the cart changes in the database.
final cartProvider = StreamProvider.autoDispose<List<CartItem>>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final firestoreService = ref.read(firestoreServiceProvider);

  // If a user is logged in, get their cart stream.
  // Otherwise, return an empty cart.
  if (authState.value?.uid != null) {
    return firestoreService.getCartStream(authState.value!.uid);
  } else {
    return Stream.value([]);
  }
});

// A provider to get the total number of unique items in the cart.
final cartItemCountProvider = Provider.autoDispose<int>((ref) {
  // Watches the cartProvider and returns the number of items.
  return ref.watch(cartProvider).when(
    data: (items) => items.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

// A provider to calculate the total price of all items in the cart.
final cartTotalProvider = Provider.autoDispose<double>((ref) {
  // Watches the cartProvider and calculates the total price.
  return ref.watch(cartProvider).when(
    data: (items) {
      double total = 0.0;
      for (final item in items) {
        total += item.price * item.quantity;
      }
      return total;
    },
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});