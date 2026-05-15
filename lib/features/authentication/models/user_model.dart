class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role; // 'guest', 'exhibitor', 'organizer', 'admin'
  final String? companyName; // Only for exhibitors/organizers

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.companyName,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'companyName': companyName,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'guest',
      companyName: map['companyName'],
    );
  }
}