import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ngames/models/chat_message_model.dart';
import 'package:ngames/models/user_model.dart'; // For fetching users as contacts
import 'package:ngames/services/auth_service.dart'; // To get current user ID

// Re-use firestoreProvider from high_score_service.dart or define it here if not already globally accessible
// For now, assuming it's defined elsewhere or we define a new one.
// final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final messagingServiceProvider = Provider<MessagingService>((ref) {
  return MessagingService(
    FirebaseFirestore.instance,
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
  String? get currentUserEmail =>
      _firebaseAuth.currentUser?.email; // Or displayName

  // Send a message
  Future<void> sendMessage(String receiverId, String text) async {
    if (currentUserId == null || text.trim().isEmpty) return;

    final message = ChatMessage(
      senderId: currentUserId!,
      receiverId: receiverId,
      text: text.trim(),
      timestamp: Timestamp.now(),
      senderName: currentUserEmail, // Or a display name if you have it
    );

    // Create a chat ID that is consistent regardless of who is sender/receiver
    List<String> ids = [currentUserId!, receiverId];
    ids.sort(); // Ensures chatID is the same for both users
    String chatId = ids.join('_');

    await _firestore
        .collection(_chatsCollectionPath)
        .doc(chatId)
        .collection('messages')
        .add(message.toFirestore());

    // Optionally, update a 'lastMessage' field in a document representing the chat itself
    // for chat list previews, but that's an advanced feature for now.
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
        .where(
          FieldPath.documentId,
          isNotEqualTo: currentUserId,
        ) // Exclude current user
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            // Assuming your UserModel has a fromFirestore or similar constructor
            // And that user documents in Firestore have 'uid' and 'email' fields.
            // If your UserModel structure or Firestore user document structure is different, adjust this.
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            return UserModel(
              uid: doc.id, // Use document ID as UID
              email: data['email'] as String?,
              // Add other fields if your UserModel has them and they exist in Firestore
            );
          }).toList();
        });
  }

  // Note: For this to work, you need to store user data (at least email/displayName)
  // in a 'users' collection in Firestore when a user registers.
  // The AuthService currently doesn't do this. This would be an enhancement to AuthService.
  // For now, this method might return users with null emails if not stored.
}
