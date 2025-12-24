// file: lib/views/stores/publish_product_page.dart

import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tendance/controlers/authControler.dart';
import 'package:tendance/controlers/productControler.dart';
import 'package:tendance/models/productModel.dart';
import 'package:tendance/services/image_service_products.dart';
import '../../../controlers/ColorsData.dart';

class PublishProductPage extends StatefulWidget {
  final String storeId;
  final ProductModel? productToEdit; // Optionnel : produit à modifier
  const PublishProductPage({
    super.key,
    required this.storeId,
    this.productToEdit,
  });

  @override
  State<PublishProductPage> createState() => _PublishProductPageState();
}

class _PublishProductPageState extends State<PublishProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _price = TextEditingController();
  final _size = TextEditingController();
  final _brand = TextEditingController();
  final _color = TextEditingController();
  final _autreCategorie = TextEditingController();
  final _autreEtat = TextEditingController();
  String? _selectedCategory;
  String? _selectedCondition;
  final List<String> categories = ['Accessoires', 'Chaussures', 'Sacs', 'Vêtements', 'Autre'];
  final List<String> conditions = ['Neuf', 'Occasion', 'Excellent état', 'Bon état', 'État correct', 'Usé', 'Autre'];
  List<Map<String, dynamic>> _pickedImages = [];
  List<String> _existingImageUrls = [];
  bool _isSubmitting = false;
  final ImageServiceProduct _imageService = ImageServiceProduct();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ProductController productController = Get.find<ProductController>();
  final Colorsdata myColors = Colorsdata();
  List<String> _currencies = [];
String _selectedCurrency = 'FC';
  String get userIdFromAuthController {
    final auth = Get.find<AuthController>();
    final u = auth.currentUser.value;
    return u?.id ?? 'unknown_user';
  }

  @override
  void initState() {
    super.initState();
    _currencies = ['FC', '\$'];

    if (widget.productToEdit != null) {
      _title.text = widget.productToEdit!.title;
      _desc.text = widget.productToEdit!.description;
      _price.text = widget.productToEdit!.price.toString();
      _size.text = widget.productToEdit!.size ?? '';
      _brand.text = widget.productToEdit!.brand ?? '';
      _color.text = widget.productToEdit!.color ?? '';
      _selectedCategory = categories.contains(widget.productToEdit!.category) ? widget.productToEdit!.category : 'Autre';
      if (_selectedCategory == 'Autre') {
        _autreCategorie.text = widget.productToEdit!.category;
      }
      _selectedCondition = conditions.contains(widget.productToEdit!.condition) ? widget.productToEdit!.condition : 'Autre';
      if (_selectedCondition == 'Autre') {
        _autreEtat.text = widget.productToEdit!.condition;
      }
      _existingImageUrls = List.from(widget.productToEdit!.imageUrls);
     _currencies = ['FC', '\$']; // initialisation sécurisée
  if (widget.productToEdit != null) {
    _selectedCurrency = widget.productToEdit!.currency ?? 'FC';
  }
}
  }

  // ---------- pick images with visible progress dialogue ----------
  Future<void> _pickImages() async {
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          backgroundColor: myColors.white,
          content: SizedBox(
            height: 80,
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                CircularProgressIndicator(color: myColors.primaryColor),
                const SizedBox(height: 12),
                const Text('Préparation des images...')
              ]),
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
    try {
      final imgs = await _imageService.pickAndCompressMultiple(maxImages: 4 - (_existingImageUrls.length + _pickedImages.length));
      if (Get.isDialogOpen ?? false) Get.back();
      if (imgs == null || imgs.isEmpty) {
        Get.snackbar('Aucune image', 'Aucune nouvelle image sélectionnée', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange, colorText: myColors.white);
        return;
      }
      setState(() => _pickedImages.addAll(imgs));
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar('Erreur', 'Impossible de préparer les images: ${e.toString()}', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: myColors.white);
    }
  }

  Widget _buildImagePreview() {
    final allImages = <dynamic>[..._existingImageUrls];
    for (var img in _pickedImages) {
      allImages.add(img['bytes'] as Uint8List);
    }
    if (allImages.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        alignment: Alignment.center,
        child: Text('Aucune image sélectionnée', style: TextStyle(color: Colors.grey.shade600)),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: allImages.map((img) {
        return Stack(children: [
          img is String
              ? Image.network(img, width: 100, height: 100, fit: BoxFit.cover)
              : Image.memory(img as Uint8List, width: 100, height: 100, fit: BoxFit.cover),
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (img is String) {
                    _existingImageUrls.remove(img);
                  } else {
                    _pickedImages.removeWhere((element) => (element['bytes'] as Uint8List) == img);
                  }
                });
              },
              child: Container(
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.close, size: 18, color: Colors.white),
              ),
            ),
          ),
        ]);
      }).toList(),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedImages.isEmpty && _existingImageUrls.isEmpty) {
      Get.snackbar('Images manquantes', 'Veuillez ajouter au moins 1 image', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange, colorText: myColors.white);
      return;
    }

    setState(() => _isSubmitting = true);
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          backgroundColor: myColors.white,
          content: SizedBox(
            height: 110,
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                CircularProgressIndicator(color: myColors.primaryColor),
                const SizedBox(height: 12),
                const Text('Téléchargement des images...')
              ]),
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        if (mounted && (Get.isDialogOpen ?? false)) Navigator.of(context).pop();
        Get.snackbar('Erreur d\'authentification', 'Veuillez vous connecter pour publier un produit.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: myColors.white);
        setState(() => _isSubmitting = false);
        return;
      }

      // LOGIQUE POUR LA MODIFICATION (suppression d'anciennes images)
      if (widget.productToEdit != null) {
        final List<String> oldImageUrls = List.from(widget.productToEdit!.imageUrls);
        final List<String> imagesToDelete = oldImageUrls.where((url) => !_existingImageUrls.contains(url)).toList();
        if (imagesToDelete.isNotEmpty) {
          debugPrint('Images à supprimer de R2 lors de la modification: $imagesToDelete');
          final bool deleted = await _imageService.deleteProductImagesFromR2(imagesToDelete);
          if (!deleted) {
            debugPrint('Avertissement: Échec de la suppression de certaines anciennes images R2.');
            Get.snackbar('Avertissement', 'Produit modifié, mais certaines anciennes images n\'ont pas pu être supprimées de R2.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange, colorText: myColors.white, duration: const Duration(seconds: 5));
          }
        }
      }

      List<String> newImageUrls = [];
      if (_pickedImages.isNotEmpty) {
        final uploaded = await _imageService.uploadProductImages(images: _pickedImages, prefix: 'product');
        if (uploaded != null) {
          newImageUrls = uploaded;
        } else {
          throw Exception('Échec de l\'upload de certaines images (via service).');
        }
      }

      final allImageUrls = [..._existingImageUrls, ...newImageUrls];
      if (allImageUrls.isEmpty) throw Exception('Échec de l\'upload des images.');

      final CollectionReference productsRef = _firestore
          .collection('profiles')
          .doc(firebaseUser.uid)
          .collection('stores')
          .doc(widget.storeId)
          .collection('products');
      DocumentReference docRef;
      if (widget.productToEdit == null) {
        docRef = productsRef.doc(); // Nouveau produit
      } else {
        docRef = productsRef.doc(widget.productToEdit!.id); // Produit existant
      }

      final category = (_selectedCategory == 'Autre' && _autreCategorie.text.trim().isNotEmpty) ? _autreCategorie.text.trim() : (_selectedCategory ?? 'Autre');
      final condition = (_selectedCondition == 'Autre' && _autreEtat.text.trim().isNotEmpty) ? _autreEtat.text.trim() : (_selectedCondition ?? 'Non spécifié');

      final productData = {
        'id': docRef.id,
        'title': _title.text.trim(),
        'description': _desc.text.trim(),
        'price': double.tryParse(_price.text.replaceAll(',', '.')) ?? 0.0,
        'category': category,
        'condition': condition,
        'size': _size.text.trim().isEmpty ? null : _size.text.trim(),
        'brand': _brand.text.trim().isEmpty ? null : _brand.text.trim(),
        'color': _color.text.trim().isEmpty ? null : _color.text.trim(),
        'imageUrls': allImageUrls,
        'sellerId': firebaseUser.uid,
        'storeId': widget.storeId,
        'createdAt': widget.productToEdit == null ? FieldValue.serverTimestamp() : widget.productToEdit!.createdAt,
        'updatedAt': FieldValue.serverTimestamp(),
        'viewers': <String>[],
        'favorites': <String>[],
        'currency': _selectedCurrency,
      };

      await docRef.set(productData, SetOptions(merge: true));

      if (mounted && (Get.isDialogOpen ?? false)) Navigator.of(context).pop();

      Get.snackbar(
        'Succès',
        widget.productToEdit == null ? 'Produit publié avec succès !' : 'Produit modifié avec succès !',
        backgroundColor: Colors.green,
        colorText: myColors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );

      await Future.delayed(const Duration(seconds: 2));

      if (widget.productToEdit == null) {
        _formKey.currentState!.reset();
        if (mounted) {
          setState(() {
            _pickedImages = [];
            _existingImageUrls = [];
            _selectedCategory = null;
            _selectedCondition = null;
            _autreCategorie.clear();
            _autreEtat.clear();
            _size.clear();
            _brand.clear();
            _color.clear();
            _price.clear();
          });
        }
      }
      
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted && (Get.isDialogOpen ?? false)) Navigator.of(context).pop();
      debugPrint('Erreur publication/modification: $e');
      Get.snackbar('Erreur', 'Impossible d\'enregistrer le produit.\n${e.toString()}', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: myColors.white);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    // final bool isSmallScreen = screenWidth < 600; // Variable non utilisée, peut être supprimée
    return Scaffold(
      backgroundColor: myColors.background,
      appBar: AppBar(
        title: Text(widget.productToEdit == null ? 'Publier un produit' : 'Modifier le produit'),
        backgroundColor: myColors.primaryColor,
        foregroundColor: myColors.white,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionTitle('Informations Générales'),
                  _buildTextInput(
                    controller: _title,
                    labelText: 'Titre du produit',
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Le titre est requis' : null,
                  ),
                  _buildTextInput(
                    controller: _desc,
                    labelText: 'Description du produit',
                    maxLines: 4,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'La description est requise' : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: Row(
                      children: [
                        // Champ prix
                        Expanded(
                          child: TextFormField(
                            controller: _price,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Prix',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: myColors.primaryColor, width: 2),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Le prix est requis';
                              if (double.tryParse(v.replaceAll(',', '.')) == null) return 'Veuillez entrer un nombre valide';
                              return null;
                            },
                          ),
                        ),
                        SizedBox(width: 8,),
                        // Dropdown devise
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedCurrency,
                            items: _currencies.map((c) {
                              return DropdownMenuItem<String>(
                                value: c,
                                child: Text(c),
                              );
                            }).toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _selectedCurrency = v);
                              }
                            },
                            underline: const SizedBox(),
                          ),
                        ),
                        
                        
                      ],
                    ),
                  ),


                  
                  _buildSectionTitle('Détails du Produit'),
                  _buildDropdownInput(
                    labelText: 'Catégorie',
                    value: _selectedCategory,
                    items: categories,
                    onChanged: (v) => setState(() => _selectedCategory = v),
                    validator: (v) => (v == null || v.isEmpty) ? 'La catégorie est requise' : null,
                  ),
                  if (_selectedCategory == 'Autre')
                    _buildTextInput(
                      controller: _autreCategorie,
                      labelText: 'Précisez la catégorie',
                      margin: const EdgeInsets.only(top: 8, bottom: 10),
                    ),
                  
                  _buildDropdownInput(
                    labelText: 'État',
                    value: _selectedCondition,
                    items: conditions,
                    onChanged: (v) => setState(() => _selectedCondition = v),
                    validator: (v) => (v == null || v.isEmpty) ? 'L\'état est requis' : null,
                  ),
                  if (_selectedCondition == 'Autre')
                    _buildTextInput(
                      controller: _autreEtat,
                      labelText: 'Précisez l\'état',
                      margin: const EdgeInsets.only(top: 8, bottom: 10),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextInput(
                          controller: _size,
                          labelText: 'Taille',
                          margin: const EdgeInsets.only(right: 5), // Espacement entre les champs
                        ),
                      ),
                      Expanded(
                        child: _buildTextInput(
                          controller: _brand,
                          labelText: 'Marque',
                          margin: const EdgeInsets.only(left: 5), // Espacement entre les champs
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildTextInput(
                    controller: _color,
                    labelText: 'Couleur',
                  ),
                  _buildSectionTitle('Images du Produit'),
                  ElevatedButton.icon(
                    onPressed: () {
                      if ((_pickedImages.length + _existingImageUrls.length) >= 4) {
                        Get.snackbar('Limite atteinte', 'Vous avez déjà 4 images pour ce produit.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange, colorText: myColors.white);
                        return;
                      }
                      _pickImages();
                    },
                    icon: const Icon(Icons.photo_library),
                    label: Text('Sélectionner les images (max ${4 - (_pickedImages.length + _existingImageUrls.length)})'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: myColors.accentColor,
                      foregroundColor: myColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildImagePreview(),
                  const SizedBox(height: 20),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: myColors.primaryColor,
                        foregroundColor: myColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                          : Text(widget.productToEdit == null ? 'Publier le produit' : 'Enregistrer les modifications'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widgets d'aide pour le design
  Widget _buildTextInput({
    required TextEditingController controller,
    required String labelText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
    EdgeInsetsGeometry margin = const EdgeInsets.only(bottom: 15),
  }) {
    return Padding(
      padding: margin,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: myColors.primaryColor, width: 2),
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDropdownInput({
    required String labelText,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
    EdgeInsetsGeometry margin = const EdgeInsets.only(bottom: 15),
  }) {
    return Padding(
      padding: margin,
      child: DropdownButtonFormField<String>(
        value: value,
        items: items.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: myColors.primaryColor, width: 2),
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, top: 20),
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
}
