import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../authentication/providers/auth_provider.dart';
import '../providers/exhibition_provider.dart';

// --- NEW: StateProvider for Organizer Filter ---
final organizerFilterProvider = StateProvider<String>((ref) => 'All');

class OrganizerDashboard extends ConsumerWidget {
  const OrganizerDashboard({super.key});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exhibitionsAsyncValue = ref.watch(organizerExhibitionsProvider);
    final selectedFilter = ref.watch(organizerFilterProvider);
    final filters = ['All', 'Ongoing', 'Upcoming', 'Past'];
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Exhibitions', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      // CLEAN, FOCUSED SIDEBAR
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(user?.name ?? 'Organizer', style: const TextStyle(fontWeight: FontWeight.bold)),
              accountEmail: Text(user?.email ?? 'Manage your events'),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.event, size: 40, color: Colors.orange),
              ),
              decoration: BoxDecoration(color: Colors.orange.shade400),
            ),
            ListTile(
              leading: const Icon(Icons.add_circle_outline, color: Colors.orange),
              title: const Text('Create New Exhibition'),
              onTap: () {
                Navigator.pop(context);
                context.push('/organizer/create');
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
      body: Column(
        children: [
          // --- THE FILTER ROW ---
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = filters[index];
                final isSelected = selectedFilter == filter;
                return ChoiceChip(
                  label: Text(filter),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      ref.read(organizerFilterProvider.notifier).state = filter;
                    }
                  },
                  selectedColor: Colors.orange.shade100,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.orange.shade900 : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              },
            ),
          ),

          // --- THE LIST ---
          Expanded(
            child: exhibitionsAsyncValue.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
              data: (exhibitions) {
                // Apply Filter Logic
                final filteredExhibitions = exhibitions.where((ex) {
                  if (selectedFilter == 'All') return true;
                  final statusText = _getExhibitionStatus(ex.startDate, ex.endDate)['text'] as String;
                  return statusText.toLowerCase() == selectedFilter.toLowerCase();
                }).toList();

                if (filteredExhibitions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No $selectedFilter exhibitions found.',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: filteredExhibitions.length,
                  itemBuilder: (context, index) {
                    final exhibition = filteredExhibitions[index];
                    final dateFormat = DateFormat('MMM dd, yyyy');

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell( // <-- ADDED: Makes the whole card clickable!
                        onTap: () => context.push('/organizer/manage/${exhibition.id}'),
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
                                  const SizedBox(height: 8),

                                  // --- NEW: DESCRIPTION ADDED HERE ---
                                  Text(
                                    exhibition.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  // -----------------------------------

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

                                  // --- MANAGE APPLICATIONS BUTTON ---
                                  FilledButton.tonalIcon(
                                    onPressed: () => context.push('/organizer/manage/${exhibition.id}'),
                                    icon: const Icon(Icons.people_alt),
                                    label: const Text('Manage Applications', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),

                                  const SizedBox(height: 4),
                                  const Divider(),
                                  const SizedBox(height: 4),

                                  // ORGANIZER CONTROL BUTTONS
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () => context.push('/organizer/edit', extra: exhibition),
                                        icon: const Icon(Icons.edit_document, color: Colors.blue),
                                        label: const Text('Edit Details'),
                                      ),
                                      FilledButton.icon(
                                        style: FilledButton.styleFrom(backgroundColor: Colors.orange.shade700),
                                        onPressed: () => context.push('/organizer/builder/${exhibition.id}'),
                                        icon: const Icon(Icons.map),
                                        label: const Text('Map Editor'),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/organizer/create'),
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Exhibition', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}