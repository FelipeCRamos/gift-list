import '../../core/formatting/ascii_sanitize.dart';
import '../../data/models/enums.dart';
import '../payments/payment_instruction.dart';
import '../payments/payment_instruction_service.dart';
import '../payments/payment_request.dart';
import 'pix_payload_service.dart';

/// Pix implementation of the payment seam. Adapts a [PixPayloadService] (the
/// EMV/CRC engine) to the method-agnostic [PaymentInstructionService].
///
/// This adapter owns Pix-specific *normalization*: it sanitizes the merchant
/// name/city to ASCII and caps their length before handing them to the engine,
/// which then *validates* the result. See
/// docs/decisions/0004-payment-method-abstraction.md.
class PixInstructionService extends PaymentInstructionService {
  const PixInstructionService(this._payloadService);

  static const int _maxMerchantName = 25;
  static const int _maxMerchantCity = 15;

  final PixPayloadService _payloadService;

  @override
  PaymentMethod get method => PaymentMethod.pix;

  @override
  PaymentInstruction build(PaymentRequest request) {
    final PixPayee payee = switch (request.payee) {
      final PixPayee p => p,
    };

    final String copiaECola = _payloadService.buildCopiaECola(
      pixKey: payee.pixKey,
      amountCents: request.amountCents,
      merchantName: sanitizeAscii(
        payee.merchantName,
        maxLength: _maxMerchantName,
      ),
      merchantCity: sanitizeAscii(
        payee.merchantCity,
        maxLength: _maxMerchantCity,
      ),
      txid: request.reference,
    );

    return PixInstruction(copiaECola: copiaECola);
  }
}
