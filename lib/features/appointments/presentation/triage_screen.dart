import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../pets/models/pet.dart';
import '../models/triage.dart';
import 'schedule_screen.dart';

class TriageScreen extends StatefulWidget {
  const TriageScreen({
    super.key,
    required this.pet,
    required this.ownerName,
    this.isUrgent = false,
  });

  final Pet pet;
  final String ownerName;
  final bool isUrgent;

  @override
  State<TriageScreen> createState() => _TriageScreenState();
}

class _TriageScreenState extends State<TriageScreen> {
  static const _options = [
    'Vómito', 'Decaimiento', 'Cojera', 'Tos', 'No come', 'Picazón',
  ];
  static const _intensityLabels = [
    'Muy leve', 'Leve', 'Moderada', 'Fuerte', 'Muy fuerte',
  ];

  final _selected = <String>{};
  final _notes = TextEditingController();
  late int _intensity;
  int _days = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _intensity = widget.isUrgent ? 4 : 3;
    _days = widget.isUrgent ? 0 : 1;
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Triage get _triage => Triage(
    symptoms: _options.where(_selected.contains).toList(),
    intensity: _intensity,
    startedDaysAgo: _days,
    notes: _notes.text.trim(),
  );

  String get _daysLabel =>
      _days == 0 ? 'Empezó hoy' : _days == 1 ? 'Empezó hace 1 día' : 'Empezó hace $_days días';

  void _updateIntensityFromOffset(double dx, double totalWidth) {
    if (totalWidth <= 0) return;
    final ratio = (dx / totalWidth).clamp(0.0, 0.999);
    final level = (ratio * 5).floor() + 1;
    if (level != _intensity) {
      setState(() => _intensity = level);
    }
  }

  void _continue() {
    if (_selected.isEmpty) {
      setState(() => _error = 'Marca al menos un síntoma.');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScheduleScreen(
          pet: widget.pet,
          ownerName: widget.ownerName,
          triage: _triage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pet = widget.pet;
    final priority = _triage.priority;
    final (bannerText, bannerBg, bannerFg) = switch (priority) {
      TriagePriority.low =>
      ('Prioridad baja · puedes agendar con calma', AppColors.successSoft, AppColors.success),
      TriagePriority.medium =>
      ('Prioridad media · pasa a videoconsulta', AppColors.primarySoft, AppColors.primary),
      TriagePriority.high =>
      ('Prioridad alta · busca atención lo antes posible', AppColors.dangerSoft, AppColors.danger),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isUrgent ? 'Triaje urgente' : 'Triaje previo'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: widget.isUrgent
                            ? AppColors.dangerSoft
                            : AppColors.primarySoft,
                        child: Icon(
                          Icons.pets,
                          color: widget.isUrgent
                              ? AppColors.danger
                              : AppColors.primary,
                        ),
                      ),
                      title: Text(
                        pet.breed.isEmpty ? pet.name : '${pet.name} · ${pet.breed}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        widget.isUrgent ? 'Consulta de urgencia 24/7' : 'Nueva consulta',
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('¿Qué notas en ${pet.name}?',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text(
                    'Marca todos los síntomas para que el veterinario llegue preparado.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final s in _options)
                        FilterChip(
                          showCheckmark: false,
                          label: Text(s),
                          selected: _selected.contains(s),
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _selected.contains(s)
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                          onSelected: (on) => setState(() {
                            on ? _selected.add(s) : _selected.remove(s);
                            _error = null;
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Intensidad',
                                  style: TextStyle(fontWeight: FontWeight.w700)),
                              Text(_intensityLabels[_intensity - 1],
                                  style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTapDown: (d) => _updateIntensityFromOffset(
                                      d.localPosition.dx, constraints.maxWidth),
                                  onHorizontalDragUpdate: (d) =>
                                      _updateIntensityFromOffset(
                                          d.localPosition.dx,
                                          constraints.maxWidth),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    child: Row(
                                      children: [
                                        for (var i = 1; i <= 5; i++)
                                          Expanded(
                                            child: AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 150),
                                              height: 12,
                                              margin: EdgeInsets.only(
                                                  right: i == 5 ? 0 : 6),
                                              decoration: BoxDecoration(
                                                color: i <= _intensity
                                                    ? AppColors.primary
                                                    : AppColors.border,
                                                borderRadius:
                                                BorderRadius.circular(6),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.schedule,
                                  size: 16, color: AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(_daysLabel,
                                    style: const TextStyle(
                                        color: AppColors.textSecondary)),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: _days > 0
                                    ? () => setState(() => _days--)
                                    : null,
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: _days < 60
                                    ? () => setState(() => _days++)
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notes,
                    minLines: 3,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Notas para el veterinario',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: bannerBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.medical_services_outlined,
                            size: 20, color: bannerFg),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(bannerText,
                              style: TextStyle(
                                  color: bannerFg, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
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
                onPressed: _continue,
                child: const Text('Continuar con la cita'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}