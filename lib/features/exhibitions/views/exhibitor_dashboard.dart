import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/exhibition_provider.dart';
import '../../authentication/providers/auth_provider.dart';

// --- NEW: StateProvider for Exhibitor Filter ---
final exhibitorFilterProvider = StateProvider<String>((ref) => 'All');

class ExhibitorDashboard extends ConsumerWidget {
  const ExhibitorDashboard({super.key});

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
    final exhibitionsAsyncValue = ref.watch(publishedExhibitionsProvider);
    final selectedFilter = ref.watch(exhibitorFilterProvider);
    final filters = ['All', 'Ongoing', 'Upcoming', 'Past'];
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Exhibitions'),
      ),
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
                Navigator.pop(context);
                context.push('/history');
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
                      ref.read(exhibitorFilterProvider.notifier).state = filter;
                    }
                  },
                  selectedColor: Colors.blue.shade100,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.blue.shade900 : Colors.black87,
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
                      child: Text('No $selectedFilter exhibitions.',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 18)
                      )
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
                      child: InkWell(
                        onTap: () => context.push('/map/${exhibition.id}'),
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
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 120,
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
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}