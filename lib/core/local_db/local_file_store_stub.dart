import 'dart:typed_data';

class LocalFileStore {
  static Future<bool> exists(String path) async => false;

  static Future<String> saveDownloadedMaterial({
    required String materialId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    throw UnsupportedError(
      'Offline material downloads are not available in this build.',
    );
  }
}
