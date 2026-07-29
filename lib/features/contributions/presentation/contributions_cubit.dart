import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/errors.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/gift_registry_repository.dart';

part 'contributions_state.dart';

/// Creator's contributions inbox for one list: confirm/reject reservations and
/// the confirmed thank-you wall. Reservations past their TTL surface as
/// `expired` (lazy expiry happens in the repository read).
class ContributionsCubit extends Cubit<ContributionsState> {
  ContributionsCubit({
    required GiftRegistryRepository registry,
    required this.listId,
  }) : _registry = registry,
       super(const ContributionsState());

  final GiftRegistryRepository _registry;
  final String listId;

  Future<void> load() async {
    emit(state.copyWith(status: ContributionsStatus.loading, clearError: true));
    try {
      final GiftList list = await _registry.getMyList(listId);
      final List<Contribution> rows = await _registry.contributionsForList(
        listId,
      );
      emit(
        state.copyWith(
          status: ContributionsStatus.ready,
          listTitle: list.title,
          contributions: rows,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ContributionsStatus.failure,
          errorMessage: _messageFor(error),
        ),
      );
    }
  }

  Future<void> confirm(String id) => _mutate(id, _registry.confirmContribution);

  Future<void> reject(String id) => _mutate(id, _registry.rejectContribution);

  Future<void> _mutate(String id, Future<void> Function(String) action) async {
    emit(state.withBusy(id));
    try {
      await action(id);
      final List<Contribution> rows = await _registry.contributionsForList(
        listId,
      );
      emit(state.copyWith(contributions: rows).withoutBusy(id));
    } catch (error) {
      emit(state.copyWith(errorMessage: _messageFor(error)).withoutBusy(id));
    }
  }

  String _messageFor(Object error) => error is AppException
      ? error.message
      : 'Something went wrong. Please try again.';
}
