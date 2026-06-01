import 'dart:io';
import 'package:flutter/material.dart';

class SmartImage extends StatelessWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;

  const SmartImage({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 8.0, // Bo góc mặc định cho đẹp
  });

  @override
  Widget build(BuildContext context) {
    // 1. Chặn lỗi rỗng
    if (imagePath.isEmpty) {
      return _buildPlaceholder();
    }

    // 2. KỸ SƯ PHÂN LOẠI DỮ LIỆU BẰNG CÁCH NHÌN CHỮ CÁI ĐẦU
    bool isNetwork =
        imagePath.startsWith('http://') || imagePath.startsWith('https://');

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: isNetwork
          ? Image.network(
              imagePath,
              width: width,
              height: height,
              fit: fit,
              // Xử lý mượt nếu rớt mạng hoặc link die
              errorBuilder: (context, error, stackTrace) => _buildErrorState(),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return _buildLoadingState();
              },
            )
          : Image.file(
              File(imagePath),
              width: width,
              height: height,
              fit: fit,
              // Xử lý mượt nếu file trong máy bị xóa mất
              errorBuilder: (context, error, stackTrace) => _buildErrorState(),
            ),
    );
  }

  // Khung xám rỗng
  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }

  // Khung báo lỗi ảnh
  Widget _buildErrorState() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: const Icon(Icons.broken_image, color: Colors.red),
    );
  }

  // Khung đang xoay load ảnh
  Widget _buildLoadingState() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF1B6B60),
          ),
        ),
      ),
    );
  }
}
