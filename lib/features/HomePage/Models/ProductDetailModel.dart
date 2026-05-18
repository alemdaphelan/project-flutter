class ProductDetailModel {
  final String shopName;
  final String shopHandle;
  final String shopAvatarUrl; // Link ảnh thật sau này
  final String timeAgo;
  final String productImageUrl;
  final String productName;
  final String price;
  final Map<String, String> specifications;
  final String description;

  ProductDetailModel({
    required this.shopName,
    required this.shopHandle,
    required this.shopAvatarUrl,
    required this.timeAgo,
    required this.productImageUrl,
    required this.productName,
    required this.price,
    required this.specifications,
    required this.description,
  });
}
