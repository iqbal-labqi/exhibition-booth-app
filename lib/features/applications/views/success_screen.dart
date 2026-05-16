import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 100, color: Colors.green),
              const SizedBox(height: 24),
              Text('Application Submitted!', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text(
                'Your booth application has been sent to the organizer. You can track its status in your Application History.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              FilledButton(
                onPressed: () => context.go('/history'), // We will build this next!
                child: const Text('View Application History'),
              ),
              TextButton(
                onPressed: () => context.go('/exhibitor'),
                child: const Text('Back to Home'),
              )
            ],
          ),
        ),
      ),
    );
  }
}