import 'package:charmy_craft_studio/models/product.dart';
import 'package:charmy_craft_studio/services/auth_service.dart';
import 'package:charmy_craft_studio/services/firestore_service.dart';
import 'package:charmy_craft_studio/state/cart_provider.dart';
// ** FIX 1: Corrected the import path to the new provider file. **
import 'package:charmy_craft_studio/state/product_review_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class ExpandedProductContentWidget extends ConsumerWidget {
  final Product product;

  const ExpandedProductContentWidget({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasDiscount = product.discountedPrice != null && product.discountedPrice! < product.price;
    // ** FIX 2: Calling the renamed provider 'productReviewProvider'. **
    final userReviewAsync = ref.watch(productReviewProvider(product.id));
    final currentUser = ref.watch(authStateChangesProvider).value;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 380, // This value controls the title's vertical position
            left: 24,
            right: 24,
            child: Text(
              product.title,
              style: GoogleFonts.lato(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.left,
            ),
          ),
          Positioned(
            bottom: 20,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '₹${(product.discountedPrice ?? product.price).toStringAsFixed(0)}',
                              style: GoogleFonts.lato(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                                fontSize: 18,
                              ),
                            ),
                            if (hasDiscount)
                              Padding(
                                padding: const EdgeInsets.only(left: 6.0),
                                child: Text(
                                  '₹${product.price.toStringAsFixed(0)}',
                                  style: GoogleFonts.lato(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (hasDiscount)
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Text(
                              '${product.discountPercentage}% OFF',
                              style: GoogleFonts.lato(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    _buildRatingWidget(userReviewAsync, currentUser, ref),
                  ],
                ),
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  child: IconButton(
                    iconSize: 22,
                    onPressed: () {
                      ref.read(cartProvider.notifier).addItem(product);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Added to cart!')),
                      );
                    },
                    icon: const Icon(Icons.add_shopping_cart_outlined),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ** FIX 3: The `_buildRatingWidget` method is updated to call the correct `setReview` function. **
  Widget _buildRatingWidget(AsyncValue<Review?> userReviewAsync, dynamic currentUser, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        RatingBar.builder(
          initialRating: userReviewAsync.value?.rating ?? 0.0,
          minRating: 1,
          direction: Axis.horizontal,
          itemCount: 5,
          itemSize: 18.0,
          itemPadding: const EdgeInsets.symmetric(horizontal: 0.5),
          itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
          onRatingUpdate: (rating) {
            if (currentUser != null) {
              // Calling the new 'setReview' method with all required arguments.
              ref.read(firestoreServiceProvider).setReview(
                product.id,
                currentUser.uid,
                currentUser.displayName ?? 'Anonymous',
                currentUser.photoURL ?? '',
                rating,
                userReviewAsync.value?.text ?? "", // Pass existing text or empty string
              );
            }
          },
        ),
        const SizedBox(height: 4),
        if (product.ratingCount > 0)
          Text(
            '${product.averageRating.toStringAsFixed(1)} (${product.ratingCount})',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          )
        else
          Text(
            'No ratings yet',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
      ],
    );
  }
}