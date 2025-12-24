import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tendance/views/pagesIn/explore/detailProduct.dart';
import '../../../controlers/navControler.dart';
import '../../../controlers/productControler.dart';
import '../../../models/navIds.dart';
import '../../../models/productModel.dart';
import '../../../controlers/ColorsData.dart';

class StoreDetailPageClient extends StatefulWidget {
  final String storeId;
  final String sellerId;

  StoreDetailPageClient({super.key, required this.storeId, required this.sellerId});

  @override
  State<StoreDetailPageClient> createState() => _StoreDetailPageState();
}

class _StoreDetailPageState extends State<StoreDetailPageClient> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ProductController productController = Get.put(ProductController());

  String storeName = '';
  String storeDescription = '';
  String ownerName = '';
  List<ProductModel> storeProducts = [];
  bool isLoading = true;

  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchStoreData();
  }

  Future<void> fetchStoreData() async {
    try {
      // 🔹 Infos boutique
      final storeDoc = await _firestore
          .collection('profiles')
          .doc(widget.sellerId)
          .collection('stores')
          .doc(widget.storeId)
          .get();

      if (storeDoc.exists) {
        setState(() {
          storeName = storeDoc.data()?['name'] ?? 'Nom inconnu';
          storeDescription = storeDoc.data()?['description'] ?? 'Aucune description';
        });
      }

      // 🔹 Nom propriétaire
      final ownerDoc = await _firestore.collection('profiles').doc(widget.sellerId).get();
      if (ownerDoc.exists) {
        ownerName = ownerDoc.data()?['username'] ?? '';
      }

      // 🔹 Produits de cette boutique
      final querySnapshot = await _firestore
          .collection('profiles')
          .doc(widget.sellerId)
          .collection('stores')
          .doc(widget.storeId)
          .collection('products')
          .get();

      storeProducts = querySnapshot.docs
          .map((doc) => ProductModel.fromFirestore({
                ...doc.data(),
                'id': doc.id,
                'sellerId': widget.sellerId,
                'storeId': widget.storeId,
                'storeName': storeName,    // 🔹 injecté
                'ownerName': ownerName,    // 🔹 injecté
              }))
          .toList();
    } catch (e) {
      print('Erreur fetch boutique: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  List<ProductModel> get filteredProducts {
    if (searchController.text.isEmpty) return storeProducts;
    return storeProducts
        .where((p) =>
            p.title.toLowerCase().contains(searchController.text.toLowerCase()) ||
            p.description.toLowerCase().contains(searchController.text.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(storeName),
        backgroundColor: Colorsdata().white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  // Description boutique
                  Container(
                    padding: EdgeInsets.only(right: 8),
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Description : ', style: TextStyle(fontWeight: FontWeight.bold),),
                        Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ExpandableTextWidget(
                              text: storeDescription,
                              maxLines: 2,
                            ),
                          ),
                        ],
                                          ),
                      ],
                    ),

                  ),
                  const SizedBox(height: 10),

                  // Barre de recherche
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher un produit',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 10),

                  // Liste produits
                  Expanded(
                    child: filteredProducts.isEmpty
                        ? Center(child: Text('Aucun produit trouvé'))
                        : ListView.builder(
                            itemCount: filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = filteredProducts[index];
                              return Card(
                                child: ListTile(
                                  leading: product.imageUrls.isNotEmpty
                                      ? Image.network(product.imageUrls[0],
                                          width: 50, height: 50, fit: BoxFit.cover)
                                      : const Icon(Icons.image),
                                  title: Text(product.title, 
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1),
                                  subtitle: Text(
                                      '${product.price.toStringAsFixed(2)} ${product.currency ?? 'FC'}'),
                                  onTap: () {
                                    final navController = Get.find<NavigationInController>();
                                    switch (navController.selectedIndex.value) {
                                      case 0:
                                        Get.toNamed(
                                          '/ExploreInPage/detail',
                                          id: NavInIds.explorer,
                                          arguments: product,
                                        );
                                        break;
                                      case 1:
                                        Get.toNamed(
                                          '/favoris/detail',
                                          arguments: product,
                                          id: NavInIds.favoris,
                                        );
                                        break;
                                      case 2:
                                        Get.toNamed(
                                          '/message/detail',
                                          arguments: product,
                                          id: NavInIds.messages,
                                        );
                                        break;
                                      case 3:
                                        Get.toNamed(
                                          '/dashboard/detail',
                                          arguments: product,
                                          id: NavInIds.dashboard,
                                        );
                                        break;
                                      default:
                                        print("Index inconnu: ${navController.selectedIndex.value}");
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
class ExpandableTextWidget extends StatefulWidget {
  final String text;
  final int maxLines;

  const ExpandableTextWidget({super.key, required this.text, this.maxLines = 3});

  @override
  State<ExpandableTextWidget> createState() => _ExpandableTextWidgetState();
}

class _ExpandableTextWidgetState extends State<ExpandableTextWidget> {
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
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: constraints.maxWidth);

      final isOverflow = tp.didExceedMaxLines;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.text,
            style: const TextStyle(fontSize: 14),
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
                style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
        ],
      );
    });
  }
}
