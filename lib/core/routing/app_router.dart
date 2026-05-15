import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/views/admin_dashboard.dart';
import '../../features/authentication/views/login_screen.dart';
import '../../features/exhibitions/views/exhibitor_dashboard.dart';
import '../../features/exhibitions/views/guest_home_screen.dart';
import '../../features/exhibitions/views/organizer_dashboard.dart';
import '../../features/exhibitions/views/create_exhibition_screen.dart'; // ADD IMPORT
import '../../features/authentication/views/register_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    // We change THIS to start directly on the organizer screen
    initialLocation: '/',
    debugLogDiagnostics: true, // <--- ADD THIS
    routes: [
      GoRoute(
        // This MUST stay as '/'
        path: '/',
        builder: (context, state) => const GuestHomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(               // ADD THIS NEW ROUTE
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/exhibitor',
        builder: (context, state) => const ExhibitorDashboard(),
      ),
      GoRoute(
        path: '/organizer',
        builder: (context, state) => const OrganizerDashboard(),
      ),
      GoRoute(               // ADD THIS NEW ROUTE
        path: '/organizer/create',
        builder: (context, state) => const CreateExhibitionScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboard(),
      ),
    ],
  );
});