import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../controlers/ColorsData.dart';

class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      backgroundColor: myColors.background,
      appBar: AppBar(
        title: const Text('À propos de Tendance'),
        backgroundColor: myColors.primaryColor,
        foregroundColor: myColors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Bienvenue sur Tendance",
              style: GoogleFonts.poppins(
                color: myColors.primaryColor,
                fontSize: isMobile ? 28 : 38,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Text(
              "Achetez et vendez facilement vos produits neufs ou d’occasion en RDC.",
              style: GoogleFonts.poppins(
                color: Colors.black87,
                fontSize: isMobile ? 16 : 20,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            _buildSectionTitle('Notre Mission', myColors, isMobile),
            Text(
              "Tendance simplifie le commerce digital en RDC. Créez vos boutiques, vendez vos articles, et rejoignez une communauté dynamique d’acheteurs et de vendeurs congolais. Nous nous engageons à offrir une plateforme sécurisée, rapide et intuitive pour tous vos besoins d'achat et de vente.",
              style: GoogleFonts.poppins(
                fontSize: isMobile ? 15 : 17,
                height: 1.6,
                color: Colors.black87,
              ),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 40),
            _buildSectionTitle('Fonctionnalités Clés', myColors, isMobile),
            _buildFeatureItem(
              icon: Icons.storefront,
              title: "Créez plusieurs boutiques",
              description: "Organisez vos produits selon vos marques ou catégories.",
              isMobile: isMobile,
              myColors: myColors,
            ),
            _buildFeatureItem(
              icon: Icons.shopping_cart_outlined,
              title: "Achat & vente rapides",
              description: "Publiez vos annonces et trouvez des clients en un clic.",
              isMobile: isMobile,
              myColors: myColors,
            ),
            _buildFeatureItem(
              icon: Icons.chat_bubble_outline,
              title: "Messagerie intégrée",
              description: "Discutez directement avec vos clients.",
              isMobile: isMobile,
              myColors: myColors,
            ),
            _buildFeatureItem(
              icon: Icons.category,
              title: "Classez vos produits",
              description: "Une interface intuitive pour gérer vos articles.",
              isMobile: isMobile,
              myColors: myColors,
            ),
            const SizedBox(height: 40),
            _buildSectionTitle('Pourquoi choisir Tendance ?', myColors, isMobile),
            _buildReasonItem(
              icon: Icons.lock_outline,
              title: "Sécurisée",
              description: "Vos données et transactions sont protégées.",
              isMobile: isMobile,
              myColors: myColors,
            ),
            _buildReasonItem(
              icon: Icons.flash_on,
              title: "Rapide",
              description: "Publiez et recevez des offres instantanément.",
              isMobile: isMobile,
              myColors: myColors,
            ),
            _buildReasonItem(
              icon: Icons.people_outline,
              title: "Communautaire",
              description: "Une large communauté d’acheteurs et de vendeurs.",
              isMobile: isMobile,
              myColors: myColors,
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                "© ${DateTime.now().year} Tendance. Tous droits réservés. Conçu avec ❤️ en RDC",
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Colorsdata myColors, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: isMobile ? 22 : 30,
          fontWeight: FontWeight.bold,
          color: myColors.primaryColor,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required bool isMobile,
    required Colorsdata myColors,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 30, color: myColors.primaryColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: myColors.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonItem({
    required IconData icon,
    required String title,
    required String description,
    required bool isMobile,
    required Colorsdata myColors,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: myColors.primaryColor),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: myColors.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
