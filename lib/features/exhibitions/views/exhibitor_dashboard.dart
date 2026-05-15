import 'package:flutter/material.dart';

class ExhibitorDashboard extends StatelessWidget {
  const ExhibitorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exhibitor Dashboard')),
      body: const Center(child: Text('Exhibitor tools here')),
    );
  }
}