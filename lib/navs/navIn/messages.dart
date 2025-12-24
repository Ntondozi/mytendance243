import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tendance/views/pagesIn/messages/InboxPage.dart';
import '../../models/navIds.dart';
import '../../models/productModel.dart';
import '../../views/pagesIn/dashboard/my_subscription_page.dart';
import '../../views/pagesIn/dashboard/storeDetailClient.dart';
import '../../views/pagesIn/explore/cart.dart';
import '../../views/pagesIn/explore/detailProduct.dart';
import '../../views/pagesIn/explore/notification.dart';
import '../../views/pagesIn/explore/profil.dart';
import '../../views/pagesIn/explore/store.dart';


class Messagesnav extends StatelessWidget {
  const Messagesnav({super.key});
  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: Get.nestedKey(NavInIds.messages),
      onGenerateRoute: (settings) {
        if (settings.name == '/message/detail') {
        final product = settings.arguments as ProductModel; // 🔹 récupère l'objet
        return GetPageRoute(
          settings: settings,
          page: () => Detailproduct(product: product),
        );} if (settings.name == '/message/cart'){
          return GetPageRoute(
            settings: settings,
            page: () => CartPage(),
          );}
          if (settings.name == '/message/storeDetail') {
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
      }if (settings.name == '/message/notifications'){
          final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
        return GetPageRoute(
          settings: settings,
          page: () => NotificationsPage(userId: userId),
        );
        }if (settings.name == '/message/store'){
          return GetPageRoute(
            settings: settings,
            page: () => StorePage(),
          );
        } if (settings.name == '/message/cart'){
          return GetPageRoute(
            settings: settings,
            page: () => CartPage(),
          );
        }if (settings.name == '/message/profil'){
          return GetPageRoute(
            settings: settings,
            page: () => ProfilPage(),
          );
        }if (settings.name == '/message/MySubscriptionPage') {
        return GetPageRoute(
          settings: settings,
          page: () => MySubscriptionPage(),
        );
        }     
         else {
          return GetPageRoute(
            settings: settings,
            page: () => InboxPage(),
          );
        }
        
      },
    );
  }
}