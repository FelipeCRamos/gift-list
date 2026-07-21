import 'dart:typed_data';

/// Image storage boundary. Returns a public URL for the uploaded bytes.
abstract class StorageRepository {
  Future<String> uploadImage(String path, Uint8List bytes);
}
