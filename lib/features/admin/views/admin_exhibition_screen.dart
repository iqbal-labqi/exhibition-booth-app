import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../exhibitions/models/exhibition_model.dart';
import '../../exhibitions/repositories/exhibition_repository.dart';
import '../../authentication/providers/auth_provider.dart';
import 'user_management_screen.dart';

// Provider to watch ALL exhibitions for the Admin
final adminAllExhibitionsProvider = StreamProvider<List<ExhibitionModel>>((ref) {
  return ref.watch(exhibitionRepositoryProvider).getAllExhibitionsAdmin();
});

// --- NEW: STATE PROVIDER FOR THE FILTER ---
final adminExhibitionFilterProvider = StateProvider<String>((ref) => 'All');

class AdminExhibitionScreen extends ConsumerWidget {
  const AdminExhibitionScreen({super.key});

  // Helper method for Status Badge & Filtering
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
    final usersAsync = ref.watch(allUsersProvider);
    final currentUser = ref.watch(currentUserProvider);
    final filter = ref.watch(adminExhibitionFilterProvider); // Watch the active filter!
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Exhibitions'),
      ),
      body: exhibitionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (exhibitions) {

          // --- NEW: FILTER LOGIC ---
          final filteredExhibitions = exhibitions.where((exhibition) {
            if (filter == 'All') return true;

            final status = _getExhibitionStatus(exhibition.startDate, exhibition.endDate)['text'];
            if (filter == 'Upcoming' && status == 'UPCOMING') return true;
            if (filter == 'Ongoing' && status == 'ONGOING') return true;
            if (filter == 'Past' && status == 'PAST') return true;

            return false;
          }).toList();

          return Column(
            children: [
              // --- NEW: BEAUTIFUL FILTER CHIPS ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                color: Colors.grey.shade50,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Upcoming', 'Ongoing', 'Past'].map((String category) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(category, style: TextStyle(
                              fontWeight: filter == category ? FontWeight.bold : FontWeight.normal,
                              color: filter == category ? Colors.white : Colors.black87
                          )),
                          selected: filter == category,
                          selectedColor: Colors.deepPurple,
                          backgroundColor: Colors.white,
                          onSelected: (selected) {
                            if (selected) {
                              ref.read(adminExhibitionFilterProvider.notifier).state = category;
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // --- THE EXHIBITION LIST ---
              Expanded(
                child: filteredExhibitions.isEmpty
                    ? Center(
                  child: Text(
                    'No $filter exhibitions found.',
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: filteredExhibitions.length,
                  itemBuilder: (context, index) {
                    final exhibition = filteredExhibitions[index];

                    // Cross-reference Creator
                    String creatorName = 'Loading...';
                    if (usersAsync.value != null) {
                      if (exhibition.organizerId == currentUser?.uid) {
                        creatorName = 'You (Admin)';
                      } else {
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

                                Text(
                                  exhibition.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 12),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                        '${dateFormat.format(exhibition.startDate)} - ${dateFormat.format(exhibition.endDate)}',
                                        style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)
                                    ),
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
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/organizer/create'), // Reuses the Organizer form!
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Exhibition', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}