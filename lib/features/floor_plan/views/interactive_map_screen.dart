import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/booth_model.dart';
import '../repositories/booth_repository.dart'; // NEW: To get live booths
import '../../authentication/providers/auth_provider.dart';
import '../../applications/views/application_history_screen.dart';
import '../../applications/models/application_model.dart';
import '../../applications/repositories/application_repository.dart'; // NEW: To check if a booth is paid/approved

// 1. Fetch the LIVE booths created by the Organizer
final liveBoothsProvider = StreamProvider.family<List<BoothModel>, String>((ref, exhibitionId) {
  return ref.watch(boothRepositoryProvider).getBoothsForExhibition(exhibitionId);
});

// 2. Fetch ALL applications for this exhibition so the map knows what is already booked
final allExhibitionAppsProvider = StreamProvider.family<List<ApplicationModel>, String>((ref, exhibitionId) {
  return ref.watch(applicationRepositoryProvider).getApplicationsForExhibition(exhibitionId);
});

class InteractiveMapScreen extends ConsumerStatefulWidget {
  final String exhibitionId;
  const InteractiveMapScreen({super.key, required this.exhibitionId});

  @override
  ConsumerState<InteractiveMapScreen> createState() => _InteractiveMapScreenState();
}

class _InteractiveMapScreenState extends ConsumerState<InteractiveMapScreen> {

  // Notice: _dummyBooths is completely GONE!

  void _onBoothTapped(BoothModel booth, List<ApplicationModel> userApps, bool isBooked) {
    if (isBooked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This booth is already booked.'), backgroundColor: Colors.red),
      );
      return;
    }

    // --- ANTI-SPAM LOGIC ---
    final hasApplied = userApps.any((app) =>
    app.exhibitionId == widget.exhibitionId &&
        app.boothIds.contains(booth.boothNumber) &&
        (app.status == 'pending' || app.status == 'approved' || app.status == 'paid' || app.status == 'cancel_requested')
    );

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        final user = ref.watch(currentUserProvider);

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Booth ${booth.boothNumber}', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text('Price: RM ${booth.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, color: Colors.green)),
              const SizedBox(height: 24),

              if (user == null)
                FilledButton.icon(
                  onPressed: () {
                    context.pop();
                    context.push('/login');
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('Login to Book'),
                )
              else if (user.role == 'exhibitor')
                if (hasApplied)
                   FilledButton.icon(
                    onPressed: null,
                    icon: Icon(Icons.lock_clock),
                    label: Text('Application Already Submitted'),
                  )
                else
                  FilledButton(
                    onPressed: () {
                      context.pop();
                      context.push('/book/${widget.exhibitionId}/${booth.boothNumber}', extra: booth.price);
                    },
                    child: const Text('Apply for Booth'),
                  )
              else
                const Text('Only Exhibitors can book booths.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch user's history for anti-spam
    final historyAsync = ref.watch(exhibitorHistoryProvider);
    final userApps = historyAsync.value ?? [];

    // Watch LIVE Booths and LIVE Applications
    final boothsAsync = ref.watch(liveBoothsProvider(widget.exhibitionId));
    final allAppsAsync = ref.watch(allExhibitionAppsProvider(widget.exhibitionId));

    return Scaffold(
      appBar: AppBar(title: const Text('Interactive Floor Plan')),
      body: boothsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading map: $err')),
        data: (liveBooths) {

          if (liveBooths.isEmpty) {
            return const Center(child: Text('The organizer has not set up the floor plan yet.'));
          }

          // Figure out which booths are already taken by other people
          final allApps = allAppsAsync.value ?? [];
          final takenBoothNumbers = allApps
              .where((app) => app.status == 'approved' || app.status == 'paid')
              .expand((app) => app.boothIds)
              .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem(Colors.green, 'Available'),
                    const SizedBox(width: 16),
                    _buildLegendItem(Colors.red, 'Booked'),
                  ],
                ),
              ),
              Expanded(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  constrained: false,
                  boundaryMargin: const EdgeInsets.all(double.infinity),
                  child: Stack(
                    children: [
                      Container(
                        width: 1200,
                        height: 1200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          image: const DecorationImage(
                            image: NetworkImage('https://www.transparenttextures.com/patterns/graphy.png'),
                            repeat: ImageRepeat.repeat,
                          ),
                        ),
                        child: const Center(child: Text('Exhibition Hall Map', style: TextStyle(color: Colors.grey, fontSize: 32))),
                      ),

                      // Loop through the LIVE booths instead of dummy booths
                      ...liveBooths.map((booth) {

                        // Check if this specific booth number is in the "taken" list
                        final isBooked = takenBoothNumbers.contains(booth.boothNumber);
                        final color = isBooked ? Colors.red : Colors.green;

                        return Positioned(
                          left: booth.dx,
                          top: booth.dy,
                          child: GestureDetector(
                            onTap: () => _onBoothTapped(booth, userApps, isBooked),
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.8),
                                border: Border.all(color: Colors.black54, width: 2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  booth.boothNumber,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(width: 16, height: 16, color: color),
        const SizedBox(width: 4),
        Text(text),
      ],
    );
  }
}