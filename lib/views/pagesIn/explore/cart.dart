import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../controlers/String.dart';
import '../../../controlers/navControler.dart';
import '../../../models/navIds.dart';
import '../../../controlers/ColorsData.dart';
import '../../../models/productModel.dart';
import '../../../controlers/cartController.dart';
import '../messages/messagesPage.dart'; // NOUVEAU: Importez votre page de messages
import 'package:firebase_auth/firebase_auth.dart'; // NOUVEAU: Importez Firebase Auth

class CartPage extends StatelessWidget {
  CartPage({super.key});
  final CartController cartController = Get.find<CartController>();
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    // final height = MediaQuery.of(context).size.height; // non utilisé, peut être supprimé
    double adaptiveSize(double small, double medium, double large) {
      if (width <= 500) return small;
      if (width <= 900) return medium;
      return large;
    }
    // Récupérer l'ID de l'utilisateur Firebase actuellement connecté
    // Cette variable sera utilisée pour la comparaison sellerId != currentFirebaseUserId
    final String? currentFirebaseUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colorsdata().background,
      body: Column(
        children: <Widget>[
          if(!kIsWeb) SizedBox(height: 35,) else SizedBox(),
          // ------------------- HEADER -------------------
          Container(
            padding: EdgeInsets.all(adaptiveSize(width / 33, 20, 30)),
            color: Colorsdata().white,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Row(
                    children: <Widget>[
                      IconButton(
                        onPressed: () {
                          final navController = Get.find<NavigationInController>();
                          switch (navController.selectedIndex.value) {
                            case 0:
                              Get.back(id: NavInIds.explorer);
                              break;
                            case 1:
                              Get.back(id: NavInIds.favoris);
                              break;
                            case 2:
                              Get.back(id: NavInIds.messages);
                              break;
                            case 3:
                              Get.back(id: NavInIds.dashboard);
                              break;
                            default:
                              print("Index inconnu: ${navController.selectedIndex.value}");
                          }
                        },
                        icon: Icon(Icons.arrow_back_ios),
                      ),
                      Text(
                        word().name,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: adaptiveSize(20, 24, 28),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // L'espace pour le bouton du panier dans le header est vide ici, si vous voulez l'ajouter...
              ],
            ),
          ),
          // ------------------- BODY -------------------
          Expanded(
            child: Obx(() {
              if (cartController.cartItems.isEmpty) {
                return Center(child: Text("Votre panier est vide"));
              }
              return SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    // Titre et total items
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text('Mon Panier',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black)),
                              Text("Articles que vous souhaitez acheter",
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.normal,
                                      color: Colorsdata().buttonHover)),
                            ],
                          ),
                          Row(
                            children: <Widget>[
                              Icon(Icons.shop_outlined, size: 15),
                              SizedBox(width: 3),
                              Text('${cartController.cartItems.length} articles',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black)),
                            ],
                          )
                        ],
                      ),
                    ),
                    // Liste des articles
                    ...cartController.cartItems.map((product) {
                      return Container(
                        height: 230,
                        margin: EdgeInsets.all(8),
                        padding: EdgeInsets.only(bottom: 8, right: 10),
                        decoration: BoxDecoration(
                          color: Colorsdata().white,
                          border: Border(bottom: BorderSide(color: Colors.grey))
                        ),
                        child: Row(
                          children: <Widget>[
                            Container(
                              width: 150,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: NetworkImage(product.imageUrls.first),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 8, left: 8,),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(product.title,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2, style: TextStyle(fontWeight: FontWeight.bold),),
                                    SizedBox(height: 7,),
                                    Text(product.storeName ?? "Boutique inconnue",
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1, style: TextStyle(fontWeight: FontWeight.normal, fontSize: 12),),
                                    SizedBox(height: 4,),
                                    Row(
                                      children: <Widget>[
                                        Container(
                                          padding: EdgeInsets.all(3),
                                          height: 30,
                                          decoration: BoxDecoration(
                                            color: Colorsdata().background,
                                            borderRadius: BorderRadius.circular(4)
                                          ),
                                          child: Align(
                                            alignment: AlignmentGeometry.center,
                                            child: Text(product.size ?? "Non spécifiée",
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1, style: TextStyle(fontWeight: FontWeight.normal, fontSize: 12), ),
                                          )
                                        ),
                                        SizedBox(width: 7,),
                                        Container(
                                          padding: EdgeInsets.all(3),
                                          height: 30,
                                          decoration: BoxDecoration(
                                            color: Colorsdata().background,
                                            borderRadius: BorderRadius.circular(4)
                                          ),
                                          child: Align(
                                            alignment: AlignmentGeometry.center,
                                            child: Text(product.condition,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1, style: TextStyle(fontWeight: FontWeight.normal, fontSize: 12),),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 7,),
                                    SizedBox(
                                      child: Row(children: <Widget>[
                                        Icon(Icons.calendar_month_outlined, size: 13,),
                                        SizedBox(width: 4,),
                                        Text("Publié le ", style: TextStyle(color: Colors.black, fontSize: 13)),
                                        Text(product.createdAt != null
                                        ? DateFormat("d MMMM yyyy", "fr_FR").format(product.createdAt!)
                                        : "Date inconnue",style: TextStyle(color: Colors.black, fontSize: 13))
                                      ],),
                                    ),
                                    Spacer(),
                                    Column(
                                      children: [
                                        SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red, // Changement de couleur pour "Retirer"
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(7)),
                                          ),
                                          icon: Icon(Icons.remove, color: Colors.white,), // Icone blanche
                                          onPressed: () => cartController.removeFromCart(product),
                                          label: Text('Retirer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),)), // Texte blanc
                                    ),
                                    SizedBox(height: 5,),

                                    // NOUVEAU: Bouton "Contacter le vendeur"
                                // Vérifie si le sellerId est disponible et différent de l'utilisateur actuel
                                // Utilise la variable currentFirebaseUserId que nous avons définie plus haut
                                if (currentFirebaseUserId != null && product.sellerId != null && product.sellerId != currentFirebaseUserId)
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colorsdata().primaryColor, // Couleur primaire pour le bouton de contact
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(7)),
                                    ),
                                    onPressed: () {
                                      // Naviguer vers la page de chat
                                      Get.to(() => ChatPage(
                                        receiverId: product.sellerId!,
                                        receiverName: product.ownerName ?? 'Vendeur', // Utilisez ownerName si disponible
                                      ));
                                    },
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: <Widget>[
                                        Icon(Icons.chat_outlined, color: Colors.white, size: 18),
                                        SizedBox(width: 8),
                                        Text("Message", style: TextStyle(color: Colors.white, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text("${product.price.toStringAsFixed(2)} FC", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),),
                                
                              ],
                            )
                          ],
                        ),
                      );
                    }).toList(),
                    // Résumé et total
                    Container(
                      padding: EdgeInsets.all(10),
                      margin: EdgeInsets.only(left: 15, bottom: 15, right: 15),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colorsdata().white,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Résumé de la commande',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text('Total',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 15)),
                              Text(
                                '${cartController.cartItems.fold<double>(0, (sum, item) => sum + item.price).toStringAsFixed(2)} FC',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 17)),
                            ],
                          ),
                          SizedBox(height: 8),
                          // Le bouton "Contacter le vendeur pour acheter" du bas est maintenant obsolète si nous avons un bouton par article.
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
