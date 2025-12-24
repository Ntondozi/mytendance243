import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';

Future<List<Map<String, dynamic>>> compressImagesIsolate(
    List<Map<String, dynamic>> images) async {
  List<Map<String, dynamic>> compressed = [];

  for (var item in images) {
    Uint8List bytes = item['bytes'];
    String fileName = item['fileName'];

    final decoded = img.decodeImage(bytes);
    if (decoded != null) {
      final resized = img.copyResize(decoded, width: 1280);
      final jpg = img.encodeJpg(resized, quality: 75);
      compressed.add({'bytes': Uint8List.fromList(jpg), 'fileName': fileName});
    } else {
      compressed.add({'bytes': bytes, 'fileName': fileName});
    }
  }

  return compressed;
}
