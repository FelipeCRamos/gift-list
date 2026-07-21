/// BRL money helpers. Money is integer cents everywhere; convert to a display
/// or Pix-payload string only at the boundary.
library;

/// Formats integer cents as the dotted amount required by the Pix Transaction
/// Amount field (54), e.g. `15000 -> "150.00"`. No thousands separators, dot
/// decimal, exactly two places. Rejects negative values.
String centsToPixAmount(int cents) {
  if (cents < 0) {
    throw ArgumentError.value(cents, 'cents', 'must be non-negative');
  }
  final int reais = cents ~/ 100;
  final int remainder = cents % 100;
  return '$reais.${remainder.toString().padLeft(2, '0')}';
}

/// Formats integer cents for display in BRL, e.g. `15000 -> "R\$ 150,00"`.
/// Uses the Brazilian convention (comma decimal, dot thousands).
String centsToBrl(int cents) {
  final bool negative = cents < 0;
  final int abs = negative ? -cents : cents;
  final int reais = abs ~/ 100;
  final int remainder = abs % 100;
  final digits = reais.toString();

  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(digits[i]);
  }

  final String centavos = remainder.toString().padLeft(2, '0');
  return '${negative ? '-' : ''}R\$ $buffer,$centavos';
}

/// Parses a user-typed BRL amount into integer cents, or null if unparseable.
/// Accepts `1234`, `1234.56`, `1234,56`, and `1.234,56` (pt-BR grouping).
int? tryParseReaisToCents(String input) {
  String s = input.trim().replaceAll(RegExp(r'[R$\s]'), '');
  if (s.isEmpty) {
    return null;
  }
  final bool hasComma = s.contains(',');
  final bool hasDot = s.contains('.');
  if (hasComma && hasDot) {
    // pt-BR: dot groups thousands, comma is the decimal separator.
    s = s.replaceAll('.', '').replaceAll(',', '.');
  } else if (hasComma) {
    s = s.replaceAll(',', '.');
  }
  final double? value = double.tryParse(s);
  if (value == null || value < 0) {
    return null;
  }
  return (value * 100).round();
}
