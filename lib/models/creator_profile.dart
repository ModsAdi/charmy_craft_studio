// lib/models/creator_profile.dart

import 'package:cloud_firestore/cloud_firestore.dart';

// SocialLink class remains the same
class SocialLink {
  final String name;
  final String url;
  final String icon;

  SocialLink({required this.name, required this.url, required this.icon});

  Map<String, dynamic> toMap() {
    return {'name': name, 'url': url, 'icon': icon};
  }

  factory SocialLink.fromMap(Map<String, dynamic> map) {
    return SocialLink(
      name: map['name'] ?? '',
      url: map['url'] ?? '',
      icon: map['icon'] ?? 'link',
    );
  }
}

class CreatorProfile {
  // NEW: Added displayName and photoUrl
  final String displayName;
  final String photoUrl;
  final String aboutMe;
  final List<SocialLink> socialLinks;
  final String whatsappNumber;

  CreatorProfile({
    required this.displayName,
    required this.photoUrl,
    required this.aboutMe,
    required this.socialLinks,
    required this.whatsappNumber,
  });

  factory CreatorProfile.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    var linksFromDb = data['socialLinks'] as List<dynamic>? ?? [];
    List<SocialLink> links = linksFromDb
        .map((linkData) => SocialLink.fromMap(linkData as Map<String, dynamic>))
        .toList();

    return CreatorProfile(
      displayName: data['displayName'] ?? 'Charmy Craft',
      photoUrl: data['photoUrl'] ?? '',
      aboutMe: data['aboutMe'] ?? 'About me section...',
      socialLinks: links,
      // ** ADD THIS LINE (with a default number) **
      whatsappNumber: data['whatsappNumber'] ?? '+910000000000',
    );
  }
}