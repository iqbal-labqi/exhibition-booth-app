class BoothModel {
  final String id;
  final String boothNumber;
  final String status; // 'available', 'booked', 'pending'
  final double price;
  final double dx; // X Coordinate on map
  final double dy; // Y Coordinate on map

  BoothModel({
    required this.id,
    required this.boothNumber,
    required this.status,
    required this.price,
    required this.dx,
    required this.dy,
  });
}