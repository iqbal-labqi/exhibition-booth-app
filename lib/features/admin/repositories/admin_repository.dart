import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminRepositoryProvider = Provider((ref) => AdminRepository(FirebaseFirestore.instance));

class AdminRepository {
  final FirebaseFirestore _firestore;
  AdminRepository(this._firestore);

  // 1. Fetch all users from the database
  Stream<List<Map<String, dynamic>>> getAllUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['uid'] = doc.id; // Inject the document ID so we know exactly who to update
        return data;
      }).toList();
    });
  }

  // 2. NEW: Update a user's Name, Role, or Suspend Status
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  // 3. We keep the hard delete just in case you ever need it in the backend!
  Future<void> deleteUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }
}