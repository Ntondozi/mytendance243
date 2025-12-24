import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tendance/views/pagesIn/explore/profil.dart';
import '../../../controlers/authControler.dart';
import '../../../controlers/ColorsData.dart';
import '../../../models/userModel.dart';

class EditProfilPage extends StatefulWidget {
  final UserModel user;
  const EditProfilPage({super.key, required this.user});

  @override
  State<EditProfilPage> createState() => _EditProfilPageState();
}

class _EditProfilPageState extends State<EditProfilPage> {
  final AuthController controller = Get.find();

  late TextEditingController usernameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController villeController;
  late TextEditingController typeCompteController;
  late TextEditingController bioController;

  bool isSaving = false; // pour gérer le chargement

  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController(text: widget.user.username);
    emailController = TextEditingController(text: widget.user.email);
    phoneController = TextEditingController(text: widget.user.phone ?? '');
    villeController = TextEditingController(text: widget.user.ville ?? '');
    typeCompteController =
        TextEditingController(text: widget.user.typeCompte ?? '');
    bioController = TextEditingController(text: widget.user.bio ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colorsdata().background,
      appBar: AppBar(
        backgroundColor: Colorsdata().white,
        title:
            const Text("Modifier mon profil", style: TextStyle(color: Colors.black)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const SizedBox(height: 30),
            _buildTextField("Nom d'utilisateur", usernameController),
            _buildTextField("Email", emailController),
            _buildTextField("Téléphone", phoneController),
            _buildTextField("Ville", villeController),
            _buildTextField("Type de compte", typeCompteController),
            _buildTextField("Description (bio)", bioController, maxLines: 3),
            const SizedBox(height: 25),

            // === Bouton avec indicateur de chargement ===
            ElevatedButton(
              onPressed: isSaving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colorsdata().buttonHover,
                padding: const EdgeInsets.all(20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: isSaving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : const Text(
                      "Valider les modifications",
                      style: TextStyle(color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    setState(() => isSaving = true);
    try {
      final uid = controller.currentUser.value!.id;

      await controller.firestore.collection('profiles').doc(uid).update({
        'username': usernameController.text.trim(),
        'email': emailController.text.trim(),
        'phone': phoneController.text.trim(),
        'city': villeController.text.trim(),
        'account_type': typeCompteController.text.trim(),
        'bio': bioController.text.trim(),
      });

      await controller.fetchUserProfile(uid);
      controller.currentUser.refresh();

      setState(() => isSaving = false);

      Get.snackbar(
        "Succès",
        "Les informations ont bien été mises à jour 🎉",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        margin: const EdgeInsets.all(10),
      );

      // Redirection vers la page profil après un petit délai
      await Future.delayed(const Duration(milliseconds: 800));
      Get.back();
    } catch (e) {
      setState(() => isSaving = false);
      Get.snackbar(
        "Erreur",
        "Impossible de mettre à jour le profil : $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        margin: const EdgeInsets.all(10),
      );
    }
  }
}
