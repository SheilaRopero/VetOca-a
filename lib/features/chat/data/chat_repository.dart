import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';

typedef JsonMap = Map<String, dynamic>;

class ChatRepository {
  ChatRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<JsonMap> _messages(String appointmentId) =>
      _db.collection('chats').doc(appointmentId).collection('messages');

  Stream<List<ChatMessage>> watchMessages(String appointmentId) {
    return _messages(appointmentId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(ChatMessage.fromDoc).toList());
  }

  Future<void> sendMessage(String appointmentId, ChatMessage msg) =>
      _messages(appointmentId).add(msg.toMap());
}