import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ngames/models/chat_message_model.dart';
import 'package:ngames/services/messaging_service.dart';

// Provider for chat messages for a specific receiverId
final chatMessagesProvider = StreamProvider.family<List<ChatMessage>, String>((
  ref,
  receiverId,
) {
  final messagingService = ref.watch(messagingServiceProvider);
  return messagingService.getChatMessages(receiverId);
});

class ChatScreen extends ConsumerStatefulWidget {
  final String receiverId;
  final String receiverName; // Passed via GoRouter's extra

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _sendMessage(WidgetRef ref) {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      ref.read(messagingServiceProvider).sendMessage(widget.receiverId, text);
      _messageController.clear();
      // Scroll to bottom after sending (optional, might need slight delay)
      // WidgetsBinding.instance.addPostFrameCallback((_) {
      //   if (_scrollController.hasClients) {
      //     _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      //   }
      // });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final messagesAsyncValue = ref.watch(
      chatMessagesProvider(widget.receiverId),
    );
    final currentUserId = ref.watch(messagingServiceProvider).currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverName),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsyncValue.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(child: Text('No messages yet. Say hi!'));
                }
                // Scroll to bottom when messages load or new messages arrive
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController
                          .position
                          .minScrollExtent, // Messages are ordered descending
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, // To show latest messages at the bottom
                  padding: const EdgeInsets.all(8.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUserId;
                    return _buildMessageBubble(message, isMe, theme);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (err, stack) =>
                      Center(child: Text('Error loading messages: $err')),
            ),
          ),
          _buildMessageInputField(ref, theme),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe, ThemeData theme) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
        decoration: BoxDecoration(
          color:
              isMe
                  ? theme.colorScheme.primary
                  : theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft:
                isMe ? const Radius.circular(16) : const Radius.circular(0),
            bottomRight:
                isMe ? const Radius.circular(0) : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 3,
              offset: const Offset(1, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // if (!isMe && message.senderName != null) ...[
            //   Text(
            //     message.senderName!,
            //     style: theme.textTheme.labelSmall?.copyWith(
            //       color: isMe ? theme.colorScheme.onPrimary.withOpacity(0.8) : theme.colorScheme.onSecondaryContainer.withOpacity(0.8),
            //       fontWeight: FontWeight.bold
            //     ),
            //   ),
            //   const SizedBox(height: 2),
            // ],
            Text(
              message.text,
              style: theme.textTheme.bodyLarge?.copyWith(
                color:
                    isMe
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${message.timestamp.toDate().hour}:${message.timestamp.toDate().minute.toString().padLeft(2, '0')}',
              style: theme.textTheme.labelSmall?.copyWith(
                color:
                    isMe
                        ? theme.colorScheme.onPrimary.withOpacity(0.7)
                        : theme.colorScheme.onSecondaryContainer.withOpacity(
                          0.7,
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInputField(WidgetRef ref, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -1),
            blurRadius: 3,
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 10.0,
                ),
              ),
              onSubmitted: (_) => _sendMessage(ref),
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          const SizedBox(width: 8.0),
          IconButton(
            icon: Icon(Icons.send, color: theme.colorScheme.primary),
            onPressed: () => _sendMessage(ref),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.primaryContainer,
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }
}
