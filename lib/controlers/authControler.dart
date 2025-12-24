import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tendance/navs/navIn/homeInNav.dart';
import 'package:tendance/views/pagesIn/homeIn.dart';

import '../homepage.dart';
import '../models/userModel.dart';
import '../views/pagesOut/loginOutPage.dart';
import '../landingPage/landingPage.dart';

class AuthController extends GetxController {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Rxn<UserModel> currentUser = Rxn<UserModel>();
  RxBool isLoading = false.obs;
  var error = "".obs;

  @override
  void onInit() {
    auth.setLanguageCode('fr'); // 🇫🇷 Email Firebase en français
    super.onInit();
  }

  // ─────────────── Connexion ───────────────
  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value = true;

      await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = auth.currentUser;
      if (user == null) throw 'Utilisateur non trouvé';

      await fetchUserProfile(user.uid);
      Get.offAll(() => homeIn(), transition: Transition.fadeIn);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        error.value = "Email ou mot de passe incorrect";
      } else if (e.code == 'network-request-failed') {
        error.value =
            "Problème de connexion. Vérifiez votre Internet et réessayez.";
      } else {
        print(e.code);
        error.value = "Erreur: ${e.message}";
      }
      Get.snackbar('Erreur', error.value);
    } catch (e) {
      error.value = "Erreur inconnue: $e";
      Get.snackbar('Erreur', error.value);
    } finally {
      isLoading.value = false;
    }
  }

  // ─────────────── Inscription ───────────────
  Future<void> signUp({
    required String email,
    required String password,
    required String username,
    required String typeCompte,
    String? phone,
    String? ville,
    String? bio,
    
  }) async {
    try {
      isLoading.value = true;

      // Création du compte Firebase
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) throw 'Erreur lors de la création du compte.';

      // Enregistrement du profil dans Firestore
      await firestore.collection('profiles').doc(user.uid).set({
        'id': user.uid,
        'username': username,
        'email': email,
        'account_type': typeCompte,
        'phone': phone,
        'city': ville,
        'bio': bio,
        'created_at': FieldValue.serverTimestamp(),
        
      });

      await fetchUserProfile(user.uid);
      Get.offAll(() => homeIn(), transition: Transition.fadeIn);
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Erreur', e.message ?? 'Une erreur est survenue');
       if (e.code == 'email-already-in-use'
       ) {
        error.value =
            "L'adresse e-mail est déjà utilisée par un autre compte.";
      } else {
        error.value = "Erreur: ${e.message}";
        print(e.code);
        print(e);
      }
      
    } catch (e) {
      Get.snackbar('Erreur', e.toString());
      if (kDebugMode) print(e);

    } finally {
      isLoading.value = false;
    }
  }

  // ─────────────── Récupère les infos utilisateur ───────────────
  Future<void> fetchUserProfile(String userId) async {
    final doc = await firestore.collection('profiles').doc(userId).get();
    if (doc.exists) {
      currentUser.value = UserModel.fromMap(doc.data()!);
    }
  }

  // ─────────────── Déconnexion ───────────────
  Future<void> logout() async {
    await auth.signOut();
    currentUser.value = null;
    Get.offAll(() => const LandingPageTendance());
  }

  Future<void> resetPassword(String email) async {
  try {
    // Appel simple sans ActionCodeSettings
    await auth.sendPasswordResetEmail(email: email);

    // Popup de succès
    // Get.snackbar(
    //   "Email envoyé",
    //   "Vérifiez votre boîte mail pour réinitialiser votre mot de passe.",
    //   snackPosition: SnackPosition.BOTTOM,
    // );
  } catch (e) {
    Get.snackbar(
      "Erreur",
      e.toString(),
      snackPosition: SnackPosition.BOTTOM,
    );
    print(e.toString());
  }
}

}

