import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tendance/models/productModel.dart';
import 'package:tendance/views/pagesIn/explore/detailProduct.dart';
import '../../models/navIds.dart';


class Homeinnav extends StatelessWidget {
  const Homeinnav({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(

      // key: Get.nestedKey(NavInIds.home),
      onGenerateRoute: (settings) {
        if (settings.name == '/vvv'){
          return GetPageRoute(
            settings: settings,
            page: () => Container(color: Colors.red,),
          );
        } else {
          return GetPageRoute(
            settings: settings,
            page: () => Container(color: Colors.amber,)
          );
        }
        
      },
    );
  }
}