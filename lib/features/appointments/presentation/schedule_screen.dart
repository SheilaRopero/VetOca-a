import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_format.dart';
import '../../clinic/data/clinic_repository.dart';
import '../../clinic/models/clinic.dart';
import '../../pets/models/pet.dart';
import '../data/appointment_repository.dart';
import '../models/appointment.dart';
import '../models/triage.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({
    super.key,
    required this.pet,
    required this.ownerName,
    this.triage,
  });

  final Pet pet;
  final String ownerName;
  final Triage? triage;

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final _clinics = ClinicRepository();
  final _appointments = AppointmentRepository();
  final _streams = <String, Stream<Set<String>>>{};
  late final Stream<List<Clinic>> _clinicStream = _clinics.watchAll();

  static const _times = [(15, 30), (16, 0), (16, 30), (17, 0), (17, 30), (18, 0)];

  late final List<DateTime> _days;
  late DateTime _day;
  String? _clinicId;
  DateTime? _slot;
  AppointmentMode _mode = AppointmentMode.video;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _days = List.generate(5, (i) => today.add(Duration(days: i)));
    _day = _days.first;
  }

  Future<void> _confirm(Clinic clinic) async {
    final slot = _slot;
    if (slot == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _appointments.book(
        Appointment(
          id: '',
          petId: widget.pet.id,
          ownerId: widget.pet.ownerId,
          clinicId: clinic.id,
          dateTime: slot,
          mode: _mode,
          status: AppointmentStatus.scheduled,
          price: clinic.consultPrice,
          petName: widget.pet.name,
          petInfo: widget.pet.breed.isNotEmpty
              ? widget.pet.breed
              : widget.pet.species.label,
          ownerName: widget.ownerName,
          clinicName: clinic.name,
          triage: widget.triage?.toMap(),
        ),
        shareHistoryWithClinic: widget.pet.shareHistory,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Cita confirmada')));
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.code == 'permission-denied'
            ? 'Ese horario ya fue tomado. Elige otro.'
            : 'No se pudo confirmar la cita (${e.code}).';
        _slot = null;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo confirmar la cita.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _pickClinic(List<Clinic> clinics) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final c in clinics)
              ListTile(
                title: Text(c.name),
                subtitle: Text(c.address),
                onTap: () {
                  setState(() {
                    _clinicId = c.id;
                    _slot = null;
                  });
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agenda tu cita')),
      body: StreamBuilder<List<Clinic>>(
        stream: _clinicStream,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('No se pudieron cargar las clínicas.\n\n${snap.error}'),
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final clinics = snap.data!;
          if (clinics.isEmpty) {
            return const Center(child: Text('Aún no hay clínicas registradas.'));
          }
          final clinic = clinics.firstWhere(
                (c) => c.id == _clinicId,
            orElse: () => clinics.first,
          );
          return _body(clinic, clinics);
        },
      ),
    );
  }

  Widget _body(Clinic clinic, List<Clinic> clinics) {
    final slotsStream = _streams.putIfAbsent(
      '${clinic.id}|${dayKey(_day)}',
          () => _appointments.watchTakenSlots(clinic.id, _day),
    );

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(clinic.name,
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined,
                                      size: 14, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(clinic.address,
                                        style: const TextStyle(
                                            color: AppColors.textSecondary)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (clinics.length > 1)
                          ActionChip(
                            label: const Text('CAMBIAR'),
                            onPressed: () => _pickClinic(clinics),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  monthName(_day).toUpperCase(),
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final d in _days)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: _DayChip(
                            day: d,
                            selected: d == _day,
                            onTap: () => setState(() {
                              _day = d;
                              _slot = null;
                            }),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'CUPOS DISPONIBLES',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                StreamBuilder<Set<String>>(
                  stream: slotsStream,
                  builder: (context, snap) {
                    final taken = snap.data ?? <String>{};
                    final now = DateTime.now();
                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      childAspectRatio: 2.6,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      children: [
                        for (final t in _times)
                              () {
                            final dt = DateTime(
                                _day.year, _day.month, _day.day, t.$1, t.$2);
                            final disabled =
                                taken.contains(slotKey(dt)) || dt.isBefore(now);
                            return _SlotButton(
                              label: formatSlot(dt),
                              selected: _slot == dt,
                              disabled: disabled,
                              onTap: () => setState(() => _slot = dt),
                            );
                          }(),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    for (final m in AppointmentMode.values)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                              right: m == AppointmentMode.values.last ? 0 : 8),
                          child: _ModeButton(
                            mode: m,
                            selected: _mode == m,
                            onTap: () => setState(() => _mode = m),
                          ),
                        ),
                      ),
                  ],
                ),
                if (_slot != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Consulta de medicina interna'),
                              Text(formatCop(clinic.consultPrice),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(widget.pet.name,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary)),
                              Text(
                                '${weekdayShort(_slot!)} ${_slot!.day} · ${formatTime12(_slot!)}',
                                style: const TextStyle(
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppColors.danger)),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: ElevatedButton(
              onPressed: (_slot == null || _saving) ? null : () => _confirm(clinic),
              child: _saving
                  ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
                  : const Text('Confirmar cupo'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.day,
    required this.selected,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Column(
          children: [
            Text(
              weekdayShort(day),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlotButton extends StatelessWidget {
  const _SlotButton({
    required this.label,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: disabled ? null : onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : disabled
              ? const Color(0xFFF1F5F9)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: disabled ? TextDecoration.lineThrough : null,
            color: selected
                ? Colors.white
                : disabled
                ? AppColors.textSecondary
                : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final AppointmentMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textPrimary;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              mode == AppointmentMode.video
                  ? Icons.videocam_outlined
                  : Icons.place_outlined,
              size: 18,
              color: color,
            ),
            const SizedBox(width: 6),
            Text(mode.label,
                style: TextStyle(fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}