import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../exhibitions/models/exhibition_model.dart';
import '../../exhibitions/repositories/exhibition_repository.dart';

// Provider to watch ALL exhibitions for the Admin
final adminAllExhibitionsProvider = StreamProvider<List<ExhibitionModel>>((ref) {
  return ref.watch(exhibitionRepositoryProvider).getAllExhibitionsAdmin();
});

class AdminExhibitionScreen extends ConsumerWidget {
  const AdminExhibitionScreen({super.key});

  void _confirmDelete(BuildContext context, WidgetRef ref, String id, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Exhibition?', style: TextStyle(color: Colors.red)),
        content: Text('Are you sure you want to permanently delete "$title"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(exhibitionRepositoryProvider).deleteExhibition(id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Exhibition Deleted'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exhibitionsAsync = ref.watch(adminAllExhibitionsProvider);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      // We add a Floating Action Button so the Admin can CREATE exhibitions too!
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/organizer/create'),
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Exhibition', style: TextStyle(color: Colors.white)),
      ),
      body: exhibitionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (exhibitions) {
          if (exhibitions.isEmpty) return const Center(child: Text('No exhibitions exist yet.'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: exhibitions.length,
            itemBuilder: (context, index) {
              final exhibition = exhibitions[index];

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    ListTile(
                      title: Text(exhibition.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      subtitle: Text('${dateFormat.format(exhibition.startDate)} - ${dateFormat.format(exhibition.endDate)}'),
                      trailing: Switch(
                        value: exhibition.isPublished,
                        activeColor: Colors.green,
                        onChanged: (val) async {
                          // The Master Kill-Switch!
                          await ref.read(exhibitionRepositoryProvider).updateExhibition(
                              exhibition.id,
                              {'isPublished': val}
                          );
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // 1. UPDATE DETAILS
                          TextButton.icon(
                            onPressed: () => context.push('/organizer/edit', extra: exhibition),
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            label: const Text('Edit Details'),
                          ),
                          // 2. UPDATE FLOOR PLAN
                          TextButton.icon(
                            onPressed: () => context.push('/organizer/builder/${exhibition.id}'),
                            icon: const Icon(Icons.map, color: Colors.deepPurple),
                            label: const Text('Map Editor'),
                          ),
                          // 3. DELETE
                          IconButton(
                            onPressed: () => _confirmDelete(context, ref, exhibition.id, exhibition.title),
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Delete Exhibition',
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}