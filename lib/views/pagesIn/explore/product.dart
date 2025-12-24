import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controlers/ColorsData.dart';
import '../../../controlers/productControler.dart';
import '../../../models/productModel.dart';

class Exploreinpage extends StatefulWidget {
  const Exploreinpage({super.key});

  @override
  State<Exploreinpage> createState() => _ExploreinpageState();
}

class _ExploreinpageState extends State<Exploreinpage> {
  final ProductController productController = Get.put(ProductController());

  String? selectedValue;
  String? selectedValueEtat;
  String? selectedValueTrie;

  int currentPage = 1;
  final int itemsPerPage = 20;

  final List<String> categories = [
    'Accessoires',
    'Chaussures',
    'Sacs',
    'Vêtements'
  ];
  final List<String> etats = [
    'Neuf',
    'Occasion',
    'Excellent état',
    'Bon état',
    'État correct',
    'Usé'
  ];
  final List<String> trie = [
    'Aléatoire',
    'Plus récents',
    'Prix croissant',
    'Prix décroissant',
    'Plus populaires'
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colorsdata().background,
      body: Obx(() {
        if (productController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = productController.products;

        if (products.isEmpty) {
          return const Center(child: Text("Aucun produit trouvé"));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: width < 600 ? 2 : 4,
            mainAxisSpacing: 15,
            crossAxisSpacing: 15,
            mainAxisExtent: 280,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return _buildProductCard(product, width);
          },
        );
      }),
    );
  }

  Widget _buildProductCard(ProductModel product, double width) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
              child: Image.network(
                product.imageUrls.isNotEmpty
                    ? product.imageUrls.first
                    : 'https://via.placeholder.com/150',
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              Text("${product.price.toStringAsFixed(2)} \$",
                  style: const TextStyle(color: Colors.black87)),
              Text(product.category,
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ]),
          ),
        ],
      ),
    );
  }
}
