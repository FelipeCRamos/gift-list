import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/errors.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/gift_registry_repository.dart';
import '../../../services/payments/payment_instruction.dart';
import '../../../services/payments/payment_instruction_service.dart';
import '../../../services/payments/payment_request.dart';

part 'gift_state.dart';

/// Drives one contribution: loads the item + payee from the public list, creates
/// the (reserving) contribution on submit, then builds the Pix payment
/// instruction to render. Depends on the method-agnostic
/// [PaymentInstructionService], not on Pix directly (see ADR-0004).
class GiftCubit extends Cubit<GiftState> {
  GiftCubit({
    required GiftRegistryRepository registry,
    required PaymentInstructionService payments,
    required AuthRepository auth,
    required this.slug,
    required this.itemId,
  }) : _registry = registry,
       _payments = payments,
       _auth = auth,
       super(const GiftState());

  final GiftRegistryRepository _registry;
  final PaymentInstructionService _payments;
  final AuthRepository _auth;
  final String slug;
  final String itemId;

  Future<void> load() async {
    emit(state.copyWith(status: GiftStatus.loading, clearError: true));
    try {
      final PublicList list = await _registry.getPublicList(slug);
      final GiftItem? item = _findItem(list.items);
      if (item == null) {
        throw const NotFoundException('Item not found');
      }
      final List<ItemProgress> progress = await _registry.publicProgress(slug);
      final ItemProgress? itemProgress = _findProgress(progress);
      final int remaining = itemProgress == null
          ? item.targetAmountCents
          : item.targetAmountCents -
                itemProgress.confirmedCents -
                itemProgress.reservedCents;

      final bool taken =
          itemProgress?.state == ItemState.complete ||
          (!item.allowPartial && itemProgress?.state == ItemState.reserved) ||
          remaining <= 0;
      if (taken) {
        emit(
          state.copyWith(
            status: GiftStatus.unavailable,
            list: list,
            item: item,
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: GiftStatus.ready,
          list: list,
          item: item,
          remainingCents: remaining,
          giverName: _prefillName(),
        ),
      );
    } catch (error) {
      _emitError(error);
    }
  }

  Future<void> submit({
    required String giverName,
    required int amountCents,
    String? giverMessage,
  }) async {
    final GiftItem? item = state.item;
    final PublicList? list = state.list;
    if (item == null || list == null) {
      return;
    }
    if (giverName.trim().isEmpty) {
      emit(state.copyWith(errorMessage: 'Please tell us who this is from.'));
      return;
    }
    if (item.allowPartial &&
        (amountCents < 1 || amountCents > state.remainingCents)) {
      emit(
        state.copyWith(errorMessage: 'Enter an amount up to the remaining.'),
      );
      return;
    }

    emit(state.copyWith(status: GiftStatus.submitting, clearError: true));
    try {
      final Contribution contribution = await _registry.createContribution(
        NewContribution(
          itemId: item.id,
          listId: item.listId,
          giverName: giverName.trim(),
          amountCents: amountCents,
          contributorId: _auth.currentUser?.id,
          giverMessage: (giverMessage?.trim().isEmpty ?? true)
              ? null
              : giverMessage!.trim(),
        ),
      );

      final PaymentInstruction instruction = _payments.build(
        PaymentRequest(
          amountCents: contribution.amountCents,
          reference: contribution.pixTxid,
          payee: PixPayee(
            pixKey: list.pixKey,
            keyType: list.pixKeyType,
            merchantName: list.merchantName,
            merchantCity: list.merchantCity,
          ),
        ),
      );

      emit(
        state.copyWith(
          status: GiftStatus.awaitingPayment,
          contribution: contribution,
          instruction: instruction,
        ),
      );
    } on ValidationException catch (error) {
      // Cap/availability rejection: keep the form up with the reason.
      emit(
        state.copyWith(status: GiftStatus.ready, errorMessage: error.message),
      );
    } catch (error) {
      _emitError(error);
    }
  }

  GiftItem? _findItem(List<GiftItem> items) {
    for (final item in items) {
      if (item.id == itemId) {
        return item;
      }
    }
    return null;
  }

  ItemProgress? _findProgress(List<ItemProgress> progress) {
    for (final p in progress) {
      if (p.itemId == itemId) {
        return p;
      }
    }
    return null;
  }

  String _prefillName() => _auth.currentUser?.email.split('@').first ?? '';

  void _emitError(Object error) {
    if (error is AccessDeniedException || error is NotAuthenticatedException) {
      emit(state.copyWith(status: GiftStatus.denied));
      return;
    }
    emit(
      state.copyWith(
        status: GiftStatus.failure,
        errorMessage: error is AppException
            ? error.message
            : 'Something went wrong. Please try again.',
      ),
    );
  }
}
