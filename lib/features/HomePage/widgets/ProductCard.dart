import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_flutter/features/HomePage/Models/Product.dart';
import 'package:project_flutter/features/HomePage/screens/UserProfile.dart';
import 'package:project_flutter/features/HomePage/screens/DetailListing.dart';
import 'package:project_flutter/features/payment/screens/checkout_screen.dart';
import 'package:project_flutter/features/HomePage/utils/timeFormat.dart';
import 'package:project_flutter/features/TinNhan/screens/chat_screen.dart';
import 'package:project_flutter/features/TinNhan/services/firebase_chat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project_flutter/features/HomePage/utils/SmartImage.dart';import 'package:cached_network_image/cached_network_image.dart';
class ProductCard extends StatelessWidget {
  final ProductModel product;
  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final sellerName = product.seller?.displayName ?? 'Người bán ẩn danh';
    final sellerEmail = product.seller?.email ?? 'Không có thông tin';
    final sellerAvatar =
        product.seller?.avatarUrl ?? 'https://i.pravatar.cc/150';
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = currentUid != null && currentUid == product.sellerId;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (product.seller != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ProfileScreen(userProfile: product.seller!),
                      ),
                    );
                  }
                },
                // ── StreamBuilder để real-time listen avatar từ Firestore ──
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(product.sellerId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    String avatarUrl =
                        product.seller?.avatarUrl ?? 'https://i.pravatar.cc/150';

                    if (snapshot.hasData &&
                        snapshot.data?.exists == true) {
                      final userData = snapshot.data!.data() as Map?;
                      avatarUrl = (userData?['avatarUrl'] ?? avatarUrl) as String;
                    }

                    return SmartImage(
                      imagePath: avatarUrl,
                      width: 40,
                      height: 40,
                      borderRadius: 20,
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sellerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      sellerEmail,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // ĐÓNG GÓI KHU VỰC THỜI GIAN VÀ NÚT LƯU BÀI VIẾT VÀO MỘT COLUMN
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatTimeAgo(DateTime.parse(product.time)),
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),

                  // ========================================================
                  // KỸ SƯ RÁP BIỂU TƯỢNG VÀ LOGIC LƯU BÀI VIẾT REAL-TIME
                  // ========================================================
                  if (currentUid != null)
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(currentUid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        bool isSaved = false;

                        if (snapshot.hasData && snapshot.data!.exists) {
                          var userData =
                              snapshot.data!.data() as Map<String, dynamic>?;
                          // Bốc cái mảng danh sách bài viết đã lưu về
                          List<dynamic> savedProducts =
                              userData?['savedProducts'] ?? [];
                          // Kiểm tra xem ID của sản phẩm này đã nằm trong mảng chưa
                          isSaved = savedProducts.contains(product.id);
                        }

                        return IconButton(
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.only(top: 4),
                          icon: Icon(
                            isSaved
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            color: isSaved
                                ? const Color(0xFF1B6B60)
                                : Colors.grey.shade400,
                            size: 22,
                          ),
                          onPressed: () async {
                            final userDocRef = FirebaseFirestore.instance
                                .collection('users')
                                .doc(currentUid);

                            if (isSaved) {
                              // Nếu đã lưu rồi -> Bấm vào để BỎ LƯU
                              await userDocRef.update({
                                'savedProducts': FieldValue.arrayRemove([
                                  product.id,
                                ]),
                              });
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('💔 Đã bỏ lưu bài viết này!'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              }
                            } else {
                              // Nếu chưa lưu -> Bấm vào để LƯU BÀI VIẾT
                              await userDocRef.update({
                                'savedProducts': FieldValue.arrayUnion([
                                  product.id,
                                ]),
                              });
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      '💖 Đã lưu bài viết vào mục yêu thích!',
                                    ),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              }
                            }
                          },
                        );
                      },
                    ),
                  // ========================================================
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(product: product),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                SmartImage(
                  imagePath: product.productImageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  borderRadius: 10,
                ),
                const SizedBox(height: 10),
                Text(
                  '${product.price.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} VNĐ',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Color(0xFF1B6B60),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.description,
                  style: const TextStyle(color: Colors.black87, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: Colors.grey,
                size: 16,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  product.location,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: isOwner
                      ? null
                      : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CheckoutScreen(product: product),
                          ),
                        ),
                  icon: Icon(
                    Icons.shopping_cart_outlined,
                    size: 16,
                    color: isOwner ? Colors.grey.shade500 : Colors.white,
                  ),
                  label: Text(
                    isOwner ? 'Của bạn' : 'Mua hàng',
                    style: TextStyle(
                      fontSize: 12,
                      color: isOwner ? Colors.grey.shade500 : Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isOwner
                        ? Colors.grey.shade300
                        : const Color(0xFF4C9A82),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 4,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (c) =>
                          const Center(child: CircularProgressIndicator()),
                    );

                    final chatService = FirebaseChatService();
                    String myCurrentUserId =
                        FirebaseAuth.instance.currentUser!.uid;
                    String roomId = await chatService.getOrCreateChatRoom(
                      buyerId: myCurrentUserId,
                      sellerId: product.sellerId,
                      productName: product.productName,
                      sellerName: product.sellerName,
                      isOffer: false,
                    );

                    if (context.mounted) Navigator.pop(context);

                    if (roomId.isNotEmpty && context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            chatRoomId: roomId,
                            isSellerViewInit: false,
                            titleName: product.sellerName,
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(
                    Icons.chat_outlined,
                    size: 16,
                    color: Color(0xFF4C9A82),
                  ),
                  label: const Text(
                    'Liên hệ người bán',
                    style: TextStyle(fontSize: 12, color: Color(0xFF4C9A82)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF4C9A82)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: OutlinedButton.icon(
                  onPressed: isOwner
                      ? null
                      : () async {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (c) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );

                          final chatService = FirebaseChatService();
                          String myCurrentUserId =
                              FirebaseAuth.instance.currentUser!.uid;
                          String roomId = await chatService.getOrCreateChatRoom(
                            buyerId: myCurrentUserId,
                            sellerId: product.sellerId,
                            productName: product.productName,
                            sellerName: product.sellerName,
                            isOffer: false,
                          );

                          if (context.mounted) Navigator.pop(context);

                          if (roomId.isNotEmpty && context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  chatRoomId: roomId,
                                  isSellerViewInit: false,
                                  titleName: product.sellerName,
                                  autoShowOffer: true,
                                  initOfferPrice: product.price,
                                  initOfferImageUrl: product.productImageUrl,
                                ),
                              ),
                            );
                          }
                        },
                  icon: Icon(
                    Icons.local_offer_outlined,
                    size: 16,
                    color: isOwner ? Colors.grey.shade400 : Colors.orange,
                  ),
                  label: Text(
                    'Thương lượng',
                    style: TextStyle(
                      fontSize: 11,
                      color: isOwner ? Colors.grey.shade400 : Colors.orange,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: isOwner ? Colors.grey.shade300 : Colors.orange,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
