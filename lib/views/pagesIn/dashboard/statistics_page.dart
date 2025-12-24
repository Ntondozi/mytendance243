import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart' hide RadarChart; // Pour les graphiques
import 'package:intl/intl.dart'; // Pour formater les nombres
import 'package:flutter_radar_chart/flutter_radar_chart.dart'; // Import pour RadarChart

import '../../../controlers/ColorsData.dart';
import '../../../controlers/authControler.dart';
import '../../../controlers/storeControlers.dart';
import '../../../controlers/subscription_controller.dart';
import '../../../models/productModel.dart'; // Importez votre ProductModel
import 'visibility_guide_page.dart'; // Importez la nouvelle page

// Nouvelle structure de données pour stocker les stats de produit traitées
class ProductStatData {
  final String id;
  final String title;
  final int views;
  final int favorites;
  final double totalScore;
  final Map<String, double> scoreComponents;
  final DateTime? createdAt;
  final double price;
  final String? storeName;

  ProductStatData({
    required this.id,
    required this.title,
    required this.views,
    required this.favorites,
    required this.totalScore,
    required this.scoreComponents,
    this.createdAt,
    required this.price,
    this.storeName,
  });
}

// Cache pour les informations du vendeur afin d'éviter les lectures répétées
class _SellerCacheEntry {
  final DateTime? createdAt;
  final bool hasActiveSubscription;
  final String? ownerName;

  _SellerCacheEntry({this.createdAt, required this.hasActiveSubscription, this.ownerName});
}

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final Colorsdata myColors = Colorsdata();
  final StoreController storeController = Get.find<StoreController>();
  final SubscriptionController subController = Get.find<SubscriptionController>();
  final AuthController authController = Get.find<AuthController>();

  String? selectedStoreId = 'global'; 

  Map<String, dynamic>? statsData;
  List<ProductStatData> productStats = [];
  Map<String, double> scoreComponentTotals = {};
  bool isLoadingStats = false;
  
  final Map<String, double> _scoreWeights = {
    'abonnement': 0.30,
    'boost_payant_max': 0.55,
    'vues': 0.10,
    'completude': 0.05,
    'favoris': 0.05,
    'product_freshness_max': 0.55,
    'account_freshness_max': 0.55,
    'account_loyalty_max': 0.50,
  };

  final Map<String, _SellerCacheEntry> _sellerCache = {};

  @override
  void initState() {
    super.initState();
    final userId = authController.currentUser.value?.id ?? '';
    storeController.fetchUserStores(userId).then((_) {
      if (mounted) {
        loadStats();
      }
    });
  }

  Future<void> loadStats({String? storeId}) async {
    setState(() {
      isLoadingStats = true;
      selectedStoreId = storeId ?? 'global';
      productStats = [];
      scoreComponentTotals = {};
    });

    try {
      final userId = authController.currentUser.value?.id ?? '';
      List<DocumentSnapshot> allProductDocs = [];
      List<Map<String, dynamic>> storesToProcess = [];

      if (selectedStoreId == 'global') {
        storesToProcess = storeController.userStores.toList();
      } else {
        final selectedStore = storeController.userStores.firstWhereOrNull((s) => s['id'] == selectedStoreId);
        if (selectedStore != null) {
          storesToProcess.add(selectedStore);
        }
      }

      for (var store in storesToProcess) {
        final productsSnap = await FirebaseFirestore.instance
            .collection('profiles')
            .doc(userId)
            .collection('stores')
            .doc(store['id'])
            .collection('products')
            .get();
        allProductDocs.addAll(productsSnap.docs);
      }

      await _processProductStats(allProductDocs, userId);

    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de charger les statistiques: $e',
          backgroundColor: Colors.red, colorText: myColors.white);
    } finally {
      if(mounted){
        setState(() => isLoadingStats = false);
      }
    }
  }

  Future<void> _processProductStats(List<DocumentSnapshot> productDocs, String currentUserId) async {
    int totalViews = 0;
    int totalFavorites = 0;
    List<ProductStatData> tempProductStats = [];
    Map<String, double> tempScoreComponentTotals = {
      'Abonnement': 0, 'Boost': 0, 'Vues': 0, 'Favoris': 0,
      'Complétude': 0, 'Fraîcheur Produit': 0, 'Ancienneté Compte': 0,
    };

    Set<String> uniqueSellerIds = {};
    for (var doc in productDocs) {
      final pathSegments = doc.reference.path.split('/');
      if (pathSegments.length >= 4) {
        uniqueSellerIds.add(pathSegments[1]);
      }
    }

    for (var sellerId in uniqueSellerIds) {
      if (!_sellerCache.containsKey(sellerId)) {
        final userDoc = await FirebaseFirestore.instance.collection('profiles').doc(sellerId).get();
        final sellerData = userDoc.data() as Map<String, dynamic>?;
        final sellerSubscription = await subController.readSubscriptionFromFirestore(sellerId);
        final sellerCreatedAt = (sellerData?['created_at'] as Timestamp?)?.toDate();
        final hasActiveSub = sellerSubscription != null && sellerSubscription.expiresAtMillis > DateTime.now().millisecondsSinceEpoch;
        _sellerCache[sellerId] = _SellerCacheEntry(
          createdAt: sellerCreatedAt,
          hasActiveSubscription: hasActiveSub,
          ownerName: sellerData?['username'],
        );
      }
    }
    
    for (var doc in productDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final pathSegments = doc.reference.path.split('/');
      String? sellerId;
      String? storeId;
      if (pathSegments.length >= 4) {
        sellerId = pathSegments[1];
        storeId = pathSegments[3];
      }

      if (sellerId == null || storeId == null) {
        continue;
      }

      final sellerCacheEntry = _sellerCache[sellerId];
      if (sellerCacheEntry == null) {
        continue;
      }
      
      String? currentStoreName;
      final storeInController = storeController.userStores.firstWhereOrNull((s) => s['id'] == storeId);
      currentStoreName = storeInController?['name'] ?? storeId;

      List<String> favorites = List<String>.from(data['favorites'] ?? []);
      List<String> viewers = List<String>.from(data['viewers'] ?? []);

      final ProductModel baseProduct = ProductModel.fromFirestore({
        ...data,
        'id': doc.id,
        'ownerName': sellerCacheEntry.ownerName,
        'storeName': currentStoreName,
        'favorites': favorites,
        'viewers': viewers,
        'ownerHasActiveSubscription': sellerCacheEntry.hasActiveSubscription,
        'sellerCreatedAt': sellerCacheEntry.createdAt,
      });

      final double completude = baseProduct.calculateCompletudeScore();
      final ProductModel product = baseProduct.copyWith(completudeScore: completude);

      final views = product.viewers.length;
      final favoritesCount = product.favorites.length;
      totalViews += views;
      totalFavorites += favoritesCount;

      final scoreComponents = _calculateIndividualProductScoreComponents(product);
      double totalScore = _calculateProductScoreTotal(product);

      scoreComponents.forEach((key, value) {
        tempScoreComponentTotals[key] = (tempScoreComponentTotals[key] ?? 0) + value;
      });

      tempProductStats.add(ProductStatData(
        id: product.id,
        title: product.title,
        views: views,
        favorites: favoritesCount,
        totalScore: totalScore,
        scoreComponents: scoreComponents,
        createdAt: product.createdAt,
        price: product.price,
        storeName: currentStoreName,
      ));
    }

    tempProductStats.sort((a, b) => b.totalScore.compareTo(a.totalScore));

    setState(() {
      statsData = {
        'totalProducts': productDocs.length,
        'totalViews': totalViews,
        'totalFavorites': totalFavorites,
      };
      productStats = tempProductStats;
      scoreComponentTotals = tempScoreComponentTotals;
    });
  }

  double _calculateProductScoreTotal(ProductModel product) {
    double score = 0.0;
    final now = DateTime.now();

    if (product.ownerHasActiveSubscription == true) {
      score += _scoreWeights['abonnement']! * 100;
    }

    if (product.boostLevel != null &&
        product.boostExpiresAt != null &&
        product.boostExpiresAt!.isAfter(now)) {
      switch (product.boostLevel) {
        case 'petit':
          score += 0.25 * _scoreWeights['boost_payant_max']! * 100;
          break;
        case 'moyen':
          score += 0.40 * _scoreWeights['boost_payant_max']! * 100;
          break;
        case 'grand':
          score += _scoreWeights['boost_payant_max']! * 100;
          break;
      }
    }

    final totalViews = product.viewers.length;
    if (totalViews > 100) {
      score += _scoreWeights['vues']! * 100;
    } else if (totalViews > 50) {
      score += 0.07 * 100;
    } else if (totalViews > 10) {
      score += 0.04 * 100;
    } else {
      score += 0.01 * 100;
    }

    final totalFavorites = product.favorites.length;
    if (totalFavorites > 20) {
      score += _scoreWeights['favoris']! * 100;
    } else if (totalFavorites > 10) {
      score += 0.03 * 100;
    } else if (totalFavorites > 0) {
      score += 0.01 * 100;
    }

    score += (product.completudeScore ?? 0.0) * _scoreWeights['completude']! * 100;

    if (product.createdAt != null) {
      final daysSinceCreation = now.difference(product.createdAt!).inDays;
      if (daysSinceCreation < 7) {
        final decayFactor = (7 - daysSinceCreation) / 7;
        score += decayFactor * _scoreWeights['product_freshness_max']! * 100;
      }
    }

    if (product.sellerCreatedAt != null) {
      final accountAgeInDays = now.difference(product.sellerCreatedAt!).inDays;
      final accountAgeInMonths = (accountAgeInDays / 30).floor();
      if (accountAgeInDays < 30) {
        if (accountAgeInDays < 20) {
          final decayFactor = (20 - accountAgeInDays) / 20;
          score += decayFactor * _scoreWeights['account_freshness_max']! * 100;
        }
      } else {
        if (accountAgeInMonths > 0) {
          double loyaltyBonus = accountAgeInMonths * 10.0;
          score += loyaltyBonus.clamp(0.0, _scoreWeights['account_loyalty_max']! * 100);
        }
      }
    }
    return score.clamp(0.0, 1000.0);
  }

  Map<String, double> _calculateIndividualProductScoreComponents(ProductModel product) {
    Map<String, double> components = {};
    final now = DateTime.now();

    components['Abonnement'] = product.ownerHasActiveSubscription == true ? _scoreWeights['abonnement']! * 100 : 0;

    double boostScore = 0;
    if (product.boostLevel != null && product.boostExpiresAt != null && product.boostExpiresAt!.isAfter(now)) {
      switch (product.boostLevel) {
        case 'petit':
          boostScore = 0.25 * _scoreWeights['boost_payant_max']! * 100;
          break;
        case 'moyen':
          boostScore = 0.40 * _scoreWeights['boost_payant_max']! * 100;
          break;
        case 'grand':
          boostScore = _scoreWeights['boost_payant_max']! * 100;
          break;
      }
    }
    components['Boost'] = boostScore;

    double vuesScore = 0;
    final totalViews = product.viewers.length;
    if (totalViews > 100) vuesScore = _scoreWeights['vues']! * 100;
    else if (totalViews > 50) vuesScore = 0.07 * 100;
    else if (totalViews > 10) vuesScore = 0.04 * 100;
    else if (totalViews > 0) vuesScore = 0.01 * 100;
    components['Vues'] = vuesScore;

    double favorisScore = 0;
    final totalFavorites = product.favorites.length;
    if (totalFavorites > 20) favorisScore = _scoreWeights['favoris']! * 100;
    else if (totalFavorites > 10) favorisScore = 0.03 * 100;
    else if (totalFavorites > 0) favorisScore = 0.01 * 100;
    components['Favoris'] = favorisScore;

    components['Complétude'] = (product.completudeScore ?? 0.0) * _scoreWeights['completude']! * 100;

    double productFreshnessScore = 0;
    if (product.createdAt != null) {
      final daysSinceCreation = now.difference(product.createdAt!).inDays;
      if (daysSinceCreation < 7) {
        final decayFactor = (7 - daysSinceCreation) / 7;
        productFreshnessScore = decayFactor * _scoreWeights['product_freshness_max']! * 100;
      }
    }
    components['Fraîcheur Produit'] = productFreshnessScore;

    double accountScore = 0;
    if (product.sellerCreatedAt != null) {
      final accountAgeInDays = now.difference(product.sellerCreatedAt!).inDays;
      final accountAgeInMonths = (accountAgeInDays / 30).floor();
      if (accountAgeInDays < 30) {
        if (accountAgeInDays < 20) {
          final decayFactor = (20 - accountAgeInDays) / 20;
          accountScore = decayFactor * _scoreWeights['account_freshness_max']! * 100;
        }
      } else {
        if (accountAgeInMonths > 0) {
          double loyaltyBonus = accountAgeInMonths * 10.0;
          accountScore = loyaltyBonus.clamp(0.0, _scoreWeights['account_loyalty_max']! * 100);
        }
      }
    }
    components['Ancienneté Compte'] = accountScore;

    return components;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: myColors.background,
      body: Obx(() {
        final stores = storeController.userStores;
        if (stores.isEmpty && selectedStoreId != 'global') {
          return const Center(child: Text("Vous n'avez pas encore de boutiques."));
        }

        List<DropdownMenuItem<String>> dropdownItems = [
          const DropdownMenuItem<String>(
            value: 'global',
            child: Text('Stats Globales', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ...stores.map((store) {
            return DropdownMenuItem<String>(
              value: store['id'] as String,
              child: Text(store['name']),
            );
          }).toList(),
        ];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sélectionnez une vue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: myColors.primaryColor)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedStoreId,
                items: dropdownItems,
                onChanged: (val) {
                  if (val != null) loadStats(storeId: val == 'global' ? null : val);
                },
                decoration: InputDecoration(
                  fillColor: myColors.white,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              if (isLoadingStats)
                const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()))
              else if (statsData != null)
                _buildStatsContent()
              else
                const Center(child: Text("Aucune donnée à afficher.")),
              
              const SizedBox(height: 30),
              const Divider(),
              _buildFooter(), // Ajout du footer
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatsContent() {
    final title = selectedStoreId == 'global' ? 'Stats Globales du Compte' : 'Statistiques de la boutique';
    final numberFormatter = NumberFormat.compact(locale: 'fr');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: myColors.primaryColor)),
        const SizedBox(height: 16),
        
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            _statCard('Produits', numberFormatter.format(statsData!['totalProducts']), Colors.blue),
            _statCard('Vues Totales', numberFormatter.format(statsData!['totalViews']), Colors.orange),
            _statCard('Favoris Total', numberFormatter.format(statsData!['totalFavorites']), Colors.red),
          ],
        ),
        const SizedBox(height: 24),
        const Divider(),
        
        Text('Répartition des Scores Généraux', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: myColors.primaryColor)),
        const SizedBox(height: 16),
        
        SizedBox(
          height: 200,
          child: _buildScorePieChart(),
        ),
        const SizedBox(height: 16),
        
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: scoreComponentTotals.entries.map((e) {
             final total = scoreComponentTotals.values.fold(0.0, (prev, curr) => prev + curr);
             final percentage = total == 0 ? 0.0 : (e.value / total * 100);
             return _scoreChip(e.key, e.value, _getColorForScore(e.key), percentage);
          }).toList(),
        ),
        
        const SizedBox(height: 24),
        const Divider(),

        Text('Top Produits par Score', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: myColors.primaryColor)),
        const SizedBox(height: 16),
        SizedBox(
          height: 250,
          child: _buildTopProductsBarChart(),
        ),
        const SizedBox(height: 24),
        const Divider(),

        if (selectedStoreId != 'global' && productStats.isNotEmpty) ...[
          Text('Statistiques Détaillées des Produits', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: myColors.primaryColor)),
          const SizedBox(height: 16),
          ...productStats.map((product) => _buildIndividualProductCard(product)).toList(),
        ],
      ],
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3))
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 14, color: color.withOpacity(0.9))),
        ],
      ),
    );
  }
  
  Widget _scoreChip(String label, double value, Color color, double percentage) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: ${value.toStringAsFixed(0)} pts (${percentage.toStringAsFixed(1)}%)',
        style: TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 12),
      ),
    );
  }

  Widget _buildScorePieChart() {
    double totalScore = scoreComponentTotals.values.fold(0.0, (prev, e) => prev + e);
    if (totalScore == 0) return const Center(child: Text("Pas de données de score"));

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: scoreComponentTotals.entries.map((entry) {
          return PieChartSectionData(
            color: _getColorForScore(entry.key),
            value: entry.value,
            title: totalScore == 0 ? '0%' : '${(entry.value / totalScore * 100).toStringAsFixed(0)}%',
            radius: 60,
            titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTopProductsBarChart() {
    final topProducts = productStats.take(5).toList();
    if(topProducts.isEmpty) return const Center(child: Text("Pas de produits à afficher"));

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: topProducts.isNotEmpty ? topProducts.first.totalScore * 1.2 : 100,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Colors.blueGrey,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final product = topProducts[group.x.toInt()];
              return BarTooltipItem(
                '${product.title}\n',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                children: <TextSpan>[
                  TextSpan(
                    text: (rod.toY).toStringAsFixed(0) + ' pts',
                    style: const TextStyle(color: Colors.yellow),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final product = topProducts[value.toInt()];
                return SideTitleWidget(
                  meta: meta,
                  space: 8.0,
                  child: Text(
                    product.title, 
                    style: const TextStyle(fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: topProducts.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.totalScore,
                color: myColors.primaryColor,
                width: 15,
                borderRadius: BorderRadius.circular(4)
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildIndividualProductCard(ProductStatData product) {
    final List<String> features = product.scoreComponents.keys.toList();
    final List<double> values = product.scoreComponents.values.toList();

    // Normaliser les valeurs pour le RadarChart (max 100 par composant)
    final List<double> normalizedData = values.map((e) => e.clamp(0.0, 100.0)).toList();
    final List<List<double>> radarData = [normalizedData];
    
    // Ticks pour une échelle de 0 à 100
    const ticks = [25, 50, 75, 100];

    // Max pour le CircularProgressIndicator
    final int maxViews = productStats.map((p) => p.views).fold(0, (prev, e) => e > prev ? e : prev);
    final int maxFavorites = productStats.map((p) => p.favorites).fold(0, (prev, e) => e > prev ? e : prev);
    final int overallMax = (maxViews > maxFavorites ? maxViews : maxFavorites);
    final double viewsProgress = overallMax == 0 ? 0 : product.views / overallMax;
    final double favsProgress = overallMax == 0 ? 0 : product.favorites / overallMax;


    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(product.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text('Score total: ${product.totalScore.toStringAsFixed(0)} pts',
          style: const TextStyle(fontSize: 12)),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Détail des scores:', style: TextStyle(fontWeight: FontWeight.bold, color: myColors.primaryColor)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: product.scoreComponents.entries.map((e) {
              final total = product.scoreComponents.values.fold(0.0, (prev, curr) => prev + curr);
              final percentage = total == 0 ? 0.0 : (e.value / total * 100);
              return _scoreChip(e.key, e.value, _getColorForScore(e.key), percentage);
            }).toList(),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Visualisation des Scores (Radar Chart):', style: TextStyle(fontWeight: FontWeight.bold, color: myColors.primaryColor)),
          ),
          const SizedBox(height: 12),
          Container(
            height: 250,
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300)
            ),
            child: RadarChart(
              ticks: ticks,
              features: features,
              data: radarData,
              sides: features.length,
              outlineColor: myColors.primaryColor.withOpacity(0.8),
              axisColor: Colors.grey.shade600,
              featuresTextStyle: const TextStyle(color: Colors.black, fontSize: 10),
              graphColors: [myColors.primaryColor],
              // usePoints: false,
              // reverseAxis: false,
            ),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Performance Vues et Favoris:', style: TextStyle(fontWeight: FontWeight.bold, color: myColors.primaryColor)),
          ),
          const SizedBox(height: 12),
          // Nouveau design pour Vues et Favoris
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCircularMetric(
                label: 'Vues',
                value: product.views,
                color: Colors.blue,
                progress: viewsProgress,
                overallMax: overallMax,
              ),
              _buildCircularMetric(
                label: 'Favoris',
                value: product.favorites,
                color: Colors.red,
                progress: favsProgress,
                overallMax: overallMax,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircularMetric({
    required String label,
    required int value,
    required Color color,
    required double progress,
    required int overallMax,
  }) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 8,
                backgroundColor: color.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Text(
              value.toString(),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: color, fontSize: 14)),
        Text('(Max: ${overallMax == 0 ? 'N/A' : overallMax})', style: TextStyle(color: Colors.grey[600], fontSize: 10)),
      ],
    );
  }

  Color _getColorForScore(String scoreComponent) {
    switch (scoreComponent) {
      case 'Abonnement': return Colors.purple;
      case 'Boost': return Colors.amber;
      case 'Vues': return Colors.blue;
      case 'Favoris': return Colors.red;
      case 'Complétude': return Colors.green;
      case 'Fraîcheur Produit': return Colors.teal;
      case 'Ancienneté Compte': return Colors.indigo;
      default: return Colors.grey;
    }
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Column(
        children: [
          const Text(
            'Les statistiques vous permettent de comprendre la performance de vos produits et d\'optimiser leur visibilité.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              Get.to(() => const VisibilityGuidePage());
            },
            child: Text(
              'Cliquez ici pour comprendre comment sont calculés les scores',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: myColors.primaryColor,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
