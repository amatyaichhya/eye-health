import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:eye_health/api_configs/screening_api_config.dart';
import 'package:eye_health/utils/utility_methods/color_print.dart';
import 'package:http/http.dart' as http;

/// Calls the local screening server (MobileViT DR + MobileOne glaucoma).
class ScreeningService {
  static const Duration _timeout = Duration(seconds: 60);

  static bool isConfigured() => ScreeningApiConfig.isConfigured;

  /// Prefer a human-readable file name over iOS `image_picker_…` temp names.
  static String displayFileName(XFile image, {String? serverFilename}) {
    final basename = image.path.split(RegExp(r'[/\\]')).last;
    for (final candidate in [image.name, serverFilename, basename]) {
      if (candidate == null || candidate.trim().isEmpty) continue;
      if (!_isTempPickerName(candidate)) return candidate;
    }
    return image.name.isNotEmpty ? image.name : basename;
  }

  static bool _isTempPickerName(String name) {
    return name.startsWith('image_picker_') ||
        name.startsWith('scaled_') ||
        RegExp(
          r'^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}',
        ).hasMatch(name);
  }

  /// Screens one fundus image via POST /screen (multipart file).
  static Future<Map<String, dynamic>> screenImage(XFile image) async {
    try {
      colorPrint('Screening via ${ScreeningApiConfig.screenEndpoint}');

      final displayName = displayFileName(image);
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ScreeningApiConfig.screenEndpoint),
      );
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          image.path,
          filename: displayName,
        ),
      );

      final streamed = await request.send().timeout(_timeout);
      final body = await streamed.stream.bytesToString();

      if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
        return {
          'success': false,
          'error': 'HTTP ${streamed.statusCode}: $body',
        };
      }

      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        return {'success': false, 'error': 'Unexpected response format'};
      }

      return decoded;
    } catch (e) {
      colorPrint('ScreeningService error: $e');
      return {
        'success': false,
        'error':
            'Could not connect to the screening server. '
            'Check that it is running on your computer, then try again.',
      };
    }
  }

  /// Screens multiple images; returns per-image results plus a summary message.
  static Future<Map<String, dynamic>> screenImages(List<XFile> images) async {
    if (images.isEmpty) {
      return {'success': false, 'error': 'No images provided'};
    }

    final results = <Map<String, dynamic>>[];
    for (final image in images) {
      final result = await screenImage(image);
      // Attach local path so the chat report can show the fundus image.
      final withLocal = Map<String, dynamic>.from(result);
      withLocal['local_path'] = image.path;
      withLocal['filename'] = displayFileName(
        image,
        serverFilename: result['filename']?.toString(),
      );
      results.add(withLocal);
      if (result['success'] != true) {
        return {
          'success': false,
          'error': result['error'] ?? 'Screening failed',
          'results': results,
        };
      }
    }

    return {
      'success': true,
      'source': 'local_screening',
      'results': results,
      'primary': results.first,
    };
  }

  /// Per-image payloads from a successful [screenImages] response.
  static List<Map<String, dynamic>> extractResults(Map<String, dynamic> result) {
    final raw = result['results'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (result.containsKey('diabetic_retinopathy') ||
        result.containsKey('glaucoma')) {
      return [result];
    }
    return [];
  }

  /// Human-readable chat message from a successful /screen payload.
  static String formatResultMessage(Map<String, dynamic> result) {
    final buffer = StringBuffer();
    buffer.writeln('**Local screening results**');
    buffer.writeln();

    final items =
        result['results'] is List
            ? List<Map<String, dynamic>>.from(
              (result['results'] as List).whereType<Map>().map(
                (e) => Map<String, dynamic>.from(e),
              ),
            )
            : [result];

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (items.length > 1) {
        buffer.writeln('**Photo ${i + 1}**');
      }

      final dr = item['diabetic_retinopathy'];
      if (dr is Map) {
        buffer.writeln(
          '**Diabetic retinopathy:** ${dr['label']} (grade ${dr['grade']})',
        );
        final probs = dr['probabilities'];
        if (probs is Map) {
          final conf = probs['${dr['grade']}'] ?? probs[dr['grade']];
          if (conf != null) {
            final pct = (double.tryParse(conf.toString()) ?? 0) * 100;
            buffer.writeln('**DR confidence:** ${pct.toStringAsFixed(1)}%');
          }
        }
      }

      final gl = item['glaucoma'];
      if (gl is Map) {
        buffer.writeln('**Glaucoma screen:** ${gl['label']}');
        final probs = gl['probabilities'];
        if (probs is Map) {
          final key = gl['positive'] == true ? 'positive' : 'negative';
          final conf = probs[key];
          if (conf != null) {
            final pct = (double.tryParse(conf.toString()) ?? 0) * 100;
            buffer.writeln(
              '**Glaucoma confidence:** ${pct.toStringAsFixed(1)}%',
            );
          }
        }
      }
      buffer.writeln();
    }

    buffer.writeln(
      'These are model screening outputs for demo/education only — not a clinical diagnosis.',
    );
    buffer.writeln(
      'Feel free to ask me any questions about these results or about general eye health!',
    );
    return buffer.toString();
  }
}
