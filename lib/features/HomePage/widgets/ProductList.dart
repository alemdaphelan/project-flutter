import 'package:flutter/material.dart';
import 'package:project_flutter/features/HomePage/Models/Product.dart';
import 'package:project_flutter/firestore_service.dart';
import 'package:project_flutter/features/HomePage/widgets/ProductCard.dart';

// 1. CHUYỂN THÀNH STATEFULWIDGET ĐỂ GIỮ STATE VÀ CACHE FUTURE
class ProductList extends StatefulWidget {
  final FirestoreService firestore;
  final String selectedCategory;
  final String searchQuery;
  final String? userId;

  const ProductList({
    super.key,
    required this.firestore,
    required this.selectedCategory,
    required this.searchQuery,
    this.userId,
  });

  @override
  State<ProductList> createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  late Future<List<ProductModel>> _productsFuture;

  @override
  void initState() {
    super.initState();
    if (widget.userId != null && widget.userId!.isNotEmpty) {
      _productsFuture = widget.firestore.getProductsByUser(widget.userId!);
    } else {
      _productsFuture = widget.firestore.getProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ProductModel>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF4C9A82)),
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Error: ${snapshot.error}'),
          );
        }

        List<ProductModel> productsData = snapshot.data ?? [];

        if (widget.searchQuery.isNotEmpty) {
          productsData = productsData.where((product) {
            return product.productName.toLowerCase().contains(
              widget.searchQuery.toLowerCase(),
            );
          }).toList();
        }

        if (widget.selectedCategory != 'All') {
          productsData = productsData.where((product) {
            return product.category == widget.selectedCategory;
          }).toList();
        }

        if (productsData.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: Text('Không tìm thấy sản phẩm nào.')),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: productsData.length,
          itemBuilder: (context, index) {
            return ProductCard(product: productsData[index]);
          },
        );
      },
    );
  }
}
