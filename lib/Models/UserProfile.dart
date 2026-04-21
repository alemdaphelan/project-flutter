class UserProfileModel {
  final String name;
  final String email;
  final String location;
  final int totalReviews;
  final double averageRating;
  final String avatarUrl;

  UserProfileModel({
    required this.name,
    required this.email,
    required this.location,
    required this.totalReviews,
    required this.averageRating,
    required this.avatarUrl,
  });
}
