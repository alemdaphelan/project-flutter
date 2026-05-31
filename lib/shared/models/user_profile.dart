import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String? displayName;
  final String? email;
  final String? avatarUrl;
  final String? phoneNumber;
  final String? location;
  final List<String>? interests;
  final String? bio;
  final bool hasCompletedProfile;
  final double averageRating;
  final int totalReviews;
  final DateTime? updatedAt;

  UserProfile({
    required this.uid,
    this.displayName,
    this.email,
    this.avatarUrl,
    this.phoneNumber,
    this.location,
    this.interests,
    this.bio,
    this.hasCompletedProfile = false,
    this.averageRating = 0.0,
    this.totalReviews = 0,
    this.updatedAt,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map, String uid) {
    return UserProfile(
      uid: uid,
      displayName: map['displayName'] as String?, // thống nhất key
      email: map['email'] as String?,
      avatarUrl: map['avatarUrl'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      location: map['location'] as String?,
      interests: map['interests'] != null
          ? List<String>.from(map['interests'])
          : [],
      bio: map['bio'] as String?,
      hasCompletedProfile: map['hasCompletedProfile'] as bool? ?? false,
      averageRating: (map['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: map['totalReviews'] as int? ?? 0,
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      'avatarUrl': avatarUrl,
      'phoneNumber': phoneNumber,
      'location': location,
      'interests': interests ?? [],
      'bio': bio,
      'hasCompletedProfile': hasCompletedProfile,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  UserProfile copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? avatarUrl,
    String? phoneNumber,
    String? location,
    List<String>? interests,
    String? bio,
    bool? hasCompletedProfile,
    double? averageRating,
    int? totalReviews,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      location: location ?? this.location,
      interests: interests ?? this.interests,
      bio: bio ?? this.bio,
      hasCompletedProfile: hasCompletedProfile ?? this.hasCompletedProfile,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
