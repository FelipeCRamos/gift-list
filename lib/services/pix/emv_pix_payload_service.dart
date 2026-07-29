import 'pix_payload_service.dart';

/// EMV®MPM implementation of the Pix BR Code.
///
/// NOTE: This is a Phase 1 placeholder so DI can bind the service. The real,
/// test-first implementation (TLV field assembly + CRC-16/CCITT-FALSE) lands in
/// Phase 5 (Pix core) — see docs/gift-registry-spec.md §7.
class EmvPixPayloadService extends PixPayloadService {
  const EmvPixPayloadService();

  @override
  String buildCopiaECola({
    required String pixKey,
    required int amountCents,
    required String merchantName,
    required String merchantCity,
    required String txid,
  }) {
    throw UnimplementedError(
      'EmvPixPayloadService is implemented in Phase 5 (Pix core).',
    );
  }
}
