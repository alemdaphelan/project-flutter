import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:project_flutter/firestore_service.dart';
import 'package:project_flutter/features/Review/ReviewModel.dart';
import 'package:project_flutter/features/Notification/NotificationModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  List<ReviewModel> _allReviews = [];
  List<ReviewModel> _filteredReviews = [];
  bool _isLoading = true;
  int _selectedFilter = 0;
  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);
    try {
      List<ReviewModel> data = await _firestoreService.getReviewsForSeller(
        widget.sellerId,
      );
      setState(() {
        _allReviews = data;
        _applyFilter();
      });
    } catch (e) {
      debugPrint("Lỗi load đánh giá: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilter() {
    setState(() {
      if (_selectedFilter == 0) {
        _filteredReviews = List.from(_allReviews);
      } else {
        _filteredReviews = _allReviews.where((review) {
          return review.rating.toInt() == _selectedFilter;
        }).toList();
      }
    });
  }

  void _showAddReviewSheet() async {
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
    bool hasReviewed = _allReviews.any(
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF1B6B60)),
      ),
    );
    try {
      final orderQuery = await FirebaseFirestore.instance
          .collection('orders')
          .where('buyerId', isEqualTo: widget.currentUserId)
          .where('sellerId', isEqualTo: widget.sellerId)
          .limit(1)
          .get();
      if (context.mounted) Navigator.pop(context);
      if (orderQuery.docs.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Chỉ những ai đã mua hàng từ người này mới được đánh giá! 🛑',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      debugPrint('Lỗi kiểm tra quyền đánh giá: $e');
      return;
    }
    double currentRating = 5.0;
    final TextEditingController commentController = TextEditingController();
    bool isSubmitting = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                          ? null
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
                                ReviewModel newReview = ReviewModel(
                                  reviewId: '',
                                  reviewerId: widget.currentUserId,
                                  sellerId: widget.sellerId,
                                  productId: '',
                                  rating: currentRating,
                                  comment: commentController.text.trim(),
                                  time: DateTime.now().toString(),
                                );

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

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _buildFilterChip('Tất cả', 0),
            const SizedBox(width: 8),
            _buildFilterChip('5 Sao', 5),
            const SizedBox(width: 8),
            _buildFilterChip('4 Sao', 4),
            const SizedBox(width: 8),
            _buildFilterChip('3 Sao', 3),
            const SizedBox(width: 8),
            _buildFilterChip('2 Sao', 2),
            const SizedBox(width: 8),
            _buildFilterChip('1 Sao', 1),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int filterValue) {
    bool isSelected = _selectedFilter == filterValue;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (filterValue > 0) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.star,
              size: 14,
              color: isSelected ? Colors.amberAccent : Colors.amber,
            ),
          ],
        ],
      ),
      selected: isSelected,
      selectedColor: const Color(0xFF1B6B60),
      backgroundColor: Colors.grey.shade200,
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            _selectedFilter = filterValue;
            _applyFilter();
          });
        }
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? const Color(0xFF1B6B60) : Colors.transparent,
        ),
      ),
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
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          if (!_isLoading && _allReviews.isNotEmpty) _buildFilterSection(),
          if (!_isLoading && _allReviews.isNotEmpty)
            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1B6B60)),
                  )
                : _allReviews.isEmpty
                ? _buildEmptyState()
                : _filteredReviews.isEmpty
                ? Center(
                    child: Text(
                      'Không có đánh giá $_selectedFilter sao nào.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredReviews.length, // Xài list đã lọc
                    separatorBuilder: (context, index) =>
                        const Divider(height: 32),
                    itemBuilder: (context, index) {
                      final review = _filteredReviews[index];
                      return _buildReviewItem(review);
                    },
                  ),
          ),
        ],
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
