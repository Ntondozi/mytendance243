// file: lib/views/pagesIn/dashboard/my_stores_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tendance/controlers/authControler.dart';
import 'package:tendance/controlers/storeControlers.dart';
import 'package:tendance/controlers/subscription_controller.dart';
import 'package:tendance/views/pagesIn/dashboard/add_store_page.dart';
import 'package:tendance/views/pagesIn/dashboard/store_detail_seller_page.dart';
import '../../../controlers/ColorsData.dart';
import 'subscription/subscription_page.dart';

// ÉTAPE 1: CONVERTIR LE WIDGET EN STATEFULWIDGET
class MyStoresPage extends StatefulWidget {
  const MyStoresPage({super.key});

  @override
  State<MyStoresPage> createState() => _MyStoresPageState();
}

class _MyStoresPageState extends State<MyStoresPage> {
  // ÉTAPE 2: DÉPLACER L'INITIALISATION DES CONTRÔLEURS ET VARIABLES D'ÉTAT ICI
  final AuthController auth = Get.find<AuthController>();
  final StoreController storeController = Get.find<StoreController>();

  final SubscriptionController subCtrl = Get.find<SubscriptionController>();
  final Colorsdata myColors = Colorsdata();
  String? userId;

  @override
  void initState() {
    super.initState();
    userId = auth.currentUser.value?.id;
    // ÉTAPE 3: APPELER LA RÉCUPÉRATION DES DONNÉES DANS initState
    // Cela garantit que la méthode n'est appelée qu'une seule fois à la création de la page.
    if (userId != null) {
      // Nous utilisons addPostFrameCallback pour nous assurer que tout est prêt
      // avant d'appeler une méthode qui pourrait déclencher une reconstruction.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        storeController.fetchUserStores(userId!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return Center(
        child: Text('Utilisateur non connecté.', style: TextStyle(color: myColors.primaryColor)),
      );
    }

    // ÉTAPE 4: SUPPRIMER L'APPEL DE RÉCUPÉRATION DES DONNÉES DE LA MÉTHODE build
    // storeController.fetchUserStores(userId); <-- Cette ligne est supprimée d'ici

    return Scaffold(
      backgroundColor: myColors.background,
      body: Obx(() {
        if (storeController.isLoading.value && storeController.userStores.isEmpty) {
          // Afficher le loader seulement si on charge pour la première fois
          return Center(child: CircularProgressIndicator(color: myColors.primaryColor));
        }

        final userStores = storeController.userStores;

        if (userStores.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Vous n\'avez pas encore créé de boutique.',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _checkAndNavigateToAddStore(context, userId!, subCtrl),
                  icon: const Icon(Icons.add),
                  label: const Text('Créer une boutique'),
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

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: userStores.length,
          separatorBuilder: (_, __) => const Divider(height: 20, color: Colors.transparent), // Rendu invisible pour utiliser l'élévation des cartes
          itemBuilder: (context, i) {
            final store = userStores[i];
            return Card(
              elevation: 4,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: myColors.white,
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Icon(Icons.storefront, color: myColors.primaryColor, size: 30),
                title: Text(
                  store['name'] ?? 'Sans nom',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: myColors.primaryColor),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                subtitle: Text(
                  store['description'] ?? 'Aucune description',
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: myColors.accentColor),
                      tooltip: 'Modifier la boutique',
                      onPressed: () {
                        Get.to(() => AddStorePage(
                          storeIdToEdit: store['id'], 
                          initialName: store['name'] as String?, 
                          initialDescription: store['description'] as String?
                        ));
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Supprimer la boutique',
                      onPressed: () => _confirmDeleteStore(context, store['id'], userId!, storeController),
                    ),
                  ],
                ),
                onTap: () {
                  Get.to(() => StoreDetailsSellerPage(
                    storeId: store['id'],
                    storeName: store['name'] ?? 'Ma Boutique',
                    sellerId: userId!,
                  ));
                },
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _checkAndNavigateToAddStore(context, userId!, subCtrl),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter une boutique'),
        backgroundColor: myColors.primaryColor,
        foregroundColor: myColors.white,
      ),
    );
  }

  Future<void> _checkAndNavigateToAddStore(BuildContext context, String userId, SubscriptionController subCtrl) async {
    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    final can = await subCtrl.canCreateStore(userId);
    if (Get.isDialogOpen ?? false) Get.back();

    if (!can) {
      Get.snackbar(
        'Abonnement requis',
        'Vous devez activer/renouveler un abonnement pour créer une nouvelle boutique ou augmenter votre limite.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.to(() => SubscriptionPage(userId: userId));
    } else {
      
      Get.to(() => const AddStorePage());
    }
  }

  Future<void> _confirmDeleteStore(BuildContext context, String storeId, String userId, StoreController storeController) async {
    final confirm = await Get.defaultDialog<bool>(
      title: 'Supprimer la boutique ?',
      middleText: 'Voulez-vous vraiment supprimer cette boutique et tous ses produits ? Cette action est irréversible.',
      textConfirm: 'Supprimer',
      textCancel: 'Annuler',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      cancelTextColor: Colors.black,
      onConfirm: () => Get.back(result: true),
      onCancel: () => Get.back(result: false),
    );

    if (confirm == true) {
      await storeController.deleteStore(storeId: storeId, userId: userId);
    }
  }
}
