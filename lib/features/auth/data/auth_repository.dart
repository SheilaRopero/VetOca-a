import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';

class AuthRepository {
  AuthRepository({FirebaseAuth? auth, FirebaseFirestore? db})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Stream<User?> authChanges() => _auth.authStateChanges();

  Stream<AppUser?> profileChanges(String uid) =>
      _db.collection('users').doc(uid).snapshots().map(
            (doc) => doc.exists ? AppUser.fromDoc(doc) : null,
      );

  Future<void> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  Future<void> register({
    required String name,
    required String phone,
    required String email,
    required String password,
    UserRole role = UserRole.owner,
    String? clinicName,
    String? clinicAddress,
    int consultPrice = 45000,
    bool onDuty = false,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = cred.user!.uid;
    String? createdClinicId;

    // 1. Primero guardamos el usuario para que las reglas reconozcan isVet()
    final userRef = _db.collection('users').doc(uid);

    if (role == UserRole.vet) {
      final clinicRef = _db.collection('clinics').doc();
      createdClinicId = clinicRef.id;

      await userRef.set(AppUser(
        id: uid,
        role: UserRole.vet,
        name: name.trim(),
        phone: phone.trim(),
        clinicId: createdClinicId,
      ).toMap());

      await clinicRef.set({
        'name': (clinicName ?? '').trim().isEmpty
            ? name.trim()
            : clinicName!.trim(),
        'address': (clinicAddress ?? '').trim().isEmpty
            ? 'Ocaña, Norte de Santander'
            : clinicAddress!.trim(),
        'phone': phone.trim(),
        'onDuty': onDuty,
        'closesAt': '6:00 p. m.',
        'consultPrice': consultPrice,
      });
    } else {
      await userRef.set(AppUser(
        id: uid,
        role: UserRole.owner,
        name: name.trim(),
        phone: phone.trim(),
      ).toMap());
    }
  }

  Future<void> signOut() => _auth.signOut();
}