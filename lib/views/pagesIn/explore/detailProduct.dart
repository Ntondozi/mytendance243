import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:tendance/expandableTextWidget.dart';
import 'package:tendance/views/pagesIn/explore/fullSreenImage.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import pour currentUser
import '../../../controlers/cartController.dart';
import '../../../controlers/navControler.dart';
import '../../../controlers/productControler.dart';
import '../../../models/productModel.dart';
import '../../../controlers/ColorsData.dart';
import '../../../models/navIds.dart';
import '../messages/messagesPage.dart';
import 'boostPage.dart';

class Detailproduct extends StatefulWidget {
  final ProductModel product;
  Detailproduct({super.key, required this.product});
  @override
  State<Detailproduct> createState() => _DetailproductState();
}

class _DetailproductState extends State<Detailproduct> {
  final ProductController productController = Get.put(ProductController());
  int _currentImageIndex = 0;
  final CartController cartController = Get.find<CartController>();
  final navController = Get.find<NavigationInController>();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    double adaptiveSize(double small, double medium, double large) {
      if (width <= 500) return small;
      if (width <= 900) return medium;
      return large;
    }

    final indexNav = navController.selectedIndex.value;
    bool navId = false; // Ce 'navId' semble lié à la navigation principale (explore, favoris, messages)
    if (indexNav < 3 ) { // Index 0, 1, 2 sont explore, favoris, messages. Index 3 est dashboard.
      navId = true;
    }

    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final bool isOwner = currentUserId == widget.product.sellerId;
    final bool isBoosted = widget.product.boostExpiresAt?.isAfter(DateTime.now()) ?? false;

    return Scaffold(
      backgroundColor: Colorsdata().background,
      body: Column(
        children: [
          if(!kIsWeb) SizedBox(height: 35,) else SizedBox(),
          // HEADER
          Container(
            padding: EdgeInsets.all(adaptiveSize(width / 33, 20, 30)),
            color: Colorsdata().white,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              switch (navController.selectedIndex.value) {
                                case 0:
                                  Get.back(id: NavInIds.explorer);
                                  break;
                                case 1:
                                  Get.back(id: NavInIds.favoris);
                                  break;
                                case 2:
                                  Get.back(id: NavInIds.messages);
                                  break;
                                case 3: // Si on vient du dashboard, on fait simplement Get.back()
                                  Get.back();
                                  break;
                                default:
                                  print("Index inconnu: ${navController.selectedIndex.value}");
                              }
                            },
                            icon: Icon(Icons.arrow_back_ios),
                          ),
                          Text(
                            "Détails du produit",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: adaptiveSize(20, 24, 28),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    navId ? Obx(() {
                      final count = Get.find<CartController>().itemCount.value;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            icon: Icon(Icons.shopping_cart_outlined,
                                size: 30,
                                color: const Color.fromARGB(221, 79, 72, 72)),
                            onPressed: () {
                              final navController = Get.find<NavigationInController>();
                                switch (navController.selectedIndex.value) {
                                case 0:
                                  Get.toNamed('/ExploreInPage/cart', id: NavInIds.explorer);
                                  break;
                                case 1:
                                  Get.toNamed('/favoris/cart', id: NavInIds.favoris);
                                  break;
                                case 2:
                                  Get.toNamed('/message/back', id: NavInIds.messages);
                                  break;
                                case 3:
                                  Get.toNamed('/dashboard/back', id: NavInIds.dashboard);
                                  break;
                                default:
                                  print("Index inconnu: ${navController.selectedIndex.value}");
                                }
                            },
                          ),
                          if (count > 0)
                            Positioned(
                              right: 4,
                              top: 0,
                              child: Container(
                                padding: EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  count.toString(),
                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ),
                        ],
                      );
                    }) : SizedBox(),
                  ],
                ),
                SizedBox(height: adaptiveSize(height / 65, 15, 25)),
              ],
            ),
          ),
          // BODY
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ------------------ Carousel ------------------
                  if (widget.product.imageUrls.isNotEmpty)
                    Column(
                      children: [
                        CarouselSlider.builder(
                          itemCount: widget.product.imageUrls.length,
                          itemBuilder: (context, index, realIndex) {
                            final imgUrl = widget.product.imageUrls[index];
                            return GestureDetector(
                              onTap: () {
                                // ➤ Ouvre l'image en plein écran
                                Get.to(() => FullscreenImageViewer(
                                      imageUrls: widget.product.imageUrls,
                                      initialIndex: index,
                                    ));
                              },
                              child: Stack(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        image: NetworkImage(imgUrl),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  // Boost badge on image
                                  if (isBoosted)
                                    Positioned(
                                      top: 15,
                                      left: 15,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colorsdata().buttonHover,
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        child: Text(
                                          'BOOSTÉ',
                                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  // Favorite button
                                  Positioned(
                                    top: 15,
                                    right: 15,
                                    child: IconButton(
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.white.withOpacity(0.8),
                                      ),
                                      onPressed: () async {
                                        // Vérifiez que l'utilisateur est connecté avant de toggler le favori
                                        if (FirebaseAuth.instance.currentUser?.uid != null) {
                                          await productController.toggleFavorite(
                                            widget.product.id,
                                            FirebaseAuth.instance.currentUser!.uid,
                                          );
                                          setState(() {});
                                        } else {
                                          Get.snackbar('Connexion requise', 'Veuillez vous connecter pour ajouter aux favoris.', snackPosition: SnackPosition.BOTTOM);
                                        }
                                      },
                                      icon: Icon(
                                        widget.product.favorites
                                                .contains(productController.currentUserId.value)
                                            ? Icons.favorite
                                            : Icons.favorite_border_outlined,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                  // Condition label (e.g., "Neuf")
                                  Positioned(
                                    bottom: 15, // Changed position to bottom left for better visibility with boost badge
                                    left: 15,
                                    child: Container(
                                      padding:
                                          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.deepOrange,
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Text(
                                        widget.product.condition,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          options: CarouselOptions(
                            height: 300,
                            viewportFraction: 1.0,
                            autoPlay: true, // ✅ défilement automatique
                            autoPlayInterval: const Duration(seconds: 4),
                            autoPlayAnimationDuration: const Duration(milliseconds: 800),
                            enableInfiniteScroll: true,
                            onPageChanged: (index, reason) {
                              setState(() {
                                _currentImageIndex = index;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        AnimatedSmoothIndicator(
                          activeIndex: _currentImageIndex,
                          count: widget.product.imageUrls.length,
                          effect: ExpandingDotsEffect(
                            activeDotColor: Colors.deepOrange,
                            dotHeight: 8,
                            dotWidth: 8,
                            expansionFactor: 3,
                          ),
                        ),
                      ],
                    )
                  else
                    Container(
                      width: double.infinity,
                      height: 300,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/a.jpg'), // Fallback image
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  SizedBox(height: 8),
                  // ------------------ Infos produit ------------------
                  Padding(padding: EdgeInsets.only(left: 15, right: 15, top: 15, bottom: 15),
                      child: SizedBox(
                        width: 500,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ExpandableTextWidget(text: widget.product.title),
                            SizedBox(height: 8,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text("${widget.product.price.toStringAsFixed(2)} ${widget.product.currency ?? 'FC'}",
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: Colorsdata().buttonHover),),
                                SizedBox(width: 15,),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(widget.product.condition,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: width < 600 ? 12 : 13,
                                      fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            SizedBox(height: 8,),
                            SizedBox(
                              width: double.infinity,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Catégorie :', style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal),),
                                        Text(widget.product.category,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),),
                                        SizedBox(height: 8,),
                                        Text('Couleur :',
                                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal),),
                                        Text(widget.product.color?? "Non spécifiée",
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),)
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 20,),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Taille :', style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal),),
                                        Text(widget.product.size?? "Non specifiée",
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),),
                                        SizedBox(height: 8,),
                                        Text('Marque :', style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal),),
                                        Text(widget.product.brand ?? 'Non spécifiée',
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),)
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ),
                  Padding(padding: EdgeInsets.only(left: 15, right: 15, bottom: 15,),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Déscription', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),),
                        SizedBox(height: 8,),
                        ExpandableTextWidgetDescript(text: widget.product.description ),
                        SizedBox(height: 8,),
                        
                        Container(
                          padding: EdgeInsets.all(15),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(7),
                            color: Colorsdata().white
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    height: 50,
                                    width: 50,
                                    child: CircleAvatar(
                                      backgroundColor: Colorsdata().background,
                                      child: Icon(Icons.store, color: Colorsdata().buttonHover, size: 30,)),
                                  ),
                                  SizedBox(width: 8,),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(widget.product.storeName ?? 'Non spécifiée', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),),
                                      Text(widget.product.ownerName?? 'Non spécifié', style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),),
                                    ],
                                  )
                                ],
                              ),
                              SizedBox(height: 12,),
                              // "Voir la boutique" button
                              if (navId) // N'affiche que si nous sommes dans un contexte de navigation générale, pas le tableau de bord
                                Row(children: [
                                  TextButton(
                                    onPressed: () {
                                      final navController = Get.find<NavigationInController>();
                                      switch (navController.selectedIndex.value) {
                                        case 0:
                                          Get.toNamed(
                                            '/ExploreInPage/storeDetail',
                                            arguments: {
                                              'storeId': widget.product.storeId,
                                              'sellerId': widget.product.sellerId,
                                            },
                                            id: NavInIds.explorer,
                                          );
                                          break;
                                        case 1:
                                          Get.toNamed(
                                            '/favoris/storeDetail',
                                            arguments: {
                                              'storeId': widget.product.storeId,
                                              'sellerId': widget.product.sellerId,
                                            },
                                            id: NavInIds.favoris,
                                          );
                                          break;
                                        case 2:
                                          Get.toNamed(
                                            '/message/storeDetail',
                                            arguments: {
                                              'storeId': widget.product.storeId,
                                              'sellerId': widget.product.sellerId,
                                            },
                                            id: NavInIds.messages,
                                          );
                                          break;
                                        default:
                                          print("Index inconnu: ${navController.selectedIndex.value}");
                                      }
                                    },
                                    child: Row(
                                      children: [
                                        Text('Voir la boutique', style: TextStyle(color: Colorsdata().buttonHover)),
                                      ],
                                    ),
                                  ), Icon(Icons.arrow_right_outlined, color: Colorsdata().buttonHover,)
                                ]),
                            ],
                          ),
                        ),
                        // Action buttons at the very bottom
                        SizedBox(height: 15,),
                        if (isOwner && !isBoosted) // Afficher le bouton Booster si propriétaire et non boosté
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.only(bottom: 7.5),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colorsdata().primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                              ),
                              onPressed: () {
                                Get.to(() => BoostPage(
                                  targetId: widget.product.id,
                                  targetType: 'product',
                                  targetName: widget.product.title,
                                ));
                              },
                              icon: Icon(Icons.rocket_launch),
                              label: Text("Booster ce produit", style: TextStyle(fontSize: 15)),
                            ),
                          )else if (isOwner && isBoosted) // Afficher le statut Boosté si propriétaire et déjà boosté
                          
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Statut Boost: ${widget.product.boostLevel} (actif)',
                                      style: TextStyle(color: Colors.green, fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                                    if (widget.product.boostExpiresAt != null)
                                      Text(
                                        'Expire le: ${DateFormat("d MMMM yyyy à HH:mm", "fr_FR").format(widget.product.boostExpiresAt!)}',
                                        style: TextStyle(color: Colors.green, fontSize: 12),
                                      ),
                                  ],
                                ),
                              ),
                         if (!isOwner) // Afficher Ajouter au panier si non propriétaire
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.only(bottom: 7.5),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepOrangeAccent, // Couleur préférée pour Ajouter au panier
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                              ),
                              onPressed: () async {
                                try {
                                  await cartController.addToCart(widget.product);
                                  Get.snackbar(
                                    "Panier",
                                    "Produit ajouté au panier",
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: Colors.green.withOpacity(0.2),
                                  );
                                } catch (e) {
                                  Get.snackbar(
                                    "Erreur",
                                    "Impossible d'ajouter le produit au panier",
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: Colors.red.withOpacity(0.2),
                                  );
                                  print("Erreur ajout panier : $e");
                                }
                              },
                              icon: Icon(Icons.shopping_cart_outlined),
                              label: Text("Ajouter au panier", style: TextStyle(fontSize: 15)),
                            ),
                          ),
                        if (!isOwner) // Afficher Contacter le vendeur si non propriétaire
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.only(bottom: 15, top: 7.5),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colorsdata().background,
                                foregroundColor: Colors.black, // Couleur du texte pour Contacter le vendeur
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                              ),
                              onPressed: () {
                                if (widget.product.sellerId != null) {
                                  Get.to(() => ChatPage(
                                    receiverId: widget.product.sellerId!,
                                    receiverName: widget.product.ownerName ?? 'Vendeur',
                                  ));
                                }
                              },
                              icon: Icon(Icons.chat_outlined, color: Colorsdata().buttonHover),
                              label: Text("Contacter le vendeur", style: TextStyle(fontSize: 15)),
                            ),
                          ),
                        SizedBox(height: 15,),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              child: Row(children: [
                                Icon(Icons.remove_red_eye_outlined, size: 13,),
                                SizedBox(width: 5,),
                                Text("${widget.product.viewers.length}", style: TextStyle(color: Colors.black, fontSize: 13))
                              ],),
                            ),
                            SizedBox(
                              child: Row(children: [
                                Icon(Icons.calendar_month_outlined, size: 13,),
                                SizedBox(width: 4,),
                                Text("Publié le ", style: TextStyle(color: Colors.black, fontSize: 13)),
                                Text(widget.product.createdAt != null
                                ? DateFormat("d MMMM yyyy", "fr_FR").format(widget.product.createdAt!)
                                : "Date inconnue",style: TextStyle(color: Colors.black, fontSize: 13))
                              ],),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20,)
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ExpandableTextWidgetDescript extends StatefulWidget {
  final String text;
  final int maxLines;

  const ExpandableTextWidgetDescript({super.key, required this.text, this.maxLines = 3});

  @override
  State<ExpandableTextWidgetDescript> createState() => _ExpandableTextWidgetDescriptState();
}

class _ExpandableTextWidgetDescriptState extends State<ExpandableTextWidgetDescript> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final span = TextSpan(
        text: widget.text,
        style: const TextStyle(fontSize: 14, color: Colors.black),
      );
      final tp = TextPainter(
        text: span,
        maxLines: widget.maxLines,
        textDirection: ui.TextDirection.ltr,
      )..layout(maxWidth: constraints.maxWidth);

      final isOverflow = tp.didExceedMaxLines;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.text,
            style: const TextStyle(fontSize: 14,),
            textAlign: TextAlign.justify,
            maxLines: isExpanded ? null : widget.maxLines,
            overflow: TextOverflow.fade,
          ),
          if (isOverflow)
            GestureDetector(
              onTap: () {
                setState(() {
                  isExpanded = !isExpanded;
                });
              },
              child: Text(
                isExpanded ? "moins" : "...plus",
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.normal),
              ),
            ),
        ],
      );
    });
  }
}
