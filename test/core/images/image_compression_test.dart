import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gift_list/core/images/image_compression.dart';
import 'package:image/image.dart' as img;

Uint8List _png(int width, int height) =>
    img.encodePng(img.Image(width: width, height: height));

void main() {
  group('compressImage', () {
    test('downscales so the longest edge is at most maxDimension', () {
      final Uint8List out = compressImage(_png(4000, 2000), maxDimension: 1000);
      final img.Image decoded = img.decodeImage(out)!;
      expect(decoded.width, 1000);
      expect(decoded.height, 500); // aspect ratio preserved
    });

    test('leaves small images at their original dimensions', () {
      final Uint8List out = compressImage(_png(300, 200), maxDimension: 1000);
      final img.Image decoded = img.decodeImage(out)!;
      expect(decoded.width, 300);
      expect(decoded.height, 200);
    });

    test('re-encodes as decodable JPEG', () {
      final Uint8List out = compressImage(_png(100, 100));
      expect(img.decodeJpg(out), isNotNull);
    });

    test('returns the input unchanged when it cannot be decoded', () {
      final garbage = Uint8List.fromList([1, 2, 3, 4]);
      expect(compressImage(garbage), garbage);
    });
  });
}
