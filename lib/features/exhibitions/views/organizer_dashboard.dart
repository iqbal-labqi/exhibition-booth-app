import 'package:flutter/material.dart';

class OrganizerDashboard extends StatelessWidget {
  const OrganizerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Organizer Dashboard')),
      body: const Center(child: Text('Organizer tools here')),
    );
  }
}