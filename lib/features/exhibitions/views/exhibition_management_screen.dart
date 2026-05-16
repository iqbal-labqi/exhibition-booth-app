import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../applications/models/application_model.dart';
import '../../applications/repositories/application_repository.dart';

// We use .family to pass the exhibitionId into the provider!
final exhibitionApplicationsProvider = StreamProvider.family<List<ApplicationModel>, String>((ref, exhibitionId) {
  return ref.watch(applicationRepositoryProvider).getApplicationsForExhibition(exhibitionId);
});

class ExhibitionManagementScreen extends ConsumerWidget {
  final String exhibitionId;
  const ExhibitionManagementScreen({super.key, required this.exhibitionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationsAsync = ref.watch(exhibitionApplicationsProvider(exhibitionId));

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Applications')),
      body: applicationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (applications) {
          if (applications.isEmpty) return const Center(child: Text('No applications yet.'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final app = applications[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(app.companyName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          _buildStatusBadge(app.status),
                        ],
                      ),
                      const Divider(),
                      Text('Booth Requested: ${app.boothIds.join(', ')}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Profile: ${app.exhibitProfile}'),
                      if (app.addOns.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('Add-ons: ${app.addOns.join(', ')}', style: const TextStyle(color: Colors.blueAccent)),
                      ],
                      const SizedBox(height: 16),
                      // ACTION BUTTONS BASED ON STATUS
                      _buildActionButtons(context, ref, app),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.grey;
    if (status == 'approved') color = Colors.green;
    if (status == 'rejected') color = Colors.red;
    if (status == 'pending') color = Colors.orange;
    if (status == 'cancel_requested') color = Colors.purple;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, ApplicationModel app) {
    final repo = ref.read(applicationRepositoryProvider);

    if (app.status == 'pending') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton.icon(
            onPressed: () => repo.updateApplicationStatus(app.id, 'rejected'),
            icon: const Icon(Icons.close, color: Colors.red),
            label: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              // Show loading/confirmation in a real app, but for now:
              try {
                // CALL THE NEW SMART METHOD! Pass the whole 'app' object.
                await repo.approveApplicationAndRejectOthers(app);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Approved! Competitors rejected.'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            icon: const Icon(Icons.check),
            label: const Text('Approve'),
          ),
        ],
      );
    } else if (app.status == 'cancel_requested') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => repo.updateApplicationStatus(app.id, 'approved'), // Deny cancel, keep approved
            child: const Text('Deny Cancellation'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => repo.updateApplicationStatus(app.id, 'cancelled'), // Accept cancel
            child: const Text('Approve Cancellation'),
          ),
        ],
      );
    }
    return const SizedBox.shrink(); // No buttons if already approved/rejected/cancelled
  }
}