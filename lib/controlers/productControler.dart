// file: lib/controlers/productControler.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/productModel.dart';
import 'ColorsData.dart';
import 'subscription_controller.dart';
import '../services/image_service_products.dart';
import 'boostController.dart';

class ProductController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RxList<ProductModel> products = <ProductModel>[].obs;
  final RxList<ProductModel> storeProducts = <ProductModel>[].obs;

  final RxBool isLoading = false.obs;
  StreamSubscription? _favoritesSubscription;

  SubscriptionController get _subscriptionController => Get.find<SubscriptionController>();
  BoostController get _boostController => Get.find<BoostController>();

  final Colorsdata myColors = Colorsdata();
  final ImageServiceProduct _imageService = ImageServiceProduct();

  RxString searchQuery = ''.obs;
  RxString? selectedCategory = RxString('');
  RxString? selectedCondition = RxString('');
  RxDouble minPrice = 0.0.obs;
  RxDouble maxPrice = 100000000.0.obs;
  RxString sortBy = 'Meilleur score'.obs;

  final RxString currentUserId = (FirebaseAuth.instance.currentUser?.uid ?? '').obs;
  RxList<ProductModel> favoriteProducts = <ProductModel>[].obs;

  bool hasShuffled = false;
  bool isManualUpdate = false;

  StreamSubscription? _productsSubscription;
  StreamSubscription? _storeProductsSubscription;

  final Map<String, double> _scoreWeights = {
    'abonnement': 0.30,
    'boost_payant_max': 0.55,
    'vues': 0.10,
    'completude': 0.05,
    'favoris': 0.05,
    'product_freshness_max': 0.55,
    'account_freshness_max': 0.55,
    'account_loyalty_max': 0.50,
  };

  @override
  void onInit() {
    super.onInit();
    fetchAllProductsRealtime();
    listenFavoritesRealtime();
  }

  @override
  void onClose() {
    _productsSubscription?.cancel();
    _storeProductsSubscription?.cancel();
     _favoritesSubscription?.cancel(); // 🔹 ajouté
    super.onClose();
  }

  void fetchAllProductsRealtime() {
    isLoading.value = true;
    _productsSubscription?.cancel();

    _productsSubscription = _firestore
        .collectionGroup('products')
        .snapshots()
        .listen((querySnapshot) async {
      List<ProductModel> tempList = [];

      final List<Future<ProductModel>> productFutures = [];
      for (var doc in querySnapshot.docs) {
        final pathSegments = doc.reference.path.split('/');
        String? sellerId;
        String? storeId;

        if (pathSegments.length >= 4) {
          sellerId = pathSegments[1];
          storeId = pathSegments[3];
        }

        productFutures.add(_processProductDocument(doc, sellerId, storeId));
      }

      final processedProducts = await Future.wait(productFutures);
      tempList.assignAll(processedProducts);

      tempList.sort((a, b) => _calculateProductScore(b).compareTo(_calculateProductScore(a)));

      products.assignAll(tempList);

      // 🔹 Mettre à jour les favoris uniquement après avoir chargé products et currentUserId
      if (currentUserId.value.isNotEmpty) {
        updateFavoriteProducts();
      }

      isLoading.value = false;

    }, onError: (e) {
      print('Erreur récupération produits en temps réel : $e');
      isLoading.value = false;
    });
  }

  void fetchProductsForStore(String sellerId, String storeId) {
    isLoading.value = true;
    _storeProductsSubscription?.cancel();

    _storeProductsSubscription = _firestore
        .collection('profiles')
        .doc(sellerId)
        .collection('stores')
        .doc(storeId)
        .collection('products')
        .snapshots()
        .listen((querySnapshot) async {
      List<ProductModel> tempList = [];

      final List<Future<ProductModel>> productFutures = [];
      for (var doc in querySnapshot.docs) {
        productFutures.add(_processProductDocument(doc, sellerId, storeId));
      }

      final processedProducts = await Future.wait(productFutures);
      tempList.assignAll(processedProducts);

      storeProducts.assignAll(tempList);
      isLoading.value = false;
    }, onError: (e) {
      print('Erreur récupération produits pour boutique : $e');
      Get.snackbar('Erreur', 'Impossible de charger les produits de la boutique.',
          backgroundColor: Colors.red, colorText: myColors.white);
      isLoading.value = false;
    });
  }

  Future<ProductModel> _processProductDocument(
      DocumentSnapshot doc, String? sellerId, String? storeId) async {
    final data = doc.data() as Map<String, dynamic>;
    String? ownerName;
    String? storeName;
    bool? ownerHasActiveSubscription;
    bool? ownerUsedTrial;
    DateTime? sellerCreatedAt;

    LocalSubscription? sellerSubscription;

    if (sellerId != null) {
      final userDocFuture = _firestore.collection('profiles').doc(sellerId).get();
      final storeDocFuture = storeId != null
          ? _firestore.collection('profiles').doc(sellerId).collection('stores').doc(storeId).get()
          : Future.value(null);

      final ownerSubscriptionFuture =
          _subscriptionController.readSubscriptionFromFirestore(sellerId);

      final results = await Future.wait([userDocFuture, storeDocFuture, ownerSubscriptionFuture]);

      final userDoc = results[0] as DocumentSnapshot;
      final storeDoc = results[1] as DocumentSnapshot?;
      sellerSubscription = results[2] as LocalSubscription?;

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>?;
        ownerName = userData?['username'];

        final createdAtTimestamp = userData?['created_at'];
        if (createdAtTimestamp is Timestamp) {
          sellerCreatedAt = createdAtTimestamp.toDate();
        } else if (createdAtTimestamp is DateTime) {
          sellerCreatedAt = createdAtTimestamp;
        }
      }

      if (storeDoc != null && storeDoc.exists) {
        final storeData = storeDoc.data() as Map<String, dynamic>?;
        storeName = storeData?['name'] ?? storeDoc.id;
      }

      if (sellerSubscription != null) {
        ownerUsedTrial = sellerSubscription.trialUsed;
        ownerHasActiveSubscription =
            sellerSubscription.expiresAtMillis > DateTime.now().millisecondsSinceEpoch;
      } else {
        ownerUsedTrial = false;
        ownerHasActiveSubscription = false;
      }
    }

    List<String> favorites = List<String>.from(data['favorites'] ?? []);
    List<String> viewers = List<String>.from(data['viewers'] ?? []);

    final ProductModel baseProduct = ProductModel.fromFirestore({
      ...data,
      'id': doc.id,
      'ownerName': ownerName,
      'storeName': storeName,
      'favorites': favorites,
      'viewers': viewers,
      'ownerHasActiveSubscription': ownerHasActiveSubscription,
      'ownerUsedTrial': ownerUsedTrial,
      'sellerCreatedAt': sellerCreatedAt,
    });

    final double completude = baseProduct.calculateCompletudeScore();

    return baseProduct.copyWith(completudeScore: completude);
  }

  double _calculateProductScore(ProductModel product) {
    double score = 0.0;
    final now = DateTime.now();

    // 🔥 Nouveau : un seul critère — l'abonnement actif (essai ou payé)
    if (product.ownerHasActiveSubscription == true) {
      score += _scoreWeights['abonnement']! * 100;
    }

    if (product.boostLevel != null &&
        product.boostExpiresAt != null &&
        product.boostExpiresAt!.isAfter(now)) {
      switch (product.boostLevel) {
        case 'petit':
          score += 0.25 * _scoreWeights['boost_payant_max']! * 100;
          break;
        case 'moyen':
          score += 0.40 * _scoreWeights['boost_payant_max']! * 100;
          break;
        case 'grand':
          score += _scoreWeights['boost_payant_max']! * 100;
          break;
      }
    }

    final totalViews = product.viewers.length;
    if (totalViews > 100) {
      score += _scoreWeights['vues']! * 100;
    } else if (totalViews > 50) {
      score += 0.07 * 100;
    } else if (totalViews > 10) {
      score += 0.04 * 100;
    } else {
      score += 0.01 * 100;
    }

    final totalFavorites = product.favorites.length;
    if (totalFavorites > 20) {
      score += _scoreWeights['favoris']! * 100;
    } else if (totalFavorites > 10) {
      score += 0.03 * 100;
    } else if (totalFavorites > 0) {
      score += 0.01 * 100;
    }

    score += (product.completudeScore ?? 0.0) * _scoreWeights['completude']! * 100;

    if (product.createdAt != null) {
      final daysSinceCreation = now.difference(product.createdAt!).inDays;
      if (daysSinceCreation < 7) {
        final decayFactor = (7 - daysSinceCreation) / 7;
        score += decayFactor * _scoreWeights['product_freshness_max']! * 100;
      }
    }

    if (product.sellerCreatedAt != null) {
      final accountAgeInDays = now.difference(product.sellerCreatedAt!).inDays;
      final accountAgeInMonths = (accountAgeInDays / 30).floor();

      if (accountAgeInDays < 30) {
        if (accountAgeInDays < 20) {
          final decayFactor = (20 - accountAgeInDays) / 20;
          score += decayFactor * _scoreWeights['account_freshness_max']! * 100;
        }
      } else {
        if (accountAgeInMonths > 0) {
          double loyaltyBonus = accountAgeInMonths * 10.0;
          score += loyaltyBonus.clamp(0.0, _scoreWeights['account_loyalty_max']! * 100);
        }
      }
    }

    return score.clamp(0.0, 1000.0);
  }

  // NOUVEAU GETTER POUR LA LANDING PAGE
  List<ProductModel> get landingPageProducts {
    List<ProductModel> list = List.from(products);

    // Filtrer uniquement les produits des propriétaires avec abonnement actif
    list = list.where((p) {
      return p.ownerHasActiveSubscription == true;
    }).toList();

    // Trier par meilleur score
    list.sort((a, b) => _calculateProductScore(b).compareTo(_calculateProductScore(a)));

    // Limiter à 6 produits
    return list.take(6).toList();
  }

  // 🔥🔥🔥 PARTIE MODIFIÉE — NOUVELLE LOGIQUE
  List<ProductModel> get filteredProducts {
    List<ProductModel> list = List.from(products);

    list = list.where((p) {
      if (p.ownerHasActiveSubscription == null) return false;
      return p.ownerHasActiveSubscription == true;
    }).toList();

    if (selectedCategory?.value.isNotEmpty ?? false) {
      list = list
          .where((p) =>
              p.category.toLowerCase() ==
              selectedCategory!.value.toLowerCase())
          .toList();
    }

    if (selectedCondition?.value.isNotEmpty ?? false) {
      list = list
          .where((p) =>
              p.condition.toLowerCase() ==
              selectedCondition!.value.toLowerCase())
          .toList();
    }

    list = list
        .where((p) => p.price >= minPrice.value && p.price <= maxPrice.value)
        .toList();

    if (searchQuery.value.isNotEmpty) {
      list = list
          .where((p) =>
              p.title.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
              p.description.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
              (p.storeName ?? '').toLowerCase().contains(searchQuery.value.toLowerCase()) ||
              (p.ownerName ?? '').toLowerCase().contains(searchQuery.value.toLowerCase()))
          .toList();
    }

    if (!isManualUpdate) {
      switch (sortBy.value) {
        case 'Prix croissant':
          list.sort((a, b) => a.price.compareTo(b.price));
          break;
        case 'Prix décroissant':
          list.sort((a, b) => b.price.compareTo(a.price));
          break;
        case 'Plus récents':
          list.sort((a, b) => (b.createdAt ?? DateTime.now())
              .compareTo(a.createdAt ?? DateTime.now()));
          break;
        case 'Meilleur score':
        default:
          list.sort((a, b) => _calculateProductScore(b).compareTo(_calculateProductScore(a)));
          break;
      }
    }

    return list;
  }

  // ========== AUTRES FONCTIONS (inchangées) ==========

  void applyFilters({
    String? category,
    String? condition,
    double? min,
    double? max,
    String? sort,
  }) {
    selectedCategory?.value = category ?? '';
    selectedCondition?.value = condition ?? '';
    minPrice.value = min ?? 0;
    maxPrice.value = max ?? 100000000;
    sortBy.value = sort ?? 'Meilleur score';
    update();
  }

  void search(String query) {
    searchQuery.value = query;
    update();
  }

  void resetFilters() {
    selectedCategory?.value = '';
    selectedCondition?.value = '';
    minPrice.value = 0;
    maxPrice.value = 100000000;
    sortBy.value = 'Meilleur score';
    searchQuery.value = '';
    update();
  }

  void updateFavoriteProducts() {
  // Ne rien faire si les données ne sont pas encore prêtes
  if (products.isEmpty || currentUserId.value.isEmpty) return;

  favoriteProducts.value = filteredProducts
      .where((p) => p.favorites.contains(currentUserId.value))
      .toList();
}


  Future<void> addView(String productId, String userId) async {
    try {
      final productRef = await _findProductRefById(productId);
      if (productRef == null) return;

      await productRef.update({
        'viewers': FieldValue.arrayUnion([userId])
      });

      _updateProductListAfterAction(productId, (p) => p.viewers.add(userId));
    } catch (e) {
      print('Erreur ajout vue : $e');
    }
  }

  Future<void> toggleFavorite(String productId, String userId) async {
    
    try {
      final productRef = await _findProductRefById(productId);
      if (productRef == null) return;

      bool isFavorite = false;

      final productInProducts = products.firstWhereOrNull((p) => p.id == productId);
      if (productInProducts != null) {
        isFavorite = productInProducts.favorites.contains(userId);
      } else {
        final productInStoreProducts =
            storeProducts.firstWhereOrNull((p) => p.id == productId);
        if (productInStoreProducts != null) {
          isFavorite = productInStoreProducts.favorites.contains(userId);
        }
      }

      await productRef.update({
        'favorites': isFavorite
            ? FieldValue.arrayRemove([userId])
            : FieldValue.arrayUnion([userId])
      });

      _updateProductListAfterAction(productId, (p) {
        if (isFavorite) {
          p.favorites.remove(userId);
        } else {
          p.favorites.add(userId);
        }
      });
      updateFavoriteProducts();
    } catch (e) {
      print('Erreur favoris : $e');
      Get.snackbar('Erreur', 'Impossible de gérer les favoris.',
          backgroundColor: Colors.red, colorText: myColors.white);
    }
  }

  Future<String?> getStoreIdForProduct(String userId, String productId) async {
    try {
      final querySnapshot = await _firestore
          .collectionGroup('products')
          .where('id', isEqualTo: productId)
          .where('sellerId', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final productDoc = querySnapshot.docs.first;
        final pathSegments = productDoc.reference.path.split('/');

        if (pathSegments.length >= 4) {
          return pathSegments[3];
        }
      }
    } catch (e) {
      print('Erreur récupération storeId : $e');
    }

    return null;
  }

  void _updateProductListAfterAction(
      String productId, Function(ProductModel) updateFn) {
    final indexInProducts = products.indexWhere((p) => p.id == productId);

    if (indexInProducts != -1) {
      isManualUpdate = true;
      updateFn(products[indexInProducts]);
      products.refresh();
      isManualUpdate = false;
    }

    final indexInStoreProducts =
        storeProducts.indexWhere((p) => p.id == productId);

    if (indexInStoreProducts != -1) {
      isManualUpdate = true;
      updateFn(storeProducts[indexInStoreProducts]);
      storeProducts.refresh();
      isManualUpdate = false;
    }
  }

  Future<DocumentReference<Map<String, dynamic>>?> _findProductRefById(
      String productId) async {
    final snapshot = await _firestore
        .collectionGroup('products')
        .where('id', isEqualTo: productId)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.reference;
    }
    return null;
  }

  Future<void> deleteProduct({
    required String productId,
    required String storeId,
    required String userId,
  }) async {
    isLoading.value = true;

    try {
      await _firestore
          .collection('profiles')
          .doc(userId)
          .collection('stores')
          .doc(storeId)
          .collection('products')
          .doc(productId)
          .delete();

      Get.snackbar('Succès', 'Produit supprimé.',
          backgroundColor: Colors.green, colorText: myColors.white);
    } catch (e) {
      Get.snackbar('Erreur', 'Suppression impossible.',
          backgroundColor: Colors.red, colorText: myColors.white);
    } finally {
      isLoading.value = false;
    }
  }

  void listenFavoritesRealtime() {
  _favoritesSubscription?.cancel();
  
  _favoritesSubscription = _firestore
      .collectionGroup('products')
      .snapshots()
      .listen((querySnapshot) {
    // On met à jour favoriteProducts en temps réel
    if (products.isNotEmpty && currentUserId.value.isNotEmpty) {
      updateFavoriteProducts();
    }

  }, onError: (e) {
    print("Erreur temps réel favoris: $e");
  });
}
}
