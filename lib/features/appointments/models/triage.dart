enum TriagePriority { low, medium, high }

class Triage {
  final List<String> symptoms;
  final int intensity; // 1 a 5
  final int startedDaysAgo;
  final String notes;

  static const intensityLabels = [
    'Muy leve', 'Leve', 'Moderada', 'Fuerte', 'Muy fuerte',
  ];

  String get intensityLabel =>
      intensityLabels[intensity.clamp(1, 5).toInt() - 1];

  factory Triage.fromMap(Map<String, dynamic> m) => Triage(
    symptoms: List<String>.from(m['symptoms'] ?? const []),
    intensity: (m['intensity'] as num?)?.toInt() ?? 1,
    startedDaysAgo: (m['startedDaysAgo'] as num?)?.toInt() ?? 0,
    notes: m['notes'] as String? ?? '',
  );

  const Triage({
    required this.symptoms,
    required this.intensity,
    required this.startedDaysAgo,
    this.notes = '',


  });

  /// Regla provisional basada solo en la intensidad.
  TriagePriority get priority {
    if (intensity >= 4) return TriagePriority.high;
    if (intensity == 3) return TriagePriority.medium;
    return TriagePriority.low;
  }

  Map<String, dynamic> toMap() => {
    'symptoms': symptoms,
    'intensity': intensity,
    'startedDaysAgo': startedDaysAgo,
    'notes': notes,
    'priority': priority.name,
  };
}