import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../repositories/application_repository.dart';
import '../../authentication/providers/auth_provider.dart';
import '../models/application_model.dart';

// Stream Provider for Exhibitor's History
final exhibitorHistoryProvider = StreamProvider<List<ApplicationModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(applicationRepositoryProvider).getExhibitorApplications(user.uid);
});

class ApplicationHistoryScreen extends ConsumerWidget {
  const ApplicationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(exhibitorHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Applications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/exhibitor'), // Go back to dashboard
        ),
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (applications) {
          if (applications.isEmpty) return const Center(child: Text('No applications found.'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final app = applications[index];
              return Card(
                child: ListTile(
                  title: Text(app.exhibitionTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${app.companyName}\nBooth: ${app.boothIds.join(', ')}\nStatus: ${app.status.toUpperCase()}'),
                  isThreeLine: true,
                    trailing: _buildTrailingAction(context, ref, app),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _getStatusIcon(String status) {
    if (status == 'approved') return const Icon(Icons.check_circle, color: Colors.green);
    if (status == 'paid') return const Icon(Icons.verified, color: Colors.blueAccent); // ADDED THIS LINE
    if (status == 'rejected') return const Icon(Icons.error, color: Colors.red);
    if (status == 'cancel_requested') return const Icon(Icons.hourglass_bottom, color: Colors.purple);
    return const Icon(Icons.do_not_disturb, color: Colors.grey);
  }

  void _confirmCancel(BuildContext context, WidgetRef ref, ApplicationModel app) { // Pass the whole 'app' object here
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Application?'),
        content: const Text('Are you sure you want to cancel this booth booking?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('No')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              // Pass the ID AND the status to our new smart method!
              await ref.read(applicationRepositoryProvider).cancelApplication(app.id, app.status);
            },
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }
  Widget _buildTrailingAction(BuildContext context, WidgetRef ref, ApplicationModel app) {
    if (app.status == 'pending') {
      return IconButton(
        icon: const Icon(Icons.cancel, color: Colors.red),
        tooltip: 'Cancel Application',
        onPressed: () => _confirmCancel(context, ref, app), // Make sure it passes 'app'
      );
    } else if (app.status == 'approved') {
      // FIX: SHOW BOTH PAY AND CANCEL BUTTONS
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.cancel_presentation, color: Colors.purple),
            tooltip: 'Request Cancellation',
            onPressed: () => _confirmCancel(context, ref, app),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            // CHANGE THIS LINE:
            onPressed: () => context.push('/pay/${app.id}'),
            icon: const Icon(Icons.payment, size: 16),
            label: const Text('Pay Now'),
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
          ),
        ],
      );
    } else {
      return _getStatusIcon(app.status);
    }
  }
}