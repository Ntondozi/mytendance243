
import 'dart:math';

import 'package:flutter/material.dart';

// --- Imports des packages ---
import 'package:animate_do/animate_do.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:visibility_detector/visibility_detector.dart';

// --- Imports de votre projet (Vérifiez les chemins !) ---
import 'package:tendance/controlers/productControler.dart';
import 'package:tendance/models/productModel.dart';
import 'package:tendance/controlers/ColorsData.dart';
import 'package:tendance/controlers/subscription_controller.dart';
import 'package:tendance/notification_settings.dart';
import 'package:tendance/views/pagesOut/loginOutPage.dart';
import 'package:tendance/views/pagesOut/signupOutPage.dart';


// NOTE: Les imports spécifiques au web comme 'dart:js' et 'pwa_install' ont été retirés.

class LandingPageTendance extends StatefulWidget {
  const LandingPageTendance({super.key});

  @override
  State<LandingPageTendance> createState() => _LandingPageTendanceState();
}

class _LandingPageTendanceState extends State<LandingPageTendance> {
  double scrollPosition = 0.0;
  final colors = Colorsdata();
  final scrollController = ScrollController();
  final GlobalKey _productSectionKey = GlobalKey();

  // --- Contrôleurs nécessaires pour la logique métier sur mobile ---
  final ProductController productController = Get.put(ProductController());
  final SubscriptionController subController = Get.put(SubscriptionController());

  @override
  void initState() {
    super.initState();
    print('DEBUG: initState called for LandingPageTendance (MOBILE).');
    // La logique PWA est retirée, on garde le reste.
    subController.checkNotificationStatus();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 700;
    final width = MediaQuery.of(context).size.width;

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
                  _aboutSection(isMobile),
                  _featuresSection(isMobile),
                  _whyChooseSection(isMobile),
                  _productPreviewSection(isMobile, width), // Maintenu pour afficher les produits
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
        height: 100,
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 80,),
        
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
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
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
                      label: const Text("Explorer", style: TextStyle(fontSize: 17, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.color.withOpacity(0.8),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                      ),
                    )
                  : const SizedBox.shrink(),
              if (!isMobile)
                Row(
                  children: [
                    _menuItem("Accueil", () => _scrollTo(0)),
                    _menuItem("Fonctionnalités", () => _scrollTo(800)),
                    _menuItem("Contact", () => _scrollTo(3000)),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: () => Get.to(() => Loginoutpage()),
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
            ],
          ),
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
                            onPressed: () => Get.to(() => Signupoutpage()),
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
                            onPressed: () => Get.to(() => Loginoutpage()),
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

  // ────────────── PRODUCT PREVIEW SECTION ──────────────
  Widget _productPreviewSection(bool isMobile, double width) {
    return Container(
      key: _productSectionKey,
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
            final List<ProductModel> previewProducts = productController.landingPageProducts;
            if (productController.isLoading.value && previewProducts.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (previewProducts.isEmpty) {
              return const Center(child: Text("Aucun produit disponible pour le moment."));
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: previewProducts.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isMobile ? 2 : 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: isMobile ? 0.46 : 0.9,
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
                Get.snackbar(
                  'Accès limité',
                  'Veuillez vous connecter ou créer un compte pour voir tous les produits.',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: colors.color.withOpacity(0.8),
                  colorText: Colors.white,
                  duration: const Duration(seconds: 3),
                  mainButton: TextButton(
                    onPressed: () => Get.to(() => Loginoutpage()),
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

  // ────────────── PRODUCT CARD PREVIEW ──────────────
  Widget _productCardPreview(ProductModel product, bool isMobile, double width) {
    final bool isBoosted = product.boostExpiresAt?.isAfter(DateTime.now()) ?? false;
    return GestureDetector(
      onTap: () {
        Get.snackbar(
          'Accès limité',
          'Veuillez vous connecter ou créer un compte pour voir les détails des produits.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: colors.color.withOpacity(0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          mainButton: TextButton(
            onPressed: () => Get.to(() => Loginoutpage()),
            child: const Text('Se connecter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: isBoosted ? BorderSide(color: colors.buttonHover, width: 2) : BorderSide.none,
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
                if (isBoosted)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.buttonHover,
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
                      backgroundColor: colors.background,
                    ),
                    onPressed: () async {
                      Get.snackbar(
                        'Accès limité',
                        'Veuillez vous connecter ou créer un compte pour voir les détails des produits.',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: colors.color.withOpacity(0.8),
                        colorText: Colors.white,
                        duration: const Duration(seconds: 3),
                        mainButton: TextButton(
                          onPressed: () => Get.to(() => Loginoutpage()),
                          child: const Text('Se connecter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      );
                    },
                    icon: Icon(Icons.favorite_border_outlined, color: Colors.red),
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
                          color: colors.buttonHover)),
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
                           Get.snackbar(
                            'Accès limité',
                            'Veuillez vous connecter ou créer un compte pour voir les détails des produits.',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: colors.color.withOpacity(0.8),
                            colorText: Colors.white,
                            duration: const Duration(seconds: 3),
                            mainButton: TextButton(
                              onPressed: () => Get.to(() => Loginoutpage()),
                              child: const Text('Se connecter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          );
                        },
                        icon: Icon(Icons.shopping_cart_outlined, size: 16, color: Colors.white),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primaryColor,
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 5),
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
                  onPressed: () => Get.to(() => Signupoutpage()),
                  child: const Text("Commencer maintenant",
                      style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(height: 12),
                NotificationButton(), // Conservé pour le mobile
                
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
}

// ============================
//   WRAPPERS & ANIMATED ITEMS
// ============================
enum SlideDirection { up, left, right, down }

class SectionReveal extends StatefulWidget {
  final Widget child;
  final int index;
  final SlideDirection direction;
  final Duration duration;
  final double visibleThreshold;

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
      ),
    );
  }
}

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