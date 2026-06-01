import 'package:project_flutter/shared/models/user_profile.dart';

/// Trạng thái listing do NGƯỜI BÁN tự kiểm soát
enum ListingStatus {
  available,  // Còn hàng — hiện bình thường
  reserved,   // Đang có đơn chờ — người bán có thể đổi về available nếu còn hàng
  sold,       // Đã bán — ẩn khỏi feed
}

extension ListingStatusX on ListingStatus {
  String get label {
    switch (this) {
      case ListingStatus.available: return 'Còn hàng';
      case ListingStatus.reserved: return 'Đang đặt';
      case ListingStatus.sold:     return 'Đã bán';
    }
  }

  static ListingStatus fromString(String? s) {
    switch (s) {
      case 'reserved': return ListingStatus.reserved;
      case 'sold':     return ListingStatus.sold;
      default:         return ListingStatus.available;
    }
  }
}

class ProductModel {
  final String id;          // Firestore doc ID — cần để update status
  final String sellerId;
  final String sellerName;
  final String time;
  final String productImageUrl;
  final String productName;
  final double price;
  final Map<String, dynamic> specifications;
  final String description;
  final String location;
  final String category;
  final ListingStatus status; // ← trạng thái do người bán quản lý

  UserProfile? seller;

  ProductModel({
    this.id = '',
    required this.sellerId,
    this.sellerName = '',
    required this.time,
    required this.productImageUrl,
    required this.productName,
    required this.price,
    required this.specifications,
    required this.description,
    required this.location,
    required this.category,
    this.status = ListingStatus.available,
  });

  bool get isAvailable => status == ListingStatus.available;
  bool get isReserved  => status == ListingStatus.reserved;
  bool get isSold      => status == ListingStatus.sold;

  /// Lưu lên Firestore — đảm bảo sellerId và status luôn có mặt
  Map<String, dynamic> toMap() {
    return {
      'sellerId':    sellerId,
      'sellerName':  sellerName,
      'image':       productImageUrl,
      'name':        productName,
      'price':       price,
      'fields':      specifications,
      'description': description,
      'location':    location,
      'category':    category,
      'status':      status.name,
      'time':        DateTime.now(),
    };
  }

  factory ProductModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ProductModel(
      id:               id,
      sellerId:         data['sellerId'] ?? '',
      sellerName:       data['sellerName'] ?? '',
      time:             data['time'].toDate().toString(),
      productImageUrl:  data['image'] ?? '',
      productName:      data['name'] ?? '',
      price:            (data['price'] ?? 0).toDouble(),
      specifications:   data['fields'] ?? {},
      description:      data['description'] ?? '',
      location:         data['location'] ?? '',
      category:         data['category'] ?? '',
      status:           ListingStatusX.fromString(data['status']),
    );
  }
}