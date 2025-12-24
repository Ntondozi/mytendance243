import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controlers/ColorsData.dart'; // Assurez-vous que le chemin est correct

class VisibilityGuidePage extends StatelessWidget {
  const VisibilityGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    final Colorsdata myColors = Colorsdata();

    return Scaffold(
      backgroundColor: myColors.background,
      appBar: AppBar(
        title: const Text('Guide de Visibilité des Produits', style: TextStyle(color: Colors.white)),
        backgroundColor: myColors.primaryColor,
        
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Guide de Visibilité des Produits : Comment apparaître en tête de liste ! 🚀',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: myColors.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sur Tendance, nous voulons que les meilleurs produits et les vendeurs les plus engagés soient mis en avant. Notre algorithme de visibilité classe les produits sur la page d\'acceuil en fonction de plusieurs critères. Plus votre produit répond à ces critères, plus il sera visible pour les acheteurs !',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            const Divider(),
            _buildSectionTitle('Le Score de Visibilité : Votre produit en première ligne ⭐', myColors),
            const Text(
              'Chaque produit reçoit un score de visibilité total, calculé sur 100 points, basé sur les éléments suivants :',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildScoreCriterionCard(
              title: 'Abonnement Actif du Vendeur (Jusqu\'à 30 points)',
              description: 'Principe : Les vendeurs abonnés ou en période d\'essai bénéficient d\'une visibilité accrue pour tous leurs produits.\n'
                  'Comment ça marche : Si vous avez un abonnement actif ([Nom de l\'abonnement]) ou que vous utilisez votre période d\'essai, tous vos produits reçoivent un bonus important de 30 points. Sinon, ils commencent à 0 point pour ce critère.\n'
                  'Conseil : Abonnez-vous pour donner un coup de pouce immédiat à tous vos produits !',
              color: Colors.purple,
            ),
            _buildScoreCriterionCard(
              title: 'Boostage Payant du Produit (Jusqu\'à 55 points)',
              description: 'Principe : Augmentez temporairement la visibilité d\'un produit spécifique en le "boostant" avec un paiement.\n'
                  'Comment ça marche : Vous pouvez choisir de booster un produit. Le bonus dépend du niveau de boost choisi et est actif pendant une durée définie :\n'
                  '• Petit Boost : +25 points (Ex: pendant 7 jours)\n'
                  '• Moyen Boost : +40 points (Ex: pendant 15 jours)\n'
                  '• Grand Boost : +55 points (Ex: pendant 30 jours)\n'
                  'Conseil : Utilisez le boost pour vos nouveautés, vos promotions ou vos produits phares afin d\'attirer rapidement l\'attention.',
              color: Colors.amber,
            ),
            _buildScoreCriterionCard(
              title: 'Fraîcheur du Produit (Jusqu\'à 55 points)',
              description: 'Principe : Les produits fraîchement publiés ou mis à jour reçoivent un coup de pouce initial pour les aider à démarrer. Ce bonus est temporaire.\n'
                  'Comment ça marche : Un produit obtient le même bonus qu\'un "Grand Boost" lors de sa publication, mais ce bonus diminue progressivement sur 7 jours.\n'
                  '• Jour 0 (publication/mise à jour) : +55 points (bonus maximum)\n'
                  '• Jour 1 : Le bonus diminue légèrement.\n'
                  '• Jour 7 et au-delà : Le bonus de fraîcheur du produit est de 0 point.\n'
                  'Conseil : Publiez régulièrement de nouveaux produits ou mettez à jour les informations de vos produits existants (même une petite correction de description) pour bénéficier de ce bonus temporaire.',
              color: Colors.teal,
            ),
            _buildScoreCriterionCard(
              title: 'Popularité par Vues (Jusqu\'à 10 points)',
              description: 'Principe : Les produits qui intéressent les acheteurs (ceux qui ont été vus de nombreuses fois) méritent plus de visibilité.\n'
                  'Comment ça marche : Plus un produit a de vues, plus il gagne de points.\n'
                  '• Très populaire (> 100 vues) : +10 points\n'
                  '• Populaire (> 50 vues) : +7 points\n'
                  '• Vues significatives (> 10 vues) : +4 points\n'
                  '• Quelques vues (1 à 9 vues) : +1 point\n'
                  'Conseil : Partagez vos produits sur les réseaux sociaux et dans vos cercles pour générer les premières vues.',
              color: Colors.blue,
            ),
            _buildScoreCriterionCard(
              title: 'Taux d\'Interaction du Produit (Favoris) (Jusqu\'à 5 points)',
              description: 'Principe : Un produit souvent ajouté aux favoris montre qu\'il est très attrayant pour les acheteurs.\n'
                  'Comment ça marche : Le nombre de fois qu\'un produit est mis en favori par différents utilisateurs augmente son score.\n'
                  '• Très apprécié (> 20 favoris) : +5 points\n'
                  '• Apprécié (> 10 favoris) : +3 points\n'
                  '• Au moins un favori (1 à 9 favoris) : +1 point\n'
                  'Conseil : Un produit de qualité, de belles photos et une description complète encouragent les ajouts aux favoris.',
              color: Colors.red,
            ),
            _buildScoreCriterionCard(
              title: 'Complétude des Détails du Produit (Jusqu\'à 5 points)',
              description: 'Principe : Un produit bien décrit et avec toutes les informations nécessaires rassure l\'acheteur et est valorisé par notre système.\n'
                  'Comment ça marche : Nous calculons le pourcentage de champs remplis pour votre produit (titre, description, prix, catégorie, condition, taille, marque, couleur, photos, etc.). Plus un produit est complet, plus il gagne de points.\n'
                  'Exemple : Si 80% des champs sont remplis, vous obtenez (0.80 * 5) = 4 points.\n'
                  'Conseil : Prenez le temps de remplir tous les détails possibles de votre produit et d\'ajouter au moins une photo pour maximiser ce score.',
              color: Colors.green,
            ),
            _buildScoreCriterionCard(
              title: 'Ancienneté du Compte Vendeur (Bonus Spécial)',
              description: 'Principe : Nous voulons encourager les nouveaux vendeurs et récompenser la fidélité des plus anciens.\n'
                  'Comment ça marche :\n'
                  '• Nouveau Compte (< 1 mois) : Bénéficie d\'un bonus initial de 55 points (équivalent à un "Grand Boost"), qui diminue progressivement sur les 20 premiers jours de la vie du compte. Après 20 jours, ce bonus est de 0.\n'
                  '• Compte Ancien (> 1 mois) : Gagne un bonus croissant basé sur sa loyauté. Chaque mois d\'ancienneté du compte ajoute 10 points à la visibilité de tous ses produits, avec un plafond de 50 points (soit après 5 mois d\'ancienneté).\n'
                  'Conseil : Si vous êtes un nouveau vendeur, profitez de ce coup de pouce initial. Si vous êtes un vendeur établi, votre fidélité est automatiquement récompensée !',
              color: Colors.indigo,
            ),
            const SizedBox(height: 24),
            const Divider(),
            _buildSectionTitle('Exemple Concret de Calcul de Score 📊', myColors),
            _buildScoreExampleTable(myColors),
            const SizedBox(height: 24),
            const Divider(),
            _buildSectionTitle('Comment Utiliser ce Guide pour Booster vos Ventes ?', myColors),
            _buildSalesBoostTip(
              'Soignez vos Annonces',
              'Remplissez tous les détails de vos produits et ajoutez de belles photos pour maximiser la complétude et attirer l\'attention (critères 5 & 6).',
            ),
            _buildSalesBoostTip(
              'Restez Actif',
              'Mettez régulièrement à jour vos produits pour bénéficier du bonus de fraîcheur du produit (critère 3).',
            ),
            _buildSalesBoostTip(
              'Engagez votre Communauté',
              'Partagez vos produits sur les réseaux sociaux et dans vos cercles pour générer des vues et encourager les favoris (critères 4 & 5).',
            ),
            _buildSalesBoostTip(
              'Devenez Premium',
              'Un abonnement actif donne un avantage considérable à tous vos produits (critère 1).',
            ),
            _buildSalesBoostTip(
              'Utilisez le Boostage',
              'Pour un coup de projecteur ciblé sur vos produits les plus importants, activez un boost payant (critère 2).',
            ),
            _buildSalesBoostTip(
              'La Fidélité Paye',
              'Plus vous restez longtemps sur la plateforme, plus vos produits bénéficient d\'un bonus d\'ancienneté du compte (critère 7).',
            ),
            const SizedBox(height: 24),
            const Text(
              'Nous espérons que ce guide vous aidera à optimiser la visibilité de vos produits et à réaliser plus de ventes sur Tendance !',
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Colorsdata myColors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: myColors.primaryColor,
        ),
      ),
    );
  }

  Widget _buildScoreCriterionCard({required String title, required String description, required Color color}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreExampleTable(Colorsdata myColors) {
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(1),
        4: FlexColumnWidth(2),
        5: FlexColumnWidth(1),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: myColors.primaryColor.withOpacity(0.1)),
          children: [ // Removed 'const' here
            _buildTableHeaderCell('Critère'),
            _buildTableHeaderCell('Poids Max'),
            _buildTableHeaderCell('Produit A (Vendeur : 2 mois, Produit : 2 jours, Grand Boost)'),
            _buildTableHeaderCell('Score Obtenu A'),
            _buildTableHeaderCell('Produit B (Vendeur : 15 jours, Produit : 10 jours, Aucun Boost)'),
            _buildTableHeaderCell('Score Obtenu B'),
          ],
        ),
        _buildTableRow('Abonnement Actif du Vendeur', '30%', 'Actif', '30 points', 'Inactif', '0 points'),
        _buildTableRow('Boostage Payant', '55%', 'Grand Boost', '55 points', 'Aucun', '0 points'),
        _buildTableRow('Fraîcheur du Produit', '55%', '2 jours (facteur ~0.71)', '39 points', '10 jours (facteur 0)', '0 points'),
        _buildTableRow('Popularité par Vues', '10%', '> 100 vues', '10 points', '< 10 vues', '1 point'),
        _buildTableRow('Taux d\'Interaction (Favoris)', '5%', '> 20 favoris', '5 points', '0 favori', '0 points'),
        _buildTableRow('Complétude (Ex: 80% des champs)', '5%', '4 points', '4 points', '2.5 points', '2.5 points'), // Correction ici pour éviter une colonne vide
        _buildTableRow('Ancienneté du Compte Vendeur', '55% / 50%', 'Vendeur 2 mois (20 points de loyauté)', '20 points', 'Vendeur 15 jours (facteur ~0.25)', '13.75 points'),
        TableRow(
          decoration: BoxDecoration(color: myColors.accentColor.withOpacity(0.1)),
          children: [ // Removed 'const' here
            _buildTableCell('Score Total', isBold: true),
            _buildTableCell('', isBold: true),
            _buildTableCell('', isBold: true),
            _buildTableCell('163 points', isBold: true),
            _buildTableCell('', isBold: true),
            _buildTableCell('17.25 points', isBold: true),
          ],
        ),
      ],
    );
  }

  static Widget _buildTableHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }

  static TableRow _buildTableRow(String c1, String c2, String c3, String c4, String c5, String c6) {
    return TableRow(
      children: [
        _buildTableCell(c1),
        _buildTableCell(c2, isCenter: true),
        _buildTableCell(c3),
        _buildTableCell(c4, isCenter: true),
        _buildTableCell(c5),
        _buildTableCell(c6, isCenter: true),
      ],
    );
  }

  static Widget _buildTableCell(String text, {bool isBold = false, bool isCenter = false}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: 12),
        textAlign: isCenter ? TextAlign.center : TextAlign.left,
      ),
    );
  }

  Widget _buildSalesBoostTip(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• $title :',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: myColors.primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '  $description',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
