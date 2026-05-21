import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/exhibition_provider.dart';

// --- NEW: StateProvider to track the selected filter ---
final guestFilterProvider = StateProvider<String>((ref) => 'All');

class GuestHomeScreen extends ConsumerWidget {
  const GuestHomeScreen({super.key});

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
    final exhibitionsAsyncValue = ref.watch(publishedExhibitionsProvider);
    final selectedFilter = ref.watch(guestFilterProvider); // Watch the active filter
    final filters = ['All', 'Ongoing', 'Upcoming', 'Past']; // Filter options

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Exhibitions', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/login'),
            icon: const Icon(Icons.login),
            label: const Text('Login'),
          ),
        ],
      ),
      body: Column(
        children: [
          // --- THE NEW FILTER ROW ---
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
                      // Update the filter provider when clicked!
                      ref.read(guestFilterProvider.notifier).state = filter;
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

          // --- THE EXHIBITIONS LIST ---
          Expanded(
            child: exhibitionsAsyncValue.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
              data: (exhibitions) {
                // Apply the filter logic!
                final filteredExhibitions = exhibitions.where((ex) {
                  if (selectedFilter == 'All') return true;
                  final statusText = _getExhibitionStatus(ex.startDate, ex.endDate)['text'] as String;
                  return statusText.toLowerCase() == selectedFilter.toLowerCase();
                }).toList();

                if (filteredExhibitions.isEmpty) {
                  return _buildEmptyState(selectedFilter);
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: filteredExhibitions.length,
                  itemBuilder: (context, index) {
                    final exhibition = filteredExhibitions[index];
                    final dateformat = DateFormat('MMM dd, yyyy');

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      clipBehavior: Clip.antiAlias, // Keeps ripples inside corners
                      child: InkWell( // Makes it clickable
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    exhibition.title,
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    exhibition.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${dateformat.format(exhibition.startDate)} - ${dateformat.format(exhibition.endDate)}',
                                        style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: FilledButton.tonal(
                                      onPressed: () => context.push('/map/${exhibition.id}'),
                                      child: const Text('View Floor Plan'),
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

  // Dynamic empty state based on filter
  Widget _buildEmptyState(String filter) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No $filter Exhibitions.',
            style: TextStyle(fontSize: 20, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}