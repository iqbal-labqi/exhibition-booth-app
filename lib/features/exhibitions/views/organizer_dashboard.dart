import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../authentication/providers/auth_provider.dart';
import '../providers/exhibition_provider.dart';

// Notice we changed this to a ConsumerWidget so it can read Riverpod!
class OrganizerDashboard extends ConsumerWidget {
  const OrganizerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the new organizer provider
    final exhibitionsAsyncValue = ref.watch(organizerExhibitionsProvider);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Exhibitions'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: const Text('Organizer'),
              accountEmail: const Text('Manage your events'),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.event, size: 40, color: Colors.orange),
              ),
              decoration: BoxDecoration(color: Colors.orange.shade400),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                // Read auth provider to logout properly
                await ref.read(authControllerProvider.notifier).logout();
                if (context.mounted) context.go('/');
              },
            ),
          ],
        ),
      ),
      body: exhibitionsAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (exhibitions) {
          if (exhibitions.isEmpty) {
            return const Center(child: Text('You have not created any exhibitions yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: exhibitions.length,
            itemBuilder: (context, index) {
              final exhibition = exhibitions[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16.0),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16.0),
                  title: Text(exhibition.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text('${dateFormat.format(exhibition.startDate)} - ${dateFormat.format(exhibition.endDate)}'),
                      const SizedBox(height: 8),
                      // Show a badge indicating if it is published or a draft
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: exhibition.isPublished ? Colors.green.shade100 : Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          exhibition.isPublished ? 'Published' : 'Draft',
                          style: TextStyle(
                            color: exhibition.isPublished ? Colors.green.shade800 : Colors.orange.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // UPDATE THE TRAILING PROPERTY:
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blueAccent),
                        tooltip: 'Edit Exhibition Details',
                        onPressed: () => context.push('/organizer/edit', extra: exhibition),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    ],
                  ),
                  onTap: () {
                    // Route to the new management screen!
                    context.push('/organizer/manage/${exhibition.id}');
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/organizer/create'),
        icon: const Icon(Icons.add),
        label: const Text('Create Exhibition'),
      ),
    );
  }
}