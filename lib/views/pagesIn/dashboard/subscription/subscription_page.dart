// file: lib/views/subscription/subscription_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tendance/controlers/subscription_controller.dart';
// import 'package:universal_html/html.dart'; // Cet import est probablement inutile pour Flutter mobile/web sans manipulation directe du DOM
import '../../../../controlers/ColorsData.dart'; // Assurez-vous que ce chemin est correct

class SubscriptionPage extends StatefulWidget {
  final String userId;
  const SubscriptionPage({super.key, required this.userId});
  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  final SubscriptionController subCtrl = Get.find<SubscriptionController>();
  String? appliedPromo;
  bool useTrial = false;
  bool loading = false; // État de chargement local pour les actions de cette page
  String? lastPaymentLink; // Pour afficher le dernier lien de paiement

  final Colorsdata myColors = Colorsdata();

  @override
  void initState() {
    super.initState();
    // Charger les données initiales pour l'affichage dès l'ouverture de la page.
    _refreshStatus();
  }

  // Pas besoin de dispose() pour _refreshTimer car il a été déplacé dans le contrôleur.

  Widget _buildPlanCard() {
    return Obx(() {
      final plan = subCtrl.remotePlan.value;
      if (plan == null) {
        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 16),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: CircularProgressIndicator(color: myColors.primaryColor),
            ),
          ),
        );
      }
      final priceText =
          '${(plan.priceFc * 1.133).ceil()} FC / ${plan.duration.inDays >= 1 ? '${plan.duration.inDays} jours' : '${plan.duration.inHours} heures'}';
      return Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: myColors.white,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Votre Plan Actuel',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: myColors.primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              _buildDetailRow('Prix', subCtrl.subscriptionIsActive.value ? priceText : 'Gratuit'),
              _buildDetailRow('Essai gratuit', subCtrl.subscriptionIsActive.value ? plan.trialAvailable ? 'Oui (1 mois)' : 'Non': 'Illimité'),
              _buildDetailRow('Boutiques autorisées', plan.allowedStores == -1 ? 'Illimité' : plan.allowedStores.toString()),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label :',
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Future<void> _startTrial() async {
  setState(() => loading = true);
  try {
    await subCtrl.activateTrialIfAvailable(userId: widget.userId, promo: appliedPromo);
    Get.snackbar('Succès', 'Essai gratuit activé !',
        backgroundColor: Colors.green, colorText: myColors.white, snackPosition: SnackPosition.BOTTOM);
    await _refreshStatus();
  } catch (e) {
    final msg = e.toString();
    if (msg.contains('Trial already used')) {
      Get.snackbar('Erreur', 'Vous avez déjà utilisé votre essai gratuit.',
          backgroundColor: Colors.red, colorText: myColors.white, snackPosition: SnackPosition.BOTTOM);
    } else if (msg.contains('Unique trial already activated')) {
      Get.snackbar('Erreur', 'L\'essai gratuit unique a déjà été activé pour ce compte.',
          backgroundColor: Colors.red, colorText: myColors.white, snackPosition: SnackPosition.BOTTOM);
    } else {
      Get.snackbar('Erreur', msg,
          backgroundColor: Colors.red, colorText: myColors.white, snackPosition: SnackPosition.BOTTOM);
    }
  } finally {
    setState(() => loading = false);
  }
}

  Future<void> _payNow() async {
    setState(() => loading = true);
    try {
      final link = await subCtrl.initiatePaymentForCurrentPlan(
          userId: widget.userId, promoCode: appliedPromo, message: 'Abonnement Tendance');
      if (link == null) {
        Get.snackbar('Erreur', 'Impossible de créer le paiement.',
            backgroundColor: Colors.red, colorText: myColors.white, snackPosition: SnackPosition.BOTTOM);
        setState(() => loading = false);
        return;
      }
      lastPaymentLink = link;
      if (mounted) {
        Get.dialog(
          AlertDialog(
            title: const Text('Paiement lancé'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Un lien de paiement a été ouvert. Veuillez compléter la transaction.'),
              const SizedBox(height: 10),
              SelectableText(link, maxLines: 4, style: const TextStyle(fontSize: 12, color: Colors.blue)),
            ]),
            actions: [
              TextButton(onPressed: () => Get.back(), child: Text('Fermer', style: TextStyle(color: myColors.primaryColor))),
            ],
          ),
        );
      }
      Get.snackbar('Info', 'Vérification automatique du paiement en cours...',
          backgroundColor: Colors.blueGrey, colorText: myColors.white, snackPosition: SnackPosition.BOTTOM);
      await _refreshStatus(); // Rafraîchir pour refléter l'état du paiement
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors de l\'initiation du paiement: $e',
          backgroundColor: Colors.red, colorText: myColors.white, snackPosition: SnackPosition.BOTTOM);
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _refreshStatus() async {
    setState(() => loading = true); // Active l'indicateur de chargement local
    try {
      await subCtrl.loadRemoteConfig();
      await subCtrl.loadPromoCodes();
      await subCtrl.loadLocalSubscription();
      // subCtrl.monitorAndNotify est appelé par le timer interne du contrôleur
    } catch (e) {
      print("Erreur lors de l'actualisation du statut : $e");
    } finally {
      setState(() => loading = false); // Désactive l'indicateur de chargement local
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
        // récupérer le flag de config
        final settingAllowSubscriptions = subCtrl.subscriptionIsActive.value;


      final local = subCtrl.localSub.value;
      final active = local != null && local.expiresAtMillis > DateTime.now().millisecondsSinceEpoch;
      final expiresStr = local != null
          ? DateTime.fromMillisecondsSinceEpoch(local.expiresAtMillis).toLocal().toString().split('.')[0]
          : 'Non abonné';
      return Scaffold(
        backgroundColor: myColors.background,
        appBar: AppBar(
          title: const Text('Gérer votre Abonnement'),
          backgroundColor: myColors.primaryColor,
          foregroundColor: myColors.white,
          elevation: 0,
          actions: [
            IconButton(
                onPressed: _refreshStatus,
                icon: Icon(Icons.refresh, color: myColors.white),
                tooltip: 'Actualiser le statut'),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPlanCard(),
                  const SizedBox(height: 20),
                  // Section Code Promo
                  subCtrl.subscriptionIsActive.value ? TextField(
                    decoration: InputDecoration(
                      labelText: 'Code promo (optionnel)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: myColors.primaryColor, width: 2),
                      ),
                    ),
                    onChanged: (v) => appliedPromo = v.trim(),
                  ) : SizedBox(),
                  const SizedBox(height: 12),
                  // Option Essai gratuit: Afficher uniquement si l'abonnement n'est pas actif ET si l'essai est disponible ET n'a pas été utilisé
                  if (!active && (subCtrl.remotePlan.value?.trialAvailable ?? false) && (local == null || local.trialUsed == false))
                    subCtrl.subscriptionIsActive.value ?Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: CheckboxListTile(
                        title: const Text('Démarrer par l\'essai gratuit (1 mois)'),
                        value: useTrial,
                        onChanged: (v) => setState(() => useTrial = v ?? false),
                        activeColor: myColors.primaryColor,
                      ),
                    ) : SizedBox(),
                  subCtrl.subscriptionIsActive.value ? const SizedBox(height: 20) : SizedBox(),
                  // Statut de l'abonnement
                  if (active)
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: Colors.green.shade50,
                      child: ListTile(
                        leading: const Icon(Icons.check_circle, color: Colors.green, size: 30),
                        title: const Text('Abonnement actif', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: subCtrl.subscriptionIsActive.value ? Text('Valide jusqu\'à : $expiresStr') : SizedBox(),
                      ),
                    )
                  else
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: Colors.red.shade50,
                      child: const ListTile(
                        leading: Icon(Icons.cancel, color: Colors.red, size: 30),
                        title: Text('Abonnement inactif', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Votre abonnement est expiré ou non actif.'),
                      ),
                    ),
                  const SizedBox(height: 20),
                  // Boutons d'action (Payer / Activer Essai)
                 if (loading)
                    Center(child: CircularProgressIndicator(color: myColors.primaryColor))
                  else
                    Column(
                      children: [
                        // Si les abonnements sont désactivés globalement, on n'affiche QUE l'option essai
                        if (!settingAllowSubscriptions) ...[
                          ElevatedButton(
                            onPressed: () async {
                              // Forcer useTrial = true
                              await _startTrial();
                              setState(() => useTrial = false);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: myColors.primaryColor,
                              foregroundColor: myColors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            child: const Text('Activer l\'essai gratuit'),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Les abonnements payants sont temporairement désactivés. Seul l\'essai gratuit est disponible.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black54),
                          ),
                        ] else ...[
                          // comportement normal : bouton Payer/Activer (ou activer essai si useTrial)
                          ElevatedButton(
                            onPressed: () async {
                              if (useTrial) {
                                await _startTrial();
                                setState(() => useTrial = false);
                              } else {
                                await _payNow();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: myColors.primaryColor,
                              foregroundColor: myColors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            child: Text(useTrial ? 'Activer l\'essai gratuit' : 'Payer / Activer'),
                          ),
                        ],
                      ],
                    ),
                  const SizedBox(height: 20),
                  // Affichage du dernier lien de paiement (si existant)
                  if (lastPaymentLink != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Dernier lien de paiement généré :', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        SelectableText(
                          lastPaymentLink!,
                          maxLines: 3,
                          style: TextStyle(color: Colors.blue.shade700, decoration: TextDecoration.underline),
                        ),
                      ],
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
    });
  }
}
