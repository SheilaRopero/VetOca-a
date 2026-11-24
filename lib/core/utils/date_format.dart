const _monthsShort = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

const _monthsLong = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];

/// 12 mar 2026
String formatShortDate(DateTime d) =>
    '${d.day} ${_monthsShort[d.month - 1]} ${d.year}';

/// 3 de diciembre
String formatLongDate(DateTime d) => '${d.day} de ${_monthsLong[d.month - 1]}';

/// Días que faltan desde hoy (negativo si ya pasó).
int daysUntil(DateTime d) {
  final now = DateTime.now();
  return DateTime(d.year, d.month, d.day)
      .difference(DateTime(now.year, now.month, now.day))
      .inDays;
}

const _weekdaysShort = ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB', 'DOM'];

String weekdayShort(DateTime d) => _weekdaysShort[d.weekday - 1];

String monthName(DateTime d) => _monthsLong[d.month - 1];

/// 2026-11-18
String dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// 2026-11-18_1630 (identifica un cupo)
String slotKey(DateTime d) =>
    '${dayKey(d)}_${d.hour.toString().padLeft(2, '0')}${d.minute.toString().padLeft(2, '0')}';

/// 4:30
String formatSlot(DateTime d) {
  final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return '$h12:${d.minute.toString().padLeft(2, '0')}';
}

/// 4:30 p. m.
String formatTime12(DateTime d) =>
    '${formatSlot(d)} ${d.hour < 12 ? 'a. m.' : 'p. m.'}';

/// $45.000
String formatCop(int value) {
  final s = value.toString();
  final out = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) out.write('.');
    out.write(s[i]);
  }
  return '\$$out';
}