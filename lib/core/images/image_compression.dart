import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Decodes [bytes], downscales so the longest edge is at most [maxDimension],
/// and re-encodes as JPEG at [quality]. Returns the original bytes unchanged if
/// the input can't be decoded. Pure and platform-independent (runs on web) so
/// it can be unit-tested without a picker or backend.
Uint8List compressImage(
  Uint8List bytes, {
  int maxDimension = 1280,
  int quality = 80,
}) {
  img.Image? decoded;
  try {
    decoded = img.decodeImage(bytes);
  } catch (_) {
    // Some decoders throw rather than return null on malformed input.
    return bytes;
  }
  if (decoded == null) {
    return bytes;
  }
  final bool tooBig =
      decoded.width > maxDimension || decoded.height > maxDimension;
  final img.Image resized = tooBig
      ? img.copyResize(
          decoded,
          width: decoded.width >= decoded.height ? maxDimension : null,
          height: decoded.height > decoded.width ? maxDimension : null,
        )
      : decoded;
  return img.encodeJpg(resized, quality: quality);
}
