import 'package:charmy_craft_studio/models/order_item.dart';
import 'package:charmy_craft_studio/models/product.dart';
import 'package:charmy_craft_studio/models/user.dart';
import 'package:charmy_craft_studio/services/firestore_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

// Represents the state of our order creation screen
@immutable
class CreateOrderState {
  final UserModel? foundUser;
  final List<OrderItem> items;
  final bool isLoading;
  final String? errorMessage;

  const CreateOrderState({
    this.foundUser,
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  CreateOrderState copyWith({
    UserModel? foundUser,
    bool clearUser = false,
    List<OrderItem>? items,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CreateOrderState(
      foundUser: clearUser ? null : foundUser ?? this.foundUser,
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

// Manages the logic for the order creation process
class CreateOrderNotifier extends StateNotifier<CreateOrderState> {
  final Ref _ref;
  CreateOrderNotifier(this._ref) : super(const CreateOrderState());

  Future<void> findUserByEmail(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final firestore = _ref.read(firestoreServiceProvider);
    try {
      final user = await firestore.getUserByEmail(email); // We'll add this method next
      if (user != null) {
        state = state.copyWith(foundUser: user, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, errorMessage: 'User not found.');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> addProductById(String productId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final firestore = _ref.read(firestoreServiceProvider);
    try {
      final product = await firestore.getProductById(productId); // We'll add this method next
      if (product != null) {
        // Check if product is already in the list
        final existingIndex = state.items.indexWhere((item) => item.productId == product.id);
        if (existingIndex != -1) {
          // If it exists, increase quantity
          final updatedItems = List<OrderItem>.from(state.items);
          final existingItem = updatedItems[existingIndex];
          updatedItems[existingIndex] = OrderItem(
            productId: existingItem.productId,
            title: existingItem.title,
            imageUrl: existingItem.imageUrl,
            price: existingItem.price,
            quantity: existingItem.quantity + 1,
          );
          state = state.copyWith(items: updatedItems, isLoading: false);
        } else {
          // If new, add it to the list
          final newItem = OrderItem(
            productId: product.id,
            title: product.title,
            imageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
            price: product.discountedPrice ?? product.price,
            quantity: 1,
          );
          state = state.copyWith(items: [...state.items, newItem], isLoading: false);
        }
      } else {
        state = state.copyWith(isLoading: false, errorMessage: 'Product not found.');
      }
    } catch(e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void removeItem(String productId) {
    final updatedItems = state.items.where((item) => item.productId != productId).toList();
    state = state.copyWith(items: updatedItems);
  }

  void reset() {
    state = const CreateOrderState();
  }
}

final createOrderProvider = StateNotifierProvider.autoDispose<CreateOrderNotifier, CreateOrderState>((ref) {
  return CreateOrderNotifier(ref);
});