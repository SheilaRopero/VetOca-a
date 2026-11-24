import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/clinic.dart';

class ClinicRepository {
  ClinicRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Stream<List<Clinic>> watchAll() => _db
      .collection('clinics')
      .snapshots()
      .map((snap) => snap.docs.map(Clinic.fromDoc).toList());

  Stream<Clinic?> watchOne(String id) => _db
      .collection('clinics')
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? Clinic.fromDoc(d) : null);
}