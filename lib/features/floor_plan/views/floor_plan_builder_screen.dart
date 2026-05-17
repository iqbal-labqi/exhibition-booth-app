import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/booth_model.dart';
import '../repositories/booth_repository.dart';
import '../../applications/repositories/application_repository.dart';

class FloorPlanBuilderScreen extends ConsumerStatefulWidget {
  final String exhibitionId;
  const FloorPlanBuilderScreen({super.key, required this.exhibitionId});

  @override
  ConsumerState<FloorPlanBuilderScreen> createState() => _FloorPlanBuilderScreenState();
}

class _FloorPlanBuilderScreenState extends ConsumerState<FloorPlanBuilderScreen> {
  List<BoothModel> _booths = [];
  bool _isLoading = false;

  // 1. ADD THIS INITSTATE METHOD
  @override
  void initState() {
    super.initState();
    _loadExistingBooths();
  }

  Future<void> _loadExistingBooths() async {
    setState(() => _isLoading = true);
    try {
      // Grab the current saved floor plan from Firebase!
      final existingBooths = await ref.read(boothRepositoryProvider)
          .getBoothsForExhibition(widget.exhibitionId)
          .first; // Gets the latest snapshot

      if (mounted) {
        setState(() {
          _booths = existingBooths.toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading booths: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  // Handles tapping on the map to place a new booth
  void _handleTap(TapUpDetails details) {
    final dx = details.localPosition.dx;
    final dy = details.localPosition.dy;
    _showAddBoothDialog(dx, dy);
  }

  void _showAddBoothDialog(double dx, double dy) {
    final numberCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '1500');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Booth'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: numberCtrl, decoration: const InputDecoration(labelText: 'Booth Number (e.g. A-01)')),
            TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (RM)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (numberCtrl.text.isNotEmpty) {
                setState(() {
                  _booths.add(BoothModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(), // Temp ID
                    boothNumber: numberCtrl.text.trim(),
                    price: double.tryParse(priceCtrl.text) ?? 1500,
                    dx: dx - 40, // Offset so the tap is in the center of the 80x80 box
                    dy: dy - 40,
                  ));
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Place Booth'),
          )
        ],
      ),
    );
  }

  Future<void> _saveFloorPlan() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(boothRepositoryProvider).saveFloorPlan(widget.exhibitionId, _booths);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Floor Plan Saved!'), backgroundColor: Colors.green));
        context.pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Build Floor Plan'),
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _saveFloorPlan,
            icon: const Icon(Icons.save, color: Colors.black),
            label: const Text('Save', style: TextStyle(color: Colors.black)),
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.blue.shade50,
            child: const Row(
              children: [
                Icon(Icons.touch_app, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(child: Text('Tap anywhere on the grid to place a new booth. Tap an existing booth to delete it.')),
              ],
            ),
          ),
          Expanded(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              constrained: false,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              child: GestureDetector(
                onTapUp: _handleTap, // Captures the exact X and Y of the tap!
                child: Stack(
                  children: [
                    // The Background Grid
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
                      child: const Center(child: Text('Floor Plan Canvas', style: TextStyle(color: Colors.grey, fontSize: 48))),
                    ),

                    // The Booths Being Placed
                    ..._booths.map((booth) => Positioned(
                      left: booth.dx,
                      top: booth.dy,
                      child: GestureDetector(
                        // UPGRADED ONTAP: The Strict Guard Logic
                        onTap: () async {
                          setState(() => _isLoading = true);
                          try {
                            final hasActiveApps = await ref.read(applicationRepositoryProvider)
                                .hasActiveApplicationsForBooth(widget.exhibitionId, booth.boothNumber);

                            if (hasActiveApps) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Cannot delete: Booth ${booth.boothNumber} has active applications!'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } else {
                              // Safe to delete!
                              setState(() => _booths.remove(booth));
                            }
                          } catch (e) {
                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                          } finally {
                            if (mounted) setState(() => _isLoading = false);
                          }
                        },
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.8),
                            border: Border.all(color: Colors.black54, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(booth.boothNumber, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    )),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}