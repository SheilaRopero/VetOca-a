import 'package:cloud_firestore/cloud_firestore.dart';

enum VaccineStatus { upToDate, upcoming, overdue }

class Vaccine {
  final String id;
  final String name;
  final DateTime? appliedAt;
  final DateTime? nextDueAt;
  final int reminderDaysBefore;

  const Vaccine({
    required this.id,
    required this.name,
    this.appliedAt,
    this.nextDueAt,
    this.reminderDaysBefore = 2,
  });

  /// Se calcula al vuelo, nunca se guarda.
  VaccineStatus get status {
    final due = nextDueAt;
    if (due == null) return VaccineStatus.upToDate;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (due.isBefore(today)) return VaccineStatus.overdue;
    if (due.difference(today).inDays <= 30) return VaccineStatus.upcoming;
    return VaccineStatus.upToDate;
  }

  factory Vaccine.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Vaccine(
      id: doc.id,
      name: d['name'] as String? ?? '',
      appliedAt: (d['appliedAt'] as Timestamp?)?.toDate(),
      nextDueAt: (d['nextDueAt'] as Timestamp?)?.toDate(),
      reminderDaysBefore: (d['reminderDaysBefore'] as num?)?.toInt() ?? 2,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'appliedAt': appliedAt == null ? null : Timestamp.fromDate(appliedAt!),
    'nextDueAt': nextDueAt == null ? null : Timestamp.fromDate(nextDueAt!),
    'reminderDaysBefore': reminderDaysBefore,
  };
}