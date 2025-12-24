// file: lib/services/image_service_products.dart

import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img_lib;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class ImageServiceProduct {
  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String get _projectId => _firestore.app.options.projectId!;

  // --- Fonction utilitaires pour les appels HTTP aux Cloud Functions ---
  Future<Map<String, dynamic>> _callHttpsFunction(String functionName, Map<String, dynamic> params) async {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (idToken == null) {
      throw Exception('Utilisateur non authentifié. Veuillez vous reconnecter.');
    }
    
    // REMPLACEZ 'us-central1' PAR LA RÉGION DE VOS FONCTIONS (ex: 'europe-west1', 'asia-east2')
    final String cloudFunctionRegion = 'us-central1'; // <= VÉRIFIEZ ET MODIFIEZ CETTE RÉGION
    final String url = 'https://$cloudFunctionRegion-$_projectId.cloudfunctions.net/$functionName';
    
    // Correction CLÉ : Envelopper les paramètres dans une clé "data"
    final Map<String, dynamic> requestBody = {'data': params};

    print('[DEBUG CF_CALL] Appel de la fonction $functionName avec l\'URL: $url');
    print('[DEBUG CF_CALL] Corps de la requête (RAW): ${jsonEncode(requestBody)}');

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body) as Map<String, dynamic>;
      print('[DEBUG CF_CALL] Réponse de $functionName (RAW): ${response.body}');
      // Les réponses des fonctions onCall sont aussi enveloppées dans "result"
      if (responseData.containsKey('result')) {
        return responseData['result'] as Map<String, dynamic>;
      } else {
        throw Exception('Réponse inattendue de la fonction Cloud: Pas de clé "result".');
      }
    } else {
      print('[DEBUG CF_CALL] Erreur HTTP ${response.statusCode}: ${response.body}');
      throw Exception('Problème lors de l\'appel à la fonction Cloud ($functionName - ${response.statusCode}): ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>?> pickAndCompressMultiple({int maxImages = 4}) async {
    try {
      List<Map<String, dynamic>> picked = [];
      if (kIsWeb) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: true,
          withData: true,
        );
        if (result == null || result.files.isEmpty) return null;
        for (final f in result.files) {
          if (f.bytes == null) continue;
          picked.add({'bytes': f.bytes!, 'fileName': f.name});
        }
      } else {
        final picker = ImagePicker();
        final images = await picker.pickMultiImage(imageQuality: 85);
        if (images == null || images.isEmpty) return null;
        for (final p in images) {
          final bytes = await p.readAsBytes();
          picked.add({'bytes': bytes, 'fileName': p.name});
        }
      }
      if (picked.length > maxImages) {
        picked.shuffle();
        picked = picked.sublist(0, maxImages);
      }
      List<Map<String, dynamic>> compressedList = [];
      for (final item in picked) {
        Uint8List bytes = item['bytes'];
        final name = item['fileName'] ?? 'image.jpg';
        if (kIsWeb) {
          final decoded = img_lib.decodeImage(bytes);
          if (decoded != null) {
            final resized = img_lib.copyResize(decoded, width: 1280);
            final jpg = img_lib.encodeJpg(resized, quality: 75);
            compressedList.add({'bytes': Uint8List.fromList(jpg), 'fileName': name});
          } else {
            compressedList.add({'bytes': bytes, 'fileName': name});
          }
        } else {
          try {
            final compressed = await FlutterImageCompress.compressWithList(
              bytes,
              quality: 75,
              minWidth: 1280,
              minHeight: 1280,
              format: CompressFormat.jpeg,
            );
            compressedList.add({'bytes': Uint8List.fromList(compressed), 'fileName': name});
          } catch (e) {
            compressedList.add({'bytes': bytes, 'fileName': name});
          }
        }
      }
      return compressedList;
    } catch (e) {
      debugPrint('Erreur pickAndCompressMultiple: $e');
      return null;
    }
  }

  /// Upload multiple images to Cloudflare R2 via a Cloud Function and return list of public urls
  Future<List<String>?> uploadProductImages({
    required List<Map<String, dynamic>> images,
    required String prefix,
  }) async {
    try {
      List<String> urls = [];
      for (int i = 0; i < images.length; i++) {
        final bytes = images[i]['bytes'] as Uint8List;
        final originalName = images[i]['fileName'] as String? ?? 'img.jpg';
        final String base64Image = base64Encode(bytes);

        final result = await _callHttpsFunction('uploadImageToR2', {
          'imageData': base64Image,
          'fileName': originalName,
          'prefix': prefix,
        });
        
        if (result.containsKey('imageUrl') && result['imageUrl'] != null) {
          urls.add(result['imageUrl'] as String);
        } else {
          throw Exception('La fonction Cloud n\'a pas retourné d\'URL d\'image valide.');
        }
      }
      return urls;
    } on Exception catch (e) {
      debugPrint('Erreur uploadProductImages: ${e.toString()}');
      throw Exception('Une erreur est survenue lors de l\'upload des images: ${e.toString()}');
    }
  }

  /// Delete images from Cloudflare R2 via a Cloud Function
  Future<bool> deleteProductImagesFromR2(List<String> imageUrls) async {
    if (imageUrls.isEmpty) return true;
    try {
      final result = await _callHttpsFunction('deleteR2ImagesByUrls', {
        'imageUrls': imageUrls,
      });
      return result.containsKey('success') ? (result['success'] as bool) : false;
    } on Exception catch (e) {
      debugPrint('Erreur deleteProductImagesFromR2: ${e.toString()}');
      throw Exception('Une erreur est survenue lors de la suppression des images: ${e.toString()}');
    }
  }
}
