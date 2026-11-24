import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  owner,
  vet,
  admin;

  static UserRole fromName(String? name) => UserRole.values.firstWhere(
        (r) => r.name == name,
    orElse: () => UserRole.owner,
  );
}

class AppUser {
  final String id;
  final UserRole role;
  final String name;
  final String phone;
  final String? clinicId;

  const AppUser({
    required this.id,
    required this.role,
    required this.name,
    this.phone = '',
    this.clinicId,
  });

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return AppUser(
      id: doc.id,
      role: UserRole.fromName(d['role'] as String?),
      name: d['name'] as String? ?? '',
      phone: d['phone'] as String? ?? '',
      clinicId: d['clinicId'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'role': role.name,
    'name': name,
    'phone': phone,
    'clinicId': clinicId,
    'createdAt': FieldValue.serverTimestamp(),
  };
}