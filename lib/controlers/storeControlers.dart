import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // Importé pour Colors, notamment dans Get.snackbar
import 'package:get/get.dart';
import 'package:tendance/controlers/subscription_controller.dart'; // Assurez-vous d'importer le SubscriptionController
import 'package:tendance/models/navIds.dart';
import 'ColorsData.dart'; // Assurez-vous d'importer Colorsdata

class StoreController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RxList<Map<String, dynamic>> allStores = <Map<String, dynamic>>[].obs; // Stores de tous les utilisateurs
  final RxList<Map<String, dynamic>> userStores = <Map<String, dynamic>>[].obs; // Stores de l'utilisateur actuel
  final RxList<Map<String, dynamic>> filteredStores = <Map<String, dynamic>>[].obs; // Pour la page Explorer
  final RxBool isLoading = false.obs;

  // Champs de recherche et tri
  final RxString searchQuery = ''.obs;
  final RxString selectedCity = ''.obs;
  final RxString sortOption = ''.obs;

  final Colorsdata myColors = Colorsdata(); // Instance des couleurs (assurez-vous d'importer Colorsdata)

  // Ajoutez une instance du SubscriptionController
  late final SubscriptionController _subscriptionController;

  @override
  void onInit() {
    super.onInit();
    // Initialisez le SubscriptionController
    _subscriptionController = Get.find<SubscriptionController>();
    fetchAllStores(); // Charge toutes les boutiques pour la page Explorer
    // Écoute les changements de filtre/recherche pour filteredStores (page Explorer)
    everAll([searchQuery, selectedCity, sortOption], (_) => applyFilters());
  }

  // Récupère toutes les boutiques (pour la page Explorer)
  Future<void> fetchAllStores() async {
    try {
      isLoading.value = true;
      final List<Map<String, dynamic>> tempAllStores = [];
      final querySnapshot = await _firestore.collectionGroup('stores').get();

      for (var doc in querySnapshot.docs) {
        final Map<String, dynamic> storeData = doc.data(); // Explicit cast here
        final storeId = doc.id;
        final parentPath = doc.reference.parent?.parent; // Utilisez l'opérateur de navigation sécurisée
        
        if (parentPath == null) {
          print('Parent path is null for store ${doc.id}, skipping.');
          continue;
        }
        final userId = parentPath.id; // L'ID du propriétaire de la boutique

        // Récupérer les données de l'utilisateur et le nombre de produits
        // et le statut d'abonnement
        final userDocFuture = _firestore.collection('profiles').doc(userId).get();
        final productsSnapFuture = _firestore.collection('profiles').doc(userId).collection('stores').doc(storeId).collection('products').get();
        final ownerSubscriptionFuture = _subscriptionController.readSubscriptionFromFirestore(userId);

        final results = await Future.wait([userDocFuture, productsSnapFuture, ownerSubscriptionFuture]);

        final userDoc = results[0] as DocumentSnapshot;
        final productsSnap = results[1] as QuerySnapshot;
        final ownerSubscription = results[2] as LocalSubscription?;

        final Map<String, dynamic> userData = (userDoc.data() as Map<String, dynamic>?) ?? {}; 
        final totalProducts = productsSnap.docs.length;

        // Déterminez si le propriétaire a un abonnement actif ou un essai
        bool ownerHasActiveSubscription = false;
        if (ownerSubscription != null) {
          ownerHasActiveSubscription = ownerSubscription.expiresAtMillis > DateTime.now().millisecondsSinceEpoch;
        }

        tempAllStores.add({
          'id': storeId,
          'ownerId': userId,
          'name': storeData['name'] ?? 'Nom inconnu',
          'description': storeData['description'] ?? 'Aucune description',
          'totalProducts': totalProducts,
          'imageUrl': storeData['imageUrl'],
          'city': userData['city'] as String? ?? 'Ville inconnue', 
          'createdAt': storeData['createdAt'] is Timestamp ? (storeData['createdAt'] as Timestamp).toDate() : DateTime.now(),
          'ownerHasActiveSubscription': ownerHasActiveSubscription, // Ajoutez le statut d'abonnement
        });
      }

      allStores.assignAll(tempAllStores);
      applyFilters(); // Appliquer les filtres initiaux pour la page Explorer
    } catch (e) {
      print('Erreur récupération toutes les boutiques : $e');
      Get.snackbar('Erreur', 'Impossible de charger toutes les boutiques : $e', backgroundColor: Colors.red, colorText: myColors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // Récupère les boutiques spécifiques à l'utilisateur connecté (pour le Dashboard)
  Future<void> fetchUserStores(String userId) async {
    try {
      isLoading.value = true;
      final List<Map<String, dynamic>> tempUserStores = [];
      final querySnapshot = await _firestore.collection('profiles').doc(userId).collection('stores').orderBy('createdAt', descending: true).get();

      for (var doc in querySnapshot.docs) {
        final Map<String, dynamic> storeData = doc.data(); // Explicit cast here
        final storeId = doc.id;
        // Récupérer le nombre de produits pour cette boutique
        final productsSnap = await _firestore.collection('profiles').doc(userId).collection('stores').doc(storeId).collection('products').get();
        final totalProducts = productsSnap.docs.length;

        // Déterminez si le propriétaire a un abonnement actif (pour l'utilisateur courant)
        // Note: Pour les boutiques de l'utilisateur courant, on peut supposer que l'abonnement
        // est déjà connu ou n'est pas le critère principal d'affichage dans le dashboard
        // Mais pour la cohérence, on peut aussi l'ajouter.
        bool ownerHasActiveSubscription = false;
        final ownerSubscription = await _subscriptionController.readSubscriptionFromFirestore(userId);
        if (ownerSubscription != null) {
          ownerHasActiveSubscription = ownerSubscription.expiresAtMillis > DateTime.now().millisecondsSinceEpoch;
        }

        tempUserStores.add({
          'id': storeId,
          'ownerId': userId,
          'name': storeData['name'] ?? 'Nom inconnu',
          'description': storeData['description'] ?? 'Aucune description',
          'totalProducts': totalProducts,
          'imageUrl': storeData['imageUrl'],
          'createdAt': storeData['createdAt'] is Timestamp ? (storeData['createdAt'] as Timestamp).toDate() : DateTime.now(),
          'ownerHasActiveSubscription': ownerHasActiveSubscription, // Ajoutez le statut d'abonnement
        });
      }

      userStores.assignAll(tempUserStores);
    } catch (e) {
      print('Erreur récupération boutiques utilisateur : $e');
      Get.snackbar('Erreur', 'Impossible de charger vos boutiques.', backgroundColor: myColors.primaryColor, colorText: myColors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // Ajoute ou modifie une boutique
  Future<void> saveStore({
    String? storeId,
    required String userId,
    required String name,
    required String description,
  }) async {
    try {
      isLoading.value = true;
      final CollectionReference storesRef = _firestore.collection('profiles').doc(userId).collection('stores');
      DocumentReference docRef;

      if (storeId == null) {
        // Nouvelle boutique
        final SubscriptionController subCtrl = Get.find();
        final canCreate = await subCtrl.canCreateStore(userId);
        if (!canCreate) {
          throw Exception('Limite de boutiques atteinte ou abonnement inactif.');
        }
        docRef = storesRef.doc();
      } else {
        // Modification d'une boutique existante
        docRef = storesRef.doc(storeId);
      }
      
      final existingData = await docRef.get();
      final Map<String, dynamic>? existingStoreData = existingData.data() as Map<String, dynamic>?;

      await docRef.set({
        'id': docRef.id,
        'name': name.trim(),
        'description': description.trim(),
        'createdAt': storeId == null 
            ? FieldValue.serverTimestamp() 
            : existingStoreData?['createdAt'] ?? FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

     

Get.snackbar(
  'Succès',
  'Boutique enregistrée avec succès.',
  backgroundColor: Colors.green,
  colorText: myColors.white,
);

await fetchUserStores(userId);
await fetchAllStores();

Future.delayed(const Duration(milliseconds: 300), () {
  // Ferme le snackbar si encore présent
  if (Get.isOverlaysOpen ?? false) Get.back();

  // Ferme la page AddStorePage
  try {
    Get.back();
  } catch (e) {
    print('Impossible de pop la page AddStore: $e');
  }
});

      
    } catch (e) {
      print('Erreur enregistrement boutique : $e');
      Get.snackbar('Erreur', 'Impossible d\'enregistrer la boutique : ${e.toString()}', backgroundColor: Colors.red, colorText: myColors.white);
    } finally {
      isLoading.value = false;
     
    }
  }

  // Supprime une boutique et ses produits
  Future<void> deleteStore({required String storeId, required String userId}) async {
    try {
      isLoading.value = true;
      final storeDocRef = _firestore.collection('profiles').doc(userId).collection('stores').doc(storeId);
      // 1. Supprimer tous les produits de cette boutique
      final productsSnapshot = await storeDocRef.collection('products').get();
      final batch = _firestore.batch();
      for (var doc in productsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      // 2. Supprimer la boutique elle-même
      await storeDocRef.delete();
      Get.snackbar('Succès', 'Boutique et ses produits supprimés.', backgroundColor: Colors.green, colorText: myColors.white);
      fetchUserStores(userId); // Rafraîchir la liste
      fetchAllStores(); // Rafraîchir toutes les boutiques pour l'explorer
    } catch (e) {
      print('Erreur suppression boutique : $e');
      Get.snackbar('Erreur', 'Impossible de supprimer la boutique : $e', backgroundColor: Colors.red, colorText: myColors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // --- filtre et tri dynamiques (pour la page Explorer) ---
  void applyFilters() {
    var list = List<Map<String, dynamic>>.from(allStores); // Utilise allStores

    // 💰 FILTRE ABONNEMENT : N'afficher que les boutiques dont le propriétaire a un abonnement actif
    list = list.where((s) {
      final bool ownerHasActiveSubscription = (s['ownerHasActiveSubscription'] as bool?) ?? false;
      return ownerHasActiveSubscription;
    }).toList();

    // 🔍 Filtre recherche
    if (searchQuery.value.isNotEmpty) {
      final q = searchQuery.value.toLowerCase();
      list = list.where((s) {
        // Accès sécurisé aux valeurs du Map
        final storeName = (s['name'] as String?)?.toLowerCase() ?? '';
        final storeCity = (s['city'] as String?)?.toLowerCase() ?? '';
        final storeDescription = (s['description'] as String?)?.toLowerCase() ?? '';
        return storeName.contains(q) || storeCity.contains(q) || storeDescription.contains(q);
      }).toList();
    }

    // 🏙️ Filtre par ville
    if (selectedCity.value.isNotEmpty) {
      list = list.where((s) => (s['city'] as String?) == selectedCity.value).toList();
    }

    // 🔽 Tri
    switch (sortOption.value) {
      case 'Plus récents':
        list.sort((a, b) {
          final DateTime? dateA = (a['createdAt'] is Timestamp) ? (a['createdAt'] as Timestamp).toDate() : (a['createdAt'] as DateTime?);
          final DateTime? dateB = (b['createdAt'] is Timestamp) ? (b['createdAt'] as Timestamp).toDate() : (b['createdAt'] as DateTime?);
          if (dateA == null || dateB == null) return 0; // Gérer les cas où createdAt est null
          return dateB.compareTo(dateA);
        });
        break;
      case 'Plus populaires':
        list.sort((b, a) => (a['totalProducts'] as int? ?? 0).compareTo(b['totalProducts'] as int? ?? 0));
        break;
      case 'Aléatoire':
        list.shuffle();
        break;
    }

    filteredStores.assignAll(list); // Met à jour filteredStores pour l'Explorer
  }
}
