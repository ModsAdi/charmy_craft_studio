import 'package:charmy_craft_studio/services/auth_service.dart';
import 'package:charmy_craft_studio/services/firestore_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// This new provider fetches the entire Review object (rating + text).
final productReviewProvider = StreamProvider.autoDispose.family<Review?, String>((ref, productId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final user = ref.watch(authStateChangesProvider).value;

  if (user != null) {
    // We now call the new method to get the full review object
    return firestoreService.getCurrentUserReview(productId, user.uid);
  } else {
    return Stream.value(null);
  }
});