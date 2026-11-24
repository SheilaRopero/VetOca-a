import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/models/app_user.dart';
import '../data/pet_repository.dart';
import '../models/pet.dart';
import 'new_pet_screen.dart';
import 'vaccines_screen.dart';
import '../../appointments/presentation/my_appointments_screen.dart';
import '../../appointments/presentation/triage_screen.dart';

class OwnerHomeScreen extends StatelessWidget {
  OwnerHomeScreen({super.key, required this.user});

  final AppUser user;
  final _repo = PetRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis mascotas'),
        actions: [
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
      body: StreamBuilder<List<Pet>>(
        stream: _repo.watchOwnerPets(user.id),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(child: Text('No se pudieron cargar tus mascotas.'));
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