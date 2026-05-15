class ExhibitionModel {
  final String id;
  final String organizerId;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final bool isPublished; // Controls visibility to guests/exhibitors
  final String? floorPlanImageUrl;

  ExhibitionModel({
    required this.id,
    required this.organizerId,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    this.isPublished = false,
    this.floorPlanImageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'organizerId': organizerId,
      'title': title,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isPublished': isPublished,
      'floorPlanImageUrl': floorPlanImageUrl,
    };
  }

  factory ExhibitionModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ExhibitionModel(
      id: documentId,
      organizerId: map['organizerId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      isPublished: map['isPublished'] ?? false,
      floorPlanImageUrl: map['floorPlanImageUrl'],
    );
  }
}