// file: lib/models/userModel.dart

import 'package:cloud_firestore/cloud_firestore.dart'; // N'oubliez pas cet import !

class UserModel {
  final String id;
  final String username;
  final String email;
  final String? phone;
  final String? ville;
  final String? bio;
  final String? avatarUrl;
  final String? typeCompte;
  final String? photoUrl;
  final DateTime? createdAt; // <--- NOUVEAU : Champ pour la date de création

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.phone,
    this.ville,
    this.bio,
    this.avatarUrl,
    this.typeCompte,
    this.photoUrl,
    this.createdAt, // <--- NOUVEAU : Ajout au constructeur
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      id: data['id'],
      username: data['username'],
      email: data['email'],
      phone: data['phone'],
      ville: data['city'], // Utilise 'city' comme dans votre AuthController
      bio: data['bio'],
      avatarUrl: data['avatar_url'],
      typeCompte: data['account_type'], // Utilise 'account_type' comme dans votre AuthController
      photoUrl: data['photoUrl'],
      // NOUVEAU : Conversion du Timestamp de Firestore en DateTime
      createdAt: (data['created_at'] is Timestamp) 
          ? (data['created_at'] as Timestamp).toDate() 
          : null, // Si 'created_at' n'est pas un Timestamp, ou est absent
    );
  }
}
