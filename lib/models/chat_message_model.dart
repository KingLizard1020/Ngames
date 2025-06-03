import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String senderId;
  final String receiverId;
  final String text;
  final Timestamp timestamp;
  final String? senderName; // Optional: for display

  ChatMessage({
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    this.senderName,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data()! as Map<String, dynamic>;
    return ChatMessage(
      senderId: data['senderId'] as String,
      receiverId: data['receiverId'] as String,
      text: data['text'] as String,
      timestamp: data['timestamp'] as Timestamp,
      senderName: data['senderName'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': timestamp,
      if (senderName != null) 'senderName': senderName,
    };
  }
}
