import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

// ---------------------------------------------------------
// 1. Current User Provider (Modern Syntax)
// ---------------------------------------------------------
class CurrentUserNotifier extends Notifier<UserModel?> {
  @override
  UserModel? build() {
    return null; // Initial state is null (no user logged in)
  }

  // We create a clean method to update the state so we never
  // have to call .state from outside this class!
  void setUser(UserModel? user) {
    state = user;
  }
}

final currentUserProvider = NotifierProvider<CurrentUserNotifier, UserModel?>(() {
  return CurrentUserNotifier();
});


// ---------------------------------------------------------
// 2. Auth Controller (Modern Syntax)
// ---------------------------------------------------------
class AuthController extends Notifier<bool> {
  @override
  bool build() {
    return false; // Initial state is false (not loading)
  }

  Future<void> login(String email, String password) async {
    state = true; // Set loading to true
    try {
      // ref is automatically available inside Notifier!
      final repo = ref.read(authRepositoryProvider);
      final cred = await repo.signInWithEmail(email, password);

      // Fetch user role from Firestore
      final userModel = await repo.getUserData(cred.user!.uid);

      // Update the user using our custom method
      ref.read(currentUserProvider.notifier).setUser(userModel);

    } catch (e) {
      state = false;
      throw Exception('Login failed: $e');
    }
    state = false;
  }

  // --- NEW REGISTER METHOD ---
  Future<void> register(String email, String password, String name, String role) async {
    state = true; // Set loading to true
    try {
      final repo = ref.read(authRepositoryProvider);

      // Calls the repository to create the user in Auth AND Firestore
      final newUser = await repo.signUpWithEmail(
          email: email,
          password: password,
          name: name,
          role: role
      );

      // Update the global user state
      ref.read(currentUserProvider.notifier).setUser(newUser);

    } catch (e) {
      state = false;
      throw Exception('Registration failed: $e');
    }
    state = false;
  }

  // --- EXISTING LOGOUT METHOD ---
  Future<void> logout() async {
    await ref.read(authRepositoryProvider).signOut();
    ref.read(currentUserProvider.notifier).setUser(null);
  }
}

final authControllerProvider = NotifierProvider<AuthController, bool>(() {
  return AuthController();
});