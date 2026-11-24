import 'package:cloud_firestore/cloud_firestore.dart';
import 'species.dart';

class Pet {
  final String id;
  final String ownerId;
  final String name;
  final Species species;
  final String breed;
  final int ageYears;
  final double weightKg;
  final String? photoUrl;
  final bool shareHistory;
  final List<String> sharedWithClinics;

  const Pet({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.species,
    required this.breed,
    required this.ageYears,
    required this.weightKg,
    this.photoUrl,
    this.shareHistory = false,
    this.sharedWithClinics = const [],
  });

  factory Pet.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Pet(
      id: doc.id,
      ownerId: d['ownerId'] as String? ?? '',
      name: d['name'] as String? ?? '',
      species: Species.fromName(d['species'] as String?),
      breed: d['breed'] as String? ?? '',
      ageYears: (d['ageYears'] as num?)?.toInt() ?? 0,
      weightKg: (d['weightKg'] as num?)?.toDouble() ?? 0,
      photoUrl: d['photoUrl'] as String?,
      shareHistory: d['shareHistory'] as bool? ?? false,
      sharedWithClinics: List<String>.from(d['sharedWithClinics'] ?? const []),
    );
  }

  Map<String, dynamic> toMap() => {
    'ownerId': ownerId,
    'name': name,
    'species': species.name,
    'breed': breed,
    'ageYears': ageYears,
    'weightKg': weightKg,
    'photoUrl': photoUrl,
    'shareHistory': shareHistory,
    'sharedWithClinics': sharedWithClinics,
    'createdAt': FieldValue.serverTimestamp(),
  };
}