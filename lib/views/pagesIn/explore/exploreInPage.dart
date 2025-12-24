// file: lib/views/pagesIn/exploreinpage.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tendance/controlers/String.dart';
import 'package:tendance/controlers/authControler.dart';
import 'package:tendance/models/productModel.dart';
import 'package:tendance/views/pagesIn/explore/boostPage.dart';
import '../../../controlers/cartController.dart';
import '../../../controlers/navControler.dart';
import '../../../controlers/productControler.dart';
import '../../../controlers/subscription_controller.dart';
import '../../../controlers/trieController.dart';
// import '../../../models/boostPlanModel.dart'; // N'est plus nécessaire ici car BoostPage gère les plans
import '../../../models/navIds.dart';
import '../../../controlers/ColorsData.dart';
import 'detailProduct.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import pour vérifier l'utilisateur actuel

class Exploreinpage extends StatefulWidget {
  const Exploreinpage({super.key});

  @override
  State<Exploreinpage> createState() => _ExploreinpageState();
}

class _ExploreinpageState extends State<Exploreinpage> {
  final ProductController productController = Get.put(ProductController());
  final SubscriptionController subCtrl = Get.find<SubscriptionController>(); // Utilisez Get.find()
  final TrierController T = Get.put(TrierController()); // Initialisez le contrôleur ici ou dans initState
  final AuthController controller = Get.find();
   final navController = Get.find<NavigationInController>();

  String? selectedCategoryValue;
  String? selectedConditionValue;
  String? selectedSortValue;
  int currentPage = 1;
  final int itemsPerPage = 20;
  
  final List<String> categories = [
    'Accessoires',
    'Chaussures',
    'Sacs',
    'Vêtements',
    'Autre'
  ];
  final List<String> conditions = [
    'Neuf',
    'Occasion',
    'Excellent état',
    'Bon état',
    'État correct',
    'Usé',
    'Autre'
  ];
  final List<String> sortOptions = [
    'Meilleur score',
    'Prix croissant',
    'Prix décroissant',
    'Plus récents',
    'Aléatoire',
  ];

  final TextEditingController minPriceController =
      TextEditingController(text: '0');
  final TextEditingController maxPriceController =
      TextEditingController(text: '1000000');
  
  // ⚠️ TRÈS IMPORTANT: Ces variables ne sont plus nécessaires ici.
  // La logique de sélection des plans de boost et les détails des plans
  // sont désormais gérés par la BoostPage et le SubscriptionController.
  // String? _selectedBoostLevel;
  // final List<String> _boostLevels = ['petit', 'moyen', 'grand'];
  // final List<Duration> _boostDurations = [
  //   const Duration(days: 7),
  //   const Duration(days: 15),
  //   const Duration(days: 30),
  // ];
  // final List<int> _boostAmounts = [1000, 2000, 3000];

  @override
  void initState() {
    super.initState();
    // Assurez-vous d'initialiser selectedSortValue pour qu'il ne soit pas null
    // s'il n'y a pas de valeur existante dans le contrôleur.
    selectedCategoryValue = productController.selectedCategory?.value.isEmpty ?? true ? null : productController.selectedCategory?.value;
    selectedConditionValue = productController.selectedCondition?.value.isEmpty ?? true ? null : productController.selectedCondition?.value;
    selectedSortValue = productController.sortBy.value; // Par défaut 'Meilleur score' via ProductController
    minPriceController.text = productController.minPrice.value.toString();
    maxPriceController.text = productController.maxPrice.value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

        double aspectRatio;

      if (width >= 1090) {
        aspectRatio = 0.60;
      } 
      else
      if (width >= 1032) {
        aspectRatio = 0.60;
      } 
      else
      if (width >= 992) {
        aspectRatio = 0.58;
      } 
      else
      if (width >= 866) {
        aspectRatio = 0.69;
      } 
      else
      if (width >= 798) {
        aspectRatio = 0.64;
      } 
      else
      if (width >= 767.5) {
        aspectRatio = 0.66;
      } 
      else if (width >= 730) {
        aspectRatio = 0.95;
      } 
      else
      if (width >= 680) {
        aspectRatio = 0.92;
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
        aspectRatio = 0.72;
      } 
      else
      if (width >= 511) {
        aspectRatio = 0.69;
      } 
      else
      if (width >= 498) {
        aspectRatio = 0.66;
      } 
      else
      if (width >= 480) {
        aspectRatio = 0.70;
      } 
      else
      if (width >= 466) {
        aspectRatio = 0.66;
      } 
      else
      if (width >= 450) {
        aspectRatio = 0.64;
      } 
      else if (width >= 434) { // 435–449
        aspectRatio = 0.62;
      }else if (width >= 420) {  // 420–434
        aspectRatio = 0.59;
      } 
      else if (width >= 405) {  // 405–419
        aspectRatio = 0.57;
      } 
      else if (width >= 390) {  // 390–404
        aspectRatio = 0.55;
      } 
      else if (width >= 375) {  // 375–389
        aspectRatio = 0.52;
      } 
      else if (width >= 360) {  // 360–374
        aspectRatio = 0.50;
      } 
      else if (width >= 345) {  // 345–359
        aspectRatio = 0.48;
      } 
      else if (width >= 330) {  // 330–344
        aspectRatio = 0.46;
      } 
      else if (width >= 315) {  // 315–329
        aspectRatio = 0.43;
      } 
      else if (width >= 300) {  // 300–314
        aspectRatio = 0.41;
      } 
      else if (width >= 285) {  // 285–299
        aspectRatio = 0.38;
      } 
      else if (width >= 270) {  // 270–284
        aspectRatio = 0.36;
      } 
      else if (width >= 255) {  // 255–269
        aspectRatio = 0.34;
      } 
      else if (width >= 240) {  // 240–254
        aspectRatio = 0.32;
      } 
      else if (width >= 225) {  // 225–239
        aspectRatio = 0.29;
      }
      else {  // <225px
        aspectRatio = 0.27;
      }


    double adaptiveSize(double small, double medium, double large) {
      if (width <= 500) return small;
      if (width <= 900) return medium;
      return large;
    }
    print("Rebuilding ExploreInPage with width: $width");
  
    return Scaffold(
      backgroundColor: Colorsdata().background,
      body: Obx(() {
        if (productController.isLoading.value && productController.products.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final products = productController.filteredProducts;
        final int totalPages = (products.length / itemsPerPage).ceil();
        final int startIndex = (currentPage - 1) * itemsPerPage;
        final int endIndex = (startIndex + itemsPerPage > products.length)
            ? products.length
            : startIndex + itemsPerPage;
        final List<ProductModel> visibleProducts =
            products.isNotEmpty ? products.sublist(startIndex, endIndex) : [];
        int crossAxisCount = 2;
        if (width >= 1200) {
          crossAxisCount = 5;
        } else if (width >= 992) {
          crossAxisCount = 4;
        } else if (width >= 768) {
          crossAxisCount = 3;
        }
        double horizontalPadding = adaptiveSize(10, 25, 50);
        
        final photo = controller.currentUser.value?.photoUrl;
       
        
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER
                Container(
                  padding: EdgeInsets.all(adaptiveSize(width / 33, 20, 30)),
                  color: Colorsdata().white,
                  child: Column(
                    children: [
                      if(!kIsWeb) SizedBox(height: 35,) else SizedBox(),
                      Row( 
                        children: [
                          Expanded(
                            child: Text(
                              word().name,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: adaptiveSize(20, 24, 28),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _buildNotificationIcon(width, controller.currentUser.value!.id, subCtrl),
                          SizedBox(width: adaptiveSize(10, 20, 25)),
                          _buildHeaderIcon(
                            width,
                            Icons.store_outlined,
                            () => Get.toNamed(
                              '/ExploreInPage/store',
                              id: NavInIds.explorer,
                            ),
                          ),
                          SizedBox(width: adaptiveSize(10, 20, 25)),
                          Obx(() {
                            final CartController cartController = Get.find<CartController>();
                            final count = cartController.itemCount.value;
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.shopping_cart_outlined,
                                      size: adaptiveSize(30, 30, 40),
                                      color: const Color.fromARGB(221, 79, 72, 72)),
                                  onPressed: () {
                                   
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
                                    child: AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 300),
                                      transitionBuilder: (child, animation) =>
                                          ScaleTransition(scale: animation, child: child),
                                      child: Container(
                                        key: ValueKey<int>(count),
                                        padding: EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: BoxConstraints(
                                          minWidth: 18,
                                          minHeight: 18,
                                          maxWidth: 24,
                                        ),
                                        child: Center(
                                          child: Text(
                                            count > 9 ? '+9' : '$count',
                                            style: const TextStyle(color: Colors.white, fontSize: 12),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          }),
                          SizedBox(width: adaptiveSize(10, 20, 25)),
                          InkWell(
                            child: CircleAvatar(
                              radius: 15,
                              backgroundColor: const Color.fromARGB(255, 141, 43, 43),
                              backgroundImage: (photo != null && photo.isNotEmpty) ? NetworkImage(photo) : null,
                              child: (photo == null || photo.isEmpty)
                                  ? Text(controller.currentUser.value!.username[0].toUpperCase(),
                                      style: TextStyle(color: Colors.white))
                                  : Text('?'),
                            ),
                            onTap: () => Get.toNamed(
                              '/ExploreInPage/profil',
                              id: NavInIds.explorer,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: adaptiveSize(height / 65, 15, 25)),
                      SizedBox(
                        height: adaptiveSize(42, 45, 48),
                        child: TextFormField(
                          onChanged: (value) => productController.search(value),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: Icon(Icons.search,
                                color: Colors.grey,
                                size: adaptiveSize(20, 22, 24)),
                            hintText: 'Rechercher des articles...',
                            hintStyle: TextStyle(
                                color: Colors.grey,
                                fontSize: adaptiveSize(14, 15, 16)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(7),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(7),
                              borderSide: BorderSide(
                                  width: 1.2, color: Colorsdata().buttonHover),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // CONTENU PRINCIPAL
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Obx(() =>
                            GestureDetector(
                              onTap: () => T.toggleVisibility(),
                              child: SizedBox(
                                width: 85,
                                child: Row(
                                  children: [
                                    Text("Trier", style: TextStyle(fontWeight: FontWeight.bold, color: Colorsdata().buttonHover, fontSize: 17),),
                                    IconButton(
                                    icon: Icon(
                                        T.isVisible.value
                                            ? Icons.arrow_drop_up
                                            : Icons.arrow_drop_down,
                                        size: 26,
                                        color: Colorsdata().buttonHover,
                                    ),
                                    onPressed:() {
                                        T.toggleVisibility();
                                    } ,
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: adaptiveSize(5, 10, 15)),
                          T.isVisible.value
                          ? _buildFilters(width) : SizedBox(),
                          SizedBox(height: adaptiveSize(5, 10, 15)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Tous les articles',
                                  style: TextStyle(
                                      fontSize: adaptiveSize(16, 20, 22),
                                      fontWeight: FontWeight.bold)),
                              Text('${products.length} articles',
                                  style: TextStyle(
                                      fontSize: adaptiveSize(13, 15, 16))),
                            ],
                          ),
                          SizedBox(height: adaptiveSize(5, 10, 15)),
                          // 🟢 Grille produits ou message "Aucun produit trouvé"
                          products.isEmpty
                              ? Container(
                                  padding: EdgeInsets.all(50),
                                  alignment: Alignment.center,
                                  child: SizedBox(
                                    height: 200,
                                    width: double.infinity,
                                    child: Center(child: const Text("Aucun produit trouvé"))),
                                )
                              : GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: visibleProducts.length,
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    mainAxisSpacing: 8,
                                    crossAxisSpacing: 8,
                                    childAspectRatio: aspectRatio,
                                  ),
                                  itemBuilder: (context, index) {
                                    final product = visibleProducts[index];
                                    return _buildProductCard(product, width);
                                  },
                                ),
                          if (products.isNotEmpty) ...[
                            SizedBox(height: adaptiveSize(20, 25, 30)),
                            _buildPagination(totalPages, width),
                            SizedBox(height: adaptiveSize(25, 30, 40)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // -------------------------------
  // 🔹 WIDGETS SECONDAIRES
  // -------------------------------

  Widget _buildProductCard(ProductModel product, double width) {
    // NOUVEAU: Détermine si le produit est boosté
    final bool isBoosted = product.boostExpiresAt?.isAfter(DateTime.now()) ?? false;

    return GestureDetector(
      onTap: () {
        Get.toNamed(
          '/ExploreInPage/detail',
          id: NavInIds.explorer,
          arguments: product,
        );
        Future.delayed(Duration(milliseconds: 300), () async {
          // Vérifiez que l'utilisateur est connecté avant d'ajouter une vue
          if (FirebaseAuth.instance.currentUser?.uid != null) {
            await productController.addView(
              product.id,
              FirebaseAuth.instance.currentUser!.uid,
            );
          }
        });
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
                      // Vérifiez que l'utilisateur est connecté avant de toggler le favori
                      if (FirebaseAuth.instance.currentUser?.uid != null) {
                        await productController.toggleFavorite(
                          product.id,
                          FirebaseAuth.instance.currentUser!.uid,
                        );
                      } else {
                        Get.snackbar('Connexion requise', 'Veuillez vous connecter pour ajouter aux favoris.', snackPosition: SnackPosition.BOTTOM);
                      }
                    },
                    icon: Icon(
                      product.favorites.contains(FirebaseAuth.instance.currentUser?.uid)
                          ? Icons.favorite
                          : Icons.favorite_border_outlined,
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
                      // NOUVEAU: Bouton "Booster" si l'utilisateur est le propriétaire du produit
                      if (product.sellerId == FirebaseAuth.instance.currentUser?.uid) // Vérifie si c'est son propre produit
                        if (isBoosted) SizedBox() else
                        ElevatedButton.icon(
                          onPressed: () => _showBoostProductDialog(context, product),
                          icon: Icon(Icons.rocket_launch, size: 16, color: Colors.white),
                          label: Text("Booster", style: TextStyle(fontSize: 12, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero, // Pour permettre un plus petit bouton
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Réduit la zone cliquable
                          ),
                        )
                      else // NOUVEAU: Bouton "Ajouter au panier" si ce n'est pas son produit
                        IconButton(
                          onPressed: () {
                            if (FirebaseAuth.instance.currentUser?.uid != null) {
                              // Ajout au panier local + Firestore
                              Get.find<CartController>().addToCart(product);
                              Get.snackbar(
                                "Panier",
                                "Produit ajouté au panier",
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: Colors.green.withOpacity(0.2),
                              );
                            } else {
                              Get.snackbar('Connexion requise', 'Veuillez vous connecter pour ajouter au panier.', snackPosition: SnackPosition.BOTTOM);
                            }
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
    );
  }

  Widget _buildFilters(double width) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colorsdata().white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 5,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        children: [
          _buildDropdownResponsive('Catégorie', categories, selectedCategoryValue,
              (v) => setState(() => selectedCategoryValue = v), width),
          _buildDropdownResponsive('État', conditions, selectedConditionValue,
              (v) => setState(() => selectedConditionValue = v), width),
          _buildTextFieldResponsive('Prix min', minPriceController, width),
          _buildTextFieldResponsive('Prix max', maxPriceController, width),
          _buildDropdownResponsive('Trier par', sortOptions, selectedSortValue,
              (v) => setState(() => selectedSortValue = v), width),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colorsdata().white,
                    elevation: 2,
                  ),
                  onPressed: () {
                    setState(() {
                      selectedCategoryValue = null;
                      selectedConditionValue = null;
                      selectedSortValue = 'Meilleur score';
                      minPriceController.text = '0';
                      maxPriceController.text = '1000000';
                    });
                    productController.resetFilters();
                  },
                  child: const Text(
                    'Réinitialiser',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colorsdata().buttonHover,
                    elevation: 2,
                  ),
                  onPressed: () {
                    double min = double.tryParse(minPriceController.text) ?? 0;
                    double max =
                        double.tryParse(maxPriceController.text) ?? 1000000;
                    productController.applyFilters(
                      category: selectedCategoryValue,
                      condition: selectedConditionValue,
                      min: min,
                      max: max,
                      sort: selectedSortValue,
                    );
                  },
                  child: const Text('Appliquer',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPagination(int totalPages, double width) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
            onPressed:
                currentPage > 1 ? () => setState(() => currentPage--) : null,
            icon: Icon(Icons.arrow_back_ios,
                size: width < 600 ? 14 : 18,
                color: Colorsdata().buttonHover)),
        ...List.generate(totalPages, (index) {
          final page = index + 1;
          return GestureDetector(
            onTap: () => setState(() => currentPage = page),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: currentPage == page
                    ? Colorsdata().buttonHover
                    : Colors.white,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colorsdata().buttonHover),
              ),
              child: Text("$page",
                  style: TextStyle(
                      fontSize: width < 600 ? 12 : 14,
                      color: currentPage == page
                          ? Colors.white
                          : Colorsdata().buttonHover)),
            ),
          );
        }),
        IconButton(
            onPressed: currentPage < totalPages
                ? () => setState(() => currentPage++)
                : null,
            icon: Icon(Icons.arrow_forward_ios,
                size: width < 600 ? 14 : 18,
                color: Colorsdata().buttonHover)),
      ],
    );
  }

  Widget _buildDropdownResponsive(String title, List<String> items, String? value,
      Function(String?) onChanged, double width) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 10),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colorsdata().background,
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: width < 600 ? 12 : 14)),
          const SizedBox(height: 5),
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colorsdata().white,
              borderRadius: BorderRadius.circular(5),
            ),
            child: DropdownButton<String>(
              style: const TextStyle(fontSize: 14),
              isExpanded: true,
              hint: const Text('Sélectionner'),
              value: value,
              onChanged: onChanged,
              items: items
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFieldResponsive(
      String title, TextEditingController controller, double width) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colorsdata().background,
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: width < 600 ? 12 : 14)),
          const SizedBox(height: 5),
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colorsdata().white,
              borderRadius: BorderRadius.circular(5),
            ),
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: title == 'Prix min' ? '0' : '1000000',
                hintStyle: TextStyle(fontSize: width < 600 ? 14 : 16),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // NOUVEAU: Dialogue pour choisir le niveau de boost et activer
  void _showBoostProductDialog(BuildContext context, ProductModel product) {
    // ⚠️ Correction ici: Naviguer directement vers la BoostPage
    Get.to(() => BoostPage(
      targetId: product.id,
      targetType: 'product',
      targetName: product.title,
    ));
  }
}

// Les fonctions _buildHeaderIcon et _buildNotificationIcon restent les mêmes
Widget _buildHeaderIcon(
    double screenWidth, IconData icon, VoidCallback onPressed) {
  return IconButton(
    onPressed: onPressed,
    icon: Icon(icon,
        size: screenWidth < 600 ? 30 : 40,
        color: const Color.fromARGB(221, 79, 72, 72)),
  );
}

Widget _buildNotificationIcon(
    double screenWidth, String userId, SubscriptionController subCtrl) {
  return Obx(() {
    int unreadCount =
        subCtrl.notifications.where((n) => n['read'] == false).length;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: 'Notifications',
          onPressed: () {
            Get.toNamed('/ExploreInPage/notifications', id: NavInIds.explorer);
          },
          icon: Icon(
            Icons.notifications_outlined,
            size: screenWidth < 600 ? 30 : 40,
            color: const Color.fromARGB(221, 79, 72, 72),
          ),
        ),
        if (unreadCount > 0)
          Positioned(
            right: 4,
            top: 4,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Container(
                key: ValueKey<int>(unreadCount),
                padding: EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                constraints: BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                  maxWidth: 20,
                ),
                child: Center(
                  child: Text(
                    unreadCount > 9 ? '+9' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  });
}
