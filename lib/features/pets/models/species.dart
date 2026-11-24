enum Species {
  dog('Perro'),
  cat('Gato'),
  other('Otro');

  const Species(this.label);
  final String label;

  static Species fromName(String? name) => Species.values.firstWhere(
        (s) => s.name == name,
    orElse: () => Species.other,
  );
}