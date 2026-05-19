class Offer {
  final double price;
  final String? productImageUrl; // Mới: Ảnh sản phẩm riêng cho từng offer
  String status; 

  Offer({required this.price, this.productImageUrl, this.status = 'pending'});

  Map<String, dynamic> toMap() => {
    'price': price, 
    'productImageUrl': productImageUrl,
    'status': status
  };

  factory Offer.fromMap(Map<String, dynamic> map) => Offer(
        price: (map['price'] ?? 0).toDouble(),
        productImageUrl: map['productImageUrl'],
        status: map['status'] ?? 'pending',
      );
}