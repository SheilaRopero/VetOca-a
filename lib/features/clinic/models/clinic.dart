import 'package:cloud_firestore/cloud_firestore.dart';

class Clinic {
  final String id;
  final String name;
  final String address;
  final String phone;
  final bool onDuty;
  final String? closesAt;
  final int consultPrice;

  const Clinic({
    required this.id,
    required this.name,
    required this.address,
    this.phone = '',
    this.onDuty = false,
    this.closesAt,
    this.consultPrice = 0,
  });

factory Clinic.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
final d = doc.data() ?? {};
return Clinic(
id: doc.id,
name: d['name'] as String? ?? '',
address: d['address'] as String? ?? '',
phone: d['phone'] as String? ?? '',
onDuty: _toBool(d['onDuty']),
closesAt: d['closesAt'] as String?,
consultPrice: _toInt(d['consultPrice']),
);
}

// Aceptan número o texto, porque estos datos los cargas a mano en la consola.
static int _toInt(dynamic v) {
if (v is num) return v.toInt();
if (v is String) {
return int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
}
return 0;
}

static bool _toBool(dynamic v) {
if (v is bool) return v;
if (v is String) return v.toLowerCase() == 'true';
return false;
}
}