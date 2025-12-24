// file: lib/models/productModel.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ProductModel {
  final String id;
  final String title;
  final String description;
  final double price;
  final String category;
  final String condition;
  final String? size;
  final String? brand;
  final String? color;
  final List<String> imageUrls;
  final String sellerId;
  final String storeId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  List<String> favorites;
  List<String> viewers;
  final String? ownerName;
  final String? storeName;
  final String? currency;

  // Champs d'abonnement du propriétaire (seller)
  final bool? ownerHasActiveSubscription;
  final bool? ownerUsedTrial;

  // NOUVEAUX CHAMPS POUR LE BOOSTING ET LA VISIBILITÉ
  final String? boostLevel; // ex: 'petit', 'moyen', 'grand'
  final DateTime? boostExpiresAt; // Date et heure d'expiration du boost
  final double? completudeScore; // Score de complétude (0.0 à 1.0)
  final int? totalFavoritesCount; // Nombre total de favoris (pour le taux d'interaction)
  final int? totalViewsCount; // Nombre total de vues (pour la popularité)
  final DateTime? lastActivityAt; // Dernière activité pour la fraîcheur
  final DateTime? sellerCreatedAt; // NOUVEAU: Date de création du compte du vendeur

  ProductModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.condition,
    this.size,
    this.brand,
    this.color,
    required this.imageUrls,
    required this.sellerId,
    required this.storeId,
    this.createdAt,
    this.updatedAt,
    this.ownerName,
    this.storeName,
    this.favorites = const [],
    this.viewers = const [],
    this.ownerHasActiveSubscription,
    this.ownerUsedTrial,
    // Initialisation des nouveaux champs
    this.boostLevel,
    this.boostExpiresAt,
    this.completudeScore,
    this.totalFavoritesCount,
    this.totalViewsCount,
    this.lastActivityAt,
    this.sellerCreatedAt, 
    this.currency, 
  });

  // ⚠️ NOUVEAU: Méthode copyWith
  ProductModel copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    String? category,
    String? condition,
    String? size,
    String? brand,
    String? color,
    List<String>? imageUrls,
    String? sellerId,
    String? storeId,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? favorites,
    List<String>? viewers,
    String? ownerName,
    String? storeName,
    bool? ownerHasActiveSubscription,
    bool? ownerUsedTrial,
    String? boostLevel,
    DateTime? boostExpiresAt,
    double? completudeScore,
    int? totalFavoritesCount,
    int? totalViewsCount,
    DateTime? lastActivityAt,
    DateTime? sellerCreatedAt,
    String? currency,
  }) {
    return ProductModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      size: size ?? this.size,
      brand: brand ?? this.brand,
      color: color ?? this.color,
      imageUrls: imageUrls ?? this.imageUrls,
      sellerId: sellerId ?? this.sellerId,
      storeId: storeId ?? this.storeId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      favorites: favorites ?? this.favorites,
      viewers: viewers ?? this.viewers,
      ownerName: ownerName ?? this.ownerName,
      storeName: storeName ?? this.storeName,
      ownerHasActiveSubscription: ownerHasActiveSubscription ?? this.ownerHasActiveSubscription,
      ownerUsedTrial: ownerUsedTrial ?? this.ownerUsedTrial,
      boostLevel: boostLevel ?? this.boostLevel,
      boostExpiresAt: boostExpiresAt ?? this.boostExpiresAt,
      completudeScore: completudeScore ?? this.completudeScore,
      totalFavoritesCount: totalFavoritesCount ?? this.totalFavoritesCount,
      totalViewsCount: totalViewsCount ?? this.totalViewsCount,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      sellerCreatedAt: sellerCreatedAt ?? this.sellerCreatedAt,
      currency: currency ?? this.currency,
    );
  }


  factory ProductModel.fromFirestore(Map<String, dynamic> dynamicData) {
    final data = dynamicData;
    return ProductModel(
      id: data['id'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      category: data['category'] as String? ?? '',
      condition: data['condition'] as String? ?? '',
      size: data['size'] as String?,
      brand: data['brand'] as String?,
      color: data['color'] as String?,
      imageUrls: List<String>.from(data['imageUrls'] as List<dynamic>? ?? []),
      sellerId: data['sellerId'] as String? ?? '',
      storeId: data['storeId'] as String? ?? '',
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : (data['createdAt'] is DateTime ? data['createdAt'] as DateTime : null),
      updatedAt: (data['updatedAt'] is Timestamp)
          ? (data['updatedAt'] as Timestamp).toDate()
          : (data['updatedAt'] is DateTime ? data['updatedAt'] as DateTime : null),
      ownerName: data['ownerName'] as String?,
      storeName: data['storeName'] as String?,
      favorites: List<String>.from(data['favorites'] as List<dynamic>? ?? []),
      viewers: List<String>.from(data['viewers'] as List<dynamic>? ?? []),
      ownerHasActiveSubscription: data['ownerHasActiveSubscription'] as bool?,
      ownerUsedTrial: data['ownerUsedTrial'] as bool?,
      // Initialisation des nouveaux champs de boosting
      boostLevel: data['boostLevel'] as String?,
      boostExpiresAt: (data['boostExpiresAt'] is Timestamp)
          ? (data['boostExpiresAt'] as Timestamp).toDate()
          : (data['boostExpiresAt'] is DateTime ? data['boostExpiresAt'] as DateTime : null),
      completudeScore: (data['completudeScore'] as num?)?.toDouble(),
      totalFavoritesCount: (data['favorites'] as List<dynamic>?)?.length,
      totalViewsCount: (data['viewers'] as List<dynamic>?)?.length,
      lastActivityAt: (data['updatedAt'] is Timestamp)
          ? (data['updatedAt'] as Timestamp).toDate()
          : (data['updatedAt'] is DateTime ? data['updatedAt'] as DateTime : null),
      sellerCreatedAt: (data['sellerCreatedAt'] is Timestamp) // NOUVEAU
          ? (data['sellerCreatedAt'] as Timestamp).toDate()
          : (data['sellerCreatedAt'] is DateTime ? data['sellerCreatedAt'] as DateTime : null),
      currency: data['currency'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'condition': condition,
      'size': size,
      'brand': brand,
      'color': color,
      'imageUrls': imageUrls,
      'sellerId': sellerId,
      'storeId': storeId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'favorites': favorites,
      'viewers': viewers,
      'boostLevel': boostLevel,
      'boostExpiresAt': boostExpiresAt != null ? Timestamp.fromDate(boostExpiresAt!) : null,
      'currency': currency,
    };
  }

  /// 🔹 Getter pour afficher la date au format français
  String get formattedDate {
    if (createdAt == null) return "Date inconnue";
    return DateFormat("d MMMM yyyy", "fr_FR").format(createdAt!);
  }

  /// 🔹 Méthode pour calculer le score de complétude du produit
  double calculateCompletudeScore() {
    int filledFields = 0;
    int totalFields = 0;

    // Champs obligatoires ou fortement recommandés
    if (title.isNotEmpty) filledFields++;
    totalFields++;
    if (description.isNotEmpty) filledFields++;
    totalFields++;
    if (price > 0) filledFields++;
    totalFields++;
    if (category.isNotEmpty) filledFields++;
    totalFields++;
    if (condition.isNotEmpty) filledFields++;
    totalFields++;
    if (imageUrls.isNotEmpty) filledFields++;
    totalFields++;

    // Champs optionnels qui ajoutent de la complétude
    if (size != null && size!.isNotEmpty) filledFields++;
    totalFields++;
    if (brand != null && brand!.isNotEmpty) filledFields++;
    totalFields++;
    if (color != null && color!.isNotEmpty) filledFields++;
    totalFields++;
    // Ajoutez d'autres champs si vous en avez

    return totalFields > 0 ? (filledFields / totalFields) : 0.0;
  }
}
