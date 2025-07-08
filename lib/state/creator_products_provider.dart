// lib/state/creator_products_provider.dart

import 'package:charmy_craft_studio/models/product.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// This provider fetches ALL products.
// In a real-world app with many products, you'd want to fetch only the creator's products.
final creatorProductsProvider = StreamProvider<List<Product>>((ref) {
  final collection = FirebaseFirestore.instance
      .collection('products')
      .orderBy('title');

  return collection.snapshots().map((snapshot) {
    return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
  });
});