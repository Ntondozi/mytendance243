// file: lib/models/chatModel.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  String? id;
  final String senderId;
  final String receiverId;
  final String message;
  final DateTime? createdAt;
  final DateTime? editedAt;
  final String status; // "pending" | "sent" | "delivered" | "read"
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final bool hasPendingWrites; // utile côté client pour UI

  ChatMessage({
    this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    this.createdAt,
    this.editedAt,
    this.status = 'pending',
    this.deliveredAt,
    this.readAt,
    this.hasPendingWrites = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      // si on veut un timestamp côté client immédiat on peut utiliser Timestamp.fromDate
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      'status': status,
      'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
    };
  }

  // Création à partir d'un DocumentSnapshot : on accepte le map et l'id et le flag hasPendingWrites
  factory ChatMessage.fromMap(Map<String, dynamic> map, {String? id, bool hasPendingWrites = false}) {
    return ChatMessage(
      id: id,
      senderId: map['senderId'] as String,
      receiverId: map['receiverId'] as String,
      message: map['message'] as String,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      editedAt: (map['editedAt'] as Timestamp?)?.toDate(),
      status: (map['status'] as String?) ?? 'pending',
      deliveredAt: (map['deliveredAt'] as Timestamp?)?.toDate(),
      readAt: (map['readAt'] as Timestamp?)?.toDate(),
      hasPendingWrites: hasPendingWrites,
    );
  }
  
  ChatMessage copyWith({
  String? status,
  bool? hasPendingWrites,
}) {
  return ChatMessage(
    id: id,
    senderId: senderId,
    receiverId: receiverId,
    message: message,
    createdAt: createdAt,
    editedAt: editedAt,
    status: status ?? this.status,
    hasPendingWrites: hasPendingWrites ?? this.hasPendingWrites,
  );
}

}
