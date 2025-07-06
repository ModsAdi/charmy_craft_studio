import 'package:cloud_firestore/cloud_firestore.dart';

class CartItem {
  final String id; // This will be the Product ID
  final String title;
  final double price;
  final String imageUrl;
  int quantity;

  CartItem({
    required this.id,
    required this.title,
    required this.price,
    required this.imageUrl,
    this.quantity = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'imageUrl': imageUrl,
      'quantity': quantity,
    };
  }

  factory CartItem.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return CartItem(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: data['imageUrl'] ?? '',
      quantity: (data['quantity'] as num?)?.toInt() ?? 0,
    );
  }
}