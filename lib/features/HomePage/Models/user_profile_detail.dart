import 'package:project_flutter/shared/models/user_profile.dart';
import 'package:project_flutter/features/HomePage/models/product.dart';

class UserProfileDetail {
  final UserProfile profile;       
  final List<ProductModel> userPosts;

  UserProfileDetail({
    required this.profile,
    this.userPosts = const [],
  });
}