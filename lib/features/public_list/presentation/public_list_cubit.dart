import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/errors.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/gift_registry_repository.dart';

part 'public_list_state.dart';

/// Loads a public list's content plus PII-free per-item progress once the gate
/// has granted access.
class PublicListCubit extends Cubit<PublicListState> {
  PublicListCubit({
    required GiftRegistryRepository registry,
    required this.slug,
  }) : _registry = registry,
       super(const PublicListState());

  final GiftRegistryRepository _registry;
  final String slug;

  Future<void> load() async {
    emit(state.copyWith(status: PublicListStatus.loading, clearError: true));
    try {
      final PublicList list = await _registry.getPublicList(slug);
      final List<ItemProgress> progress = await _registry.publicProgress(slug);
      emit(
        state.copyWith(
          status: PublicListStatus.ready,
          list: list,
          progress: {for (final p in progress) p.itemId: p},
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: PublicListStatus.failure,
          errorMessage: _messageFor(error),
        ),
      );
    }
  }

  String _messageFor(Object error) {
    if (error is AppException) {
      return error.message;
    }
    return 'Could not load this list. Please try again.';
  }
}
