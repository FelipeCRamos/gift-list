import 'package:flutter_test/flutter_test.dart';
import 'package:gift_list/core/formatting/brl_money.dart';

void main() {
  group('centsToPixAmount', () {
    test('formats with two decimals and dot separator', () {
      expect(centsToPixAmount(15000), '150.00');
      expect(centsToPixAmount(5), '0.05');
      expect(centsToPixAmount(0), '0.00');
    });

    test('rejects negatives', () {
      expect(() => centsToPixAmount(-1), throwsArgumentError);
    });
  });

  group('centsToBrl', () {
    test('uses pt-BR grouping and comma decimals', () {
      expect(centsToBrl(15000), r'R$ 150,00');
      expect(centsToBrl(123456), r'R$ 1.234,56');
      expect(centsToBrl(0), r'R$ 0,00');
    });
  });

  group('tryParseReaisToCents', () {
    test('parses the accepted formats to cents', () {
      expect(tryParseReaisToCents('150'), 15000);
      expect(tryParseReaisToCents('150,00'), 15000);
      expect(tryParseReaisToCents('150.00'), 15000);
      expect(tryParseReaisToCents('1.234,56'), 123456);
      expect(tryParseReaisToCents(r'R$ 99,90'), 9990);
    });

    test('returns null for invalid input', () {
      expect(tryParseReaisToCents(''), isNull);
      expect(tryParseReaisToCents('abc'), isNull);
    });
  });
}
