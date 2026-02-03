import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/chat_controller.dart';
import '../widgets/chat_bubble.dart';

class CustomerChatScreen extends StatefulWidget {
  const CustomerChatScreen({super.key});

  @override
  State<CustomerChatScreen> createState() => _CustomerChatScreenState();
}

class _CustomerChatScreenState extends State<CustomerChatScreen> {
  final ChatController chatController = Get.put(ChatController());
  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    // For demo purposes, we'll assign a random customer ID or ask for one.
    // For now, let's hardcode '1' or generate a random one if we had auth.
    // Let's assume ID 1 for simplicity in this demo, or use a dialog to ask.
    // Using Future.microtask to show dialog after build
    Future.microtask(() => _showCustomerIdDialog());
  }

  void _showCustomerIdDialog() {
    final idController = TextEditingController(text: "1");
    Get.defaultDialog(
      title: "Enter Customer ID",
      content: TextField(
        controller: idController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: "Customer ID"),
      ),
      textConfirm: "Connect",
      onConfirm: () {
        int? id = int.tryParse(idController.text);
        if (id != null) {
          chatController.setCustomerId(id);
          Get.back();
        }
      },
      barrierDismissible: false,
    );
  }
  
  void _scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to messages list changes to scroll
    ever(chatController.messages, (_) => Future.delayed(Duration(milliseconds: 100), _scrollToBottom));

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Support Chat", style: GoogleFonts.outfit()),
            Obx(() => Text(
                  chatController.connectionStatus.value,
                  style: GoogleFonts.inter(fontSize: 12, color: _getStatusColor(chatController.connectionStatus.value)),
                )),
          ],
        ),
        backgroundColor: const Color(0xFF2A2A35),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (chatController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              return ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(vertical: 20),
                itemCount: chatController.messages.length,
                itemBuilder: (context, index) {
                  final msg = chatController.messages[index];
                  // For customer screen, "Me" is the customer.
                  return ChatBubble(
                    text: msg.text,
                    isMe: msg.isMe, // Assuming Message model has isMe helper or we check msg.senderType == SenderType.customer
                    timestamp: msg.timestamp,
                  );
                },
              );
            }),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Connected': return Colors.greenAccent;
      case 'Error': return Colors.redAccent;
      default: return Colors.grey;
    }
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF2A2A35),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: textController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Type your message...",
                hintStyle: TextStyle(color: Colors.grey[500]),
                filled: true,
                fillColor: const Color(0xFF1E1E2C),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF6C63FF),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    if (textController.text.trim().isEmpty) return;
    chatController.sendMessage(textController.text.trim());
    textController.clear();
  }
}
