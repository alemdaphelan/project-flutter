import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String? displayName;
  final String? avatarUrl;
  final String? phoneNumber;
  final List<String>? interests;
  final String? bio;
  final bool hasCompletedProfile;
  final DateTime? updatedAt;

  UserProfile({
    required this.uid,
    this.displayName,
    this.avatarUrl,
    this.phoneNumber,
    this.interests,
    this.bio,
    this.hasCompletedProfile = false,
    this.updatedAt,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map, String uid) {
    return UserProfile(
      uid: uid,
      displayName: map['displayName'] as String?,
      avatarUrl: map['avatarUrl'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      interests: map['interests'] != null
          ? List<String>.from(map['interests'])
          : [],
      bio: map['bio'] as String?,
      hasCompletedProfile: map['hasCompletedProfile'] as bool? ?? false,
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'phoneNumber': phoneNumber,
      'interests': interests ?? [],
      'bio': bio,
      'hasCompletedProfile': true,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Tạo bản sao với các trường được cập nhật
  UserProfile copyWith({
    String? displayName,
    String? avatarUrl,
    String? phoneNumber,
    List<String>? interests,
    String? bio,
    bool? hasCompletedProfile,
  }) {
    return UserProfile(
      uid: uid,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      interests: interests ?? this.interests,
      bio: bio ?? this.bio,
      hasCompletedProfile: hasCompletedProfile ?? this.hasCompletedProfile,
    );
  }
}