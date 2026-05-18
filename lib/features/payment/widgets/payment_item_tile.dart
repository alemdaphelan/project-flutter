import 'package:flutter/material.dart';

class PaymentItemTile extends StatelessWidget {
  final String name;
  final double price;

  const PaymentItemTile({super.key, required this.name, required this.price});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: const Icon(Icons.shopping_bag, color: Colors.blue, size: 40),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          "Giá: ${price.toStringAsFixed(0)} VNĐ",
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }
}
