import 'dart:convert';
import 'dart:typed_data';

import '../storage_repository.dart';

/// In-memory [StorageRepository]. Keeps bytes in a map and returns a base64
/// `data:` URI so uploaded images actually render in the mock build (on web
/// `Image.network` handles data URIs). The Supabase impl will return real
/// public/signed URLs instead.
class InMemoryStorageRepository implements StorageRepository {
  final Map<String, Uint8List> _files = {};

  @override
  Future<String> uploadImage(String path, Uint8List bytes) async {
    _files[path] = bytes;
    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  }
}
