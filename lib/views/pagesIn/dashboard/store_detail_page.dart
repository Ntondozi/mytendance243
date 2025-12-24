import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controlers/authControler.dart';
import '../explore/detailProduct.dart';
import 'publish_product_page.dart';

class StoreDetailPage extends StatelessWidget {
  final String storeId;
  final String storeName;
  const StoreDetailPage({super.key, required this.storeId, required this.storeName});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final user = auth.currentUser.value;
    if (user == null) return const Scaffold(body: Center(child: Text('Utilisateur non connecté')));

    final productsRef = FirebaseFirestore.instance
        .collection('profiles')
        .doc(user.id)
        .collection('stores')
        .doc(storeId)
        .collection('products');

    return Scaffold(
      appBar: AppBar(title: Text(storeName)),
      body: StreamBuilder<QuerySnapshot>(
        stream: productsRef.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Aucun produit pour le moment.'),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () => Get.to(() => PublishProductPage(storeId: storeId)),
                  icon: const Icon(Icons.add),
                  label: const Text('Mettre en ligne un produit'),
                )
              ]),
            );
          }

          final docs = snap.data!.docs;
          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, childAspectRatio: 0.75, mainAxisSpacing: 8, crossAxisSpacing: 8),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final p = docs[i];
              final imgs = (p['imageUrls'] as List<dynamic>?) ?? [];
              final sellerId = p['sellerId'] as String?;

              return Card(
                elevation: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                        },
                        child: imgs.isNotEmpty
                            ? Image.network(imgs[0], fit: BoxFit.cover)
                            : const Icon(Icons.image_not_supported, size: 60),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(p['title'] ?? 'Sans titre',overflow: TextOverflow.ellipsis,
                                maxLines: 1,  style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        '${p['price'] ?? 0} ${p['currency'] != null && p['currency'].toString().isNotEmpty ? p['currency'] : 'FC'}',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      )

                    ),
                    const SizedBox(height: 8),
                    if (sellerId == user.id) // seulement propriétaire
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          IconButton(onPressed: () async {
                              final confirm = await Get.defaultDialog<bool>(
                                title: 'Supprimer ?',
                                middleText: 'Voulez-vous vraiment supprimer ce produit ?',
                                textCancel: 'Annuler',
                                textConfirm: 'Supprimer',
                                confirmTextColor: Colors.white,
                                onConfirm: () => Get.back(result: true),
                                onCancel: () => Get.back(result: false),
                              );
                              if (confirm == true) {
                                try {
                                  await productsRef.doc(p.id).delete();
                                  Get.snackbar('Succès', 'Produit supprimé',
                                      backgroundColor: Colors.green, colorText: Colors.white);
                                } catch (e) {
                                  Get.snackbar('Erreur', 'Impossible de supprimer le produit',
                                      backgroundColor: Colors.red, colorText: Colors.white);
                                }
                              }
                            }, icon: Icon(Icons.delete, size: 16),)
                        ],
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.to(() => PublishProductPage(storeId: storeId)),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau produit'),
      ),
    );
  }
}
