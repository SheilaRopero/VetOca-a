import 'package:cloud_firestore/cloud_firestore.dart';

class PrescriptionItem {
  final String name;
  final String dosage;
  final String notes;

  const PrescriptionItem({
    required this.name,
    required this.dosage,
    this.notes = '',
  });

  factory PrescriptionItem.fromMap(Map<String, dynamic> m) => PrescriptionItem(
    name: m['name'] as String? ?? '',
    dosage: m['dosage'] as String? ?? '',
    notes: m['notes'] as String? ?? '',
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'dosage': dosage,
    'notes': notes,
  };
}

class Prescription {
  final String id;
  final String appointmentId;
  final String petId;
  final String ownerId;
  final String clinicId;
  final String vetName;
  final String vetLicense;
  final String petName;
  final String petInfo;
  final List<PrescriptionItem> items;
  final String indications;
  final String folio;
  final DateTime createdAt;

  const Prescription({
    required this.id,
    required this.appointmentId,
    required this.petId,
    required this.ownerId,
    required this.clinicId,
    required this.vetName,
    this.vetLicense = 'MV · TP 18-4421',
    required this.petName,
    required this.petInfo,
    required this.items,
    this.indications = '',
    required this.folio,
    required this.createdAt,
  });

  factory Prescription.fromDoc(DocumentSnapshot doc) {
    final d = (doc.data() as Map<String, dynamic>?) ?? {};
    final rawItems = d['items'] as List<dynamic>? ?? const [];
    return Prescription(
      id: doc.id,
      appointmentId: d['appointmentId'] as String? ?? '',
      petId: d['petId'] as String? ?? '',
      ownerId: d['ownerId'] as String? ?? '',
      clinicId: d['clinicId'] as String? ?? '',
      vetName: d['vetName'] as String? ?? '',
      vetLicense: d['vetLicense'] as String? ?? 'MV · TP 18-4421',
      petName: d['petName'] as String? ?? '',
      petInfo: d['petInfo'] as String? ?? '',
      items: rawItems
          .map((e) =>
          PrescriptionItem.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      indications: d['indications'] as String? ?? '',
      folio: d['folio'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'appointmentId': appointmentId,
    'petId': petId,
    'ownerId': ownerId,
    'clinicId': clinicId,
    'vetName': vetName,
    'vetLicense': vetLicense,
    'petName': petName,
    'petInfo': petInfo,
    'items': items.map((e) => e.toMap()).toList(),
    'indications': indications,
    'folio': folio,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}