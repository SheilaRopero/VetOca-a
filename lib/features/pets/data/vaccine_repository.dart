import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vaccine.dart';

class VaccineRepository {
  VaccineRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String petId) =>
      _db.collection('pets').doc(petId).collection('vaccines');

  Stream<List<Vaccine>> watch(String petId) {
    return _col(petId).snapshots().map((snap) {
      final list = snap.docs.map(Vaccine.fromDoc).toList();
      // Por fecha de próxima dosis; las que no tienen fecha van al final.
      list.sort((a, b) {
        final x = a.nextDueAt;
        final y = b.nextDueAt;
        if (x == null && y == null) return 0;
        if (x == null) return 1;
        if (y == null) return -1;
        return x.compareTo(y);
      });
      return list;
    });
  }

  Future<void> add(String petId, Vaccine vaccine) =>
      _col(petId).add(vaccine.toMap());
}