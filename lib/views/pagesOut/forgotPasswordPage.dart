import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controlers/authControler.dart';
import '../../controlers/ColorsData.dart';

class ForgotPasswordPage extends StatelessWidget {
  final bool isUserLogged;
  final TextEditingController _emailCtrl = TextEditingController();
  final RxBool _isLoading = false.obs;

  ForgotPasswordPage({super.key, this.isUserLogged = false}) {
    // Si l'utilisateur est connecté → préremplir l'email
    if (isUserLogged) {
      final user = Get.find<AuthController>().currentUser.value;
      if (user != null) {
        _emailCtrl.text = user.email ?? '';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Réinitialiser le mot de passe", style: TextStyle(color: Colors.white),),
        backgroundColor: Colorsdata().buttonHover,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Veuillez entrer votre adresse email. Un lien de réinitialisation vous sera envoyé.",
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 25),

            // Champ email
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                labelText: "Adresse email",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 25),

            // Bouton avec loader
            Obx(() => SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colorsdata().buttonHover,
                    ),
                    onPressed: _isLoading.value
                        ? null
                        : () async {
                            _isLoading.value = true;
                            try {
                              await auth.resetPassword(_emailCtrl.text.trim());
                              _isLoading.value = false;

                              // Affiche le popup
                              Get.dialog(
                                _successPopup(),
                                barrierDismissible: false,
                              );
                            } catch (e) {
                              _isLoading.value = false;
                              Get.snackbar(
                                  "Erreur", e.toString(),
                                  snackPosition: SnackPosition.BOTTOM);
                            }
                          },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isLoading.value) ...[
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        const Text(
                          "Réinitialiser le mot de passe",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _successPopup() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 70,
            ),
            const SizedBox(height: 15),
            const Text(
              "Lien envoyé !",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Un lien de réinitialisation a été envoyé à votre adresse email.\n\n"
              "Si vous ne voyez pas l’email, vérifiez votre spam ou assurez-vous "
              "d'avoir entré correctement l'adresse.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("OK"),
            )
          ],
        ),
      ),
    );
  }
}
