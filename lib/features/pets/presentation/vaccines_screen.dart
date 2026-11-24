import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_format.dart';
import '../data/vaccine_repository.dart';
import '../models/pet.dart';
import '../models/vaccine.dart';

class VaccinesScreen extends StatelessWidget {
  VaccinesScreen({super.key, required this.pet});

  final Pet pet;
  final _repo = VaccineRepository();

  void _openAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _AddVaccineSheet(petId: pet.id, repo: _repo),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vacunas y alertas')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Agregar vacuna'),
        onPressed: () => _openAddSheet(context),
      ),
      body: StreamBuilder<List<Vaccine>>(
        stream: _repo.watch(pet.id),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(child: Text('No se pudo cargar el carné.'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final vaccines = snap.data!;
          final pending =
              vaccines.where((v) => v.status != VaccineStatus.upToDate).length;
          final today = DateTime.now();
          final startOfToday = DateTime(today.year, today.month, today.day);
          // La lista ya viene ordenada por fecha: la primera futura es la próxima.
          final next = vaccines
              .where((v) =>
          v.nextDueAt != null && !v.nextDueAt!.isBefore(startOfToday))
              .firstOrNull;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              _PetHeader(pet: pet, pending: pending),
              const SizedBox(height: 12),
              _NextBooster(vaccine: next),
              const SizedBox(height: 20),
              const Text(
                'CARNÉ DE VACUNAS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              if (vaccines.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Aún no hay vacunas registradas.\nToca "Agregar vacuna" para empezar el carné.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              else
                for (final v in vaccines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _VaccineTile(vaccine: v),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _PetHeader extends StatelessWidget {
  const _PetHeader({required this.pet, required this.pending});

  final Pet pet;
  final int pending;

  @override
  Widget build(BuildContext context) {
    final subtitle = pending == 0
        ? 'Todo al día'
        : pending == 1
        ? '1 refuerzo pendiente'
        : '$pending refuerzos pendientes';
    final title = pet.breed.isEmpty ? pet.name : '${pet.name} · ${pet.breed}';

    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.primarySoft,
          child: Icon(Icons.pets, color: AppColors.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class _NextBooster extends StatelessWidget {
  const _NextBooster({required this.vaccine});

  final Vaccine? vaccine;

  @override
  Widget build(BuildContext context) {
    final v = vaccine;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: v == null
          ? const Text(
        'Sin refuerzos próximos',
        style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700),
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'PRÓXIMO REFUERZO',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            formatLongDate(v.nextDueAt!),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            '${v.name} · ${_inDays(daysUntil(v.nextDueAt!))}',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  String _inDays(int d) {
    if (d == 0) return 'hoy';
    if (d == 1) return 'mañana';
    return 'en $d días';
  }
}

class _VaccineTile extends StatelessWidget {
  const _VaccineTile({required this.vaccine});

  final Vaccine vaccine;

  @override
  Widget build(BuildContext context) {
    final parts = [
      if (vaccine.appliedAt != null)
        'Aplicada ${formatShortDate(vaccine.appliedAt!)}',
      if (vaccine.nextDueAt != null)
        'Próxima ${formatShortDate(vaccine.nextDueAt!)}',
    ];

    final (label, bg, fg) = switch (vaccine.status) {
      VaccineStatus.upToDate => ('AL DÍA', AppColors.successSoft, AppColors.success),
      VaccineStatus.upcoming => ('PRÓXIMA', AppColors.primarySoft, AppColors.primary),
      VaccineStatus.overdue => ('VENCIDA', AppColors.dangerSoft, AppColors.danger),
    };

    return Card(
      child: ListTile(
        leading: const Icon(Icons.vaccines, color: AppColors.textSecondary),
        title: Text(vaccine.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(parts.join(' · ')),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
                color: fg, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _AddVaccineSheet extends StatefulWidget {
  const _AddVaccineSheet({required this.petId, required this.repo});

  final String petId;
  final VaccineRepository repo;

  @override
  State<_AddVaccineSheet> createState() => _AddVaccineSheetState();
}

class _AddVaccineSheetState extends State<_AddVaccineSheet> {
  final _name = TextEditingController();
  DateTime? _applied;
  DateTime? _next;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool applied}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (applied ? _applied : _next) ?? now,
      firstDate: DateTime(2000),
      lastDate: applied ? now : DateTime(2100),
    );
    if (picked == null) return;
    setState(() => applied ? _applied = picked : _next = picked);
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || (_applied == null && _next == null)) {
      setState(() =>
      _error = 'Escribe el nombre y elige al menos una fecha.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repo.add(
        widget.petId,
        Vaccine(
          id: '',
          name: _name.text.trim(),
          appliedAt: _applied,
          nextDueAt: _next,
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudo guardar. Intenta de nuevo.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Agregar vacuna',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
                labelText: 'Nombre (ej. Rabia, Polivalente)'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48)),
            icon: const Icon(Icons.event_available),
            label: Text(_applied == null
                ? 'Fecha de aplicación'
                : 'Aplicada: ${formatShortDate(_applied!)}'),
            onPressed: () => _pickDate(applied: true),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48)),
            icon: const Icon(Icons.event_repeat),
            label: Text(_next == null
                ? 'Fecha del próximo refuerzo'
                : 'Próxima: ${formatShortDate(_next!)}'),
            onPressed: () => _pickDate(applied: false),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: AppColors.danger)),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: Colors.white),
            )
                : const Text('Guardar vacuna'),
          ),
        ],
      ),
    );
  }
}