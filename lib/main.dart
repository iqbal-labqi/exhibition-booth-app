import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routing/app_router.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // ADD THIS

  // Initialize Firebase.
  // NOTE: If you haven't run `flutterfire configure`, this will throw an error.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print("Firebase not configured yet: $e");
  }

  runApp(
    const ProviderScope(
      child: ExhibitionApp(),
    ),
  );
}

class ExhibitionApp extends ConsumerWidget {
  const ExhibitionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the router provider
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Exhibition Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true, // Crucial for modern UI
      ),
      routerConfig: router,
    );
  }
}