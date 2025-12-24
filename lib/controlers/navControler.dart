// file: lib/controlers/navControler.dart

import 'package:get/get.dart';

class NavigationOutController extends GetxController {
  static NavigationOutController get to => Get.find();
  var selectedIndex = 0.obs;

  void changeIndex(int index) {
    selectedIndex.value = index;
  }
}

class NavigationInController extends GetxController {
  // CORRECTION : Doit faire référence à elle-même, pas à NavigationOutController
  static NavigationInController get to => Get.find();

  // Votre selectedIndex existant pour la navigation principale de l'application (BottomNavBar/Rail)
  var selectedIndex = 0.obs;

  // NOUVEAU : Index pour la navigation interne du Dashboard
  var dashboardPageIndex = 0.obs;

  void changeIndex(int index) {
    selectedIndex.value = index;
  }

  void changeDashboardPageIndex(int index) {
    dashboardPageIndex.value = index;
  }
}
