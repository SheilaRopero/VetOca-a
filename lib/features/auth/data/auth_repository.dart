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
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    // Todo registro nuevo entra como propietario (lo exigen las reglas).
    final user = AppUser(
      id: cred.user!.uid,
      role: UserRole.owner,
      name: name.trim(),
      phone: phone.trim(),
    );
    await _db.collection('users').doc(user.id).set(user.toMap());
  }

  Future<void> signOut() => _auth.signOut();
}