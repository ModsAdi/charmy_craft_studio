import 'package:charmy_craft_studio/models/order_item.dart';
import 'package:charmy_craft_studio/models/product.dart';
import 'package:charmy_craft_studio/models/user.dart';
import 'package:charmy_craft_studio/services/firestore_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

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

class CreateOrderNotifier extends StateNotifier<CreateOrderState> {
  final Ref _ref;
  CreateOrderNotifier(this._ref) : super(const CreateOrderState());

  Future<void> findUserByEmail(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final firestore = _ref.read(firestoreServiceProvider);
    try {
      final user = await firestore.getUserByEmail(email);
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
    final firestore = _ref.read(firestoreServiceProvider);
    try {
      final product = await firestore.getProductById(productId);
      if (product != null) {
        final existingIndex = state.items.indexWhere((item) => item.productId == product.id);
        if (existingIndex != -1) {
          // If item exists, increase quantity using the new method
          updateItemQuantity(productId, state.items[existingIndex].quantity + 1);
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

  // ++ NEW FUNCTION TO HANDLE QUANTITY CHANGES ++
  void updateItemQuantity(String productId, int newQuantity) {
    // If quantity is zero or less, remove the item
    if (newQuantity < 1) {
      removeItem(productId);
      return;
    }

    // Otherwise, update the quantity of the specific item
    final updatedItems = state.items.map((item) {
      if (item.productId == productId) {
        return item.copyWith(quantity: newQuantity);
      }
      return item;
    }).toList();

    state = state.copyWith(items: updatedItems);
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