import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/prescription.dart';

class PrescriptionRepository {
  PrescriptionRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<String> create(Prescription p) async {
    final ref = await _db.collection('prescriptions').add(p.toMap());
    return ref.id;
  }

  Stream<Prescription?> watchOne(String id) => _db
      .collection('prescriptions')
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? Prescription.fromDoc(d) : null);
}