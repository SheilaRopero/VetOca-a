import 'package:flutter_test/flutter_test.dart';
import 'package:vetocana_app/features/pets/models/vaccine.dart';

void main() {
  test('Vacuna con fecha pasada está vencida', () {
    final v = Vaccine(
      id: '1',
      name: 'Leptospira',
      nextDueAt: DateTime.now().subtract(const Duration(days: 10)),
    );
    expect(v.status, VaccineStatus.overdue);
  });

  test('Vacuna en 15 días está próxima', () {
    final v = Vaccine(
      id: '2',
      name: 'Rabia',
      nextDueAt: DateTime.now().add(const Duration(days: 15)),
    );
    expect(v.status, VaccineStatus.upcoming);
  });

  test('Vacuna lejana está al día', () {
    final v = Vaccine(
      id: '3',
      name: 'Polivalente',
      nextDueAt: DateTime.now().add(const Duration(days: 300)),
    );
    expect(v.status, VaccineStatus.upToDate);
  });
}