// file: lib/views/pagesIn/explore/boost_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../controlers/ColorsData.dart';
import '../../../controlers/boostController.dart';
import '../../../models/boostPlanModel.dart';

class BoostPage extends StatefulWidget {
  final String targetId;   // ID du produit ou de la boutique à booster
  final String targetType; // 'product' ou 'store'
  final String targetName; // Nom du produit ou de la boutique pour l'affichage
 
  const BoostPage({
    super.key,
    required this.targetId,
    required this.targetType,
    required this.targetName,
  });

  @override
  State<BoostPage> createState() => _BoostPageState();
}

class _BoostPageState extends State<BoostPage> {
  // boostController est maintenant Get.find() car il est Get.put() dans main.dart
  final BoostController boostController = Get.find<BoostController>();
  final Colorsdata myColors = Colorsdata();
  BoostPlan? _selectedBoostPlan;

  @override
  void initState() {
    super.initState();
    if (boostController.boostPlans.isEmpty) {
      boostController.loadBoostPlans();
    }
    if (boostController.boostPlans.isNotEmpty && _selectedBoostPlan == null) {
      _selectedBoostPlan = boostController.boostPlans.values.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: myColors.background,
      appBar: AppBar(
        title: Text('Booster ${widget.targetName} (${widget.targetType == 'product' ? 'Produit' : 'Boutique'})'),
        backgroundColor: myColors.primaryColor,
        foregroundColor: myColors.white,
        elevation: 0,
      ),
      body: Obx(() {
        if (boostController.boostPlans.isEmpty) {
          return Center(child: CircularProgressIndicator(color: myColors.primaryColor));
        }
        final List<BoostPlan> availableBoostPlans = boostController.boostPlans.values.toList()
          ..sort((a, b) => a.priceFc.compareTo(b.priceFc));
        if (_selectedBoostPlan == null && availableBoostPlans.isNotEmpty) {
           _selectedBoostPlan = availableBoostPlans.first;
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Choisissez un plan de boost pour votre ${widget.targetType == 'product' ? 'produit' : 'boutique'} et augmentez sa visibilité !',
                style: const TextStyle(fontSize: 16, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: availableBoostPlans.length,
                  itemBuilder: (context, index) {
                    final plan = availableBoostPlans[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: _selectedBoostPlan?.id == plan.id ? 8 : 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: _selectedBoostPlan?.id == plan.id
                            ? BorderSide(color: myColors.primaryColor, width: 2)
                            : BorderSide.none,
                      ),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedBoostPlan = plan;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                plan.label,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: myColors.primaryColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                             
                              Text(
                                "Prix : ${ (plan.priceFc * 1.133).ceil() } FC",
                                style: const TextStyle(fontSize: 16, color: Colors.black87),

                              ),
                              Text(
                                'Durée : ${plan.duration.inDays} jours',
                                style: const TextStyle(fontSize: 16, color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _selectedBoostPlan == null
                    ? null
                    : () async {
                        final userId = FirebaseAuth.instance.currentUser?.uid;
                        if (userId == null) {
                          Get.snackbar('Erreur', 'Vous devez être connecté pour activer un boost.', backgroundColor: Colors.red);
                          return;
                        }
                        
                        final selectedPlan = _selectedBoostPlan!;
                        final String paymentMessage = "Boost ${widget.targetType} - ${widget.targetName} (${selectedPlan.label})";
                        
                        final String? paymentLink = await boostController.createLygosBoostPaymentAndOpen(
                          amountFc: selectedPlan.priceFc,
                          userId: userId,
                          message: paymentMessage,
                          targetId: widget.targetId,
                          targetType: widget.targetType,
                          boostLevel: selectedPlan.id,
                          boostDuration: selectedPlan.duration,
                        );

                        if (paymentLink != null) {
                          Get.snackbar(
                            'Paiement Initié',
                            'Veuillez compléter le paiement via la fenêtre ouverte. Votre boost sera activé après confirmation.',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.blue,
                            colorText: Colors.white,
                            duration: const Duration(seconds: 5),
                          );
                          Get.back();
                        } else {
                          Get.snackbar(
                            'Erreur de Paiement',
                            'Impossible d\'initier le paiement Lygos. Veuillez réessayer.',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                        }
                      },
                child: Text('Payer et Activer le Boost (${((_selectedBoostPlan?.priceFc ?? 0) * 1.133).ceil()} FC)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: myColors.primaryColor,
                  foregroundColor: myColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
