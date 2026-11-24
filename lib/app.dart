import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_gate.dart';

class VetOcanaApp extends StatelessWidget {
  const VetOcanaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VetOcaña',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AuthGate(),
    );
  }
}