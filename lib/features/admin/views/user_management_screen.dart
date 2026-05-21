import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../repositories/admin_repository.dart';

// Listen to the stream of all users
final allUsersProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(adminRepositoryProvider).getAllUsers();
});

class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});

  // --- NEW EDIT DIALOG ---
  void _showEditUserDialog(BuildContext context, WidgetRef ref, Map<String, dynamic> user) {
    final nameController = TextEditingController(text: user['name'] ?? '');
    String selectedRole = user['role'] ?? 'guest';
    bool isSuspended = user['isSuspended'] ?? false;
    final uid = user['uid'];

    showDialog(
      context: context,
      // StatefulBuilder lets the Switch animate inside the dialog without a full screen refresh!
      builder: (ctx) => StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit User Profile'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: const InputDecoration(labelText: 'System Role', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'guest', child: Text('Guest')),
                        DropdownMenuItem(value: 'exhibitor', child: Text('Exhibitor')),
                        DropdownMenuItem(value: 'organizer', child: Text('Organizer')),
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      ],
                      onChanged: (val) => setState(() => selectedRole = val!),
                    ),
                    const SizedBox(height: 16),
                    // THE SUSPEND SWITCH
                    SwitchListTile(
                      title: const Text('Suspend Account', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Blocks user from logging in'),
                      value: isSuspended,
                      activeColor: Colors.red,
                      onChanged: (val) => setState(() => isSuspended = val),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                FilledButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    try {
                      // Send the updates to Firebase!
                      await ref.read(adminRepositoryProvider).updateUser(uid, {
                        'name': nameController.text.trim(),
                        'role': selectedRole,
                        'isSuspended': isSuspended,
                      });
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User updated successfully!'), backgroundColor: Colors.green));
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                      }
                    }
                  },
                  child: const Text('Save Changes'),
                ),
              ],
            );
          }
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Users')),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, stack) => Center(child: Text('Error: $e')),
        data: (users) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final name = user['name'] ?? 'Unknown Name';
              final email = user['email'] ?? 'Unknown Email';
              final role = user['role'] ?? 'guest';
              final isSuspended = user['isSuspended'] ?? false;
              final uid = user['uid'];

              // Color code the roles
              Color roleColor = Colors.grey;
              if (role == 'admin') roleColor = Colors.deepPurple;
              if (role == 'organizer') roleColor = Colors.blue;
              if (role == 'exhibitor') roleColor = Colors.green;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    // If suspended, show a red block icon!
                    backgroundColor: isSuspended ? Colors.red.shade100 : roleColor.withOpacity(0.2),
                    child: Icon(isSuspended ? Icons.block : Icons.person, color: isSuspended ? Colors.red : roleColor),
                  ),
                  title: Row(
                    children: [
                      // Cross out their name if they are suspended
                      Text(name, style: TextStyle(fontWeight: FontWeight.bold, decoration: isSuspended ? TextDecoration.lineThrough : null)),
                      if (isSuspended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                          child: const Text('SUSPENDED', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        )
                      ]
                    ],
                  ),
                  subtitle: Text('$email\nRole: ${role.toUpperCase()}'),
                  isThreeLine: true,
                  // Open the new Edit Dialog instead of deleting!
                  trailing: role == 'admin'
                      ? const Icon(Icons.security, color: Colors.deepPurple)
                      : IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blueAccent),
                    tooltip: 'Edit User',
                    onPressed: () => _showEditUserDialog(context, ref, user),
                  ),
                ),
              );
            },
          );
        },
      ),
      // --- ADD USER BUTTON ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/register'),
        icon: const Icon(Icons.person_add),
        label: const Text('Add User'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
    );
  }
}