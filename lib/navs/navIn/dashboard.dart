// file: lib/navs/navIn/dashboard.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tendance/models/navIds.dart'; // Assurez-vous que ce chemin est correct
import 'package:tendance/views/pagesIn/dashboard/user_dashboard_page.dart'; // Importez la nouvelle page

class Dashboardnav extends StatelessWidget {
  const Dashboardnav({super.key});

  @override
  Widget build(BuildContext context) {
    // Le Navigator principal pour le dashboard pointera vers la UserDashboardPage
    // qui gérera sa propre navigation interne.
    return Navigator(
      key: Get.nestedKey(NavInIds.dashboard),
      onGenerateRoute: (settings) {
        // La route par défaut du dashboard est maintenant UserDashboardPage
        return GetPageRoute(
          settings: settings,
          page: () => const UserDashboardPage(),
        );
      },
    );
  }
}
