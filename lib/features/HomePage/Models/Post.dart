class UserPostModel {
  final String authorName;
  final String timeAgo;
  final String authorAvatarUrl;
  final String productImageUrl;
  final String productName;
  final String price;

  UserPostModel({
    required this.authorName,
    required this.timeAgo,
    required this.authorAvatarUrl,
    required this.productImageUrl,
    required this.productName,
    required this.price,
  });
}
