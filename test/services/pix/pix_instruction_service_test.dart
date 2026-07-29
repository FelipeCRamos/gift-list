import 'package:flutter_test/flutter_test.dart';
import 'package:gift_list/data/models/enums.dart';
import 'package:gift_list/services/payments/payment_instruction.dart';
import 'package:gift_list/services/payments/payment_request.dart';
import 'package:gift_list/services/pix/emv_pix_payload_service.dart';
import 'package:gift_list/services/pix/pix_instruction_service.dart';

void main() {
  const service = PixInstructionService(EmvPixPayloadService());

  PaymentRequest request({
    String merchantName = 'FULANO DE TAL',
    String merchantCity = 'SAO PAULO',
  }) {
    return PaymentRequest(
      amountCents: 15000,
      reference: 'ABC123',
      payee: PixPayee(
        pixKey: 'test@example.com',
        keyType: PixKeyType.email,
        merchantName: merchantName,
        merchantCity: merchantCity,
      ),
    );
  }

  group('PixInstructionService', () {
    test('reports the Pix method', () {
      expect(service.method, PaymentMethod.pix);
    });

    test('builds a PixInstruction wrapping the engine output', () {
      final PaymentInstruction instruction = service.build(request());
      expect(instruction, isA<PixInstruction>());
      final String copia = (instruction as PixInstruction).copiaECola;
      expect(
        copia,
        const EmvPixPayloadService().buildCopiaECola(
          pixKey: 'test@example.com',
          amountCents: 15000,
          merchantName: 'FULANO DE TAL',
          merchantCity: 'SAO PAULO',
          txid: 'ABC123',
        ),
      );
    });

    test(
      'sanitizes accented and over-long merchant fields before building',
      () {
        // Raw payee data the engine would reject; the adapter must normalize it
        // (strip accents, uppercase, cap length) so the engine accepts it.
        final instruction =
            service.build(
                  request(
                    merchantName: 'João da Silva com um nome muito longo',
                    merchantCity: 'São Paulo do Sul',
                  ),
                )
                as PixInstruction;

        expect(
          instruction.copiaECola,
          contains('5925JOAO DA SILVA COM UM NOME'),
        );
        expect(instruction.copiaECola, contains('6015SAO PAULO DO SU'));
      },
    );
  });
}
