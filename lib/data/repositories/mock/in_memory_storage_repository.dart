import 'dart:typed_data';

import '../storage_repository.dart';

/// In-memory [StorageRepository]. Keeps bytes in a map and returns a stable
/// fake URL — enough to exercise upload flows without a backend.
class InMemoryStorageRepository implements StorageRepository {
  final Map<String, Uint8List> _files = {};

  @override
  Future<String> uploadImage(String path, Uint8List bytes) async {
    _files[path] = bytes;
    return 'https://mock.local/storage/$path';
  }
}
