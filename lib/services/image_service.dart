import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloudflare_r2/cloudflare_r2.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:mime/mime.dart';
import 'package:image/image.dart' as img;

class ImageService {
  // ⚠️ Remplace par tes infos R2
  final String accountId = 'd2fe783fd35d148dff45eac1efc15744';
  final String accessKeyId = 'c918cd2b1ed359f508fa436f8a584d17';
  final String secretAccessKey =
      '058d3002e7e7f8f1b76a38e75cecc50112bb6cc20b888cf09869c89347198986';
  final String bucket = 'user-profils';

  // Public Dev URL de ton bucket
  final String publicDevUrl = 'https://pub-085bd261b6864e2182d9182b3b6581e4.r2.dev';

  ImageService() {
    CloudFlareR2.init(
      accountId: accountId,
      accessKeyId: accessKeyId,
      secretAccessKey: secretAccessKey,
    );
  }

  /// 📸 Sélection et compression d'une image (mobile ou web)
  Future<Map<String, dynamic>?> pickAndCompress() async {
    try {
      Uint8List? imageBytes;
      String? fileName;

      if (kIsWeb) {
        // Web : sélection avec FilePicker
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          withData: true,
        );
        if (result == null || result.files.isEmpty) return null;

        imageBytes = result.files.first.bytes!;
        fileName = result.files.first.name;

        // Compression web via package 'image'
        img.Image? image = img.decodeImage(imageBytes);
        if (image != null) {
          final resized = img.copyResize(image, width: 1080); // Reduit largeur à 1080px
          imageBytes = Uint8List.fromList(img.encodeJpg(resized, quality: 70));
        }
      } else {
        // Mobile : sélection avec ImagePicker + compression FlutterImageCompress
        final picker = ImagePicker();
        final picked = await picker.pickImage(source: ImageSource.gallery);
        if (picked == null) return null;

        final compressed = await FlutterImageCompress.compressWithFile(
          picked.path,
          quality: 70,
          minWidth: 1080,
          minHeight: 1080,
          format: CompressFormat.jpeg,
        );
        imageBytes = compressed;
        fileName = picked.name;
      }

      return {"bytes": imageBytes, "fileName": fileName};
    } catch (e) {
      debugPrint("Erreur sélection/compression image : $e");
      return null;
    }
  }

  /// ☁️ Upload vers Cloudflare R2 (un seul profil par utilisateur)
  Future<String?> uploadUserProfile({
    required Uint8List bytes,
    required String userId,
    String? fileExtension,
  }) async {
    try {
      final ext = fileExtension ?? 'jpg';
      final mimeType = lookupMimeType('profile.$ext') ?? "image/jpeg";

      // Nom unique basé sur l'ID de l'utilisateur (écrase l'ancien)
      final objectName = 'profile_$userId.$ext';

      await CloudFlareR2.putObject(
        bucket: bucket,
        objectName: objectName,
        objectBytes: bytes,
        contentType: mimeType,
      );

      // Retourne l'URL publique via Public Dev URL
      return '$publicDevUrl/$objectName';
    } catch (e) {
      debugPrint("Erreur upload R2 : $e");
      Get.snackbar(
        "Erreur",
        "Échec de l'upload sur Cloudflare R2",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    }
  }
}
