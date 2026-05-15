class BoothModel {
  final String id;
  final String exhibitionId;
  final String boothNumber; // e.g., "A-12"
  final String type; // e.g., "Premium", "Standard"
  final double size; // in sqm
  final double price;
  final String status; // 'available', 'booked', 'pending'
  final double dx; // X coordinate on the interactive map
  final double dy; // Y coordinate on the interactive map

  BoothModel({
    required this.id,
    required this.exhibitionId,
    required this.boothNumber,
    required this.type,
    required this.size,
    required this.price,
    required this.status,
    required this.dx,
    required this.dy,
  });

  Map<String, dynamic> toMap() {
    return {
      'exhibitionId': exhibitionId,
      'boothNumber': boothNumber,
      'type': type,
      'size': size,
      'price': price,
      'status': status,
      'dx': dx,
      'dy': dy,
    };
  }

  factory BoothModel.fromMap(Map<String, dynamic> map, String documentId) {
    return BoothModel(
      id: documentId,
      exhibitionId: map['exhibitionId'] ?? '',
      boothNumber: map['boothNumber'] ?? '',
      type: map['type'] ?? 'Standard',
      size: (map['size'] ?? 0).toDouble(),
      price: (map['price'] ?? 0).toDouble(),
      status: map['status'] ?? 'available',
      dx: (map['dx'] ?? 0).toDouble(),
      dy: (map['dy'] ?? 0).toDouble(),
    );
  }
}