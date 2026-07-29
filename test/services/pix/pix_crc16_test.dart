import 'package:flutter_test/flutter_test.dart';
import 'package:gift_list/services/pix/pix_crc16.dart';

void main() {
  group('pixCrc16', () {
    test('returns the canonical CRC-16/CCITT-FALSE check value', () {
      // 0x29B1 is the published check value for "123456789" under this CRC
      // variant — an authoritative, implementation-independent anchor.
      expect(pixCrc16('123456789'), '29B1');
    });

    test('always returns 4 uppercase hex chars, left-padded', () {
      final String result = pixCrc16('');
      expect(result, hasLength(4));
      expect(result, matches(RegExp(r'^[0-9A-F]{4}$')));
      // CRC of the empty string is the init value 0xFFFF.
      expect(result, 'FFFF');
    });

    test('is deterministic and sensitive to input', () {
      expect(pixCrc16('A'), pixCrc16('A'));
      expect(pixCrc16('A'), isNot(pixCrc16('B')));
    });
  });
}
