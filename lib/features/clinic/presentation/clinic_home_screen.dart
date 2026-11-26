import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_format.dart';
import '../../appointments/data/appointment_repository.dart';
import '../../appointments/models/appointment.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/models/app_user.dart';
import '../../chat/presentation/chat_screen.dart';
import '../data/clinic_repository.dart';

class ClinicHomeScreen extends StatefulWidget {
  const ClinicHomeScreen({super.key, required this.user});

  final AppUser user;

  @override
  State<ClinicHomeScreen> createState() => _ClinicHomeScreenState();
}

class _ClinicHomeScreenState extends State<ClinicHomeScreen> {
  final _clinics = ClinicRepository();
  final _appointments = AppointmentRepository();
  final _auth = AuthRepository();

  late DateTime _day;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _day = DateTime(now.year, now.month, now.day);
  }

  void _shiftDay(int delta) {
    setState(() => _day = _day.add(Duration(days: delta)));
  }

  String _dayHeader(DateTime d) {
    final now = DateTime.now();
    final isToday =
        d.year == now.year && d.month == now.month && d.day == now.day;
    return isToday ? 'Hoy · ${formatShortDate(d)}' : formatShortDate(d);
  }

  @override
  Widget build(BuildContext context) {
    final clinicId = widget.user.clinicId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel clínica'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () => _auth.signOut(),
          ),
        ],
      ),
      body: clinicId == null || clinicId.isEmpty
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
          : StreamBuilder(
        stream: _clinics.watchOne(clinicId),
        builder: (context, clinicSnap) {
          final clinicName = clinicSnap.data?.name ?? 'Clínica';
          final isOnDuty = clinicSnap.data?.onDuty ?? false;

          return StreamBuilder(
            stream: _appointments.watchClinicAppointments(clinicId),
            builder: (context, apptSnap) {
              final all = apptSnap.data ?? const <Appointment>[];

              bool isUrgent(Appointment a) =>
                  a.status != AppointmentStatus.completed &&
                      a.triage?['priority'] == 'high';

              final list = all
                  .where((a) =>
              a.dateTime.year == _day.year &&
                  a.dateTime.month == _day.month &&
                  a.dateTime.day == _day.day)
                  .toList()
                ..sort((a, b) {
                  final uA = isUrgent(a) ? 0 : 1;
                  final uB = isUrgent(b) ? 0 : 1;
                  if (uA != uB) return uA.compareTo(uB);
                  return a.dateTime.compareTo(b.dateTime);
                });

              final pending = list
                  .where((a) => a.status != AppointmentStatus.completed)
                  .length;
              final attended = list
                  .where((a) => a.status == AppointmentStatus.completed)
                  .length;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Hola, ${widget.user.name}',
                    style:
                    const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    clinicName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: SwitchListTile(
                      secondary: CircleAvatar(
                        backgroundColor: isOnDuty
                            ? AppColors.dangerSoft
                            : AppColors.primarySoft,
                        child: Icon(
                          Icons.local_hospital,
                          color: isOnDuty
                              ? AppColors.danger
                              : AppColors.primary,
                        ),
                      ),
                      title: const Text(
                        'Turno de urgencias 24/7',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        isOnDuty
                            ? 'Activo · visible para dueños con urgencia'
                            : 'Inactivo · solo horario regular',
                        style: const TextStyle(fontSize: 12),
                      ),
                      activeThumbColor: AppColors.danger,
                      value: isOnDuty,
                      onChanged: (val) =>
                          _clinics.setOnDuty(clinicId, val),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'CITAS HOY',
                          value: '${list.length}',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          label: 'POR ATENDER',
                          value: '$pending',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          label: 'ATENDIDAS',
                          value: '$attended',
                        ),
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
                            letterSpacing: 0.8,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => _shiftDay(-1),
                      ),
                      Text(
                        _dayHeader(_day),
                        style:
                        const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => _shiftDay(1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (apptSnap.hasError)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No se pudo cargar la agenda.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  else if (!apptSnap.hasData)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (list.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'No hay citas para este día.',
                            style:
                            TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      )
                    else
                      for (final a in list)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ClinicApptTile(
                            appointment: a,
                            onTap: () => _openDetail(a),
                          ),
                        ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _openDetail(Appointment a) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _DetailSheet(
        appointment: a,
        user: widget.user,
        onMarkAttended: () async {
          await _appointments.updateStatus(a.id, AppointmentStatus.completed);
          if (sheetContext.mounted) Navigator.pop(sheetContext);
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
        padding: const EdgeInsets.all(14),
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
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClinicApptTile extends StatelessWidget {
  const _ClinicApptTile({required this.appointment, required this.onTap});

  final Appointment appointment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final attended = a.status == AppointmentStatus.completed;
    final isVideo = a.mode == AppointmentMode.video;
    final urgent = !attended && a.triage?['priority'] == 'high';

    final accentColor = attended
        ? AppColors.success
        : (urgent ? AppColors.danger : AppColors.primary);

    return Card(
      shape: urgent
          ? RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.danger.withValues(alpha: 0.45),
          width: 1.5,
        ),
      )
          : null,
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        onTap: onTap,
        leading: SizedBox(
          width: 62,
          child: Text(
            formatTime12(a.dateTime),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: urgent ? AppColors.danger : AppColors.textSecondary,
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 3,
              height: 36,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.petInfo.isEmpty ? a.petName : '${a.petName} · ${a.petInfo}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${a.ownerName.isEmpty ? 'Propietario' : a.ownerName} · ${isVideo ? 'Video' : 'Presencial'}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: attended
                ? AppColors.successSoft
                : (urgent ? AppColors.dangerSoft : AppColors.primarySoft),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (urgent) ...[
                const Icon(Icons.priority_high,
                    size: 12, color: AppColors.danger),
                const SizedBox(width: 2),
              ],
              Text(
                attended ? 'ATENDIDA' : (urgent ? 'URGENCIA' : 'PENDIENTE'),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailSheet extends StatefulWidget {
  const _DetailSheet({
    required this.appointment,
    required this.user,
    required this.onMarkAttended,
  });

  final Appointment appointment;
  final AppUser user;
  final Future<void> Function() onMarkAttended;

  @override
  State<_DetailSheet> createState() => _DetailSheetState();
}

class _DetailSheetState extends State<_DetailSheet> {
  bool _saving = false;

  String _priorityLabel(String? raw) {
    switch (raw) {
      case 'high':
        return 'Alta (Urgente)';
      case 'medium':
        return 'Media';
      case 'low':
        return 'Baja';
      default:
        return '';
    }
  }

  Future<void> _handleMarkAttended() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.onMarkAttended();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.appointment;
    final attended = a.status == AppointmentStatus.completed;
    final t = a.triage;

    final symptomsList = (t?['symptoms'] as List?)?.cast<String>() ?? const [];
    final daysAgo = t?['startedDaysAgo'];
    final intensity = t?['intensity'];
    final priority = _priorityLabel(t?['priority'] as String?);
    final notes = (t?['notes'] as String? ?? '').trim();

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              a.petInfo.isEmpty ? a.petName : '${a.petName} · ${a.petInfo}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Propietario: ${a.ownerName.isEmpty ? 'No registrado' : a.ownerName}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            Text(
              'Hora: ${formatTime12(a.dateTime)} · ${a.mode.label}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            if (t != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'RESUMEN DE TRIAGE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.7,
                            color: AppColors.primary,
                          ),
                        ),
                        const Spacer(),
                        if (priority.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Prioridad: $priority',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (symptomsList.isNotEmpty)
                      Text(
                        'Síntomas: ${symptomsList.join(', ')}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    if (daysAgo != null || intensity != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (daysAgo != null)
                            daysAgo == 0
                                ? 'Inició hoy'
                                : 'Hace $daysAgo ${daysAgo == 1 ? 'día' : 'días'}',
                          if (intensity != null) 'Intensidad: $intensity/5',
                        ].join(' · '),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    if (notes.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Notas: $notes',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Abrir chat / Receta digital'),
              onPressed: _saving
                  ? null
                  : () {
                final nav = Navigator.of(context);
                nav.pop();
                nav.push(
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      appointment: a,
                      currentUserId: widget.user.id,
                      currentUserName: widget.user.name,
                      isVet: true,
                    ),
                  ),
                );
              },
            ),
            if (!attended) ...[
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _saving ? null : _handleMarkAttended,
                child: Text(
                  _saving ? 'Guardando...' : 'Marcar como atendida',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}