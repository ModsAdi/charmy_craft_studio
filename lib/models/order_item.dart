class OrderItem {
  final String productId;
  final String title;
  final String imageUrl;
  final double price;
  final int quantity;

  OrderItem({
    required this.productId,
    required this.title,
    required this.imageUrl,
    required this.price,
    required this.quantity,
  });

  // Convert to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'title': title,
      'imageUrl': imageUrl,
      'price': price,
      'quantity': quantity,
    };
  }

  // Create from a map from Firestore
  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      title: map['title'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      quantity: map['quantity'] ?? 0,
    );
  }

  // ++ ADD THIS METHOD ++
  // Allows creating a new instance with updated values.
  OrderItem copyWith({
    int? quantity,
  }) {
    return OrderItem(
      productId: this.productId,
      title: this.title,
      imageUrl: this.imageUrl,
      price: this.price,
      quantity: quantity ?? this.quantity,
    );
  }
}