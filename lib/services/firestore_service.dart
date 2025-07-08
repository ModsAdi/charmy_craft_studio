// lib/services/firestore_service.dart

import 'dart:math';
import 'package:charmy_craft_studio/models/address.dart';
import 'package:charmy_craft_studio/models/artwork.dart';
import 'package:charmy_craft_studio/models/cart_item.dart';
import 'package:charmy_craft_studio/models/creator_profile.dart';
import 'package:charmy_craft_studio/models/order.dart' as my_order;
import 'package:charmy_craft_studio/models/product.dart';
import 'package:charmy_craft_studio/models/product_review.dart';
import 'package:charmy_craft_studio/models/user.dart';
import 'package:charmy_craft_studio/services/storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Ref _ref;

  FirestoreService(this._ref);

  // --- User Methods ---
  Future<UserModel?> getUser(String uid) async {
    final docSnap = await _db.collection('users').doc(uid).get();
    if (docSnap.exists) {
      return UserModel.fromFirestore(docSnap);
    }
    return null;
  }

  Future<UserModel?> getUserByEmail(String email) async {
    final querySnapshot = await _db
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return UserModel.fromFirestore(querySnapshot.docs.first);
    }
    return null;
  }

  Future<void> setUser(User user, {String? name}) async {
    final userRef = _db.collection('users').doc(user.uid);
    final doc = await userRef.get();
    final role = doc.exists ? doc.data()!['role'] : 'user';
    await userRef.set(
      {
        'uid': user.uid,
        'email': user.email,
        'displayName': name ?? user.displayName,
        'photoUrl': user.photoURL,
        'lastSeen': FieldValue.serverTimestamp(),
        'role': role,
      },
      SetOptions(merge: true),
    );
  }

  Future<void> updateUserDisplayName(String uid, String newName) async {
    try {
      final userDocRef = _db.collection('users').doc(uid);
      await userDocRef.update({'displayName': newName});

      final userDoc = await userDocRef.get();
      final userRole = (userDoc.data() as Map<String, dynamic>)['role'];

      if (userRole == 'creator') {
        await updateCreatorProfileDetails({'displayName': newName});
      }
    } catch (e) {
      throw Exception('Error updating display name in Firestore: $e');
    }
  }

  Future<void> updateUserPhotoUrl(String uid, String newPhotoUrl) async {
    try {
      await _db.collection('users').doc(uid).update({'photoUrl': newPhotoUrl});
    } catch (e) {
      throw Exception('Error updating photo URL in Firestore: $e');
    }
  }

  // --- Product Methods ---
  Stream<List<Product>> getProducts() {
    return _db
        .collection('products')
        .orderBy('title')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Product.fromFirestore(
        doc as DocumentSnapshot<Map<String, dynamic>>))
        .toList());
  }

  Future<Product?> getProductById(String productId) async {
    final docSnap = await _db.collection('products').doc(productId).get();
    if (docSnap.exists) {
      return Product.fromFirestore(
          docSnap as DocumentSnapshot<Map<String, dynamic>>);
    }
    return null;
  }

  Future<List<Product>> searchProductsByTitle(String query) async {
    if (query.isEmpty) {
      return [];
    }
    final querySnapshot = await _db
        .collection('products')
        .where('title', isGreaterThanOrEqualTo: query)
        .where('title', isLessThanOrEqualTo: query + '\uf8ff')
        .limit(10)
        .get();

    return querySnapshot.docs
        .map((doc) => Product.fromFirestore(
        doc as DocumentSnapshot<Map<String, dynamic>>))
        .toList();
  }

  Stream<Product> getProduct(String productId) {
    return _db.collection('products').doc(productId).snapshots().map(
            (snapshot) => Product.fromFirestore(
            snapshot as DocumentSnapshot<Map<String, dynamic>>));
  }

  Future<DocumentReference> addProduct(Product product) async {
    String newId;
    while (true) {
      // Generate a random 7-digit number as a string
      newId = (Random().nextInt(9000000) + 1000000).toString();
      final doc = await _db.collection('products').doc(newId).get();
      if (!doc.exists) {
        // If the ID is unique, break the loop
        break;
      }
    }

    // Create the document with the new unique ID
    final docRef = _db.collection('products').doc(newId);
    await docRef.set(product.toMap());
    return docRef;
  }

  Future<void> updateProduct(Product product) {
    return _db.collection('products').doc(product.id).update(product.toMap());
  }

  Future<void> deleteProduct(String productId) {
    return _db.collection('products').doc(productId).delete();
  }

  Future<void> setProductArchivedStatus(
      String productId, bool isArchived) async {
    try {
      await _db
          .collection('products')
          .doc(productId)
          .update({'isArchived': isArchived});
    } catch (e) {
      throw Exception('Error updating archive status: $e');
    }
  }

  // --- Artwork Methods ---
  Future<void> addArtwork(Artwork artwork) async {
    try {
      await _db.collection('artworks').add(artwork.toMap());
    } catch (e) {
      throw Exception('Error adding artwork to Firestore: $e');
    }
  }

  Future<void> updateArtwork(Artwork artwork) async {
    try {
      await _db.collection('artworks').doc(artwork.id).update(artwork.toMap());
    } catch (e) {
      throw Exception('Error updating artwork: $e');
    }
  }

  Future<void> setArtworkArchivedStatus(
      String artworkId, bool isArchived) async {
    try {
      await _db
          .collection('artworks')
          .doc(artworkId)
          .update({'isArchived': isArchived});
    } catch (e) {
      throw Exception('Error updating archive status: $e');
    }
  }

  Future<void> deleteArtwork(Artwork artwork) async {
    try {
      final storageService = _ref.read(storageServiceProvider);

      if (artwork.imageUrls.isNotEmpty) {
        for (final url in artwork.imageUrls) {
          await storageService.deleteImageFromUrl(url);
        }
      }
      if (artwork.thumbnailUrl.isNotEmpty) {
        await storageService.deleteImageFromUrl(artwork.thumbnailUrl);
      }

      await _db.collection('artworks').doc(artwork.id).delete();
    } catch (e) {
      throw Exception('Error deleting artwork: $e');
    }
  }

  // --- Favorite Methods ---
  Stream<List<String>> getFavoritesStream(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  Future<bool> isFavorite(String userId, String artworkId) async {
    final doc = await _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(artworkId)
        .get();
    return doc.exists;
  }

  Future<void> addFavorite(String userId, String artworkId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(artworkId)
        .set({'favoritedAt': FieldValue.serverTimestamp()});
  }

  Future<void> removeFavorite(String userId, String artworkId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(artworkId)
        .delete();
  }

  // --- Category Methods ---
  Future<void> addCategory(String categoryName) async {
    try {
      final querySnapshot = await _db
          .collection('categories')
          .orderBy('index', descending: true)
          .limit(1)
          .get();

      int newIndex = 1;
      if (querySnapshot.docs.isNotEmpty) {
        newIndex = (querySnapshot.docs.first.data()['index'] ?? 0) + 1;
      }

      await _db.collection('categories').add({
        'name': categoryName,
        'imageUrl': '',
        'index': newIndex,
      });
    } catch (e) {
      throw Exception('Error adding category: $e');
    }
  }

  Future<void> updateCategoryThumbnail(
      String categoryId, String newImageUrl) async {
    try {
      await _db
          .collection('categories')
          .doc(categoryId)
          .update({'imageUrl': newImageUrl});
    } catch (e) {
      throw Exception('Error updating category thumbnail: $e');
    }
  }

  // --- Creator Profile Methods ---
  Stream<CreatorProfile> getCreatorProfile() {
    return _db.collection('creator_profile').doc('my_profile').snapshots().map(
          (doc) => doc.exists
          ? CreatorProfile.fromFirestore(doc)
          : CreatorProfile(
          displayName: 'Charmy Craft',
          photoUrl: '',
          aboutMe: 'Tap edit to add your story!',
          socialLinks: [],
          whatsappNumber: '+910000000000'),
    );
  }

  Future<void> updateWhatsappNumber(String newNumber) async {
    await _db
        .collection('creator_profile')
        .doc('my_profile')
        .set(
      {'whatsappNumber': newNumber},
      SetOptions(merge: true),
    );
  }

  Future<void> updateAboutMe(String newText) async {
    await _db
        .collection('creator_profile')
        .doc('my_profile')
        .set(
      {'aboutMe': newText},
      SetOptions(merge: true),
    );
  }

  Future<void> updateSocialLinks(List<SocialLink> links) async {
    final linksAsMaps = links.map((link) => link.toMap()).toList();
    await _db
        .collection('creator_profile')
        .doc('my_profile')
        .set(
      {'socialLinks': linksAsMaps},
      SetOptions(merge: true),
    );
  }

  Future<DocumentSnapshot> getCreatorProfileDocument() async {
    return _db.collection('creator_profile').doc('my_profile').get();
  }

  Future<void> updateCreatorProfileDetails(Map<String, dynamic> data) async {
    await _db
        .collection('creator_profile')
        .doc('my_profile')
        .set(data, SetOptions(merge: true));
  }

  // --- Address Methods ---
  Stream<List<Address>> getAddresses(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Address.fromFirestore(
        doc as DocumentSnapshot<Map<String, dynamic>>))
        .toList());
  }

  Future<void> addAddress(String userId, Address address) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .add(address.toMap());
  }

  Future<void> updateAddress(String userId, Address address) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .doc(address.id)
        .update(address.toMap());
  }

  Future<void> deleteAddress(String userId, String addressId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .doc(addressId)
        .delete();
  }

  // --- Order Methods ---
  Future<void> createOrder(my_order.Order order) async {
    await _db.collection('orders').doc(order.id).set(order.toMap());
  }

  // ++ MODIFIED: Now fetches only active, unfulfilled orders ++
  Stream<List<my_order.Order>> getAllOrders() {
    return _db
        .collection('orders')
        .where('isFulfilled', isEqualTo: false) // <-- ADDED FILTER
        .orderBy('orderPlacementDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => my_order.Order.fromFirestore(
        doc as DocumentSnapshot<Map<String, dynamic>>))
        .toList());
  }

  // ++ NEW: Fetches only fulfilled orders ++
  Stream<List<my_order.Order>> getFulfilledOrders() {
    return _db
        .collection('orders')
        .where('isFulfilled', isEqualTo: true)
        .orderBy('orderPlacementDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => my_order.Order.fromFirestore(
        doc as DocumentSnapshot<Map<String, dynamic>>))
        .toList());
  }

  // ++ NEW: Marks an order as fulfilled ++
  Future<void> fulfillOrder(String orderId) {
    return _db.collection('orders').doc(orderId).update({'isFulfilled': true});
  }

  Stream<List<my_order.Order>> getMyOrders(String userId) {
    return _db
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('orderPlacementDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => my_order.Order.fromFirestore(
        doc as DocumentSnapshot<Map<String, dynamic>>))
        .toList());
  }

  Future<void> updateOrder(String orderId, Map<String, dynamic> data) async {
    await _db.collection('orders').doc(orderId).update(data);
  }

  // --- Review Methods ---
  Future<void> setReview(String productId, String userId, String userName,
      String userPhotoUrl, double rating, String text) async {
    final reviewRef =
    _db.collection('products').doc(productId).collection('reviews').doc(userId);
    await reviewRef.set({
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'rating': rating,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<ProductReview>> getReviewsForProduct(String productId) {
    return _db
        .collection('products')
        .doc(productId)
        .collection('reviews')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => ProductReview.fromFirestore(doc)).toList());
  }

  Stream<ProductReview?> getCurrentUserReview(String productId, String userId) {
    return _db
        .collection('products')
        .doc(productId)
        .collection('reviews')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return ProductReview.fromFirestore(doc);
      }
      return null;
    });
  }

  Future<void> deleteReview(String productId, String reviewId) async {
    await _db
        .collection('products')
        .doc(productId)
        .collection('reviews')
        .doc(reviewId)
        .delete();
  }

  // --- Cart Methods ---
  Stream<List<CartItem>> getCartStream(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('cart')
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => CartItem.fromFirestore(doc)).toList());
  }

  Future<void> addToCart(String userId, CartItem item) async {
    final cartRef =
    _db.collection('users').doc(userId).collection('cart').doc(item.id);
    await cartRef.set(item.toMap(), SetOptions(merge: true));
  }

  Future<void> removeFromCart(String userId, String productId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(productId)
        .delete();
  }

  Future<void> updateCartItemQuantity(
      String userId, String productId, int newQuantity) async {
    if (newQuantity < 1) {
      await removeFromCart(userId, productId);
    } else {
      await _db
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc(productId)
          .update({'quantity': newQuantity});
    }
  }

  Future<void> clearCart(String userId) async {
    final cartSnapshot =
    await _db.collection('users').doc(userId).collection('cart').get();
    for (var doc in cartSnapshot.docs) {
      await doc.reference.delete();
    }
  }
}

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService(ref);
});