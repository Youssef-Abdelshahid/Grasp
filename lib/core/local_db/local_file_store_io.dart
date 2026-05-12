import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class LocalFileStore {
  static Future<bool> exists(String path) {
    return File(path).exists();
  }

  static Future<String> saveDownloadedMaterial({
    required String materialId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final materialDir = Directory(p.join(dir.path, 'offline_materials'));
    if (!await materialDir.exists()) {
      await materialDir.create(recursive: true);
    }
    final safeName = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final file = File(p.join(materialDir.path, '${materialId}_$safeName'));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}
