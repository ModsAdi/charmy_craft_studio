// lib/state/create_order_provider.dart

import 'package:charmy_craft_studio/models/order_item.dart';
import 'package:charmy_craft_studio/models/product.dart';
import 'package:charmy_craft_studio/models/user.dart';
import 'package:charmy_craft_studio/services/firestore_service.dart';
import 'package:charmy_craft_studio/services/order_parser_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  Future<void> parseAndFillOrder(String message) async {
    state = state.copyWith(isLoading: true, clearError: true, items: []);
    final parser = _ref.read(orderParserServiceProvider);
    final firestore = _ref.read(firestoreServiceProvider);

    try {
      final parsedData = parser.parseOrderFromString(message);

      if (parsedData.email == null) {
        throw Exception("Could not find a valid email in the message.");
      }

      final user = await firestore.getUserByEmail(parsedData.email!);
      if (user == null) {
        throw Exception("Customer with email '${parsedData.email}' not found.");
      }

      final orderItems =
      await parser.convertParsedItemsToOrderItems(parsedData.parsedItems);
      if (orderItems.isEmpty) {
        throw Exception("Could not find any valid products in the message.");
      }

      state =
          state.copyWith(foundUser: user, items: orderItems, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> findUserByEmail(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _ref.read(firestoreServiceProvider).getUserByEmail(email);
      if (user != null) {
        state = state.copyWith(foundUser: user, isLoading: false);
      } else {
        state = state.copyWith(
            isLoading: false, errorMessage: 'No user found for that email.');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> addProductById(String productId) async {
    state = state.copyWith(isLoading: true);
    try {
      final product =
      await _ref.read(firestoreServiceProvider).getProductById(productId);
      if (product != null) {
        final existingItemIndex =
        state.items.indexWhere((item) => item.productId == productId);
        if (existingItemIndex != -1) {
          // If item exists, increase quantity
          final updatedItems = List<OrderItem>.from(state.items);
          final existingItem = updatedItems[existingItemIndex];
          updatedItems[existingItemIndex] =
              existingItem.copyWith(quantity: existingItem.quantity + 1);
          state = state.copyWith(items: updatedItems, isLoading: false);
        } else {
          // If item does not exist, add it to the list
          final newItem = OrderItem(
            productId: product.id,
            title: product.title,
            imageUrl:
            product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
            price: product.discountedPrice ?? product.price,
            quantity: 1,
          );
          state =
              state.copyWith(items: [...state.items, newItem], isLoading: false);
        }
      } else {
        state = state.copyWith(
            isLoading: false, errorMessage: 'Product not found');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void updateItemQuantity(String productId, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(productId);
      return;
    }
    final updatedItems = state.items.map((item) {
      if (item.productId == productId) {
        return item.copyWith(quantity: newQuantity);
      }
      return item;
    }).toList();
    state = state.copyWith(items: updatedItems);
  }

  void removeItem(String productId) {
    final updatedItems =
    state.items.where((item) => item.productId != productId).toList();
    state = state.copyWith(items: updatedItems);
  }

  void reset() {
    state = const CreateOrderState();
  }
}

final createOrderProvider =
StateNotifierProvider.autoDispose<CreateOrderNotifier, CreateOrderState>(
        (ref) {
      return CreateOrderNotifier(ref);
    });