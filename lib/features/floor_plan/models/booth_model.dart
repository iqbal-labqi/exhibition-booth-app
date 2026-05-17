class BoothModel {
  final String id;
  final String boothNumber;
  final double price;
  final double dx; // X Coordinate
  final double dy; // Y Coordinate

  BoothModel({
    required this.id,
    required this.boothNumber,
    required this.price,
    required this.dx,
    required this.dy,
  });

  Map<String, dynamic> toMap() {
    return {
      'boothNumber': boothNumber,
      'price': price,
      'dx': dx,
      'dy': dy,
    };
  }

  factory BoothModel.fromMap(Map<String, dynamic> map, String id) {
    return BoothModel(
      id: id,
      boothNumber: map['boothNumber'] ?? '',
      price: map['price']?.toDouble() ?? 1500.0,
      dx: map['dx']?.toDouble() ?? 0.0,
      dy: map['dy']?.toDouble() ?? 0.0,
    );
  }
}