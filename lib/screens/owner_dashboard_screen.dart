import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/admin_controller.dart';
import '../widgets/chat_bubble.dart';
import '../models/message.dart';

class OwnerDashboardScreen extends StatelessWidget {
  OwnerDashboardScreen({super.key});

  final AdminController adminController = Get.put(AdminController());
  final TextEditingController _replyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      body: Row(
        children: [
          // Sidebar: Conversation List
          Container(
            width: 300,
            color: const Color(0xFF2A2A35),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    "Inbox",
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Obx(() => ListView.builder(
                    itemCount: adminController.conversations.length,
                    itemBuilder: (context, index) {
                      final conv = adminController.conversations[index];
                      final isSelected = adminController.selectedCustomerId.value == conv['customer_id'];
                      return ListTile(
                        selected: isSelected,
                        selectedTileColor: const Color(0xFF6C63FF).withOpacity(0.1),
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey[800],
                          child: Text("${conv['customer_id']}", style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text(
                          "Customer ${conv['customer_id']}",
                          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          conv['last_message'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 12),
                        ),
                        onTap: () => adminController.selectCustomer(conv['customer_id']),
                      );
                    },
                  )),
                ),
              ],
            ),
          ),
          
          // Main Content: Chat & Controls
          Expanded(
            child: Obx(() {
              if (adminController.selectedCustomerId.value == null) {
                return Center(
                  child: Text("Select a conversation to start", style: GoogleFonts.inter(color: Colors.grey)),
                );
              }
              
              // Scroll to bottom when messages update
              if (adminController.messages.isNotEmpty) {
                 Future.delayed(Duration(milliseconds: 100), () {
                    if (_scrollController.hasClients) {
                      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                    }
                 });
              }

              return Column(
                children: [
                  // Chat Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    color: const Color(0xFF232330),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Chat with Customer ${adminController.selectedCustomerId.value}", 
                             style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                        Row(
                          children: [
                            Text("Auto-Reply", style: TextStyle(color: Colors.grey)),
                            const SizedBox(width: 8),
                            Switch(
                              value: adminController.llmEnabled.value,
                              onChanged: (val) => adminController.toggleLlm(val),
                              activeColor: const Color(0xFF00B4D8),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  
                  // Messages List
                  Expanded(
                    child: adminController.isLoading.value 
                    ? const Center(child: CircularProgressIndicator()) 
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(20),
                        itemCount: adminController.messages.length,
                        itemBuilder: (context, index) {
                          final msg = adminController.messages[index];
                          // Adjust isMe logic for Owner: Owner is "Me" if sender is admin.
                          bool isMe = msg.senderType == SenderType.admin;
                          // If sender is customer, it's on the left.
                          // If sender is bot, maybe distinguish it? 
                          // Let's say Bot is also on "My" side but different color? 
                          // Or left side? Usually Bot acts on behalf of owner, so Right side.
                          
                          // Custom bubble for Dashboard
                          String? label;
                          if (msg.senderType == SenderType.bot) label = "AI Agent";
                          if (msg.senderType == SenderType.admin) label = "You (Admin)";
                          if (msg.senderType == SenderType.customer) label = "Customer";

                          return ChatBubble(
                            text: msg.text,
                            isMe: isMe || msg.senderType == SenderType.bot,
                            timestamp: msg.timestamp,
                            senderLabel: label,
                          );
                        },
                      ),
                  ),
                  
                  // Input Area
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: const Color(0xFF2A2A35),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _replyController,
                            style: const TextStyle(color: Colors.white),
                            enabled: !adminController.llmEnabled.value, // Disable if LLM is ON
                            decoration: InputDecoration(
                              hintText: adminController.llmEnabled.value 
                                  ? "Disable Auto-Reply to type..." 
                                  : "Type a reply...",
                              hintStyle: TextStyle(color: Colors.grey[500]),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                              filled: true,
                              fillColor: adminController.llmEnabled.value 
                                  ? const Color(0xFF1E1E2C).withOpacity(0.5) 
                                  : const Color(0xFF1E1E2C),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                            ),
                            onSubmitted: (_) {
                              if (!adminController.llmEnabled.value) {
                                adminController.sendReply(_replyController.text);
                                _replyController.clear();
                              }
                            },
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.send, 
                            color: adminController.llmEnabled.value ? Colors.grey : const Color(0xFF6C63FF)),
                          onPressed: adminController.llmEnabled.value 
                            ? null 
                            : () {
                             if (_replyController.text.isNotEmpty) {
                               adminController.sendReply(_replyController.text);
                               _replyController.clear();
                             }
                          },
                        )
                      ],
                    ),
                  )
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
