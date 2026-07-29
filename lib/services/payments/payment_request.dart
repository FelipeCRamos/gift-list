import 'package:equatable/equatable.dart';

import '../../data/models/enums.dart';

/// Method-agnostic inputs for building a payment instruction: the transaction
/// facts plus a [Payee] carrying the creator's method-specific credentials.
///
/// The contribute flow (Phase 6) constructs this from the item amount, a
/// generated reference (txid), and the creator's payee config.
class PaymentRequest extends Equatable {
  const PaymentRequest({
    required this.amountCents,
    required this.reference,
    required this.payee,
  });

  /// Integer BRL cents.
  final int amountCents;

  /// Per-contribution reference embedded in the instruction (the Pix txid).
  final String reference;

  final Payee payee;

  @override
  List<Object?> get props => [amountCents, reference, payee];
}

/// Creator payee credentials. Sealed so each payment method contributes its own
/// variant and consumers handle them exhaustively — adding a method is
/// additive. See docs/decisions/0004-payment-method-abstraction.md.
sealed class Payee extends Equatable {
  const Payee();

  PaymentMethod get method;
}

/// Pix payee: the creator's key plus the merchant name/city rendered into the
/// BR Code. Values may be raw here; the Pix adapter sanitizes them.
class PixPayee extends Payee {
  const PixPayee({
    required this.pixKey,
    required this.keyType,
    required this.merchantName,
    required this.merchantCity,
  });

  final String pixKey;
  final PixKeyType keyType;
  final String merchantName;
  final String merchantCity;

  @override
  PaymentMethod get method => PaymentMethod.pix;

  @override
  List<Object?> get props => [pixKey, keyType, merchantName, merchantCity];
}
