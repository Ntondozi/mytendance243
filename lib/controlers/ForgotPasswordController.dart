import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordController extends GetxController {
  final email = ''.obs;
  final isLoading = false.obs;

  Future<void> resetPassword() async {
    try {
      isLoading.value = true;

      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: email.value.trim());

      isLoading.value = false;

      // Affiche le popup
      Get.dialog(
        _successPopup(),
        barrierDismissible: false,
      );
    } catch (e) {
      isLoading.value = false;
      Get.snackbar("Erreur", e.toString());
      print(e.toString());
    }
  }

  Widget _successPopup() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icône vert "très bien"
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 70,
            ),
            const SizedBox(height: 15),

            const Text(
              "Lien envoyé !",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
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
