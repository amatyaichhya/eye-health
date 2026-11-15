import 'dart:convert';

import 'package:camera/camera.dart';

import 'color_print.dart';

/// Converts XFile image to base64 string with optimization
Future<String> convertImageToBase64(XFile imageFile) async {
  try {
    final bytes = await imageFile.readAsBytes();

    // For now, we'll use the image as-is
    // In a production app, you might want to resize/compress the image
    // to reduce API costs and improve performance

    return base64Encode(bytes);
  } catch (e) {
    colorPrint('Error converting image to base64: $e');
    rethrow;
  }
}
