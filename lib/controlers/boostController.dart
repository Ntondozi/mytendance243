// file: lib/controlers/boostController.dart

import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../models/boostPlanModel.dart';
import 'productControler.dart';

class BoostController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // REMARQUE : FirebaseFunctions _functions n'est plus utilisé directement pour les appels, mais le package peut rester si d'autres parties l'utilisent.
  String get _projectId => _firestore.app.options.projectId!;
  final RxMap<String, BoostPlan> boostPlans = <String, BoostPlan>{}.obs;

  ProductController get _productController => Get.find<ProductController>();

  @override
  void onInit() {
    super.onInit();
    loadBoostPlans();
  }

  Future<void> loadBoostPlans() async {
    try {
      final doc = await _firestore.collection('settings').doc('boost_config').get();
      if (doc.exists && doc.data() != null) {
        final plansData = doc.data()!['plans'] as Map<String, dynamic>?;
        if (plansData != null) {
          boostPlans.clear();
          plansData.forEach((key, value) {
            boostPlans[key] = BoostPlan.fromMap(key, value as Map<String, dynamic>);
          });
        }
      }
    } catch (e) {
      print('loadBoostPlans error: $e');
      _setFallbackBoostPlans(); // Appelle le fallback même si doc n'existe pas ou erreur
    }
    // Assurez-vous qu'il y a toujours des plans, même si le chargement échoue
    if (boostPlans.isEmpty) {
      _setFallbackBoostPlans();
    }
  }

  void _setFallbackBoostPlans() {
    boostPlans['petit'] = BoostPlan(
      id: 'petit', label: 'Petit Boost (7 jours)', priceFc: 1000.0, duration: const Duration(days: 7),
    );
    boostPlans['moyen'] = BoostPlan(
      id: 'moyen', label: 'Moyen Boost (15 jours)', priceFc: 2000.0, duration: const Duration(days: 15),
    );
    boostPlans['grand'] = BoostPlan(
      id: 'grand', label: 'Grand Boost (30 jours)', priceFc: 3000.0, duration: const Duration(days: 30),
    );
  }

  // --- Fonctions utilitaires pour les appels HTTP aux Cloud Functions ---
  Future<Map<String, dynamic>> _callHttpsFunction(String functionName, Map<String, dynamic> params) async {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (idToken == null) {
      throw Exception('Utilisateur non authentifié. Veuillez vous reconnecter.');
    }

    // REMPLACEZ 'us-central1' PAR LA RÉGION DE VOS FONCTIONS (ex: 'europe-west1', 'asia-east2')
    final String cloudFunctionRegion = 'us-central1'; // <= VÉRIFIEZ ET MODIFIEZ CETTE RÉGION
    final String url = 'https://$cloudFunctionRegion-$_projectId.cloudfunctions.net/$functionName';

    // Correction CLÉ : Envelopper les paramètres dans une clé "data"
    final Map<String, dynamic> requestBody = {'data': params};

    print('[DEBUG CF_CALL] Appel de la fonction $functionName avec l\'URL: $url');
    print('[DEBUG CF_CALL] Corps de la requête (RAW): ${jsonEncode(requestBody)}');

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body) as Map<String, dynamic>;
      print('[DEBUG CF_CALL] Réponse de $functionName (RAW): ${response.body}');
      // Les réponses des fonctions onCall sont aussi enveloppées dans "result"
      if (responseData.containsKey('result')) {
        return responseData['result'] as Map<String, dynamic>;
      } else {
        throw Exception('Réponse inattendue de la fonction Cloud: Pas de clé "result".');
      }
    } else {
      print('[DEBUG CF_CALL] Erreur HTTP ${response.statusCode}: ${response.body}');
      throw Exception('Problème lors de l\'appel à la fonction Cloud ($functionName - ${response.statusCode}): ${response.body}');
    }
  }

  Future<String?> createLygosBoostPaymentAndOpen({
    required double amountFc,
    required String userId,
    required String message,
    required String targetId,
    required String targetType,
    required String boostLevel,
    required Duration boostDuration,
    String? promoCode,
  }) async {
    try {
      print('[DEBUG BOOST] Début createLygosBoostPaymentAndOpen');
      String? resolvedStoreId;
      if (targetType == 'product') {
        resolvedStoreId = await _productController.getStoreIdForProduct(userId, targetId);
        if (resolvedStoreId == null) {
          throw Exception('Impossible de trouver l\'ID de la boutique pour le produit spécifié.');
        }
      }

      final Map<String, dynamic> params = {
        'amountFc': amountFc,
        'message': message,
        'paymentType': 'boost',
        'targetId': targetId,
        'targetType': targetType,
        'boostLevel': boostLevel,
        'boostDurationMinutes': boostDuration.inMinutes.toDouble(), // Envoyer comme double
        'promoCode': promoCode,
      };
      
      if (resolvedStoreId != null) {
        params['storeId'] = resolvedStoreId;
      }

      print('[DEBUG BOOST] Paramètres envoyés à l\'initiation de paiement: $params');
      final result = await _callHttpsFunction('lygos_initiatePayment', params);
      
      final link = result['link'] as String?;
      final orderId = result['orderId'] as String?;
      
      if (link != null && orderId != null) {
        final uri = Uri.parse(link);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.inAppWebView);
        }
        _pollLygosBoostOrder(orderId, userId);
        return link;
      } else {
        throw Exception('La fonction Cloud n\'a pas retourné de lien ou d\'ID de commande.');
      }
    } on Exception catch (e, s) {
      print('createLygosBoostPaymentAndOpen error: $e');
      print('STACK TRACE: $s');
      Get.snackbar('Erreur', 'Problème lors de l\'initiation du boost: ${e.toString()}', backgroundColor: Colors.red, colorText: Colors.white);
      return null;
    }
  }

  Future<String?> _getLygosPayinStatus(String orderId) async {
    try {
      final result = await _callHttpsFunction('lygos_checkPaymentStatus', {'orderId': orderId});
      final status = result['status'] as String?;
      print('Lygos status for boost order $orderId: $status');
      return status;
    } catch (e) {
      print('_getLygosPayinStatus error: $e');
      return null;
    }
  }

  Future<void> _processPaymentResult({
    required String userId,
    required String orderId,
    required bool success,
    String? reason,
  }) async {
    try {
      await _callHttpsFunction('lygos_processPaymentResult', {
        'orderId': orderId,
        'success': success,
        'reason': reason,
      });
      print('Boost payment result processed for orderId: $orderId');
      if (success) {
        Get.snackbar('Succès', 'Boost activé avec succès !', backgroundColor: Colors.green);
      } else {
        Get.snackbar('Échec du Boost', 'Le boost n\'a pas pu être activé. Raison: ${reason ?? 'inconnue'}', backgroundColor: Colors.red);
      }
    } on Exception catch (e) {
      print('_processPaymentResult error: $e');
      Get.snackbar('Erreur', 'Un problème est survenu lors de l\'activation de votre boost. Contactez le support.', backgroundColor: Colors.red);
    }
  }

  Future<void> _pollLygosBoostOrder(String orderId, String userId, {int maxChecks = 100, Duration interval = const Duration(seconds: 5)}) async {
    int tries = 0;
    while (tries < maxChecks) {
      tries++;
      final status = await _getLygosPayinStatus(orderId);
      if (status == 'SUCCESS' || status == 'SUCCEEDED' || status == 'PAID' || status == 'COMPLETED') {
        await _processPaymentResult(userId: userId, orderId: orderId, success: true);
        return;
      } else if (status == 'FAILED' || status == 'CANCELLED' || status == 'ERROR') {
        await _processPaymentResult(userId: userId, orderId: orderId, success: false, reason: status);
        return;
      }
      await Future.delayed(interval);
    }
    await _processPaymentResult(userId: userId, orderId: orderId, success: false, reason: 'TIMEOUT');
  }
}
