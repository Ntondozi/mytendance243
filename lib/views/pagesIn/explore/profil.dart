import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // N'oubliez pas cet import !
import 'package:tendance/views/pagesIn/explore/editProfile.dart';
import '../../../controlers/authControler.dart';
import '../../../controlers/navControler.dart';
import '../../../models/navIds.dart';
import '../../../controlers/ColorsData.dart';
import '../../../services/image_service.dart';

class ProfilPage extends StatelessWidget {
  ProfilPage({super.key});

  final AuthController controller = Get.find();
  final navController = Get.find<NavigationInController>();


  // Fonction pour formater la date de création du compte (AJOUTÉE)
  String _formatCreationDate(DateTime? date) { // Type changé à DateTime? car user.createdAt sera maintenant un DateTime?
    if (date == null) {
      return 'Non disponible';
    }
    // Format souhaité : "24 septembre 2024"
    return DateFormat('dd MMMM yyyy', 'fr_FR').format(date);
    // Si vous préférez "24/09/2024", utilisez: return DateFormat('dd/MM/yyyy', 'fr_FR').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    double adaptiveSize(double small, double medium, double large) {
      if (width <= 500) return small;
      if (width <= 900) return medium;
      return large;
    }
    final indexNav = navController.selectedIndex.value;
    bool navId = false;
    if (indexNav < 3 ) {
      navId = true;
    }

    return Scaffold(
      backgroundColor: Colorsdata().background,
      appBar: navId ? AppBar(
        backgroundColor: Colorsdata().white,
        leading: IconButton(
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
          icon: const Icon(Icons.arrow_back_ios),
        ),
        title: Text(
          "Mon Profil",
          style: TextStyle(
            color: Colors.black,
            fontSize: adaptiveSize(20, 24, 28),
            fontWeight: FontWeight.bold,
          ),
        ),
      ): null,
      
      body: Obx(() {
        final user = controller.currentUser.value;
        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          child: Column(
            children: [
              // === EN-TÊTE AVEC PHOTO ===
              Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.all(15),
                    decoration:
                        BoxDecoration(color: Colorsdata().buttonHover),
                    width: double.infinity,
                    height: 140,
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      padding: EdgeInsets.only(top: 85),
                      
                      child: GestureDetector(
                        onDoubleTap: () => _pickAndUploadPhoto(context),
                        onTap: () {
                          final photo = controller.currentUser.value?.photoUrl;
                      
                          if (photo == null) {
                            _pickAndUploadPhoto(context);
                          } else {
                            // Afficher en plein écran
                            showDialog(
                              context: context,
                              builder: (_) => GestureDetector(
                                child: Dialog(
                                  backgroundColor: Colors.transparent,
                                  insetPadding: EdgeInsets.zero,
                                  child: InteractiveViewer(
                                    child: Image.network(
                                      photo,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                        child: Obx(() {
                          final photo = controller.currentUser.value?.photoUrl;
                          return CircleAvatar(
                            radius: 60,
                            backgroundImage: photo != null
                                ? NetworkImage(
                                    '$photo?ts=${DateTime.now().millisecondsSinceEpoch}')
                                : const AssetImage('assets/images/profil.jpg')
                                    as ImageProvider,
                            child: photo == null
                                ? const Icon(Icons.camera_alt,
                                    color: Colors.white)
                                : null,
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 230),
                ],
              ),
              
              // === INFOS UTILISATEUR ===
              Container(
                margin: const EdgeInsets.all(15),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colorsdata().white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    Text(user.username,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 230,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colorsdata().buttonHover,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(7)),
                        ),
                        onPressed: () {
                          Get.to(() => EditProfilPage(user: user));
                        },
                        icon: const Icon(Icons.edit_outlined,
                            color: Colors.white),
                        label: Text("Modifier mon profil",
                            style: TextStyle(color: Colorsdata().white)),
                      ),
                    ),
                    _buildInfoRow(Icons.mail_outline, 'E-mail', user.email),
                    _buildInfoRow(Icons.call_outlined, 'Téléphone',
                        user.phone ?? 'Non spécifié'),
                    _buildInfoRow(Icons.map_outlined, 'Ville',
                        user.ville ?? 'Non spécifiée'),
                    _buildInfoRow(Icons.chat_rounded, 'Contact préféré', 'Chat'),
                    _buildButtonInfo("Nom d'utilisateur", user.username),
                    _buildButtonInfo(
                        "Type de compte", user.typeCompte ?? 'Mixte'),
                    // MODIFICATION DE LA LIGNE SUIVANTE : (utilisant la fonction _formatCreationDate)
                    _buildButtonInfo("Compte créé depuis", _formatCreationDate(user.createdAt)), // user.createdAt est maintenant un DateTime?
                    const SizedBox(height: 10),
                    const Row(
                      children: [
                        Padding(padding: EdgeInsets.all(15), child: Text('Actions rapides'),),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 7.5),
      padding: const EdgeInsets.all(10),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colorsdata().background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon), const SizedBox(width: 4), Text(label)]),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionRapide(IconData icon, String title, Color color){
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15, bottom: 7),
      child: ElevatedButton(
      style: ElevatedButton.styleFrom(
      backgroundColor: Colorsdata().background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      ),
        onPressed: () {
          // Action rapide
      }, child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
      const Icon(Icons.favorite, color: Colors.red,),
      const SizedBox(width: 20,),
      const Text("Mes Favoris", style: TextStyle(color: Colors.black),)          ],)),
    );
  }

  Widget _buildButtonInfo(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(25),
          backgroundColor: Colorsdata().buttonHover,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        ),
        onPressed: () {},
        child: Column(
          children: [
            Text(label,
                style:
                    TextStyle(color: Colorsdata().white, fontSize: 12)),
            Text(value,
                style: TextStyle(
                    color: Colorsdata().white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadPhoto(BuildContext context) async {
    final imageService = ImageService();
    final controller = Get.find<AuthController>();
    final imageData = await imageService.pickAndCompress();
    if (imageData == null) return;
    final uploadedUrl = await imageService.uploadUserProfile(
      bytes: imageData["bytes"],
      userId: controller.currentUser.value!.id,
      fileExtension: 'jpg',
    );
    if (uploadedUrl != null) {
      await controller.firestore
          .collection('profiles')
          .doc(controller.currentUser.value!.id)
          .update({'photoUrl': uploadedUrl});
      await controller.fetchUserProfile(controller.currentUser.value!.id);
      controller.currentUser.refresh();
      Get.snackbar(
        "Succès",
        "Photo mise à jour !",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    }
  }
}
