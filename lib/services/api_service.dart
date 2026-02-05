import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';

class ApiService {
  // Use 127.0.0.1 for web, or 10.0.2.2 for Android emulator.
  // For web, we can often use localhost if the port is forwarded or if running on same machine.
  static const String baseUrl = 'https://customer-service-bot-xalv.onrender.com';

  Future<List<Message>> getCustomerMessages(int customerId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/messages?customer_id=$customerId'));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body); // API returns {"data": [...]}
        // Handle both list directly or wrapping object just in case, based on previous code.
        // The backend returns {"data": messages} or {"message": ...}
        
        List<dynamic> data = [];
        if (jsonResponse['data'] != null) {
          data = jsonResponse['data'];
        } 
        
        List<Message> messages = [];
        
        for (var item in data) {
          // Add the customer's query
          messages.add(Message(
            id: item['id'].toString(),
            text: item['content'],
            senderType: SenderType.customer,
            timestamp: DateTime.parse(item['created_at']),
            status: item['message_status'],
          ));
          
          // If there is a reply, add it as a separate message
          if (item['reply'] != null && 
              item['reply'] != " " &&
              item['reply_status'] != 'not_replied') {
             
             SenderType replier = SenderType.bot;
             if (item['replied_by'] == 'admin') replier = SenderType.admin;

             messages.add(Message(
              id: "${item['id']}_reply",
              text: item['reply'],
              senderType: replier,
              timestamp: item['replied_at'] != null ? DateTime.parse(item['replied_at']) : DateTime.now(),
              status: 'delivered',
            ));
          }
        }
        
        // Sort by timestamp
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        return messages;
      } else {
        throw Exception('Failed to load messages');
      }
    } catch (e) {
      print('Error fetching messages: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/admin/customers'));
      if (response.statusCode == 200) {
        List<dynamic> list = json.decode(response.body);
        return List<Map<String, dynamic>>.from(list);
      }
      return [];
    } catch (e) {
      print('Error fetching conversations: $e');
      return [];
    }
  }

  Future<bool> toggleLlm(bool enabled) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/llm/enable?enabled=$enabled'),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error toggling LLM: $e');
    }    return false;
  }

  Future<bool> ingestDocuments(List<String> contents) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/add/many'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'documents': contents}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error ingesting documents: $e');
      return false;
    }
  }
}
