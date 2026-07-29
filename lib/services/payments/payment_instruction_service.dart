import '../../data/models/enums.dart';
import 'payment_instruction.dart';
import 'payment_request.dart';

/// Builds a [PaymentInstruction] from a [PaymentRequest]. The contribute flow
/// depends on this abstraction, never on a concrete payment mechanism, so
/// enabling a new method is a matter of adding an implementation (and its
/// [Payee] / [PaymentInstruction] variants) rather than editing the flow.
///
/// See docs/decisions/0004-payment-method-abstraction.md.
abstract class PaymentInstructionService {
  const PaymentInstructionService();

  /// The method this service handles; must match the request's [Payee.method].
  PaymentMethod get method;

  PaymentInstruction build(PaymentRequest request);
}
