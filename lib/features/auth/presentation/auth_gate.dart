import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../clinic/presentation/clinic_home_screen.dart';
import '../../pets/presentation/owner_home_screen.dart';
import '../data/auth_repository.dart';
import '../models/app_user.dart';
import 'auth_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = AuthRepository();

    return StreamBuilder<User?>(
      stream: repo.authChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const _Loading();
        }
        final firebaseUser = authSnap.data;
        if (firebaseUser == null) return const AuthScreen();

        return StreamBuilder<AppUser?>(
          stream: repo.profileChanges(firebaseUser.uid),
          builder: (context, profileSnap) {
            final profile = profileSnap.data;
            if (profile == null) {
              return _Loading(onSignOut: repo.signOut);
            }
            return switch (profile.role) {
              UserRole.owner => OwnerHomeScreen(user: profile),
              UserRole.vet || UserRole.admin => ClinicHomeScreen(user: profile),
            };
          },
        );
      },
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading({this.onSignOut});

  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (onSignOut != null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: onSignOut,
                child: const Text('Cerrar sesión'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}