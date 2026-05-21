import 'package:cloud_firestore/cloud_firestore.dart';

class ApplicationModel {
  final String id;
  final String exhibitorId;
  final String exhibitorName;
  final String exhibitionId;
  final String exhibitionTitle;
  final List<String> boothIds;
  final String companyName;
  final String companyDesc;
  final String exhibitProfile;
  final List<String> addOns;
  final String status;
  final double amount;
  final DateTime createdAt;

  ApplicationModel({
    required this.id,
    required this.exhibitorId,
    required this.exhibitorName,
    required this.exhibitionId,
    required this.exhibitionTitle,
    required this.boothIds,
    required this.companyName,
    required this.companyDesc,
    required this.exhibitProfile,
    required this.addOns,
    required this.status,
    required this.amount,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'exhibitorId': exhibitorId,
      'exhibitorName': exhibitorName,
      'exhibitionId': exhibitionId,
      'exhibitionTitle': exhibitionTitle,
      'boothIds': boothIds,
      'companyName': companyName,
      'companyDesc': companyDesc,
      'exhibitProfile': exhibitProfile,
      'addOns': addOns,
      'status': status,
      'amount': amount,
      'createdAt': Timestamp.fromDate(createdAt), // Always saves as Timestamp moving forward
    };
  }

  factory ApplicationModel.fromMap(Map<String, dynamic> map, String documentId) {
    // --- THE FIX: Safely parse old Strings AND new Timestamps! ---
    DateTime parsedDate = DateTime.now();
    if (map['createdAt'] != null) {
      if (map['createdAt'] is Timestamp) {
        parsedDate = (map['createdAt'] as Timestamp).toDate(); // Handle proper Timestamps
      } else if (map['createdAt'] is String) {
        parsedDate = DateTime.tryParse(map['createdAt']) ?? DateTime.now(); // Handle old String data
      }
    }

    return ApplicationModel(
      id: documentId,
      exhibitorId: map['exhibitorId'] ?? '',
      exhibitorName: map['exhibitorName'] ?? 'Unknown',
      exhibitionId: map['exhibitionId'] ?? '',
      exhibitionTitle: map['exhibitionTitle'] ?? '',
      boothIds: List<String>.from(map['boothIds'] ?? []),
      companyName: map['companyName'] ?? '',
      companyDesc: map['companyDesc'] ?? '',
      exhibitProfile: map['exhibitProfile'] ?? '',
      addOns: List<String>.from(map['addOns'] ?? []),
      status: map['status'] ?? 'pending',
      amount: (map['amount'] ?? 1500.0).toDouble(),
      createdAt: parsedDate, // <-- Use the safely parsed date here!
    );
  }
}