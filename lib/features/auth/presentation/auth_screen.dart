import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../data/auth_repository.dart';
import '../models/app_user.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _repo = AuthRepository();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _clinicName = TextEditingController();
  final _clinicAddress = TextEditingController();
  final _consultPrice = TextEditingController(text: '45000');
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _isLogin = true;
  bool _loading = false;
  UserRole _role = UserRole.owner;
  bool _onDuty = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _clinicName.dispose();
    _clinicAddress.dispose();
    _consultPrice.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;

    if (email.isEmpty ||
        password.isEmpty ||
        (!_isLogin && _name.text.trim().isEmpty)) {
      setState(() => _error = 'Completa los campos obligatorios.');
      return;
    }

    if (!_isLogin &&
        _role == UserRole.vet &&
        (_clinicName.text.trim().isEmpty ||
            _clinicAddress.text.trim().isEmpty)) {
      setState(() =>
      _error = 'Ingresa el nombre y la dirección de la veterinaria.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_isLogin) {
        await _repo.signIn(email, password);
      } else {
        final price = int.tryParse(
            _consultPrice.text.trim().replaceAll(RegExp(r'[^0-9]'), '')) ??
            45000;

        await _repo.register(
          name: _name.text,
          phone: _phone.text,
          email: email,
          password: password,
          role: _role,
          clinicName: _clinicName.text,
          clinicAddress: _clinicAddress.text,
          consultPrice: price,
          onDuty: _onDuty,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = _message(e.code));
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Ocurrió un error. Intenta de nuevo.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _message(String code) {
    switch (code) {
      case 'invalid-email':
        return 'El correo no es válido.';
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return 'Correo o contraseña incorrectos.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con ese correo.';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres.';
      case 'network-request-failed':
        return 'Sin conexión. Revisa tu internet.';
      default:
        return 'No se pudo completar la acción ($code).';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.pets,
                      size: 36, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'VetOcaña',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                _isLogin ? 'Inicia sesión' : 'Crea tu cuenta',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              if (!_isLogin) ...[
                Row(
                  children: [
                    Expanded(
                      child: _RoleChip(
                        label: 'Propietario',
                        icon: Icons.person_outline,
                        selected: _role == UserRole.owner,
                        onTap: () => setState(() => _role = UserRole.owner),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _RoleChip(
                        label: 'Veterinaria',
                        icon: Icons.local_hospital_outlined,
                        selected: _role == UserRole.vet,
                        onTap: () => setState(() => _role = UserRole.vet),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: _role == UserRole.owner
                        ? 'Tu nombre completo'
                        : 'Nombre del médico veterinario',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono de contacto',
                  ),
                ),
                if (_role == UserRole.vet) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _clinicName,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la veterinaria (ej. Vet Centro)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _clinicAddress,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Dirección en Ocaña (ej. Calle 11 #12-45)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _consultPrice,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Valor de consulta (COP)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: SwitchListTile(
                      value: _onDuty,
                      onChanged: (v) => setState(() => _onDuty = v),
                      title: const Text(
                        'Atención de urgencias 24/7',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: const Text('Aparecerá como clínica de turno'),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration:
                const InputDecoration(labelText: 'Correo electrónico'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white),
                )
                    : Text(_isLogin ? 'Iniciar sesión' : 'Crear cuenta'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loading
                    ? null
                    : () => setState(() {
                  _isLogin = !_isLogin;
                  _error = null;
                }),
                child: Text(_isLogin
                    ? '¿No tienes cuenta? Regístrate'
                    : '¿Ya tienes cuenta? Inicia sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textPrimary;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
      ),
    );
  }
}