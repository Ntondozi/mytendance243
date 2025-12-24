import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controlers/authControler.dart';
import '../../../controlers/subscription_controller.dart';
import 'add_store_page.dart';
import 'store_detail_page.dart';
import 'subscription/subscription_page.dart';

class StoreListPage extends StatelessWidget {
  const StoreListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final user = auth.currentUser.value;
    final userId = user?.id;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Utilisateur non connecté')),
      );
    }

    final storesRef = FirebaseFirestore.instance
        .collection('profiles')
        .doc(userId)
        .collection('stores');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes boutiques'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: storesRef.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Aucune boutique trouvée.'),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                   onPressed: () async {
                      final auth = Get.find<AuthController>();
                      final user = auth.currentUser.value;
                      if (user == null) {
                        Get.snackbar('Erreur', 'Utilisateur non connecté');
                        return;
                      }
                      final subCtrl = Get.put(SubscriptionController());
                      // show a small loading
                      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
                      final can = await subCtrl.canCreateStore(user.id);
                      if (Get.isDialogOpen ?? false) Get.back();
                      if (!can) {
                        // Rediriger vers page d'abonnement
                        Get.to(() => SubscriptionPage(userId: user.id));
                      } else {
                        Get.to(() => const AddStorePage());
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Créer une boutique'),
                  ),
                ],
              ),
            );
          }

          final docs = snap.data!.docs;
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final store = docs[i];
              return ListTile(
                leading: const Icon(Icons.store, color: Colors.blue),
                title: Text(store['name'] ?? 'Sans nom', overflow: TextOverflow.ellipsis,
                                maxLines: 1,),
                subtitle: Text(store['description' ] ?? '', overflow: TextOverflow.ellipsis,
                                maxLines: 1),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Bouton supprimer
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final confirm = await Get.defaultDialog<bool>(
                          title: 'Supprimer ?',
                          middleText:
                              'Voulez-vous vraiment supprimer cette boutique et tous ses produits ?',
                          textCancel: 'Annuler',
                          textConfirm: 'Supprimer',
                          confirmTextColor: Colors.white,
                          onConfirm: () => Get.back(result: true),
                          onCancel: () => Get.back(result: false),
                        );

                        if (confirm == true) {
                          try {
                            final storeDoc = storesRef.doc(store.id);

                            // Supprimer tous les produits de la boutique
                            final productsSnapshot =
                                await storeDoc.collection('products').get();
                            final batch = FirebaseFirestore.instance.batch();
                            for (var doc in productsSnapshot.docs) {
                              batch.delete(doc.reference);
                            }
                            await batch.commit();

                            // Supprimer la boutique elle-même
                            await storeDoc.delete();

                            Get.snackbar(
                              'Succès',
                              'Boutique et ses produits supprimés',
                              backgroundColor: Colors.green,
                              colorText: Colors.white,
                            );
                          } catch (e) {
                            Get.snackbar(
                              'Erreur',
                              'Impossible de supprimer la boutique : $e',
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );
                          }
                        }
                      },
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () {
                  Get.to(() => StoreDetailPage(
                        storeId: store.id,
                        storeName: store['name'] ?? 'Boutique',
                      ));
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final auth = Get.find<AuthController>();
          final user = auth.currentUser.value;
          if (user == null) {
            Get.snackbar('Erreur', 'Utilisateur non connecté');
            return;
          }
          final subCtrl = Get.put(SubscriptionController());
          // show a small loading
          Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
          final can = await subCtrl.canCreateStore(user.id);
          if (Get.isDialogOpen ?? false) Get.back();
          if (!can) {
            // Rediriger vers page d'abonnement
            Get.to(() => SubscriptionPage(userId: user.id));
          } else {
            Get.to(() => const AddStorePage());
          }
        },
        child: const Icon(Icons.add),
      ),

    );
  }
}
