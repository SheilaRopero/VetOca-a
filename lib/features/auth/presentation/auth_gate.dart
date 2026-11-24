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

    return StreamBuilder(
      stream: repo.authChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const _Splash();
        }
        final firebaseUser = authSnap.data;
        if (firebaseUser == null) {
          return const AuthScreen();
        }

        return StreamBuilder(
          stream: repo.profileChanges(firebaseUser.uid),
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const _Splash();
            }
            final appUser = userSnap.data;
            if (appUser == null) {
              return const _Splash(label: 'Preparando tu cuenta...');
            }

            return appUser.role == UserRole.vet
                ? ClinicHomeScreen(user: appUser)
                : OwnerHomeScreen(user: appUser);
          },
        );
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash({this.label});
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (label != null) ...[
              const SizedBox(height: 16),
              Text(label!),
            ],
          ],
        ),
      ),
    );
  }
}