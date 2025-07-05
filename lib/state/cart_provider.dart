// lib/state/cart_provider.dart

import 'package:charmy_craft_studio/models/cart_item.dart';
import 'package:charmy_craft_studio/models/product.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addItem(Product product) {
    // Check if the product is already in the cart
    final existingIndex = state.indexWhere((item) => item.productId == product.id);

    if (existingIndex != -1) {
      // If it exists, increase the quantity
      final updatedItem = state[existingIndex].copyWith(quantity: state[existingIndex].quantity + 1);
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == existingIndex) updatedItem else state[i],
      ];
    } else {
      // If it's a new product, add it to the cart
      state = [...state, CartItem.fromProduct(product)];
    }
  }

  void removeItem(String productId) {
    state = state.where((item) => item.productId != productId).toList();
  }

  void updateQuantity(String productId, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(productId);
      return;
    }

    state = [
      for (final item in state)
        if (item.productId == productId)
          item.copyWith(quantity: newQuantity)
        else
          item,
    ];
  }

  double get totalValue => state.fold(0, (total, item) => total + (item.price * item.quantity));
  int get totalItems => state.fold(0, (total, item) => total + item.quantity);

  void clearCart() {
    state = [];
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});