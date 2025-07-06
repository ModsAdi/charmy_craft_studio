import 'package:charmy_craft_studio/models/product_review.dart'; // Import the correct model
import 'package:charmy_craft_studio/services/auth_service.dart';
import 'package:charmy_craft_studio/services/firestore_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// **FIX:** The provider now correctly uses `ProductReview?` as its return type.
final productReviewProvider = StreamProvider.autoDispose.family<ProductReview?, String>((ref, productId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final user = ref.watch(authStateChangesProvider).value;

  if (user != null) {
    // This now calls the corrected service method and gets the right object type
    return firestoreService.getCurrentUserReview(productId, user.uid);
  } else {
    return Stream.value(null);
  }
});