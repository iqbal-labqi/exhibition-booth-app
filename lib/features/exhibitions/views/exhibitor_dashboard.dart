import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/exhibition_provider.dart';
import '../../authentication/providers/auth_provider.dart';

class ExhibitorDashboard extends ConsumerWidget {
  const ExhibitorDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the published exhibitions and the current logged-in user
    final exhibitionsAsyncValue = ref.watch(publishedExhibitionsProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Exhibitions'),
      ),
      // THIS IS YOUR SIDEBAR (Wireframe 7)
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(user?.name ?? 'Exhibitor', style: const TextStyle(fontWeight: FontWeight.bold)),
              accountEmail: Text(user?.email ?? ''),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.store, size: 40, color: Colors.blueAccent),
              ),
              decoration: const BoxDecoration(color: Colors.blueAccent),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('My Applications'),
              onTap: () {
                context.pop(); // Closes the sidebar drawer
                context.push('/history'); // Routes to the new screen!
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await ref.read(authControllerProvider.notifier).logout();
                if (context.mounted) context.go('/');
              },
            ),
          ],
        ),
      ),
      // THE LIST OF EXHIBITIONS
      body: exhibitionsAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (exhibitions) {
          if (exhibitions.isEmpty) {
            return const Center(child: Text('No upcoming exhibitions available.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: exhibitions.length,
            itemBuilder: (context, index) {
              final exhibition = exhibitions[index];
              return _buildExhibitorCard(context, exhibition);
            },
          );
        },
      ),
    );
  }

  Widget _buildExhibitorCard(BuildContext context, exhibition) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // THIS MAKES THE MAP WORK FOR THE EXHIBITOR
          context.push('/map/${exhibition.id}');
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.indigo.shade100,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: const Center(child: Icon(Icons.map, size: 50, color: Colors.indigo)),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exhibition.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('${dateFormat.format(exhibition.startDate)} - ${dateFormat.format(exhibition.endDate)}', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.tonal(
                      onPressed: () => context.push('/map/${exhibition.id}'),
                      child: const Text('View Floor Plan & Book'),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}