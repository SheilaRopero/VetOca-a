import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_format.dart';
import '../../appointments/models/appointment.dart';
import '../../prescriptions/presentation/create_prescription_sheet.dart';
import '../../prescriptions/presentation/prescription_detail_screen.dart';
import '../data/chat_repository.dart';
import '../models/chat_message.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.appointment,
    required this.currentUserId,
    required this.currentUserName,
    required this.isVet,
  });

  final Appointment appointment;
  final String currentUserId;
  final String currentUserName;
  final bool isVet;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _repo = ChatRepository();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    await _repo.sendMessage(
      widget.appointment.id,
      ChatMessage(
        id: '',
        senderId: widget.currentUserId,
        senderRole: widget.isVet ? 'vet' : 'owner',
        text: text,
        createdAt: DateTime.now(),
      ),
    );
  }

  void _openPrescriptionForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => CreatePrescriptionSheet(
        appointment: widget.appointment,
        vetName: widget.currentUserName,
        onCreated: (prescriptionId, summary) async {
          await _repo.sendMessage(
            widget.appointment.id,
            ChatMessage(
              id: '',
              senderId: widget.currentUserId,
              senderRole: 'vet',
              text:
              'Te comparto la fórmula médica para ${widget.appointment.petName}.',
              createdAt: DateTime.now(),
              prescriptionId: prescriptionId,
              prescriptionSummary: summary,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.appointment;
    final headerTitle = widget.isVet
        ? '${a.ownerName.isEmpty ? 'Propietario' : a.ownerName} (${a.petName})'
        : a.clinicName.isEmpty
        ? 'Veterinaria VetOcaña'
        : a.clinicName;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primarySoft,
              child: Icon(Icons.medical_services,
                  size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    headerTitle,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Row(
                    children: [
                      Icon(Icons.circle, size: 8, color: AppColors.success),
                      SizedBox(width: 4),
                      Text(
                        'En línea · Ocaña Norte',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.success,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (widget.isVet)
            IconButton(
              tooltip: 'Emitir receta digital',
              icon: const Icon(Icons.description_outlined,
                  color: AppColors.primary),
              onPressed: _openPrescriptionForm,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _repo.watchMessages(a.id),
              builder: (context, snap) {
                if (snap.hasError) {
                  return const Center(
                      child: Text('No se pudieron cargar los mensajes.'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snap.data!;
                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        widget.isVet
                            ? 'Inicia la consulta escribiendo un mensaje o tocando el ícono de receta arriba a la derecha.'
                            : 'Escribe aquí para comunicarte con la clínica sobre ${a.petName}.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final m = messages[i];
                    final isMe = m.senderId == widget.currentUserId;
                    return _MessageBubble(message: m, isMe: isMe);
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  if (widget.isVet)
                    IconButton(
                      icon: const Icon(Icons.medication_outlined,
                          color: AppColors.primary),
                      tooltip: 'Adjuntar receta digital',
                      onPressed: _openPrescriptionForm,
                    ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Escribe un mensaje',
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: IconButton(
                      icon:
                      const Icon(Icons.send, size: 18, color: Colors.white),
                      onPressed: _send,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMe});

  final ChatMessage message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final bg = isMe ? AppColors.primary : const Color(0xFFF1F5F9);
    final fg = isMe ? Colors.white : AppColors.textPrimary;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        constraints:
        BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.text, style: TextStyle(color: fg)),
            if (message.prescriptionId != null) ...[
              const SizedBox(height: 8),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PrescriptionDetailScreen(
                      prescriptionId: message.prescriptionId!,
                    ),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primarySoft,
                        child: Icon(Icons.medication_outlined,
                            size: 16, color: AppColors.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Receta digital',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                            if (message.prescriptionSummary != null)
                              Text(
                                message.prescriptionSummary!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                formatTime12(message.createdAt),
                style: TextStyle(
                  fontSize: 10,
                  color: isMe ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}