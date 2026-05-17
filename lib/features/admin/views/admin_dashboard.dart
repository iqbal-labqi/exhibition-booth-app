import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../authentication/providers/auth_provider.dart';
import 'user_management_screen.dart';
import 'admin_exhibition_screen.dart';
import 'admin_reservations_screen.dart';
import 'admin_overview_screen.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  int _selectedIndex = 0;

  // We will build these sub-screens in the next steps!
  final List<Widget> _pages = [
    const AdminOverviewScreen(), // <-- Dashboard added!
    const UserManagementScreen(), // <-- NEW SCREEN ADDED HERE!
    const AdminExhibitionScreen(), // <-- NEW SCREEN ADDED!
    const AdminReservationsScreen(), // <-- THE FINAL SCREEN!
  ];

  final List<String> _titles = [
    'System Overview',
    'Manage Users',
    'All Exhibitions',
    'Master Reservations'
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex], style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple, // Distinct color for Admin!
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: const Text('System Administrator', style: TextStyle(fontWeight: FontWeight.bold)),
              accountEmail: Text(user?.email ?? 'admin@system.com'),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.security, size: 40, color: Colors.deepPurple),
              ),
              decoration: const BoxDecoration(color: Colors.deepPurple),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Overview'),
              selected: _selectedIndex == 0,
              selectedColor: Colors.deepPurple,
              onTap: () {
                setState(() => _selectedIndex = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Manage Users'),
              selected: _selectedIndex == 1,
              selectedColor: Colors.deepPurple,
              onTap: () {
                setState(() => _selectedIndex = 1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.business),
              title: const Text('Exhibitions'),
              selected: _selectedIndex == 2,
              selectedColor: Colors.deepPurple,
              onTap: () {
                setState(() => _selectedIndex = 2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.book_online),
              title: const Text('Reservations'),
              selected: _selectedIndex == 3,
              selectedColor: Colors.deepPurple,
              onTap: () {
                setState(() => _selectedIndex = 3);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await ref.read(authControllerProvider.notifier).logout();
                if (context.mounted) context.go('/');
              },
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
    );
  }
}