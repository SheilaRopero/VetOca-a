import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_format.dart';
import '../../appointments/data/appointment_repository.dart';
import '../../appointments/models/appointment.dart';
import '../../appointments/models/triage.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/models/app_user.dart';
import '../data/clinic_repository.dart';
import '../models/clinic.dart';

class ClinicHomeScreen extends StatefulWidget {
  const ClinicHomeScreen({super.key, required this.user});

  final AppUser user;

  @override
  State<ClinicHomeScreen> createState() => _ClinicHomeScreenState();
}

class _ClinicHomeScreenState extends State<ClinicHomeScreen> {
  final _appointments = AppointmentRepository();
  final _clinics = ClinicRepository();
  Stream<List<Appointment>>? _apptStream;
  Stream<Clinic?>? _clinicStream;
  late DateTime _day;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _day = DateTime(now.year, now.month, now.day);
    final clinicId = widget.user.clinicId;
    if (clinicId != null && clinicId.isNotEmpty) {
      _apptStream = _appointments.watchClinicAppointments(clinicId);
      _clinicStream = _clinics.watchOne(clinicId);
    }
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool get _isToday => _sameDay(_day, DateTime.now());

  void _shiftDay(int delta) =>
      setState(() => _day = _day.add(Duration(days: delta)));

  void _openDetail(Appointment a) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _DetailSheet(
        appointment: a,
        onComplete: () async {
          try {
            await _appointments.updateStatus(a.id, AppointmentStatus.completed);
          } catch (_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No se pudo actualizar la cita.')),
              );
            }
          }
          if (sheetContext.mounted) Navigator.pop(sheetContext);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel clínica'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => AuthRepository().signOut(),
          ),
        ],
      ),
      body: _apptStream == null
          ? const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Tu cuenta aún no tiene una clínica asignada.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      )
          : StreamBuilder<List<Appointment>>(
        stream: _apptStream,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('No se pudo cargar la agenda.\n\n${snap.error}'),
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final day = snap.data!
              .where((a) => _sameDay(a.dateTime, _day))
              .toList()
            ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
          final pending = day
              .where((a) => a.status == AppointmentStatus.scheduled)
              .length;
          final done = day
              .where((a) => a.status == AppointmentStatus.completed)
              .length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              StreamBuilder<Clinic?>(
                stream: _clinicStream,
                builder: (context, cs) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hola, ${widget.user.name}',
                      style: const TextStyle(
                          color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cs.data?.name ?? 'Tu clínica',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: _isToday ? 'CITAS HOY' : 'CITAS DEL DÍA',
                      value: '${day.length}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(label: 'POR ATENDER', value: '$pending'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(label: 'ATENDIDAS', value: '$done'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'AGENDA DEL DÍA',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => _shiftDay(-1),
                  ),
                  Text(
                    '${_isToday ? 'Hoy · ' : ''}${weekdayShort(_day)} ${_day.day} ${monthName(_day)}',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => _shiftDay(1),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (day.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    'No hay citas para este día.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              else
                for (final a in day)
                  _AppointmentRow(
                    appointment: a,
                    onTap: () => _openDetail(a),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentRow extends StatelessWidget {
  const _AppointmentRow({required this.appointment, required this.onTap});

  final Appointment appointment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final title = a.petInfo.isEmpty ? a.petName : '${a.petName} · ${a.petInfo}';
    final modeShort = a.mode == AppointmentMode.video ? 'Video' : 'Presencial';
    final isHigh = a.triage?['priority'] == 'high';

    final (label, bg, fg, bar) = switch (a.status) {
      AppointmentStatus.scheduled =>
      ('PENDIENTE', AppColors.primarySoft, AppColors.primary, AppColors.primary),
      AppointmentStatus.completed =>
      ('HECHA', const Color(0xFFF1F5F9), AppColors.textSecondary, const Color(0xFFCBD5E1)),
      AppointmentStatus.cancelled =>
      ('CANCELADA', AppColors.dangerSoft, AppColors.danger, AppColors.danger),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  child: Text(
                    formatSlot(a.dateTime),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary),
                  ),
                ),
                Container(
                  width: 3,
                  height: 38,
                  decoration: BoxDecoration(
                    color: bar,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title.isEmpty ? 'Mascota' : title,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(
                        '${a.ownerName.isEmpty ? 'Propietario' : a.ownerName} · $modeShort',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (isHigh)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(Icons.priority_high,
                        size: 18, color: AppColors.danger),
                  ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                        color: fg, fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailSheet extends StatefulWidget {
  const _DetailSheet({required this.appointment, required this.onComplete});

  final Appointment appointment;
  final Future<void> Function() onComplete;

  @override
  State<_DetailSheet> createState() => _DetailSheetState();
}

class _DetailSheetState extends State<_DetailSheet> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.appointment;
    final d = a.dateTime;
    final t = a.triage == null ? null : Triage.fromMap(a.triage!);
    final title = a.petInfo.isEmpty ? a.petName : '${a.petName} · ${a.petInfo}';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.isEmpty ? 'Mascota' : title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            '${a.ownerName.isEmpty ? 'Propietario' : a.ownerName} · ${a.mode.label}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          Text(
            '${weekdayShort(d)} ${d.day} · ${formatTime12(d)} · ${formatCop(a.price)}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          if (t == null)
            const Text('Sin triaje previo.',
                style: TextStyle(color: AppColors.textSecondary))
          else ...[
            _PriorityBanner(priority: t.priority),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [for (final s in t.symptoms) Chip(label: Text(s))],
            ),
            const SizedBox(height: 8),
            Text(
              'Intensidad: ${t.intensityLabel} · Empezó ${_ago(t.startedDaysAgo)}',
            ),
            if (t.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'NOTAS DEL PROPIETARIO',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(t.notes),
            ],
          ],
          const SizedBox(height: 20),
          if (a.status == AppointmentStatus.scheduled)
            ElevatedButton(
              onPressed: _busy
                  ? null
                  : () async {
                setState(() => _busy = true);
                await widget.onComplete();
              },
              child: const Text('Marcar como atendida'),
            ),
        ],
      ),
    );
  }

  String _ago(int days) =>
      days == 0 ? 'hoy' : days == 1 ? 'hace 1 día' : 'hace $days días';
}

class _PriorityBanner extends StatelessWidget {
  const _PriorityBanner({required this.priority});

  final TriagePriority priority;

  @override
  Widget build(BuildContext context) {
    final (text, bg, fg) = switch (priority) {
      TriagePriority.low =>
      ('Prioridad baja', AppColors.successSoft, AppColors.success),
      TriagePriority.medium =>
      ('Prioridad media', AppColors.primarySoft, AppColors.primary),
      TriagePriority.high =>
      ('Prioridad alta', AppColors.dangerSoft, AppColors.danger),
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.medical_services_outlined, size: 20, color: fg),
          const SizedBox(width: 10),
          Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}