import 'package:flutter/material.dart';

/// Widget dropdown có tìm kiếm — dùng chung cho Tỉnh/Phường
/// ở cả EditProfileScreen và CheckoutScreen
class SearchableAddressDropdown extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? selectedValue;
  final String? hintText;
  final bool enabled;
  final Color primaryTeal;
  final Function(Map<String, dynamic> item) onSelected;
  final List<dynamic> items;
  final String displayKey;

  const SearchableAddressDropdown({
    super.key,
    required this.label,
    required this.icon,
    required this.items,
    required this.displayKey,
    required this.onSelected,
    this.selectedValue,
    this.hintText,
    this.enabled = true,
    this.primaryTeal = const Color(0xFF1B6B60),
  });

  void _openSheet(BuildContext context) {
    if (!enabled || items.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SearchSheet(
        title: label,
        items: items,
        displayKey: displayKey,
        primaryTeal: primaryTeal,
        onSelected: (item) {
          Navigator.pop(context);
          onSelected(item);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasValue = selectedValue != null && selectedValue!.isNotEmpty;

    return GestureDetector(
      onTap: enabled ? () => _openSheet(context) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled ? Colors.grey.shade300 : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: enabled ? primaryTeal : Colors.grey.shade400,
                size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hasValue ? selectedValue! : (hintText ?? 'Chọn $label'),
                style: TextStyle(
                  fontSize: 15,
                  color: hasValue ? Colors.black87 : Colors.grey.shade400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color:
                  enabled ? Colors.grey.shade500 : Colors.grey.shade300,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom Sheet ──
class _SearchSheet extends StatefulWidget {
  final String title;
  final List<dynamic> items;
  final String displayKey;
  final Color primaryTeal;
  final Function(Map<String, dynamic>) onSelected;

  const _SearchSheet({
    required this.title,
    required this.items,
    required this.displayKey,
    required this.primaryTeal,
    required this.onSelected,
  });

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  final _searchCtrl = TextEditingController();
  List<dynamic> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.items;
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearch);
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Bỏ dấu tiếng Việt ──
  // Dùng replaceAll từng ký tự riêng lẻ thay vì dùng index
  // vì String trong Dart là UTF-16, index character có thể sai với ký tự đa byte
  String _normalize(String s) {
    return s
        .toLowerCase()
        // a
        .replaceAll('à', 'a').replaceAll('á', 'a')
        .replaceAll('â', 'a').replaceAll('ã', 'a')
        .replaceAll('ă', 'a').replaceAll('ắ', 'a')
        .replaceAll('ặ', 'a').replaceAll('ằ', 'a')
        .replaceAll('ẳ', 'a').replaceAll('ẵ', 'a')
        .replaceAll('ấ', 'a').replaceAll('ầ', 'a')
        .replaceAll('ẩ', 'a').replaceAll('ẫ', 'a')
        .replaceAll('ậ', 'a').replaceAll('ả', 'a')
        .replaceAll('ạ', 'a')
        // e
        .replaceAll('è', 'e').replaceAll('é', 'e')
        .replaceAll('ê', 'e').replaceAll('ë', 'e')
        .replaceAll('ế', 'e').replaceAll('ề', 'e')
        .replaceAll('ệ', 'e').replaceAll('ể', 'e')
        .replaceAll('ễ', 'e').replaceAll('ẻ', 'e')
        .replaceAll('ẹ', 'e')
        // i
        .replaceAll('ì', 'i').replaceAll('í', 'i')
        .replaceAll('î', 'i').replaceAll('ï', 'i')
        .replaceAll('ỉ', 'i').replaceAll('ị', 'i')
        .replaceAll('ĩ', 'i')
        // o
        .replaceAll('ò', 'o').replaceAll('ó', 'o')
        .replaceAll('ô', 'o').replaceAll('õ', 'o')
        .replaceAll('ö', 'o').replaceAll('ố', 'o')
        .replaceAll('ồ', 'o').replaceAll('ộ', 'o')
        .replaceAll('ổ', 'o').replaceAll('ỗ', 'o')
        .replaceAll('ơ', 'o').replaceAll('ớ', 'o')
        .replaceAll('ờ', 'o').replaceAll('ợ', 'o')
        .replaceAll('ở', 'o').replaceAll('ỡ', 'o')
        .replaceAll('ỏ', 'o').replaceAll('ọ', 'o')
        // u
        .replaceAll('ù', 'u').replaceAll('ú', 'u')
        .replaceAll('û', 'u').replaceAll('ü', 'u')
        .replaceAll('ư', 'u').replaceAll('ứ', 'u')
        .replaceAll('ừ', 'u').replaceAll('ự', 'u')
        .replaceAll('ử', 'u').replaceAll('ữ', 'u')
        .replaceAll('ủ', 'u').replaceAll('ụ', 'u')
        .replaceAll('ũ', 'u')
        // y
        .replaceAll('ý', 'y').replaceAll('ỳ', 'y')
        .replaceAll('ỷ', 'y').replaceAll('ỹ', 'y')
        .replaceAll('ỵ', 'y')
        // d
        .replaceAll('đ', 'd')
        // n
        .replaceAll('ñ', 'n');
  }

  void _onSearch() {
    final raw = _searchCtrl.text.trim();
    if (raw.isEmpty) {
      setState(() => _filtered = widget.items);
      return;
    }
    final queryNorm = _normalize(raw);
    setState(() {
      _filtered = widget.items.where((item) {
        final name = item[widget.displayKey] as String;
        final nameNorm = _normalize(name);
        // Match cả bản không dấu lẫn bản gốc
        return nameNorm.contains(queryNorm) ||
            name.toLowerCase().contains(raw.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final double sheetHeight = MediaQuery.of(context).size.height * 0.85;

    return Container(
      height: sheetHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Tiêu đề
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Chọn ${widget.title}',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: widget.primaryTeal,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Ô tìm kiếm
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm... (có thể gõ không dấu)',
                prefixIcon:
                    Icon(Icons.search, color: widget.primaryTeal),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => _searchCtrl.clear(),
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: widget.primaryTeal, width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Số kết quả
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _searchCtrl.text.isEmpty
                    ? '${widget.items.length} mục'
                    : '${_filtered.length} kết quả',
                style:
                    TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ),
          ),

          const Divider(height: 1),

          // Danh sách
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off,
                            size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        Text('Không tìm thấy kết quả',
                            style:
                                TextStyle(color: Colors.grey.shade400)),
                        const SizedBox(height: 4),
                        Text('Thử gõ không dấu, VD: "Ho Chi Minh"',
                            style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 12)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final item =
                          _filtered[index] as Map<String, dynamic>;
                      final name = item[widget.displayKey] as String;
                      return InkWell(
                        onTap: () => widget.onSelected(item),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          child: Row(
                            children: [
                              Icon(Icons.location_on_outlined,
                                  size: 18,
                                  color: Colors.grey.shade400),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(name,
                                    style:
                                        const TextStyle(fontSize: 15)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}