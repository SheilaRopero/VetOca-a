import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../appointments/presentation/my_appointments_screen.dart';
import '../../appointments/presentation/triage_screen.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/models/app_user.dart';
import '../../clinic/data/clinic_repository.dart';
import '../../clinic/models/clinic.dart';
import '../../clinic/presentation/emergency_screen.dart';
import '../data/pet_repository.dart';
import '../models/pet.dart';
import 'new_pet_screen.dart';
import 'vaccines_screen.dart';

class OwnerHomeScreen extends StatelessWidget {
  OwnerHomeScreen({super.key, required this.user});

  final AppUser user;
  final _repo = PetRepository();
  final _clinics = ClinicRepository();

  void _openEmergency(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EmergencyScreen(
          ownerId: user.id,
          ownerName: user.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis mascotas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.local_hospital, color: AppColors.danger),
            tooltip: 'Urgencias 24/7',
            onPressed: () => _openEmergency(context),
          ),
          IconButton(
            icon: const Icon(Icons.event_note),
            tooltip: 'Mis citas',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MyAppointmentsScreen(ownerId: user.id),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => AuthRepository().signOut(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nueva mascota'),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NewPetScreen(ownerId: user.id),
          ),
        ),
      ),
      body: Column(
        children: [
          StreamBuilder<List<Clinic>>(
            stream: _clinics.watchAll(),
            builder: (context, clinicSnap) {
              final dutyCount =
                  (clinicSnap.data ?? const <Clinic>[]).where((c) => c.onDuty).length;
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _openEmergency(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.dangerSoft,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.danger.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.local_hospital,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Urgencias veterinarias 24/7',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.danger,
                                ),
                              ),
                              Text(
                                dutyCount == 0
                                    ? 'Ver clínicas y contacto de emergencia'
                                    : '$dutyCount ${dutyCount == 1 ? 'clínica de turno' : 'clínicas de turno'} ahora en Ocaña',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            color: AppColors.danger),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          Expanded(
            child: StreamBuilder<List<Pet>>(
              stream: _repo.watchOwnerPets(user.id),
              builder: (context, snap) {
                if (snap.hasError) {
                  return const Center(
                      child: Text('No se pudieron cargar tus mascotas.'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final pets = snap.data!;
                if (pets.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Aún no tienes mascotas registradas.\nToca "Nueva mascota" para agregar la primera.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: pets.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) =>
                      _PetCard(pet: pets[i], ownerName: user.name),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PetCard extends StatelessWidget {
  const _PetCard({required this.pet, required this.ownerName});

  final Pet pet;
  final String ownerName;

  @override
  Widget build(BuildContext context) {
    final years = pet.ageYears == 1 ? '1 año' : '${pet.ageYears} años';
    final details = [
      pet.species.label,
      if (pet.breed.isNotEmpty) pet.breed,
      years,
      '${pet.weightKg} kg',
    ].join(' · ');

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => VaccinesScreen(pet: pet)),
        ),
        leading: const CircleAvatar(
          radius: 26,
          backgroundColor: AppColors.primarySoft,
          child: Icon(Icons.pets, color: AppColors.primary),
        ),
        title: Text(pet.name,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(details),
        trailing: IconButton(
          tooltip: 'Agendar cita',
          icon: const Icon(Icons.event_available, color: AppColors.primary),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TriageScreen(pet: pet, ownerName: ownerName),
            ),
          ),
        ),
      ),
    );
  }
}