import 'dart:math';
import 'dart:js' as js; // Import pour l'interopérabilité JavaScript

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:animate_do/animate_do.dart';

import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import 'package:get/get.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tendance/views/pagesIn/homeIn.dart';

import 'package:visibility_detector/visibility_detector.dart';

import '../../../controlers/productControler.dart'; // Assurez-vous d'avoir cet import
import '../../../models/productModel.dart'; // Assurez-vous d'avoir cet import
import '../../../controlers/ColorsData.dart'; // Import pour Colorsdata
import 'package:tendance/downloadApk/downloadApk.dart';
import '../controlers/authControler.dart';
import '../controlers/subscription_controller.dart';
import '../notification_settings.dart';
import '../views/pagesOut/loginOutPage.dart';
import '../views/pagesOut/signupOutPage.dart';


class LandingPageTendance extends StatefulWidget {
  const LandingPageTendance({super.key});

  @override
  State<LandingPageTendance> createState() => _LandingPageTendanceState();
}

class _LandingPageTendanceState extends State<LandingPageTendance> {
  double scrollPosition = 0.0;
  final colors = Colorsdata();
  final scrollController = ScrollController();
  final GlobalKey _productSectionKey = GlobalKey(); // Clé pour la section des produits
  final SubscriptionController subController = Get.find<SubscriptionController>();
  
  bool _checkingAuth = true;
  @override
  void initState() {
    super.initState();

    if (kIsWeb) {
       _checkAuthInstant();
    }
    
    subController.checkNotificationStatus();
  }

  // ------------------------------------------------------
  // 🔥 Vérification instantanée (Web uniquement)
  // ------------------------------------------------------
  Future<void> _checkAuthInstant() async {
    final user = await _getCurrentUserReliable();

    if (user != null) {
      try {
        await Get.find<AuthController>()
            .fetchUserProfile(user.uid)
            .timeout(const Duration(seconds: 2));
      } catch (_) {}

      // Navigation après le 1er frame : évite le flash
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAll(() => homeIn());
      });
      return;
    }

    // User non connecté → afficher LandingPage
    setState(() => _checkingAuth = false);
  }

  // ------------------------------------------------------
  // 🔥 Méthode robuste pour récupérer user (Web)
  // ------------------------------------------------------
  Future<User?> _getCurrentUserReliable() async {
    try {
      final user = await FirebaseAuth.instance.idTokenChanges()
          .first
          .timeout(const Duration(milliseconds: 700));
      if (user != null) return user;
    } catch (_) {}

    // Recheck rapide pour éviter les null intermittents
    for (int i = 0; i < 3; i++) {
      final u = FirebaseAuth.instance.currentUser;
      if (u != null) return u;
      await Future.delayed(Duration(milliseconds: 120));
    }

    return FirebaseAuth.instance.currentUser;
  }




  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 700;
    final width = MediaQuery.of(context).size.width;

            double aspectRatio;

      if (width >= 1090) {
        aspectRatio = 0.85;
      } 
      else
      if (width >= 1032) {
        aspectRatio = 0.78;
      } 
      else
      if (width >= 992) {
        aspectRatio = 0.72;
      } 
      else
      if (width >= 866) {
        aspectRatio = 0.65;
      } 
      else
      if (width >= 798) {
        aspectRatio = 0.60;
      } 
      else
      if (width >= 767.5) {
        aspectRatio = 0.58;
      } 
      else if (width >= 730) {
        aspectRatio = 0.52;
      } else
      if (width >= 700) {
        aspectRatio = 0.49;
      }
      else
      if (width >= 680) {
        aspectRatio = 0.85;
      } 
      else
      if (width >= 650) {
        aspectRatio = 0.88;
      } 
      else
      if (width >= 614) {
        aspectRatio = 0.85;
      } 
      else
      if (width >= 570) {
        aspectRatio = 0.8;
      } 
      else
      if (width >= 540) {
        aspectRatio = 0.76;
      } 
      else
      if (width >= 511) {
        aspectRatio = 0.70;
      } 
      else
      if (width >= 498) {
        aspectRatio = 0.66;
      } 
      else
      if (width >= 480) {
        aspectRatio = 0.65;
      } 
      else
      if (width >= 466) {
        aspectRatio = 0.63;
      } 
      else
      if (width >= 450) {
        aspectRatio = 0.61;
      } 
      else if (width >= 434) { // 435–449
        aspectRatio = 0.59;
      }else if (width >= 420) {  // 420–434
        aspectRatio = 0.59;
      } 
      else if (width >= 405) {  // 405–419
        aspectRatio = 0.57;
      } 
      else if (width >= 390) {  // 390–404
        aspectRatio = 0.517;
      } 
      else if (width >= 375) {  // 375–389
        aspectRatio = 0.487;
      } 
      else if (width >= 360) {  // 360–374
        aspectRatio = 0.46;
      } 
      else if (width >= 345) {  // 345–359
        aspectRatio = 0.44;
      } 
      else if (width >= 330) {  // 330–344
        aspectRatio = 0.42;
      } 
      else if (width >= 315) {  // 315–329
        aspectRatio = 0.39;
      } 
      else if (width >= 300) {  // 300–314
        aspectRatio = 0.37;
      } 
      else if (width >= 285) {  // 285–299
        aspectRatio = 0.34;
      } 
      else if (width >= 270) {  // 270–284
        aspectRatio = 0.32;
      } 
      else if (width >= 255) {  // 255–269
        aspectRatio = 0.30;
      } 
      else if (width >= 240) {  // 240–254
        aspectRatio = 0.28;
      } 
      else if (width >= 225) {  // 225–239
        aspectRatio = 0.26;
      }
      else {  // <225px
        aspectRatio = 0.24;
      }
      print(width);

    // Si on vérifie encore → afficher une page vide sans layout
    if (_checkingAuth) {
      return Center(
        child: Image.asset(
          "assets/images/splashScreen.gif",
          width: 100,
          height: 100,
          fit: BoxFit.contain,
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (scrollInfo) {
              setState(() => scrollPosition = scrollInfo.metrics.pixels);
              return true;
            },
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                children: [
                  _heroSection(size, isMobile),
                  // L'ordre a été modifié ici pour que la section produits soit après "Pourquoi choisir Tendance"
                  _aboutSection(isMobile),
                  _featuresSection(isMobile),
                  _whyChooseSection(isMobile),
                  _productPreviewSection(isMobile, width, aspectRatio), // Section produits ici
                  _ctaSection(isMobile),
                  _footerSection(isMobile),
                ],
              ),
            ),
          ),
          _header(context, isMobile),
        ],
      ),
    );
  }

  // ────────────── HEADER ──────────────
  Widget _header(BuildContext context, bool isMobile) {
    final opacity = (scrollPosition < 100) ? 0.0 : 0.9;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 70,
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 80),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(opacity),
          boxShadow: [
            if (scrollPosition > 100)
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 5,
                offset: const Offset(0, 3),
              )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Tendance",
                style: GoogleFonts.poppins(
                    color: colors.color,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            isMobile
                ? ElevatedButton.icon(
                          onPressed: () {
                            if (_productSectionKey.currentContext != null) {
                              Scrollable.ensureVisible(
                                _productSectionKey.currentContext!,
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                          icon: const Icon(Icons.arrow_downward, color: Colors.white),
                          label: const Text("Explorer", style: TextStyle(fontSize: 13, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.color.withOpacity(0.8),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 12),
                          ),
                        ) // Menu hamburger ou autre pour mobile peut être ajouté ici
                : const SizedBox.shrink(),
            if (!isMobile)
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _menuItem("Accueil", () => _scrollTo(0)),
                      _menuItem("Fonctionnalités", () => _scrollTo(800)),
                      _menuItem("Contact", () => _scrollTo(3000)),
                      const SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: () => Get.to(Loginoutpage()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.color,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 25, vertical: 12),
                        ),
                        child: const Text("Se connecter"),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                                onPressed: () {
                                  if (_productSectionKey.currentContext != null) {
                                    Scrollable.ensureVisible(
                                      _productSectionKey.currentContext!,
                                      duration: const Duration(milliseconds: 800),
                                      curve: Curves.easeInOut,
                                    );
                                  }
                                },
                                icon: const Icon(Icons.arrow_downward, color: Colors.white),
                                label: const Text("Explorer", style: TextStyle(fontSize: 17, color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colors.color.withOpacity(0.8),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                                ),
                              ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(String text, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Text(text,
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500)),
        ),
      );

  void _scrollTo(double position) {
    scrollController.animateTo(position,
        duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
  }

  // ────────────── HERO SECTION ──────────────
  Widget _heroSection(Size size, bool isMobile) {
    return SizedBox(
      height: isMobile ? size.height * 0.7 : size.height * 0.9,
      child: Stack(
        children: [
          Positioned(
            top: -scrollPosition * 0.3,
            left: 0,
            right: 0,
            child: Image.asset(
              "assets/images/c.jpg",
              height: isMobile ? size.height * 0.7 : size.height * 0.9,
              fit: BoxFit.cover,
            ),
          ),
          Container(
            color: Colors.black.withOpacity(0.45),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeInDown(
                    duration: const Duration(milliseconds: 800),
                    child: Text("Bienvenue sur Tendance",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: isMobile ? 30 : 50,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center),
                  ),
                  const SizedBox(height: 14),
                  FadeIn(
                    delay: const Duration(milliseconds: 200),
                    child: Text(
                      "Achetez et vendez facilement vos produits neufs ou d’occasion en RDC.",
                      style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: isMobile ? 16 : 20),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 25),
                  AnimationLimiter(
                    child: Column(
                      children: AnimationConfiguration.toStaggeredList(
                        duration: const Duration(milliseconds: 500),
                        childAnimationBuilder: (widget) => SlideAnimation(
                          verticalOffset: 20,
                          child: FadeInAnimation(child: widget),
                        ),
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 55, vertical: 14),
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => Get.to(Signupoutpage()),
                            icon: const Icon(Icons.person_add_alt_1_outlined,
                                color: Colors.black, size: 25),
                            label: const Text("S'inscrire gratuitement",
                                style: TextStyle(
                                    color: Colors.black, fontSize: 17)),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 90, vertical: 14),
                              backgroundColor: colors.color,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              side: BorderSide(color: colors.white, width: 2),
                            ),
                            onPressed: () => Get.to(Loginoutpage()),
                            icon: const Icon(Icons.login_outlined,
                                color: Colors.white, size: 23),
                            label: const Text("Se connecter",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 17)),
                          ),

                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────── NOUVELLE SECTION : APERÇU DES PRODUITS ──────────────
  Widget _productPreviewSection(bool isMobile, double width, double aspectRatio) {
    // On utilise Get.find pour récupérer l'instance du ProductController
    final ProductController productController = Get.find<ProductController>();

    return Container(
      key: _productSectionKey, // Assigne la GlobalKey ici pour le défilement
      padding: EdgeInsets.symmetric(vertical: 0, horizontal: isMobile ? 20 : 80),
      color: colors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Découvrez nos produits",
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 24 : 32,
              fontWeight: FontWeight.bold,
              color: colors.color,
            ),
            textAlign: isMobile ? TextAlign.center : TextAlign.left,
          ),
          const SizedBox(height: 20),
          Obx(() {
            // Utilisation du nouveau getter landingPageProducts
            final List<ProductModel> previewProducts = productController.landingPageProducts;

            if (productController.isLoading.value && previewProducts.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (previewProducts.isEmpty) {
              return const Center(child: Text("Aucun produit disponible pour le moment."));
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(), // Empêche le défilement interne du GridView
              itemCount: previewProducts.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isMobile ? 2 : 3, // 2 colonnes sur mobile, 3 sur desktop pour afficher 6 produits
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: aspectRatio, // Ajustez si vos cartes de produits ont un ratio différent
              ),
              itemBuilder: (context, index) {
                final product = previewProducts[index];
                return _productCardPreview(product, isMobile, width);
              },
            );
          }),
          const SizedBox(height: 15),
          Center(
            child: ElevatedButton(
              onPressed: () {
                // Affiche un message pour se connecter ou créer un compte
                Get.snackbar(
                  'Accès limité',
                  'Veuillez vous connecter ou créer un compte pour voir tous les produits.',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: colors.color.withOpacity(0.8),
                  colorText: Colors.white,
                  duration: const Duration(seconds: 3),
                  mainButton: TextButton(
                    onPressed: () {
                      Get.to(Loginoutpage()); // Navigue vers la page de connexion
                    },
                    child: const Text('Se connecter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
              child: const Text("Voir tous les produits"),
            ),
          
          ),
          SizedBox(height: isMobile ? 20 : 35),
        ],
      ),
    );
  }

  // ────────────── WIDGET CARTE PRODUIT SIMPLIFIÉE POUR L'APERCU ──────────────
  Widget _productCardPreview(ProductModel product, bool isMobile, double width) {
    final bool isBoosted = product.boostExpiresAt?.isAfter(DateTime.now()) ?? false;

    return GestureDetector(
      onTap: () {
        // Affiche un message pour se connecter ou créer un compte
        Get.snackbar(
          'Accès limité',
          'Veuillez vous connecter ou créer un compte pour voir les détails des produits.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: colors.color.withOpacity(0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          mainButton: TextButton(
            onPressed: () {
              Get.to(Loginoutpage()); // Navigue vers la page de connexion
            },
            child: const Text('Se connecter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: isBoosted ? BorderSide(color: Colorsdata().buttonHover, width: 2) : BorderSide.none, // Bordure pour le boost
        ),
        elevation: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                  child: Image.network(
                    product.imageUrls.isNotEmpty
                        ? product.imageUrls.first
                        : 'https://via.placeholder.com/150',
                    height: width < 600 ? 155 : 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                if (isBoosted) // NOUVEAU: Badge "BOOSTÉ"
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colorsdata().buttonHover,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        'BOOSTÉ',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colorsdata().background,
                    ),
                    onPressed: () async {
                      // Affiche un message pour se connecter ou créer un compte
                    Get.snackbar(
                      'Accès limité',
                      'Veuillez vous connecter ou créer un compte pour voir les détails des produits.',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: colors.color.withOpacity(0.8),
                      colorText: Colors.white,
                      duration: const Duration(seconds: 3),
                      mainButton: TextButton(
                        onPressed: () {
                          Get.to(Loginoutpage()); // Navigue vers la page de connexion
                        },
                        child: const Text('Se connecter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    );
                    },
                    icon: Icon(Icons.favorite_border_outlined,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.title,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: width < 600 ? 12.5 : 14)),
                  Text("${product.price.toStringAsFixed(2)} ${product.currency ?? 'FC'}",
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                          fontSize: width < 600 ? 15 : 17,
                          fontWeight: FontWeight.bold,
                          color: Colorsdata().buttonHover)),
                  Text(product.size ?? "Non spécifiée",
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                          fontSize: width < 600 ? 12.5 : 14,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 3),
                  Text(
                    product.storeName ?? 'Boutique inconnue',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                        fontSize: width < 600 ? 13 : 15,
                        color: Colors.black,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "par ${product.ownerName ?? 'Utilisateur inconnu'}",
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                        fontSize: width < 600 ? 12 : 14, color: Colors.grey[700]),
                  ),
                  SizedBox(height: 10,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                        IconButton(
                          onPressed: () {
                           // Affiche un message pour se connecter ou créer un compte
                          Get.snackbar(
                            'Accès limité',
                            'Veuillez vous connecter ou créer un compte pour voir les détails des produits.',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: colors.color.withOpacity(0.8),
                            colorText: Colors.white,
                            duration: const Duration(seconds: 3),
                            mainButton: TextButton(
                              onPressed: () {
                                Get.to(Loginoutpage()); // Navigue vers la page de connexion
                              },
                              child: const Text('Se connecter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          );
                          },
                          icon: Icon(Icons.shopping_cart_outlined, size: 16, color: Colors.white),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colorsdata().primaryColor,
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      const SizedBox(width: 5), // Espace entre le bouton Boost/Panier et les vues
                      Row(
                        children: [
                          Icon(Icons.remove_red_eye,
                              size: width < 600 ? 14 : 16, color: Colors.grey),
                          const SizedBox(width: 5),
                          Text("${product.viewers.length}",
                              style: TextStyle(fontSize: width < 600 ? 11 : 12)),
                        ],
                      )
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),

      // Card(
      //   elevation: 3,
      //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      //   child: Column(
      //     crossAxisAlignment: CrossAxisAlignment.start,
      //     children: [
      //       ClipRRect(
      //         borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      //         child: Image.network(
      //           product.imageUrls.isNotEmpty ? product.imageUrls.first : 'https://via.placeholder.com/150',
      //           height: isMobile ? 120 : 150, // Hauteur de l'image ajustée
      //           width: double.infinity,
      //           fit: BoxFit.cover,
      //         ),
      //       ),
      //       Padding(
      //         padding: const EdgeInsets.all(8.0),
      //         child: Column(
      //           crossAxisAlignment: CrossAxisAlignment.start,
      //           children: [
      //             Text(
      //               product.title,
      //               overflow: TextOverflow.ellipsis,
      //               maxLines: 1,
      //               style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: isMobile ? 14 : 16),
      //             ),
      //             Text(
      //               "${product.price.toStringAsFixed(2)} FC",
      //               overflow: TextOverflow.ellipsis,
      //               maxLines: 1,
      //               style: GoogleFonts.poppins(fontSize: isMobile ? 14 : 16, fontWeight: FontWeight.bold, color: colors.color),
      //             ),
      //             Text(
      //               product.storeName ?? 'Boutique inconnue',
      //               overflow: TextOverflow.ellipsis,
      //               maxLines: 1,
      //               style: GoogleFonts.poppins(fontSize: isMobile ? 12 : 14, color: Colors.grey[700]),
      //             ),
      //           ],
      //         ),
      //       ),
      //     ],
      //   ),
      // ),
    );
  }

  // ────────────── ABOUT ──────────────
  Widget _aboutSection(bool isMobile) {
    final content = Padding(
      padding:
          EdgeInsets.symmetric(horizontal: isMobile ? 20 : 100, vertical: 60),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (!isMobile)
            Expanded(
              child: Image.asset("assets/images/h.jpg", height: 300),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text("À propos de Tendance",
                    style: GoogleFonts.poppins(
                        fontSize: isMobile ? 24 : 32,
                        fontWeight: FontWeight.bold,
                        color: colors.color)),
                const SizedBox(height: 20),
                Text(
                  "Tendance simplifie le commerce digital en RDC. Créez vos boutiques, vendez vos articles, et rejoignez une communauté dynamique d’acheteurs et de vendeurs congolais.",
                  style: GoogleFonts.poppins(
                      fontSize: isMobile ? 15 : 17, height: 1.6),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return SectionReveal(
      index: 0,
      child: content,
      direction: SlideDirection.left,
    );
  }

  // ────────────── FEATURES ──────────────
  Widget _featuresSection(bool isMobile) {
    final featureData = [
      ["Créez plusieurs boutiques", "Organisez vos produits selon vos marques ou catégories.", Icons.store],
      ["Achat & vente rapides", "Publiez vos annonces et trouvez des clients en un clic.", Icons.shopping_cart_outlined],
      ["Messagerie intégrée", "Discutez directement avec vos clients.", Icons.chat_bubble_outline],
      ["Classez vos produits", "Une interface intuitive pour gérer vos articles.", Icons.category],
    ];
    final content = Container(
      
      padding: EdgeInsets.symmetric(vertical: 80, horizontal: isMobile ? 20 : 80),
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: isMobile? BorderRadius.circular(15): null
      ),
      child: Column(
        children: [
          Text(
            "Fonctionnalités principales",
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 24 : 30,
              fontWeight: FontWeight.bold,
              color: colors.color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: List.generate(featureData.length, (index) {
              final item = featureData[index];
              return AnimatedFeatureCard(
                index: index,
                icon: item[2] as IconData,
                title: item[0] as String,
                desc: item[1] as String,
              );
            }),
          ),
        ],
      ),
    );
    return SectionReveal(
      index: 1,
      child: content,
      direction: SlideDirection.up,
    );
  }

  // ────────────── WHY CHOOSE ──────────────
  Widget _whyChooseSection(bool isMobile) {
    final reasons = [
      ["Sécurisée", "Vos données et transactions sont protégées.", Icons.lock_outline],
      ["Rapide", "Publiez et recevez des offres instantanément.", Icons.flash_on],
      ["Communautaire", "Une large communauté d’acheteurs et de vendeurs.", Icons.people_outline],
    ];
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 30),
      child: Column(
        children: [
          Text("Pourquoi choisir Tendance ?",
              style: GoogleFonts.poppins(
                  fontSize: isMobile ? 24 : 30,
                  fontWeight: FontWeight.bold,
                  color: colors.color),
              textAlign: TextAlign.center),
          const SizedBox(height: 50),
          Wrap(
            spacing: 50,
            runSpacing: 50,
            alignment: WrapAlignment.center,
            children: List.generate(reasons.length, (index) {
              final r = reasons[index];
              return AnimatedReasonCard(
                index: index,
                icon: r[2] as IconData,
                title: r[0] as String,
                desc: r[1] as String,
              );
            }),
          ),
        ],
      ),
    );
    return SectionReveal(
      index: 2,
      child: content,
      direction: SlideDirection.right,
    );
  }

  // ────────────── CTA ──────────────
  Widget _ctaSection(bool isMobile) {
    final content = Stack(
      children: [
        Positioned.fill(
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(
                colors.color.withOpacity(0.6), BlendMode.srcOver),
            child: Image.asset("assets/images/g.jpg", fit: BoxFit.cover),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 20),
          child: Center(
            child: Column(
              children: [
                Text("Rejoignez la communauté Tendance",
                    style: TextStyle(
                        fontSize: isMobile ? 26 : 38,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                    textAlign: TextAlign.center),
                const SizedBox(height: 20),
                Text(
                  "Créez votre première boutique et commencez à vendre vos produits dès aujourd’hui.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: isMobile ? 16 : 20, color: Colors.white70),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: colors.color,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 35, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: () => Get.to(Signupoutpage()),
                  child: const Text("Commencer maintenant",
                      style: TextStyle(fontSize: 18)),
                ),

                const SizedBox(height: 12),
                NotificationButton(),
                const SizedBox(height: 12),
                DownloadApkButton(), // Bouton de téléchargement APK

                
              ],
            ),
          ),
        ),
      ],
    );
    return SectionReveal(
      index: 3,
      child: content,
      direction: SlideDirection.up,
    );
  }

  // ────────────── FOOTER ──────────────
  Widget _footerSection(bool isMobile) {
    final content = Container(
      width: double.infinity,
      color: colors.color,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 40,
            children: [
              Text("© ${DateTime.now().year} Tendance. Tous droits réservés.",
                  style: GoogleFonts.poppins(
                      color: Colors.white70, fontSize: 14)),
              Text("Conçu avec ❤️ en RDC",
                  style: GoogleFonts.poppins(
                      color: Colors.white70, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 20,
            children: const [
              Icon(Icons.facebook, color: Colors.white),
              Icon(Icons.alternate_email, color: Colors.white),
              Icon(Icons.phone, color: Colors.white),
            ],
          )
        ],
      ),
    );
    return SectionReveal(
      index: 4,
      child: content,
      direction: SlideDirection.up,
    );
  }

  // ────────────── FEATURE CARD ──────────────
  Widget _featureCard(IconData icon, String title, String desc) {
    return Card(
      color: colors.background,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            Icon(icon, size: 45, color: colors.color),
            const SizedBox(height: 15),
            Text(title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.color)),
            const SizedBox(height: 10),
            Text(desc,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 15, color: Colors.black54, height: 1.4)),
          ],
        ),
      ),
    );
  }

  // ────────────── REASON CARD ──────────────
  Widget _reasonCard(IconData icon, String title, String desc) {
    return SizedBox(
      width: 260,
      child: Column(
        children: [
          Transform.rotate(
              angle: pi / 20, child: Icon(icon, size: 60, color: colors.color)),
          const SizedBox(height: 15),
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.color)),
          const SizedBox(height: 10),
          Text(desc,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 15, color: Colors.black54, height: 1.5)),
        ],
      ),
    );
  }
}

/* ============================
    WRAPPERS & ANIMATED ITEMS
    ============================ */

enum SlideDirection { up, left, right, down }

class SectionReveal extends StatefulWidget {
  final Widget child;
  final int index;
  final SlideDirection direction;
  final Duration duration;
  final double visibleThreshold; // fraction required to trigger
  const SectionReveal({
    super.key,
    required this.child,
    required this.index,
    this.direction = SlideDirection.up,
    this.duration = const Duration(milliseconds: 700),
    this.visibleThreshold = 0.15,
  });

  @override
  State<SectionReveal> createState() => _SectionRevealState();
}

class _SectionRevealState extends State<SectionReveal> {
  bool _visible = false;
  Offset _offsetForDirection(SlideDirection dir) {
    switch (dir) {
      case SlideDirection.left:
        return const Offset(-0.08, 0);
      case SlideDirection.right:
        return const Offset(0.08, 0);
      case SlideDirection.down:
        return const Offset(0, 0.08);
      case SlideDirection.up:
      default:
        return const Offset(0, 0.08);
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('section_reveal_${widget.index}'),
      onVisibilityChanged: (info) {
        if (!_visible && info.visibleFraction > widget.visibleThreshold) {
          setState(() => _visible = true);
        }
      },
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        child: AnimatedSlide(
          offset: _visible ? Offset.zero : _offsetForDirection(widget.direction),
          duration: widget.duration,
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      )
    );
  }
}

/// AnimatedFeatureCard: chaque carte a sa propre VisibilityDetector + delay basé sur index
class AnimatedFeatureCard extends StatefulWidget {
  final int index;
  final IconData icon;
  final String title;
  final String desc;
  const AnimatedFeatureCard({
    super.key,
    required this.index,
    required this.icon,
    required this.title,
    required this.desc,
  });

  @override
  State<AnimatedFeatureCard> createState() => _AnimatedFeatureCardState();
}

class _AnimatedFeatureCardState extends State<AnimatedFeatureCard> {
  bool _shown = false;
  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('feature_card_${widget.index}'),
      onVisibilityChanged: (info) {
        if (!_shown && info.visibleFraction > 0.12) {
          Future.delayed(Duration(milliseconds: widget.index * 120), () {
            if (mounted) setState(() => _shown = true);
          });
        }
      },
      child: AnimatedOpacity(
        opacity: _shown ? 1 : 0,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeOut,
        child: AnimatedSlide(
          offset: _shown ? Offset.zero : const Offset(0, 0.06),
          duration: const Duration(milliseconds: 550),
          curve: Curves.easeOut,
          child: Card(
            color: Colors.white,
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              width: 280,
              padding: const EdgeInsets.all(25),
              child: Column(
                children: [
                  Icon(widget.icon, size: 45, color: Colors.blue[800]),
                  const SizedBox(height: 15),
                  Text(widget.title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800])),
                  const SizedBox(height: 10),
                  Text(widget.desc,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                          fontSize: 15, color: Colors.black54, height: 1.4)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// AnimatedReasonCard: fonction similaire pour les raisons
class AnimatedReasonCard extends StatefulWidget {
  final int index;
  final IconData icon;
  final String title;
  final String desc;
  const AnimatedReasonCard({
    super.key,
    required this.index,
    required this.icon,
    required this.title,
    required this.desc,
  });

  @override
  State<AnimatedReasonCard> createState() => _AnimatedReasonCardState();
}

class _AnimatedReasonCardState extends State<AnimatedReasonCard> {
  bool _shown = false;
  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('reason_card_${widget.index}'),
      onVisibilityChanged: (info) {
        if (!_shown && info.visibleFraction > 0.12) {
          Future.delayed(Duration(milliseconds: widget.index * 160), () {
            if (mounted) setState(() => _shown = true);
          });
        }
      },
      child: AnimatedOpacity(
        opacity: _shown ? 1 : 0,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeOut,
        child: AnimatedSlide(
          offset: _shown ? Offset.zero : const Offset(0, 0.06),
          duration: const Duration(milliseconds: 550),
          curve: Curves.easeOut,
          child: SizedBox(
            width: 260,
            child: Column(
              children: [
                Transform.rotate(
                    angle: pi / 20,
                    child: Icon(widget.icon, size: 60, color: Colors.blue[800])),
                const SizedBox(height: 15),
                Text(widget.title,
                    style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800])),
                const SizedBox(height: 10),
                Text(widget.desc,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        fontSize: 15, color: Colors.black54, height: 1.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

