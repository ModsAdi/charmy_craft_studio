// lib/models/order.dart

import 'package:charmy_craft_studio/models/order_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Order {
  final String id;
  final String userId;
  final String userEmail;
  final String userName;
  final List<OrderItem> items;
  final double totalValue;
  final DateTime orderPlacementDate;
  final DateTime? approximateDeliveryDate;
  final String status;
  final bool advancePaid;
  final String? deliveryMode;
  final String? specialNote;
  final Map<String, dynamic>? trackingDetails;
  final String? trackingLink;
  final bool isFulfilled; // <-- NEW FIELD

  Order({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.items,
    required this.totalValue,
    required this.orderPlacementDate,
    this.approximateDeliveryDate,
    required this.status,
    required this.advancePaid,
    this.deliveryMode,
    this.specialNote,
    this.trackingDetails,
    this.trackingLink,
    this.isFulfilled = false, // <-- ADDED TO CONSTRUCTOR
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'items': items.map((item) => item.toMap()).toList(),
      'totalValue': totalValue,
      'orderPlacementDate': Timestamp.fromDate(orderPlacementDate),
      'approximateDeliveryDate': approximateDeliveryDate != null
          ? Timestamp.fromDate(approximateDeliveryDate!)
          : null,
      'status': status,
      'advancePaid': advancePaid,
      'deliveryMode': deliveryMode,
      'specialNote': specialNote,
      'trackingDetails': trackingDetails,
      'trackingLink': trackingLink,
      'isFulfilled': isFulfilled, // <-- ADDED TO MAP
    };
  }

  factory Order.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Order(
      id: doc.id,
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      userName: data['userName'] ?? '',
      items: (data['items'] as List<dynamic>? ?? [])
          .map((itemData) =>
          OrderItem.fromMap(itemData as Map<String, dynamic>))
          .toList(),
      totalValue: (data['totalValue'] ?? 0.0).toDouble(),
      orderPlacementDate: (data['orderPlacementDate'] as Timestamp).toDate(),
      approximateDeliveryDate:
      (data['approximateDeliveryDate'] as Timestamp?)?.toDate(),
      status: data['status'] ?? 'Pending',
      advancePaid: data['advancePaid'] ?? false,
      deliveryMode: data['deliveryMode'],
      specialNote: data['specialNote'],
      trackingDetails: data['trackingDetails'] != null
          ? Map<String, dynamic>.from(data['trackingDetails'])
          : null,
      trackingLink: data['trackingLink'],
      isFulfilled: data['isFulfilled'] ?? false, // <-- ADDED FROM FIRESTORE
    );
  }
}