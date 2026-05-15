import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart'; // Add 'intl' to pubspec.yaml for date formatting
import '../providers/exhibition_provider.dart';

class GuestHomeScreen extends ConsumerWidget {
  const GuestHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the stream of exhibitions
    final exhibitionsAsyncValue = ref.watch(publishedExhibitionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming Exhibitions', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/login'),
            icon: const Icon(Icons.login),
            label: const Text('Login'),
          ),
        ],
      ),
      // .when handles the Loading, Error, and Success states automatically!
      body: exhibitionsAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (exhibitions) {
          if (exhibitions.isEmpty) {
            return _buildEmptyState();
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: exhibitions.length,
            itemBuilder: (context, index) {
              final exhibition = exhibitions[index];
              return _buildExhibitionCard(context, exhibition);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No exhibitions available right now.',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildExhibitionCard(BuildContext context, exhibition) {
    final dateformat = DateFormat('MMM dd, yyyy'); // Requires 'intl' package

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // TODO: Navigate to Exhibition Details Screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Details coming soon!')),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Placeholder Image
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: const Icon(Icons.image, size: 50, color: Colors.blue),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}