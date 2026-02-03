enum SenderType {
  customer,
  bot,
  admin
}

class Message {
  final String id;
  final String text;
  final SenderType senderType;
  final DateTime timestamp;
  final String status; // 'pending', 'delivered', 'read'

  Message({
    required this.id,
    required this.text,
    required this.senderType,
    required this.timestamp,
    required this.status,
  });

  bool get isMe => senderType == SenderType.customer; // Helper for UI compatibility if needed

  factory Message.fromJson(Map<String, dynamic> json) {
    // Determine sender type
    // replied_by: admin, llm, not_replied
    // message_status: pending, received_by_owner, replied
    
    // Logic: If we are fetching 'my' history as a customer, created_at messages are mine (customer).
    // Replies are from bot or admin.
    
    // However, the backend returns a flat list of CustomerMessage objects.
    // The "content" is ALWAYS from the customer.
    // The "reply" is from the bot/admin.
    
    // We should parse this differently depending on if we are the customer or the owner viewing it.
    // But to keep it simple, let's treat the CustomerMessage object as the "customer" part.
    
    return Message(
      id: json['id'].toString(),
      text: json['content'] ?? '',
      senderType: SenderType.customer,
      timestamp: DateTime.parse(json['created_at']),
      status: json['message_status'] ?? 'pending',
    );
  }
  
  static Message fromReplyJson(Map<String, dynamic> json) {
    SenderType type = SenderType.bot;
    if (json['replied_by'] == 'admin') {
      type = SenderType.admin;
    }
    
    return Message(
      id: "${json['id']}_reply",
      text: json['reply'] ?? '',
      senderType: type,
      timestamp: json['replied_at'] != null ? DateTime.parse(json['replied_at']) : DateTime.now(),
      status: 'delivered',
    );
  }
}
