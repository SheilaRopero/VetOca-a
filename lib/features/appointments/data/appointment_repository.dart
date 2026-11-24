import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/date_format.dart';
import '../models/appointment.dart';

class AppointmentRepository {
  AppointmentRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Ids de los cupos ya tomados ese día en esa clínica.
  Stream<Set<String>> watchTakenSlots(String clinicId, DateTime day) {
    return _db
        .collection('clinics')
        .doc(clinicId)
        .collection('slots')
        .where('day', isEqualTo: dayKey(day))
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toSet());
  }

  /// Guarda el cupo y la cita en una sola operación.
  /// Si el cupo ya existe, las reglas rechazan todo (permission-denied).
  Future<void> book(
      Appointment a, {
        bool shareHistoryWithClinic = false,
      }) async {
    final apptRef = _db.collection('appointments').doc();
    final slotRef = _db
        .collection('clinics')
        .doc(a.clinicId)
        .collection('slots')
        .doc(slotKey(a.dateTime));

    final batch = _db.batch();
    batch.set(slotRef, {
      'day': dayKey(a.dateTime),
      'ownerId': a.ownerId,
      'appointmentId': apptRef.id,
    });
    batch.set(apptRef, a.toMap());
    if (shareHistoryWithClinic) {
      batch.update(_db.collection('pets').doc(a.petId), {
        'sharedWithClinics': FieldValue.arrayUnion([a.clinicId]),
      });
    }
    await batch.commit();
  }

  /// Citas de un propietario.
  Stream<List<Appointment>> watchOwnerAppointments(String ownerId) {
    return _db
        .collection('appointments')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snap) => snap.docs.map(Appointment.fromDoc).toList());
  }

  /// Todas las citas de una clínica (el filtro por día se hace en la app).
  Stream<List<Appointment>> watchClinicAppointments(String clinicId) {
    return _db
        .collection('appointments')
        .where('clinicId', isEqualTo: clinicId)
        .snapshots()
        .map((snap) => snap.docs.map(Appointment.fromDoc).toList());
  }

  Future<void> updateStatus(String id, AppointmentStatus status) =>
      _db.collection('appointments').doc(id).update({'status': status.name});
}