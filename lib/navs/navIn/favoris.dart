import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tendance/views/pagesIn/favoris/favorisPage.dart';
import '../../models/navIds.dart';
import '../../models/productModel.dart';
import '../../views/pagesIn/dashboard/my_subscription_page.dart';
import '../../views/pagesIn/dashboard/storeDetailClient.dart';
import '../../views/pagesIn/explore/cart.dart';
import '../../views/pagesIn/explore/detailProduct.dart';
import '../../views/pagesIn/explore/notification.dart';
import '../../views/pagesIn/explore/profil.dart';
import '../../views/pagesIn/explore/store.dart';


class Favorinav extends StatelessWidget {
  const Favorinav({super.key});
  @override
  Widget build(BuildContext context) {
    return Navigator(

      key: Get.nestedKey(NavInIds.favoris),
      onGenerateRoute: (settings) {
        if (settings.name == '/ddd'){
          return GetPageRoute(
            settings: settings,
            page: () => Container(color: Colors.red,),
          );
        } if (settings.name == '/favoris/detail') {
        final product = settings.arguments as ProductModel; // 🔹 récupère l'objet
        return GetPageRoute(
          settings: settings,
          page: () => Detailproduct(product: product),
        );} if (settings.name == '/favoris/cart'){
          return GetPageRoute(
            settings: settings,
            page: () => CartPage(),
          );}
          if (settings.name == '/favoris/storeDetail') {
        final args = settings.arguments as Map<String, dynamic>;
        final storeId = args['storeId'];
        final sellerId = args['sellerId'];
        return GetPageRoute(
          settings: settings,
          page: () => StoreDetailPageClient(
            storeId: storeId,
            sellerId: sellerId,
          ),
        );
      }if (settings.name == '/favoris/notifications'){
          final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
        return GetPageRoute(
          settings: settings,
          page: () => NotificationsPage(userId: userId),
        );
        }if (settings.name == '/favoris/store'){
          return GetPageRoute(
            settings: settings,
            page: () => StorePage(),
          );
        } if (settings.name == '/favoris/cart'){
          return GetPageRoute(
            settings: settings,
            page: () => CartPage(),
          );
        }if (settings.name == '/favoris/profil'){
          return GetPageRoute(
            settings: settings,
            page: () => ProfilPage(),
          );
        } if (settings.name == '/favoris/MySubscriptionPage') {
        return GetPageRoute(
          settings: settings,
          page: () => MySubscriptionPage(),
        );
        }    
        else {
          return GetPageRoute(
            settings: settings,
            page: () => FavoriteProductsPage(),
          );
        }
        
      },
    );
  }
}