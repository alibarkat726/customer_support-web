import 'dart:convert';
import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/message.dart';
import '../services/api_service.dart';

class ChatController extends GetxController {
  final ApiService _apiService = ApiService();
  
  // Observables
  var messages = <Message>[].obs;
  var isLoading = false.obs;
  var connectionStatus = 'Disconnected'.obs;
  var currentCustomerId = 0.obs;
  
  WebSocketChannel? _channel;

  @override
  void onClose() {
    _channel?.sink.close();
    super.onClose();
  }

  void setCustomerId(int id) {
    currentCustomerId.value = id;
    fetchHistory();
    connectToWebSocket();
  }

  Future<void> fetchHistory() async {
    isLoading.value = true;
    try { // Clear previous messages when switching or reloading
      messages.clear();
      var history = await _apiService.getCustomerMessages(currentCustomerId.value);
      messages.addAll(history);
    } finally {
      isLoading.value = false;
    }
  }

  void connectToWebSocket() {
    try {
      // Connect to the WebSocket
      // ws://127.0.0.1:8000/ws/customer/{customer_id}
      final wsUrl = 'wss://customer-service-bot-xalv.onrender.com/ws/customer/${currentCustomerId.value}';
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      connectionStatus.value = 'Connected';
      
      _channel!.stream.listen((message) {
        _handleIncomingMessage(message);
      }, onDone: () {
        connectionStatus.value = 'Disconnected';
      }, onError: (error) {
        connectionStatus.value = 'Error';
        print("WS Error: $error");
      });
    } catch (e) {
      connectionStatus.value = 'Error';
      print("WS Connection Exception: $e");
    }
  }

  void _handleIncomingMessage(dynamic data) {

    try {
      final parsed = json.decode(data);


      if (parsed['type'] == 'llm_reply' || parsed['type'] == 'owner_reply') {
         SenderType type = parsed['type'] == 'llm_reply' ? SenderType.bot : SenderType.admin;
         messages.add(Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: parsed['reply'] ?? '',
          senderType: type,
          timestamp: DateTime.now(),
          status: 'delivered',
        ));
      } else if (parsed['type'] == 'pending_message') {
        // This is a message from the owner (live agent) that was pending
        messages.add(Message(
          id: parsed['message_id']?.toString() ?? DateTime.now().toString(),
          text: parsed['reply'] ?? '',
          senderType: SenderType.admin,  // Pending message is from Admin usually
          timestamp: DateTime.now(),
          status: 'delivered',
        ));
      } else if (parsed['type'] == 'info') {
        Get.snackbar(
          "Notification", 
          parsed['message'] ?? '',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.primaryColor.withOpacity(0.8),
          colorText: Get.theme.colorScheme.onPrimary,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      print("Error parsing incoming WS message: $e");
    }
  }

  void sendMessage(String text) {
    if (text.isEmpty) return;

    // Add immediate optimistic update
    messages.add(Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      senderType: SenderType.customer,
      timestamp: DateTime.now(),
      status: 'pending',
    ));

    // Send to WebSocket
    // Format: raw text or JSON {"query": text}
    if (_channel != null) {
      _channel!.sink.add(json.encode({'query': text}));
    }
  }
}
