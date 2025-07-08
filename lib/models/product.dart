// lib/models/product.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String title;
  final String description;
  final List<String> imageUrls;
  final double price;
  final double? discountedPrice;
  final int? discountPercentage;
  final DateTime? discountCountdown;
  final String deliveryTime;
  final bool requiresAdvance;
  final double averageRating;
  final int ratingCount;
  final bool isArchived; // <-- NEW FIELD

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrls,
    required this.price,
    this.discountedPrice,
    this.discountPercentage,
    this.discountCountdown,
    required this.deliveryTime,
    required this.requiresAdvance,
    this.averageRating = 0.0,
    this.ratingCount = 0,
    this.isArchived = false, // <-- NEW FIELD
  });

  // Factory to create a Product from a Firestore document
  factory Product.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Product(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      price: (data['price'] ?? 0.0).toDouble(),
      discountedPrice: (data['discountedPrice'])?.toDouble(),
      discountPercentage: data['discountPercentage'],
      discountCountdown: (data['discountCountdown'] as Timestamp?)?.toDate(),
      deliveryTime: data['deliveryTime'] ?? 'N/A',
      requiresAdvance: data['requiresAdvance'] ?? false,
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      ratingCount: data['ratingCount'] ?? 0,
      isArchived: data['isArchived'] ?? false, // <-- NEW FIELD
    );
  }

  // Method to convert a Product object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'imageUrls': imageUrls,
      'price': price,
      'discountedPrice': discountedPrice,
      'discountPercentage': discountPercentage,
      'discountCountdown': discountCountdown != null ? Timestamp.fromDate(discountCountdown!) : null,
      'deliveryTime': deliveryTime,
      'requiresAdvance': requiresAdvance,
      'averageRating': averageRating,
      'ratingCount': ratingCount,
      'isArchived': isArchived, // <-- NEW FIELD
    };
  }
}