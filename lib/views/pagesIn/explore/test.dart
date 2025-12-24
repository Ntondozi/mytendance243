import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/navIds.dart';
import '../../../controlers/ColorsData.dart';
import '../../../models/productModel.dart';
import '../../../controlers/cartController.dart';

class CartPage extends StatelessWidget {
  CartPage({super.key});

  final CartController cartController = Get.find<CartController>();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    double adaptiveSize(double small, double medium, double large) {
      if (width <= 500) return small;
      if (width <= 900) return medium;
      return large;
    }

    return Scaffold(
      backgroundColor: Colorsdata().background,
      body: Column(
        children: [
          // ------------------- HEADER -------------------
          Container(
            padding: EdgeInsets.all(adaptiveSize(width / 33, 20, 30)),
            color: Colorsdata().white,
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          Get.toNamed('/ExploreInPage/back', id: NavInIds.explorer);
                        },
                        icon: Icon(Icons.arrow_back_ios),
                      ),
                      Text(
                        'Vani',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: adaptiveSize(20, 24, 28),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: adaptiveSize(10, 20, 25)),
                InkWell(
                  onTap: () => Get.toNamed('/ExploreInPage/profil', id: NavInIds.explorer),
                  child: Container(
                    width: width < 600 ? 30 : 30,
                    height: height < 600 ? 20 : 30,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 141, 43, 43),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text('J', style: TextStyle(color: Colorsdata().white)),
                    ),
                  ),
                )
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
                  children: [
                    // Titre et total items
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                            children: [
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
                        width: double.infinity,
                        padding: EdgeInsets.all(15),
                        margin: EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colorsdata().white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: NetworkImage(product.imageUrls.first),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(product.title,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  Text(product.storeName ?? "Boutique inconnue"),
                                  SizedBox(height: 5),
                                  Text("${product.price.toStringAsFixed(2)} FC",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colorsdata().buttonHover)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: () => cartController.removeFromCart(product),
                            ),
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
                        children: [
                          Text('Résumé de la commande',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
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
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colorsdata().buttonHover,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(7)),
                            ),
                            onPressed: () {
                              // Procéder à l'achat
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.sell_outlined, color: Colorsdata().white),
                                SizedBox(width: 20),
                                Text("Procéder à l'achat",
                                    style: TextStyle(color: Colorsdata().white)),
                              ],
                            ),
                          ),
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
