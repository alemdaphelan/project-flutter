import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'chat_screen.dart';
import '../models/chat_room.dart';
import '../widgets/chat_filter_chip.dart';
import '../services/firebase_chat_service.dart';
import '../services/management_service.dart';
import '../services/chat_extension_service.dart';

class MainScreen_Chat extends StatefulWidget {
  const MainScreen_Chat({Key? key}) : super(key: key);
  @override
  State<MainScreen_Chat> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen_Chat> {
  final FirebaseChatService _chatService = FirebaseChatService();
  final ManagementService _mngt = ManagementService();

  String _searchQuery = "";
  String _selectedFilter = "Tất cả";
  DateTime? _selectedDate;

  Widget _highlightText(String text, String query) {
    if (query.isEmpty || !text.toLowerCase().contains(query.toLowerCase())) {
      return Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      );
    }

    final String lowerText = text.toLowerCase();
    final String lowerQuery = query.toLowerCase();
    final int start = lowerText.indexOf(lowerQuery);

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        children: [
          TextSpan(text: text.substring(0, start)),
          TextSpan(
            text: text.substring(start, start + query.length),
            style: const TextStyle(backgroundColor: Color(0xFFFFCE00)),
          ),
          TextSpan(text: text.substring(start + query.length)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Chat",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onSelected: (val) {
              if (val == 0) _mngt.manageCategories(context);
              if (val == 1) _mngt.setupAutoReply(context);
              if (val == 2) _mngt.manageQuickMessages(context);
              if (val == 3) _mngt.showHiddenChats(context);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 0,
                child: ListTile(
                  leading: Icon(Icons.business_center_outlined),
                  title: Text("Quản lý phân loại"),
                ),
              ),
              const PopupMenuItem(
                value: 1,
                child: ListTile(
                  leading: Icon(Icons.settings_outlined),
                  title: Text("Cài đặt trả lời tự động"),
                ),
              ),
              const PopupMenuItem(
                value: 2,
                child: ListTile(
                  leading: Icon(Icons.message_outlined),
                  title: Text("Quản lý Tin nhắn nhanh"),
                ),
              ),
              const PopupMenuItem(
                value: 3,
                child: ListTile(
                  leading: Icon(Icons.visibility_off_outlined),
                  title: Text("Hội thoại đã ẩn"),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: const InputDecoration(
                        hintText: "Nhập để tìm kiếm...",
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: Icon(
                    Icons.calendar_month,
                    color: _selectedDate != null
                        ? const Color(0xFFFFCE00)
                        : Colors.grey,
                  ),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    setState(() => _selectedDate = date);
                  },
                ),
              ],
            ),
          ),
          Container(
            height: 45,
            padding: const EdgeInsets.only(left: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ChatFilterChip(
                  label: "Tất cả",
                  isSelected: _selectedFilter == "Tất cả",
                  onTap: () => setState(() => _selectedFilter = "Tất cả"),
                ),
                ChatFilterChip(
                  label: "Chưa đọc",
                  isSelected: _selectedFilter == "Chưa đọc",
                  onTap: () => setState(() => _selectedFilter = "Chưa đọc"),
                ),
                ChatFilterChip(
                  label: "Tin rác / Bỏ qua",
                  isSelected: _selectedFilter == "Tin rác / Bỏ qua",
                  onTap: () =>
                      setState(() => _selectedFilter = "Tin rác / Bỏ qua"),
                ),
                if (_selectedDate != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Chip(
                      label: Text(DateFormat('dd/MM').format(_selectedDate!)),
                      onDeleted: () => setState(() => _selectedDate = null),
                      backgroundColor: Colors.grey[200],
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getChatRoomsStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                var rooms = snapshot.data!.docs
                    .map((d) => ChatRoom.fromFirestore(d))
                    .toList();

                rooms = rooms
                    .where(
                      (r) => !ChatExtensionService.hiddenChatIds.contains(r.id),
                    )
                    .toList();

                if (_searchQuery.isNotEmpty) {
                  rooms = rooms
                      .where(
                        (r) => r.otherUserName.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ),
                      )
                      .toList();
                }

                if (_selectedDate != null) {
                  rooms = rooms.where((r) {
                    final rDate = r.timestamp.toDate();
                    return rDate.year == _selectedDate!.year &&
                        rDate.month == _selectedDate!.month &&
                        rDate.day == _selectedDate!.day;
                  }).toList();
                }

                if (rooms.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  itemCount: rooms.length,
                  itemBuilder: (c, i) => ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFFFCE00),
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: _highlightText(rooms[i].otherUserName, _searchQuery),
                    subtitle: Text(
                      rooms[i].lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      DateFormat('HH:mm').format(rooms[i].timestamp.toDate()),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    onTap: () {
                      String myCurrentUserId = "buyer_id_001"; 
                      
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) => ChatScreen(
                            chatRoomId: rooms[i].id,
                            isSellerViewInit: false, 
                            titleName: rooms[i].otherUserName,
                          ),
                        ),
                      );
                    },
                    onLongPress: () => ChatExtensionService.showChatOptions(
                      context,
                      rooms[i].id,
                      rooms[i].otherUserName,
                      () => setState(() {}),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFFCE00),
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () async {
          String id = await _chatService.createNewChat();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (c) => ChatScreen(
                chatRoomId: id,
                isSellerViewInit: false,
                titleName: "Trò chuyện mới",
              )
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 10),
          const Text(
            "Không tìm thấy cuộc trò chuyện nào!",
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}