import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/booth_model.dart';
import '../repositories/booth_repository.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../authentication/models/user_model.dart'; // Needed for role check
import '../../applications/views/application_history_screen.dart';
import '../../applications/models/application_model.dart';
import '../../applications/repositories/application_repository.dart';

final liveBoothsProvider = StreamProvider.family<List<BoothModel>, String>((ref, exhibitionId) {
  return ref.watch(boothRepositoryProvider).getBoothsForExhibition(exhibitionId);
});

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

  // --- SMART TAP HANDLER ---
  void _onBoothTapped(BoothModel booth, bool isLocked, bool hasApplied, UserModel? user) {
    // 0. THE BOUNCER: Politely invite Guests to log in!
    if (user == null || user.role != 'exhibitor') {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Exhibitor Account Required'),
          content: const Text('Halt! You need to login to do that :/'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/login'); // Route them to the login screen!
              },
              child: const Text('Login'),
            ),
          ],
        ),
      );
      return; // Stop them from proceeding to the booking form
    }

    // 1. CHECK IF CURRENT USER ALREADY APPLIED (ORANGE WARNING)
    if (hasApplied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have already applied for this booth. Please wait for approval.'), backgroundColor: Colors.orange),
      );
      return;
    }

    // 2. CHECK IF ANOTHER USER FULLY SECURED IT (RED WARNING)
    if (isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This booth has already been approved for another exhibitor.'), backgroundColor: Colors.red),
      );
      return;
    }

    // 3. IF FREE (OR PENDING FOR OTHERS), SHOW BOOKING DIALOG
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Booth ${booth.boothNumber}'),
        content: Text('Price: RM ${booth.price.toStringAsFixed(2)}\nWould you like to apply for this booth?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/book/${widget.exhibitionId}/${booth.boothNumber}', extra: booth.price);
            },
            child: const Text('Apply for Booth'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final boothsAsync = ref.watch(liveBoothsProvider(widget.exhibitionId));
    final allExAppsAsync = ref.watch(allExhibitionAppsProvider(widget.exhibitionId));
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exhibition Floor Plan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'My Applications',
            onPressed: () => context.push('/history'),
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            width: double.infinity,
            child: const Text(
              'Tap on any available booth to apply. Drag to pan around the map.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),

          // Legend
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(Colors.blueAccent, 'Available'),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.orange, 'My Application'),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.red.shade400, 'Reserved'),
              ],
            ),
          ),

          Expanded(
            child: boothsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, stack) => Center(child: Text('Error: $e')),
              data: (booths) {
                if (booths.isEmpty) {
                  return const Center(child: Text('No booths have been created for this exhibition yet.'));
                }

                return InteractiveViewer(
                  constrained: false,
                  minScale: 0.1,
                  maxScale: 2.0,
                  boundaryMargin: const EdgeInsets.all(100),
                  child: Container(
                    width: 3000,
                    height: 3000,
                    color: Colors.grey.shade200,
                    child: Stack(
                      children: [
                        CustomPaint(
                          size: const Size(3000, 3000),
                          painter: GridPainter(),
                        ),

                        ...booths.map((booth) {
                          final allExhibitionApps = allExAppsAsync.value ?? [];

                          // --- SMART LOGIC 1: Did the CURRENT USER apply? ---
                          bool hasApplied = allExhibitionApps.any((app) {
                            if (app.exhibitorId != user?.uid) return false;
                            final isActive = (app.status == 'pending' || app.status == 'approved' || app.status == 'paid');
                            final matchesBooth = app.boothIds.contains(booth.id) || app.boothIds.contains(booth.boothNumber);
                            return isActive && matchesBooth;
                          });

                          // --- SMART LOGIC 2: THE FIX ---
                          // Did ANYONE ELSE get 'approved' or 'paid'? (Pending is ignored now!)
                          bool isLocked = false;
                          for (var app in allExhibitionApps) {
                            if (app.exhibitorId == user?.uid) continue;

                            // ONLY Approved or Paid lock the booth for others!
                            final isActuallyLocked = (app.status == 'approved' || app.status == 'paid');
                            final matchesBooth = app.boothIds.contains(booth.id) || app.boothIds.contains(booth.boothNumber);

                            if (isActuallyLocked && matchesBooth) {
                              isLocked = true;
                              break;
                            }
                          }

                          // --- SMART LOGIC 3: Assign Colors ---
                          Color boothColor = Colors.blueAccent.withOpacity(0.8);
                          if (hasApplied) {
                            boothColor = Colors.orange; // My bookings turn orange
                          } else if (isLocked) {
                            boothColor = Colors.red.shade400; // Others' APPROVED bookings turn red
                          }

                          return Positioned(
                            left: booth.dx,
                            top: booth.dy,
                            child: GestureDetector(
                              // Pass the user to the tap handler!
                              onTap: () => _onBoothTapped(booth, isLocked, hasApplied, user),
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: boothColor,
                                  border: Border.all(color: Colors.black54, width: 2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(booth.boothNumber, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                      Text('RM${booth.price.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white70, fontSize: 10)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.black54, width: 1)
            )
        ),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}