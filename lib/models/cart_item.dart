// lib/models/cart_item.dart

import 'package:charmy_craft_studio/models/product.dart';

class CartItem {
  final String productId;
  final String title;
  final String imageUrl;
  final double price;
  final int quantity;

  CartItem({
    required this.productId,
    required this.title,
    required this.imageUrl,
    required this.price,
    required this.quantity,
  });

  // A factory to create a CartItem from a Product
  factory CartItem.fromProduct(Product product) {
    return CartItem(
      productId: product.id,
      title: product.title,
      imageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
      price: product.discountedPrice ?? product.price,
      quantity: 1,
    );
  }

  CartItem copyWith({int? quantity}) {
    return CartItem(
      productId: productId,
      title: title,
      imageUrl: imageUrl,
      price: price,
      quantity: quantity ?? this.quantity,
    );
  }
}