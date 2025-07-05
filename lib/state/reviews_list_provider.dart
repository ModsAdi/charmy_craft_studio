import 'package:charmy_craft_studio/models/product_review.dart';
import 'package:charmy_craft_studio/services/firestore_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final reviewsListProvider = StreamProvider.autoDispose.family<List<ProductReview>, String>((ref, productId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getReviewsForProduct(productId);
});