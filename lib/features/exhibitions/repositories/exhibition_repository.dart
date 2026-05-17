import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exhibition_model.dart';

final exhibitionRepositoryProvider = Provider<ExhibitionRepository>((ref) {
  return ExhibitionRepository(firestore: FirebaseFirestore.instance);
});

class ExhibitionRepository {
  final FirebaseFirestore _firestore;

  ExhibitionRepository({required FirebaseFirestore firestore}) : _firestore = firestore;

  // Stream of PUBLISHED exhibitions for Guests and Exhibitors
  Stream<List<ExhibitionModel>> getPublishedExhibitions() {
    return _firestore
        .collection('exhibitions')
        .where('isPublished', isEqualTo: true)
    // .orderBy('startDate') // NOTE: Requires a Firestore index if used with 'where'
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ExhibitionModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  // Stream of ALL exhibitions for a specific Organizer
  Stream<List<ExhibitionModel>> getOrganizerExhibitions(String organizerId) {
    return _firestore
        .collection('exhibitions')
        .where('organizerId', isEqualTo: organizerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ExhibitionModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  // ADD THIS METHOD to your existing ExhibitionRepository class
  Future<void> createExhibition(ExhibitionModel exhibition) async {
    try {
      await _firestore.collection('exhibitions').add(exhibition.toMap());
    } catch (e) {
      throw Exception('Failed to create exhibition: $e');
    }
  }
  // ADD THIS: Update an existing exhibition
  Future<void> updateExhibition(String exhibitionId, Map<String, dynamic> updatedData) async {
    try {
      await _firestore.collection('exhibitions').doc(exhibitionId).update(updatedData);
    } catch (e) {
      throw Exception('Failed to update exhibition: $e');
    }
  }
}