class ApplicationModel {
  final String id;
  final String exhibitorId;
  final String exhibitionId;
  final List<String> boothIds; // Can select multiple booths
  final String status; // 'pending', 'approved', 'rejected', 'cancelled'
  final String companyName;
  final String companyDesc;
  final String exhibitProfile; // What they plan to showcase
  final List<String> addOns; // e.g., ['Extra Wifi', 'Furniture']
  final DateTime createdAt;

  ApplicationModel({
    required this.id,
    required this.exhibitorId,
    required this.exhibitionId,
    required this.boothIds,
    required this.status,
    required this.companyName,
    required this.companyDesc,
    required this.exhibitProfile,
    required this.addOns,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'exhibitorId': exhibitorId,
      'exhibitionId': exhibitionId,
      'boothIds': boothIds,
      'status': status,
      'companyName': companyName,
      'companyDesc': companyDesc,
      'exhibitProfile': exhibitProfile,
      'addOns': addOns,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ApplicationModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ApplicationModel(
      id: documentId,
      exhibitorId: map['exhibitorId'] ?? '',
      exhibitionId: map['exhibitionId'] ?? '',
      boothIds: List<String>.from(map['boothIds'] ?? []),
      status: map['status'] ?? 'pending',
      companyName: map['companyName'] ?? '',
      companyDesc: map['companyDesc'] ?? '',
      exhibitProfile: map['exhibitProfile'] ?? '',
      addOns: List<String>.from(map['addOns'] ?? []),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}