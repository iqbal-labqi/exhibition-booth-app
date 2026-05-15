import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GuestHomeScreen extends StatelessWidget {
  const GuestHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exhibitions (Guest)')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => context.push('/login'),
          child: const Text('Go to Login'),
        ),
      ),
    );
  }
}