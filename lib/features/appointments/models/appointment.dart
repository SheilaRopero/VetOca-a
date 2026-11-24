import 'package:cloud_firestore/cloud_firestore.dart';

enum AppointmentMode {
  video('Videoconsulta'),
  inPerson('Presencial');

  const AppointmentMode(this.label);
  final String label;

  static AppointmentMode fromName(String? name) =>
      AppointmentMode.values.firstWhere(
            (m) => m.name == name,
        orElse: () => AppointmentMode.inPerson,
      );
}

enum AppointmentStatus {
  scheduled,
  completed,
  cancelled;

  static AppointmentStatus fromName(String? name) =>
      AppointmentStatus.values.firstWhere(
            (s) => s.name == name,
        orElse: () => AppointmentStatus.scheduled,
      );
}

class Appointment {
  final String id;
  final String petId;
  final String ownerId;
  final String clinicId;
  final String? vetId;
  final DateTime dateTime;
  final AppointmentMode mode;
  final AppointmentStatus status;
  final int price;
  final Map<String, dynamic>? triage;
  final String petName;
  final String petInfo;
  final String ownerName;
  final String clinicName;

  const Appointment({
    required this.id,
    required this.petId,
    required this.ownerId,
    required this.clinicId,
    this.vetId,
    required this.dateTime,
    required this.mode,
    required this.status,
    required this.price,
    this.triage,
    this.petName = '',
    this.petInfo = '',
    this.ownerName = '',
    this.clinicName = '',
  });

  factory Appointment.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Appointment(
      id: doc.id,
      petId: d['petId'] as String? ?? '',
      ownerId: d['ownerId'] as String? ?? '',
      clinicId: d['clinicId'] as String? ?? '',
      vetId: d['vetId'] as String?,
      dateTime: (d['dateTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      mode: AppointmentMode.fromName(d['mode'] as String?),
      status: AppointmentStatus.fromName(d['status'] as String?),
      price: (d['price'] as num?)?.toInt() ?? 0,
      triage: d['triage'] as Map<String, dynamic>?,
      petName: d['petName'] as String? ?? '',
      petInfo: d['petInfo'] as String? ?? '',
      ownerName: d['ownerName'] as String? ?? '',
      clinicName: d['clinicName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'petId': petId,
    'ownerId': ownerId,
    'clinicId': clinicId,
    'vetId': vetId,
    'dateTime': Timestamp.fromDate(dateTime),
    'mode': mode.name,
    'status': status.name,
    'price': price,
    'triage': triage,
    'petName': petName,
    'petInfo': petInfo,
    'ownerName': ownerName,
    'clinicName': clinicName,
    'createdAt': FieldValue.serverTimestamp(),
  };
}