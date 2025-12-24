import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Assurez-vous d'avoir le package intl
import 'package:tendance/controlers/ColorsData.dart'; // Vos couleurs
import 'package:tendance/controlers/subscription_controller.dart';

import '../../../controlers/String.dart';
import '../../../controlers/navControler.dart';
import '../../../models/navIds.dart';

class NotificationsPage extends StatelessWidget {
  final String userId;
  NotificationsPage({super.key, required this.userId});

  final SubscriptionController subCtrl = Get.find<SubscriptionController>();
  final RxString selectedFilter = 'Toutes'.obs;
  final navController = Get.find<NavigationInController>();


  // Fonction pour afficher le temps écoulé de manière lisible
  String timeAgo(DateTime date) {
    final duration = DateTime.now().difference(date);
    
    // Initialisation de la localisation française
    // Assurez-vous d'avoir initialisé `Intl.defaultLocale = 'fr_FR';` dans votre main.dart
    
    if (duration.inDays > 365) {
      return DateFormat('dd MMM yyyy', 'fr_FR').format(date);
    }
    if (duration.inDays > 7) {
      return DateFormat('dd MMM', 'fr_FR').format(date);
    } else if (duration.inDays >= 2) {
      return 'Il y a ${duration.inDays} jours';
    } else if (duration.inDays >= 1) {
      return 'Hier';
    } else if (duration.inHours >= 1) {
      return 'Il y a ${duration.inHours} h';
    } else if (duration.inMinutes >= 1) {
      return 'Il y a ${duration.inMinutes} min';
    } else {
      return 'À l\'instant';
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    double adaptiveSize(double small, double medium, double large) {
      if (width <= 500) return small;
      if (width <= 900) return medium;
      return large;
    }
    // Écoute Firestore une seule fois
    subCtrl.listenToNotifications(userId: userId);
    final colors = Colorsdata();
    final indexNav = navController.selectedIndex.value;
    bool navId = false;
    if (indexNav < 3 ) {
      navId = true;
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          if(!kIsWeb) SizedBox(height: 35,) else SizedBox(),
           // HEADER
              navId ? Container(
                padding: EdgeInsets.all(adaptiveSize(width / 33, 20, 30)),
                color: Colorsdata().white,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              IconButton(onPressed: () {
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
                              }, icon: Icon(Icons.arrow_back_ios)),
                              Text(
                                'Notifications',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: adaptiveSize(20, 24, 28),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ), 
                      ],
                    ),
                  ],
                ),
              ): SizedBox(),
          // CORPS DE LA PAGE
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    'Rester informé de toutes les nouveautés importantes',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: colors.buttonHover,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => subCtrl.markAllAsRead(userId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.buttonHover,
                          foregroundColor: colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                        ),
                        icon: const Icon(Icons.mark_email_read_outlined, size: 20),
                        label: const Text('Tout marquer comme lu'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          // TODO: Logique pour ouvrir les paramètres de notification
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.white,
                          padding: const EdgeInsets.all(18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                        ),
                        child: Icon(Icons.settings_outlined, color: colors.buttonHover),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // BOUTONS DE FILTRE
                  _buildFilterButtons(),
                  const SizedBox(height: 10),
                  // LISTE DES NOTIFICATIONS
                  Expanded(
                    child: Obx(() {
                      if (subCtrl.notifications.isEmpty) {
                        return const Center(child: Text("Aucune notification pour le moment."));
                      }
                      
                      // Trier par date décroissante
                      final sorted = subCtrl.notifications.toList()
                        ..sort((a, b) {
                          final aDate = a['createdAt'] is Timestamp ? (a['createdAt'] as Timestamp).toDate() : DateTime.now();
                          final bDate = b['createdAt'] is Timestamp ? (b['createdAt'] as Timestamp).toDate() : DateTime.now();
                          return bDate.compareTo(aDate);
                        });

                      // Appliquer le filtre sélectionné
                      final filteredList = sorted.where((notif) {
                        if (selectedFilter.value == 'Non lues') {
                          return !(notif['read'] ?? false);
                        }
                        // TODO: Ajouter la logique pour les autres filtres ('Achats', 'Système')
                        // if (selectedFilter.value == 'Achats') {
                        //   return notif['type'] == 'achat';
                        // }
                        return true; // Pour 'Toutes'
                      }).toList();

                      if (filteredList.isEmpty) {
                        return Center(child: Text("Aucune notification '${selectedFilter.value}'."));
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.only(top: 10),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final notif = filteredList[index];
                          return _buildNotificationCard(notif);
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButtons() {
    final colors = Colorsdata();
    return Obx(() => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ['Toutes', 'Non lues', 'Achats', 'Système'].map((filter) {
          bool isSelected = selectedFilter.value == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton(
              onPressed: () => selectedFilter.value = filter,
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected ? colors.buttonHover.withOpacity(0.15) : colors.white,
                foregroundColor: isSelected ? colors.buttonHover : Colors.black54,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? colors.buttonHover : Colors.grey.shade300,
                  ),
                ),
              ),
              child: Text(filter),
            ),
          );
        }).toList(),
      ),
    ));
  }

  Widget _buildNotificationCard(Map<String, dynamic> notif) {
    final colors = Colorsdata();
    final isRead = notif['read'] ?? false;
    final title = notif['title'] ?? "Notification";
    final message = notif['message'] ?? "";
    final createdAt = notif['createdAt'] is Timestamp
        ? (notif['createdAt'] as Timestamp).toDate()
        : DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isRead ? colors.white : const Color(0xFFF0F5FF), // Couleur de fond légèrement différente si non lue
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            width: 5,
            color: isRead ? Colors.transparent : colors.buttonHover,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.buttonHover.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(Icons.notifications_outlined, color: colors.buttonHover),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        if (!isRead)
                          Container(
                            margin: const EdgeInsets.only(right: 5),
                            height: 9,
                            width: 9,
                            decoration: BoxDecoration(
                              color: colors.buttonHover,
                              shape: BoxShape.circle,
                            ),
                          ),
                        Text(
                          timeAgo(createdAt),
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  message,
                  style: TextStyle(fontSize: 14, color: Colors.black.withOpacity(0.7)),
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
