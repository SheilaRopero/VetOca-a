import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../appointments/presentation/triage_screen.dart';
import '../../pets/data/pet_repository.dart';
import '../../pets/models/pet.dart';
import '../data/clinic_repository.dart';
import '../models/clinic.dart';

class EmergencyScreen extends StatelessWidget {
  EmergencyScreen({
    super.key,
    required this.ownerId,
    required this.ownerName,
  });

  final String ownerId;
  final String ownerName;

  final _clinics = ClinicRepository();
  final _pets = PetRepository();

  Future<void> _startEmergencyTriage(BuildContext context) async {
    final pets = await _pets.watchOwnerPets(ownerId).first;
    if (!context.mounted) return;

    if (pets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primero registra una mascota para iniciar el triaje.'),
        ),
      );
      return;
    }

    if (pets.length == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TriageScreen(
            pet: pets.first,
            ownerName: ownerName,
            isUrgent: true,
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '¿Cuál mascota necesita atención?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              for (final p in pets)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.dangerSoft,
                      child: Icon(Icons.pets, color: AppColors.danger),
                    ),
                    title: Text(p.name,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      p.breed.isEmpty
                          ? p.species.label
                          : '${p.species.label} · ${p.breed}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TriageScreen(
                            pet: p,
                            ownerName: ownerName,
                            isUrgent: true,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Urgencias 24/7')),
      body: StreamBuilder<List<Clinic>>(
        stream: _clinics.watchAll(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(
              child: Text('No se pudieron cargar las clínicas de turno.'),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final all = snap.data!;
          final onDuty = all.where((c) => c.onDuty).toList();
          final regular = all.where((c) => !c.onDuty).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.dangerSoft,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.local_hospital,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Atención veterinaria inmediata',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.danger,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Contacta una clínica de turno en Ocaña o envía un triaje urgente.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.bolt),
                        label: const Text('Iniciar triaje urgente ahora'),
                        onPressed: () => _startEmergencyTriage(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text(
                    'CLÍNICAS DE TURNO 24/7',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.danger,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.dangerSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${onDuty.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (onDuty.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Ninguna clínica tiene activo el turno 24/7 en este momento. Puedes contactar las clínicas en horario regular abajo.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                )
              else
                for (final c in onDuty) ...[
                  _EmergencyClinicCard(
                    clinic: c,
                    onTriage: () => _startEmergencyTriage(context),
                  ),
                  const SizedBox(height: 10),
                ],
              if (regular.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text(
                  'OTRAS CLÍNICAS EN OCAÑA',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                for (final c in regular) ...[
                  _EmergencyClinicCard(
                    clinic: c,
                    onTriage: () => _startEmergencyTriage(context),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}

class _EmergencyClinicCard extends StatelessWidget {
  const _EmergencyClinicCard({
    required this.clinic,
    required this.onTriage,
  });

  final Clinic clinic;
  final VoidCallback onTriage;

  @override
  Widget build(BuildContext context) {
    final c = clinic;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    c.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: c.onDuty
                        ? AppColors.dangerSoft
                        : AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    c.onDuty
                        ? 'TURNO 24/7'
                        : (c.closesAt != null && c.closesAt!.isNotEmpty
                        ? 'Cierra ${c.closesAt}'
                        : 'HORARIO REGULAR'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: c.onDuty ? AppColors.danger : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    c.address.isEmpty ? 'Ocaña, Norte de Santander' : c.address,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            if (c.phone.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.phone_outlined,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    c.phone,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (c.phone.isNotEmpty) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copiar teléfono'),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: c.phone));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                            Text('Teléfono ${c.phone} copiado para llamar'),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      c.onDuty ? AppColors.danger : AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.medical_services_outlined, size: 18),
                    label: const Text('Agendar cita'),
                    onPressed: onTriage,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}