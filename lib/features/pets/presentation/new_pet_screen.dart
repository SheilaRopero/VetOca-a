import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../data/pet_repository.dart';
import '../models/pet.dart';
import '../models/species.dart';

class NewPetScreen extends StatefulWidget {
  const NewPetScreen({super.key, required this.ownerId});

  final String ownerId;

  @override
  State<NewPetScreen> createState() => _NewPetScreenState();
}

class _NewPetScreenState extends State<NewPetScreen> {
  final _repo = PetRepository();
  final _name = TextEditingController();
  final _breed = TextEditingController();
  final _age = TextEditingController();
  final _weight = TextEditingController();

  Species _species = Species.dog;
  bool _share = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _breed.dispose();
    _age.dispose();
    _weight.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final age = int.tryParse(_age.text.trim());
    final weight = double.tryParse(_weight.text.trim().replaceAll(',', '.'));

    if (name.isEmpty || age == null || weight == null) {
      setState(() => _error = 'Completa nombre, edad y peso con valores válidos.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await _repo.addPet(Pet(
        id: '',
        ownerId: widget.ownerId,
        name: name,
        species: _species,
        breed: _breed.text.trim(),
        ageYears: age,
        weightKg: weight,
        shareHistory: _share,
      ));
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudo guardar la ficha. Intenta de nuevo.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva mascota')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  for (final s in Species.values)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                            right: s == Species.values.last ? 0 : 8),
                        child: ChoiceChip(
                          showCheckmark: false,
                          selected: _species == s,
                          onSelected: (_) => setState(() => _species = s),
                          selectedColor: AppColors.primary,
                          label: SizedBox(
                            width: double.infinity,
                            child: Text(
                              s.label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _species == s
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _breed,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Raza'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _age,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Edad (años)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _weight,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Peso (kg)'),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SwitchListTile(
                  value: _share,
                  onChanged: (v) => setState(() => _share = v),
                  title: const Text('Compartir historial',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Visible para las sedes autorizadas'),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: AppColors.danger)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white),
                )
                    : const Text('Guardar ficha'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}