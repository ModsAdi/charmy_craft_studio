// lib/state/single_product_provider.dart

import 'package:charmy_craft_studio/models/product.dart';
import 'package:charmy_craft_studio/services/firestore_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final singleProductProvider = StreamProvider.family<Product, String>((ref, productId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getProduct(productId);
});