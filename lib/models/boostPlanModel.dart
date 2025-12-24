// file: lib/models/boostPlanModel.dart

import 'package:flutter/material.dart'; // Pour Duration

class BoostPlan {
  final String id; // 'petit', 'moyen', 'grand'
  final String label; // "Petit Boost (7 jours)"
  final double priceFc; // CHANGEMENT: Type double pour le prix
  final Duration duration; // Type Duration pour la durée

  BoostPlan({
    required this.id,
    required this.label,
    required this.priceFc,
    required this.duration,
  });

  factory BoostPlan.fromMap(String id, Map<String, dynamic> data) {
    // Parser correctement depuis les données, en s'assurant du double pour priceFc
    return BoostPlan(
      id: id,
      label: data['label'] as String? ?? id,
      priceFc: (data['priceFc'] as num?)?.toDouble() ?? 0.0, // Convertir les données en double
      duration: Duration(minutes: (data['durationMinutes'] as num?)?.toInt() ?? 0), // Convertir en Duration
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'priceFc': priceFc,
      'durationMinutes': duration.inMinutes, // Stocker la durée en minutes (int) si Firestore le permet
    };
  }
}
