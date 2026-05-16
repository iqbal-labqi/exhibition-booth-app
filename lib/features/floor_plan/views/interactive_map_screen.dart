import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ADDED
import 'package:go_router/go_router.dart';
import '../models/booth_model.dart';
import '../../authentication/providers/auth_provider.dart'; // ADDED

// CHANGED TO ConsumerStatefulWidget
class InteractiveMapScreen extends ConsumerStatefulWidget {
  final String exhibitionId;
  const InteractiveMapScreen({super.key, required this.exhibitionId});

  @override
  ConsumerState<InteractiveMapScreen> createState() => _InteractiveMapScreenState();
}

class _InteractiveMapScreenState extends ConsumerState<InteractiveMapScreen> {
  // Temporary dummy booths with specific X/Y coordinates
  final List<BoothModel> _dummyBooths = [
    BoothModel(id: '1', boothNumber: 'A-01', status: 'available', price: 1500, dx: 50, dy: 100),
    BoothModel(id: '2', boothNumber: 'A-02', status: 'booked', price: 1500, dx: 150, dy: 100),
    BoothModel(id: '3', boothNumber: 'B-01', status: 'available', price: 2500, dx: 50, dy: 200),
  ];

  void _onBoothTapped(BoothModel booth) {
    if (booth.status == 'booked') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This booth is already booked.'), backgroundColor: Colors.red),
      );
      return;
    }

    // Show booking bottom sheet
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        // Read the current user inside the bottom sheet
        final user = ref.watch(currentUserProvider);

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Booth ${booth.boothNumber}', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text('Price: \$${booth.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, color: Colors.green)),
              const SizedBox(height: 24),

              // ROLE-BASED BUTTON LOGIC
              if (user == null)
                FilledButton.icon(
                  onPressed: () {
                    context.pop();
                    context.push('/login'); // Redirect Guest
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('Login to Book'),
                )
              else if (user.role == 'exhibitor')
                FilledButton(
                  onPressed: () {
                    context.pop();
                    context.push('/book/${widget.exhibitionId}/${booth.boothNumber}');
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
    return Scaffold(
      appBar: AppBar(title: const Text('Interactive Floor Plan')),
      body: Column(
        children: [
          // Legend
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

          // The Interactive Map
          Expanded(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0, // Allow users to zoom in close
              constrained: false, // Allows panning beyond screen bounds
              boundaryMargin: const EdgeInsets.all(double.infinity),
              child: Stack(
                children: [
                  // 1. The Floor Plan Background (Using a dummy grid container for now)
                  Container(
                    width: 800,
                    height: 800,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      // Simple grid pattern to simulate a blueprint
                      image: const DecorationImage(
                        image: NetworkImage('https://www.transparenttextures.com/patterns/graphy.png'),
                        repeat: ImageRepeat.repeat,
                      ),
                    ),
                    child: const Center(
                      child: Text('Exhibition Hall Map', style: TextStyle(color: Colors.grey, fontSize: 32)),
                    ),
                  ),

                  // 2. The Interactive Booths overlay
                  ..._dummyBooths.map((booth) {
                    final color = booth.status == 'available' ? Colors.green : Colors.red;
                    return Positioned(
                      left: booth.dx,
                      top: booth.dy,
                      child: GestureDetector(
                        onTap: () => _onBoothTapped(booth),
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