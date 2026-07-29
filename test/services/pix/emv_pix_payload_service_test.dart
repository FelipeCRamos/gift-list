import 'package:flutter_test/flutter_test.dart';
import 'package:gift_list/services/pix/emv_pix_payload_service.dart';
import 'package:gift_list/services/pix/pix_crc16.dart';

void main() {
  const service = EmvPixPayloadService();

  String build({
    String pixKey = 'test@example.com',
    int amountCents = 15000,
    String merchantName = 'FULANO DE TAL',
    String merchantCity = 'SAO PAULO',
    String txid = 'ABC123',
  }) {
    return service.buildCopiaECola(
      pixKey: pixKey,
      amountCents: amountCents,
      merchantName: merchantName,
      merchantCity: merchantCity,
      txid: txid,
    );
  }

  group('EmvPixPayloadService.buildCopiaECola', () {
    test('matches a hand-assembled golden payload', () {
      // Body assembled field-by-field here, independently of the service's
      // assembly code, so a mismatch pinpoints an assembly bug. The CRC is
      // computed with pixCrc16, which pix_crc16_test proves against the
      // canonical 0x29B1 check value.
      const merchantAccountInfo = '0014br.gov.bcb.pix0116test@example.com';
      const additionalData = '0506ABC123';
      final String body = <String>[
        '000201', // Payload Format Indicator
        '010212', // Point of Initiation Method
        '2638$merchantAccountInfo', // Merchant Account Info (Pix)
        '52040000', // Merchant Category Code
        '5303986', // Transaction Currency
        '5406150.00', // Transaction Amount
        '5802BR', // Country Code
        '5913FULANO DE TAL', // Merchant Name
        '6009SAO PAULO', // Merchant City
        '6210$additionalData', // Additional Data (txid)
      ].join();
      final expected = '${body}6304${pixCrc16('${body}6304')}';

      expect(build(), expected);
    });

    test('is structurally valid: header, currency, and CRC trailer', () {
      final String payload = build();
      expect(payload.startsWith('000201010212'), isTrue);
      expect(payload, contains('0014br.gov.bcb.pix'));
      expect(payload, contains('5303986')); // BRL
      expect(payload, matches(RegExp(r'6304[0-9A-F]{4}$')));
    });

    test('CRC covers the whole body including the 6304 header', () {
      final String payload = build();
      final String withoutCrc = payload.substring(0, payload.length - 4);
      final String actualCrc = payload.substring(payload.length - 4);
      expect(pixCrc16(withoutCrc), actualCrc);
    });

    test('encodes the amount from integer cents', () {
      expect(build(amountCents: 50), contains('54040.50'));
      expect(build(amountCents: 100000), contains('54071000.00'));
    });

    group('rejects non-conforming input', () {
      test('empty pix key', () {
        expect(() => build(pixKey: ''), throwsArgumentError);
      });

      test('negative amount', () {
        expect(() => build(amountCents: -1), throwsArgumentError);
      });

      test('txid with a disallowed character', () {
        expect(() => build(txid: 'ABC-123'), throwsArgumentError);
      });

      test('txid longer than 25 chars', () {
        expect(() => build(txid: 'A' * 26), throwsArgumentError);
      });

      test('non-ASCII merchant name (must be sanitized first)', () {
        expect(() => build(merchantName: 'JOÃO'), throwsArgumentError);
      });

      test('merchant name longer than 25 chars', () {
        expect(() => build(merchantName: 'A' * 26), throwsArgumentError);
      });

      test('merchant city longer than 15 chars', () {
        expect(() => build(merchantCity: 'A' * 16), throwsArgumentError);
      });
    });
  });
}
