import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booth_model.dart';

final boothRepositoryProvider = Provider((ref) => BoothRepository(FirebaseFirestore.instance));

class BoothRepository {
  final FirebaseFirestore _firestore;
  BoothRepository(this._firestore);

  // Save the entire floor plan to Firebase
  Future<void> saveFloorPlan(String exhibitionId, List<BoothModel> booths) async {
    final batch = _firestore.batch();
    final collection = _firestore.collection('exhibitions').doc(exhibitionId).collection('booths');

    // First, clear out the old layout
    final existingBooths = await collection.get();
    for (var doc in existingBooths.docs) {
      batch.delete(doc.reference);
    }

    // Then, save all the newly placed booths
    for (var booth in booths) {
      final docRef = collection.doc();
      batch.set(docRef, booth.toMap());
    }

    await batch.commit();
  }

  // Fetch the live booths for the interactive map
  Stream<List<BoothModel>> getBoothsForExhibition(String exhibitionId) {
    return _firestore.collection('exhibitions').doc(exhibitionId).collection('booths').snapshots()
        .map((snap) => snap.docs.map((doc) => BoothModel.fromMap(doc.data(), doc.id)).toList());
  }
}