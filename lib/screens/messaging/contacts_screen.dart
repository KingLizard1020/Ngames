import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ngames/models/user_model.dart';
import 'package:ngames/services/messaging_service.dart';

final usersProvider = StreamProvider<List<UserModel>>((ref) {
  final messagingService = ref.watch(messagingServiceProvider);
  return messagingService.getUsers();
});

class ContactsScreen extends ConsumerWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final usersAsyncValue = ref.watch(usersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      body: usersAsyncValue.when(
        data: (users) {
          if (users.isEmpty) {
            return const Center(child: Text('No other users found.'));
          }
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: theme.colorScheme.surfaceContainerHighest,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    child: Text(
                      user.email?[0].toUpperCase() ?? 'U',
                      style: TextStyle(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                  title: Text(
                    user.email ?? 'Unknown User',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  onTap: () {
                    // Navigate to ChatScreen with this user's ID and name/email
                    context.go(
                      '/chat/${user.uid}',
                      extra: user.email ?? 'Chat',
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading users: $err')),
      ),
    );
  }
}
