import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tendance/controlers/ColorsData.dart';
import 'package:tendance/views/pagesIn/explore/detailProduct.dart';
import '../../../controlers/productControler.dart';
import '../../../models/navIds.dart';

class FavoriteProductsPage extends StatelessWidget {
  final ProductController controller = Get.find<ProductController>();
  final TextEditingController searchController = TextEditingController();

  FavoriteProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colorsdata().white,
      appBar: AppBar(
        
        automaticallyImplyLeading: false,

        backgroundColor: Colorsdata().white,
        title: const Text('Mes Favoris ❤️'),
      ),
      body: Column(
        children: [
          // 🔍 Barre de recherche
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un produit...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                controller.search(value);
              },
            ),
          ),

          // 🧾 Liste des favoris filtrés
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              
              if (controller.favoriteProducts.isEmpty) {
                return const Center(
                  child: Text('Aucun produit trouvé dans vos favoris.'),
                );
              }

              return ListView.builder(
                itemCount: controller.favoriteProducts.length,
                itemBuilder: (context, index) {
                  final product = controller.favoriteProducts[index];
                  return Card(
                    color: Colorsdata().background,
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: ListTile(
                      leading: product.imageUrls.isNotEmpty
                          ? Image.network(product.imageUrls.first, width: 60, fit: BoxFit.cover)
                          : const Icon(Icons.image_not_supported),
                      title: Text(product.title, 
                      overflow: TextOverflow.ellipsis,
                                maxLines: 1),
                      subtitle: Text('${product.price.toStringAsFixed(2)} FC'),
                      trailing: IconButton(
                        icon: const Icon(Icons.favorite, color: Colors.red),
                        onPressed: () {
                          controller.toggleFavorite(product.id, controller.currentUserId.value);
                        },
                      ),
                      onTap: () {
                        Get.toNamed(
                          '/favoris/detail',
                          id: NavInIds.favoris, // 👈 très important !
                          arguments: product,
                        );
                      },
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}