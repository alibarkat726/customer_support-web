import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:collection/collection.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../models/message.dart';

class AdminController extends GetxController {
  final ApiService _apiService = ApiService();
  // State
  var conversations = <Map<String, dynamic>>[].obs;
  var selectedCustomerId = Rxn<int>();
  var messages = <Message>[].obs;
  var isLoading = false.obs;
  var llmEnabled = true.obs;
  var uploadStatus = ''.obs;
  var isUploading = false.obs;
  WebSocketChannel? _channel;
  
  // Hardcoded owner ID for demo
  final int ownerId = 999; 

  @override
  void onInit() {
    super.onInit();
    fetchConversations();
    connectToOwnerSocket();
  }

  @override
  void onClose() {
    _channel?.sink.close();
    super.onClose();
  }

  void connectToOwnerSocket() {
    try {
      final wsUrl = 'wss://customer-service-bot-xalv.onrender.com/ws/owner/$ownerId';
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      _channel!.stream.listen((message) {
        _handleIncomingMessage(message);
      }, onError: (e) => print("Owner WS Error: $e"));
    } catch (e) {
      print("Owner WS Connection Error: $e");
    }
  }

  void _handleIncomingMessage(dynamic data) {
    try {
      final parsed = json.decode(data);
      final type = parsed['type'];
      
      if (type == 'new_customer_message' || type == 'chat_update') {
        int custId = parsed['customer_id'];
        String text = parsed['message'] ?? parsed['query'] ?? '';
        
        // Update conversation preview
        int index = conversations.indexWhere((c) => c['customer_id'] == custId);
        if (index != -1) {
          conversations[index]['last_message'] = text;
          conversations[index]['timestamp'] = DateTime.now().toIso8601String();
          conversations.refresh();
        } else {
          // Add new conversation if not exists
          fetchConversations(); 
        }

        // If currently selecting this customer, add to messages
        if (selectedCustomerId.value == custId) {
           // Avoid dupes if necessary, but robust dedupe needs IDs
           if (type == 'new_customer_message') {
              // Now we have message_id from backend!
              String msgId = parsed['message_id'] ?? DateTime.now().toString();
              
              bool isDuplicate = false;
              if (messages.isNotEmpty) {
                final last = messages.last;
                if (last.text == text && 
                    last.senderType == SenderType.customer && 
                    DateTime.now().difference(last.timestamp).inSeconds < 2) {
                  isDuplicate = true;
                }
              }

              if (!isDuplicate) {
                messages.add(Message(
                  id: msgId,
                  text: text,
                  senderType: SenderType.customer,
                  timestamp: DateTime.now(),
                  status: 'received'
                ));
              }

           } else if (type == 'chat_update' && parsed['reply'] != null) {
              // This is LLM reply or Owner reply broadcast
              // Check for duplicate reply
              bool isDuplicate = false;
              if (messages.isNotEmpty) {
                  final last = messages.last;
                  if (last.text == parsed['reply'] && 
                      (last.senderType == SenderType.bot || last.senderType == SenderType.admin) &&
                      DateTime.now().difference(last.timestamp).inSeconds < 2) {
                     isDuplicate = true;
                  }
              }
              
              if (!isDuplicate) {
                  messages.add(Message(
                    id: "${parsed['message_id']}_reply",
                    text: parsed['reply'],
                    senderType: SenderType.bot, // Default to bot, but if it was owner reply via this channel? 
                    // Websocket broadcast for manual reply handles type?
                    timestamp: DateTime.now(),
                    status: 'delivered'
                  ));
              }
           }
        }
      }
    } catch (e) {
      print("Error parsing owner message: $e");
    }
  }

  Future<void> fetchConversations() async {
    var list = await _apiService.getConversations();
    conversations.assignAll(list);
  }

  void selectCustomer(int id) async {
    selectedCustomerId.value = id;
    isLoading.value = true;
    messages.clear();
    try {
      var history = await _apiService.getCustomerMessages(id);
      messages.assignAll(history);
      // Update LLM status switch based on selected customer config if available
      var customerData = conversations.firstWhereOrNull((c) => c['customer_id'] == id);
      if (customerData != null) {
        llmEnabled.value = customerData['llm_enabled'] ?? true;
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> sendReply(String text) async {
    if (selectedCustomerId.value == null || text.isEmpty) return;
    
    // Add optimistic message
    String msgId = DateTime.now().millisecondsSinceEpoch.toString();
    messages.add(Message(
      id: msgId,
      text: text,
      senderType: SenderType.admin,
      timestamp: DateTime.now(),
      status: 'pending'
    ));

    // Send to WS
    if (_channel != null) {
      // Find the message to reply to. Ideally we reply to specific ID. 
      // For now, let's just send a generic reply structure or assume last message.
      // The backend expects "message_id" to reply to specific message.
      // We'll need to track the last customer message ID or adapt backend to accept generic replies.
      
      // Adaptation: Find last customer message ID from list
      var lastCustMsg = messages.lastWhereOrNull((m) => m.senderType == SenderType.customer);
      if (lastCustMsg != null) {
         _channel!.sink.add(json.encode({
           "type": "reply",
           "message_id": lastCustMsg.id,
           "customer_id": selectedCustomerId.value, // Added for robustness
           "reply": text
         }));
      } else {
        print("No message to reply to");
      }
    }
  }

  Future<void> toggleLlm(bool value) async {
    bool success = await _apiService.toggleLlm(value);
    if (success) {
      llmEnabled.value = value;
      // Also update backend specific room if needed via WS or specific endpoint
      if (selectedCustomerId.value != null && _channel != null) {
          _channel!.sink.add(json.encode({
            "type": "toggle_llm",
            "customer_id": selectedCustomerId.value,
            "enabled": value
          }));
      }
    }
  }

  Future<void> ingestDocument(String content) async {
    if (content.isEmpty) return;
    
    isUploading.value = true;
    uploadStatus.value = 'Uploading...';
    try {
      bool success = await _apiService.ingestDocument(content);
      if (success) {
        uploadStatus.value = 'Success!';
        Future.delayed(Duration(seconds: 2), () => uploadStatus.value = '');
      } else {
        uploadStatus.value = 'Failed';
      }
    } finally {
      isUploading.value = false;
    }
  }
}
