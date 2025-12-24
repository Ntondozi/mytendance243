import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/productModel.dart';

class CartController extends GetxController {
  var cartItems = <ProductModel>[].obs;
  var itemCount = 0.obs;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void onInit() {
    super.onInit();
    _loadCartFromFirebase();
  }

  // Charger le panier depuis Firestore
  Future<void> _loadCartFromFirebase() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final snapshot = await _firestore
          .collection('carts')
          .doc(user.uid)
          .collection('items')
          .get();

      final products = snapshot.docs.map((doc) {
        final data = doc.data();
        return ProductModel(
          id: data['id'] ?? '',
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          price: (data['price'] ?? 0).toDouble(),
          category: data['category'] ?? '',
          condition: data['condition'] ?? '',
          size: data['size'],
          brand: data['brand'],
          color: data['color'],
          imageUrls: List<String>.from(data['imageUrls'] ?? []),
          sellerId: data['sellerId'] ?? '',
          storeId: data['storeId'] ?? '',
          createdAt: data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : null,
          ownerName: data['ownerName'],
          storeName: data['storeName'],
          favorites: List<String>.from(data['favorites'] ?? []),
          viewers: List<String>.from(data['viewers'] ?? []),
        );
      }).toList();

      cartItems.assignAll(products);
      itemCount.value = cartItems.length;
    } catch (e) {
      print("Erreur chargement panier : $e");
    }
  }

  // Ajouter un produit au panier
  Future<void> addToCart(ProductModel product) async {
    final user = _auth.currentUser;
    if (user == null) return;

    cartItems.add(product);
    itemCount.value = cartItems.length;

    try {
      await _firestore
          .collection('carts')
          .doc(user.uid)
          .collection('items')
          .doc(product.id)
          .set(product.toMap());
    } catch (e) {
      print("Erreur ajout panier : $e");
    }
  }

  // Supprimer un produit du panier
  Future<void> removeFromCart(ProductModel product) async {
    final user = _auth.currentUser;
    if (user == null) return;

    cartItems.removeWhere((p) => p.id == product.id); // 🔹 par ID
    itemCount.value = cartItems.length;

    try {
      await _firestore
          .collection('carts')
          .doc(user.uid)
          .collection('items')
          .doc(product.id)
          .delete();
    } catch (e) {
      print("Erreur suppression panier : $e");
    }
  }

  // Vider le panier
  Future<void> clearCart() async {
    final user = _auth.currentUser;
    if (user == null) return;

    cartItems.clear();
    itemCount.value = 0;

    try {
      final batch = _firestore.batch();
      final itemsRef =
          _firestore.collection('carts').doc(user.uid).collection('items');
      final items = await itemsRef.get();
      for (var doc in items.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print("Erreur vidage panier : $e");
    }
  }

  // Pour le badge uniquement
  void clearBadge() {
    itemCount.value = 0;
  }
}
