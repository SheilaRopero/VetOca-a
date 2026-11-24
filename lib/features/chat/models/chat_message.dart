import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String senderRole; // 'owner' | 'vet'
  final String text;
  final DateTime createdAt;
  final String? prescriptionId;
  final String? prescriptionSummary;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.text,
    required this.createdAt,
    this.prescriptionId,
    this.prescriptionSummary,
  });

  factory ChatMessage.fromDoc(DocumentSnapshot doc) {
    final d = (doc.data() as Map<String, dynamic>?) ?? {};
    return ChatMessage(
      id: doc.id,
      senderId: d['senderId'] as String? ?? '',
      senderRole: d['senderRole'] as String? ?? 'owner',
      text: d['text'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      prescriptionId: d['prescriptionId'] as String?,
      prescriptionSummary: d['prescriptionSummary'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'senderId': senderId,
    'senderRole': senderRole,
    'text': text,
    'createdAt': FieldValue.serverTimestamp(),
    if (prescriptionId != null) 'prescriptionId': prescriptionId,
    if (prescriptionSummary != null)
      'prescriptionSummary': prescriptionSummary,
  };
}