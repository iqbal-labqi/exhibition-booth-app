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

  @override
  void initState() {
    super.initState();
    _loadExistingBooths();
  }

  Future<void> _loadExistingBooths() async {
    setState(() => _isLoading = true);
    try {
      final existingBooths = await ref.read(boothRepositoryProvider)
          .getBoothsForExhibition(widget.exhibitionId)
          .first;

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
            TextField(controller: priceCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Price (RM)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (numberCtrl.text.isNotEmpty) {
                setState(() {
                  _booths.add(BoothModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(), // Temp ID for new booths
                    boothNumber: numberCtrl.text.trim(),
                    price: double.tryParse(priceCtrl.text) ?? 1500,
                    dx: dx - 40,
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- NEW EDIT BOOTH DIALOG ---
  void _showEditBoothDialog(BoothModel booth) {
    final numberController = TextEditingController(text: booth.boothNumber);
    final priceController = TextEditingController(text: booth.price.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Booth Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: numberController,
              decoration: const InputDecoration(
                labelText: 'Booth Number/Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Price (RM)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          // 1. CANCEL BUTTON
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),

          // 2. THE NEW DELETE BUTTON
          TextButton.icon(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              setState(() => _booths.remove(booth)); // Removes it from the grid!
            },
            icon: const Icon(Icons.delete, color: Colors.red, size: 18),
            label: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),

          // 3. SAVE BUTTON
          FilledButton(
            onPressed: () {
              final newNumber = numberController.text.trim();
              final newPrice = double.tryParse(priceController.text) ?? booth.price;

              Navigator.pop(ctx); // Close dialog

              // Update the booth locally in the list
              setState(() {
                final index = _booths.indexOf(booth);
                if (index != -1) {
                  _booths[index] = BoothModel(
                    id: booth.id,
                    boothNumber: newNumber,
                    price: newPrice,
                    dx: booth.dx,
                    dy: booth.dy,
                  );
                }
              });
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Floor Plan Builder'),
        actions: [
          _isLoading
              ? const Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: CircularProgressIndicator()))
              : IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveFloorPlan,
            tooltip: 'Save Floor Plan',
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
              'Tap anywhere on the grid to add a booth. Tap an existing booth to edit or delete it.\nDrag to pan around the map.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),

          Expanded(
            // --- WE ADDED INTERACTIVE VIEWER HERE TO RESTORE SCROLLING! ---
            child: InteractiveViewer(
              constrained: false, // This is the magic rule that lets the canvas be bigger than the screen
              minScale: 0.1,
              maxScale: 2.0, // Lets them zoom in and out
              boundaryMargin: const EdgeInsets.all(100), // Gives a little extra padding at the edges
              child: GestureDetector(
                onTapUp: _handleTap,
                child: Container(
                  width: 3000, // We give you a massive 3000x3000 canvas to scroll around in!
                  height: 3000,
                  color: Colors.grey.shade200,
                  child: Stack(
                    children: [
                      // Grid background
                      CustomPaint(
                        size: const Size(3000, 3000), // Match the canvas size
                        painter: GridPainter(),
                      ),

                      // Draw the booths!
                      ..._booths.map((booth) => Positioned(
                        left: booth.dx,
                        top: booth.dy,
                        child: GestureDetector(
                          onTap: () async {
                            if (_isLoading) return;

                            setState(() => _isLoading = true);
                            try {
                              // 1. Check our Strict Guard first!
                              final isLocked = await ref.read(applicationRepositoryProvider).isBoothBookedOrPending(widget.exhibitionId, booth.id, booth.boothNumber);

                              if (isLocked) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Cannot edit. This booth is already booked or pending!'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } else {
                                // 2. If it is NOT locked, open our new Edit Dialog!
                                if (context.mounted) {
                                  _showEditBoothDialog(booth);
                                }
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
                      )),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// A simple painter to draw a grid background
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