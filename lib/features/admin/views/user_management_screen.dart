import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/admin_repository.dart';

// Listen to the stream of all users
final allUsersProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(adminRepositoryProvider).getAllUsers();
});

class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});

  // The Warning Dialog before executing a delete
  void _confirmDelete(BuildContext context, WidgetRef ref, String uid, String email) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User?', style: TextStyle(color: Colors.red)),
        content: Text('Are you sure you want to permanently delete the account for $email? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(adminRepositoryProvider).deleteUser(uid);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User deleted successfully'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                }
              }
            },
            child: const Text('Yes, Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);

    return usersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (users) {
        if (users.isEmpty) return const Center(child: Text('No users found in database.'));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final uid = user['uid'] ?? '';
            final name = user['name'] ?? 'Unknown Name';
            final email = user['email'] ?? 'Unknown Email';
            final role = user['role'] ?? 'guest';

            // Color code the roles so the Admin can read the list easily!
            Color roleColor = Colors.grey;
            if (role == 'admin') roleColor = Colors.deepPurple;
            if (role == 'organizer') roleColor = Colors.blue;
            if (role == 'exhibitor') roleColor = Colors.green;

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: roleColor.withOpacity(0.2),
                  child: Icon(Icons.person, color: roleColor),
                ),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('$email\nRole: ${role.toUpperCase()}'),
                isThreeLine: true,
                // Do not let Admins delete other Admins!
                trailing: role == 'admin'
                    ? const Icon(Icons.security, color: Colors.deepPurple)
                    : IconButton(
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  tooltip: 'Delete User',
                  onPressed: () => _confirmDelete(context, ref, uid, email),
                ),
              ),
            );
          },
        );
      },
    );
  }
}