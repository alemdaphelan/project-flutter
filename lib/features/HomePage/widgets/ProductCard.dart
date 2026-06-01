import 'package:flutter/material.dart';
import 'package:project_flutter/features/HomePage/Models/Product.dart';
import 'package:project_flutter/features/HomePage/screens/UserProfile.dart';
import 'package:project_flutter/features/HomePage/screens/DetailListing.dart';
import 'package:project_flutter/features/payment/screens/checkout_screen.dart';
import 'package:project_flutter/features/HomePage/utils/timeFormat.dart';
import 'package:project_flutter/features/TinNhan/screens/chat_screen.dart';
import 'package:project_flutter/features/TinNhan/services/firebase_chat_service.dart';
import 'package:project_flutter/shared/models/user_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
          // ── Header: avatar + tên + badge trạng thái ──
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
                child: CircleAvatar(
                  backgroundImage: NetworkImage(sellerAvatar),
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
              // Thời gian + badge status (nếu không available)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!product.isAvailable) _buildStatusBadge(),
                  Text(
                    formatTimeAgo(DateTime.parse(product.time)),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Ảnh + thông tin sản phẩm ──
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(product: product),
              ),
            ),
            child: Stack(
              children: [
                Column(
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
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        product.productImageUrl,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 180,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image_not_supported),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '\$${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.description,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),

                // Overlay "ĐÃ BÁN" đè lên ảnh
                if (product.isSold)
                  Positioned(
                    top: 42,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Transform.rotate(
                        angle: -0.15,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'ĐÃ BÁN',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Footer: location + like/chat ──
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: Colors.grey,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                product.location,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const Spacer(),
              const Icon(Icons.favorite_border, color: Colors.grey, size: 16),
              const SizedBox(width: 4),
              const Text(
                '12',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.chat_bubble_outline,
                color: Colors.grey,
                size: 16,
              ),
              const SizedBox(width: 4),
              const Text(
                '3',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Action buttons — thay đổi theo status + isOwner ──
          _buildActionButtons(context, isOwner),
        ],
      ),
    );
  }

  // Badge nhỏ ở header
  Widget _buildStatusBadge() {
    final isSold = product.isSold;
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSold ? Colors.red.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSold ? Colors.red.shade300 : Colors.orange.shade300,
        ),
      ),
      child: Text(
        isSold ? 'Đã bán' : 'Đang đặt',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isSold ? Colors.red.shade700 : Colors.orange.shade700,
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isOwner) {
    // ── Chủ sản phẩm → ẩn toàn bộ 3 nút ──
    if (isOwner) return const SizedBox.shrink();

    // ── Đã bán → chỉ hiện nút nhắn tin ──
    if (product.isSold) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _openChat(context, isOffer: false),
          icon: const Icon(Icons.chat_outlined, size: 16, color: Color(0xFF4C9A82)),
          label: const Text('Nhắn tin người bán',
              style: TextStyle(fontSize: 12, color: Color(0xFF4C9A82))),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF4C9A82)),
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      );
    }

    // ── Đang được đặt → ẩn nút Mua, giữ 2 nút còn lại ──
    if (product.isReserved) {
      return Row(
        children: [
          Expanded(
            flex: 4,
            child: OutlinedButton.icon(
              onPressed: () => _openChat(context, isOffer: false),
              icon: const Icon(Icons.chat_outlined, size: 16, color: Color(0xFF4C9A82)),
              label: const Text('Liên hệ người bán',
                  style: TextStyle(fontSize: 12, color: Color(0xFF4C9A82))),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF4C9A82)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: OutlinedButton.icon(
              onPressed: () => _openChat(context, isOffer: true),
              icon: const Icon(Icons.local_offer_outlined, size: 16, color: Colors.orange),
              label: const Text('Thương lượng',
                  style: TextStyle(fontSize: 11, color: Colors.orange)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.orange),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      );
    }

    // ── Available → 3 nút đầy đủ ──
    return Row(
      children: [
        // Nút MUA HÀNG — navigate sang CheckoutScreen
        Expanded(
          flex: 3,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CheckoutScreen(product: product),
              ),
            ),
            icon: const Icon(Icons.shopping_cart_outlined, size: 16, color: Colors.white),
            label: const Text('Mua hàng',
                style: TextStyle(fontSize: 12, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4C9A82),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Nút LIÊN HỆ
        Expanded(
          flex: 4,
          child: OutlinedButton.icon(
            onPressed: () => _openChat(context, isOffer: false),
            icon: const Icon(Icons.chat_outlined, size: 16, color: Color(0xFF4C9A82)),
            label: const Text('Liên hệ người bán',
                style: TextStyle(fontSize: 12, color: Color(0xFF4C9A82))),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF4C9A82)),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Nút THƯƠNG LƯỢNG
        Expanded(
          flex: 3,
          child: OutlinedButton.icon(
            onPressed: () => _openChat(context, isOffer: true),
            icon: const Icon(Icons.local_offer_outlined, size: 16, color: Colors.orange),
            label: const Text('Thương lượng',
                style: TextStyle(fontSize: 11, color: Colors.orange)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.orange),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openChat(BuildContext context, {required bool isOffer}) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    final chatService = FirebaseChatService();
    final myCurrentUserId = FirebaseAuth.instance.currentUser!.uid;

    final roomId = await chatService.getOrCreateChatRoom(
      buyerId: myCurrentUserId,
      sellerId: product.sellerId,
      productName: product.productName,
      sellerName: product.sellerName,
      isOffer: isOffer,
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
            autoShowOffer: isOffer,
            initOfferPrice: isOffer ? product.price : null,
            initOfferImageUrl: isOffer ? product.productImageUrl : null,
          ),
        ),
      );
    }
  }
}