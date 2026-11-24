import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_format.dart';
import '../../chat/presentation/chat_screen.dart';
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
      body: StreamBuilder(
        stream: _repo.watchOwnerAppointments(ownerId),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(
              child: Text('No se pudieron cargar tus citas.'),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data ?? const <Appointment>[];
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Aún no tienes citas agendadas.\nEntra a una mascota y toca "Agendar cita".',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _AppointmentCard(appointment: items[i]),
          );
        },
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final attended = a.status == AppointmentStatus.completed;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              appointment: a,
              currentUserId: a.ownerId,
              currentUserName: a.ownerName,
              isVet: false,
            ),
          ),
        ),
        leading: CircleAvatar(
          backgroundColor: AppColors.primarySoft,
          child: Icon(
            a.mode == AppointmentMode.video
                ? Icons.videocam_outlined
                : Icons.location_on_outlined,
            color: AppColors.primary,
          ),
        ),
        title: Text(
          '${a.petName} · ${a.clinicName}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${formatShortDate(a.dateTime)} · ${formatTime12(a.dateTime)}',
            ),
            const SizedBox(height: 4),
            const Text(
              'Toca para abrir chat y ver recetas',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: attended ? AppColors.successSoft : AppColors.primarySoft,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            attended ? 'ATENDIDA' : 'PENDIENTE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: attended ? AppColors.success : AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}