import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/application_model.dart';

final applicationRepositoryProvider = Provider<ApplicationRepository>((ref) {
  return ApplicationRepository(firestore: FirebaseFirestore.instance);
});

class ApplicationRepository {
  final FirebaseFirestore _firestore;

  ApplicationRepository({required FirebaseFirestore firestore}) : _firestore = firestore;

  // Submit a new booking application
  Future<void> submitApplication(ApplicationModel application) async {
    try {
      await _firestore.collection('applications').add(application.toMap());

      // Bonus: In a real app, you would also update the Booth status to 'pending' here!
    } catch (e) {
      throw Exception('Failed to submit application: $e');
    }
  }

  // Fetch applications for a specific exhibitor (For Wireframe 8 later)
  Stream<List<ApplicationModel>> getExhibitorApplications(String exhibitorId) {
    return _firestore
        .collection('applications')
        .where('exhibitorId', isEqualTo: exhibitorId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ApplicationModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  // Pass the current status into the method
  Future<void> cancelApplication(String applicationId, String currentStatus) async {
    try {
      // Smart Logic: Instant cancel if pending, request cancel if already approved.
      String newStatus = currentStatus == 'pending' ? 'cancelled' : 'cancel_requested';

      await _firestore.collection('applications').doc(applicationId).update({'status': newStatus});
    } catch (e) {
      throw Exception('Failed to cancel: $e');
    }
  }
// ADD THIS: Fetch applications for a specific exhibition
  Stream<List<ApplicationModel>> getApplicationsForExhibition(String exhibitionId) {
    return _firestore
        .collection('applications')
        .where('exhibitionId', isEqualTo: exhibitionId)
    // NO .orderBy() HERE! We bypass the Firebase index requirement.
        .snapshots()
        .map((snapshot) {
      // 1. Get the list normally
      final applications = snapshot.docs
          .map((doc) => ApplicationModel.fromMap(doc.data(), doc.id))
          .toList();

      // 2. Sort the list using Dart right before returning it!
      applications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return applications;
    });
  }

  // ADD THIS: General method for Organizer to approve/reject
  Future<void> updateApplicationStatus(String applicationId, String newStatus) async {
    try {
      await _firestore.collection('applications').doc(applicationId).update({'status': newStatus});

      // Note: In a real app, if status is 'approved', you would also update
      // the actual Booth status to 'booked' in the booths collection here!
    } catch (e) {
      throw Exception('Failed to update status: $e');
    }
  }
// ADD THIS NEW METHOD: Approves one, and safely rejects competitors
  Future<void> approveApplicationAndRejectOthers(ApplicationModel approvedApp) async {
    try {
      final batch = _firestore.batch();

      // 1. Approve the winning application
      final appRef = _firestore.collection('applications').doc(approvedApp.id);
      batch.update(appRef, {'status': 'approved'});

      // 2. Find all other pending applications for this specific exhibition
      final otherAppsSnapshot = await _firestore.collection('applications')
          .where('exhibitionId', isEqualTo: approvedApp.exhibitionId)
          .where('status', isEqualTo: 'pending')
          .get();

      // 3. Loop through them. If they asked for the same booth, reject them!
      for (var doc in otherAppsSnapshot.docs) {
        if (doc.id != approvedApp.id) { // Don't reject the one we just approved!
          final requestedBooths = List<String>.from(doc.data()['boothIds'] ?? []);

          // Check if any booths overlap
          final hasConflict = requestedBooths.any((b) => approvedApp.boothIds.contains(b));

          if (hasConflict) {
            // Mark them as rejected because the booth was taken
            batch.update(doc.reference, {
              'status': 'rejected',
              'rejectionReason': 'Booth ${approvedApp.boothIds.join(', ')} was awarded to another exhibitor.'
            });
          }
        }
      }

      // Commit all the changes at the exact same time
      await batch.commit();

    } catch (e) {
      throw Exception('Failed to process approval: $e');
    }
  }
  // ADD THIS: Simulates processing a payment and updating the status
  Future<void> processPayment(String applicationId) async {
    try {
      // In real life, you would call Stripe or PayPal here.
      // For this project, we just pretend it succeeds and update the database!
      await _firestore.collection('applications').doc(applicationId).update({'status': 'paid'});
    } catch (e) {
      throw Exception('Payment failed: $e');
    }
  }
  // ADD THIS: Updates an existing pending application
  Future<void> updateApplicationDetails(String applicationId, Map<String, dynamic> updatedData) async {
    try {
      await _firestore.collection('applications').doc(applicationId).update(updatedData);
    } catch (e) {
      throw Exception('Failed to update application: $e');
    }
  }
  Future<bool> hasActiveApplicationsForBooth(String exhibitionId, String boothNumber) async {
    try {
      final snapshot = await _firestore.collection('applications')
          .where('exhibitionId', isEqualTo: exhibitionId)
          .where('boothIds', arrayContains: boothNumber)
          .where('status', whereIn: ['pending', 'approved', 'paid', 'cancel_requested'])
          .limit(1) // We only need to find ONE to know it's not safe to delete!
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check booth status: $e');
    }
  }

}