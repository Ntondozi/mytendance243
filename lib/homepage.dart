import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controlers/authControler.dart';

class HomePage extends StatelessWidget {
  final AuthController controller = Get.find();

  HomePage({super.key});
  DateTime? lastBackPress;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final now = DateTime.now();
        if (lastBackPress == null ||
            now.difference(lastBackPress!) > const Duration(seconds: 2)) {
          lastBackPress = now;
          Get.snackbar('Quitter', 'Appuyez encore pour quitter.');
          return false;
        }
        return true; // Quitte l’application
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Accueil"),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => controller.logout(),
            )
          ],
        ),
        body: Obx(() {
          final user = controller.currentUser.value;
          if (user == null) return const Center(child: CircularProgressIndicator());
          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                Text("Bienvenue, ${user.username} 👋",
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text("Email : ${user.email}"),
                if (user.typeCompte != null) Text("Compte : ${user.typeCompte}"),
                if (user.ville != null) Text("Ville : ${user.ville}"),
                if (user.bio != null) Text("Bio : ${user.bio}"),
              ],
            ),
          );
        }),
      ),
    );
  }
}
