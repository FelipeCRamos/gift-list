import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/errors.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/gift_registry_repository.dart';

part 'lists_state.dart';

/// Dashboard "my lists" — loads the owner's lists and creates new ones. Also
/// carries the owner's profile so the create form can prefill Pix defaults.
class ListsCubit extends Cubit<ListsState> {
  ListsCubit({required GiftRegistryRepository registry})
    : _registry = registry,
      super(const ListsState());

  final GiftRegistryRepository _registry;

  Future<void> load() async {
    emit(state.copyWith(status: ListsStatus.loading, clearError: true));
    try {
      final List<GiftList> lists = await _registry.myLists();
      final Profile? profile = await _registry.getMyProfile();
      emit(
        state.copyWith(
          status: ListsStatus.ready,
          lists: lists,
          profile: profile,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ListsStatus.failure,
          errorMessage: _messageFor(error),
        ),
      );
    }
  }

  /// Creates a list and returns it (null on failure), refreshing the list.
  Future<GiftList?> create(NewList data) async {
    try {
      final GiftList created = await _registry.createList(data);
      emit(state.copyWith(lists: [created, ...state.lists]));
      return created;
    } catch (error) {
      emit(state.copyWith(errorMessage: _messageFor(error)));
      return null;
    }
  }

  String _messageFor(Object error) {
    if (error is AppException) {
      return error.message;
    }
    return 'Could not load your lists. Please try again.';
  }
}
