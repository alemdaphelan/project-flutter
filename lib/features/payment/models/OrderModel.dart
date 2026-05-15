class OrderModel {
  final String id;
  final String shopName;
  final String shopHandle;
  final String timeAgo;
  final String productName;
  final String price;
  final String status;
  final String type;

  OrderModel({
    required this.id,
    required this.shopName,
    required this.shopHandle,
    required this.timeAgo,
    required this.productName,
    required this.price,
    required this.status,
    required this.type,
  });
}
