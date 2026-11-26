import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';

/// A fundus photo copied out of the chat so it can be shown later.
class SavedChatImage {
  final String id;
  final String imagePath;
  final String sourcePath;
  final DateTime savedAt;
  final String? drLabel;
  final String? glaucomaLabel;

  const SavedChatImage({
    required this.id,
    required this.imagePath,
    required this.sourcePath,
    required this.savedAt,
    this.drLabel,
    this.glaucomaLabel,
  });

  String get dateLabel {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[savedAt.month - 1]} ${savedAt.day}, ${savedAt.year}';
  }

  String get detailLabel {
    final parts = <String>[
      if (drLabel != null && drLabel!.trim().isNotEmpty) drLabel!.trim(),
      if (glaucomaLabel != null && glaucomaLabel!.trim().isNotEmpty)
        glaucomaLabel!.trim(),
    ];
    if (parts.isEmpty) return 'Fundus photo';
    return parts.join(' · ');
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagePath': imagePath,
      'sourcePath': sourcePath,
      'savedAt': savedAt.toIso8601String(),
      'drLabel': drLabel,
      'glaucomaLabel': glaucomaLabel,
    };
  }

  static SavedChatImage? fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString();
    final imagePath = json['imagePath']?.toString();
    final sourcePath = json['sourcePath']?.toString();
    final savedAt = DateTime.tryParse(json['savedAt']?.toString() ?? '');
    if (id == null || imagePath == null || sourcePath == null || savedAt == null) {
      return null;
    }
    return SavedChatImage(
      id: id,
      imagePath: imagePath,
      sourcePath: sourcePath,
      savedAt: savedAt,
      drLabel: json['drLabel']?.toString(),
      glaucomaLabel: json['glaucomaLabel']?.toString(),
    );
  }

  SavedChatImage copyWith({String? drLabel, String? glaucomaLabel}) {
    return SavedChatImage(
      id: id,
      imagePath: imagePath,
      sourcePath: sourcePath,
      savedAt: savedAt,
      drLabel: drLabel ?? this.drLabel,
      glaucomaLabel: glaucomaLabel ?? this.glaucomaLabel,
    );
  }
}

/// Persists fundus photos that were shown in chat.
class HealthStatisticsStore {
  static Future<Directory> _directory() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/health_statistics');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<File> _indexFile() async {
    final dir = await _directory();
    return File('${dir.path}/index.json');
  }

  static Future<List<SavedChatImage>> load() async {
    final file = await _indexFile();
    if (!await file.exists()) return [];

    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) return [];
      final records = decoded
          .whereType<Map>()
          .map((item) => SavedChatImage.fromJson(Map<String, dynamic>.from(item)))
          .whereType<SavedChatImage>()
          .where((item) => File(item.imagePath).existsSync())
          .toList();
      records.sort((a, b) => b.savedAt.compareTo(a.savedAt));
      return records;
    } catch (_) {
      return [];
    }
  }

  /// Copies a chat photo into app storage and records it.
  static Future<SavedChatImage> saveChatImage(XFile image) async {
    final existing = await load();
    for (final record in existing) {
      if (record.sourcePath == image.path) return record;
    }

    final dir = await _directory();
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final dest = File('${dir.path}/$id.jpg');
    await File(image.path).copy(dest.path);

    final record = SavedChatImage(
      id: id,
      imagePath: dest.path,
      sourcePath: image.path,
      savedAt: DateTime.now(),
    );
    await _write([record, ...existing]);
    return record;
  }

  /// Fills in screening labels for a photo already saved from chat.
  static Future<void> updateScreening({
    required String sourcePath,
    String? drLabel,
    String? glaucomaLabel,
  }) async {
    final records = await load();
    var changed = false;
    final updated = records.map((record) {
      if (record.sourcePath != sourcePath && record.imagePath != sourcePath) {
        return record;
      }
      changed = true;
      return record.copyWith(drLabel: drLabel, glaucomaLabel: glaucomaLabel);
    }).toList();
    if (changed) await _write(updated);
  }

  static Future<String?> savedPathFor(String sourcePath) async {
    final records = await load();
    for (final record in records) {
      if (record.sourcePath == sourcePath) return record.imagePath;
    }
    return null;
  }

  static Future<void> _write(List<SavedChatImage> records) async {
    final file = await _indexFile();
    final payload = records.map((record) => record.toJson()).toList();
    await file.writeAsString(jsonEncode(payload));
  }
}
