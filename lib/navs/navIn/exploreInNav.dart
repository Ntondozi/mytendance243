import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tendance/models/productModel.dart';
import 'package:tendance/views/pagesIn/dashboard/my_subscription_page.dart';
import 'package:tendance/views/pagesIn/dashboard/storeDetailClient.dart';
import 'package:tendance/views/pagesIn/dashboard/subscription/subscription_page.dart';
import 'package:tendance/views/pagesIn/explore/detailProduct.dart';
import 'package:tendance/views/pagesIn/explore/notification.dart';
import 'package:tendance/views/pagesIn/explore/profil.dart';
import 'package:tendance/views/pagesIn/explore/store.dart';
import '../../models/navIds.dart';
import '../../views/pagesIn/explore/cart.dart';
import '../../views/pagesIn/explore/exploreInPage.dart';


class Exploreinnav extends StatelessWidget {
  const Exploreinnav({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(

      key: Get.nestedKey(NavInIds.explorer),
      onGenerateRoute: (settings) {
        if (settings.name == '/ExploreInPage/notifications'){
          final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
        return GetPageRoute(
          settings: settings,
          page: () => NotificationsPage(userId: userId),
        );
        }if (settings.name == '/ExploreInPage/store'){
          return GetPageRoute(
            settings: settings,
            page: () => StorePage(),
          );
        } if (settings.name == '/ExploreInPage/cart'){
          return GetPageRoute(
            settings: settings,
            page: () => CartPage(),
          );
        }if (settings.name == '/ExploreInPage/profil'){
          return GetPageRoute(
            settings: settings,
            page: () => ProfilPage(),
          );
        }
        if (settings.name == '/ExploreInPage/detail') {
        final product = settings.arguments as ProductModel; // 🔹 récupère l'objet
        return GetPageRoute(
          settings: settings,
          page: () => Detailproduct(product: product),
        );
      }
      if (settings.name == '/ExploreInPage/storeDetail') {
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
      }if (settings.name == '/ExploreInPage/MySubscriptionPage') {
        return GetPageRoute(
          settings: settings,
          page: () => MySubscriptionPage(),
        );
        }

         else {
          return GetPageRoute(
            settings: settings,
            page: () => Exploreinpage(),
          );
        }
        
      },
    );
  }
}