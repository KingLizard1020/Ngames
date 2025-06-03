import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ngames/models/chat_message_model.dart';
import 'package:ngames/models/user_model.dart';
import 'package:ngames/services/auth_service.dart';

final messagingServiceProvider = Provider<MessagingService>((ref) {
  return MessagingService(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider),
  );
});

class MessagingService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;
  final String _usersCollectionPath = 'users';
  final String _chatsCollectionPath = 'chats';

  MessagingService(this._firestore, this._firebaseAuth);

  String? get currentUserId => _firebaseAuth.currentUser?.uid;

  Future<String?> getCurrentUserDisplayName() async {
    if (currentUserId == null) return null;
    try {
      final userDoc =
          await _firestore
              .collection(_usersCollectionPath)
              .doc(currentUserId)
              .get();
      if (userDoc.exists && userDoc.data() != null) {
        return userDoc.data()!['displayName'] as String? ??
            _firebaseAuth.currentUser?.email;
      }
    } catch (e) {
      // print('Error fetching user display name: $e');
    }
    return _firebaseAuth.currentUser?.email; // Fallback to email
  }

  // Send a message
  Future<void> sendMessage(String receiverId, String text) async {
    final senderId = currentUserId;
    final senderName =
        await getCurrentUserDisplayName(); // Get sender's display name
    if (senderId == null || text.trim().isEmpty) return;

    final message = ChatMessage(
      senderId: senderId,
      receiverId: receiverId,
      text: text.trim(),
      timestamp: Timestamp.now(),
      senderName: senderName ?? 'Unknown User', // Use fetched display name
    );

    List<String> ids = [senderId, receiverId];
    ids.sort();
    String chatId = ids.join('_');

    await _firestore
        .collection(_chatsCollectionPath)
        .doc(chatId)
        .collection('messages')
        .add(message.toFirestore());
  }

  // Get messages for a specific chat
  Stream<List<ChatMessage>> getChatMessages(String receiverId) {
    if (currentUserId == null) return Stream.value([]);
    List<String> ids = [currentUserId!, receiverId];
    ids.sort();
    String chatId = ids.join('_');
    return _firestore
        .collection(_chatsCollectionPath)
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChatMessage.fromFirestore(doc))
              .toList();
        });
  }

  // Get a list of users (contacts) excluding the current user
  Stream<List<UserModel>> getUsers() {
    if (currentUserId == null) return Stream.value([]);
    return _firestore
        .collection(_usersCollectionPath)
        .where(FieldPath.documentId, isNotEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data(); // is Map<String, dynamic>
            return UserModel(
              uid: doc.id,
              email: data['email'] as String?,
              displayName: data['displayName'] as String?,
            );
          }).toList();
        });
  }
}
