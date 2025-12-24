// file: lib/views/pagesIn/dashboard/store_detail_seller_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tendance/controlers/productControler.dart';
import 'package:tendance/models/productModel.dart';
import 'package:tendance/views/pagesIn/explore/detailProduct.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import pour currentUser
import '../../../controlers/ColorsData.dart';
import '../explore/boostPage.dart';
import 'publish_product_page.dart'; // Importez votre fichier de couleurs

class StoreDetailsSellerPage extends StatefulWidget {
  final String storeId;
  final String storeName;
  final String sellerId;
  const StoreDetailsSellerPage({
    super.key,
    required this.storeId,
    required this.storeName,
    required this.sellerId,
  });

  @override
  State<StoreDetailsSellerPage> createState() => _StoreDetailsSellerPageState();
}

class _StoreDetailsSellerPageState extends State<StoreDetailsSellerPage> {
  final ProductController productController = Get.find<ProductController>();
  final Colorsdata myColors = Colorsdata();
  final TextEditingController _searchController = TextEditingController();
  final RxString _localSearchQuery = ''.obs; // Requête de recherche locale pour les produits de cette boutique

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      productController.fetchProductsForStore(widget.sellerId, widget.storeId);
    });
    // Écoute les changements dans le champ de recherche pour mettre à jour la requête locale
    _searchController.addListener(() {
      _localSearchQuery.value = _searchController.text;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Getter pour filtrer les produits de la boutique en fonction de la requête de recherche locale
  List<ProductModel> get _filteredStoreProducts {
    List<ProductModel> currentProducts = productController.storeProducts;
    if (_localSearchQuery.value.isEmpty) {
      return currentProducts;
    } else {
      final query = _localSearchQuery.value.toLowerCase();
      return currentProducts.where((product) {
        return product.title.toLowerCase().contains(query) ||
            product.description.toLowerCase().contains(query);
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: myColors.background,
      appBar: AppBar(
        title: Text(widget.storeName),
        backgroundColor: myColors.primaryColor,
        foregroundColor: myColors.white,
        elevation: 0,
        // Ajout de la barre de recherche dans le AppBar
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight + 10), // Ajustez la hauteur si nécessaire
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                _localSearchQuery.value = value; // Met à jour la requête locale
              },
              decoration: InputDecoration(
                hintText: 'Rechercher des produits...',
                fillColor: myColors.white,
                filled: true,
                prefixIcon: Icon(Icons.search, color: myColors.primaryColor),
                suffixIcon: _localSearchQuery.value.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: myColors.primaryColor),
                        onPressed: () {
                          _searchController.clear();
                          _localSearchQuery.value = '';
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
              ),
            ),
          ),
        ),
      ),
      body: Obx(() {
        // Afficher le loader uniquement si la liste est vide ET que le chargement est en cours
        if (productController.isLoading.value && productController.storeProducts.isEmpty) {
          return Center(child: CircularProgressIndicator(color: myColors.primaryColor));
        }

        final productsToDisplay = _filteredStoreProducts; // Utilise la liste filtrée

        if (productsToDisplay.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _localSearchQuery.value.isNotEmpty
                      ? 'Aucun produit ne correspond à votre recherche.'
                      : 'Aucun produit dans cette boutique pour le moment.',
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 20),
                // N'affiche le bouton "Ajouter un produit" que si aucune recherche n'est active
                if (_localSearchQuery.value.isEmpty)
                  ElevatedButton.icon(
                    onPressed: () => Get.to(() => PublishProductPage(storeId: widget.storeId)),
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter un produit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: myColors.primaryColor,
                      foregroundColor: myColors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 250,
            childAspectRatio: 0.65,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: productsToDisplay.length,
          itemBuilder: (context, i) {
            final product = productsToDisplay[i];
            return _buildProductCard(product);
          },
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.to(() => PublishProductPage(storeId: widget.storeId)),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau produit'),
        backgroundColor: myColors.primaryColor,
        foregroundColor: myColors.white,
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    final bool isBoosted = product.boostLevel != null && product.boostExpiresAt != null && product.boostExpiresAt!.isAfter(DateTime.now());
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final bool isOwner = currentUserId == product.sellerId;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Get.to(() => Detailproduct(product: product));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Stack( // Use Stack for badge
                children: [
                  Hero(
                    tag: product.id,
                    child: product.imageUrls.isNotEmpty
                        ? Image.network(
                            product.imageUrls.first,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(child: CircularProgressIndicator(value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null, color: myColors.primaryColor));
                            },
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image, color: Colors.grey, size: 50),
                          )
                        : const Center(child: Icon(Icons.image_not_supported, color: Colors.grey, size: 50)),
                  ),
                  if (isBoosted) // Boost badge
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: myColors.buttonHover, // Couleur pour le badge "BOOSTÉ"
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          'BOOSTÉ',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${product.price.toStringAsFixed(2)} ${product.currency ?? 'FC'}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: myColors.primaryColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.condition,
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Owner actions: Edit, Delete, and conditional Boost button
                    if (isOwner) // Only show these actions if the current user is the owner
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end, // Align edit/delete to the right
                            children: [
                               // Boost info if boosted
                              if (isBoosted)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Boosté',
                                      style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                    // Text(
                                    //   'Expire le: ${product.boostExpiresAt!.day}/${product.boostExpiresAt!.month} à ${product.boostExpiresAt!.hour}h${product.boostExpiresAt!.minute}',
                                    //   style: TextStyle(color: Colors.green, fontSize: 10),
                                    // ),
                                  ],
                                ) else 
                                ElevatedButton.icon(
                                onPressed: () {
                                    Get.to(() => BoostPage(
                                      targetId: product.id,
                                      targetType: 'product',
                                      targetName: product.title,
                                    ));
                                  },
                                  icon: Icon(Icons.rocket_launch, size: 16, color: Colors.white),
                                  label: Text("Booster", style: TextStyle(fontSize: 12, color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero, // Pour permettre un plus petit bouton
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Réduit la zone cliquable
                                  ),
                              ),
                              Spacer(),
                              IconButton(
                                icon: Icon(Icons.edit, color: myColors.accentColor, size: 20),
                                tooltip: 'Modifier le produit',
                                onPressed: () {
                                  Get.to(() => PublishProductPage(
                                        storeId: widget.storeId,
                                        productToEdit: product,
                                      ));
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                tooltip: 'Supprimer le produit',
                                onPressed: () => _confirmDeleteProduct(context, product.id),
                              ),
                            ],
                          ),
                          // Show Boost button only if not already boosted
                            
                        ],
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

  Future<void> _confirmDeleteProduct(BuildContext context, String productId) async {
    final confirm = await Get.defaultDialog<bool>(
      title: 'Supprimer le produit ?',
      middleText: 'Voulez-vous vraiment supprimer ce produit ? Cette action est irréversible.',
      textConfirm: 'Supprimer',
      textCancel: 'Annuler',
      confirmTextColor: myColors.white,
      buttonColor: Colors.red,
      cancelTextColor: Colors.black,
      onConfirm: () => Get.back(result: true),
      onCancel: () => Get.back(result: false),
    );
    if (confirm == true) {
      await productController.deleteProduct(
        productId: productId,
        storeId: widget.storeId,
        userId: widget.sellerId,
      );
    }
  }
}
