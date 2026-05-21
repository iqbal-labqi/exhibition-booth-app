import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../applications/models/application_model.dart';
import '../../applications/repositories/application_repository.dart';

// Provider to fetch all reservations for the Admin
final adminAllReservationsProvider = StreamProvider<List<ApplicationModel>>((ref) {
  return ref.watch(applicationRepositoryProvider).getAllApplicationsAdmin();
});

class AdminReservationsScreen extends ConsumerWidget {
  const AdminReservationsScreen({super.key});

  // The Admin Override Dialog
  void _showEditDialog(BuildContext context, WidgetRef ref, ApplicationModel app) {
    String selectedStatus = app.status;
    final List<String> statuses = ['pending', 'approved', 'rejected', 'paid', 'cancel_requested', 'cancelled'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Admin Override: Edit Status'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Company: ${app.companyName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Booth(s): ${app.boothIds.join(', ')}'),
                  const SizedBox(height: 16),
                  const Text('Force change status to:'),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: selectedStatus,
                    items: statuses.map((String status) {
                      return DropdownMenuItem<String>(
                        value: status,
                        child: Text(status.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (newStatus) {
                      if (newStatus != null) {
                        setState(() => selectedStatus = newStatus);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.deepPurple),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    try {
                      await ref.read(applicationRepositoryProvider).updateApplicationStatus(app.id, selectedStatus);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Status overridden successfully!'), backgroundColor: Colors.green),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                  child: const Text('Save Changes'),
                ),
              ],
            );
          }
      ),
    );
  }

  // Helper to color-code the status badges
  Color _getStatusColor(String status) {
    switch (status) {
      case 'paid': return Colors.blueAccent;
      case 'approved': return Colors.green;
      case 'pending': return Colors.orange;
      case 'rejected': return Colors.red;
      case 'cancelled': return Colors.grey;
      case 'cancel_requested': return Colors.purple;
      default: return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservationsAsync = ref.watch(adminAllReservationsProvider);
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return Scaffold(
      body: reservationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (reservations) {
          if (reservations.isEmpty) return const Center(child: Text('No reservations found in the system.'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reservations.length,
            itemBuilder: (context, index) {
              final app = reservations[index];
              final statusColor = _getStatusColor(app.status);

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              app.companyName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: statusColor),
                            ),
                            child: Text(
                              app.status.toUpperCase(),
                              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      Text('Exhibition: ${app.exhibitionTitle}'),
                      Text('Booth(s): ${app.boothIds.join(', ')}'),
                      // THE FIX: Read the actual amount from Firebase!
                      Text('Amount: RM ${app.amount.toStringAsFixed(2)}'),
                      Text('Date: ${dateFormat.format(app.createdAt)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: () => _showEditDialog(context, ref, app),
                          icon: const Icon(Icons.edit_document, size: 16, color: Colors.deepPurple),
                          label: const Text('Admin Override', style: TextStyle(color: Colors.deepPurple)),
                        ),
                      )
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
}