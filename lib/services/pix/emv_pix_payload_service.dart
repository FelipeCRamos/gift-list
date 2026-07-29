import '../../core/formatting/brl_money.dart';
import 'pix_crc16.dart';
import 'pix_payload_service.dart';

/// EMV®MPM implementation of the Pix BR Code ("Copia e Cola").
///
/// Assembles the ordered TLV fields (`ID(2) + LEN(2) + VALUE`) and closes them
/// with a CRC-16/CCITT-FALSE — deterministic and offline, never calling a
/// third-party service. See docs/gift-registry-spec.md §7.
///
/// Merchant name/city must already be ASCII-sanitized and length-capped by the
/// caller (the [PaymentInstructionService] adapter does this); this service
/// *validates* and throws [ArgumentError] on any non-conforming input so bugs
/// surface loudly rather than producing a payload a bank will reject.
class EmvPixPayloadService extends PixPayloadService {
  const EmvPixPayloadService();

  static const String _gui = 'br.gov.bcb.pix';
  static final RegExp _txidPattern = RegExp(r'^[A-Za-z0-9]{1,25}$');
  static final RegExp _ascii = RegExp(r'^[\x20-\x7E]*$');

  static const int _maxMerchantName = 25;
  static const int _maxMerchantCity = 15;

  @override
  String buildCopiaECola({
    required String pixKey,
    required int amountCents,
    required String merchantName,
    required String merchantCity,
    required String txid,
  }) {
    if (pixKey.isEmpty) {
      throw ArgumentError.value(pixKey, 'pixKey', 'must not be empty');
    }
    if (!_txidPattern.hasMatch(txid)) {
      throw ArgumentError.value(
        txid,
        'txid',
        r'must match ^[A-Za-z0-9]{1,25}$',
      );
    }
    _requireConforming(merchantName, 'merchantName', _maxMerchantName);
    _requireConforming(merchantCity, 'merchantCity', _maxMerchantCity);

    // centsToPixAmount rejects negative values.
    final String amount = centsToPixAmount(amountCents);

    final String merchantAccountInfo = _tlv('00', _gui) + _tlv('01', pixKey);
    final String additionalData = _tlv('05', txid);

    final body = StringBuffer()
      ..write(_tlv('00', '01')) // Payload Format Indicator
      ..write(_tlv('01', '12')) // Point of Initiation Method (single-use)
      ..write(_tlv('26', merchantAccountInfo)) // Merchant Account Info (Pix)
      ..write(_tlv('52', '0000')) // Merchant Category Code
      ..write(_tlv('53', '986')) // Transaction Currency (BRL)
      ..write(_tlv('54', amount)) // Transaction Amount
      ..write(_tlv('58', 'BR')) // Country Code
      ..write(_tlv('59', merchantName)) // Merchant Name
      ..write(_tlv('60', merchantCity)) // Merchant City
      ..write(_tlv('62', additionalData)); // Additional Data (txid)

    // CRC covers the whole body plus the CRC field's own ID+length ("6304").
    final withCrcHeader = '${body}6304';
    return '$withCrcHeader${pixCrc16(withCrcHeader)}';
  }

  /// Encodes one TLV field. EMV lengths are exactly two digits, so a value may
  /// not exceed 99 characters (a Pix email key maxes at 77, so the nested
  /// Merchant Account Info stays within bounds).
  String _tlv(String id, String value) {
    if (value.length > 99) {
      throw ArgumentError.value(
        value,
        'value',
        'TLV value for id $id exceeds 99 chars (${value.length})',
      );
    }
    return '$id${value.length.toString().padLeft(2, '0')}$value';
  }

  void _requireConforming(String value, String name, int maxLength) {
    if (!_ascii.hasMatch(value)) {
      throw ArgumentError.value(value, name, 'must be ASCII (sanitize first)');
    }
    if (value.isEmpty || value.length > maxLength) {
      throw ArgumentError.value(
        value,
        name,
        'length must be 1..$maxLength (was ${value.length})',
      );
    }
  }
}
