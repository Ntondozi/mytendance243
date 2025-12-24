import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tendance/views/pagesIn/dashboard/storeDetailClient.dart';
import 'package:tendance/views/pagesIn/dashboard/store_detail_page.dart';

import '../../../controlers/String.dart';
import '../../../controlers/navControler.dart';
import '../../../controlers/storeControlers.dart';
import '../../../models/navIds.dart';
import '../../../controlers/ColorsData.dart';

class StorePage extends StatefulWidget {
  StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  String? selectedValue;
  int currentPage = 1;
  final int itemsPerPage = 20;

  final storeController = Get.put(StoreController());
  final TextEditingController searchController = TextEditingController();

  final List<String> categories = [
    'Mbanza-ngungu',
    'Kimpese',
    'Lukala',
    'Kinshasa',
    'Matadi',
    'Boma',
    'Muanda',
    'Tshela',
    'Goma',
    'Bukavu',
    'Uvira',
    'Kisangani',
    'Butembo',
    'Beni'
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    double adaptiveSize(double small, double medium, double large) {
      if (width <= 500) return small;
      if (width <= 900) return medium;
      return large;
    }

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
                Expanded(
                  child: Row(
                    children: [
                      IconButton(
                          onPressed: () {
                            final navController = Get.find<NavigationInController>();
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
                          icon: Icon(Icons.arrow_back_ios)),
                      Text(
                        word().name,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: adaptiveSize(20, 24, 28),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.all(15),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Boutiques',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black)),
                          Text(
                            "Découvrez toutes les boutiques de vêtements d'occasion",
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                                color: Colorsdata().buttonHover),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),

                    // FILTRES
                    Container(
                      padding: EdgeInsets.all(15),
                      margin: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colorsdata().white,
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildTextFieldResponsive(
                              'Rechercher',
                              'Nom de la boutique, ville...',
                              width,
                              storeController,
                              searchController),
                          _buildDropdownResponsive(
                            'Toutes les villes',
                            'Ville',
                            categories,
                            selectedValue,
                            (v) {
                              setState(() => selectedValue = v);
                              storeController.selectedCity.value = v ?? '';
                            },
                            width,
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(7)),
                              backgroundColor: Colorsdata().buttonHover,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                selectedValue = null;
                              });
                              searchController.clear();
                              storeController.searchQuery.value = '';
                              storeController.selectedCity.value = '';
                              storeController.sortOption.value = '';
                            },
                            icon: Icon(Icons.refresh),
                            label: Text('Réinitialiser'),
                          )
                        ],
                      ),
                    ),

                    const SizedBox(height: 5),

                    // LISTE DES BOUTIQUES
                    Container(
                      padding: EdgeInsets.all(15),
                      margin: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: Colorsdata().white,
                          borderRadius: BorderRadius.circular(10)),
                      child: Obx(() {
                        if (storeController.isLoading.value) {
                          return Center(child: CircularProgressIndicator());
                        }

                        final stores = storeController.filteredStores;

                        if (stores.isEmpty) {
                          return Center(child: Text("Aucune boutique trouvée"));
                        }

                        return ListView.builder(
                          itemCount: stores.length,
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            final store = stores[index];

                            return Card(
                              color: Colorsdata().background,
                              margin:
                                  const EdgeInsets.symmetric(vertical: 5),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colorsdata().buttonHover,
                                  backgroundImage: store['imageUrl'] != null
                                      ? NetworkImage(store['imageUrl'])
                                      : null,
                                  child: store['imageUrl'] == null
                                      ? Text(store['name'][0].toUpperCase(),
                                          style: TextStyle(
                                              color: Colorsdata().white))
                                      : null,
                                ),
                                title: Text(store['name'], overflow: TextOverflow.ellipsis,
                                maxLines: 1),
                                subtitle: Container(
                                  margin: EdgeInsets.only(top: 5),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 4),
                                      Text(
                                        store['description'],
                                        overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                        style: TextStyle(fontSize: 13),
                                        textAlign: TextAlign.justify,
                                      ),
                                      SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            flex: 4,
                                            child: Text('Ville : ${store['city']}', overflow: TextOverflow.ellipsis,
                                                                            maxLines: 2),
                                          ),
                                          SizedBox(width: 5),
                                          Expanded(
                                            flex: 4,
                                            child: Align(
                                              alignment: Alignment.centerRight,
                                              child: Text(
                                                  'Articles : ${store['totalProducts']}',
                                                  style:
                                                      TextStyle(fontSize: 13)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                onTap: () {
                                  
                                final navController = Get.find<NavigationInController>();
                              switch (navController.selectedIndex.value) {
                              case 0:
                                Get.toNamed(
                                  '/ExploreInPage/storeDetail',
                                  arguments: {
                                    'storeId': store['id'],
                                    'sellerId': store['ownerId'],
                                  },
                                  id: NavInIds.explorer, // navigation imbriquée
                                );
                                break;
                              case 1:
                                Get.toNamed(
                                  '/favoris/storeDetail',
                                  arguments: {
                                    'storeId': store['id'],
                                    'sellerId': store['ownerId'],
                                  },
                                  id: NavInIds.favoris, // navigation imbriquée
                                );
                                break;
                              case 2:
                                Get.toNamed(
                                  '/message/storeDetail',
                                  arguments: {
                                    'storeId': store['id'],
                                    'sellerId': store['ownerId'],
                                  },
                                  id: NavInIds.messages, // navigation imbriquée
                                );
                                break;
                              case 3:
                                Get.toNamed(
                                  '/dashboard/storeDetail',
                                  arguments: {
                                    'storeId': store['id'],
                                    'sellerId': store['ownerId'],
                                  },
                                  id: NavInIds.dashboard, // navigation imbriquée
                                );
                                 break;
                              default:
                                print("Index inconnu: ${navController.selectedIndex.value}");
                            }
                                },

                                
                              ),
                            );
                          },
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildDropdownResponsive(String label, String title, List<String> items,
    String? value, Function(String?) onChanged, double width) {
  return Container(
    padding: EdgeInsets.all(8),
    margin: const EdgeInsets.only(bottom: 10),
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colorsdata().background,
      border: Border.all(color: Colors.grey),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: width < 600 ? 12 : 14)),
        Container(
          height: 40,
          margin: EdgeInsets.only(top: 4),
          padding: EdgeInsets.only(left: 10),
          decoration: BoxDecoration(
            color: Colorsdata().white,
            borderRadius: BorderRadius.circular(5),
          ),
          child: DropdownButton<String>(
            style: TextStyle(fontSize: 14),
            isExpanded: true,
            hint: Text(label),
            value: value,
            onChanged: onChanged,
            items: items
                .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                .toList(),
          ),
        ),
      ],
    ),
  );
}

Widget _buildTextFieldResponsive(String title, String hint, double width,
    StoreController controller, TextEditingController searchController) {
  return Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: EdgeInsets.all(8),
    decoration: BoxDecoration(
        color: Colorsdata().background,
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(7)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: width < 600 ? 12 : 14)),
        const SizedBox(height: 5),
        SizedBox(
          height: 40,
          child: TextField(
            controller: searchController,
            onChanged: (value) => controller.searchQuery.value = value,
            decoration: InputDecoration(
              fillColor: Colors.white,
              filled: true,
              prefixIcon: Icon(Icons.search_outlined, color: Colors.grey),
              hintText: hint,
              hintStyle: TextStyle(fontSize: width < 600 ? 14 : 16),
              focusedBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: Colorsdata().buttonHover, width: 2)),
              enabledBorder:
                  OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 1, vertical: 8),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildHeaderIcon(
    double screenWidth, IconData icons, VoidCallback onPressed) {
  return IconButton(
      onPressed: onPressed,
      icon: Icon(icons,
          size: screenWidth < 600 ? 30 : 40,
          color: const Color.fromARGB(221, 79, 72, 72)));
}
