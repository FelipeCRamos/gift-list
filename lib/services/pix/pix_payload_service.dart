/// Builds the Pix "Copia e Cola" (EMV®MPM BR Code) string entirely on the
/// client. Deterministic and offline — implementations must never call a
/// third-party service.
abstract class PixPayloadService {
  const PixPayloadService();

  /// Returns the full copia-e-cola string (all TLV fields + CRC16) for a single
  /// fixed-amount charge. Merchant name/city must already be ASCII-sanitized and
  /// length-capped; `txid` must match `^[A-Za-z0-9]{1,25}$`.
  String buildCopiaECola({
    required String pixKey,
    required int amountCents,
    required String merchantName,
    required String merchantCity,
    required String txid,
  });
}
