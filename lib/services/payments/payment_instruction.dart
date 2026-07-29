import 'package:equatable/equatable.dart';

import '../../data/models/enums.dart';

/// A renderable instruction telling a contributor how to pay the creator.
///
/// Sealed so the UI handles each method's shape exhaustively and a new method
/// is an additive variant, not a change to existing code. See
/// docs/decisions/0004-payment-method-abstraction.md.
sealed class PaymentInstruction extends Equatable {
  const PaymentInstruction();

  PaymentMethod get method;
}

/// Pix instruction: the "Copia e Cola" (EMV BR Code) string that feeds both the
/// QR image and the copy button.
class PixInstruction extends PaymentInstruction {
  const PixInstruction({required this.copiaECola});

  final String copiaECola;

  @override
  PaymentMethod get method => PaymentMethod.pix;

  @override
  List<Object?> get props => [copiaECola];
}
