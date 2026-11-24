import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pet.dart';

class PetRepository {
  PetRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _pets => _db.collection('pets');

  Stream<List<Pet>> watchOwnerPets(String ownerId) {
    return _pets
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snap) {
      final pets = snap.docs.map(Pet.fromDoc).toList();
      pets.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return pets;
    });
  }

  Future<void> addPet(Pet pet) => _pets.add(pet.toMap());
}