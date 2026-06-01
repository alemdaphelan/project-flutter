import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:project_flutter/firestore_service.dart';
import 'package:project_flutter/features/Review/ReviewModel.dart';
import 'package:project_flutter/features/Notification/NotificationModel.dart';

class SellerReviewsScreen extends StatefulWidget {
  final String sellerId;
  final String currentUserId;

  const SellerReviewsScreen({
    super.key,
    required this.sellerId,
    required this.currentUserId,
  });

  @override
  State<SellerReviewsScreen> createState() => _SellerReviewsScreenState();
}

class _SellerReviewsScreenState extends State<SellerReviewsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<ReviewModel> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  // Hàm bốc data từ Firebase
  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);
    try {
      List<ReviewModel> data = await _firestoreService.getReviewsForSeller(
        widget.sellerId,
      );
      setState(() {
        _reviews = data;
      });
    } catch (e) {
      print("Lỗi load đánh giá: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ==========================================
  // LOGIC HIỂN THỊ BOTTOM SHEET ĐỂ VIẾT ĐÁNH GIÁ
  void _showAddReviewSheet() {
    // 1. Chặn tự sướng
    if (widget.currentUserId == widget.sellerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ê, không được tự đánh giá (seeding) cho bản thân nhé!',
          ),
        ),
      );
      return;
    }

    // 2. CHỐT CHẶN ANTI-SPAM TẦNG UI
    bool hasReviewed = _reviews.any(
      (review) => review.reviewerId == widget.currentUserId,
    );
    if (hasReviewed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn đã đánh giá người này rồi. Không được spam!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    double currentRating = 5.0; // Mặc định vô là cho 5 sao
    final TextEditingController commentController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled:
          true, // Cho phép sheet đẩy lên cao khi bàn phím xuất hiện
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Đánh giá người bán',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  RatingBar.builder(
                    initialRating: 5,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                    itemBuilder: (context, _) =>
                        const Icon(Icons.star, color: Colors.amber),
                    onRatingUpdate: (rating) {
                      currentRating = rating;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Ô nhập comment
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Người bán này thế nào? Hàng họ ra sao...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF1B6B60),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Nút Gửi Đánh Giá
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B6B60),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isSubmitting
                          ? null // Nếu đang gửi thì khóa nút lại
                          : () async {
                              if (commentController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Viết vài lời nhận xét đi bro!',
                                    ),
                                  ),
                                );
                                return;
                              }

                              setModalState(() => isSubmitting = true);

                              try {
                                // Khởi tạo Model
                                ReviewModel newReview = ReviewModel(
                                  reviewId: '', // Firebase tự gen
                                  reviewerId: widget.currentUserId,
                                  sellerId: widget.sellerId,
                                  productId:
                                      '', // Tạm thời để trống nếu đây là đánh giá chung người bán
                                  rating: currentRating,
                                  comment: commentController.text.trim(),
                                  time: '', // Firebase tự lo
                                );

                                // Bắn lên mây
                                await _firestoreService.addReview(
                                  newReview.toMap(),
                                );
                                await _firestoreService.triggerNotification(
                                  receiverId: widget.sellerId,
                                  title: 'Đánh giá mới! ⭐',
                                  body:
                                      'Bạn vừa nhận được đánh giá $currentRating sao từ người mua.',
                                  type: NotificationType.review,
                                  relatedId: widget.currentUserId,
                                );
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  _loadReviews();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Đã gửi đánh giá thành công!',
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                setModalState(() => isSubmitting = false);
                              }
                            },
                      child: isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Gửi đánh giá',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F8F7),
      appBar: AppBar(
        title: const Text(
          'Đánh giá & Nhận xét',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1B6B60)),
            )
          : _reviews.isEmpty
          ? _buildEmptyState() // Trạng thái chưa có ai đánh giá
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _reviews.length,
              separatorBuilder: (context, index) => const Divider(height: 32),
              itemBuilder: (context, index) {
                final review = _reviews[index];
                return _buildReviewItem(review);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1B6B60),
        onPressed: _showAddReviewSheet,
        icon: const Icon(Icons.edit, color: Colors.white),
        label: const Text(
          'Viết đánh giá',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.speaker_notes_off_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Người bán này chưa có đánh giá nào.\nHãy là người đầu tiên bóc phốt họ!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(ReviewModel review) {
    String reviewerName = review.reviewer?.displayName ?? 'Người dùng ẩn danh';
    String avatarUrl = review.reviewer?.avatarUrl ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey.shade300,
          backgroundImage: avatarUrl.isNotEmpty
              ? NetworkImage(avatarUrl)
              : null,
          child: avatarUrl.isEmpty
              ? const Icon(Icons.person, color: Colors.white)
              : null,
        ),
        const SizedBox(width: 12),
        // Nội dung review
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reviewerName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              RatingBarIndicator(
                rating: review.rating,
                itemBuilder: (context, index) =>
                    const Icon(Icons.star, color: Colors.amber),
                itemCount: 5,
                itemSize: 16.0,
                direction: Axis.horizontal,
              ),
              const SizedBox(height: 8),
              Text(
                review.comment,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                review.time.split(' ')[0],
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
