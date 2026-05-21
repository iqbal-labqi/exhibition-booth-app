import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../exhibitions/models/exhibition_model.dart';
import '../../exhibitions/repositories/exhibition_repository.dart';
// --- NEW IMPORTS FOR CREATOR LOGIC ---
import '../../authentication/providers/auth_provider.dart';
import 'user_management_screen.dart'; // Brings in allUsersProvider

// Provider to watch ALL exhibitions for the Admin
final adminAllExhibitionsProvider = StreamProvider<List<ExhibitionModel>>((ref) {
  return ref.watch(exhibitionRepositoryProvider).getAllExhibitionsAdmin();
});

class AdminExhibitionScreen extends ConsumerWidget {
  const AdminExhibitionScreen({super.key});

  // Helper method for Status Badge
  Map<String, dynamic> _getExhibitionStatus(DateTime start, DateTime end) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);

    if (today.isBefore(startDate)) {
      return {'text': 'UPCOMING', 'color': Colors.blue};
    } else if (today.isAfter(endDate)) {
      return {'text': 'PAST', 'color': Colors.grey};
    } else {
      return {'text': 'ONGOING', 'color': Colors.green};
    }
  }

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
                    const SnackBar(content: Text('Exhibition deleted'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
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
    // --- WATCH LIVE USER DATA ---
    final usersAsync = ref.watch(allUsersProvider);
    final currentUser = ref.watch(currentUserProvider);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Exhibitions'),
      ),
      body: exhibitionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (exhibitions) {
          if (exhibitions.isEmpty) {
            return const Center(child: Text('No exhibitions found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: exhibitions.length,
            itemBuilder: (context, index) {
              final exhibition = exhibitions[index];

              // --- CROSS-REFERENCE CREATOR ID WITH USERS DB ---
              String creatorName = 'Loading...';
              if (usersAsync.value != null) {
                if (exhibition.organizerId == currentUser?.uid) {
                  creatorName = 'You (Admin)';
                } else {
                  // Find the user who created it
                  final creator = usersAsync.value!.firstWhere(
                          (u) => u['uid'] == exhibition.organizerId,
                      orElse: () => {'name': 'Unknown Organizer'}
                  );
                  creatorName = creator['name'] ?? 'Unknown Organizer';
                }
              }

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: Image.network(
                            exhibition.imageUrl.isNotEmpty
                                ? exhibition.imageUrl
                                : 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?q=80&w=1000&auto=format&fit=crop',
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 150,
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                              );
                            },
                          ),
                        ),
                        // TIMELINE STATUS BADGE
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Builder(
                              builder: (context) {
                                final status = _getExhibitionStatus(exhibition.startDate, exhibition.endDate);
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                      color: status['color'],
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))
                                      ]
                                  ),
                                  child: Text(
                                    status['text'],
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
                                  ),
                                );
                              }
                          ),
                        ),
                      ],
                    ),

                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(exhibition.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),

                          // --- NEW: STYLISH CREATOR TAG ---
                          Row(
                            children: [
                              Icon(Icons.person, size: 16, color: Colors.deepPurple.shade300),
                              const SizedBox(width: 6),
                              Text(
                                'Created by: $creatorName',
                                style: TextStyle(color: Colors.deepPurple.shade700, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // DESCRIPTION (Max 2 lines)
                          Text(
                            exhibition.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),

                          // DATES & PUBLISHED TAG
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  '${dateFormat.format(exhibition.startDate)} - ${dateFormat.format(exhibition.endDate)}',
                                  style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)
                              ),
                              // PUBLISHED/DRAFT INDICATOR
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: exhibition.isPublished ? Colors.green.shade50 : Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: exhibition.isPublished ? Colors.green : Colors.orange),
                                ),
                                child: Text(
                                  exhibition.isPublished ? 'Published' : 'Draft',
                                  style: TextStyle(
                                    color: exhibition.isPublished ? Colors.green.shade700 : Colors.orange.shade800,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),

                          // --- ADMIN ACTION BUTTONS ---
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              TextButton.icon(
                                onPressed: () => context.push('/organizer/edit', extra: exhibition),
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                label: const Text('Edit Details'),
                              ),
                              TextButton.icon(
                                onPressed: () => context.push('/organizer/builder/${exhibition.id}'),
                                icon: const Icon(Icons.map, color: Colors.deepPurple),
                                label: const Text('Map Editor'),
                              ),
                              IconButton(
                                onPressed: () => _confirmDelete(context, ref, exhibition.id, exhibition.title),
                                icon: const Icon(Icons.delete, color: Colors.red),
                                tooltip: 'Delete Exhibition',
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
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