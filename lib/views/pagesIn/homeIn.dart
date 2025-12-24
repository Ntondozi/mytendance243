// file: lib/views/pagesIn/homeIn.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:tendance/controlers/ColorsData.dart';
import 'package:tendance/navs/navIn/dashboard.dart';
import 'package:tendance/navs/navIn/exploreInNav.dart';
import 'package:tendance/navs/navIn/favoris.dart';
import 'package:tendance/navs/navIn/messages.dart';
import '../../controlers/navControler.dart';
import '../../controlers/authControler.dart';
import '../../models/navIds.dart'; // Assurez-vous que ce chemin est correct

class homeIn extends StatefulWidget {
  const homeIn({super.key});

  @override
  State<homeIn> createState() => _HomeInState();
}

class _HomeInState extends State<homeIn> {
  final NavigationInController navController = Get.put(NavigationInController());
  final AuthController authController = Get.find();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Liste des destinations principales pour la NavigationRail et la ConvexAppBar
  final List<Map<String, dynamic>> _mainNavItems = [
    {'icon': Icons.home_outlined, 'label': 'Accueil'},
    {'icon': Icons.favorite_outline, 'label': 'Favoris'},
    {'icon': Icons.message_outlined, 'label': 'Messages'},
    {'icon': Icons.dashboard_outlined, 'label': 'Dashboard'},
  ];

  Widget get content => IndexedStack(
        index: navController.selectedIndex.value,
        children: const [
          Exploreinnav(),
          Favorinav(),
          Messagesnav(),
          Dashboardnav(),
        ],
      );
      
  /// 🔁 Stream pour compter les messages non lus
  Stream<int> unreadCountStream(String currentUserId) {
    // Vérifiez si l'utilisateur est un invité ou si l'ID est invalide
    if (currentUserId == 'guest' || currentUserId.isEmpty) {
      return Stream.value(0); // Retourne un flux de 0 pour les invités
    }
    return firestore.collection('chats').snapshots().map((snapshot) {
      int total = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        // Vérifie si l'ID du chat contient currentUserId et s'il y a des messages non lus pour cet utilisateur
        if (doc.id.contains(currentUserId)) {
          final unread = List<String>.from(data['unread'] ?? []);
          if (unread.contains(currentUserId)) {
            total++;
          }
        }
      }
      return total;
    });
  }

  // AJOUTÉ : Pour obtenir la clé du Navigator correspondant à l'onglet actuel
  GlobalKey<NavigatorState>? _getNavigatorKey(int index) {
    switch (index) {
      case 0:
        return Get.nestedKey(NavInIds.explorer);
      case 1:
        return Get.nestedKey(NavInIds.favoris);
      case 2:
        return Get.nestedKey(NavInIds.messages);
      case 3:
        return Get.nestedKey(NavInIds.dashboard);
      default:
        return null;
    }
  }

  // AJOUTÉ : Gère l'appui sur le bouton retour du téléphone
  DateTime? _lastBackPressTime;

Future<bool> _onWillPop() async {
  final int currentIndex = navController.selectedIndex.value;
  final GlobalKey<NavigatorState>? navigatorKey = _getNavigatorKey(currentIndex);

  // Si le Navigator de l'onglet peut pop → dépile
  if (navigatorKey?.currentState != null && navigatorKey!.currentState!.canPop()) {
    navigatorKey.currentState!.pop();
    return false;
  }

  // Sinon on est sur la première page de l'onglet
  DateTime now = DateTime.now();
  if (_lastBackPressTime == null || now.difference(_lastBackPressTime!) > Duration(seconds: 2)) {
    _lastBackPressTime = now;

    // Affiche un toast ou SnackBar pour dire "appuyez à nouveau pour quitter"
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Appuyez à nouveau pour quitter l'application"),
        duration: Duration(seconds: 2),
      ),
    );
    return false; // Ne ferme pas l'app
  }

  // Si back press répété dans 2 secondes → afficher le popup
  bool? exit = await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text("Quitter l'application ?"),
      content: Text("Voulez-vous vraiment quitter l'application ?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text("Non"),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text("Oui"),
        ),
      ],
    ),
  );

  return exit ?? false;
}


  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isDesktop = width >= 800;

    // Obtenez l'ID de l'utilisateur actuel, ou 'guest' si non connecté
    final String currentUserId = authController.currentUser.value?.id ?? 'guest';

    // MODIFIÉ : Ajout du WillPopScope pour gérer le bouton retour
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Obx(
        () => Scaffold(
          body: isDesktop
              ? Row(
                  children: [
                    // 🧭 NavigationRail pour desktop (similaire au dashboard)
                    Obx(() => NavigationRail(
                          selectedIndex: navController.selectedIndex.value,
                          onDestinationSelected: (index) {
                            navController.changeIndex(index);
                          },
                          labelType: NavigationRailLabelType.all,
                          backgroundColor: Colorsdata().white,
                          selectedIconTheme: IconThemeData(color: Colorsdata().buttonHover),
                          unselectedIconTheme: const IconThemeData(color: Colors.grey),
                          selectedLabelTextStyle: TextStyle(color: Colorsdata().buttonHover, fontWeight: FontWeight.bold),
                          unselectedLabelTextStyle: const TextStyle(color: Colors.grey),
                          destinations: _mainNavItems.map((item) {
                            // Pour l'élément "Messages", ajoutez le badge des messages non lus
                            if (item['label'] == 'Messages' && currentUserId != 'guest') {
                              return NavigationRailDestination(
                                icon: StreamBuilder<int>(
                                  stream: unreadCountStream(currentUserId),
                                  builder: (context, snapshot) {
                                    final unreadCount = snapshot.data ?? 0;
                                    return Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Icon(item['icon'] as IconData),
                                        if (unreadCount > 0)
                                          Positioned(
                                            right: -5, // Ajustez la position du badge si nécessaire
                                            top: -5,
                                            child: Container(
                                              padding: EdgeInsets.all(3),
                                              decoration: BoxDecoration(
                                                color: Colors.red,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              constraints: BoxConstraints(
                                                minWidth: 18,
                                                minHeight: 18,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  unreadCount > 9 ? '+9' : '$unreadCount',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                                selectedIcon: Icon(item['icon'] as IconData, color: Colorsdata().buttonHover),
                                label: Text(item['label'] as String),
                              );
                            }
                            // Pour les autres éléments, retournez une destination normale
                            return NavigationRailDestination(
                              icon: Icon(item['icon'] as IconData),
                              selectedIcon: Icon(item['icon'] as IconData, color: Colorsdata().buttonHover),
                              label: Text(item['label'] as String),
                            );
                          }).toList(),
                        )),
                    Expanded(child: content),
                  ],
                )
              : content,
          // 📱 Convex Bottom Bar pour mobile (utilise les mêmes _mainNavItems)
          bottomNavigationBar: isDesktop
              ? null
              : StreamBuilder<int>(
                  stream: unreadCountStream(currentUserId),
                  builder: (context, snapshot) {
                    final unreadCount = snapshot.data ?? 0;
                    final badges = <int, dynamic>{};
                    if (unreadCount > 0) {
                      badges[_mainNavItems.indexWhere((item) => item['label'] == 'Messages')] = unreadCount > 9 ? '+9' : '$unreadCount';
                    }
                    return ConvexAppBar.badge(
                      badges,
                      backgroundColor: Colorsdata().white,
                      activeColor: Colorsdata().buttonHover,
                      color: Colors.grey,
                      style: TabStyle.reactCircle,
                      height: 60,
                      items: _mainNavItems.map((item) =>
                        TabItem(icon: item['icon'] as IconData, title: item['label'] as String)
                      ).toList(),
                      initialActiveIndex: navController.selectedIndex.value,
                      onTap: (index) {
                        navController.changeIndex(index);
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }
}
