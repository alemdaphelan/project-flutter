import 'package:flutter/material.dart';
import 'package:project_flutter/features/HomePage/Models/Product.dart';
import 'package:project_flutter/features/HomePage/screens/UserProfile.dart';
import 'package:project_flutter/features/HomePage/screens/DetailListing.dart';
import 'package:project_flutter/features/payment/screens/checkout_screen.dart';
import 'package:project_flutter/features/HomePage/utils/timeFormat.dart';
import 'package:project_flutter/features/TinNhan/screens/chat_screen.dart';
import 'package:project_flutter/features/TinNhan/services/firebase_chat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final sellerName = product.seller?.displayName ?? 'Người bán ẩn danh';
    final sellerEmail = product.seller?.email ?? 'Không có thông tin';
    final sellerAvatar = 'https://i.pravatar.cc/150';
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
                      sellerEmail,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '@${sellerName.replaceAll(" ", "").toLowerCase()}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                formatTimeAgo(DateTime.parse(product.time)),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    product.productImageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CheckoutScreen(product: product),
                    ),
                  ),
                  icon: const Icon(
                    Icons.shopping_cart_outlined,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Mua hàng',
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4C9A82),
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
                            autoShowOffer: true,
                            initOfferPrice: product.price,
                            initOfferImageUrl: product.productImageUrl,
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(
                    Icons.local_offer_outlined,
                    size: 16,
                    color: Colors.orange,
                  ),
                  label: const Text(
                    'Thương lượng',
                    style: TextStyle(fontSize: 11, color: Colors.orange),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.orange),
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
