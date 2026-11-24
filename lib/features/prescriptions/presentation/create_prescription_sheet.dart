import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../appointments/models/appointment.dart';
import '../data/prescription_repository.dart';
import '../models/prescription.dart';

class CreatePrescriptionSheet extends StatefulWidget {
  const CreatePrescriptionSheet({
    super.key,
    required this.appointment,
    required this.vetName,
    required this.onCreated,
  });

  final Appointment appointment;
  final String vetName;
  final void Function(String prescriptionId, String summary) onCreated;

  @override
  State<CreatePrescriptionSheet> createState() =>
      _CreatePrescriptionSheetState();
}

class _CreatePrescriptionSheetState extends State<CreatePrescriptionSheet> {
  final _repo = PrescriptionRepository();
  final _medName = TextEditingController();
  final _dosage = TextEditingController();
  final _medNotes = TextEditingController();
  final _indications = TextEditingController();
  final List<PrescriptionItem> _items = [];
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _medName.dispose();
    _dosage.dispose();
    _medNotes.dispose();
    _indications.dispose();
    super.dispose();
  }

  void _addItem() {
    if (_medName.text.trim().isEmpty || _dosage.text.trim().isEmpty) {
      setState(() => _error = 'Escribe el medicamento y su dosis/frecuencia.');
      return;
    }
    setState(() {
      _items.add(PrescriptionItem(
        name: _medName.text.trim(),
        dosage: _dosage.text.trim(),
        notes: _medNotes.text.trim(),
      ));
      _medName.clear();
      _dosage.clear();
      _medNotes.clear();
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (_items.isEmpty) {
      setState(() => _error = 'Agrega al menos un medicamento a la fórmula.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final a = widget.appointment;
      final folio = (1000 + Random().nextInt(9000)).toString();
      final rx = Prescription(
        id: '',
        appointmentId: a.id,
        petId: a.petId,
        ownerId: a.ownerId,
        clinicId: a.clinicId,
        vetName: widget.vetName,
        petName: a.petName,
        petInfo: a.petInfo,
        items: _items,
        indications: _indications.text.trim(),
        folio: folio,
        createdAt: DateTime.now(),
      );

      final id = await _repo.create(rx);
      final summary = '${_items.first.name} · ${_items.first.dosage}';
      if (!mounted) return;
      Navigator.pop(context);
      widget.onCreated(id, summary);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudo emitir la receta.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Emitir receta digital',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            if (_items.isNotEmpty) ...[
              for (var i = 0; i < _items.length; i++)
                Card(
                  child: ListTile(
                    dense: true,
                    title: Text(_items[i].name,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(_items[i].dosage),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.danger),
                      onPressed: () => setState(() => _items.removeAt(i)),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
            ],
            TextField(
              controller: _medName,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Medicamento (ej. Meloxicam 0.5 mg/ml)',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _dosage,
              decoration: const InputDecoration(
                labelText: 'Dosis y duración (ej. 3 gotas c/12 h · 5 días)',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _medNotes,
              decoration: const InputDecoration(
                labelText: 'Nota (ej. Con la comida)',
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add),
              label: const Text('Agregar medicamento'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _indications,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Indicaciones generales y control',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
                  : const Text('Firmar y enviar receta'),
            ),
          ],
        ),
      ),
    );
  }
}