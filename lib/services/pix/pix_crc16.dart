/// CRC-16/CCITT-FALSE used to close the Pix "Copia e Cola" payload (field 63).
///
/// Parameters: poly `0x1021`, init `0xFFFF`, no input/output reflection,
/// xorout `0x0000`. Returns 4 uppercase hex chars, left-padded — see
/// docs/gift-registry-spec.md §7.
library;

/// Computes the CRC-16/CCITT-FALSE of [payload] and returns it as 4 uppercase
/// hex characters. [payload] must be ASCII (the BR Code is ASCII by
/// construction), so iterating `codeUnits` is equivalent to iterating bytes.
String pixCrc16(String payload) {
  var crc = 0xFFFF;
  for (final int byte in payload.codeUnits) {
    crc ^= (byte << 8) & 0xFFFF;
    for (var i = 0; i < 8; i++) {
      crc = (crc & 0x8000) != 0
          ? ((crc << 1) ^ 0x1021) & 0xFFFF
          : (crc << 1) & 0xFFFF;
    }
  }
  return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
}
