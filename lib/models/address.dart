// lib/models/address.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Address {
  final String? id;
  final String country;
  final String fullName;
  final String mobileNumber;
  final String flatHouseNo;
  final String areaStreet;
  final String landmark;
  final String pincode;
  final String townCity;
  final String state;
  final bool isDefault;

  Address({
    this.id,
    required this.country,
    required this.fullName,
    required this.mobileNumber,
    required this.flatHouseNo,
    required this.areaStreet,
    required this.landmark,
    required this.pincode,
    required this.townCity,
    required this.state,
    this.isDefault = false,
  });

  // Convert Address object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'country': country,
      'fullName': fullName,
      'mobileNumber': mobileNumber,
      'flatHouseNo': flatHouseNo,
      'areaStreet': areaStreet,
      'landmark': landmark,
      'pincode': pincode,
      'townCity': townCity,
      'state': state,
      'isDefault': isDefault,
    };
  }

  // Create an Address object from a Firestore document
  factory Address.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Address(
      id: doc.id,
      country: data['country'] ?? '',
      fullName: data['fullName'] ?? '',
      mobileNumber: data['mobileNumber'] ?? '',
      flatHouseNo: data['flatHouseNo'] ?? '',
      areaStreet: data['areaStreet'] ?? '',
      landmark: data['landmark'] ?? '',
      pincode: data['pincode'] ?? '',
      townCity: data['townCity'] ?? '',
      state: data['state'] ?? '',
      isDefault: data['isDefault'] ?? false,
    );
  }
}