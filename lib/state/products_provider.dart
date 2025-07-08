import 'package:charmy_craft_studio/models/product.dart';
import 'package:charmy_craft_studio/services/firestore_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final productsProvider = StreamProvider<List<Product>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  // ** FIX: The stream now filters for 'isArchived == false' **
  return firestoreService.getProducts().map((products) =>
      products.where((product) => !product.isArchived).toList()
  );
});