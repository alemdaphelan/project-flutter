import 'package:flutter/material.dart';

class CategorySelector extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final int selectedIndex;
  final Function(int) onCategorySelected;

  const CategorySelector({
    super.key,
    required this.categories,
    required this.selectedIndex,
    required this.onCategorySelected,
  });

  IconData _getIconFromString(String? iconString) {
    switch (iconString) {
      case 'Phone':
        return Icons.phone;
      case 'Monitor':
        return Icons.monitor;
      case 'Headphone':
        return Icons.headphones;
      case 'Laptop':
        return Icons.laptop;
      case 'All':
        return Icons.grid_3x3;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      height: 95,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isActive = index == selectedIndex;

          final String catName = cat['name'] ?? 'All';
          final IconData catIcon = _getIconFromString(cat['name']?.toString());

          return GestureDetector(
            onTap: () => onCategorySelected(index),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFFD6EBE0)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      catIcon,
                      color: isActive ? const Color(0xFF4C9A82) : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    catName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isActive
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isActive
                          ? const Color(0xFF4C9A82)
                          : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
