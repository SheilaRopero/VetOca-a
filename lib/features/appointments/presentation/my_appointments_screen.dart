import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_format.dart';
import '../data/appointment_repository.dart';
import '../models/appointment.dart';

class MyAppointmentsScreen extends StatelessWidget {
  MyAppointmentsScreen({super.key, required this.ownerId});

  final String ownerId;
  final _repo = AppointmentRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis citas')),
      body: StreamBuilder<List<Appointment>>(
        stream: _repo.watchOwnerAppointments(ownerId),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(child: Text('No se pudieron cargar tus citas.'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snap.data!;
          final limit = DateTime.now().subtract(const Duration(hours: 1));
          final upcoming = all
              .where((a) =>
          a.status == AppointmentStatus.scheduled &&
              a.dateTime.isAfter(limit))
              .toList()
            ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
          final past = all.where((a) => !upcoming.contains(a)).toList()
            ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

          if (all.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Aún no tienes citas.\nAgéndalas con el ícono de calendario en la tarjeta de tu mascota.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (upcoming.isNotEmpty) ...[
                const _SectionTitle('PRÓXIMAS'),
                for (final a in upcoming) _AppointmentCard(a),
              ],
              if (past.isNotEmpty) ...[
                const SizedBox(height: 12),
                const _SectionTitle('ANTERIORES'),
                for (final a in past) _AppointmentCard(a),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard(this.a);

  final Appointment a;

  @override
  Widget build(BuildContext context) {
    final d = a.dateTime;
    final when = '${weekdayShort(d)} ${d.day} ${formatShortDate(d).split(' ')[1]} · ${formatTime12(d)}';
    final isVideo = a.mode == AppointmentMode.video;

    final status = switch (a.status) {
      AppointmentStatus.completed => 'COMPLETADA',
      AppointmentStatus.cancelled => 'CANCELADA',
      AppointmentStatus.scheduled => null,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.all(14),
          leading: CircleAvatar(
            backgroundColor: AppColors.primarySoft,
            child: Icon(
              isVideo ? Icons.videocam_outlined : Icons.place_outlined,
              color: AppColors.primary,
            ),
          ),
          title: Text(
            a.petName.isEmpty ? 'Mascota' : a.petName,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            [
              when,
              if (a.clinicName.isNotEmpty) a.clinicName,
              a.mode.label,
            ].join('\n'),
          ),
          isThreeLine: true,
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatCop(a.price),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              if (status != null)
                Text(status,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}