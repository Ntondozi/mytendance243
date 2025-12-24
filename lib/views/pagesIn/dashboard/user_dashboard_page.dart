import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart'; // Import pour url_launcher
import 'package:tendance/controlers/authControler.dart';
import 'package:tendance/controlers/navControler.dart';
import 'package:tendance/controlers/messageController.dart'; // Assurez-vous d'importer votre MessageController
import 'package:tendance/views/pagesIn/dashboard/my_stores_page.dart';
import 'package:tendance/views/pagesIn/dashboard/my_subscription_page.dart';
import 'package:tendance/views/pagesIn/dashboard/statistics_page.dart';
import 'package:tendance/views/pagesIn/explore/profil.dart';
import 'package:tendance/views/pagesIn/explore/notification.dart';
import 'package:tendance/views/pagesIn/dashboard/about_app_page.dart'; // Importez la nouvelle page "À propos"
import '../../../controlers/ColorsData.dart';
import '../messages/messagesPage.dart';

class UserDashboardPage extends StatefulWidget {
  const UserDashboardPage({super.key});

  @override
  State<UserDashboardPage> createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends State<UserDashboardPage> {
  final NavigationInController navInController = Get.find<NavigationInController>();
  final AuthController authController = Get.find<AuthController>();
  final MessageController messageController = Get.find<MessageController>();

  // IDs et numéros de téléphone des administrateurs
  static const String issraelKambaUid = 'fpFpDF3KkvcBjqOBUWK2i4jXOUf2';
  static const String issraelKambaName = 'Israel Buzi';
  static const String issraelKambaPhone = '+243858103391'; // Format international
  static const String justiceNtondoziUid = 'HZTwLIIo57h7GZ1c5rHDNxyPQGS2';
  static const String justiceNtondoziName = 'Justice Ntondozi';
  static const String justiceNtondoziPhone = '+243842691516'; // Format international

  // Liste des destinations du tableau de bord
  late final List<Widget> _pages;
  late final List<String> _pageTitles;
  late final List<Map<String, dynamic>> _dashboardItems;
  String? currentUserId; // Pour stocker l'ID de l'utilisateur connecté

  @override
  void initState() {
    super.initState();
    currentUserId = authController.currentUser.value?.id; // Récupère l'ID de l'utilisateur au démarrage
    _pages = [
      const MyStoresPage(),
      const MySubscriptionPage(),
      const StatisticsPage(),
      ProfilPage(),
      NotificationsPage(userId: FirebaseAuth.instance.currentUser?.uid ?? ''),
      const AboutAppPage(), // Nouvelle page "À propos"
    ];

    _pageTitles = [
      'Mes Boutiques',
      'Mon Abonnement',
      'Statistiques',
      'Mon Profil',
      'Notifications',
      'À propos', // Titre de la nouvelle page
    ];

    _dashboardItems = [
      {'icon': Icons.storefront, 'label': 'Mes Boutiques', 'index': 0},
      {'icon': Icons.subscriptions, 'label': 'Abonnement', 'index': 1},
      {'icon': Icons.analytics, 'label': 'Statistiques', 'index': 2},
      {'icon': Icons.person, 'label': 'Mon Profil', 'index': 3},
      {'icon': Icons.notifications, 'label': 'Notifications', 'index': 4},
      {'icon': Icons.info_outline, 'label': 'À propos', 'index': 5}, // Nouvelle entrée
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bool isLargeScreen = MediaQuery.of(context).size.width > 700;
      if (!isLargeScreen && navInController.dashboardPageIndex.value != -1) {
        navInController.changeDashboardPageIndex(-1);
      } else if (isLargeScreen && navInController.dashboardPageIndex.value == -1) {
        navInController.changeDashboardPageIndex(0);
      }
    });
  }

  // AJOUTÉ : Gère l'appui sur le bouton retour à l'intérieur du Dashboard
  Future<bool> _onWillPop() async {
    final isLargeScreen = MediaQuery.of(context).size.width > 700;

    // Sur mobile, si on est dans une sous-page du dashboard...
    if (!isLargeScreen && navInController.dashboardPageIndex.value != -1) {
      // ...on retourne à la grille principale du dashboard.
      navInController.changeDashboardPageIndex(-1);
      // On empêche le pop de se propager plus loin.
      return false;
    }
    // Sinon (si on est déjà sur la grille ou sur grand écran), on laisse le WillPopScope parent gérer l'action.
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final bool isLargeScreen = MediaQuery.of(context).size.width > 700;
    final bool isMobile = MediaQuery.of(context).size.width <= 500;

    Widget dashboardContentBuilder() {
      if (!isLargeScreen && navInController.dashboardPageIndex.value == -1) {
        return _buildDashboardGrid(context, isMobile: isMobile);
      }

      final int actualIndex = navInController.dashboardPageIndex.value == -1
          ? 0 // Pour grand écran, si -1, affiche "Mes Boutiques"
          : navInController.dashboardPageIndex.value;

      return _pages[actualIndex];
    }

    // MODIFIÉ : Le widget racine est maintenant un WillPopScope
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Builder(builder: (context) { // Builder ajouté pour obtenir un nouveau context pour le Scaffold/Row
        if (isLargeScreen) {
          return Row(
            children: [
              Expanded(child: Obx(() => dashboardContentBuilder())),
              _buildNavigationRail(),
            ],
          );
        }

        return Scaffold(
          backgroundColor: myColors.background,
          appBar: AppBar(
            title: Obx(() {
              if (navInController.dashboardPageIndex.value == -1) {
                return const Text('Tableau de Bord');
              }
              return Text(_pageTitles[navInController.dashboardPageIndex.value]);
            }),
            backgroundColor: myColors.primaryColor,
            foregroundColor: myColors.white,
            elevation: 0,
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          ),
          drawer: _buildDrawer(),
          body: Obx(() => dashboardContentBuilder()),
        );
      }),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: myColors.primaryColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: myColors.accentColor,
                  child: Text(
                    authController.currentUser.value?.username?[0].toUpperCase() ?? 'U',
                    style: TextStyle(fontSize: 24, color: myColors.white),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  authController.currentUser.value?.username ?? 'Utilisateur',
                  style: TextStyle(color: myColors.white, fontSize: 18),
                ),
                Text(
                  authController.currentUser.value?.email ?? '',
                  style: TextStyle(color: myColors.white.withOpacity(0.7), fontSize: 14),
                ),
              ],
            ),
          ),
          _buildDrawerItem(Icons.dashboard_customize, 'Accueil Dashboard', -1),
          const Divider(),
          ..._dashboardItems.map((item) =>
            _buildDrawerItem(item['icon'] as IconData, item['label'] as String, item['index'] as int)
          ).toList(),
          const Divider(),
          ExpansionTile(
            leading: Icon(Icons.support_agent, color: myColors.primaryColor),
            title: Text('Contacter un Administrateur', style: TextStyle(color: myColors.primaryColor, fontWeight: FontWeight.bold)),
            children: [
              _buildAdminContactExpansionTile(issraelKambaName, issraelKambaUid, issraelKambaPhone, myColors, currentUserId),
              _buildAdminContactExpansionTile(justiceNtondoziName, justiceNtondoziUid, justiceNtondoziPhone, myColors, currentUserId),
            ],
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Se Déconnecter', style: TextStyle(color: Colors.red)),
            onTap: () {
              final AuthController controller = Get.put(AuthController());
                  Get.defaultDialog(
                      title: "Déconnexion",
                      middleText: "Voulez-vous vraiment vous déconnecter ?",
                      textCancel: "Annuler",
                      textConfirm: "Oui",
                      confirmTextColor: Colors.white,
                      cancelTextColor: Colors.red,
                      onConfirm: () {
                        controller.logout();
                        Get.back(); // Ferme le dialogue
                      });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index) {
    return Obx(() => ListTile(
      leading: Icon(icon, color: (navInController.dashboardPageIndex.value == index || (index == -1 && navInController.dashboardPageIndex.value == -1)) ? myColors.primaryColor : Colors.black54),
      title: Text(
        title,
        style: TextStyle(
          color: (navInController.dashboardPageIndex.value == index || (index == -1 && navInController.dashboardPageIndex.value == -1)) ? myColors.primaryColor : Colors.black87,
          fontWeight: (navInController.dashboardPageIndex.value == index || (index == -1 && navInController.dashboardPageIndex.value == -1)) ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () {
        Navigator.of(context).pop();
        navInController.changeDashboardPageIndex(index);
      },
    ));
  }

  // Widget pour les options de contact de chaque administrateur
  Widget _buildAdminContactExpansionTile(String name, String uid, String phone, Colorsdata myColors, String? currentUserId) {
    bool isSelf = (currentUserId != null && currentUserId == uid);

    return ExpansionTile(
      title: Text(name, style: TextStyle(fontWeight: FontWeight.w600, color: myColors.primaryColor)),
      leading: const Icon(Icons.person_outline),
      children: [
        ListTile(
          title: Text(
            'Sur Tendance',
            style: TextStyle(
              color: isSelf ? Colors.grey : Colors.indigoAccent,
            ),
          ),
          leading: Icon(Icons.chat, color: isSelf ? Colors.grey : myColors.accentColor),
          onTap: isSelf ? null : () { // Désactiver si c'est l'utilisateur lui-même
            // Navigator.of(context).pop();
            messageController.selectConversation(
              receiverId: uid,
              receiverName: name,
            );
            Get.to(() => ChatPage(receiverId: uid, receiverName: name));
          },
        ),
        ListTile(
          title: const Text('Sur WhatsApp'),
          leading: Icon(Icons.message, color: Colors.green),
          onTap: () async {
            print(phone);
            final whatsappUrl = "https://wa.me/$phone";
            if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
              await launchUrl(Uri.parse(whatsappUrl), mode: LaunchMode.externalApplication);
            } else {
              Get.snackbar('Erreur', 'Impossible d\\\'ouvrir WhatsApp. Veuillez vérifier son installation.', backgroundColor: Colors.red, colorText: Colors.white);
            }
          },
        ),
        ListTile(
          title: const Text('Appel'),
          leading: Icon(Icons.phone, color: Colors.blue),
          onTap: () async {
            final callUrl = "tel:$phone";
            if (await canLaunchUrl(Uri.parse(callUrl))) {
              await launchUrl(Uri.parse(callUrl));
            } else {
              Get.snackbar('Erreur', 'Impossible de passer l\\\'appel.', backgroundColor: Colors.red, colorText: Colors.white);
            }
          },
        ),
      ],
    );
  }

  Widget _buildNavigationRail() {
    return Obx(() => NavigationRail(
      selectedIndex: navInController.dashboardPageIndex.value == -1 ? 0 : navInController.dashboardPageIndex.value,
      onDestinationSelected: (index) {
        navInController.changeDashboardPageIndex(index);
      },
      labelType: NavigationRailLabelType.all,
      backgroundColor: myColors.white,
      selectedIconTheme: IconThemeData(color: myColors.primaryColor),
      unselectedIconTheme: const IconThemeData(color: Colors.black54),
      selectedLabelTextStyle: TextStyle(color: myColors.primaryColor, fontWeight: FontWeight.bold),
      unselectedLabelTextStyle: const TextStyle(color: Colors.black87),
      destinations: _dashboardItems.map((item) =>
        NavigationRailDestination(
          icon: Icon(item['icon'] as IconData),
          selectedIcon: Icon(item['icon'] as IconData),
          label: Text(item['label'] as String),
        )
      ).toList(),
      trailing: Column(
        children: [
          const SizedBox(height: 5),
          InkWell(
            onTap: () => _showAdminContactDialog(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
              child: Column(
                children: [
                  Icon(Icons.support_agent, color: myColors.primaryColor),
                  Text('Contacter Admin', style: TextStyle(color: myColors.primaryColor, fontSize: 12)),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: () {
              final AuthController controller = Get.put(AuthController());
                  Get.defaultDialog(
                      title: "Déconnexion",
                      middleText: "Voulez-vous vraiment vous déconnecter ?",
                      textCancel: "Annuler",
                      textConfirm: "Oui",
                      confirmTextColor: Colors.white,
                      cancelTextColor: Colors.red,
                      onConfirm: () {
                        controller.logout();
                        Get.back(); // Ferme le dialogue
                      });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
              child: Column(
                children: [
                  Icon(Icons.logout, color: Colors.red),
                  Text('Se Déconnecter', style: TextStyle(color: Colors.red, fontSize: 12)),
                ],
              ),
            ),
          ),
          
        ],
      ),
      
    ));
  }

  void _showAdminContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Contacter un Administrateur'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAdminContactTile(issraelKambaName, issraelKambaUid, issraelKambaPhone, myColors, currentUserId),
              const Divider(),
              _buildAdminContactTile(justiceNtondoziName, justiceNtondoziUid, justiceNtondoziPhone, myColors, currentUserId),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Fermer', style: TextStyle(color: myColors.primaryColor)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Widget pour les options de contact d'un administrateur dans un dialogue
  Widget _buildAdminContactTile(String name, String uid, String phone, Colorsdata myColors, String? currentUserId) {
    bool isSelf = (currentUserId != null && currentUserId == uid);
    return Column(
      children: [
        Text(name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: myColors.primaryColor)),
        ListTile(
          title: Text(
            'Sur Tendance',
            style: TextStyle(
              color: isSelf ? Colors.grey : myColors.accentColor,
            ),
          ),
          leading: Icon(Icons.chat, color: isSelf ? Colors.grey : myColors.accentColor),
          onTap: isSelf ? null : () { // Désactiver si c'est l'utilisateur lui-même
            Navigator.of(context).pop(); // Fermer le dialogue
            messageController.selectConversation(
              receiverId: uid,
              receiverName: name,
            );
            Get.to(() => ChatPage(receiverId: uid, receiverName: name));
          },
        ),
        ListTile(
          title: const Text('Sur WhatsApp'),
          leading: Icon(Icons.message, color: Colors.green),
          onTap: () async {
            final whatsappUrl = "whatsapp://send?phone=$phone";
            if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
              await launchUrl(Uri.parse(whatsappUrl), mode: LaunchMode.externalApplication);
            } else {
              Get.snackbar('Erreur', 'Impossible d\\\'ouvrir WhatsApp. Veuillez vérifier son installation.', backgroundColor: Colors.red, colorText: Colors.white);
            }
          },
        ),
        ListTile(
          title: const Text('Appel normal'),
          leading: Icon(Icons.phone, color: Colors.blue),
          onTap: () async {
            final callUrl = "tel:$phone";
            if (await canLaunchUrl(Uri.parse(callUrl))) {
              await launchUrl(Uri.parse(callUrl));
            } else {
              Get.snackbar('Erreur', 'Impossible de passer l\\\'appel.', backgroundColor: Colors.red, colorText: Colors.white);
            }
          },
        ),
      ],
    );
  }

  Widget _buildDashboardGrid(BuildContext context, {required bool isMobile}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isMobile ? 2 : 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 1.2,
                ),
                itemCount: _dashboardItems.length,
                itemBuilder: (context, index) {
                  final item = _dashboardItems[index];
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border(
                        left: BorderSide(
                          width: 5,
                          color: myColors.primaryColor.withOpacity(0.7),
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _buildDashboardCard(
                      isMobile: isMobile,
                      icon: item['icon'] as IconData,
                      title: item['label'] as String,
                      onTap: () => navInController.changeDashboardPageIndex(item['index'] as int),
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: myColors.white,
                child: ExpansionTile(
                  leading: Icon(Icons.support_agent, color: myColors.primaryColor),
                  title: Text('Contacter un Administrateur', style: TextStyle(color: myColors.primaryColor, fontWeight: FontWeight.bold)),
                  children: [
                    _buildAdminContactExpansionTile(issraelKambaName, issraelKambaUid, issraelKambaPhone, myColors, currentUserId),
                    _buildAdminContactExpansionTile(justiceNtondoziName, justiceNtondoziUid, justiceNtondoziPhone, myColors, currentUserId),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  final AuthController controller = Get.put(AuthController());
                  Get.defaultDialog(
                      title: "Déconnexion",
                      middleText: "Voulez-vous vraiment vous déconnecter ?",
                      textCancel: "Annuler",
                      textConfirm: "Oui",
                      confirmTextColor: Colors.white,
                      cancelTextColor: Colors.red,
                      onConfirm: () {
                        controller.logout();
                        Get.back(); // Ferme le dialogue
                      });
                },
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: myColors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(width: 10,),
                        Icon(Icons.logout, color: Colors.red),
                        SizedBox(width: 8,),
                        Text(
                          'Se Déconnecter',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                        
                      ],  
                            ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardCard({ required bool isMobile, required IconData icon, required String title, required VoidCallback onTap}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: myColors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: myColors.primaryColor, size: isMobile ? 40 : 50),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: myColors.primaryColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
