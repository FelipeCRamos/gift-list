/// ASCII sanitization for Pix Merchant Name (field 59) and Merchant City
/// (field 60). Some banks reject non-conforming payloads, so we strip accents,
/// drop non-ASCII, and enforce max lengths.
library;

const Map<String, String> _accentMap = {
  'á': 'a',
  'à': 'a',
  'ã': 'a',
  'â': 'a',
  'ä': 'a',
  'é': 'e',
  'è': 'e',
  'ê': 'e',
  'ë': 'e',
  'í': 'i',
  'ì': 'i',
  'î': 'i',
  'ï': 'i',
  'ó': 'o',
  'ò': 'o',
  'õ': 'o',
  'ô': 'o',
  'ö': 'o',
  'ú': 'u',
  'ù': 'u',
  'û': 'u',
  'ü': 'u',
  'ç': 'c',
  'ñ': 'n',
};

/// Strips accents to their ASCII base letter, removes any remaining non-ASCII
/// printable characters, collapses whitespace, uppercases, and truncates to
/// [maxLength]. Used for Pix merchant name/city.
String sanitizeAscii(String input, {required int maxLength}) {
  final buffer = StringBuffer();
  for (final String char in input.toLowerCase().split('')) {
    final String mapped = _accentMap[char] ?? char;
    final int code = mapped.codeUnitAt(0);
    // Keep printable ASCII (space..~); drop everything else.
    if (code >= 0x20 && code <= 0x7E) {
      buffer.write(mapped);
    }
  }

  final String collapsed = buffer
      .toString()
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim()
      .toUpperCase();

  return collapsed.length <= maxLength
      ? collapsed
      : collapsed.substring(0, maxLength).trim();
}
