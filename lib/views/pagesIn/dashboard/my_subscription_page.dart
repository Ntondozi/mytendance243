// file: lib/views/pagesIn/dashboard/my_subscription_page.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tendance/controlers/subscription_controller.dart';
import '../../../controlers/ColorsData.dart';
import '../../../controlers/navControler.dart';
import '../../../models/navIds.dart';
import 'subscription/subscription_page.dart'; // Votre page de gestion d'abonnement

class MySubscriptionPage extends StatelessWidget {
  const MySubscriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final SubscriptionController subCtrl = Get.find<SubscriptionController>();
    final Colorsdata myColors = Colorsdata();
    final userId = FirebaseAuth.instance.currentUser?.uid;

    final navController = Get.find<NavigationInController>();
    final width = MediaQuery.of(context).size.width;
    // final height = MediaQuery.of(context).size.height; // 'height' n'est pas utilisé, peut être retiré

    double adaptiveSize(double small, double medium, double large) {
      if (width <= 500) return small;
      if (width <= 900) return medium;
      return large;
    }

    if (userId == null) {
      return Center(
        child: Text('Utilisateur non connecté.', style: TextStyle(color: myColors.primaryColor)),
      );
    }

    final indexNav = navController.selectedIndex.value;
    bool navId = false;
    if (indexNav < 3) {
      navId = true;
    }

    return Scaffold(
      backgroundColor: myColors.background,
      body: Column(
        children: [
          // HEADER (inchangé, car non lié au problème d'abonnement)
          navId
              ? Container(
                  padding: EdgeInsets.all(adaptiveSize(width / 33, 20, 30)),
                  color: Colorsdata().white,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () {
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
                                  },
                                  icon: Icon(Icons.arrow_back_ios),
                                ),
                                Text(
                                  'Mon abonnement',
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
                )
              : SizedBox(),
          Obx(() {
            final localSub = subCtrl.localSub.value;
            final remotePlan = subCtrl.remotePlan.value; // Observez aussi remotePlan si nécessaire

            // --- SUPPRIMEZ CE BLOC PROBLÉMATIQUE ---
            // if (localSub == null && !subCtrl.isLoading.value) {
            //   subCtrl.loadLocalSubscription();
            //   subCtrl.loadRemoteConfig();
            // }
            // --- FIN DU BLOC À SUPPRIMER ---

            final bool isActive = localSub != null && localSub.expiresAtMillis > DateTime.now().millisecondsSinceEpoch;

            return Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          color: myColors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Text(
                                    'Statut de votre abonnement',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: myColors.primaryColor,
                                    ),
                                  ),
                                ),
                                const Divider(height: 20, thickness: 1),
                                // Affiche les détails de l'abonnement si localSub n'est pas null
                                if (localSub != null) ...[
                                  _buildSubscriptionDetailRow('Plan ID', subCtrl.subscriptionIsActive.value ? localSub.planId: "Utilisation gratuite"),
                                  _buildSubscriptionDetailRow(
                                    'Actif',
                                    isActive ? 'Oui' : 'Non',
                                    valueColor: isActive ? Colors.green.shade700 : Colors.red.shade700,
                                  ),
                                  subCtrl.subscriptionIsActive.value ?_buildSubscriptionDetailRow(
                                    'Expire le',
                                    DateTime.fromMillisecondsSinceEpoch(localSub.expiresAtMillis).toLocal().toString().split('.')[0],
                                  ): SizedBox(),
                                  subCtrl.subscriptionIsActive.value ? _buildSubscriptionDetailRow(
                                    'Début de l\'abonnement',
                                    DateTime.fromMillisecondsSinceEpoch(localSub.startAtMillis).toLocal().toString().split('.')[0],
                                  ): SizedBox(),
                                  subCtrl.subscriptionIsActive.value ?_buildSubscriptionDetailRow(
                                    'Essai utilisé',
                                    localSub.trialUsed ? 'Oui' : 'Non',
                                  ): SizedBox(),
                                  _buildSubscriptionDetailRow(
                                    'Boutiques autorisées',
                                    localSub.allowedStores == -1 ? 'Illimité' : localSub.allowedStores.toString(),
                                  ),
                                    
                                  if (localSub.promoCode != null)
                                    _buildSubscriptionDetailRow('Code promo', localSub.promoCode!),
                                ] else ...[
                                  // Ce bloc s'affiche correctement lorsque localSub est null
                                  const Text(
                                    'Aucun abonnement actif trouvé. Veuillez activer un plan ou un essai.',
                                    style: TextStyle(fontSize: 16, color: Colors.black54),
                                  ),
                                ],
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => Get.to(() => SubscriptionPage(userId: userId)),
                                    icon: const Icon(Icons.credit_card),
                                    label: Text(isActive ? 'Gérer mon abonnement' : 'Activer un abonnement'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: myColors.primaryColor,
                                      foregroundColor: myColors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        // N'affiche le plan distant que s'il est chargé
                        if (remotePlan != null)
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            color: myColors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(
                                    child: Text(
                                      'Plan Actuel (Configuration)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                        color: myColors.primaryColor,
                                      ),
                                    ),
                                  ),
                                  const Divider(height: 20, thickness: 1),
                                  _buildSubscriptionDetailRow('Prix', subCtrl.subscriptionIsActive.value ? '${(remotePlan.priceFc * 1.133).ceil()} FC' : 'Gratuit'),
                                  _buildSubscriptionDetailRow(
                                    'Durée',
                                    subCtrl.subscriptionIsActive.value ? remotePlan.duration.inDays >= 1
                                        ? '${remotePlan.duration.inDays} jours'
                                        : '${remotePlan.duration.inHours} heures'
                                        : 'Illimitée',
                                  ),
                                  subCtrl.subscriptionIsActive.value ? _buildSubscriptionDetailRow(
                                    'Essai disponible',
                                    remotePlan.trialAvailable ? 'Oui' : 'Non',
                                  ) : SizedBox(),
                                  subCtrl.subscriptionIsActive.value ? _buildSubscriptionDetailRow(
                                    'Durée essai',
                                    remotePlan.trialDuration.inDays >= 1
                                        ? '${remotePlan.trialDuration.inDays} jours'
                                        : '${remotePlan.trialDuration.inHours} heures',
                                  ) : SizedBox(),
                                  _buildSubscriptionDetailRow(
                                    'Boutiques autorisées',
                                    remotePlan.allowedStores == -1 ? 'Illimité' : remotePlan.allowedStores.toString(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 10),
                        const Text(
                          'Les notifications et l\'historique sont enregistrés dans votre profil.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // _buildSubscriptionDetailRow reste inchangé
  Widget _buildSubscriptionDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '$label :',
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
