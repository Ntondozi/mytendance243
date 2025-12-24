// file: splash_loader.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tendance/controlers/authControler.dart';
import 'views/pagesIn/homeIn.dart';
import 'landingPage/landingPage.dart';
import 'views/pagesOut/loginOutPage.dart';
import 'views/pagesOut/signupOutPage.dart';

class SplashLoader extends StatefulWidget {
  @override
  State<SplashLoader> createState() => _SplashLoaderState();
}

class _SplashLoaderState extends State<SplashLoader> {
  @override
  void initState() {
    super.initState();
    // Démarrer après build pour éviter les problèmes de navigation dans initState
    Future.delayed(Duration.zero, _redirect);
  }

  /// Retourne l'utilisateur Firebase si disponible rapidement, sinon null.
  /// Stratégie : tenter idTokenChanges().first (fiable sur web),
  /// fallback vers currentUser avec quelques retries courts.
  Future<User?> _getCurrentUserReliable() async {
  try {
    // Essayer d'obtenir un user via idTokenChanges() (meilleur sur web)
    final user = await FirebaseAuth.instance.idTokenChanges().first;
    if (user != null) return user;
  } catch (_) {
    // ignore
  }

  // Fallback : attendre la restauration de currentUser (logic Gemini améliorée)
  for (int i = 0; i < 5; i++) {
    final u = FirebaseAuth.instance.currentUser;
    if (u != null) return u;

    await Future.delayed(Duration(milliseconds: 200 * (i + 1)));
  }

  return FirebaseAuth.instance.currentUser;
}


  Future<void> _redirect() async {
  // 1️⃣ Permet à l'UI d'apparaître et initialise la locale
  await initializeDateFormatting('fr_FR', null);

  // 2️⃣ Obtenir l'utilisateur de façon fiable
  final user = await _getCurrentUserReliable();

  // 3️⃣ Détecter la route initiale côté Web
  String initialRoute = '/';
  if (kIsWeb) {
    final uri = Uri.base;
    if (uri.pathSegments.isNotEmpty) {
      initialRoute = '/' + uri.pathSegments.join('/');
    }
  }

  // 4️⃣ Si l'utilisateur est connecté → charger home
  if (user != null) {
    try {
      await Get.find<AuthController>()
          .fetchUserProfile(user.uid)
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      print('fetchUserProfile timeout/error: $e');
    }

    if (!mounted) return;

    // Rediriger vers homeIn()
    Get.offAll(() => homeIn());
    return;
  }

  // 5️⃣ Utilisateur non connecté → gérer première ouverture
  try {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('first_launch') ?? true;
    if (isFirstLaunch) await prefs.setBool('first_launch', false);
  } catch (e) {
    print('SharedPreferences error: $e');
  }

  if (!mounted) return;

  // 6️⃣ Redirection selon la route initiale (Web) ou default
  switch (initialRoute) {
    case '/login':
      Get.offAll(() => Loginoutpage());
      break;
    case '/signup':
      Get.offAll(() => Signupoutpage());
      break;
    case '/':
      Get.offAll(() => LandingPageTendance());
    default:
      Get.offAll(() => LandingPageTendance());
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          "assets/images/splashScreen.gif",
          width: 140,
          height: 140,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
