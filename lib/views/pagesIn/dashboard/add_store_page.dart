// file: lib/views/stores/add_store_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tendance/controlers/authControler.dart';
import 'package:tendance/controlers/storeControlers.dart'; // Importez le StoreController
import '../../../controlers/ColorsData.dart'; // Importez votre fichier de couleurs

class AddStorePage extends StatefulWidget {
  final String? storeIdToEdit; // ID de la boutique si on est en mode édition
  final String? initialName;
  final String? initialDescription;

  const AddStorePage({
    super.key,
    this.storeIdToEdit,
    this.initialName,
    this.initialDescription,
  });

  @override
  State<AddStorePage> createState() => _AddStorePageState();
}

class _AddStorePageState extends State<AddStorePage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _desc = TextEditingController();
  bool _loading = false;

  final StoreController storeController = Get.find<StoreController>(); // Accéder au StoreController
  final AuthController auth = Get.find<AuthController>();
  final Colorsdata myColors = Colorsdata();

  @override
  void initState() {
    super.initState();
    if (widget.storeIdToEdit != null) {
      _name.text = widget.initialName ?? '';
      _desc.text = widget.initialDescription ?? '';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final user = auth.currentUser.value;
    if (user == null) {
      Get.snackbar('Erreur', 'Utilisateur non connecté', backgroundColor: Colors.red, colorText: myColors.white);
      return;
    }

    setState(() => _loading = true);
    try {
      await storeController.saveStore(
        storeId: widget.storeIdToEdit, // Null pour nouvelle, ID pour édition
        userId: user.id,
        name: _name.text,
        description: _desc.text,
      );
      
      // Le contrôleur gère déjà le Get.back() et le snackbar
    } finally {
      setState(() => _loading = false);
      
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: myColors.background,
      appBar: AppBar(
        title: Text(widget.storeIdToEdit == null ? 'Nouvelle boutique' : 'Modifier la boutique'),
        backgroundColor: myColors.primaryColor,
        foregroundColor: myColors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                decoration: InputDecoration(
                  labelText: 'Nom de la boutique',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: myColors.primaryColor, width: 2),
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Le nom de la boutique est requis.' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _desc,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description de la boutique',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: myColors.primaryColor, width: 2),
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Une description est requise.' : null,
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _loading ? null : _save,
                icon: _loading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                    : const Icon(Icons.save),
                label: Text(widget.storeIdToEdit == null ? 'Créer la boutique' : 'Enregistrer les modifications'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: myColors.primaryColor,
                  foregroundColor: myColors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
