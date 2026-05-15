import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

// Provider to access the repository globally
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
  );
});

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository({required FirebaseAuth auth, required FirebaseFirestore firestore})
      : _auth = auth,
        _firestore = firestore;

  // Stream to listen to Firebase Auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Fetch custom UserModel from Firestore using Firebase UID
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
    return null;
  }

  // Register a new user
  Future<UserModel?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String role, // 'exhibitor', 'organizer', etc.
  }) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      UserModel newUser = UserModel(
        uid: cred.user!.uid,
        email: email,
        name: name,
        role: role,
      );

      // Save additional user info (like role) to Firestore
      await _firestore.collection('users').doc(newUser.uid).set(newUser.toMap());
      return newUser;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Login existing user
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}