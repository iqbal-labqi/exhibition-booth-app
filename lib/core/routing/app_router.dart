import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/views/admin_dashboard.dart';
import '../../features/authentication/views/login_screen.dart';
import '../../features/exhibitions/views/exhibitor_dashboard.dart';
import '../../features/exhibitions/views/guest_home_screen.dart';
import '../../features/exhibitions/views/organizer_dashboard.dart';
import '../../features/exhibitions/views/create_exhibition_screen.dart'; // ADD IMPORT
import '../../features/authentication/views/register_screen.dart';
import '../../features/floor_plan/views/interactive_map_screen.dart';
import '../../features/applications/views/booking_form_screen.dart';
import '../../features/applications/views/success_screen.dart'; // ADD
import '../../features/applications/views/application_history_screen.dart'; // ADD
import '../../features/exhibitions/views/exhibition_management_screen.dart';
import '../../features/applications/views/payment_screen.dart';

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
        path: '/organizer/manage/:exhibitionId',
        builder: (context, state) {
          return ExhibitionManagementScreen(
            exhibitionId: state.pathParameters['exhibitionId']!,
          );
        },
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboard(),
      ),
      GoRoute(
        path: '/map/:exhibitionId',
        builder: (context, state) {
          final id = state.pathParameters['exhibitionId']!;
          return InteractiveMapScreen(exhibitionId: id);
        },
      ),
      GoRoute(
        path: '/book/:exhibitionId/:boothId',
        builder: (context, state) {
          return BookingFormScreen(
            exhibitionId: state.pathParameters['exhibitionId']!,
            boothId: state.pathParameters['boothId']!,
          );
        },
      ),
      GoRoute(
        path: '/success',
        builder: (context, state) => const SuccessScreen(),
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const ApplicationHistoryScreen(),
      ),
      GoRoute(
        path: '/pay/:applicationId',
        builder: (context, state) {
          return PaymentScreen(
            applicationId: state.pathParameters['applicationId']!,
          );
        },
      ),
    ],
  );
});