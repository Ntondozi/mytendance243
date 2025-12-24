// file: lib/controlers/subscription_controller.dart

// VERSION CORRIGÉE - SANS SURVEILLANCE CÔTÉ CLIENT, AVEC MÉTHODES DE PAIEMENT

import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

// Les classes RemotePlanConfig et LocalSubscription restent INCHANGÉES
class RemotePlanConfig {
  final int priceFc;
  final Duration duration;
  final Duration trialDuration;
  final bool trialAvailable;
  final int allowedStores;

  RemotePlanConfig({
    required this.priceFc,
    required this.duration,
    required this.trialDuration,
    required this.trialAvailable,
    required this.allowedStores,
  });
}

class LocalSubscription {
  String planId;
  int expiresAtMillis;
  bool trialUsed;
  int allowedStores;
  String? promoCode;
  int startAtMillis;

  LocalSubscription({
    required this.planId,
    required this.expiresAtMillis,
    this.trialUsed = false,
    required this.allowedStores,
    this.promoCode,
    required this.startAtMillis,
  });

  Map<String, dynamic> toJson() => {
        'planId': planId,
        'expiresAtMillis': expiresAtMillis,
        'trialUsed': trialUsed,
        'allowedStores': allowedStores,
        'promoCode': promoCode,
        'startAtMillis': startAtMillis,
      };

  static LocalSubscription fromJson(Map<String, dynamic> j) => LocalSubscription(
        planId: j['planId'] ?? 'single_5000_month',
        expiresAtMillis: (j['expiresAtMillis'] ?? 0) as int,
        trialUsed: j['trialUsed'] ?? false,
        allowedStores: (j['allowedStores'] ?? -1) as int,
        promoCode: j['promoCode'],
        startAtMillis: (j['startAtMillis'] ?? DateTime.now().millisecondsSinceEpoch) as int,
      );
}

class SubscriptionController extends GetxController {
  static SubscriptionController get to => Get.find();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String get _projectId => _firestore.app.options.projectId!;
  final RxBool subscriptionIsActive = true.obs;

  final Rxn<LocalSubscription> localSub = Rxn<LocalSubscription>();
  final RxBool isLoading = false.obs;
  final Rxn<RemotePlanConfig> remotePlan = Rxn<RemotePlanConfig>();
  final RxMap<String, int> promoCodes = <String, int>{}.obs;
  final RxList<Map<String, dynamic>> notifications = <Map<String, dynamic>>[].obs;
  final Rx<AuthorizationStatus> notificationStatus = AuthorizationStatus.notDetermined.obs;

  StreamSubscription<User?>? _authStateSubscription;

  // SUPPRIMÉ : Le Timer pour la surveillance en arrière-plan.
  // Timer? _backgroundMonitorTimer;

  @override
  void onInit() {
    super.onInit();
    _initializeControllerAsync();
  }

  Future<void> _initializeControllerAsync() async {
    await _setupFirebaseMessaging();
    loadRemoteConfig();
    loadPromoCodes();
    
    await loadLocalSubscription();

    _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        if (notificationStatus.value == AuthorizationStatus.authorized || notificationStatus.value == AuthorizationStatus.provisional) {
          _saveFCMToken(user.uid);
        }
        listenToNotifications(userId: user.uid);
        
        final fsSub = await readSubscriptionFromFirestore(user.uid);
        if (fsSub != null) {
          await saveLocalSubscription(fsSub);
        } else {
          await clearLocalSubscription();
        }

      } else {
        notifications.clear();
        localSub.value = null;
      }
    });

    final initialUser = FirebaseAuth.instance.currentUser;
    if (initialUser != null) {
      if (notificationStatus.value == AuthorizationStatus.authorized || notificationStatus.value == AuthorizationStatus.provisional) {
        _saveFCMToken(initialUser.uid);
      }
      listenToNotifications(userId: initialUser.uid);
      
      final fsSub = await readSubscriptionFromFirestore(initialUser.uid);
      if (fsSub != null) {
        await saveLocalSubscription(fsSub);
      }
    }
  }

  @override
  void onClose() {
    _authStateSubscription?.cancel();
    super.onClose();
  }

  String _formatDateTimeForNotification(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(date);
  }

  // --- Fonctions de gestion de l'UI et des données (INCHANGÉES) ---
  
  Future<void> requestNotificationPermission() async {
    try {
      print('Demande manuelle de la permission via le plugin Firebase...');
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true, badge: true, sound: true,
      );
      notificationStatus.value = settings.authorizationStatus;
      print('Statut de la permission après demande manuelle : ${notificationStatus.value}');

      if (notificationStatus.value == AuthorizationStatus.authorized ||
          notificationStatus.value == AuthorizationStatus.provisional) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) await _saveFCMToken(user.uid);
        Get.snackbar('Notifications activées', 'Vous recevrez désormais les mises à jour importantes.',
            backgroundColor: Colors.green, colorText: Colors.white);
      } else if (notificationStatus.value == AuthorizationStatus.denied) {
        Get.snackbar('Activation requise',
            "Vous avez refusé. Allez dans les paramètres du navigateur/app pour autoriser les notifications.",
            backgroundColor: Colors.orange, colorText: Colors.white);
      }
    } catch (e, st) {
      print('requestNotificationPermission error: $e\n$st');
      Get.snackbar('Erreur', 'Impossible de demander la permission : $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> checkNotificationStatus() async {
    try {
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      notificationStatus.value = settings.authorizationStatus;
    } catch (e) {
      print("Erreur lors de la vérification du statut : $e");
    }
  }

  Future<void> _setupFirebaseMessaging() async {
    await checkNotificationStatus();
    print('Statut de la permission initiale : ${notificationStatus.value}');

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        Get.snackbar(
          message.notification!.title ?? 'Notification',
          message.notification!.body ?? '',
          backgroundColor: Colors.blueGrey, colorText: Colors.white,
        );
      }
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Message opened app: ${message.data}");
    });
  }

  Future<void> _saveFCMToken(String userId) async {
    try {
      if (notificationStatus.value != AuthorizationStatus.authorized &&
          notificationStatus.value != AuthorizationStatus.provisional) {
        return;
      }
      
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await _firestore.collection('profiles').doc(userId).set(
          {'fcmToken': fcmToken, 'fcmTokenPlatform': kIsWeb ? 'web' : 'mobile'},
          SetOptions(merge: true),
        );
        print('FCM Token sauvegardé: $fcmToken');
      }
    } catch (e) {
      print('Erreur lors de la sauvegarde du token FCM: $e');
    }
  }

  void listenToNotifications({required String userId}) {
    _firestore
        .collection('profiles').doc(userId).collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snap) {
      notifications.clear();
      for (var doc in snap.docs) {
        var data = doc.data();
        data['id'] = doc.id;
        notifications.add(data);
      }
    });
  }

  Future<void> markAllAsRead(String userId) async {
    final batch = _firestore.batch();
    for (var notif in notifications) {
      final docRef = _firestore.collection('profiles').doc(userId).collection('notifications').doc(notif['id']);
      batch.update(docRef, {'read': true});
    }
    await batch.commit();
  }

  Future<void> loadRemoteConfig() async {
  try {
    final doc = await _firestore.collection('settings').doc('subscription_config').get();
    if (doc.exists) {
      final d = doc.data()!;
      remotePlan.value = RemotePlanConfig(
        priceFc: (d['priceFc'] ?? 5000) as int,
        duration: Duration(minutes: (d['durationMinutes'] ?? 30 * 24 * 60) as int),
        trialDuration: Duration(minutes: (d['trialDurationMinutes'] ?? 30 * 24 * 60) as int),
        trialAvailable: (d['trialAvailable'] ?? true) as bool,
        allowedStores: (d['allowedStores'] ?? -1) as int,
      );
      subscriptionIsActive.value = (d['subscriptionIsActive'] ?? true) as bool;
    } else {
      // Valeurs par défaut
      remotePlan.value = RemotePlanConfig(
        priceFc: 5000,
        duration: const Duration(days: 30),
        trialDuration: const Duration(days: 30),
        trialAvailable: true,
        allowedStores: -1,
      );
      subscriptionIsActive.value = true;
    }
  } catch (e) {
    print('loadRemoteConfig error: $e');
    remotePlan.value ??= RemotePlanConfig(
      priceFc: 5000,
      duration: const Duration(days: 30),
      trialDuration: const Duration(days: 30),
      trialAvailable: true,
      allowedStores: -1,
    );
    subscriptionIsActive.value = true;
  }
}
// NOUVELLE HELPERS : lire/mettre à jour le flag uniqueFreeTrialActivated
Future<bool> _readUniqueFreeTrialFlag(String userId) async {
  try {
    final docRef = _firestore.collection('profiles').doc(userId).collection('meta').doc('subscription');
    final doc = await docRef.get();
    if (!doc.exists) return false;
    final data = doc.data();
    return (data?['single_5000_month_trial'] ?? false) as bool;
  } catch (e) {
    print('_readUniqueFreeTrialFlag error: $e');
    return false;
  }
}

Future<void> _setUniqueFreeTrialFlag(String userId, bool v) async {
  final docRef = _firestore.collection('profiles').doc(userId).collection('meta').doc('subscription');
  await docRef.set({'single_5000_month_trial': v, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
}

  Future<void> loadPromoCodes() async {
    try {
      final snap = await _firestore.collection('settings').doc('promo_codes').collection('codes').get();
      promoCodes.clear();
      for (var d in snap.docs) {
        if ((d.data()?['active'] ?? true) as bool) {
            promoCodes[d.id.toUpperCase()] = (d.data()?['percent'] ?? 0) as int;
        }
      }
      print('Promo codes loaded: $promoCodes');
    } catch (e) {
      print('loadPromoCodes error: $e');
    }
  }

  Future<void> loadLocalSubscription() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final s = sp.getString('local_subscription_v2');
      if (s != null) {
        localSub.value = LocalSubscription.fromJson(json.decode(s) as Map<String, dynamic>);
      } else {
        localSub.value = null;
      }
    } catch (e) {
      print('loadLocalSubscription error: $e');
      localSub.value = null;
    }
  }

  Future<void> saveLocalSubscription(LocalSubscription s) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('local_subscription_v2', json.encode(s.toJson()));
    localSub.value = s;
  }

  Future<void> clearLocalSubscription() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove('local_subscription_v2');
    localSub.value = null;
  }

  Future<void> writeSubscriptionToFirestore(String userId, LocalSubscription s) async {
    final doc = _firestore.collection('profiles').doc(userId).collection('meta').doc('subscription');
    await doc.set({
      ...s.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<LocalSubscription?> readSubscriptionFromFirestore(String userId) async {
    try {
      final doc = await _firestore.collection('profiles').doc(userId).collection('meta').doc('subscription').get();
      if (!doc.exists) return null;
      return LocalSubscription.fromJson(doc.data()!);
    } catch (e) {
      print('readSubscriptionFromFirestore error: $e');
      return null;
    }
  }

  Future<bool> hasActiveSubscription(String userId) async {
    final sub = await readSubscriptionFromFirestore(userId);
    return sub != null && sub.expiresAtMillis > DateTime.now().millisecondsSinceEpoch;
  }

  Future<bool> canCreateStore(String userId) async {
    final sub = await readSubscriptionFromFirestore(userId);
    if (sub == null || sub.expiresAtMillis < DateTime.now().millisecondsSinceEpoch) return false;
    if (sub.allowedStores == -1) return true;
    
    final storesSnap = await _firestore.collection('profiles').doc(userId).collection('stores').get();
    return storesSnap.docs.length < sub.allowedStores;
  }

  // --- MÉTHODES DE PAIEMENT ET D'ESSAI (RESTAURÉES) ---

  int applyPromo(String? code, int amount) {
    if (code == null) return amount;
    final k = code.trim().toUpperCase();
    final pct = promoCodes[k];
    if (pct == null) return amount;
    return (amount * (100 - pct) / 100).round();
  }

  Future<Map<String, dynamic>> _callHttpsFunction(String functionName, Map<String, dynamic> params) async {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (idToken == null) throw Exception('Utilisateur non authentifié.');
    
    final String url = 'https://us-central1-$_projectId.cloudfunctions.net/$functionName';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $idToken'},
      body: jsonEncode({'data': params}),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      if (responseData.containsKey('result')) {
        return responseData['result'] as Map<String, dynamic>;
      } else {
        throw Exception('Réponse inattendue de la fonction Cloud.');
      }
    } else {
      throw Exception('Erreur de la fonction Cloud (${response.statusCode}): ${response.body}');
    }
  }

  Future<String?> createLygosPaymentAndOpen({ required double amountFc, required String userId, String? message, String? promoCode }) async {
    try {
      final result = await _callHttpsFunction('lygos_initiatePayment', {
        'amountFc': amountFc, 'message': message ?? "Abonnement mensuel", 'paymentType': 'subscription', 'planId': 'single_5000_month', 'promoCode': promoCode,
      });
      
      final link = result['link'] as String?;
      final orderId = result['orderId'] as String?;
      if (link != null && orderId != null) {
        final uri = Uri.parse(link);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.inAppWebView);
        }
        _pollLygosOrder(orderId, userId);
        return link;
      } else {
        throw Exception('Lien de paiement non reçu.');
      }
    } on Exception catch (e) {
      Get.snackbar('Erreur', 'Impossible d\'initier le paiement: ${e.toString()}', backgroundColor: Colors.red);
      return null;
    }
  }

  Future<String?> _getLygosPayinStatus(String orderId) async {
    try {
      final result = await _callHttpsFunction('lygos_checkPaymentStatus', {'orderId': orderId});
      return result['status'] as String?;
    } on Exception catch (e) {
      print('\_getLygosPayinStatus error: $e');
      return null;
    }
  }

  Future<void> _processPaymentResult({ required String userId, required String orderId, required bool success, String? reason }) async {
    try {
      await _callHttpsFunction('lygos_processPaymentResult', {
        'orderId': orderId, 'success': success, 'reason': reason,
      });
    } on Exception catch (e) {
      Get.snackbar('Erreur', 'Un problème est survenu lors de la finalisation. Contactez le support.', backgroundColor: Colors.red);
    }
  }

  Future<void> _pollLygosOrder(String orderId, String userId, {int maxChecks = 100, Duration interval = const Duration(seconds: 5)}) async {
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

  // MODIFICATION : empêcher le paiement si subscriptionIsActive == false
Future<String?> initiatePaymentForCurrentPlan({ required String userId, String? promoCode, String? message }) async {
  if (subscriptionIsActive.value == false) {
    throw Exception('Subscriptions are disabled by admin'); // UI catchera et affichera un snackbar
  }
  final plan = remotePlan.value;
  if (plan == null) await loadRemoteConfig();
  final usedPlan = remotePlan.value!;
  double amount = applyPromo(promoCode, usedPlan.priceFc).toDouble();
  return await createLygosPaymentAndOpen(
    amountFc: amount, userId: userId, message: message, promoCode: promoCode,
  );
}

  Future<void> activateTrialIfAvailable({required String userId, String? promo}) async {
  final plan = remotePlan.value;
  if (plan == null) await loadRemoteConfig();
  final p = remotePlan.value!;

  // Si les abonnements sont désactivés globalement -> parcours "unique free trial"
  if (subscriptionIsActive.value == false) {
    // Vérifier notre flag propre "uniqueFreeTrialActivated" dans le doc meta/subscription
    final already = await _readUniqueFreeTrialFlag(userId);
    if (already) {
      throw Exception('Unique trial already activated');
    }

    final now = DateTime.now();
    final sub = LocalSubscription(
      planId: 'single_free_unique_trial',
      expiresAtMillis: now.add(p.trialDuration).millisecondsSinceEpoch,
      trialUsed: true,
      allowedStores: p.allowedStores,
      promoCode: promo,
      startAtMillis: now.millisecondsSinceEpoch,
    );

    await saveLocalSubscription(sub);
    // Écrire la subscription et le flag unique dans Firestore
    final docRef = _firestore.collection('profiles').doc(userId).collection('meta').doc('subscription');
    await docRef.set({
      ...sub.toJson(),
      'uniqueFreeTrialActivated': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Notification utilisateur
    final trialMessage = 'Votre essai gratuit unique est activé jusqu\'au ${_formatDateTimeForNotification(DateTime.fromMillisecondsSinceEpoch(sub.expiresAtMillis))}';
    await _firestore.collection('profiles').doc(userId).collection('notifications').add({
      'title': 'Essai activé',
      'message': trialMessage,
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });
    return;
  }

  // Sinon : comportement normal (vérifier si trial déjà utilisé via subscription Firestore)
  final subFromFs = await readSubscriptionFromFirestore(userId);
  if (subFromFs != null && subFromFs.trialUsed == true) {
    throw Exception('Trial already used');
  }
  if (!p.trialAvailable) throw Exception('Trial not available');

  final now = DateTime.now();
  final sub = LocalSubscription(
    planId: 'single_5000_month_trial',
    expiresAtMillis: now.add(p.trialDuration).millisecondsSinceEpoch,
    trialUsed: true,
    allowedStores: p.allowedStores,
    promoCode: promo,
    startAtMillis: now.millisecondsSinceEpoch,
  );

  await saveLocalSubscription(sub);
  await writeSubscriptionToFirestore(userId, sub);

  final trialMessage = 'Votre essai gratuit est activé jusqu\'au ${_formatDateTimeForNotification(DateTime.fromMillisecondsSinceEpoch(sub.expiresAtMillis))}';
  await _firestore.collection('profiles').doc(userId).collection('notifications').add({
    'title': 'Essai activé', 'message': trialMessage, 'createdAt': FieldValue.serverTimestamp(), 'read': false,
  });
}


}


