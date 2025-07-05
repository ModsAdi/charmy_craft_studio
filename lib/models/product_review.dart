import 'package:cloud_firestore/cloud_firestore.dart';

class ProductReview {
  final String id; // The user's UID who wrote the review
  final String userName;
  final String userPhotoUrl;
  final double rating;
  final String text;
  final Timestamp timestamp;

  ProductReview({
    required this.id,
    required this.userName,
    required this.userPhotoUrl,
    required this.rating,
    required this.text,
    required this.timestamp,
  });

  factory ProductReview.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return ProductReview(
      id: doc.id,
      userName: data['userName'] ?? 'Anonymous',
      userPhotoUrl: data['userPhotoUrl'] ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      text: data['text'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }
}