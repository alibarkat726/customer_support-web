import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isMe; 
  final DateTime timestamp;
  final String? senderLabel;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isMe, // True if Right aligned
    required this.timestamp,
    this.senderLabel,
  });

  @override
  Widget build(BuildContext context) {
    // Premium colors
    final Color myColor = const Color(0xFF6C63FF).withOpacity(0.9); // Distinctive Purple/Blue
    final Color theirColor = const Color(0xFF2A2A35); // Dark Grey/Black for contrast
    final Color myTextColor = Colors.white;
    final Color theirTextColor = Colors.white;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (senderLabel != null && senderLabel!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: Text(
                senderLabel!,
                style: GoogleFonts.inter(
                  color: Colors.grey[400],
                  fontSize: 10,
                  fontWeight: FontWeight.bold
                ),
              ),
            ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: isMe ? myColor : theirColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                bottomRight: isMe ? Radius.zero : const Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  text,
                  style: GoogleFonts.inter(
                    color: isMe ? myTextColor : theirTextColor,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      _formatTime(timestamp),
                      style: GoogleFonts.inter(
                        color: (isMe ? myTextColor : theirTextColor).withOpacity(0.6),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
  }
}
