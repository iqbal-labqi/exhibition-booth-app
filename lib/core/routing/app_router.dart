import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/views/admin_dashboard.dart';
import '../../features/authentication/views/login_screen.dart';
import '../../features/exhibitions/views/exhibitor_dashboard.dart';
import '../../features/exhibitions/views/guest_home_screen.dart';
import '../../features/exhibitions/views/organizer_dashboard.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/', // Start at Guest Home
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const GuestHomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/exhibitor',
        builder: (context, state) => const ExhibitorDashboard(),
      ),
      GoRoute(
        path: '/organizer',
        builder: (context, state) => const OrganizerDashboard(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboard(),
      ),
    ],
  );
});