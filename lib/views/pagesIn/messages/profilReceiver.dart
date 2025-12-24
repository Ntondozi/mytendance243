// file: lib/views/chat/profilMessage.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/navIds.dart';
import '../../../controlers/ColorsData.dart';
import '../dashboard/storeDetailClient.dart';

class ProfilMessage extends StatefulWidget {
  final String userId; // <-- ID du profil à récupérer

  ProfilMessage({super.key, required this.userId});

  @override
  State<ProfilMessage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilMessage> {
  String? selectedValue;
  String? selectedValueEtat;
  String? selectedValueTrie;
  int currentPage = 1;
  final int itemsPerPage = 20;

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserData() async {
    return await FirebaseFirestore.instance
        .collection('profiles')
        .doc(widget.userId)
        .get();
  }

  void openFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => GestureDetector(
        onTap: () => Get.back(),
        child: Container(
          color: Colors.black.withOpacity(0.9),
          child: Center(
            child: InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    double adaptiveSize(double small, double medium, double large) {
      if (width <= 500) return small;
      if (width <= 900) return medium;
      return large;
    }

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: getUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            body: Center(child: Text("Impossible de récupérer les informations...")),
          );
        }

        final data = snapshot.data!.data()!;
        final name = data['name'] ?? 'Nom complet';
        final email = data['email'] ?? 'email@example.com';
        final phone = data['phone'] ?? '0000000000';
        final city = data['city'] ?? 'Ville';
        final username = data['username'] ?? 'Username';
        final accountType = data['accountType'] ?? 'Mixte';
        final description = data['bio'] ?? 'Non spécifiée';
        final photoUrl = data['photoUrl'];
        final createdAtTimestamp = data['created_at'];
        final createdAt = createdAtTimestamp != null
            ? (createdAtTimestamp as Timestamp).toDate()
            : null;

        return Scaffold(
          backgroundColor: Colorsdata().background,
          body: Column(
            children: [
              if(!kIsWeb) SizedBox(height: 35,) else SizedBox(),
              // HEADER
              Container(
                padding: EdgeInsets.all(adaptiveSize(width / 33, 20, 30)),
                color: Colorsdata().white,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Get.back();
                      },
                      icon: Icon(Icons.arrow_back_ios),
                    ),
                    Text(
                      username,
                      overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: adaptiveSize(20, 24, 28),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            margin: EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colorsdata().buttonHover,
                            ),
                            width: double.infinity,
                            height: 140,
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Container(
                              padding: EdgeInsets.only(top: 85),
                              child: GestureDetector(
                                onTap: () {
                                  if (photoUrl != null) {
                                    openFullScreenImage(photoUrl);
                                  }
                                },
                                child: SizedBox(
                                  height: 120,
                                  width: 120,
                                  child: CircleAvatar(
                                    backgroundImage: photoUrl != null
                                        ? NetworkImage(photoUrl)
                                        : null,
                                    child: photoUrl == null ? Icon(Icons.person, size: 65,) : null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 230),
                        ],
                      ),
                      Container(
                        margin: EdgeInsets.all(15),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colorsdata().white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            SizedBox(height: 30),
                            Container(
                              padding: EdgeInsets.all(20),
                              width: double.infinity,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Bio",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18)),
                                  SizedBox(height: 4),
                                  Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: ExpandableTextWidget(
                                        text: description,
                                        maxLines: 2,
                                      ),
                                    ),
                                  ],
                                          ),
                                ],
                              ),
                            ),
                            SizedBox(height: 8),
                            _buildInfoRow(Icons.mail_outline, 'E-mail', email),
                            _buildInfoRow(Icons.call_outlined, 'Téléphone', phone),
                            _buildInfoRow(Icons.map_outlined, 'Ville', city),
                            _buildInfoRow(Icons.chat_rounded, 'Contact préféré', 'Chat'),
                            _buildButtonInfo("Nom d'utilisateur", username),
                            _buildButtonInfo("Type de compte", accountType),
                            _buildButtonInfo(
                              "Compte créé depuis",
                              createdAt != null
                                  ? "${createdAt.day}/${createdAt.month}/${createdAt.year}"
                                  : "Date inconnue",
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      margin: EdgeInsets.only(left: 15, right: 15, bottom: 7.5, top: 7.5),
      padding: EdgeInsets.all(10),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colorsdata().background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon),
              SizedBox(width: 4),
              Text(label),
            ],
          ),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildButtonInfo(String label, String value) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(15),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.all(25),
          backgroundColor: Colorsdata().buttonHover,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        ),
        onPressed: () {},
        child: Column(
          children: [
            Text(label, style: TextStyle(color: Colorsdata().white, fontSize: 12)),
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
}
