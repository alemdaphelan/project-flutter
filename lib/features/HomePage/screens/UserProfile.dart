import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Đã thêm thư viện cache
import 'package:project_flutter/features/HomePage/widgets/ProductList.dart';
import 'package:project_flutter/firestore_service.dart';
import 'package:project_flutter/shared/models/user_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project_flutter/features/Review/ReviewScreen.dart';
import 'package:project_flutter/features/Review/ReviewModel.dart'; // Đã thêm import Model

class ProfileScreen extends StatelessWidget {
  final UserProfile userProfile;

  final Color primaryTeal = const Color(0xFF1B6B60);
  final Color bgColor = const Color(0xFFF2F8F7);
  final FirestoreService _firestore = FirestoreService();

  ProfileScreen({super.key, required this.userProfile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Oldie',
              style: TextStyle(
                color: primaryTeal,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFEEEEEE),
                  ),
                ],
              ),
            ),
            _buildSectionTitle(context),
            ProductList(
              firestore: _firestore,
              userId: userProfile.uid,
              searchQuery: '',
              selectedCategory: 'All',
              showSold: true,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final hasValidAvatar = userProfile.avatarUrl?.isNotEmpty ?? false;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: primaryTeal, width: 2),
            ),
            child: ClipOval(
              child: Container(
                width: 80,
                height: 80,
                color: Colors.grey.shade300,
                child: hasValidAvatar
                    ? CachedNetworkImage(
                        imageUrl: userProfile.avatarUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.grey,
                        ),
                      )
                    : const Icon(Icons.person, size: 40, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userProfile.displayName ?? 'Tên người dùng',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                _buildInfoRow(
                  Icons.email_outlined,
                  userProfile.email ?? 'Email không xác định',
                ),
                const SizedBox(height: 4),
                FutureBuilder<List<ReviewModel>>(
                  future: _firestore.getReviewsForSeller(userProfile.uid),
                  builder: (context, snapshot) {
                    // Trạng thái đang tải dữ liệu
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text(
                        'Đang tải đánh giá...',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      );
                    }

                    // Trạng thái lỗi hoặc không có data
                    if (snapshot.hasError) {
                      return const Text(
                        'Lỗi tải đánh giá',
                        style: TextStyle(fontSize: 14, color: Colors.red),
                      );
                    }

                    // Lấy danh sách review ra để xử lý
                    final reviews = snapshot.data ?? [];
                    final int totalReviews = reviews.length;
                    double averageRating = 0.0;

                    // Tính trung bình cộng nếu có đánh giá
                    if (totalReviews > 0) {
                      double sum = 0.0;
                      for (var review in reviews) {
                        sum += review.rating;
                      }
                      averageRating = sum / totalReviews;
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tổng đánh giá: $totalReviews',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              // toStringAsFixed(1) để hiển thị 1 chữ số thập phân, vd: 4.5
                              'Đánh giá trung bình: ${averageRating.toStringAsFixed(1)} ',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.black,
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                // ==========================================
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.black87),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Bài viết đã đăng',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          OutlinedButton.icon(
            // ========================================================
            // KỸ SƯ RÁP CODE ĐIỀU HƯỚNG SANG MÀN HÌNH REVIEW Ở ĐÂY:
            // ========================================================
            onPressed: () {
              String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SellerReviewsScreen(
                    sellerId: userProfile
                        .uid, // Mở kho review của chính chủ profile này
                    currentUserId: currentUid, // ID thằng đang đi xem
                  ),
                ),
              );
            },
            // ========================================================
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryTeal,
              side: BorderSide(color: primaryTeal),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.rate_review_outlined, size: 16),
            label: const Text(
              'Xem đánh giá',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
