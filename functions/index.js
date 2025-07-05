const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

const db = admin.firestore();

/**
 * A Cloud Function that triggers whenever a review is written (created,
 * updated, or deleted) for any product.
 *
 * It recalculates the average rating and the total number of ratings
 * and updates the parent product document.
 */
exports.updateProductRating = functions.firestore
    .document("products/{productId}/reviews/{reviewId}")
    .onWrite(async (change, context) => {
      // Get the productId from the context parameters.
      const productId = context.params.productId;
      const productRef = db.collection("products").doc(productId);

      // Get a reference to the 'reviews' subcollection.
      const reviewsRef = productRef.collection("reviews");

      // Get all the review documents for the product.
      const reviewsSnapshot = await reviewsRef.get();

      if (reviewsSnapshot.empty) {
        // If there are no reviews left, reset the rating on the product.
        console.log(`No reviews for product ${productId}, resetting rating.`);
        return productRef.update({
          averageRating: 0,
          ratingCount: 0,
        });
      } else {
        // Calculate the new average rating and total count.
        const ratingCount = reviewsSnapshot.size;
        let totalRating = 0;
        reviewsSnapshot.forEach((doc) => {
          totalRating += doc.data().rating;
        });

        const averageRating = totalRating / ratingCount;

        console.log(
          `Updating product ${productId}: ` +
          `ratingCount=${ratingCount}, `+
          `averageRating=${averageRating.toFixed(1)}`
        );

        // Update the main product document with the new values.
        return productRef.update({
          // Round to one decimal place for a clean look (e.g., 4.1).
          averageRating: parseFloat(averageRating.toFixed(1)),
          ratingCount: ratingCount,
        });
      }
    });