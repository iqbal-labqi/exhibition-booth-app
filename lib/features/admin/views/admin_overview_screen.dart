import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// We import the providers from the screens we already built!
import 'user_management_screen.dart';
import 'admin_exhibition_screen.dart';
import 'admin_reservations_screen.dart';

class AdminOverviewScreen extends ConsumerWidget {
  const AdminOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch all our data streams in real-time
    final usersAsync = ref.watch(allUsersProvider);
    final exhibitionsAsync = ref.watch(adminAllExhibitionsProvider);
    final reservationsAsync = ref.watch(adminAllReservationsProvider);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Platform Analytics', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
            const SizedBox(height: 16),

            // The Metrics Grid
            GridView.count(
              crossAxisCount: 2, // 2 boxes per row
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              childAspectRatio: 1.2,
              physics: const NeverScrollableScrollPhysics(), // Let the SingleChildScrollView handle scrolling
              children: [
                // 1. Total Users Metric
                usersAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => _buildStatCard('Users', 'Error', Icons.people, Colors.grey),
                  data: (users) => _buildStatCard('Total Users', '${users.length}', Icons.people, Colors.blue),
                ),

                // 2. Total Organizers Metric
                usersAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => _buildStatCard('Organizers', 'Error', Icons.business, Colors.grey),
                  data: (users) {
                    final organizers = users.where((u) => u['role'] == 'organizer').length;
                    return _buildStatCard('Organizers', '$organizers', Icons.business, Colors.orange);
                  },
                ),

                // 3. Total Exhibitions Metric
                exhibitionsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => _buildStatCard('Exhibitions', 'Error', Icons.event, Colors.grey),
                  data: (exhibitions) => _buildStatCard('Exhibitions', '${exhibitions.length}', Icons.event, Colors.purple),
                ),

                // 4. Total Bookings Metric
                reservationsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => _buildStatCard('Bookings', 'Error', Icons.book_online, Colors.grey),
                  data: (reservations) => _buildStatCard('Total Bookings', '${reservations.length}', Icons.book_online, Colors.teal),
                ),

                // 5. Estimated Revenue Metric (Stretches across 2 columns)
              ],
            ),

            const SizedBox(height: 16),

            // Full-width Revenue Card
            reservationsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => const SizedBox.shrink(),
              data: (reservations) {
                double revenue = 0;
                for (var app in reservations) {
                  // Only count money that is paid or approved!
                  if (app.status == 'paid' || app.status == 'approved') {
                    revenue += app.amount; // THE FIX: Add the real amount!
                  }
                }
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green.shade200, width: 2),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.account_balance_wallet, color: Colors.green, size: 40),
                      const SizedBox(height: 8),
                      const Text('Total Estimated Revenue', style: TextStyle(fontSize: 16, color: Colors.black54)),
                      Text('RM ${revenue.toStringAsFixed(2)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // A helper widget to draw the beautiful cards
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54)),
        ],
      ),
    );
  }
}